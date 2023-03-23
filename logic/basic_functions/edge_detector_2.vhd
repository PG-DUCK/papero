--!@file edge_detector_2.vhd
--!@brief Detects rising and falling edges of the input
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--!@copydoc edge_detector_2.vhd
entity edge_detector_2 is
  generic(
    channels : integer   := 1;
    R_vs_F   : std_logic := '0'  -- '0': rising edge, '1': falling edge
    );
  port(
    iCLK  : in  std_logic;
    iRST  : in  std_logic;
    iD    : in  std_logic_vector(channels - 1 downto 0);
    oEDGE : out std_logic_vector(channels - 1 downto 0)
    );
end edge_detector_2;

--!@copydoc edge_detector_2.vhd
architecture Behavior of edge_detector_2 is
  constant cZERO  : std_logic_vector(channels - 1 downto 0) := (others => '0');

  signal sInDelay   : std_logic_vector(channels - 1 downto 0) := (others => '0');
  signal sRstVector : std_logic_vector(channels - 1 downto 0) := (others => '0');

begin

  FFD_PROC : process(iCLK)
  begin
    if (rising_edge(iCLK)) then
      sInDelay <= iD;
    end if;
  end process FFD_PROC;

  sRstVector <= cZERO - iRST;

  with R_vs_F select
    oEDGE <= ((iD xor sInDelay) and (not iD)) and (not sRstVector) when '1',
    ((iD xor sInDelay) and iD) and (not sRstVector)                when others;


end Behavior;
