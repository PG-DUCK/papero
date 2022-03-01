--!@file DetectorInterface.vhd
--!@brief Module to interconnect all of the ASTRA-related modules
--!@author Mattia Barbanera (mattia.barbanera@infn.it)
--!@author Matteo D'Antonio (matteo.dantonio@pg.infn.it)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.basic_package.all;
use work.paperoPackage.all;
use work.ASTRApackage.all;

--!@copydoc DetectorInterface.vhd
entity DetectorInterface is
  port (
    iCLK            : in  std_logic;    --!Main clock
    iRST            : in  std_logic;    --!Main reset
    -- Controls
    iEN             : in  std_logic;    --!Enable
    iTRIG           : in  std_logic;    --!Trigger
    oCNT            : out tControlIntfOut;     --!Control signals in output
    iASTRA_CONFIG   : in  astraConfig;  --!Configuration from the control registers
    -- ASTRA and AD7276 output ports
    oFE             : out tFpga2FeIntf;        --!Output signals to ASTRA
    iFE             : in  tFe2FpgaIntf;
    oADC            : out tFpga2AdcIntf;       --!Output signals to AD7276
    -- AD7276 Inputs
    iMULTI_ADC      : in  tMultiAdc2FpgaIntf;  --!Input signals from multiple AD7276s
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
  signal sMultiFifoOut : tMultiAdcFifoOut;
  signal sMultiFifoIn  : tMultiAdcFifoIn;

  --Trigger delay
  signal sExtTrigDel     : std_logic;
  signal sExtTrigDelBusy : std_logic;

begin

  sCntIn.en     <= iEN;
  sCntIn.start  <= sExtTrigDel;
  sCntIn.slwClk <= '0';
  sCntIn.slwEn  <= '0';

  oCNT.busy  <= sCntOut.busy or sExtTrigDelBusy;
  oCNT.error <= sCntOut.error;
  oCNT.reset <= sCntOut.reset;
  oCNT.compl <= sCntOut.compl;

  --!@brief Delay the external trigger before the FE start
  TRIG_DELAY : delay_timer
    port map(
      iCLK   => iCLK,
      iRST   => iRST,
      iSTART => iTRIG,
      iDELAY => iASTRA_CONFIG.trg2Hold,
      oBUSY  => sExtTrigDelBusy,
      oOUT   => sExtTrigDel
      );

  --!@brief ASTRA readout
  DETECTOR_INTERFACE : detectorReadout
  generic map (
    pACTIVE_EDGE => "R"    --!"F": falling, "R": rising
  )
  port map (
    iCLK          => iCLK,            --!Main clock
    iRST          => iRST,            --!Main reset
    -- Controls
    oCNT          => sCntOut,         --!Control signals in output
    iCNT          => sCntIn,          --!Control signals in input
    iFE_CLK_DIV   => iASTRA_CONFIG.feClkDiv,    --!FE SlowClock divider
    iFE_CLK_DUTY  => iASTRA_CONFIG.feClkDuty,   --!FE SlowClock duty cycle
    iADC_CLK_DIV  => iASTRA_CONFIG.adcClkDiv,   --!ADC SlowClock divider
    iADC_CLK_DUTY => iASTRA_CONFIG.adcClkDuty,  --!ADC SlowClock divider
    iADC_DELAY    => iASTRA_CONFIG.adcDelay,
    -- FE interface
    oFE           => oFE,            --!Output signals to ASTRA
    iFE           => iFE,            --!Return signals from ASTRA
    -- ADC interface
    oADC          => oADC,
    iMULTI_ADC    => iMULTI_ADC,      --!Input signals from multiple AD7276
    -- FIFO output interface
    oMULTI_FIFO   => sMultiFifoOut,   --!Output interfaces of MULTI_FIFOs
    iMULTI_FIFO   => sMultiFifoIn     --!Input interface of MULTI_FIFOs
  );


  --!@brief Collects data from the ADCs and assembles them in a single packet
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
