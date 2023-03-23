--! @file basic_package.vhd
--!@brief Basic functions and components
--!@author Mattia Barbanera, mattia.barbanera@infn.it
--!@author Hikmat Nasimi, hikmat.nasimi@pi.infn.it
--!@date 28/01/2020
--!@version 0.1 - 28/01/2020 -

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_unsigned.all;

--!@brief Basic functions and components
package basic_package is
  -- Functions -----------------------------------------------------------------
  --!@brief Converts integer to std_logic_vector(l-1 downto 0)
  --!@param[in] n Integer to convert into std_logic_vector
  --!@param[in] l length of the output std_logic_vector
  --!@return  Unsigned conversion of n into a std_logic_vector(l-1 downto 0)
  function int2slv (n : integer; l : natural) return std_logic_vector;
  --!@brief Converts std_logic_vector to integer
  --!@param[in] n std_logic_vector to converted into integer
  --!@return  Unsigned conversion of n into an integer value
  function slv2int (n : std_logic_vector) return integer;
  --!@brief Returns the minimum power of 2 grater than or equal to n
  --!@param[in] n Natural to approximate with a power of 2
  --!@return  Minimum power of 2 greater than or equal to n
  function min_pow2_gte (n : natural) return natural;
  --!@brief Returns the ceiling of the logarithm to base 2 of the parameter n
  --!@param n Argument of the logarithm
  --!@return  The minimum integer greater than n
  function ceil_log2 (n : natural) return natural;
  --!Reverse the order of the bits of a std_logic_vector
  --!@param[in] a std_logic_vector to invert
  --!@return  std_logic_vector corresponding to 'a' with reverse bits order
  function reverse_vector (a : in std_logic_vector) return std_logic_vector;
  --!@brief Compute the parity bit of an 8-bit data with both polarities
  --!@param[in] p String containing the polarity, "EVEN" or "ODD"
  --!@param[in] d Input 8-bit data
  --!@return  Parity bit of the incoming 8-bit data
  function parity8bit (p : string; d : std_logic_vector(7 downto 0)) return std_logic;
  --!@brief Compute the and between all the elements of a std_logic_vector
  --!@param[in] slv Input std_logic_vector to be reduced to a std_logic
  --!@return  And of all of the slv elements
  function unary_and(slv : in std_logic_vector) return std_logic;
  --!@brief Compute the or between all the elements of a std_logic_vector
  --!@param[in] slv Input std_logic_vector to be reduced to a std_logic
  --!@return  Or of all of the slv elements
  function unary_or(slv : in std_logic_vector) return std_logic;

  -- Components ----------------------------------------------------------------
  -- sync_stage ----------------------------------------------------------------
  component sync_stage is
    generic(pSTAGES  : natural);
    port(iCLK, iRST, iD  : in  std_logic;
      oQ : out std_logic);
  end component;
  -- edge_detector -------------------------------------------------------------
  component edge_detector is
    port(iCLK, iRST, iD  : in  std_logic;
      oQ, oEDGE_R, oEDGE_F  : out std_logic);
  end component;
  ------------------------------------------------------------------------------
  --!@copydoc edge_detector_2.vhd
  component edge_detector_2 is
    generic(
      channels : integer;
      R_vs_F   : std_logic
      );
    port(
      iCLK  : in  std_logic;
      iRST  : in  std_logic;
      iD    : in  std_logic_vector(channels - 1 downto 0);
      oEDGE : out std_logic_vector(channels - 1 downto 0)
      );
  end component;
  -- sync_edge -----------------------------------------------------------------
  component sync_edge is
    generic(pSTAGES  : natural);
    port(iCLK, iRST, iD  : in  std_logic;
      oQ, oEDGE_R, oEDGE_F  : out std_logic);
  end component;
  -- counter -------------------------------------------------------------------
  component counter is
    generic(pOVERLAP   : string;
        pBUSWIDTH  : natural);
    port(iCLK, iEN, iRST, iLOAD  : in  std_logic;
       iDATA   : in  std_logic_vector (pBUSWIDTH-1 downto 0);
       oCOUNT  : out std_logic_vector (pBUSWIDTH-1 downto 0);
       oCARRY  : out std_logic);
  end component;
  -- shift_register ------------------------------------------------------------
  component shift_register is
    generic(pWIDTH  : integer;
        pDIR  : string);
    port(iCLK, iEN, iRST, iLOAD, iSHIFT  : in  std_logic;
       iDATA       : in  std_logic_vector(pWIDTH-1 downto 0);
       oSER_DATA   : out std_logic;
       oPAR_DATA   : out std_logic_vector(pWIDTH-1 downto 0));
  end component;
  -- clock_divider -------------------------------------------------------------
  component clock_divider is
    generic(pPOLARITY : std_logic);
    port(iCLK, iRST, iEN : in  std_logic;
       oCLK_OUT, oCLK_OUT_RISING, oCLK_OUT_FALLING : out std_logic;
       iFREQ_DIV   : in  std_logic_vector(15 downto 0);
	     iDUTY_CYCLE : in  std_logic_vector(15 downto 0));
  end component;
  -- clock_divider_2 -------------------------------------------------------------
  component clock_divider_2 is
    generic(pPOLARITY : std_logic;
      pWIDTH    : natural);
    port(iCLK, iRST, iEN : in  std_logic;
       oCLK_OUT, oCLK_OUT_RISING, oCLK_OUT_FALLING : out std_logic;
       iFREQ_DIV   : in  std_logic_vector(pWIDTH-1 downto 0);
	     iDUTY_CYCLE : in  std_logic_vector(pWIDTH-1 downto 0));
  end component;
  -- parametric_fifo_synch -----------------------------------------------------
  component parametric_fifo_synch is
    generic(pWIDTH, pDEPTH, pUSEDW_WIDTH : natural;
      pAEMPTY_VAL, pAFULL_VAL : natural;
      pSHOW_AHEAD  : string);
    port(iCLK, iRST : in  std_logic;
      oAEMPTY, oEMPTY, oAFULL, oFULL : out std_logic;
      oUSEDW  : out std_logic_vector (pUSEDW_WIDTH-1 downto 0);
      iRD_REQ, iWR_REQ : in  std_logic;
      iDATA   : in  std_logic_vector (pWIDTH-1 downto 0);
      oQ      : out std_logic_vector (pWIDTH-1 downto 0)
      );
  end component;
  -- dp_fifo -------------------------------------------------------------------
  component parametric_fifo_dp is
    generic(pDEPTH, pWIDTHW, pWIDTHR : natural;
      pUSEDW_WIDTHW, pUSEDW_WIDTHR : natural;
      pSHOW_AHEAD : string);
    port(iRST, iCLK_W, iCLK_R : in  std_logic;
      oEMPTY_W, oFULL_W  : out std_logic;
      oUSEDW_W  : out std_logic_vector(pUSEDW_WIDTHW-1 downto 0);
      iWR_REQ   : in  std_logic;
      iDATA     : in  std_logic_vector(pWIDTHW-1 downto 0);
      oEMPTY_R, oFULL_R  : out std_logic;
      oUSEDW_R  : out std_logic_vector(pUSEDW_WIDTHR-1 downto 0);
      iRD_REQ   : in  std_logic;
      oQ        : out std_logic_vector(pWIDTHR-1 downto 0)
      );
  end component;
  -- ALTIOBUF  -----------------------------------------------------------------
  component differential_rx is
    generic(pWIDTH : natural := 1);
    port(iDATAp : in  std_logic_vector (pWIDTH-1 downto 0);
         iDATAn : in  std_logic_vector (pWIDTH-1 downto 0);
         oQ     : out std_logic_vector (pWIDTH-1 downto 0));
   end component;
  -- pulse_generator -----------------------------------------------------------
  component pulse_generator is
    generic(pWIDTH : natural; pPOLARITY : std_logic; pLENGTH   : natural);
    port(iCLK, iRST, iEN  : in  std_logic;
      oPULSE, oPULSE_RISING, oPULSE_FALLING : out std_logic;
      iPERIOD : in  std_logic_vector(pWIDTH-1 downto 0));
  end component;
  -- delay_timer ---------------------------------------------------------------
  component delay_timer is
    generic(pWIDTH : natural);
    port(iCLK, iRST, iSTART  : in  std_logic;
      oBUSY, oOUT : out std_logic;
      iDELAY : in  std_logic_vector(pWIDTH-1 downto 0));
  end component;
  -- count_generator -----------------------------------------------------------
  component countGenerator is
  generic(
    --!Counter width
    pWIDTH    : natural := 32;
    --!Polarity of the pulse
    pPOLARITY : std_logic := '1'
  );
  port(
    --!Main clock
    iCLK          : in  std_logic;
    --!Reset
    iRST          : in  std_logic;
    --!Enable
    iCOUNT        : in  std_logic;
    --!Number of occurences to count
    iOCCURRENCES  : in  std_logic_vector(pWIDTH-1 downto 0);
    --!Length of the pulse
    iLENGTH       : in std_logic_vector(pWIDTH-1 downto 0);
    --!Pulse
    oPULSE        : out std_logic;
    --!Output pulse flag (1 clock-cycle long)
    oPULSE_FLAG   : out std_logic
  );
  end component;
  ------------------------------------------------------------------------------
  --!@copydoc PRBS8.vhd
  component PRBS8 is
    port(iCLK, iRST, iEN  : in  std_logic;
      oPRBS : out std_logic_vector(7 downto 0));
  end component;
  ------------------------------------------------------------------------------
  --!@copydoc PRBS32.vhd
  component PRBS32 is
    port(iCLK, iRST, iEN  : in  std_logic;
      oPRBS : out std_logic_vector(31 downto 0));
  end component;
  ------------------------------------------------------------------------------
  --!@copydoc CRC32.vhd
  component CRC32 is
    generic(pINITIAL_VAL : std_logic_vector(31 downto 0));
    port(iCLK, iRST, iCRC_EN  : in  std_logic;
      iDATA   : in  std_logic_vector (31 downto 0);
      oCRC    : out std_logic_vector (31 downto 0)
      );
  end component;
  ------------------------------------------------------------------------------
  --!@copydoc HighHold.vhd
  component HighHold is
    generic(
      pCH   : integer   := 1
      );
    port(
      iCLK   : in  std_logic;
      iDATA  : in  std_logic_vector(pCH - 1 downto 0);
      oDEL_1 : out std_logic_vector(pCH - 1 downto 0);
      oDEL_2 : out std_logic_vector(pCH - 1 downto 0);
      oDEL_3 : out std_logic_vector(pCH - 1 downto 0);
      oDEL_4 : out std_logic_vector(pCH - 1 downto 0)
      );
  end component;
  

  -- Types ---------------------------------------------------------------------
  --!Counter interface with load, preset, enable and carry;
  --!Variable length record that needs a subtype to define the length
  --!@bug Quartus standard does not support unconstrained records:
  --!https://stackoverflow.com/questions/7925361/passing-generics-to-record-port-types
  --type tCountInterface is record
  --  preset  : std_logic_vector;
  --  count   : std_logic_vector;
  --  en      : std_logic;
  --  load    : std_logic;
  --  carry   : std_logic;
  --end record tCountInterface;

end basic_package;

package body basic_package is
  -- Functions -----------------------------------------------------------------
  function int2slv (n : integer; l : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(n, l));
  end function;   -- function int2slv

  function slv2int (n : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(n));
  end function;   -- function slv2int

  function min_pow2_gte(n : natural) return natural is
  begin
    return natural(2**(ceil(log2(real(n)))));
  end function;   -- function min_pow2_gte

  function ceil_log2(n : natural) return natural is
  begin
    return natural(ceil(log2(real(n))));
  end function;   -- function ceil_log2

  function reverse_vector (a : in std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'reverse_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_vector

  function parity8bit (p : string; d : std_logic_vector(7 downto 0)) return std_logic is
    variable x : std_logic;
  begin
    if p = "ODD" then
      x := not (d(0) xor d(1) xor d(2) xor d(3)
                xor d(4) xor d(5) xor d(6) xor d(7));
    elsif p = "EVEN" then
      x := d(0) xor d(1) xor d(2) xor d(3)
           xor d(4) xor d(5) xor d(6) xor d(7);
    end if;
    return x;
  end function; -- function parity8bit

  function unary_and(slv : in std_logic_vector) return std_logic is
    variable and_v : std_logic := '1';  -- Null input returns '1'
  begin
    for i in slv'range loop
      and_v := and_v and slv(i);
    end loop;
    return and_v;
  end function; -- function unary_and

  function unary_or(slv : in std_logic_vector) return std_logic is
    variable or_v : std_logic := '0';   -- Null input returns '0'
  begin
    for i in slv'range loop
      or_v := or_v or slv(i);
    end loop;
    return or_v;
  end function; -- function unary_or

end package body;
