--!@file FastData_Transmitter.vhd
--!@brief Trasmettitore di dati scientifici
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.pgdaqPackage.all;


--!@copydoc FastData_Transmitter.vhd
entity FastData_Transmitter is
	generic(
		pFW_VER : std_logic_vector(31 downto 0)
	);
	port(
	    iCLK					: in std_logic;								-- Clock
		  iRST					: in std_logic;								-- Reset
		  -- Enable
		  iEN						: in std_logic;								-- Abilitazione del modulo FastData_Transmitter
		  -- Settings Packet
		  iMETADATA			: in tF2hMetadata; --Packet header information
		  -- Fifo Management
		  iFIFO_DATA			: in 	std_logic_vector(31 downto 0);	-- "Data_Output" della FIFO a monte del FastData_Transmitter
	    iFIFO_EMPTY			: in 	std_logic;								-- "Empty" della FIFO a monte del FastData_Transmitter
		  iFIFO_AEMPTY			: in std_logic;								-- "Almost_Empty" della FIFO a monte del FastData_Transmitter. ATTENZIONE!!!--> Per un corretto funzionamento, impostare pAEMPTY_VAL = 2 sulla FIFO a monte del FastData_Transmitter
		  oFIFO_RE				: out std_logic;								-- "Read_Enable" della FIFO a monte del FastData_Transmitter
		  oFIFO_DATA			: out std_logic_vector(31 downto 0);	-- "Data_Inutput" della FIFO a valle del FastData_Transmitter
		  iFIFO_AFULL			: in 	std_logic;								-- "Almost_Full" della FIFO a valle del FastData_Transmitter
		  oFIFO_WE				: out std_logic;								-- "Write_Enable" della FIFO a valle del FastData_Transmitter
		  -- Output Flag
		  oBUSY					: out std_logic;								-- Il trasmettitore è impegnato in un trasferimento dati. '0'-->ok, '1'-->busy
		  oWARNING				: out std_logic								-- Malfunzionamenti. '0'-->ok, '1'--> errore: la macchina è finita in uno stato non precisato
		 );
end FastData_Transmitter;


--!@copydoc FastData_Transmitter.vhd
architecture Behavior of FastData_Transmitter is
-- Dichiarazione degli stati della FSM
type tStatus is (RESET, IDLE, SOP, LENG, FWV, TRIG_NUM, TRIG_TYPE, INT_TIME_0, INT_TIME_1, EXT_TIME_0, EXT_TIME_1, PAYLOAD, TRAILER, CRC);	 -- La FastData_Transmitter è una macchina a stati costituita da 14 stati.
signal sPS : tStatus;

-- Set di costanti utili per la risoluzione del pacchetto ricevuto.
constant cStart_of_packet : std_logic_vector(31 downto 0) := x"BABA1AFA";		 -- Start of packet
constant cTrailer         : std_logic_vector(31 downto 0) := x"0BADFACE";		 -- Bad Face

-- Set di segnali interni per pilotare le uscite del FastData_Transmitter
signal sFIFO_RE        	: std_logic;								 -- Segnale di "Read_Enable" della FIFO a monte del FastData_Transmitter
signal sFIFO_DATA      	: std_logic_vector(31 downto 0);		 -- Segnale di "Data_Inutput" della FIFO a valle del FastData_Transmitter
signal sFIFO_WE     	 	: std_logic;								 -- Segnale di "Write_Enable" della FIFO a valle del FastData_Transmitter
signal sScientificData	: std_logic_vector(31 downto 0);		 -- Segnale di "Data_Output" della FIFO a monte del FastData_Transmitter
signal sBusy 				: std_logic;								 -- Bit per segnalare se il trasmettitore è impegnato in un trasferimento dati. '0'-->ok, '1'--> busy
signal sFsmError 			: std_logic;								 -- Segnale di errore della macchina a stati finiti. '0'-->ok, '1'--> errore: la macchina è finita in uno stato non precisato

-- Set di segnali utili per il Signal Processing.
signal sFIFO_RE_d				: std_logic;								-- Segnale di "Read_Enable" della FIFO a monte del FastData_Transmitter ritardato di un ciclo di clock
signal DataCounter_RE		: std_logic_vector(11 downto 0);		-- Contatore del numero di parole di payload lette dalla FIFO a monte del FastData_Transmitter
signal DataCounter_WE		: std_logic_vector(11 downto 0);		-- Contatore del numero di parole di payload scritte nella FIFO a valle del FastData_Transmitter
signal sLastOne				: std_logic;								-- Indicatore della presenza di un solo elemento nella FIFO a monte del FastData_Transmitter
signal sCRC32_rst				: std_logic;								-- Reset del modulo per il calcolo del CRC
signal sCRC32_en				: std_logic;								-- Abilitazione del modulo per il calcolo del CRC
signal sEstimated_CRC32		: std_logic_vector(31 downto 0);		-- Valutazione del codice a ridondanza ciclica CRC-32/MPEG-2: Header (except length) + Payload


begin
	-- Assegnazione segnali interni del FastData_Transmitter alle porte di I/O
	oFIFO_RE				<= sFIFO_RE;
	oFIFO_DATA			<= sFIFO_DATA;
	oFIFO_WE				<= sFIFO_WE;
	sScientificData	<=	iFIFO_DATA;
	sLastOne				<= iFIFO_EMPTY xor iFIFO_AEMPTY;
	oBUSY					<= sBusy;
	oWARNING				<= sFsmError;


	-- Calcola il CRC32 per il contenuto del pacchetto (eccetto per SoP, Len, and EoP)
   Calcolo_CRC32 : CRC32
   generic map(
					pINITIAL_VAL => x"FFFFFFFF"
					)
   port map(
				iCLK    => iCLK,
				iRST    => sCRC32_rst,
				iCRC_EN => sCRC32_en,
				iDATA   => sFIFO_DATA,
				oCRC    => sEstimated_CRC32
				);


	-- Implementazione della macchina a stati
	StateFSM_proc : process (iCLK)
	begin
		if (rising_edge(iCLK)) then
			if (iRST = '1') then
				-- Stato di RESET. Si entra in questo stato solo se qualcuno dall'esterno alza il segnale di reset
				sFIFO_RE   	 <= '0';
				sFIFO_DATA 	 <= (others => '0');
				sFIFO_WE		 <= '0';
				DataCounter_RE	 <= (others => '0');
				DataCounter_WE	 <= (others => '0');
				sBusy			 <= '1';
				sFsmError	 <= '0';
				sCRC32_rst	 <= '1';
				sCRC32_en	 <= '0';
				sPS 			 <= IDLE;

			elsif (iEN = '1') then
				-- Valori di default che verranno sovrascritti, se necessario
				sFIFO_RE   	 <= '0';
				sFIFO_DATA 	 <= (others => '0');
				sFIFO_WE		 <= '0';
				sBusy			 <= '1';
				sCRC32_rst	 <= '0';
				sCRC32_en	 <= '0';
				case (sPS) is
					-- Stato di IDLE. Il Trasmettitore si mette in attesa che la FIFO a monte abbia almeno una word da inviare e quella a valle disponga di almeno 4 posizioni libere
					when IDLE =>
						sBusy			 <= '0';			-- Questo è l'unico stato in cui il trasmettitore si può considerare non impegnato in un trasferimento
						sCRC32_rst	 <= '1';
						if (iFIFO_EMPTY = '0' and iFIFO_AFULL = '0') then
							sPS	 <= SOP;
						else
							sPS	 <= IDLE;
						end if;

					-- Stato di START-OF-PACKET. Inoltro della parola "BABA1AFA"
					when SOP =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= cStart_of_packet;
							sFIFO_WE		 <= '1';
							sPS			 <= LENG;
						else
							sPS			 <= SOP;
						end if;

					-- Stato di LENGTH. Inoltro della parola contenente la lunghezza del pacchetto: Payload 32-bit words + 10
					when LENG =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= iMETADATA.pktLen; --!@todo Store the packet length at the beginning of the packet
							sFIFO_WE		 <= '1';
							sPS			 <= FWV;
						else
							sPS			 <= LENG;
						end if;

					-- Stato di FIRMWARE-VERSION. Inoltro della parola contenente la Versione del Firmware in uso (SHA dell'ultimo commit)
					when FWV =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= pFW_VER;
							sFIFO_WE		 <= '1';
							sCRC32_en	 <= '1';
							sPS			 <= TRIG_NUM;
						else
							sPS			 <= FWV;
						end if;

					-- Stato di TRIGGER-NUMBER. Inoltro della parola contenente il numero di trigger
					when TRIG_NUM =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= iMETADATA.trigNum;
							sFIFO_WE		 <= '1';
							sCRC32_en	 <= '1';
							sPS			 <= TRIG_TYPE;
						else
							sPS			 <= TRIG_NUM;
						end if;

					-- Stato di TRIGGER-TYPE. Inoltro della parola contenente il Detector-ID e il Trigger-ID
					when TRIG_TYPE =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= x"0000" & iMETADATA.detId & iMETADATA.trigId;
							sFIFO_WE		 <= '1';
							sCRC32_en	 <= '1';
							sPS			 <= INT_TIME_0;
						else
							sPS			 <= TRIG_TYPE;
						end if;

					-- Stato di INTERNAL-TIMESTAMP-MSW. Inoltro della "Most_Significant_Word" contenente il Timestamp calcolato all'interno dell'FPGA
					when INT_TIME_0 =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= iMETADATA.intTime(63 downto 32);
							sFIFO_WE		 <= '1';
							sCRC32_en	 <= '1';
							sPS			 <= INT_TIME_1;
						else
							sPS			 <= INT_TIME_0;
						end if;

					-- Stato di INTERNAL-TIMESTAMP-LSW. Inoltro della "Least_Significant_Word" contenente il Timestamp calcolato all'interno dell'FPGA
					when INT_TIME_1 =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= iMETADATA.intTime(31 downto 0);
							sFIFO_WE		 <= '1';
							sCRC32_en	 <= '1';
							sPS			 <= EXT_TIME_0;
						else
							sPS			 <= INT_TIME_1;
						end if;

					-- Stato di EXTERNAL-TIMESTAMP-MSW. Inoltro della "Most_Significant_Word" contenente il Timestamp calcolato all'esterno dell'FPGA
					when EXT_TIME_0 =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= iMETADATA.extTime(63 downto 32);
							sFIFO_WE		 <= '1';
							sCRC32_en	 <= '1';
							sPS			 <= EXT_TIME_1;
						else
							sPS			 <= EXT_TIME_0;
						end if;

					-- Stato di EXTERNAL-TIMESTAMP-LSW. Inoltro della "Least_Significant_Word" contenente il Timestamp calcolato all'esterno dell'FPGA
					when EXT_TIME_1 =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= iMETADATA.extTime(31 downto 0);
							sFIFO_WE		 <= '1';
							sCRC32_en	 <= '1';
							sPS			 <= PAYLOAD;
						else
							sPS			 <= EXT_TIME_1;
						end if;

					-- Stato di PAYLOAD. Inoltro delle parole di payload dalla FIFO a monte a quella a valle rispetto al FastData_Transmitter
					when PAYLOAD =>
						if (DataCounter_WE < DataCounter_RE or DataCounter_WE < iMETADATA.pktLen - 10) then
							if (sFIFO_RE_d = '1') then
								sFIFO_WE			<= '1';
								DataCounter_WE <= DataCounter_WE + 1;
								sCRC32_en		<= '1';
								sPS				<= PAYLOAD;
							else
								sPS				<= PAYLOAD;
							end if;
						elsif (DataCounter_RE = 0) then
							sPS				<= PAYLOAD;
						else
							DataCounter_RE <= (others => '0');
							DataCounter_WE <= (others => '0');
							sPS				<= TRAILER;
						end if;

						if (sFIFO_RE = '0' and sLastOne = '1' and iFIFO_AFULL = '0' and DataCounter_RE < iMETADATA.pktLen - 10) then
							sFIFO_RE			<= '1';
							sFIFO_DATA		<= sScientificData;
							DataCounter_RE <= DataCounter_RE + 1;
						elsif (sFIFO_RE = '1' and sLastOne = '1' and iFIFO_AFULL = '0' and DataCounter_RE < iMETADATA.pktLen - 10) then
							sFIFO_RE		<= '0';
							sFIFO_DATA	<= sScientificData;
						elsif (iFIFO_EMPTY = '0' and iFIFO_AFULL = '0' and DataCounter_RE < iMETADATA.pktLen - 10) then
							sFIFO_RE			<= '1';
							sFIFO_DATA		<= sScientificData;
							DataCounter_RE <= DataCounter_RE + 1;
						else
							sFIFO_RE		<= '0';
							sFIFO_DATA	<= sScientificData;
						end if;

					-- Stato di TRAILER. Inoltro della parola di trailer "0BADFACE"
					when TRAILER =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= cTrailer;
							sFIFO_WE		 <= '1';
							sPS			 <= CRC;
						else
							sPS			 <= TRAILER;
						end if;

					-- Stato di CRC. Inoltro del CRC-32/MPEG-2 calcolato su tutto il pacchetto (tranne per Sop, Length e Trailer)
					when CRC =>
						if (iFIFO_AFULL = '0') then
							sFIFO_DATA	 <= sEstimated_CRC32;
							sFIFO_WE		 <= '1';
							sPS			 <= IDLE;
						else
							sPS			 <= CRC;
						end if;

					-- Stato non previsto.
					when others =>
						sFIFO_RE   	 <= '0';
						sFIFO_DATA 	 <= (others => '0');
						sFIFO_WE		 <= '0';
						sFsmError	 <= '1';
						sPS 			 <= IDLE;
				end case;
			else
				-- Valori di default nel caso in cui il FastData_Transmitter venisse disabilitato
				sFIFO_RE   	 <= '0';
				sFIFO_WE		 <= '0';
				sCRC32_rst	 <= '0';
				sCRC32_en	 <= '0';
				case (sPS) is
					-- Stato di PAYLOAD. Inoltro delle parole di payload dalla FIFO a monte a quella a valle rispetto al FastData_Transmitter
					when PAYLOAD =>
						sFIFO_DATA	<= sScientificData;
						if (DataCounter_WE < DataCounter_RE or DataCounter_WE < iMETADATA.pktLen - 10) then
							if (sFIFO_RE_d = '1') then
								sFIFO_WE			<= '1';
								DataCounter_WE <= DataCounter_WE + 1;
								sCRC32_en		<= '1';
								sPS				<= PAYLOAD;
							else
								sPS				<= PAYLOAD;
							end if;
						elsif (DataCounter_RE = 0) then
							sPS				<= PAYLOAD;
						else
							DataCounter_RE <= (others => '0');
							DataCounter_WE <= (others => '0');
							sPS				<= TRAILER;
						end if;

					-- Stato non previsto.
					when others =>
						sFIFO_RE   	 <= '0';
						sFIFO_WE		 <= '0';
						sCRC32_rst	 <= '0';
						sCRC32_en	 <= '0';
					end case;
			end if;
		end if;
	end process;


	-- Flip Flop D per ritardare il segnale di "Read_Enable" della FIFO a monte del FastData_Transmitter. Lo scopo è quello di evitare di leggere il dato in uscita dalla FIFO quando questo non è ancora pronto.
   delay_Wait_Request_proc : process (iCLK)
   begin
		if rising_edge(iCLK) then
			if (iRST = '1') then
				sFIFO_RE_d <= '0';
			else
				sFIFO_RE_d <= sFIFO_RE;
			end if;
		end if;
   end process;


end Behavior;
