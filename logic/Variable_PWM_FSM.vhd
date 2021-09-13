library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;



entity Variable_PWM_FSM is						-- Dichiarazione dell'interfaccia del modulo "Variable_PWM_FSM". Questo dispositivo è un generatore di segnale PWM.
	generic (period : integer := 50;			-- Definiamo con "period" il periodo di conteggio del contatore (che di fatto andrà a definire la frequenza del segnale PWM) espresso in "numero di cicli di clock".
				duty_cycle : integer := 25;	-- Definiamo con "duty_cycle" il numero di cicli di clock per i quali l'uscita dovrà tenersi "alta".
				neg : integer := 0;				-- Definiamo con "neg" la logica di funzionamento del dispositivo. Se neg=0-->logica normale, se neg=1-->logica negata.
				R_vs_F : integer := 0			-- Definiamo con "R_vs_F" il parametro che seleziona quali fronti d'onda conteggiare. Se R_vs_F=0--> rising edge, se R_vs_F=1--> falling edge.
				);
	port (SWITCH : in std_logic;				-- Ingresso per abilitare il segnale PWM.
			ENABLE_COUNTER : in std_logic;	-- Ingresso per abilitare il contatore per la generazione del segnale PWM.
			RESET_RF_COUNTER : in std_logic;	-- Ingresso per il reset del contatore dei fronti d'onda.
			CLK : in std_logic;					-- Ingresso del segnale di Clock.
			LED : out std_logic;					-- Uscita del dispositivo.			
			RISING_LED : out std_logic;		-- Uscita di segnalazione dei fronti di salita.
			FALLING_LED : out std_logic;		-- Uscita di segnalazione dei fronti di discesa.
			RISE_FALL_COUNTER : out std_logic_vector(7 downto 0)	-- Uscita contenente il numero di fronti di salita/discesa rilevati dal detector.
			);
end Variable_PWM_FSM;



architecture Behavior of Variable_PWM_FSM is
signal counter : std_logic_vector(25 downto 0);			-- Segnale contenente il valore del contatore per la generazione del segnale PWM.
signal rise_counter : std_logic_vector(7 downto 0);	-- Segnale contenente il valore del contatore per il conteggio del numero di fronti di salita.
signal fall_counter : std_logic_vector(7 downto 0);	-- Segnale contenente il valore del contatore per il conteggio del numero di fronti di discesa.
signal output : std_logic;										-- Segnale contenente il valore dell'uscita del dispositivo parzialmente elaborata.
signal s_LED : std_logic;										-- Segnale contenente il valore dell'uscita del completamente elaborata.
signal s_RISING_LED : std_logic;								-- Segnale contenente il valore dell'uscita del detector dei fronti di salita.
signal s_FALLING_LED : std_logic;							-- Segnale contenente il valore dell'uscita del detector dei fronti di discesa.
signal s_Q : std_logic;											-- Segnale contenente il valore dell'uscita del Flip Flop D utile al funzionamento dei detector dei fronti di salita e discesa.
signal s_R_led : std_logic;									-- Segnale contenente l'uscita del detector dei fronti di salita.
signal s_F_led : std_logic;									-- Segnale contenente l'uscita del detector dei fronti di discesa.										
begin

	counter_PWM_process : process (CLK)
	begin
		if rising_edge(CLK) then
			if (SWITCH = '0') then									-- Se SWITCH=0 --> azzera il contatore.
				counter <= (others => '0');
			elsif (ENABLE_COUNTER = '1') then					-- Se ENABLE_COUNTER=1 --> abilita l'incremento del contatore PWM, altrimenti tieni il conteggio "congelato".
					if (counter < (period - 1)) then				-- Se counter<period --> incrementa il contatore. Il termine "-1" tiene conto del fatto che un ciclo di clock va "sprecato" per azzerare il contatore. Quindi in quel ciclo lì non andremo ad incrementarlo.
						counter <= counter + 1;						-- Se ENABLE_COUNTER=1 --> l'incremento è effettivo, altrimenti se ENABLE_COUNTER=1 tieni il conteggio "congelato".
					else
						counter <= (others => '0');				-- Se counter>=period --> azzera il contatore.
					end if;
			end if;
		end if;
	end process;
	
	output_process : process (CLK)
	begin
		if rising_edge(CLK) then
			if (SWITCH = '0') then								-- Se SWITCH=0 --> Manda in uscita un valore "basso".
				output <= '0';
			elsif (counter < duty_cycle) then				-- Se counter<duty_cycle --> Manda in uscita un valore "alto". NOTA: si utilizza il "<" e non il "<=" in quanto la condizione del costrutto "if" viene verificata un istante prima del fronte di salita del clock (cioè in "counter-1"), mentre il corpo "dell'if" viene eseguito nell'istante attuale (cioè in "counter"). 
				output <= '1';
			else
				output <= '0';										-- Se counter>=duty_cycle --> Manda in uscita un valore "basso".
			end if;
		end if;
	end process;
	
	FFD_process : process (CLK)				-- Questo Flip Flop D serve per memorizzare lo stato precedente (rispetto a quello attuale) del segnale PWM che stiamo generando.
	begin
		if rising_edge(CLK) then				-- Ad ogni fronte di salita del clock, "Q" contiene il valore dell'uscita nel ciclo di clock precedente.
			s_Q <= s_LED;							-- NOTA: Quando utilizzo un segnale generato da un processo sincronizzato dal clock, non ho a disposizione il suo valore effettivo ma quello ritardato di un ciclo di clock.
		end if;
	end process;
	
	rising_edge_counter_process : process (CLK)
	begin
		if rising_edge(CLK) then											
			if (RESET_RF_COUNTER = '1') then				-- Condizione di reset del contatore dei fronti d'onda.
				rise_counter <= (others => '0');
			elsif	(s_RISING_LED = '1') then				-- Ogni volta che cambia lo stato d'uscita del RISING_LED, se questo vale '1' incrementa il contatore dei fronti d'onda altrimenti lascia il valore inalterato.
				rise_counter <= rise_counter + 1;
			end if;
		end if;
	end process;
	
	falling_edge_counter_process : process (CLK)
	begin
		if rising_edge(CLK) then															
			if (RESET_RF_COUNTER = '1') then				-- Condizione di reset del contatore dei fronti d'onda.
				fall_counter <= (others => '0');
			elsif	(s_FALLING_LED = '1') then				-- Ogni volta che cambia lo stato d'uscita del RISING_LED, se questo vale '1' incrementa il contatore dei fronti d'onda altrimenti lascia il valore inalterato.
				fall_counter <= fall_counter + 1;
			end if;
		end if;
	end process;
		

	-- Data Flow per il controllo dell'uscita
	with neg select
		s_LED <= output when 0,						-- Se neg=0 --> utilizziamo una logica normale, cioè il segnale output viene riportato in uscita così com'è.
				 not output when others;			-- Se neg=1 --> utilizziamo una logica negata, cioè il segnale output viene riportato in uscita negato. 	 
	LED <= s_LED;	
	
	-- Data Flow per il controllo dei fronti di salita
	s_RISING_LED <= (s_Q xor s_LED) and s_LED;					-- Se LED[k-1]=0, LED[k]=1 --> RISING_LED=1. In tutti gli altri casi RISING_LED=0.
	RISING_LED <= s_RISING_LED;
	
	-- Data Flow per il controllo dei fronti di discesa
	s_FALLING_LED <= (s_Q xor s_LED) and (not s_LED);			-- Se LED[k-1]=1, LED[k]=0 --> FALLING_LED=1. In tutti gli altri casi FALLING_LED=0.
	FALLING_LED <= s_FALLING_LED;
	
	-- Data Flow per il conteggio dei fronti d'onda
	with R_vs_F select
		RISE_FALL_COUNTER <= rise_counter when 0,					-- Se R_vs_F=0 conteggia i fronti di salita, altrimenti quelli di discesa.
									fall_counter when others;
	
	
end Behavior;


