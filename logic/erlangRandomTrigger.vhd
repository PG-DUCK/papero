--!@file erlangRandomTrigger.vhd
--!@brief pulse generator with Erlang distribution
--!@author Matteo D'Antonio, matteo.dantonio@pg.infn.it
--!@author Mattia Barbanera, mattia.barbanera@infn.it
--!@author Luca Tosti, luca.tosti@pg.infn.it
--!@date 09/05/2022


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.paperoPackage.all;
use work.basic_package.all;


--!@copydoc erlangRandomTrigger.vhd
entity erlangRandomTrigger is
  port(
    -- Main
    iCLK            : in std_logic;                       --!Clock
    iRST            : in std_logic;                       --!Reset
    iEN             : in std_logic;                       --!randomTrigger module enable
    -- External Busy
    iEXT_BUSY       : in std_logic;                       --!Ignore trigger
    -- Trigger Property    
    iTHRSH_LEVEL    : in std_logic_vector(31 downto 0);   --!Threshold to generate trigger by randomTrigger module [0 - 12]
    iPULSE_WIDTH    : in std_logic_vector(31 downto 0);   --!Length of the pulse (in number of iCLK cycles)
    iINT_BUSY       : in std_logic_vector(31 downto 0);   --!Ignore trigger for "N" clock cycles after trigger
    iSHAPE_FACTOR   : in std_logic_vector(31 downto 0);   --!Statistic distribution: K=1 -> Exponential, K>7 -> Gaussian
    iFREQ_DIV       : in std_logic_vector(31 downto 0);   --!Period of periodic (in number of iCLK cycles) and comparison frequency for randomTrigger
    -- Output
    oTRIG           : out std_logic;                      --!Trigger
    oSLOW_CLOCK     : out std_logic                       --!Periodic trigger
    );
end erlangRandomTrigger;


--!@copydoc erlangRandomTrigger.vhd
architecture Behavior of erlangRandomTrigger is  
  --!randomTrigger signals
  signal sThreshold      : std_logic_vector(31 downto 0);   --!Threshold to configure trigger rate
  signal sIntTrig        : std_logic;                       --!Comparison between threshold and pseudoradom value
  signal sTrig           : std_logic;                       --!Output trigger
  signal sSlowClock      : std_logic;                       --!Slow clock for PRBS32
  signal sPulseWidth     : std_logic_vector(31 downto 0);   --!Length of the pulse -1
  
  
begin
  --!Combinatorial assignment
  oTRIG           <= sTrig;
  oSLOW_CLOCK     <= sSlowClock;
  sPulseWidth     <= iPULSE_WIDTH - 1;
  
  
  internal_trigger_generator : randomTrigger
  port map(
      iCLK            => iCLK,
      iRST            => iRST,
      iEN             => iEN,
      iEXT_BUSY       => iEXT_BUSY,
      iTHRESHOLD      => iTHRSH_LEVEL,
      iINT_BUSY       => iINT_BUSY,
      iSHAPER_T_ON    => iPULSE_WIDTH,
      iFREQ_DIV       => iFREQ_DIV,
      oTRIG           => sIntTrig,
      oSLOW_CLOCK     => sSlowClock
      );
  
  trig_count : entity work.countGenerator
  generic map(
    pWIDTH    => 32,
    pPOLARITY => '1'
  )
  port map(
    iCLK          => iCLK,
    iRST          => iRST,
    iCOUNT        => sIntTrig,
    iOCCURRENCES  => iSHAPE_FACTOR,
    iLENGTH       => sPulseWidth,
    oPULSE        => sTrig,
    oPULSE_FLAG   => open
  );
  
 
end Behavior;
