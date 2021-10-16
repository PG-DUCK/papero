-------------------------------------------------------
--------  PSEUDO RANDOM BINARY SEQUENCE 8bit  --------
-------------------------------------------------------
--!@file PRBS8.vhd
--!@brief Implementazione di un algoritmo PRBS a 8 bit utile per generare un intervallo temporale casuale tra l'uscita di un pachetto e il successivo
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use work.paperoPackage.all;


--!@copydoc PRBS8.vhd
entity PRBS8 is
  port(
    iCLK      : in  std_logic;          -- Segnale di clock
    iRST      : in  std_logic;          -- Segnale di reset
    iPRBS8_en : in  std_logic;          -- Segnale di abilitazione del PRBS8
    oDATA     : out std_logic_vector(7 downto 0)  -- Numero binario a 8 bit pseudo-casuale
    );
end PRBS8;

--!@copydoc PRBS8.vhd
architecture Behavior of PRBS8 is
  signal sDataReg : std_logic_vector(7 downto 0);  -- Registro di 8 bit usato per realizzare lo shift register
  signal sTapData : std_logic;  -- Segnale dato dalla combinazione dei tap del registro

begin
  -- Instanziamento del Flip-Flop D per realizzare lo stage0 di uno shift register a 8 bit
  stage_0 : FFD
    port map(
      iCLK    => iCLK,
      iRST    => iRST,
      iENABLE => iPRBS8_en,
      iD      => sTapData,
      oQ      => sDataReg(0)
      );

  -- Instanziamento di ulteriori 7 Flip-Flop D per realizzare gli stage1...stage7 di uno shift register a 8 bit
  FFD_generator : for i in 0 to 6 generate
    stage_N : FFD
      port map(
        iCLK    => iCLK,
        iRST    => iRST,
        iENABLE => iPRBS8_en,
        iD      => sDataReg(i),
        oQ      => sDataReg(i+1)
        );
  end generate;


  -- Data Flow per la generazione del bit d'ingresso dello shift register
  -- I bit del registro che combineremo per ottenere il bit d'ingresso, sono definiti 'tap'.
  -- La scelta dei tap è legata alla periodicità della sequenza d'uscita.
  -- Affinché la periodicità dell'uscita dello shift register sia la più grande possibile,
  -- la funzione combinatoria per la generazione del bit d'ingresso deve essere associata
  -- a un polinomio "primitivo". In questo caso è stato scelto: x^8 + x^4 + x^3 + x^2 + 1.
  -- tap --> [esponente della 'x' - 1] --> 8-1, 4-1, 3-1, 2-1.
  sTapData <= (sDataReg(7) xor sDataReg(3) xor sDataReg(2) xor sDataReg(1));


  -- Data Flow per il cotrollo dell'uscita
  oDATA <= sDataReg;


end Behavior;
