-----------------------------------------
--------  FLIP FLOP DI TIPO 'D'  --------
-----------------------------------------
--!@file FFD.vhd
--!@brief Flip-Flop di tipo 'D' utilizzati come unità di base per realizzare gli shift register dei moduli PRBS
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;


--!@copydoc FFD.vhd
entity FFD is
  port(
    iCLK    : in  std_logic;            -- Segnale di clock
    iRST    : in  std_logic;            -- Segnale di reset
    iENABLE : in  std_logic;            -- Segnale di enable del dispositivo
    iD      : in  std_logic;            -- Porta d'ingresso per i dati
    oQ      : out std_logic  -- Il segnale d'uscita è la copia del segnale d'ingresso ritardata di un ciclo di clock
    );
end FFD;


--!@copydoc FFD.vhd
architecture Behavior of FFD is

begin
  process (iCLK)
  begin
    if rising_edge(iCLK) then
      if (iRST = '1') then  -- ATTENZIONE, l'attivazione del segnale di "reset" porta l'uscita alta.
        oQ <= '1';  -- Questo perché tale Flip-Flop è pensato per lavorare in un modulo PRBS.
      elsif (iENABLE = '1') then
        oQ <= iD;  -- Se il segnale di "reset" non è attivo ma quello di enable si, l'uscita segue l'ingresso.
      end if;  -- Altrimenti (se il segnale di enable non è attivo) l'uscita rimane invariata.
    end if;
  end process;


end Behavior;
