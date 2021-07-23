--!@file HPS_intf.vhd
--!brief Accorpamento dei moduli Config_Receiver, registerArray e hkReader
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.pgdaqPackage.all;

--!@copydoc HPS_intf.vhd
entity HPS_intf is
	generic(
		AF_HK_FIFO	 		: natural := 949										--!Almost_Full threshold for HouseKeeping FIFO
		);																			-- AF_HK_FIFO = 1021 - (6 + 32*2) - 2 = 949
	port(
		iCLK_intf			: in  std_logic;								--!Main clock
		iRST_intf			: in  std_logic;								--!Main reset
		iFWV_intf 		   : in  std_logic_vector(31 downto 0);	--!Main firmware version
		--FIFO H2F
		iFIFO_H2F_WR		: in  std_logic;								--!Wait Request fifo_RX
		iFIFO_H2F_DATA		: in  std_logic_vector(31 downto 0);	--!Data RX
		oFIFO_H2F_RE		: out std_logic;								--!Read Enable
		oFIFO_H2F_WARN		: out std_logic_vector(2 downto 0);		--!Warning
		--registerArray
		iREGISTER_ARRAY	: in tRegIntf;									--!Registers interface (for FPGA)
		--FIFO F2H
		iHKREADER_START	: in  std_logic;								--!Start acquisition of hkReader
		iFIFO_F2H_LEVEL	: in	std_logic_vector(31 downto 0);	--!Level of HouseKeeping FIFO
		oFIFO_F2H_WE		: out std_logic;								--!Write Enable
		oFIFO_F2H_DATA		: out std_logic_vector(31 downto 0)		--!Data TX
		);
end HPS_intf;

--!@copydoc Config_Receiver.vhd
architecture Behavior of HPS_intf is

-- Set di segnali di interconnessione tra i moduli istanziati
signal address_rx			 : std_logic_vector(15 downto 0);	-- Indirizzo del registro in cui memorizzare il dato di configurazione
signal warning_rx			 : std_logic_vector(2 downto 0);		-- Segnale di avviso dei malfunzionamenti del Config_Receiver. "000"-->ok, "001"-->errore sui bit di parità, "010"-->errore nella struttura del pacchetto (word missed), "100"-->errore generico (ad esempio se la macchina finisce in uno stato non precisato).
signal receiver_output	 : tRegIntf;								-- Interfaccia d'uscita del Config_Receiver (dati+controllo).
signal sRegArray			 : tRegisterArray;						-- Array di dati in uscita dal registerArray.
signal sFifoAfull			 : std_logic;								-- Segnale di "Almost Full della FIFO".

begin
	-- Ricevitore dati di configurazione
	FIFO_h2f_receiver : Config_Receiver
	port map(
				CR_CLK_in 						=> iCLK_intf,
				CR_RST_in 						=> iRST_intf,
				CR_FIFO_WAIT_REQUEST_in 	=> iFIFO_H2F_WR,
				CR_DATA_in 						=> iFIFO_H2F_DATA,
				CR_FWV_in 						=> iFWV_intf,
				CR_FIFO_READ_EN_out			=> oFIFO_H2F_RE,
				CR_DATA_out	 					=> receiver_output.reg,
				CR_ADDRESS_out					=> address_rx,
				CR_DATA_VALID_out				=> receiver_output.we,
				CR_WARNING_out 				=> oFIFO_H2F_WARN
			  );
	receiver_output.addr <= address_rx(cREG_ADDR - 1 downto 0);
	
	-- Banco di registri per i dati di configurazione
	Config_Registers : registerArray
	port map(
				iCLK       => iCLK_intf,
				iRST       => iRST_intf,
				iCNT       => ('1', '1'),
				oCNT       => open,
				oREG_ARRAY => sRegArray,
				iHPS_REG   => receiver_output,
				iFPGA_REG  => iREGISTER_ARRAY
				);
	
	-- Trasmettitore dati di telemetria
	FIFO_f2h_transmitter : hkReader
	port map(
				iCLK        => iCLK_intf,
				iRST        => iRST_intf,
				iCNT        => ('1', '0'),
				oCNT        => open,
				iINT_START  => iHKREADER_START,
				iFW_VER     => iFWV_intf,
				iREG_ARRAY  => sRegArray,
				oFIFO_DATA  => oFIFO_F2H_DATA,
				oFIFO_WR    => oFIFO_F2H_WE,
				iFIFO_AFULL => sFifoAfull
				);
	
	-- Generazione del segnale di Almost Full della Fifo di Housekeeping in funzione del livello di riempimento della stessa
	Almost_Full_proc : process (iFIFO_F2H_LEVEL)
	begin
		if (iFIFO_F2H_LEVEL > AF_HK_FIFO - 1) then
			sFifoAfull <= '1';	-- Se il livello della FIFO è maggiore o uguale della soglia di almost full  ----> sFifoAfull = '1'
		else
			sFifoAfull <= '0';	-- Altrimenti, sFifoAfull = '0'
		end if;
	end process;
	
	
end architecture;


