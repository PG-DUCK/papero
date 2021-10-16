--!@file priorityEncoder.vhd
--!@brief Combine the ADC 16-bit FIFOs into one output 32-bit FIFO
--!@todo It now takes 2 clock cycles for each 32-bit word. If speed is requested, remove dpFIFO and read two multi_FIFO word at a time
--!@author Mattia Barbanera (mattia.barbanera@infn.it)
--!@author Matteo D'Antonio (matteo.dantonio@studenti.unipg.it)
--!@author Keida Kanxheri (keida.kanxheri@pg.infn.it)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.basic_package.all;
use work.FOOTpackage.all;
use work.paperoPackage.all;
--use work.DAQ_Package.all;

--!@copydoc priorityEncoder.vhd
entity priorityEncoder is
  generic(
    pFIFOWIDTH : natural := 32;
    pFIFODEPTH : natural := 16
    );
  port (
    iCLK            : in  std_logic;
    iRST            : in  std_logic;
    --FIFOs from detectors
    iMULTI_FIFO     : in  tMultiAdcFifoOut;
    oMULTI_FIFO     : out tMultiAdcFifoIn;
    --HPS interface
    oFASTDATA_DATA  : out std_logic_vector(pFIFOWIDTH-1 downto 0);
    oFASTDATA_WE    : out std_logic;
    iFASTDATA_AFULL : in  std_logic
    );
end priorityEncoder;

--!@copydoc priorityEncoder.vhd
architecture std of priorityEncoder is
  --Constants
  constant cLENCONV_AFULL_THR : natural := pFIFODEPTH - 3;

  --FSM
  type tPeState is (IDLE, ACTIVE);
  signal sPeState                  : tPeState;
  signal sFifoCount, sFifoCountDel : natural range 0 to min_pow2_gte(cTOTAL_ADCs)-1 := 0;

  --dpFIFO
  signal sLenConvData  : std_logic_vector(cADC_DATA_WIDTH-1 downto 0);
  signal sLenConvWr    : std_logic;
  signal sLenConvRd    : std_logic;
  signal sLenConvOut   : tFifoFdiOut;
  signal sLenConvUsedW : std_logic_vector(ceil_log2(pFIFODEPTH)-1 downto 0);

begin
  init_gen : for ii in 0 to cTOTAL_ADCS-1 generate
    oMULTI_FIFO(ii).wr   <= '0';
    oMULTI_FIFO(ii).data <= (others => '0');
  end generate init_gen;

  sLenConvData <= iMULTI_FIFO(sFifoCountDel).q;
  --!@brief Change state depending on the MultiFIFO and internal FIFO
  PRIORITY_ENC_STATE : process (iCLK)
  begin
    if (rising_edge(iCLK)) then
      if (iRST = '1') then
        sFifoCount    <= 0;
        sFifoCountDel <= 0;
        sLenConvWr    <= '0';
        read_gen_0 : for ii in 0 to cTOTAL_ADCS-1 loop
          oMULTI_FIFO(ii).rd <= '0';
        end loop read_gen_0;
        sPeState <= IDLE;
      elsif (sLenConvUsedW < int2slv(cLENCONV_AFULL_THR, sLenConvUsedW'length)) then

        --Default assignment, updated where necessary
        read_gen_1 : for ii in 0 to cTOTAL_ADCS-1 loop
          oMULTI_FIFO(ii).rd <= '0';
        end loop read_gen_1;

        sFifoCountDel <= sFifoCount;
        case (sPeState) is
          when IDLE =>
            sFifoCount <= 0;
            sLenConvWr <= '0';
            if (iMULTI_FIFO(0).empty = '0') then
              read_gen_2 : for ii in 0 to cTOTAL_ADCS-1 loop
                oMULTI_FIFO(ii).rd <= '1';
              end loop read_gen_2;
              sPeState <= ACTIVE;
            else
              sPeState <= IDLE;
            end if;

          when ACTIVE =>
            sLenConvWr <= '1';
            if (sFifoCount < cTOTAL_ADCs-1) then
              sFifoCount <= sFifoCount + 1;
              sPeState   <= ACTIVE;
            else
              sFifoCount <= 0;
              sPeState   <= IDLE;
            end if;

          when others =>
            sFifoCount <= 0;
            sLenConvWr <= '0';
            sPeState   <= IDLE;

        end case;
      else                              --sLenConvOut.full
        sFifoCountDel <= sFifoCount;
        sFifoCount    <= sFifoCount;
        sLenConvWr    <= '0';
        read_gen_3 : for ii in 0 to cTOTAL_ADCS-1 loop
          oMULTI_FIFO(ii).rd <= '0';
        end loop read_gen_3;
      end if;  --iRST
    end if;  --rising_edge
  end process PRIORITY_ENC_STATE;

  sLenConvOut.aempty <= '1';
  sLenConvOut.afull  <= '0';
  --!@brief Dual-port FIFO to go from 16 bits to 32 bits
  LEN_CONVERTER : entity work.parametric_fifo_dp
    generic map(
      pDEPTH        => pFIFODEPTH,
      pWIDTHW       => cADC_DATA_WIDTH,
      pWIDTHR       => pFIFOWIDTH,
      pUSEDW_WIDTHW => ceil_log2(pFIFODEPTH),
      pUSEDW_WIDTHR => ceil_log2(pFIFODEPTH/2),
      pSHOW_AHEAD   => "OFF"
      )
    port map(
      iCLK_W   => iCLK,
      iCLK_R   => iCLK,
      iRST     => iRST,
      --
      oEMPTY_W => open,
      oFULL_W  => sLenConvOut.full,
      oUSEDW_W => sLenConvUsedW,
      iWR_REQ  => sLenConvWr,
      iDATA    => sLenConvData,
      --
      oEMPTY_R => sLenConvOut.empty,
      oFULL_R  => open,
      oUSEDW_R => open,
      iRD_REQ  => sLenConvRd,
      oQ       => sLenConvOut.q
      );

  sLenConvRd     <= (not sLenConvOut.empty) and (not iFASTDATA_AFULL);
  oFASTDATA_DATA <= sLenConvOut.q(pFIFOWIDTH/2-1 downto 0) &
                    sLenConvOut.q(pFIFOWIDTH-1 downto pFIFOWIDTH/2);
  --!@brief Always read the length-converter FIFO and write it to the FDI
  FASTDATAWE_PROC : process (iCLK)
  begin
    if (rising_edge(iCLK)) then
      if (iRST = '1') then
        oFASTDATA_WE <= '0';
      else
        oFASTDATA_WE <= sLenConvRd;
      end if;  --iRST
    end if;  --rising_edge
  end process FASTDATAWE_PROC;

end architecture std;
