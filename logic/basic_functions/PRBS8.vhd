-------------------------------------------------------
--------  PSEUDO RANDOM BINARY SEQUENCE 8bit  --------
-------------------------------------------------------
--!@file PRBS8.vhd
--!@brief Pseudo-Random Binary Sequence, 8 bits
--!@details Linear-Feedback Shift Register;
--!@details Polynomial: x^8 + x^4 + x^3 + x^2 + 1
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.paperoPackage.all;


--!@copydoc PRBS8.vhd
entity PRBS8 is
  port(
    iCLK  : in  std_logic;
    iRST  : in  std_logic;
    iEN   : in  std_logic;
    oPRBS : out std_logic_vector(7 downto 0)
    );
end PRBS8;

--!@copydoc PRBS8.vhd
architecture std of PRBS8 is
  signal sLfsReg : std_logic_vector(7 downto 0);
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

  -- Polynomial: x^8 + x^4 + x^3 + x^2 + 1
  -- Taps: LFSR bits combined to obtain the PRBS;
  --   exponent of the polynomial - 1
  --   8-1, 4-1, 3-1, 2-1
  sTapData <= (sLfsReg(7) xor sLfsReg(3) xor sLfsReg(2) xor sLfsReg(1));

end architecture std;
