--!@file PRBS32.vhd
--!@brief Pseudo-Random Binary Sequence, 32 bits
--!@details Linear-Feedback Shift Register;
--!@details Polynomial: x^32 + x^7 + x^5 + x^3 + x^2 + x^1 + 1
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.paperoPackage.all;


--!@copydoc PRBS32.vhd
entity PRBS32 is
  port(
    iCLK  : in  std_logic;
    iRST  : in  std_logic;
    iEN   : in  std_logic;
    oPRBS : out std_logic_vector(31 downto 0)
    );
end PRBS32;

--!@copydoc PRBS32.vhd
architecture std of PRBS32 is
  signal sLfsReg : std_logic_vector(31 downto 0);
  signal sTapData : std_logic;

begin

  oPRBS <= sLfsReg;

  FFD_PROC : process (iCLK)
  begin
    if rising_edge(iCLK) then
      if (iRST = '1') then
        sLfsReg <= (others => '1');
      elsif (iEN = '1') then
        sLfsReg(0) <= sTapData;
        sLfsReg(sLfsReg'left downto 1) <= sLfsReg(sLfsReg'left-1 downto 0);
      end if;
    end if;
  end process FFD_PROC;


  -- Polynomial: x^32 + x^7 + x^5 + x^3 + x^2 + x^1 + 1
  -- Taps: LFSR bits combined to obtain the PRBS;
  --   exponent of the polynomial - 1
  --   32-1, 7-1, 5-1, 3-1, 2-1, 1-1
  sTapData <= (sLfsReg(31) xor sLfsReg(6) xor sLfsReg(4) xor sLfsReg(2)xor sLfsReg(1) xor sLfsReg(0));

end architecture std;
