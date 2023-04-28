--!@file CRC32.vhd
--!@brief Compute CRC-32 (802.3 type) for 32-bit input
--!@details
--!
--! The usual implementation of the CRC computation with a shift-register is too
--! slow for our case. This is a parallel implementation based on the work of
--! OutputLogic.com. \n
--! The polynomial is: `1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32$`
--!
--!@author Mattia Barbanera, mattia.barbanera@infn.it
-------------------------------------------------------------------------------
-- Copyright (C) 2009 OutputLogic.com
-- This source file may be used and distributed without restriction
-- provided that this copyright statement is not removed from the file
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
--
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

--!@copydoc CRC32.vhd
entity CRC32 is
  generic(
    pINITIAL_VAL : std_logic_vector(31 downto 0) := x"FFFFFFFF"
    );
  port (
    iCLK    : in  std_logic;
    iRST    : in  std_logic;
    iCRC_EN : in  std_logic;
    iDATA   : in  std_logic_vector (31 downto 0);
    oCRC    : out std_logic_vector (31 downto 0)
    );
end CRC32;

--!@copydoc CRC32.vhd
architecture std of CRC32 is
  signal sCrc     : std_logic_vector (31 downto 0) := pINITIAL_VAL;
  signal sCrcNext : std_logic_vector (31 downto 0);

begin
  -- Combinatorial assignments -----------------------------------------------
  oCRC <= sCrc;

  -- Compute in parallel the next value
  sCrcNext(0)  <= sCrc(0) xor sCrc(6) xor sCrc(9) xor sCrc(10) xor sCrc(12) xor sCrc(16) xor sCrc(24) xor sCrc(25) xor sCrc(26) xor sCrc(28) xor sCrc(29) xor sCrc(30) xor sCrc(31) xor iDATA(0) xor iDATA(6) xor iDATA(9) xor iDATA(10) xor iDATA(12) xor iDATA(16) xor iDATA(24) xor iDATA(25) xor iDATA(26) xor iDATA(28) xor iDATA(29) xor iDATA(30) xor iDATA(31);
  sCrcNext(1)  <= sCrc(0) xor sCrc(1) xor sCrc(6) xor sCrc(7) xor sCrc(9) xor sCrc(11) xor sCrc(12) xor sCrc(13) xor sCrc(16) xor sCrc(17) xor sCrc(24) xor sCrc(27) xor sCrc(28) xor iDATA(0) xor iDATA(1) xor iDATA(6) xor iDATA(7) xor iDATA(9) xor iDATA(11) xor iDATA(12) xor iDATA(13) xor iDATA(16) xor iDATA(17) xor iDATA(24) xor iDATA(27) xor iDATA(28);
  sCrcNext(2)  <= sCrc(0) xor sCrc(1) xor sCrc(2) xor sCrc(6) xor sCrc(7) xor sCrc(8) xor sCrc(9) xor sCrc(13) xor sCrc(14) xor sCrc(16) xor sCrc(17) xor sCrc(18) xor sCrc(24) xor sCrc(26) xor sCrc(30) xor sCrc(31) xor iDATA(0) xor iDATA(1) xor iDATA(2) xor iDATA(6) xor iDATA(7) xor iDATA(8) xor iDATA(9) xor iDATA(13) xor iDATA(14) xor iDATA(16) xor iDATA(17) xor iDATA(18) xor iDATA(24) xor iDATA(26) xor iDATA(30) xor iDATA(31);
  sCrcNext(3)  <= sCrc(1) xor sCrc(2) xor sCrc(3) xor sCrc(7) xor sCrc(8) xor sCrc(9) xor sCrc(10) xor sCrc(14) xor sCrc(15) xor sCrc(17) xor sCrc(18) xor sCrc(19) xor sCrc(25) xor sCrc(27) xor sCrc(31) xor iDATA(1) xor iDATA(2) xor iDATA(3) xor iDATA(7) xor iDATA(8) xor iDATA(9) xor iDATA(10) xor iDATA(14) xor iDATA(15) xor iDATA(17) xor iDATA(18) xor iDATA(19) xor iDATA(25) xor iDATA(27) xor iDATA(31);
  sCrcNext(4)  <= sCrc(0) xor sCrc(2) xor sCrc(3) xor sCrc(4) xor sCrc(6) xor sCrc(8) xor sCrc(11) xor sCrc(12) xor sCrc(15) xor sCrc(18) xor sCrc(19) xor sCrc(20) xor sCrc(24) xor sCrc(25) xor sCrc(29) xor sCrc(30) xor sCrc(31) xor iDATA(0) xor iDATA(2) xor iDATA(3) xor iDATA(4) xor iDATA(6) xor iDATA(8) xor iDATA(11) xor iDATA(12) xor iDATA(15) xor iDATA(18) xor iDATA(19) xor iDATA(20) xor iDATA(24) xor iDATA(25) xor iDATA(29) xor iDATA(30) xor iDATA(31);
  sCrcNext(5)  <= sCrc(0) xor sCrc(1) xor sCrc(3) xor sCrc(4) xor sCrc(5) xor sCrc(6) xor sCrc(7) xor sCrc(10) xor sCrc(13) xor sCrc(19) xor sCrc(20) xor sCrc(21) xor sCrc(24) xor sCrc(28) xor sCrc(29) xor iDATA(0) xor iDATA(1) xor iDATA(3) xor iDATA(4) xor iDATA(5) xor iDATA(6) xor iDATA(7) xor iDATA(10) xor iDATA(13) xor iDATA(19) xor iDATA(20) xor iDATA(21) xor iDATA(24) xor iDATA(28) xor iDATA(29);
  sCrcNext(6)  <= sCrc(1) xor sCrc(2) xor sCrc(4) xor sCrc(5) xor sCrc(6) xor sCrc(7) xor sCrc(8) xor sCrc(11) xor sCrc(14) xor sCrc(20) xor sCrc(21) xor sCrc(22) xor sCrc(25) xor sCrc(29) xor sCrc(30) xor iDATA(1) xor iDATA(2) xor iDATA(4) xor iDATA(5) xor iDATA(6) xor iDATA(7) xor iDATA(8) xor iDATA(11) xor iDATA(14) xor iDATA(20) xor iDATA(21) xor iDATA(22) xor iDATA(25) xor iDATA(29) xor iDATA(30);
  sCrcNext(7)  <= sCrc(0) xor sCrc(2) xor sCrc(3) xor sCrc(5) xor sCrc(7) xor sCrc(8) xor sCrc(10) xor sCrc(15) xor sCrc(16) xor sCrc(21) xor sCrc(22) xor sCrc(23) xor sCrc(24) xor sCrc(25) xor sCrc(28) xor sCrc(29) xor iDATA(0) xor iDATA(2) xor iDATA(3) xor iDATA(5) xor iDATA(7) xor iDATA(8) xor iDATA(10) xor iDATA(15) xor iDATA(16) xor iDATA(21) xor iDATA(22) xor iDATA(23) xor iDATA(24) xor iDATA(25) xor iDATA(28) xor iDATA(29);
  sCrcNext(8)  <= sCrc(0) xor sCrc(1) xor sCrc(3) xor sCrc(4) xor sCrc(8) xor sCrc(10) xor sCrc(11) xor sCrc(12) xor sCrc(17) xor sCrc(22) xor sCrc(23) xor sCrc(28) xor sCrc(31) xor iDATA(0) xor iDATA(1) xor iDATA(3) xor iDATA(4) xor iDATA(8) xor iDATA(10) xor iDATA(11) xor iDATA(12) xor iDATA(17) xor iDATA(22) xor iDATA(23) xor iDATA(28) xor iDATA(31);
  sCrcNext(9)  <= sCrc(1) xor sCrc(2) xor sCrc(4) xor sCrc(5) xor sCrc(9) xor sCrc(11) xor sCrc(12) xor sCrc(13) xor sCrc(18) xor sCrc(23) xor sCrc(24) xor sCrc(29) xor iDATA(1) xor iDATA(2) xor iDATA(4) xor iDATA(5) xor iDATA(9) xor iDATA(11) xor iDATA(12) xor iDATA(13) xor iDATA(18) xor iDATA(23) xor iDATA(24) xor iDATA(29);
  sCrcNext(10) <= sCrc(0) xor sCrc(2) xor sCrc(3) xor sCrc(5) xor sCrc(9) xor sCrc(13) xor sCrc(14) xor sCrc(16) xor sCrc(19) xor sCrc(26) xor sCrc(28) xor sCrc(29) xor sCrc(31) xor iDATA(0) xor iDATA(2) xor iDATA(3) xor iDATA(5) xor iDATA(9) xor iDATA(13) xor iDATA(14) xor iDATA(16) xor iDATA(19) xor iDATA(26) xor iDATA(28) xor iDATA(29) xor iDATA(31);
  sCrcNext(11) <= sCrc(0) xor sCrc(1) xor sCrc(3) xor sCrc(4) xor sCrc(9) xor sCrc(12) xor sCrc(14) xor sCrc(15) xor sCrc(16) xor sCrc(17) xor sCrc(20) xor sCrc(24) xor sCrc(25) xor sCrc(26) xor sCrc(27) xor sCrc(28) xor sCrc(31) xor iDATA(0) xor iDATA(1) xor iDATA(3) xor iDATA(4) xor iDATA(9) xor iDATA(12) xor iDATA(14) xor iDATA(15) xor iDATA(16) xor iDATA(17) xor iDATA(20) xor iDATA(24) xor iDATA(25) xor iDATA(26) xor iDATA(27) xor iDATA(28) xor iDATA(31);
  sCrcNext(12) <= sCrc(0) xor sCrc(1) xor sCrc(2) xor sCrc(4) xor sCrc(5) xor sCrc(6) xor sCrc(9) xor sCrc(12) xor sCrc(13) xor sCrc(15) xor sCrc(17) xor sCrc(18) xor sCrc(21) xor sCrc(24) xor sCrc(27) xor sCrc(30) xor sCrc(31) xor iDATA(0) xor iDATA(1) xor iDATA(2) xor iDATA(4) xor iDATA(5) xor iDATA(6) xor iDATA(9) xor iDATA(12) xor iDATA(13) xor iDATA(15) xor iDATA(17) xor iDATA(18) xor iDATA(21) xor iDATA(24) xor iDATA(27) xor iDATA(30) xor iDATA(31);
  sCrcNext(13) <= sCrc(1) xor sCrc(2) xor sCrc(3) xor sCrc(5) xor sCrc(6) xor sCrc(7) xor sCrc(10) xor sCrc(13) xor sCrc(14) xor sCrc(16) xor sCrc(18) xor sCrc(19) xor sCrc(22) xor sCrc(25) xor sCrc(28) xor sCrc(31) xor iDATA(1) xor iDATA(2) xor iDATA(3) xor iDATA(5) xor iDATA(6) xor iDATA(7) xor iDATA(10) xor iDATA(13) xor iDATA(14) xor iDATA(16) xor iDATA(18) xor iDATA(19) xor iDATA(22) xor iDATA(25) xor iDATA(28) xor iDATA(31);
  sCrcNext(14) <= sCrc(2) xor sCrc(3) xor sCrc(4) xor sCrc(6) xor sCrc(7) xor sCrc(8) xor sCrc(11) xor sCrc(14) xor sCrc(15) xor sCrc(17) xor sCrc(19) xor sCrc(20) xor sCrc(23) xor sCrc(26) xor sCrc(29) xor iDATA(2) xor iDATA(3) xor iDATA(4) xor iDATA(6) xor iDATA(7) xor iDATA(8) xor iDATA(11) xor iDATA(14) xor iDATA(15) xor iDATA(17) xor iDATA(19) xor iDATA(20) xor iDATA(23) xor iDATA(26) xor iDATA(29);
  sCrcNext(15) <= sCrc(3) xor sCrc(4) xor sCrc(5) xor sCrc(7) xor sCrc(8) xor sCrc(9) xor sCrc(12) xor sCrc(15) xor sCrc(16) xor sCrc(18) xor sCrc(20) xor sCrc(21) xor sCrc(24) xor sCrc(27) xor sCrc(30) xor iDATA(3) xor iDATA(4) xor iDATA(5) xor iDATA(7) xor iDATA(8) xor iDATA(9) xor iDATA(12) xor iDATA(15) xor iDATA(16) xor iDATA(18) xor iDATA(20) xor iDATA(21) xor iDATA(24) xor iDATA(27) xor iDATA(30);
  sCrcNext(16) <= sCrc(0) xor sCrc(4) xor sCrc(5) xor sCrc(8) xor sCrc(12) xor sCrc(13) xor sCrc(17) xor sCrc(19) xor sCrc(21) xor sCrc(22) xor sCrc(24) xor sCrc(26) xor sCrc(29) xor sCrc(30) xor iDATA(0) xor iDATA(4) xor iDATA(5) xor iDATA(8) xor iDATA(12) xor iDATA(13) xor iDATA(17) xor iDATA(19) xor iDATA(21) xor iDATA(22) xor iDATA(24) xor iDATA(26) xor iDATA(29) xor iDATA(30);
  sCrcNext(17) <= sCrc(1) xor sCrc(5) xor sCrc(6) xor sCrc(9) xor sCrc(13) xor sCrc(14) xor sCrc(18) xor sCrc(20) xor sCrc(22) xor sCrc(23) xor sCrc(25) xor sCrc(27) xor sCrc(30) xor sCrc(31) xor iDATA(1) xor iDATA(5) xor iDATA(6) xor iDATA(9) xor iDATA(13) xor iDATA(14) xor iDATA(18) xor iDATA(20) xor iDATA(22) xor iDATA(23) xor iDATA(25) xor iDATA(27) xor iDATA(30) xor iDATA(31);
  sCrcNext(18) <= sCrc(2) xor sCrc(6) xor sCrc(7) xor sCrc(10) xor sCrc(14) xor sCrc(15) xor sCrc(19) xor sCrc(21) xor sCrc(23) xor sCrc(24) xor sCrc(26) xor sCrc(28) xor sCrc(31) xor iDATA(2) xor iDATA(6) xor iDATA(7) xor iDATA(10) xor iDATA(14) xor iDATA(15) xor iDATA(19) xor iDATA(21) xor iDATA(23) xor iDATA(24) xor iDATA(26) xor iDATA(28) xor iDATA(31);
  sCrcNext(19) <= sCrc(3) xor sCrc(7) xor sCrc(8) xor sCrc(11) xor sCrc(15) xor sCrc(16) xor sCrc(20) xor sCrc(22) xor sCrc(24) xor sCrc(25) xor sCrc(27) xor sCrc(29) xor iDATA(3) xor iDATA(7) xor iDATA(8) xor iDATA(11) xor iDATA(15) xor iDATA(16) xor iDATA(20) xor iDATA(22) xor iDATA(24) xor iDATA(25) xor iDATA(27) xor iDATA(29);
  sCrcNext(20) <= sCrc(4) xor sCrc(8) xor sCrc(9) xor sCrc(12) xor sCrc(16) xor sCrc(17) xor sCrc(21) xor sCrc(23) xor sCrc(25) xor sCrc(26) xor sCrc(28) xor sCrc(30) xor iDATA(4) xor iDATA(8) xor iDATA(9) xor iDATA(12) xor iDATA(16) xor iDATA(17) xor iDATA(21) xor iDATA(23) xor iDATA(25) xor iDATA(26) xor iDATA(28) xor iDATA(30);
  sCrcNext(21) <= sCrc(5) xor sCrc(9) xor sCrc(10) xor sCrc(13) xor sCrc(17) xor sCrc(18) xor sCrc(22) xor sCrc(24) xor sCrc(26) xor sCrc(27) xor sCrc(29) xor sCrc(31) xor iDATA(5) xor iDATA(9) xor iDATA(10) xor iDATA(13) xor iDATA(17) xor iDATA(18) xor iDATA(22) xor iDATA(24) xor iDATA(26) xor iDATA(27) xor iDATA(29) xor iDATA(31);
  sCrcNext(22) <= sCrc(0) xor sCrc(9) xor sCrc(11) xor sCrc(12) xor sCrc(14) xor sCrc(16) xor sCrc(18) xor sCrc(19) xor sCrc(23) xor sCrc(24) xor sCrc(26) xor sCrc(27) xor sCrc(29) xor sCrc(31) xor iDATA(0) xor iDATA(9) xor iDATA(11) xor iDATA(12) xor iDATA(14) xor iDATA(16) xor iDATA(18) xor iDATA(19) xor iDATA(23) xor iDATA(24) xor iDATA(26) xor iDATA(27) xor iDATA(29) xor iDATA(31);
  sCrcNext(23) <= sCrc(0) xor sCrc(1) xor sCrc(6) xor sCrc(9) xor sCrc(13) xor sCrc(15) xor sCrc(16) xor sCrc(17) xor sCrc(19) xor sCrc(20) xor sCrc(26) xor sCrc(27) xor sCrc(29) xor sCrc(31) xor iDATA(0) xor iDATA(1) xor iDATA(6) xor iDATA(9) xor iDATA(13) xor iDATA(15) xor iDATA(16) xor iDATA(17) xor iDATA(19) xor iDATA(20) xor iDATA(26) xor iDATA(27) xor iDATA(29) xor iDATA(31);
  sCrcNext(24) <= sCrc(1) xor sCrc(2) xor sCrc(7) xor sCrc(10) xor sCrc(14) xor sCrc(16) xor sCrc(17) xor sCrc(18) xor sCrc(20) xor sCrc(21) xor sCrc(27) xor sCrc(28) xor sCrc(30) xor iDATA(1) xor iDATA(2) xor iDATA(7) xor iDATA(10) xor iDATA(14) xor iDATA(16) xor iDATA(17) xor iDATA(18) xor iDATA(20) xor iDATA(21) xor iDATA(27) xor iDATA(28) xor iDATA(30);
  sCrcNext(25) <= sCrc(2) xor sCrc(3) xor sCrc(8) xor sCrc(11) xor sCrc(15) xor sCrc(17) xor sCrc(18) xor sCrc(19) xor sCrc(21) xor sCrc(22) xor sCrc(28) xor sCrc(29) xor sCrc(31) xor iDATA(2) xor iDATA(3) xor iDATA(8) xor iDATA(11) xor iDATA(15) xor iDATA(17) xor iDATA(18) xor iDATA(19) xor iDATA(21) xor iDATA(22) xor iDATA(28) xor iDATA(29) xor iDATA(31);
  sCrcNext(26) <= sCrc(0) xor sCrc(3) xor sCrc(4) xor sCrc(6) xor sCrc(10) xor sCrc(18) xor sCrc(19) xor sCrc(20) xor sCrc(22) xor sCrc(23) xor sCrc(24) xor sCrc(25) xor sCrc(26) xor sCrc(28) xor sCrc(31) xor iDATA(0) xor iDATA(3) xor iDATA(4) xor iDATA(6) xor iDATA(10) xor iDATA(18) xor iDATA(19) xor iDATA(20) xor iDATA(22) xor iDATA(23) xor iDATA(24) xor iDATA(25) xor iDATA(26) xor iDATA(28) xor iDATA(31);
  sCrcNext(27) <= sCrc(1) xor sCrc(4) xor sCrc(5) xor sCrc(7) xor sCrc(11) xor sCrc(19) xor sCrc(20) xor sCrc(21) xor sCrc(23) xor sCrc(24) xor sCrc(25) xor sCrc(26) xor sCrc(27) xor sCrc(29) xor iDATA(1) xor iDATA(4) xor iDATA(5) xor iDATA(7) xor iDATA(11) xor iDATA(19) xor iDATA(20) xor iDATA(21) xor iDATA(23) xor iDATA(24) xor iDATA(25) xor iDATA(26) xor iDATA(27) xor iDATA(29);
  sCrcNext(28) <= sCrc(2) xor sCrc(5) xor sCrc(6) xor sCrc(8) xor sCrc(12) xor sCrc(20) xor sCrc(21) xor sCrc(22) xor sCrc(24) xor sCrc(25) xor sCrc(26) xor sCrc(27) xor sCrc(28) xor sCrc(30) xor iDATA(2) xor iDATA(5) xor iDATA(6) xor iDATA(8) xor iDATA(12) xor iDATA(20) xor iDATA(21) xor iDATA(22) xor iDATA(24) xor iDATA(25) xor iDATA(26) xor iDATA(27) xor iDATA(28) xor iDATA(30);
  sCrcNext(29) <= sCrc(3) xor sCrc(6) xor sCrc(7) xor sCrc(9) xor sCrc(13) xor sCrc(21) xor sCrc(22) xor sCrc(23) xor sCrc(25) xor sCrc(26) xor sCrc(27) xor sCrc(28) xor sCrc(29) xor sCrc(31) xor iDATA(3) xor iDATA(6) xor iDATA(7) xor iDATA(9) xor iDATA(13) xor iDATA(21) xor iDATA(22) xor iDATA(23) xor iDATA(25) xor iDATA(26) xor iDATA(27) xor iDATA(28) xor iDATA(29) xor iDATA(31);
  sCrcNext(30) <= sCrc(4) xor sCrc(7) xor sCrc(8) xor sCrc(10) xor sCrc(14) xor sCrc(22) xor sCrc(23) xor sCrc(24) xor sCrc(26) xor sCrc(27) xor sCrc(28) xor sCrc(29) xor sCrc(30) xor iDATA(4) xor iDATA(7) xor iDATA(8) xor iDATA(10) xor iDATA(14) xor iDATA(22) xor iDATA(23) xor iDATA(24) xor iDATA(26) xor iDATA(27) xor iDATA(28) xor iDATA(29) xor iDATA(30);
  sCrcNext(31) <= sCrc(5) xor sCrc(8) xor sCrc(9) xor sCrc(11) xor sCrc(15) xor sCrc(23) xor sCrc(24) xor sCrc(25) xor sCrc(27) xor sCrc(28) xor sCrc(29) xor sCrc(30) xor sCrc(31) xor iDATA(5) xor iDATA(8) xor iDATA(9) xor iDATA(11) xor iDATA(15) xor iDATA(23) xor iDATA(24) xor iDATA(25) xor iDATA(27) xor iDATA(28) xor iDATA(29) xor iDATA(30) xor iDATA(31);

  -- Store the value of the CRC to use it at the next clock cycle
  ffd : process (iCLK, iRST)
  begin
    if (rising_edge(iCLK)) then
      if (iRST = '1') then
        sCrc <= pINITIAL_VAL;
      elsif (iCRC_EN = '1') then
        sCrc <= sCrcNext;
      end if;
    end if;
  end process ffd;

end architecture std;
