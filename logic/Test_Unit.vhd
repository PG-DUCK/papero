----------------------------------------------------------------------------------
--------  UNITA' DI TEST DEL SISTEMA DAQ PER GENERARE DATI PSEUDOCASUALI  --------
----------------------------------------------------------------------------------
--!@file Test_Unit.vhd
--!@brief Generatore di dati pseudocasuali (tramite algoritmo PRBS) utilizzati per verificare il funzionamento della sola scheda DAQ
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.pgdaqPackage.all;


--!@copydoc Test_Unit.vhd
entity Test_Unit is
	port(
	     iCLK			: in std_logic;								-- Porta per il clock
		  iRST			: in std_logic;								-- Porta per il reset
		  iEN				: in std_logic;								-- Porta per l'abilitazione della unità di test
	     oDATA			: out std_logic_vector(31 downto 0);	-- Numero binario a 32 bit pseudo-casuale
		  oDATA_VALID	: out std_logic								-- Segnale che attesta la validità dei dati in uscita dalla Test_Unit. Se oDATA_VALID=1 --> il valore di "oDATA" è consistente
		 );
end Test_Unit;


--!@copydoc Test_Unit.vhd
architecture Behavior of Test_Unit is
-- Dichiarazione degli stati della FSM
type tStatus is (RESET, STANDBY, COUNT, RESTART_COUNT);	 -- La Test_Unit è una macchina a stati costituita da 4 stati.
signal sPS, sNS : tStatus;											 -- PS= stato attuale, NS=stato prossimo.

-- Set di segnali utili per interconnetere i vari moduli del Top-Level
signal	 sEN_R				: std_logic;								 -- Impulso generato sul fronte di salita del segnale di iEN
signal	 sPRBS14_en			: std_logic;								 -- Abilitazione del modulo PRBS14
signal	 sPRBS32_en			: std_logic;								 -- Abilitazione del modulo PRBS32
signal	 sPRBS14_out		: std_logic_vector(13 downto 0);		 -- Valore di fine conteggio del contatore
signal	 sData				: std_logic_vector(31 downto 0);		 -- Numero binario pseudo-casuale a 32 bit
signal	 sStopValue			: std_logic_vector(13 downto 0);		 -- Valore di fine conteggio del contatore (negato)
signal	 sCounter			: std_logic_vector(13 downto 0);		 -- Contatore per abilitare il PRBS32. Permette di creare un tempo di invio aleatorio tra un dato pseudocasuale e il successivo
constant	 cGND					: std_logic := '0';						 -- Massa

-- Set di segnali il cui valore indica la presenza in un preciso stato della macchina a stati.
signal sInternalReset_ps      : std_logic;  -- '1' solo se PS=RESET
signal sStandbyEnable_ps      : std_logic;  -- '1' solo se PS=STANDBY
signal sCountEnable_ps			: std_logic;  -- '1' solo se PS=COUNT
signal sRestartCountEnable_ps : std_logic;  -- '1' solo se PS=RESTART_COUNT
signal sInternalReset_ns      : std_logic;  -- '1' solo se NS=RESET
signal sStandbyEnable_ns      : std_logic;  -- '1' solo se NS=STANDBY
signal sCountEnable_ns			: std_logic;  -- '1' solo se NS=COUNT
signal sRestartCountEnable_ns : std_logic;  -- '1' solo se NS=RESTART_COUNT

-- Set di impulsi generati sul fronte di salita (R) e di discesa (F) dai rispettivi segnali di "enable".
signal sInternalReset_ps_R			: std_logic;
signal sStandbyEnable_ps_R			: std_logic;
signal sCountEnable_ps_R			: std_logic;
signal sRestartCountEnable_ps_R	: std_logic;
signal sInternalReset_ns_R			: std_logic;
signal sStandbyEnable_ns_R			: std_logic;
signal sCountEnable_ns_R			: std_logic;
signal sCountEnable_ns_F			: std_logic;
signal sRestartCountEnable_ns_R	: std_logic;


begin
	-- Assegnazione segnali interni
	sStopValue	<= not sPRBS14_out;		-- Utilizzeremo, come valore di fine conteggio, l'uscita del PRBS14 negata, altrimenti non avremmo potuto usufruire della quantità "0x0000"
	
	
	-- Instanziamento dello User Edge Detector per generare gli impulsi (di 1 ciclo di clock) che segnalano il passaggio da uno stato all'altro.
	rise_edge_implementation : edge_detector_md
   generic map(channels => 9, R_vs_F => '0')
   port map(
				iCLK 	    => iCLK,
            iRST 	    => cGND,
            iD(0)	    => iEN,
				iD(1)	    => sInternalReset_ps,
				iD(2)	    => sStandbyEnable_ps,
				iD(3)	    => sCountEnable_ps,
				iD(4)	    => sRestartCountEnable_ps,
				iD(5)	    => sInternalReset_ns,
				iD(6)	    => sStandbyEnable_ns,
				iD(7)	    => sCountEnable_ns,
				iD(8)	    => sRestartCountEnable_ns,			
				oEDGE(0)	 => sEN_R,
				oEDGE(1)	 => sInternalReset_ps_R,
				oEDGE(2)	 => sStandbyEnable_ps_R,
				oEDGE(3)	 => sCountEnable_ps_R,
				oEDGE(4)	 => sRestartCountEnable_ps_R,
				oEDGE(5)	 => sInternalReset_ns_R,
				oEDGE(6)	 => sStandbyEnable_ns_R,
				oEDGE(7)	 => sCountEnable_ns_R,
				oEDGE(8)	 => sRestartCountEnable_ns_R
            );
				
	-- Instanziamento dello User Edge Detector per generare gli impulsi di "synch_pulse" per risincronizzare l'uscita della FIFO con l'ingresso del ricevitore quando la FIFO passa da vuota a non vuota.
	fall_edge_implementation : edge_detector_md
   generic map(channels => 1, R_vs_F => '1')
   port map(
				iCLK     => iCLK,
            iRST     => cGND,
            iD(0)    => sCountEnable_ns,
            oEDGE(0) => sCountEnable_ns_F
            );
	
	-- Generazione del valore di fine conteggio
	compute_end_count : PRBS14
	port map(
				iCLK			=> iCLK,
				iRST			=> sInternalReset_ps,
				iPRBS14_en	=> sPRBS14_en,
				oDATA			=> sPRBS14_out
				);
	
	-- Generazione del dato pseudo-casuale a 32 bit
	compute_output_data : PRBS32
	port map(
				iCLK			=> iCLK,
				iRST			=> sInternalReset_ps,
				iPRBS32_en	=> sPRBS32_en,
				oDATA			=> sDATA
				);
	
	
	-- Next State Evaluation
	delta_proc : process (sPS, iEN, sCounter, sStopValue)
	begin
		case sPS is
			when RESET =>		-- Sei in RESET
				if (iEN = '1') then
					sNS <= COUNT;		-- Se la Test_Unit viene abilitata, passa a COUNT
				else
					sNS <= STANDBY;	--	Altrimenti vai in STANDBY
				end if;
			when STANDBY =>	-- Sei in STANDBY
				if ((iEN = '1') and (sCounter = sStopValue)) then
					sNS <= RESTART_COUNT;	-- Se la Test_Unit viene abilitata ed il conteggio si trova nel suo valore massimo, vai in RESTART
				elsif ((iEN = '1') and (not (sCounter = sStopValue))) then
					sNS <= COUNT;				-- Se non si trova nel suo valore massimo passa a COUNT
				else
					sNS <= STANDBY;			-- Altrimenti, senza abilitazione, rimani qui in attesa senza fare niente
				end if;
			when COUNT =>		-- Sei in COUNT
				if (iEN = '0') then
					sNS <= STANDBY;			-- Se la Test_Unit viene disabilitata, torna in STANDBY
				elsif ((iEN = '1') and (sCounter = sStopValue)) then
					sNS <= RESTART_COUNT;	-- Se la Test_Unit è ancora attiva e il conteggio ha raggiunto il suo valore massimo, vai in RESTART
				else
					sNS <= COUNT;				-- Altrimenti, se non siamo al valore massimo, rimani in COUNT
				end if;
			when RESTART_COUNT =>	-- Sei in RESTART_COUNT
				if (iEN = '0') then
					sNS <= STANDBY;			-- Se la Test_Unit viene disabilitata, torna in STANDBY
				elsif ((iEN = '1') and (sCounter = sStopValue)) then
					sNS <= RESTART_COUNT;	-- Se la Test_Unit è ancora attiva e il conteggio è ancora nel suo valore massimo, rimani in RESTART_COUNT
				else
					sNS <= COUNT;				-- Altrimenti, se non siamo al valore massimo, ricominca a contare daccapo
				end if;
			when others => 	-- Se ci troviamo in uno stato non definito, passa a RESET
				sNS	 <= RESET;
		end case;
	end process;

	
	-- State Synchronization. Sincronizza lo stato attuale della macchina con il fronte di salita del clock.
	state_proc : process (iCLK)
	begin
		if rising_edge(iCLK) then
			if (iRST = '1') then
				sPS <= RESET;
			else
				sPS <= sNS;
			end if;
		end if;
	end process;	
	
		
   -- Internal Signals Switch Data Flow. Interruttore generale per abilitare o disabilitare i segnali di "enable".
   sInternalReset_ps     	 <= '1' when sPS = RESET			 else '0';
   sStandbyEnable_ps        <= '1' when sPS = STANDBY        else '0';
   sCountEnable_ps			 <= '1' when sPS = COUNT	  	 	 else '0';
   sRestartCountEnable_ps	 <= '1' when sPS = RESTART_COUNT	 else '0';
   sInternalReset_ns     	 <= '1' when sNS = RESET			 else '0';
   sStandbyEnable_ns        <= '1' when sNS = STANDBY        else '0';
   sCountEnable_ns			 <= '1' when sNS = COUNT	  	 	 else '0';
   sRestartCountEnable_ns	 <= '1' when sNS = RESTART_COUNT	 else '0';	
	
	
	-- Internal Process. Processo asincrono per la determinzazione dei valori dei segnali interni della Test_Unit.
	internal_proc : process (sPS, sEN_R, sRestartCountEnable_ns_R, sRestartCountEnable_ns)
	begin
		case sPS is
			when RESET =>							-- Sei in RESET
				sPRBS14_en		 <= sEN_R;											-- Se viene attivata la Test_Unit, estrai una nuova lunghezza temporale
				sPRBS32_en		 <= '0';
			when STANDBY =>						-- Sei in STANDBY
				sPRBS14_en		 <= sEN_R or sRestartCountEnable_ns_R;		-- Se viene attivata la Test_Unit o se il prossimo stato è RESTART, estrai una nuova lunghezza temporale
				sPRBS32_en		 <= sRestartCountEnable_ns_R;					-- se il prossimo stato è RESTART, estrai un nuovo dato
			when COUNT =>							-- Sei in COUNT
				sPRBS14_en		 <= sRestartCountEnable_ns_R;					-- se il prossimo stato è RESTART, estrai una nuova lunghezza temporale
				sPRBS32_en		 <= sRestartCountEnable_ns_R;					-- se il prossimo stato è RESTART, estrai un nuovo dato
			when RESTART_COUNT =>				-- Sei in RESTART_COUNT
				sPRBS14_en		 <= sRestartCountEnable_ns;					-- se il prossimo stato è RESTART, estrai una nuova lunghezza temporale
				sPRBS32_en		 <= sRestartCountEnable_ns;					-- se il prossimo stato è RESTART, estrai un nuovo dato
			when others =>							-- Sei in uno stato non definito
				sPRBS14_en		 <= '0';
				sPRBS32_en		 <= '0';
		end case;
	end process;
	
	
	-- Output Process. Processo asincrono per la determinzazione dei valori sulle porte d'uscita della Test_Unit.
	output_proc : process (sPS, sData)
	begin
		case sPS is
			when RESET =>		-- Sei in RESET
				oDATA				 <= (others => '1');		-- ATTENZIONE, l'attivazione del segnale di reset porta l'uscita dati "alta".
				oDATA_VALID		 <= '0';
			when STANDBY =>	-- Sei in STANDBY
				oDATA				 <= sData;
				oDATA_VALID		 <= '0';
			when COUNT =>		-- Sei in COUNT
				oDATA				 <= sData;
				oDATA_VALID		 <= '0';
			when RESTART_COUNT =>	-- Sei in RESTART_COUNT
				oDATA				 <= sData;
				oDATA_VALID		 <= '1';						-- Attiva il segnale di Data_Valid se e solo se ci troviamo in RESTART_COUNT
			when others =>		 -- Sei in uno stato non definito
				oDATA				 <= sData;
				oDATA_VALID		 <= '0';
		end case;
	end process;
	
	
	-----------------------
	-- Signal Processing --
	-----------------------	
	
	-- Contatore per temporizzare l'invio dei dati verso l'esterno
	counter_proc : process (iCLK)
	begin
		if rising_edge(iCLK) then
			if (sInternalReset_ps = '1') then
				sCounter <= (others => '0');		-- Se siamo in RESET, azzera il contatore	
			elsif (((sCountEnable_ns_R = '1') or (sCountEnable_ps = '1')) and (sCountEnable_ns_F = '0')) then
				sCounter <= sCounter + 1;			-- Se il prossimo stato è COUNT oppure già ci siamo, incrementa il conteggio. Attenzione! in COUNT, ignora l'ultimo incremento
			elsif (sRestartCountEnable_ns_R = '1') then
				sCounter <= (others => '0');		-- Azzera il contatore ogni volta che stiamo per entrare nello stato RESTART_COUNT
			end if;
		end if;
	end process;
	
	
end Behavior;


