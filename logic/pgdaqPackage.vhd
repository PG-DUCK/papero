--!@file pgdaqPackage.vhd
--!@brief Constants, components declarations, and functions
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.basic_package.all;

--!@copydoc pgdaqPackage.vhd
package pgdaqPackage is
  -- Constants -----------------------------------------------------------------
  constant cREGISTERS : natural := 32;  --!Total number of registers
  constant cREG_ADDR  : natural := ceil_log2(cREGISTERS);  --!Register address width
  constant cREG_WIDTH : natural := 32;  --!Register width

  --Housekeeping reader
  constant cF2H_HK_SOP    : std_logic_vector(31 downto 0) := x"55AADEAD";  --!Start of Packet for the FPGA-2-HPS FSM
  constant cF2H_HK_HDR    : std_logic_vector(31 downto 0) := x"4EADE500";  --!Fixed Header for the FPGA-2-HPS FSM
  constant cF2H_HK_EOP    : std_logic_vector(31 downto 0) := x"600DF00D";  --!End of Packet for the FPGA-2-HPS FSM
  constant cF2H_HK_PERIOD : natural                       := 50000000;  --!Period for internal counter to read HKs; max: 2^32 (85 s)
  constant cF2H_AFULL     : natural                       := 949; --!Almost full threshold for the HK FIFO
  constant cFastF2H_AFULL : natural                       := 4085; --!Almost full threshold for the data FIFO

  -- Types ---------------------------------------------------------------------
  --!Register array; all registers are r/w for HPS and FPGA
  type tRegisterArray is array (0 to cREGISTERS-1) of
    std_logic_vector(cREG_WIDTH-1 downto 0);
  constant cREG_NULL : tRegisterArray := (others => (others => '0'));  --!Null vector for register array

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

  --!CRC32 interface (do not use it as port)
  type tCrc32 is record
    rst  : std_logic;
    en   : std_logic;                      --!Write enable
    data : std_logic_vector(31 downto 0);  --!Input data
    crc  : std_logic_vector(31 downto 0);  --!CRC32 out
  end record tCrc32;

  -- Components ----------------------------------------------------------------
  --!Detects rising and falling edges of the input
  component edge_detector_md is
    generic(
      channels : integer   := 1;
      R_vs_F   : std_logic := '0'
      );
    port(
      iCLK  : in  std_logic;
      iRST  : in  std_logic;
      iD    : in  std_logic_vector(channels - 1 downto 0);
      oEDGE : out std_logic_vector(channels - 1 downto 0)
      );
  end component;

  --!Generates a single clock pulse when a button is pressed
  component Key_Pulse_Gen is
    port(
      KPG_CLK_in   : in  std_logic;
      KPG_DATA_in  : in  std_logic_vector(1 downto 0);
      KPG_DATA_out : out std_logic_vector(1 downto 0)
      );
  end component;

  --!Allunga di un ciclo di clock lo stato "alto" del segnale di "Wait_Request".
  component HighHold is
    generic(
      channels   : integer   := 1;
      BAS_vs_BSS : std_logic := '0'
      );
    port(
      CLK_in      : in  std_logic;
      DATA_in     : in  std_logic_vector(channels - 1 downto 0);
      DELAY_1_out : out std_logic_vector(channels - 1 downto 0);
      DELAY_2_out : out std_logic_vector(channels - 1 downto 0);
      DELAY_3_out : out std_logic_vector(channels - 1 downto 0);
      DELAY_4_out : out std_logic_vector(channels - 1 downto 0)
      );
  end component;

  --!Temporizza l'invio di impulsi sul read_enable della FIFO.
  component WR_Timer is
    port(
      WRT_CLK_in              : in  std_logic;
      WRT_RST_in              : in  std_logic;
      WRT_START_in            : in  std_logic;
      WRT_STANDBY_in          : in  std_logic;
      WRT_STOP_COUNT_VALUE_in : in  std_logic_vector(31 downto 0);
      WRT_out                 : out std_logic;
      WRT_END_COUNT_out       : out std_logic
      );
  end component;

  --!Ricevitore dati di configurazione
  component Config_Receiver is
    port(CR_CLK_in               : in  std_logic;
         CR_RST_in               : in  std_logic;
         CR_FIFO_WAIT_REQUEST_in : in  std_logic;
         CR_DATA_in              : in  std_logic_vector(31 downto 0);
			CR_FWV_in					: in  std_logic_vector(31 downto 0);
         CR_FIFO_READ_EN_out     : out std_logic;
         CR_DATA_out             : out std_logic_vector(31 downto 0);
         CR_ADDRESS_out          : out std_logic_vector(15 downto 0);
         CR_DATA_VALID_out       : out std_logic;
         CR_WARNING_out          : out std_logic_vector(2 downto 0)
         );
  end component;

  --!Banco di registri per i dati di configurazione
  component registerArray is
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
  end component;

  --!Reads the HK and sends them in a packet
  component hkReader is
    generic(
      pFIFO_WIDTH : natural := 32;      --!FIFO data width
      pPARITY     : string  := "EVEN"   --!Parity polarity ("EVEN" or "ODD")
      );
    port (
      iCLK        : in  std_logic;      --!Main clock
      iRST        : in  std_logic;      --!Main reset
      iCNT        : in  tControlIn;     --!Control input signals
      oCNT        : out tControlOut;    --!Control output flags
      iINT_START  : in  std_logic;      --!Enable for the internal start
      --Register array
      iFW_VER     : in  std_logic_vector(31 downto 0);  --!Firmware version from HoG
      iREG_ARRAY  : in  tRegisterArray;                 --!Register array input
      --Output FIFO interface
      oFIFO_DATA  : out std_logic_vector(pFIFO_WIDTH-1 downto 0);  --!Fifo Data in
      oFIFO_WR    : out std_logic;      --!Fifo write-request in
      iFIFO_AFULL : in  std_logic       --!Fifo almost-full flag
      );
  end component;

  --!@copydoc CRC32.vhd
  component CRC32 is
  generic(
    pINITIAL_VAL : std_logic_vector(31 downto 0) := x"FFFFFFFF"
    );
    port (
      iCLK    : in  std_logic;          --!Main Clock (used at rising edge)
      iRST    : in  std_logic;          --!Main Reset (synchronous)
      iCRC_EN : in  std_logic;          --!Enable
      iDATA   : in  std_logic_vector (31 downto 0);  --!Input to compute the CRC on
      oCRC    : out std_logic_vector (31 downto 0)   --!CRC32 of the sequence
      );
  end component;

  --!Interfaccia di comunicazione tra FPGA e HPS
  component HPS_intf is
	 generic(
		AF_HK_FIFO		 : natural := 949									--!Almost_Full threshold for HouseKeeping FIFO
		);
    port(
      iCLK_intf       : in  std_logic;									--!Main clock
      iRST_intf       : in  std_logic;  								--!Main reset
      iFWV_intf       : in  std_logic_vector(31 downto 0);  	--!Main firmware version
      --FIFO H2F
      iFIFO_H2F_WR    : in  std_logic;  								--!Wait Request fifo_RX
      iFIFO_H2F_DATA  : in  std_logic_vector(31 downto 0);  	--!Data RX
      oFIFO_H2F_RE    : out std_logic;  								--!Read Enable
      oFIFO_H2F_WARN  : out std_logic_vector(2 downto 0);   	--!Warning
      --registerArray
      iREGISTER_ARRAY : in  tRegIntf;   								--!Registers interface (for FPGA)
      --FIFO F2H
      iHKREADER_START : in  std_logic;  								--!Start acquisition of hkReader
      iFIFO_F2H_LEVEL : in  std_logic_vector(31 downto 0);		--!Level of HouseKeeping FIFO
      oFIFO_F2H_WE    : out std_logic;  								--!Write Enable
      oFIFO_F2H_DATA  : out std_logic_vector(31 downto 0)   	--!Data TX
      );
  end component;

	--!@copydoc FFD.vhd
	--!Unità di base per realizzare gli shift register dei moduli PRBS
	component FFD is
		port(
			iCLK		: in std_logic;
			iRST		: in std_logic;
			iENABLE	: in std_logic;
			iD			: in std_logic;
			oQ			: out std_logic
			);
	end component;

	--!@copydoc PRBS14.vhd
	--!Modulo per la generazione di dati pseudo-casuali a 14 bit
	component PRBS14 is
		port(
			iCLK			: in std_logic;
			iRST			: in std_logic;
			iPRBS14_en	: in std_logic;
			oDATA			: out std_logic_vector(13 downto 0)
			);
	end component;

	--!@copydoc PRBS32.vhd
	--!Modulo per la generazione di dati pseudo-casuali a 32 bit
	component PRBS32 is
		port(
			iCLK			: in std_logic;
			iRST			: in std_logic;
			iPRBS32_en	: in std_logic;
			oDATA			: out std_logic_vector(31 downto 0)
			);
	end component;

	--!@copydoc Test_Unit.vhd
	--!Unità di test per verificare il funzionamento della sola scheda DAQ
	component Test_Unit is
		port(
			iCLK			: in std_logic;								-- Porta per il clock
			iRST			: in std_logic;								-- Porta per il reset
			iEN			: in std_logic;								-- Porta per l'abilitazione della unità di test
			oDATA			: out std_logic_vector(31 downto 0);	-- Numero binario a 32 bit pseudo-casuale
			oDATA_VALID	: out std_logic								-- Segnale che attesta la validità dei dati in uscita dalla Test_Unit. Se oDATA_VALID=1 --> il valore di "oDATA" è consistente
			);
	end component;

	--!@copydoc FastData_Transmitter.vhd
	--!Trasmettitore dei dati scientifici
	component FastData_Transmitter is
	port(
		  iCLK					: in std_logic;								-- Clock
		  iRST					: in std_logic;								-- Reset
		  -- Enable
		  iEN						: in std_logic;								-- Abilitazione del modulo FastData_Transmitter
		  -- Settings Packet
		  iSettingLength		: in std_logic_vector(31 downto 0);		-- Lunghezza del pacchetto --> Number of 32-bit payload words + 10
		  iFirmwareVersion	: in std_logic_vector(31 downto 0);		-- Versione del firmware in uso
		  iSettingTrigNum		: in std_logic_vector(31 downto 0);		-- Numero di trigger passati dall'ultimo reset
		  iSettingTrigDet		: in std_logic_vector(7 downto 0);		-- Detector associato al trigger attuale
		  iSettingTrigID		: in std_logic_vector(7 downto 0);		-- Identificativo della tipologia di trigger
		  iSettingIntTime		: in std_logic_vector(63 downto 0);		-- Numero di fronti di salita di clock passati dall'ultimo reset e calcolati internamente all'FPGA
		  iSettingExtTime		: in std_logic_vector(63 downto 0);		-- Numero di fronti di salita di clock passati dall'ultimo reset e calcolati esternamente all'FPGA
		  -- Fifo Management
		  iFIFO_DATA			: in std_logic_vector(31 downto 0);		-- "Data_Output" della FIFO a monte del FastData_Transmitter
		  iFIFO_EMPTY			: in std_logic;								-- "Empty" della FIFO a monte del FastData_Transmitter
		  iFIFO_AEMPTY			: in std_logic;								-- "Almost_Empty" della FIFO a monte del FastData_Transmitter. ATTENZIONE!!!--> Per un corretto funzionamento, impostare pAEMPTY_VAL = 2 sulla FIFO a monte del FastData_Transmitter
		  oFIFO_RE				: out std_logic;								-- "Read_Enable" della FIFO a monte del FastData_Transmitter
		  oFIFO_DATA			: out std_logic_vector(31 downto 0);	-- "Data_Inutput" della FIFO a valle del FastData_Transmitter
		  iFIFO_AFULL			: in std_logic;								-- "Almost_Full" della FIFO a valle del FastData_Transmitter
		  oFIFO_WE				: out std_logic;								-- "Write_Enable" della FIFO a valle del FastData_Transmitter
		  -- Output Flag
		  oBUSY					: out std_logic;								-- Il trasmettitore è impegnato in un trasferimento dati. '0'-->ok, '1'-->busy
		  oWARNING				: out std_logic								-- Malfunzionamenti. '0'-->ok, '1'--> errore: la macchina è finita in uno stato non precisato
		 );
	end component;

  -- Functions -----------------------------------------------------------------
  --!@brief Compute the parity bit of an 8-bit data with both polarities
  --!@param[in] p String containing the polarity, "EVEN" or "ODD"
  --!@param[in] d Input 8-bit data
  --!@return  Parity bit of the incoming 8-bit data
  function parity8bit (p : string; d : std_logic_vector(7 downto 0)) return std_logic;

end pgdaqPackage;

--!@copydoc pgdaqPackage.vhd
package body pgdaqPackage is
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
  end function;

end package body;
