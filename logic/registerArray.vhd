--!@file registerArray.vhd
--!@brief Configuration and telemetry registers
--!@author Mattia Barbanera, mattia.barbanera@infn.it
--!@copydoc

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.basic_package.all;
use work.pgdaqPackage.all;

entity registerArray is
  port (
    iCLK       : in  std_logic;       --!Main clock
    iRST       : in  std_logic;       --!Main reset
    iCNT       : in  tControlIn;      --!Control input signals
    oCNT       : out tControlOut;     --!Control output flags
    --Register array
    oREG_ARRAY : out tRegisterArray;  --!Register array, 32-bit cREGISTERS-deep
    iHPS_REG   : in  tRegIntf;        --!HPS interface
    iFPGA_REG  : in  tRegIntf         --!FPGA interface
    );
end registerArray;

architecture std of registerArray is
  signal sRegisters : tRegisterArray;
begin
  -- Combinatorial assignments -------------------------------------------------
  oREG_ARRAY <= sRegisters;
  ------------------------------------------------------------------------------

  --!@brief Update registers' content. HPS has precedence over FPGA.
  WRITE_PROC : process (iCLK)
  begin
    RCLK_IF : if (rising_edge(iCLK)) then
      RST_IF : if (iRST = '1') then
        sRegisters <= cREG_NULL;
      else
        sRegisters <= sRegisters;       --default value, update if necessary
        WE_IF : if (iHPS_REG.we = '1') then
          sRegisters(iHPS_REG.addr) <= iHPS_REG.reg;
        elsif (iFPGA_REG.we = '1') then
          sRegisters(iFPGA_REG.addr) <= iFPGA_REG.reg;
        end if WE_IF;
      end if RST_IF;
    end if RCLK_IF;
  end process WRITE_PROC;

end architecture std;
