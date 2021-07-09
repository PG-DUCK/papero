library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;



entity edge_detector_md is							-- Dichiarazione dell'interfaccia del modulo "edge_detector_md". Questo dispositivo rileva la presenza di fronti d'onda di salita e di discesa del segnale d'ingresso.
    generic(channels : integer := 1;
				R_vs_F : std_logic := '0'		-- Definiamo con "R_vs_F" il parametro che seleziona quali fronti d'onda conteggiare. Se R_vs_F=0--> rising edge, se R_vs_F=1--> falling edge.
			  );
	 port(iCLK     : in  std_logic;											-- Clock.
			iRST     : in  std_logic;											-- Reset.
			iD		   : in  std_logic_vector(channels - 1 downto 0);	-- Canali d'Ingresso.
			oEDGE 	: out std_logic_vector(channels - 1 downto 0)	-- Uscita del detector dei fronti d'onda.
			);
end edge_detector_md;



architecture Behavior of edge_detector_md is		-- Dichiarazione del funzionamento del modulo "edge_detector_md".
signal s_input    	  : std_logic_vector(channels - 1 downto 0) := (others => '0');	-- Segnale contenente il valore attuale dell'ingresso.
signal s_input_delay   : std_logic_vector(channels - 1 downto 0) := (others => '0');	-- Segnale contenente il valore dell'ingresso, ritardato di un ciclo di clock.
signal iRST_vector	  : std_logic_vector(channels - 1 downto 0) := (others => '0');
signal zero 			  : std_logic_vector(channels - 1 downto 0) := (others => '0');

begin
	 
	 s_input <= iD;
	 

	 ffd_proc : process(iCLK)					-- Processo per la descrizione del FLip-Flop 2.
    begin
        if (rising_edge(iCLK)) then
            s_input_delay <=	 s_input;		-- L'uscita del Flip-Flop sarà la copia dell'ingresso del detector ritardata di un ciclo di clock.
        end if;
    end process;
	 
	 
	 -- Data Flow per il controllo del reset vettoriale
	iRST_vector <= zero - iRST;
	 
	 -- Data Flow per il controllo dei fronti di salita/discesa
	 with R_vs_F select
		oEDGE <= ((s_input xor s_input_delay) and (not s_input)) and (not iRST_vector) when '1',
					((s_input xor s_input_delay) and s_input) and (not iRST_vector) when others;
	 

end Behavior;


