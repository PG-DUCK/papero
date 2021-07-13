--!@file WR_Timer.vhd
--!@brief Generatore di impulsi per estrarre un payload dalla FIFO
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.pgdaqPackage.all;

--!@copydoc WR_Timer.vhd
entity WR_Timer is
	port(WRT_CLK_in					: in std_logic;			-- Segnale di clock.
		  WRT_RST_in					: in std_logic;			-- Segnale di reset.
		  WRT_START_in					: in std_logic;			-- Segnale di "payload_enable" prodotto dal Config_Receiver. Vale '1' solo se PS=ACQUISITION.
		  WRT_STANDBY_in				: in std_logic;			-- Segnale di Wait_Request in uscita dalla FIFO. Se Wait_Request=1 --> la FIFO è vuota.
		  WRT_STOP_COUNT_VALUE_in	: in std_logic_vector(31 downto 0);		-- Lunghezza del payload + 5.
		  WRT_out						: out std_logic;			-- Impulsi di Read_Enable per acquisire il payload dalla FIFO. Se Read_Enable=1 --> la FIFO estrarrà il primo dato che ha ricevuto in ingresso.
		  WRT_DECLINE_out				: out std_logic;			-- Segnale per avvisare il Config_Receiver che dovrà rifiutare il dato in uscita dalla FIFO. Vale '1' solo se il dato del payload è da rifiutare.
		  WRT_END_COUNT_out			: out std_logic			-- Fine della trasmissione degli impulsi di Read_Enable per acquisire il payload.
		 );
end WR_Timer;

--!@copydoc WR_Timer.vhd
architecture Behavior of WR_Timer is
signal reset					: std_logic;		-- Segnale interno di reset.
signal start					: std_logic;		-- Segnale interno "payload_enable". E' "alto" solo se ci troviamo nello stato di "ACQUISITION" della macchina a stati.
signal start_R					: std_logic;		-- Impulso sul fronte di salita del "payload_enable". Ci indica che siamo appena entrati nello stato di "ACQUISITION".
signal standby					: std_logic;		-- Segnale interno di "Wait_Request" della FIFO.
signal standby_R				: std_logic;		-- Impulso sul fronte di salita del "Wait_Request". La FIFO si è appena svuotata.
signal standby_F				: std_logic;		-- Impulso sul fronte di discesa del "Wait_Request". Ci indica che la FIFO è vuota, con un ciclo di clock di ritardo.
signal output					: std_logic;		-- Segnale interno che trasporata gli impulsi di "Read_Enable".
signal WRT_output				: std_logic;		-- Segnale interno che trasporata gli impulsi di "Read_Enable". Deriva dal segnale di "output" con l'aggiunta di qualche operazione booleana.
signal end_count				: std_logic;		-- Segnale interno di fine della trasmissione .
signal general_counter 		: std_logic_vector(31 downto 0);	-- Contatore del numero di impulsi inviati in uscita.
signal bug_flag				: std_logic;		-- Flag per la segnalazione di una situazione potenzialmente dannosa che porta ad errore.


begin
	reset		 <= WRT_RST_in;			-- Assegnazione della porta di WRT_RST_in ad un segnale interno.
	start		 <= WRT_START_in;			-- Assegnazione della porta di WRT_START_in ad un segnale interno.
	standby	 <= WRT_STANDBY_in;		-- Assegnazione della porta di WRT_STANDBY_in ad un segnale interno.

	 -- Instanziamento dello User Edge Detector per generare i segnali di "start_R" e "standby_R".
	rise_edge_implementation : edge_detector_md
	generic map(channels => 2, R_vs_F => '0')
	port map(iCLK		=> WRT_CLK_in,
				iRST		=> reset,
				iD(0)		=> start,
				iD(1)		=> standby,
				oEDGE(0)	=> start_R,
				oEDGE(1)	=> standby_R
			  );

	-- Instanziamento dello User Edge Detector per generare il segnale di "standby_F".
	fall_edge_implementation : edge_detector_md
	generic map(channels => 1, R_vs_F => '1')
	port map(iCLK		=> WRT_CLK_in,
				iRST		=> reset,
				iD(0)		=> standby,
				oEDGE(0)	=> standby_F
			  );


	-- Processo per la gestione del "general_counter".
	counter_proc : process (WRT_CLK_in)
	begin
		if rising_edge(WRT_CLK_in) then
			if (reset = '1') then									-- Se reset = '1'--> azzera il "general_counter" e il "bug_flag".
				general_counter <= (others => '0');
				bug_flag <= '0';
			elsif ((general_counter = WRT_STOP_COUNT_VALUE_in - 5 - 2) and (standby_R = '1')) then
				bug_flag <= '1';										-- Se viene alzato il "Wait_Request" sul penultimo impulso di "Read_Enable", siamo in una situazione che potrebbe portare ad un errata generazione degli impulsi di "Read_Enable". Per cui, blocca il conteggio e porta alto il "bug_flag" per segnalarlo.
			elsif ((general_counter + 1 > WRT_STOP_COUNT_VALUE_in - 6) and (start = '1')) then
				general_counter <= (others => '0');				-- Se general_counter=STOP_COUNT_VALUE, azzera il conteggio perché siamo arrivati al numero massimo. Il "+1" di sx serve per bilanciare il segno ">". Il "+1" di dx serve perché il segnale "general_counter" è aggiornato al ciclo di clock di ritardo, sicché nel ciclo attuale vedo il valore del ciclo precedente, che è uguale a quello attuale "-1".
			elsif (((general_counter > 0) and (standby_F = '0') and (WRT_output = '1')) or (start_R = '1')) then
				general_counter <= general_counter + 1;		-- Se la condizione precedente è falsa (quindi non siamo arrivati al numero massimo di impulsi), controlla che: il "general_counter" abbia un valore maggiore di zero, che il "Wait_Request" sia basso e che l'uscita all'istante precedente fosse "1". Allora, incrementa il contatore, poiché nel ciclo di clock precedente è stato inviato un impulso di "Read_Enable".
			elsif ((general_counter > 0) and (standby_F = '1') and (WRT_output = '1') and (bug_flag = '1')) then
				general_counter <= WRT_STOP_COUNT_VALUE_in;	-- Se non siamo nella condizione precedente a causa del fatto che il "Wait_Request" è a "1", e al contempo il "bug_flag" è a "1", ricadiamo in un caso particolare che va trattato singolarmente. In particolare, porta il "general_counter" al valore massimo.
			end if;
		end if;
	end process;

	output_proc : process (WRT_CLK_in)
	begin
		if rising_edge(WRT_CLK_in) then
			if (reset = '1') then
				output	 <= '0';				-- Se reset = '1'--> azzera l'uscita e il bit di fine conteggio.
				end_count <= '0';
			elsif ((general_counter + 1 > WRT_STOP_COUNT_VALUE_in - 6) and (start = '1')) then
				output	 <= '0';				-- Se il "general_counter" ha raggiunto il valore massimo, porta l'uscita a zero e "alza" il bit di fine conteggio.
				end_count <= '1';
			elsif (((general_counter > 0) and (standby = '0')) or ((start_R = '1') and (standby = '0'))) then
				output	 <= '1';				-- Se il "general_counter" è maggiore di zero, ma non ha raggiunto il valore massimo, porta l'uscita a "1".
			else
				output	 <= '0';				-- Se però il "Wait_Request" è alto, allora porta l'uscita a "0" poiché la FIFO non ha valori da darmi (sebbene ne manchi ancora qualcuno).
			end if;
		end if;
	end process;


	-- Data Flow per il controllo dell'uscita
	WRT_output			 <= (output and (not reset) and start) or start_R or standby_F;
	WRT_out				 <= WRT_output;	-- L'uscita è data da "output" (a meno che il reset non sia alto), a cui va aggiunto "start_R" in modo da inviare subito un impulso di "Read_Enable" non appena payload_enable=1 , e "standby_F" in modo da inviare subito un impulso di "Read_Enable" non appena "Wait_Request"=0.
	WRT_END_COUNT_out	 <= end_count;
	WRT_DECLINE_out	 <= standby_F;


end Behavior;
