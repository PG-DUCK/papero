--!@file Key_Pulse_Gen.vhd
--!@brief Genera un impulso ad ogni pressione di un pulsante
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

use work.intel_package.all;
use work.pgdaqPackage.all;

--!@copydoc Key_Pulse_Gen.vhd
entity Key_Pulse_Gen is
  port(KPG_CLK_in   : in  std_logic;
       KPG_DATA_in  : in  std_logic_vector(1 downto 0);
       KPG_DATA_out : out std_logic_vector(1 downto 0)
       );
end Key_Pulse_Gen;

--!@copydoc Key_Pulse_Gen.vhd
architecture Behavior of Key_Pulse_Gen is

  signal vcc                : std_logic                    := '1';
  signal gnd                : std_logic                    := '0';
  signal KPG_DATA_debounced : std_logic_vector(1 downto 0) := (others => '0');
  signal KPG_DATA_inverted  : std_logic_vector(1 downto 0) := (others => '0');

begin
  --!@brief Debounce logic to clean out glitches within 1ms
  debounce_inst : debounce
    generic map(WIDTH         => 2,
                POLARITY      => "LOW",
                TIMEOUT       => 50000,  -- at 50Mhz this is a debounce time of 1ms
                TIMEOUT_WIDTH => 16     -- ceil(log2(TIMEOUT))
                )
    port map (clk      => KPG_CLK_in,
              reset_n  => vcc,
              data_in  => KPG_DATA_in,
              data_out => KPG_DATA_debounced
              );

  KPG_DATA_inverted <= not KPG_DATA_debounced;

  -- Instanziamento dello User Edge Detector
  rise_edge_implementation : edge_detector_md
    generic map(channels => 2, R_vs_F => '0')
    port map(iCLK  => KPG_CLK_in,
             iRST  => gnd,
             iD    => KPG_DATA_inverted,
             oEDGE => KPG_DATA_out
             );


end Behavior;
