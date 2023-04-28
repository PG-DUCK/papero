--!@file WR_Timer.vhd
--!@brief Pulses generator to read one paylod from the FIFO
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

use work.paperoPackage.all;
use work.basic_package.all;

--!@copydoc WR_Timer.vhd
entity WR_Timer is
  port(
    iCLK        : in  std_logic;
    iRST        : in  std_logic;
    iSTART      : in  std_logic;  -- "payload_enable"; '1' only if PS=ACQUISITION
    iSTANDBY    : in  std_logic;  -- Wait_Request of FIFO. Wait_Request=1 --> empty FIFO
    iLEN        : in  std_logic_vector(31 downto 0);  -- Payload Length + 5
    oWRT        : out std_logic;  -- Read_Enable pulses to acquire payload from FIFO
    oEND_COUNT  : out std_logic   -- End of packet
    );
end WR_Timer;

--!@copydoc WR_Timer.vhd
architecture Behavior of WR_Timer is
  signal sPayloadLen  : std_logic_vector(31 downto 0);
  signal sPulses      : std_logic;
  signal sTimerEn     : std_logic;
  signal sStartRE     : std_logic;  -- Rising-edge of iSTART
  
  signal sOutPulsesCnt  : std_logic_vector(31 downto 0);  -- Contatore del numero di impulsi inviati in uscita
  signal sPulseCounter  : std_logic_vector(31 downto 0);  -- Contatore della parità degli impulsi. Se sPulseCounter=1-->siamo su un impulso dispari

begin

  oWRT <= sPulses and (not iRST) and iSTART;  -- Combinatorial gate: stop if "RESET" or just exit from "ACQUISITION" state

  rise_edge_implementation : edge_detector_2
    generic map(
      channels => 1,
      R_vs_F   => '0'
      )
    port map(
      iCLK     => iCLK,
      iRST     => iRST,
      iD(0)    => iSTART,
      oEDGE(0) => sStartRE
      );


  -- Timer control logic
  Timer_On_Off_proc : process (iCLK)
  begin
    if rising_edge(iCLK) then
      if ((iRST = '1') or (iSTART = '0')) then -- "RESET" and not "ACQUISITION"
        sTimerEn    <= '0';
        sPayloadLen <= (others => '0');
        oEND_COUNT  <= '0';
      elsif (sStartRE = '1') then -- Just entered in "ACQUISITION"
        sTimerEn    <= '1';
        sPayloadLen <= iLEN - 5;
        oEND_COUNT  <= '0';
      elsif (sOutPulsesCnt + 1 > sPayloadLen) then -- All pulses sent
        sTimerEn    <= '0';
        oEND_COUNT  <= '1';
      end if;
    end if;
  end process;

  counter_PWM_proc : process (iCLK)
  begin
    if rising_edge(iCLK) then
      if ((iRST = '1') or (sStartRE = '1')) then -- "RESET" and just entered in "ACQUISITION"
        sPulseCounter <= (others => '0');  -- Zeroing of the parity counter
      elsif ((sTimerEn = '1') and (iSTANDBY = '0')) then
        if (sPulseCounter < 1) then  -- Timer on, wait_request off, last Read_Enable even
          sPulseCounter <= sPulseCounter + 1; -- Increment parity counter
        else
          sPulseCounter <= (others => '0');
        end if;
      else
        sPulseCounter <= (others => '0');
      end if;
    end if;
  end process;

  sPulses_proc : process (iCLK)
  begin
    if rising_edge(iCLK) then
      if ((iRST = '1') or (sStartRE = '1')) then -- "RESET" and just entered in "ACQUISITION"
        sPulses       <= '0'; -- Output low and zero pulses
        sOutPulsesCnt <= (others => '0');
      elsif ((sTimerEn = '1') and (iSTANDBY = '0')) then
        if (sPulseCounter < 1) then  -- Timer on, wait_request off, last Read_Enable even
          sPulses       <= '1'; -- Output high and increment parity counter
          sOutPulsesCnt <= sOutPulsesCnt + 1;
        else
          sPulses <= '0';  -- Output low, zero the counter of Read_Enable pulses 
        end if;
      else
        sPulses <= '0';
      end if;
    end if;
  end process;

end Behavior;
