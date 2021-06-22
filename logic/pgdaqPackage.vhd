--!@file pgdaqPackage.vhd
--!@brief Constants, components declarations, and functions
--!@author Mattia Barbanera, mattia.barbanera@infn.it
--!@copydoc

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.basic_package.all;

package pgdaqPackage is
  -- Constants -----------------------------------------------------------------
  constant cREGISTERS : natural        := 32;
  constant cREG_ADDR  : natural        := ceil_log2(cREGISTERS);
  constant cREG_WIDTH : natural        := 32;
  constant cREG_NULL  : tRegisterArray := (others => (others => '0'));

  -- Types ---------------------------------------------------------------------
  --!Register array; all registers are r/w for HPS and FPGA
  type tRegisterArray is array (0 to cREGISTERS-1) of
    std_logic_vector(cREG_WIDTH-1 downto 0);

  --!Control interface for a generic block: input signals
  type tControlIn is record
    en    : std_logic;                  --!Enable
    start : std_logic;                  --!Start
  end record tControlIn;

  --!Control interface for a generic block: output signals
  type tControlOut is record
    busy  : std_logic;                  --!Busy flag
    error : std_logic;                  --!Error flag
    reset : std_logic;                  --!Resetting flag
    compl : std_logic;                  --!completion of task
  end record tControlOut;

  --!Registers interface
  type tRegIntf is record
    reg  : std_logic_vector(cREG_WIDTH-1 downto 0);  --!Content to be written
    addr : std_logic_vector(cREG_ADDR-1 downto 0);   --!Address to be updated
    we   : std_logic;                                --!Write enable
  end record tRegIntf;

end pgdaqPackage;
