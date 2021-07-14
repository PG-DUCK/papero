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
		iFIFO_F2H_WR		: in  std_logic;								--!Wait Request fifo_TX
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

begin
	-- Ricevitore dati di configurazione
	FIFO_h2f_receiver : Config_Receiver
	port map(
				CR_CLK_in 						=> iCLK_intf,
				CR_RST_in 						=> iRST_intf,
				CR_FIFO_WAIT_REQUEST_in 	=> iFIFO_H2F_WR,
				CR_DATA_in 						=> iFIFO_H2F_DATA,			
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
	generic map(
					pFIFO_WIDTH => 32
					)
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
				iFIFO_AFULL => iFIFO_F2H_WR		--@todo Ricreare progetto Qsys esportando il segnale di "Almostfull"
				);
	
end architecture;


