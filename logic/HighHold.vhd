--!@file HighHold.vhd
--!@brief Bloccatore del livello alto dei segnali
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

--!@copydoc HighHold.vhd
entity HighHold is
	generic(channels : integer := 1;
			  BAS_vs_BSS : std_logic := '0'		-- Modalità operativa dell'HighHold. mode=0 --> segnali d'ingresso bas (By-Asynchronous-Signals), ovvero l'HighHold opera per segnali provenienti direttamente dalle porte (clock, switch, pin di GPIO..).
			 );											-- Modalità operativa dell'HighHold. mode=1 --> segnali d'ingresso bss (By-Synchronous-Signals), ovvero l'HighHold opera per ingressi provienti da un processo o da una qualsivoglia elaborazione sincronizzata (come i Flip-Flop).
	port(CLK_in				: in std_logic;												-- Segnale di clock.
		  DATA_in			: in std_logic_vector(channels - 1 downto 0);		-- Segnale d'ingresso.
		  DELAY_1_out		: out std_logic_vector(channels - 1 downto 0);		-- Segnale d'uscita con ritenuta del livello "alto" di 1 ciclo di clock.
		  DELAY_2_out 		: out std_logic_vector(channels - 1 downto 0);		-- Segnale d'uscita con ritenuta del livello "alto" di 2 ciclo di clock.
		  DELAY_3_out		: out std_logic_vector(channels - 1 downto 0);		-- Segnale d'uscita con ritenuta del livello "alto" di 3 ciclo di clock.
		  DELAY_4_out		: out std_logic_vector(channels - 1 downto 0)		-- Segnale d'uscita con ritenuta del livello "alto" di 4 ciclo di clock.
		 );
end HighHold;

--!@copydoc HighHold.vhd
architecture Behavior of HighHold is

signal delay_0 : std_logic_vector(channels - 1 downto 0) := (others => '0');	-- Copia del segnale d'ingresso.
signal delay_1 : std_logic_vector(channels - 1 downto 0) := (others => '0');	-- Copia del segnale d'ingresso ritardata di 1 ciclo di clock.
signal delay_2 : std_logic_vector(channels - 1 downto 0) := (others => '0');	-- Copia del segnale d'ingresso ritardata di 2 cicli di clock.
signal delay_3 : std_logic_vector(channels - 1 downto 0) := (others => '0');	-- Copia del segnale d'ingresso ritardata di 3 cicli di clock.
signal delay_4 : std_logic_vector(channels - 1 downto 0) := (others => '0');	-- Copia del segnale d'ingresso ritardata di 4 cicli di clock.


begin
	delay_0 <= DATA_in;			-- Assegnazione della porta di DATA_in ad un segnale interno.

	FFD_1 : process (CLK_in)	-- Flip-Flop D per creare un ritardo di un ciclo di clock.
	begin
		if rising_edge(CLK_in) then
			delay_1 <= delay_0;
		end if;
	end process;

	FFD_2 : process (CLK_in)	-- Flip-Flop D per creare un ritardo di un ciclo di clock.
	begin
		if rising_edge(CLK_in) then
			delay_2 <= delay_1;
		end if;
	end process;

	FFD_3 : process (CLK_in)	-- Flip-Flop D per creare un ritardo di un ciclo di clock.
	begin
		if rising_edge(CLK_in) then
			delay_3 <= delay_2;
		end if;
	end process;

	FFD_4 : process (CLK_in)	-- Flip-Flop D per creare un ritardo di un ciclo di clock.
	begin
		if rising_edge(CLK_in) then
			delay_4 <= delay_3;
		end if;
	end process;


	-- Data Flow per il controllo delle uscite con ritenuta di 1 ciclo di clock.
	with BAS_vs_BSS select
		DELAY_1_out <= DATA_in or delay_1 when '1',
							delay_0 or delay_1 when others;

	-- Data Flow per il controllo delle uscite con ritenuta di 1 ciclo di clock.
	with BAS_vs_BSS select
		DELAY_2_out <= DATA_in or delay_1 or delay_2 when '1',
							delay_0 or delay_1 or delay_2 when others;

	-- Data Flow per il controllo delle uscite con ritenuta di 1 ciclo di clock.
	with BAS_vs_BSS select
		DELAY_3_out <= DATA_in or delay_1 or delay_2 or delay_3 when '1',
							delay_0 or delay_1 or delay_2 or delay_3 when others;

	-- Data Flow per il controllo delle uscite con ritenuta di 1 ciclo di clock.
	with BAS_vs_BSS select
		DELAY_4_out <= DATA_in or delay_1 or delay_2 or delay_3 or delay_4 when '1',
							delay_0 or delay_1 or delay_2 or delay_3 or delay_4 when others;


end Behavior;
