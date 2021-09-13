--!@file TdaqModule.vhd
--!brief Wrapper for all of the generic trigger and data acquisition modules
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.basic_package.all;
use work.pgdaqPackage.all;

--!@copydoc TdaqModule.vhd
entity TdaqModule is
  generic(
    pFDI_WIDTH : natural := 32;
    pFDI_DEPTH  : natural := 4096;
    pGW_VER    : std_logic_vector(31 downto 0)
  );
  port (
    iCLK        : in  std_logic;  --!Main clock on the FPGA side
    iRST        : in  std_logic;  --!Main reset on the FPGA side
    --Register Array
    iRST_REG    : in  std_logic;  --!Reset of the Register array
    oREG_ARRAY  : out tRegArray;  --!Complete Registers array
    iINT_TS     : in  std_logic_vector(63 downto 0); --!Internal timestamp
    iEXT_TS     : in  std_logic_vector(63 downto 0); --!External timestamp
    --Trigger and Busy logic
    iEXT_TRIG       : in  std_logic;
    oTRIG           : out std_logic;
    oBUSY           : out std_logic;
    iTRG_BUSIES_AND : in  std_logic_vector(7 downto 0);
    iTRG_BUSIES_OR  : in  std_logic_vector(7 downto 0);
    --H2F
		iFIFO_H2F_EMPTY		: in  std_logic; --!FIFO H2F Wait Request
		iFIFO_H2F_DATA		: in  std_logic_vector(31 downto 0);	--!FIFO H2F q
		oFIFO_H2F_RE		: out std_logic;  --!FIFO H2F Read Request
		--F2H
		iFIFO_F2H_AFULL : in  std_logic;  --!FIFO F2H Almost full
		oFIFO_F2H_WE		: out std_logic;	--!FIFO F2H Write Request
		oFIFO_F2H_DATA		: out std_logic_vector(31 downto 0);  --!FIFO F2H data
		--F2H FAST
		iFIFO_F2HFAST_AFULL : in  std_logic;  --!FIFO F2H FAST Almost full
		oFIFO_F2HFAST_WE		: out std_logic;  --!FIFO F2H Write Request
		oFIFO_F2HFAST_DATA		: out std_logic_vector(31 downto 0) --!FIFO F2H data
    );
end entity TdaqModule;

--!@copydoc TdaqModule.vhd
architecture std of TdaqModule is
  -- HPS interface
  signal sHkRdrCnt : tControlIn;
  signal sHkRdrIntstart : std_logic;
  signal sF2hFastCnt : tControlIn;
  signal sF2hFastMetaData : tF2hMetadata;
  signal sF2hFastBusy : std_logic;
  signal sF2hFastWarning : std_logic;
  signal sCrWarning : std_logic_vector(2 downto 0);

  -- Register Array
  signal sRegArray : tRegArray;
  signal sRegConfigRx	 : tRegIntf;
  signal sFpgaRegIntf   : tFpgaRegIntf;
  signal sRegWarning : std_logic_vector(31 downto 0);
  signal sRegBusy : std_logic_vector(31 downto 0);

  -- Fast-Data Input FIFO
  signal sFdiFifoIn : tFifo32In;
  signal sFdiFifoOut : tFifo32Out;
  signal sFdiFifoUsedW : std_logic_vector(ceil_log2(pFDI_DEPTH)-1 downto 0);

  -- Trigger and Busy logic
  signal sTrigId    : std_logic_vector(7 downto 0);
  signal sTrigCount : std_logic_vector(31 downto 0);
  signal sTrigWhenBusyCount : std_logic_vector(7 downto 0);
  signal sTrigCfg : std_logic_vector(31 downto 0);
  signal sBusy : std_logic;

begin
  --Temporary assignments
  sHkRdrCnt         <= ('1','1');
  sHkRdrIntstart  <= '1';
  sF2hFastCnt <= ('1','1');
  sF2hFastMetaData.pktLen   <= x"0000006e";
  sF2hFastMetaData.trigNum  <= x"00000001";
  sF2hFastMetaData.detId    <= x"23";
  sF2hFastMetaData.trigId   <= x"45";
  sF2hFastMetaData.intTime  <= x"1a1a1a1a1b1b1b1b";
  sF2hFastMetaData.extTime  <= x"2a2a2a2a2b2b2b2b";
  sTrigCfg <= x"FFFFFFF1";

  oBUSY <= sBusy;

  --!@brief FPGA-HPS communication interfaces
  --!@todo connect sCrWarning, sF2hFastBusy, sF2hFastWarning
  HPS_interfaces : HPS_intf
    generic map(
      pGW_VER => pGW_VER
    )
    port map(
      iCLK                => iCLK,
      iRST                => iRST,
      --
      oCR_WARNING         => sCrWarning,
      --
      iHK_RDR_CNT         => sHkRdrCnt,
      iHK_RDR_INT_START   => sHkRdrIntstart,
      --
      iF2HFAST_CNT        => sF2hFastCnt,
      iF2HFAST_METADATA   => sF2hFastMetaData,
      oF2HFAST_BUSY       => sF2hFastBusy,
      oF2HFAST_WARNING    => sF2hFastWarning,
      --
      iREG_ARRAY          => sRegArray,
      oREG_CONFIG_RX      => sRegConfigRx,
      --
      iFDI_FIFO           => sFdiFifoOut,
      oFDI_FIFO_RD        => sFdiFifoIn.rd,
      --
      iFIFO_H2F_EMPTY     => iFIFO_H2F_EMPTY,
      iFIFO_H2F_DATA      => iFIFO_H2F_DATA,
      oFIFO_H2F_RE        => oFIFO_H2F_RE,
      --
      iFIFO_F2H_AFULL     => iFIFO_F2H_AFULL,
      oFIFO_F2H_WE        => oFIFO_F2H_WE,
      oFIFO_F2H_DATA      => oFIFO_F2H_DATA,
      --
      iFIFO_F2HFAST_AFULL => iFIFO_F2HFAST_AFULL,
      oFIFO_F2HFAST_WE    => oFIFO_F2HFAST_WE,
      oFIFO_F2HFAST_DATA  => oFIFO_F2HFAST_DATA
      );

  --!@brief Bank of registers, always enabled
  Config_Registers : registerArray
  port map(
  			iCLK       => iCLK,
  			iRST       => iRST_REG,
  			iCNT       => ('1', '1'),
  			oCNT       => open,
  			oREG_ARRAY => sRegArray,
  			iHPS_REG   => sRegConfigRx,
  			iFPGA_REG  => sFpgaRegIntf
  			);

  --!@brief PRBS-32 generator
  PRBS_generator : Test_Unit
    port map(
      iCLK        => iCLK,
      iRST        => iRST,
      iEN         => not sFdiFifoOut.aFull,
      oDATA       => sFdiFifoIn.data,
      oDATA_VALID => sFdiFifoIn.wr
      );

  --!@brief FIFO in input of the fast data tx
  fast_data_input_FDI_fifo : parametric_fifo_synch
    generic map(
      pWIDTH       => pFDI_WIDTH,
      pDEPTH       => pFDI_DEPTH,
      pUSEDW_WIDTH => ceil_log2(pFDI_DEPTH),
      pAEMPTY_VAL  => 2,
      pAFULL_VAL   => pFDI_DEPTH-10,
      pSHOW_AHEAD  => "OFF"
      )
    port map(
      iCLK    => iCLK,
      iRST    => iRST,
      oUSEDW  => sFdiFifoUsedW,
      -- Write interface
      oAFULL  => sFdiFifoOut.aFull,
      oFULL   => sFdiFifoOut.full,
      iWR_REQ => sFdiFifoIn.wr,
      iDATA   => sFdiFifoIn.data,
      -- Read interface
      oAEMPTY => sFdiFifoOut.aEmpty,
      oEMPTY  => sFdiFifoOut.Empty,
      iRD_REQ => sFdiFifoIn.rd,
      oQ      => sFdiFifoOut.q
      );

  --!@brief Trigger and busy logic
  Trig_Busy : trigBusyLogic
    port map (
      iCLK            => iCLK,
      iRST            => iRST,
      iCFG            => sTrigCfg,
      iEXT_TRIG       => iEXT_TRIG,
      iBUSIES_AND     => iTRG_BUSIES_AND,
      iBUSIES_OR      => iTRG_BUSIES_OR,
      oTRIG           => oTRIG,
      oTRIG_ID        => sTrigId, --sF2hFastMetaData.trigId
      oTRIG_COUNT     => sTrigCount, --sF2hFastMetaData.trigNum
      oTRIG_WHEN_BUSY => sTrigWhenBusyCount,
      oBUSY           => oBUSY
      );

  -- FPGA-registers mapping
  sFpgaRegIntf.regs(rGW_VER) <= pGW_VER;
  sFpgaRegIntf.we(rGW_VER)   <= '1';
  sFpgaRegIntf.regs(rINT_TS_MSB) <= iINT_TS(63 downto 32);
  sFpgaRegIntf.we(rINT_TS_MSB)   <= '1';
  sFpgaRegIntf.regs(rINT_TS_LSB) <= iINT_TS(31 downto 0);
  sFpgaRegIntf.we(rINT_TS_LSB)   <= '1';
  sFpgaRegIntf.regs(rEXT_TS_MSB) <= iEXT_TS(63 downto 32);
  sFpgaRegIntf.we(rEXT_TS_MSB)   <= '1';
  sFpgaRegIntf.regs(rEXT_TS_LSB) <= iEXT_TS(31 downto 0);
  sFpgaRegIntf.we(rEXT_TS_LSB)   <= '1';
  sFpgaRegIntf.regs(rWARNING) <= sRegWarning;
  sFpgaRegIntf.we(rWARNING)   <= '1';
  sFpgaRegIntf.regs(rBUSY) <= sRegBusy;
  sFpgaRegIntf.we(rBUSY)   <= '1';
  sFpgaRegIntf.regs(rTRG_COUNT) <= sTrigCount;
  sFpgaRegIntf.we(rTRG_COUNT)   <= '1';
  sFpgaRegIntf.regs(rFDI_FIFO_NUMWORD) <= sFdiFifoUsedW;
  sFpgaRegIntf.we(rFDI_FIFO_NUMWORD)   <= '1';
  sFpgaRegIntf.regs(9) <= (others => '0');
  sFpgaRegIntf.we(9)   <= '0';
  sFpgaRegIntf.regs(10) <= (others => '0');
  sFpgaRegIntf.we(10)   <= '0';
  sFpgaRegIntf.regs(11) <= (others => '0');
  sFpgaRegIntf.we(11)   <= '0';
  sFpgaRegIntf.regs(12) <= (others => '0');
  sFpgaRegIntf.we(12)   <= '0';
  sFpgaRegIntf.regs(13) <= (others => '0');
  sFpgaRegIntf.we(13)   <= '0';
  sFpgaRegIntf.regs(14) <= (others => '0');
  sFpgaRegIntf.we(14)   <= '0';
  sFpgaRegIntf.regs(rPIUMONE) <= x"c1a0c1a0";
  sFpgaRegIntf.we(rPIUMONE)   <= '1';

  sRegWarning <= x"0000" & sF2hFastWarning & x"0" & sCrWarning;
  sRegBusy <= sBusy & "000" & iTRG_BUSIES_AND & iTRG_BUSIES_OR & sF2hFastBusy
              & iFIFO_F2H_AFULL & iFIFO_F2HFAST_AFULL
              & sFdiFifoOut.aFull & sTrigWhenBusyCount;

end architecture std;
