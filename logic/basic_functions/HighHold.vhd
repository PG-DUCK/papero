--!@file HighHold.vhd
--!@brief Extend signal values
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

--!@copydoc HighHold.vhd
entity HighHold is
  generic(
    pCH   : integer   := 1
    );
  port(
    iCLK    : in  std_logic;
    iDATA   : in  std_logic_vector(pCH - 1 downto 0);  -- Input to be delayed
    oDEL_1  : out std_logic_vector(pCH - 1 downto 0);  -- 1 clock cycle(s) hold
    oDEL_2  : out std_logic_vector(pCH - 1 downto 0);  -- 2 clock cycle(s) hold
    oDEL_3  : out std_logic_vector(pCH - 1 downto 0);  -- 3 clock cycle(s) hold
    oDEL_4  : out std_logic_vector(pCH - 1 downto 0)   -- 4 clock cycle(s) hold
    );
end HighHold;

--!@copydoc HighHold.vhd
architecture Behavior of HighHold is

  signal sDelay0 : std_logic_vector(pCH - 1 downto 0) := (others => '0');
  signal sDelay1 : std_logic_vector(pCH - 1 downto 0) := (others => '0');
  signal sDelay2 : std_logic_vector(pCH - 1 downto 0) := (others => '0');
  signal sDelay3 : std_logic_vector(pCH - 1 downto 0) := (others => '0');
  signal sDelay4 : std_logic_vector(pCH - 1 downto 0) := (others => '0');

begin
  sDelay0 <= iDATA;

  FFD_1 : process (iCLK)  -- Flip-Flop D
  begin
    if rising_edge(iCLK) then
      sDelay1 <= sDelay0;
      sDelay2 <= sDelay1;
      sDelay3 <= sDelay2;
      sDelay4 <= sDelay3;
    end if;
  end process;


  oDEL_1 <= sDelay0 or sDelay1;
  oDEL_2 <= sDelay0 or sDelay1 or sDelay2;
  oDEL_3 <= sDelay0 or sDelay1 or sDelay2 or sDelay3;
  oDEL_4 <= sDelay0 or sDelay1 or sDelay2 or sDelay3 or sDelay4;


end Behavior;
