--!@file DetectorInterface.vhd
--!@brief Instantiate the Data_Builder.vhd and the multiAdcPlaneInterface.vhd
--!@details Top to interconnect all of the u-strip-related modules
--!@author Mattia Barbanera (mattia.barbanera@infn.it)
--!@author Keida Kanxheri (keida.kanxheri@pg.infn.it)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.basic_package.all;
use work.pgdaqPackage.all;
use work.FOOTpackage.all;

--!@copydoc DetectorInterface.vhd
entity DetectorInterface is
  port (
    iCLK            : in  std_logic;    --!Main clock
    iRST            : in  std_logic;    --!Main reset
    -- Controls
    iEN             : in  std_logic;    --!Enable
    iTRIG           : in  std_logic;    --!Trigger
    oCNT            : out tControlIntfOut;     --!Control signals in output
    iMSD_CONFIG     : in  msd_config;  --!Configuration from the control registers
    -- First FE-ADC chain ports
    oFE0            : out tFpga2FeIntf;        --!Output signals to the FE1
    oADC0           : out tFpga2AdcIntf;       --!Output signals to the ADC1
    -- Second FE-ADC chain ports
    oFE1            : out tFpga2FeIntf;        --!Output signals to the FE2
    oADC1           : out tFpga2AdcIntf;       --!Output signals to the ADC2
    -- ADCs Inputs
    iMULTI_ADC      : in  tMultiAdc2FpgaIntf;  --!Input signals from the ADCs
    -- FastDATA Interface
    oFASTDATA_DATA  : out std_logic_vector(cREG_WIDTH-1 downto 0);
    oFASTDATA_WE    : out std_logic;
    iFASTDATA_AFULL : in  std_logic
    );
end DetectorInterface;

--!@copydoc DetectorInterface.vhd
architecture std of DetectorInterface is
  --Plane interface
  signal sCntOut       : tControlIntfOut;
  signal sCntIn        : tControlIntfIn;
  signal sFeIn         : tFe2FpgaIntf;
  signal sMultiFifoOut : tMultiAdcFifoOut;
  signal sMultiFifoIn  : tMultiAdcFifoIn;

  --Trigger delay
  signal sExtTrigDel     : std_logic;
  signal sExtTrigDelBusy : std_logic;

  --MSD Conifigurations
  signal sHpCfg : std_logic_vector (3 downto 0);

begin

  sFeIn.ShiftOut <= '1';

  sCntIn.en     <= iEN;
  sCntIn.start  <= sExtTrigDel;
  sCntIn.slwClk <= '0';
  sCntIn.slwEn  <= '0';

  oCNT.busy  <= sCntOut.busy or sExtTrigDelBusy;
  oCNT.error <= sCntOut.error;
  oCNT.reset <= sCntOut.reset;
  oCNT.compl <= sCntOut.compl;

  sHpCfg <= iMSD_CONFIG.cfgPlane(3 downto 0);

  --!@brief Delay the external trigger before the FE start
  TRIG_DELAY : delay_timer
    port map(
      iCLK   => iCLK,
      iRST   => iRST,
      iSTART => iTRIG,
      iDELAY => iMSD_CONFIG.trg2Hold,
      oBUSY  => sExtTrigDelBusy,
      oOUT   => sExtTrigDel
      );

  --!@brief Low-level multiple ADCs plane interface
  DETECTOR_INTERFACE : multiAdcPlaneInterface
    generic map (
      pACTIVE_EDGE => "F"               --!"F": falling, "R": rising
      )
    port map (
      iCLK          => iCLK,            --!Main clock
      iRST          => iRST,            --!Main reset
      -- control interface
      oCNT          => sCntOut,
      iCNT          => sCntIn,          --!Control signals in output
      iFE_CLK_DIV   => iMSD_CONFIG.feClkDiv,    --!FE SlowClock divider
      iFE_CLK_DUTY  => iMSD_CONFIG.feClkDuty,   --!FE SlowClock duty cycle
      iADC_CLK_DIV  => iMSD_CONFIG.adcClkDiv,   --!ADC SlowClock divider
      iADC_CLK_DUTY => iMSD_CONFIG.adcClkDuty,  --!ADC SlowClock divider
      iCFG_FE       => sHpCfg,          --!FE configurations
      -- FE interface
      oFE0          => oFE0,            --!Output signals to the FE1
      oFE1          => oFE1,            --!Input signals from the FE1
      iFE           => sFeIn,           --!Input signals from the FE2
      -- ADC interface
      oADC0         => oADC0,           --!Output signals to the ADC2
      oADC1         => oADC1,           --!Output signals to the ADC1
      iMULTI_ADC    => iMULTI_ADC,      --!Input signals from the ADC1
      -- FIFO output interface
      oMULTI_FIFO   => sMultiFifoOut,   --!Output interfaces of MULTI_FIFOs
      iMULTI_FIFO   => sMultiFifoIn     --!Input interface of MULTI_FIFOs
      );

  --!@brief Collects data from the MSD and assembles them in a single packet
  EVENT_BUILDER : priorityEncoder
    generic map (
      pFIFOWIDTH => cREG_WIDTH,         --32
      pFIFODEPTH => cLENCONV_DEPTH
      )
    port map (
      iCLK            => iCLK,
      iRST            => iRST,
      iMULTI_FIFO     => sMultiFifoOut,
      oMULTI_FIFO     => sMultiFifoIn,
      oFASTDATA_DATA  => oFASTDATA_DATA,
      oFASTDATA_WE    => oFASTDATA_WE,
      iFASTDATA_AFULL => iFASTDATA_AFULL
      );

end architecture std;
