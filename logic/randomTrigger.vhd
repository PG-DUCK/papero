--!@file randomTrigger.vhd
--!@brief generate pulse trigger with pseudorandom delay
--!@details (iFREQ_DIV=iINT_BUSY hypothesys), f_avarage_trigger = (1/(SHAPER_T_ON*20*10^-9 + INT_BUSY*20*10^-9)) * ((2^32 - THRESHOLD)/2^32)
--!@setup 
--!         1) --> select SHAPER_T_ON
--!         2) --> select INT_BUSY
--!         3) --> put FREQ_DIV = INT_BUSY
--!         4) --> select THRESHOLD to get the desidered f_avarage_trigger
--!@author Matteo D'Antonio, matteo.dantonio@pg.infn.it
--!@date 09/05/2022


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.paperoPackage.all;
use work.basic_package.all;


--!@copydoc top_randomTrigger.vhd
entity randomTrigger is
  port(
    iCLK            : in  std_logic;        --!Main clock
    iRST            : in  std_logic;        --!Main reset
    iEN             : in  std_logic;        --!Enable Comparison between iTHRESHOLD and pseudocasual 32-bit value
    -- External Busy
    iEXT_BUSY       : in std_logic;         --!Ignore trigger
    -- Settings
    iTHRESHOLD      : in std_logic_vector(31 downto 0);  --!Threshold to configure trigger rate (low threshold --> High trigger rate)
    iINT_BUSY       : in std_logic_vector(31 downto 0);  --!Ignore trigger for "N" clock cycles after trigger
    iSHAPER_T_ON    : in std_logic_vector(31 downto 0);  --!Length of the pulse trigger
    iFREQ_DIV       : in std_logic_vector(31 downto 0);  --!Slow clock duration (in number of iCLK cycles) to drive PRBS32
    -- Output
    oTRIG           : out std_logic;   --!Trigger
    oSLOW_CLOCK     : out std_logic    --!PRBS32 enable (or trigger with costant frequency)
    );
end randomTrigger;


--!@copydoc top_randomTrigger.vhd
architecture Behavior of randomTrigger is  
  signal sPRBS32Out   : std_logic_vector(31 downto 0); --!PRBS32 output
  signal sBusyCounter : unsigned(31 downto 0);         --!Counter for trigger pause
  signal sIntBusy     : std_logic;  --!Internal Busy
  signal sSlowClock   : std_logic;                     --!Slow clock for PRBS32
  signal sClockEdge   : std_logic;                     --!Slow clock rising edge
  signal sFreqDiv     : std_logic_vector(31 downto 0); --!Slow clock duration
  signal sFreqDivRst  : std_logic;                     --!Slow clock reset
  signal sEval        : std_logic;                     --!'1': Evaluate value wrt threshold
  signal sTriggered   : std_logic;  --!Internal trigger signal
  signal sTrig        : std_logic;  --!Decision wether to assert trigger
  signal sTrigOut     : std_logic;  --!Output trigger
  
begin
  --!Combinatorial assignments
  sFreqDivRst     <= iRST;
  oSLOW_CLOCK     <= sSlowClock;
  
  pseudocasual_32bit_value : PRBS32
    port map(
      iCLK       => iCLK,
      iRST       => iRST,
      iPRBS32_en => sEval,
      oDATA      => sPRBS32Out
      );
      
  slow_clock : clock_divider_2
	generic map(
		pPOLARITY => '1',
    pWIDTH    => 32
		)
	port map(
		iCLK 					    => iCLK,
		iRST 					    => sFreqDivRst,
		iEN 					    => iEN,
		oCLK_OUT 			    => sSlowClock,
		oCLK_OUT_RISING 	=> sClockEdge,
		oCLK_OUT_FALLING 	=> open,
    iFREQ_DIV         => sFreqDiv,
    iDUTY_CYCLE       => iSHAPER_T_ON
		);
  
  --!
  comp : process (iCLK)
  begin
    RE_CLK_IF : if (rising_edge(iCLK)) then
      RST_IF : if (iRST = '1') then
        sTrigOut      <= '0';
        sTrig         <= '0';
        sBusyCounter <= (others => '1');
        sIntBusy <= '0';
      elsif (iEN = '1') then
        --Evaluate if trigger shall be generated, if not busy
        TRIG_EVAL_IF : if (sEval = '1') then
          if (unsigned(sPRBS32Out) > unsigned(iTHRESHOLD)) then
            if (sIntBusy = '0' and iEXT_BUSY = '0') then
              sTrig <= '1';
            else
              sTrig <= '0';
            end if;
          else
            sTrig <= '0';
          end if;
        end if TRIG_EVAL_IF;

        --Generate the internal busy signal
        BUSY_COUNT_IF : if (sTrig = '1' and sTriggered = '1') then
          sIntBusy <= '1';
          sBusyCounter <= (others => '0');
        elsif (sBusyCounter < (unsigned(iINT_BUSY)-1)) then
          sIntBusy <= '1';
          sBusyCounter <= sBusyCounter + 1;
        else
          sIntBusy <= '0';
          --sBusyCounter <= (others => '0');
        end if BUSY_COUNT_IF;

        --Output Trigger
        if (sTrig = '1') then
          sTrigOut <= sSlowClock;
        else
          sTrigOut <= '0';
        end if;

      end if RST_IF;
    end if RE_CLK_IF;
  end process;

  sEval <= sClockEdge;
  --!FFD buffers
  ffd : process (iCLK)
	begin
		if rising_edge(iCLK) then
			sFreqDiv <= iFREQ_DIV; --!iFREQ_DIV buffer
      sTriggered    <= sEval;
		end if;
	end process;
  
  trig_ris_edge : edge_detector
  port map(
    iCLK    => iCLK,
    iRST    => iRST,
    iD      => sTrigOut,
    oQ      => open,
    oEDGE_R => oTRIG,
    oEDGE_F => open
  );
  
 
end Behavior;
