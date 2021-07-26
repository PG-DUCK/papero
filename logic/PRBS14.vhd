-------------------------------------------------------
--------  PSEUDO RANDOM BINARY SEQUENCE 14bit  --------
-------------------------------------------------------
--!@file PRBS14.vhd
--!@brief Implementazione di un algoritmo PRBS a 14 bit utile per generare un intervallo temporale casiale tra l'uscita di un pachetto e il successivo
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.pgdaqPackage.all;


--!@copydoc PRBS14.vhd
entity PRBS14 is
	port(
	     iCLK			: in std_logic;								-- Segnale di clock
		  iRST			: in std_logic;								-- Segnale di reset
		  iPRBS14_en	: in std_logic;								-- Segnale di abilitazione del PRBS14
	     oDATA			: out std_logic_vector(13 downto 0)		-- Numero binario a 14 bit pseudo-casuale
	    );
end PRBS14;

--!@copydoc PRBS14.vhd
architecture Behavior of PRBS14 is
signal sDataReg	: std_logic_vector(13 downto 0);		-- Registro di 14 bit usato per realizzare lo shift register
signal sTapData	: std_logic;								-- Segnale dato dalla combinazione dei tap del registro

begin
	-- Instanziamento del Flip-Flop D per realizzare lo stage0 di uno shift register a 14 bit
	stage_0 : FFD
	port map(
				iCLK		=> iCLK,
				iRST		=> iRST,
				iENABLE	=> iPRBS14_en,
				iD			=> sTapData,
				oQ			=> sDataReg(0)
				);
	
	-- Instanziamento di ulteriori 13 Flip-Flop D per realizzare gli stage1...stage13 di uno shift register a 14 bit
	FFD_generator : for i in 0 to 12 generate
		stage_N : FFD
		port map(
				iCLK		=> iCLK,
				iRST		=> iRST,
				iENABLE	=> iPRBS14_en,
				iD			=> sDataReg(i),
				oQ			=> sDataReg(i+1)
				);
	end generate;
	
	
	-- Data Flow per la generazione del bit d'ingresso dello shift register
	-- I bit del registro che combineremo per ottenere il bit d'ingresso, sono definiti 'tap'.
	-- La scelta dei tap è legata alla periodicità della sequenza d'uscita.
	-- Affinché la periodicità dell'uscita dello shift register sia la più grande possibile,
	-- la funzione combinatoria per la generazione del bit d'ingresso deve essere associata
	-- a un polinomio "primitivo". In questo caso è stato scelto: x^14 + x^5 + x^3 + x^1 + 1.
	-- tap --> [esponente della 'x' - 1] --> 14-1, 5-1, 3-1, 1-1.
	sTapData <= (sDataReg(13) xor sDataReg(4) xor sDataReg(2) xor sDataReg(0));
	
	
	-- Data Flow per il cotrollo dell'uscita
	oDATA <= sDataReg;
	
	
end Behavior;