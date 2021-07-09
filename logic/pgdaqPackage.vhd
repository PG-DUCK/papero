--!@file pgdaqPackage.vhd
--!@brief Constants, components declarations, and functions
--!@author Mattia Barbanera, mattia.barbanera@infn.it
--!@todo See copydoc documentation to avoid duplications

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
	
	-- Components ----------------------------------------------------------------
	--!Detects rising and falling edges of the input
	component edge_detector is
    generic(
				channels : integer := 1;
				R_vs_F : std_logic := '0'
			  );
	 port(
			iCLK     : in  std_logic;
			iRST     : in  std_logic;
			iD		   : in  std_logic_vector(channels - 1 downto 0);
			oEDGE 	: out std_logic_vector(channels - 1 downto 0)
			);
	end component;
	
	--!Generates a single clock pulse when a button is pressed
	component Key_Pulse_Gen is
	port(KPG_CLK_in		: in std_logic;
		  KPG_DATA_in		: in std_logic_vector(1 downto 0);
		  KPG_DATA_out		: out std_logic_vector(1 downto 0)
		 );
	end component;

end pgdaqPackage;
