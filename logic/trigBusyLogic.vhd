--!@file trigBusyLogic.vhd
--!@brief Trigger and Busy logic
--!@details
--!
--!Generate the trigger signal, wheter from the internal counter or the external
--! pin. Count all the triggers and the trigger occurred when busy is asserted.
--!Generate the busy signal.
--!
--!@author Mattia Barbanera, mattia.barbanera@infn.it
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.basic_package.all;
use work.pgdaqPackage.all;

--!@copydoc trigBusyLogic.vhd
entity trigBusyLogic is
  port(
    iCLK            : in  std_logic;    --!Clock (used at rising edge)
    iRST            : in  std_logic;    --!Synchronous Reset
    iCFG            : in  std_logic_vector(31 downto 0);  --!Configuration
    iEXT_TRIG       : in  std_logic;    --!External Trigger
    iBUSIES         : in  std_logic_vector(7 downto 0);  --!Busy signals from all over the FPGA
    oTRIG           : out std_logic;    --!Output trigger
    oTRIG_ID      : out std_logic_vector(7 downto 0);  --!Trigger type
    oTRIG_COUNT     : out std_logic_vector(31 downto 0);  --!Trigger number
    oTRIG_WHEN_BUSY : out std_logic_vector(7 downto 0);  --!Triggers occurred when system is busy
    oBUSY           : out std_logic     --!Output busy
    );
end entity trigBusyLogic;

--!@copydoc trigBusyLogic.vhd
architecture std of trigBusyLogic is
  signal sExtTrigSynch : std_logic;

  signal sIntTrig       : std_logic;
  signal sIntTrigEn     : std_logic;
  signal sIntTrigPeriod : std_logic_vector(31 downto 0);

  signal sTrig     : std_logic;
  signal sMainTrig : std_logic;
  signal sTrigId : std_logic_vector(7 downto 0);

  signal sBusy : std_logic;

begin
  -- Combinatorial assignments ------------------------------------------------
  oTRIG <= sTrig;
  oBUSY <= sBusy;
  oTRIG_ID <= sTrigId;

  sIntTrigEn     <= iCFG(0);
  sIntTrigPeriod <= iCFG(iCFG'left downto 4) & "0000";

  sTrig     <= sMainTrig and not sBusy;
  sMainTrig <= sIntTrig   when sIntTrigEn else sExtTrigSynch;
  sTrigId <= cTRG_CALIB when sIntTrigEn else cTRG_PHYS;

  sBusy <= unary_and(iBUSIES);
  -----------------------------------------------------------------------------

  --!@brief Synch the trigger to the local clock domain and take the rising edge
  EXT_TRIG_RE : sync_edge
    generic map (
      pSTAGES => 3
      )
    port map (
      iCLK    => iCLK,
      iRST    => iRST,
      iD      => iEXT_TRIG,
      oEDGE_R => sExtTrigSynch
      );

  --!@brief Internal trigger counter
  --!@param[in] iCLK  Clock, used on rising edge
  IntStart_proc : process (iCLK)
  begin
    CLK_IF_TRIG : if (rising_edge(iCLK)) then
      RST_IF_TRIG : if (iRST = '1') then
        sTrigCounter <= (others => '0');
        sIntTrig     <= '0';
      else
        if (sTrigCounter < sIntTrigPeriod) then
          sTrigCounter <= sTrigCounter + sIntTrigEn;
          sIntTrig     <= '0';
        else
          sTrigCounter <= (others => '0');
          sIntTrig     <= '1';
        end if;
      end if RST_IF_TRIG;
    end if CLK_IF_TRIG;
  end process IntStart_proc;

  --!@brief Actual triggers counter
  TRIG_COUNTER : counter
    generic map (
      pOVERLAP  => "Y",
      pBUSWIDTH => oTRIG_COUNT'length
      )
    port map (
      iCLK   => iCLK,
      iRST   => iRST,
      iEN    => sTrig,
      iLOAD  => '0',
      iDATA  => (others => '0'),
      oCOUNT => oTRIG_COUNT,
      oCARRY => open
      );

  --!@brief Count the triggers occurred when busy is asserted
  TRIG_WHEN_BUSY_COUNTER : counter
    generic map (
      pOVERLAP  => "N",
      pBUSWIDTH => oTRIG_WHEN_BUSY'length
      )
    port map (
      iCLK   => iCLK,
      iRST   => iRST,
      iEN    => sMainTrig,
      iLOAD  => '0',
      iDATA  => (others => '0'),
      oCOUNT => oTRIG_WHEN_BUSY,
      oCARRY => open
      );

end architecture std;
