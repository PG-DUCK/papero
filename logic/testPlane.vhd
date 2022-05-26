--!@file testPlane.vhd
--!@brief Dummy detector interface to generate test patterns
--!
--!@details Create data test patterns for debug purposes \n\n
--!**Reset duration shall be no less than 2 clock cycles**
--!
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.basic_package.all;
use work.FOOTpackage.all;

--!@copydoc testPlane.vhd
entity testPlane is
  generic (
    pACTIVE_EDGE : string := "F"        --!"F": falling, "R": rising
    );
  port (
    iCLK          : in  std_logic;      --!Main clock
    iRST          : in  std_logic;      --!Main reset
    -- control interface
    oCNT          : out tControlIntfOut;     --!Control signals in output
    iCNT          : in  tControlIntfIn;      --!Control signals in input
    iFE_CLK_DIV   : in  std_logic_vector(15 downto 0);  --!FE SlowClock divider
    iFE_CLK_DUTY  : in  std_logic_vector(15 downto 0);  --!FE SlowClock duty cycle
    iADC_CLK_DIV  : in  std_logic_vector(15 downto 0);  --!ADC SlowClock divider
    iADC_CLK_DUTY : in  std_logic_vector(15 downto 0);  --!ADC SlowClock divider
    iADC_DELAY    : in  std_logic_vector(15 downto 0);  --!Delay from the FE falling edge and the start of the AD conversion
    iCFG_FE       : in  std_logic_vector(11 downto 0);  --!FE configurations
    iADC_FAST     : in  std_logic;                      --!Switch to the ADC fast-data mode
    -- FE interface
    oFE0          : out tFpga2FeIntf;   --!Output signals to the FE0
    oFE1          : out tFpga2FeIntf;   --!Output signals to the FE1
    iFE           : in  tFe2FpgaIntf;   --!Input signals from the FE
    -- ADC interface
    oADC0         : out tFpga2AdcIntf;  --!Signals from the FPGA to the 0-4 ADCs
    oADC1         : out tFpga2AdcIntf;  --!Signals from the FPGA to the 5-9 ADCs
    iMULTI_ADC    : in  tMultiAdc2FpgaIntf;  --!Signals from the ADCs to the FPGA
    -- FIFO output interface
    oMULTI_FIFO   : out tMultiAdcFifoOut;    --!Output interface of FIFOs
    iMULTI_FIFO   : in  tMultiAdcFifoIn      --!Input interface of FIFOs
    );
end testPlane;

--!@copydoc testPlane.vhd
architecture std of testPlane is
  signal sCntOut      : tControlIntfOut;
  signal sCntIn       : tControlIntfIn;
  signal sFifoOut     : tMultiAdcFifoOut;
  signal sFifoIn      : tMultiAdcFifoIn;

  type tDataGen is array (0 to cTOTAL_ADCS-1) of std_logic_vector(cADC_DATA_WIDTH-1 downto 0);
  signal sDataGen     : tDataGen;

  signal sFe          : tFpga2FeIntf;
  signal sFeOCnt      : tControlIntfOut;
  signal sFeICnt      : tControlIntfIn;
  signal sFeOtherEdge : std_logic;

  signal sAdc         : tFpga2AdcIntf;

  -- Clock dividers
  signal sFeCdRis, sFeCdFal   : std_logic;
  signal sFeSlwEn             : std_logic;
  signal sFeSlwRst            : std_logic;

  -- FSM signals
  type tHpState is (RESET, IDLE, READOUT, END_READOUT);
  signal sHpState, sNextHpState : tHpState;
  signal sFsmSynchEn            : std_logic;
  signal sChCount               : std_logic_vector(ceil_log2(cFE_CLOCK_CYCLES)-1 downto 0);

begin
  -- Combinatorial assignments -------------------------------------------------
  oCNT   <= sCntOut;
  sCntIn <= iCNT;

  oMULTI_FIFO <= sFifoOut;

  --Duplicate the signals for the two half-plane ports
  oFE0  <= sFe;
  oFE1  <= sFe;
  oADC0 <= sAdc;
  oADC1 <= sAdc;

  sFe.G0      <= '0';
  sFe.G1      <= '0';
  sFe.G2      <= '0';
  sFe.Hold    <= '0';
  sFe.DRst    <= '0';
  sFe.ShiftIn <= '0';
  sFe.Clk     <= '0';
  sFe.TestOn  <= '0';
  sAdc.SClk   <= '0';
  sAdc.Cs     <= '0';

  ------------------------------------------------------------------------------

  -- Slow signals Generator ----------------------------------------------------
  sFeICnt.slwEn <= sFeCdFal when (pACTIVE_EDGE = "F") else
                   sFeCdRis;
  sFeOtherEdge  <= sFeCdRis when (pACTIVE_EDGE = "F") else
                   sFeCdFal;
  --!@brief Generate the SlowClock and SlowEnable for the FEs interface
  FE_div : clock_divider_2
    generic map(
      pPOLARITY => '0',
      pWIDTH    => 16
      )
    port map (
      iCLK             => iCLK,
      iRST             => sFeSlwRst,
      iEN              => sFeSlwEn,
      iFREQ_DIV        => iFE_CLK_DIV,
      iDUTY_CYCLE      => iFE_CLK_DUTY,
      oCLK_OUT         => sFeICnt.slwClk,
      oCLK_OUT_RISING  => sFeCdRis,
      oCLK_OUT_FALLING => sFeCdFal
      );
  ------------------------------------------------------------------------------

  --!@brief Generate multiple FIFOs to sample the ADCs
  FIFO_GENERATE : for i in 0 to cTOTAL_ADCS-1 generate

    DATAGEN_proc : process(iCLK)
    begin
      if (rising_edge(iCLK)) then
        if (iRST = '1') then
          sFifoIn(i).wr <= '0';
          sDataGen(i)   <= int2slv(i, sDataGen(i)'length);
        else
          sFifoIn(i).wr <= sFsmSynchEn;
          if (sHpState = IDLE) then
            sDataGen(i)   <= int2slv(i, sDataGen(i)'length);
          else
            if (sFsmSynchEn = '1') then
              sDataGen(i) <= sDataGen(i) + int2slv(10, sDataGen(i)'length);
            end if;
          end if;
        end if;
      end if;
    end process DATAGEN_proc;

    EVEN_GEN : if (i mod 2 = 0) generate
      sFifoIn(i+1).data <= sDataGen(i);
    end generate EVEN_GEN;

    ODD_GEN : if (i mod 2 = 1) generate
      sFifoIn(i-1).data <= sDataGen(i);
    end generate ODD_GEN;

    sFifoIn(i).rd   <= iMULTI_FIFO(i).rd;
    --!@brief FIFETTE (ideally, take data from the ADCs)
    --!@brief full and aFull flags are not used, each FIFO is supposed to be ready
    ADC_FIFO : parametric_fifo_synch
      generic map(
        pWIDTH       => cADC_DATA_WIDTH,
        pDEPTH       => cADC_FIFO_DEPTH,
        pUSEDW_WIDTH => ceil_log2(cADC_FIFO_DEPTH),
        pAEMPTY_VAL  => 3,
        pAFULL_VAL   => cADC_FIFO_DEPTH-3,
        pSHOW_AHEAD  => "OFF"
        )
      port map(
        iCLK    => iCLK,
        iRST    => iRST,
        oAEMPTY => sFifoOut(i).aEmpty,
        oEMPTY  => sFifoOut(i).empty,
        oAFULL  => sFifoOut(i).aFull,
        oFULL   => sFifoOut(i).full,
        oUSEDW  => open,
        iRD_REQ => sFifoIn(i).rd,
        iWR_REQ => sFifoIn(i).wr,
        iDATA   => sFifoIn(i).data,
        oQ      => sFifoOut(i).q
        );
  end generate FIFO_GENERATE;

  --!@brief Output signals in a synchronous fashion, without reset
  --!@param[in] iCLK Clock, used on rising edge
  HP_synch_signals_proc : process (iCLK)
  begin
    if (rising_edge(iCLK)) then
      if (sHpState = RESET) then
        sFeICnt.en  <= '0';
      else
        sFeICnt.en  <= '1';
      end if;

      if (sHpState = RESET or sHpState = IDLE) then
        sFeSlwRst <= '1';
      else
        sFeSlwRst <= '0';
      end if;

      if (sHpState /= IDLE and sHpState /= RESET) then
        sFeSlwEn <= '1';
      else
        sFeSlwEn <= '0';
      end if;

      if (sHpState /= IDLE) then
        sCntOut.busy <= '1';
      else
        sCntOut.busy <= '0';
      end if;

      if (sHpState = RESET) then
        sCntOut.reset <= '1';
      else
        sCntOut.reset <= '0';
      end if;

      if (sHpState = END_READOUT) then
        sCntOut.compl <= '1';
      else
        sCntOut.compl <= '0';
      end if;

      if (sHpState /= READOUT) then
        sChCount    <= (others => '0');
      else
        sChCount    <= sChCount + sFsmSynchEn;
      end if;

      --!@todo How do I check the "when others" statement?
      sCntOut.error <= '0';

    end if;
  end process HP_synch_signals_proc;

  --!@brief Add FFDs to the combinatorial signals \n
  --!@details Delay the FE slwEn by one clock cycle to synch this FSM to the
  --!@details FSM of the FE, taking decisions when the action is performed
  --!@param[in] iCLK  Clock, used on rising edge
  ffds : process (iCLK)
  begin
    if (rising_edge(iCLK)) then
      if (iRST = '1') then
        sHpState    <= RESET;
        sFsmSynchEn <= '0';
      else
        sHpState    <= sNextHpState;
        sFsmSynchEn <= sFeICnt.slwEn;
      end if;  --iRST
    end if;  --rising_edge
  end process ffds;

  --!@brief Combinatorial FSM to operate the HP machinery
  --!@param[in] sHpState  Current state of the FSM
  --!@param[in] sCntIn    Input ports of the control interface
  --!@param[in] sChCount  Channel count
  --!@return sNextHpState Next state of the FSM
  TESTGEN_proc : process(sHpState, sCntIn, sChCount)
  begin
    case (sHpState) is
      --Reset the FSM
      when RESET =>
        sNextHpState <= IDLE;

      --Wait for the START signal
      when IDLE =>
        if (sCntIn.en = '1' and sCntIn.start = '1') then
          sNextHpState <= READOUT;
        else
          sNextHpState <= IDLE;
        end if;

      --Go to the last state or continue reading synchronized to the FE clock
      when READOUT =>
        if (sChCount < int2slv(cFE_CLOCK_CYCLES-1, sChCount'length)) then
          sNextHpState <= READOUT;
        else
          sNextHpState <= END_READOUT;
        end if;

      --The HP reading is concluded
      when END_READOUT =>
        sNextHpState <= IDLE;

      --State not foreseen
      when others =>
        sNextHpState <= RESET;

    end case;
  end process TESTGEN_proc;

end architecture std;
