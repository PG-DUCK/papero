--!@file testPlaneChecker.vhd
--!@brief Check test patterns and flag errors
--!
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.basic_package.all;

--!@copydoc testPlaneChecker.vhd
entity testPlaneChecker is
  generic (
    pWIDTH : natural;
    pCHANNELS : natural
    );
  port (
    iCLK  : in  std_logic;      --!Main clock
    iRST  : in  std_logic;      --!Main reset
    --Pattern input
    iDATA : in std_logic_vector(pWIDTH-1 downto 0); --!testPlane input
    iWR   : in std_logic; --!Write Request
    --Error output
    oERR  : out std_logic --!Error flag in output
    );
end testPlaneChecker;

--!@copydoc testPlaneChecker.vhd
architecture std of testPlaneChecker is
  signal sErr : std_logic := '0';
  signal sRef : std_logic_vector(ceil_log2(pCHANNELS)-1 downto 0);
  signal sAdd : natural := 2;

  signal sHDHig : std_logic_vector(pWIDTH/2-1 downto 0);
  signal sHDLow : std_logic_vector(pWIDTH/2-1 downto 0);

begin
  -- Combinatorial assignments -------------------------------------------------
  oERR   <= sErr;
  sHDHig <= iDATA(pWIDTH-1   downto pWIDTH/2);
  sHDLow <= iDATA(pWIDTH/2-1 downto 0);
  ------------------------------------------------------------------------------

  PROTOGEN_proc : process(iCLK)
  begin
    if (rising_edge(iCLK)) then
      if (iRST = '1') then
        sErr   <= '0';
        sRef   <= (others => '0');
      elsif (iWR = '1') then
        if ((sRef < pCHANNELS-2)) then
          if ((sHDHig /= sRef+'1') or (sHDLow /= sRef)) then
            sErr <= '1';
          end if;
          sRef <= sRef + int2slv(2, sRef'length);
        else
          sRef <= (others => '0');
        end if;

      end if;
    end if;
  end process PROTOGEN_proc;

end architecture std;
