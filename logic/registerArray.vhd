--!@file registerArray.vhd
--!@brief Configuration and telemetry registers
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.basic_package.all;
use work.pgdaqPackage.all;

--!@copydoc registerArray.vhd
entity registerArray is
  port (
    iCLK       : in  std_logic;         --!Main clock
    iRST       : in  std_logic;         --!Main reset
    iCNT       : in  tControlIn;        --!Control input signals
    oCNT       : out tControlOut;       --!Control output flags
    --Register array
    oREG_ARRAY : out tRegArray;         --!Complete Registers array
    iHPS_REG   : in  tRegIntf;          --!HPS interface
    iFPGA_REG  : in  tFpgaRegIntf       --!FPGA interface
    );
end registerArray;

--!@copydoc registerArray.vhd
architecture std of registerArray is
  signal sHpsReg  : tHpsRegArray;
  signal sFpgaReg : tFpgaRegArray;

  signal sRegisters : tRegArray;
begin
  -- Combinatorial assignments -------------------------------------------------
  oREG_ARRAY <= sRegisters;
  HPS_REG_GEN : for hh in 0 to cHPS_REGISTERS-1 generate
    sRegisters(hh) <= sHpsReg(hh);
  end generate HPS_REG_GEN;
  FPGA_REG_GEN : for ff in 0 to cFPGA_REGISTERS-1 generate
    sRegisters(ff+cHPS_REGISTERS) <= sHpsReg(ff);
  end generate FPGA_REG_GEN;
  ------------------------------------------------------------------------------

  --!@brief Update registers' content
  WRITE_PROC : process (iCLK)
  begin
    RCLK_IF : if (rising_edge(iCLK)) then
      RST_IF : if (iRST = '1') then
        sHpsReg  <= cHPS_REG_NULL;
        sFpgaReg <= cFPGA_REG_NULL;
      else
        sHpsReg  <= sHpsReg;            --default value, update if necessary
        sFpgaReg <= sFpgaReg;           --default value, update if necessary

        HPS_WE_IF : if (iHPS_REG.we = '1') then
          sHpsReg(slv2int(iHPS_REG.addr)) <= iHPS_REG.reg;
        end if HPS_WE_IF;

        FPGA_WE_LOOP : for ii in 0 to cFPGA_REGISTERS-1 loop
          if (iFPGA_REG.we(ii) = '1') then
            sFpgaReg(ii) <= iFPGA_REG.regs(ii);
          end if;
        end loop FPGA_WE_LOOP;

      end if RST_IF;
    end if RCLK_IF;
  end process WRITE_PROC;

end architecture std;
