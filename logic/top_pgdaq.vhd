--!@file top_pgdaq.vhd
--!brief Top module of the pgdaq FPGA gateware
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.intel_package.all;
use work.pgdaqPackage.all;
use work.basic_package.all;


--!@copydoc top_pgdaq.vhd
entity top_pgdaq is
  generic (
    --HoG: Global Generic Variables
    GLOBAL_DATE : std_logic_vector(31 downto 0) := (others => '0');
    GLOBAL_TIME : std_logic_vector(31 downto 0) := (others => '0');
    GLOBAL_VER  : std_logic_vector(31 downto 0) := (others => '0');
    GLOBAL_SHA  : std_logic_vector(31 downto 0) := (others => '0');
    TOP_VER     : std_logic_vector(31 downto 0) := (others => '0');
    TOP_SHA     : std_logic_vector(31 downto 0) := (others => '0');
    CON_VER     : std_logic_vector(31 downto 0) := (others => '0');
    CON_SHA     : std_logic_vector(31 downto 0) := (others => '0');
    HOG_VER     : std_logic_vector(31 downto 0) := (others => '0');
    HOG_SHA     : std_logic_vector(31 downto 0) := (others => '0');

    --HoG: Project Specific Lists (One for each .src file in your Top/ folder)
    PGDAQ_SHA : std_logic_vector(31 downto 0) := (others => '0');
    PGDAQ_VER : std_logic_vector(31 downto 0) := (others => '0')
    );
  port(
    --- CLOCK ------------------------------------------------------------------
    FPGA_CLK1_50 : in std_logic;
    FPGA_CLK2_50 : in std_logic;
    FPGA_CLK3_50 : in std_logic;

    --- HDMI -------------------------------------------------------------------
    HDMI_I2C_SCL : inout std_logic;
    HDMI_I2C_SDA : inout std_logic;
    HDMI_I2S     : inout std_logic;
    HDMI_LRCLK   : inout std_logic;
    HDMI_MCLK    : inout std_logic;
    HDMI_SCLK    : inout std_logic;
    HDMI_TX_CLK  : out   std_logic;
    HDMI_TX_D    : out   std_logic_vector(23 downto 0);
    HDMI_TX_DE   : out   std_logic;
    HDMI_TX_HS   : out   std_logic;
    HDMI_TX_INT  : in    std_logic;
    HDMI_TX_VS   : out   std_logic;

    --- HPS --------------------------------------------------------------------
    HPS_CONV_USB_N   : inout std_logic;
    HPS_DDR3_ADDR    : out   std_logic_vector(14 downto 0);
    HPS_DDR3_BA      : out   std_logic_vector(2 downto 0);
    HPS_DDR3_CAS_N   : out   std_logic;
    HPS_DDR3_CK_N    : out   std_logic;
    HPS_DDR3_CK_P    : out   std_logic;
    HPS_DDR3_CKE     : out   std_logic;
    HPS_DDR3_CS_N    : out   std_logic;
    HPS_DDR3_DM      : out   std_logic_vector(3 downto 0);
    HPS_DDR3_DQ      : inout std_logic_vector(31 downto 0);
    HPS_DDR3_DQS_N   : inout std_logic_vector(3 downto 0);
    HPS_DDR3_DQS_P   : inout std_logic_vector(3 downto 0);
    HPS_DDR3_ODT     : out   std_logic;
    HPS_DDR3_RAS_N   : out   std_logic;
    HPS_DDR3_RESET_N : out   std_logic;
    HPS_DDR3_RZQ     : in    std_logic;
    HPS_DDR3_WE_N    : out   std_logic;
    HPS_ENET_GTX_CLK : out   std_logic;
    HPS_ENET_INT_N   : inout std_logic;
    HPS_ENET_MDC     : out   std_logic;
    HPS_ENET_MDIO    : inout std_logic;
    HPS_ENET_RX_CLK  : in    std_logic;
    HPS_ENET_RX_DATA : in    std_logic_vector(3 downto 0);
    HPS_ENET_RX_DV   : in    std_logic;
    HPS_ENET_TX_DATA : out   std_logic_vector(3 downto 0);
    HPS_ENET_TX_EN   : out   std_logic;
    HPS_GSENSOR_INT  : inout std_logic;
    HPS_I2C0_SCLK    : inout std_logic;
    HPS_I2C0_SDAT    : inout std_logic;
    HPS_I2C1_SCLK    : inout std_logic;
    HPS_I2C1_SDAT    : inout std_logic;
    HPS_KEY          : inout std_logic;
    HPS_LED          : inout std_logic;
    HPS_LTC_GPIO     : inout std_logic;
    HPS_SD_CLK       : out   std_logic;
    HPS_SD_CMD       : inout std_logic;
    HPS_SD_DATA      : inout std_logic_vector(3 downto 0);
    HPS_SPIM_CLK     : out   std_logic;
    HPS_SPIM_MISO    : in    std_logic;
    HPS_SPIM_MOSI    : out   std_logic;
    HPS_SPIM_SS      : inout std_logic;
    HPS_UART_RX      : in    std_logic;
    HPS_UART_TX      : out   std_logic;
    HPS_USB_CLKOUT   : in    std_logic;
    HPS_USB_DATA     : inout std_logic_vector(7 downto 0);
    HPS_USB_DIR      : in    std_logic;
    HPS_USB_NXT      : in    std_logic;
    HPS_USB_STP      : out   std_logic;

    --- KEY --------------------------------------------------------------------
    KEY : in std_logic_vector(1 downto 0);

    --- LED --------------------------------------------------------------------
    LED : out std_logic_vector(7 downto 0);

    --- SW ---------------------------------------------------------------------
    SW : in std_logic_vector(3 downto 0)
    );
end entity top_pgdaq;

--!@copydoc top_pgdaq.vhd
architecture std of top_pgdaq is
-------------------------------------------------------------
signal hps_fpga_reset_n       : std_logic;
signal fpga_debounced_buttons : std_logic_vector(1 downto 0);
signal fpga_led_internal      : std_logic_vector(6 downto 0);
signal hps_reset_req          : std_logic_vector(2 downto 0);
signal hps_cold_reset         : std_logic;
signal hps_warm_reset         : std_logic;
signal hps_debug_reset        : std_logic;
signal stm_hw_events          : std_logic_vector(27 downto 0);
signal fpga_clk_50            : std_logic;

-- Set di segnali ausiliari
signal 	neg_fpga_debounced_buttons : std_logic_vector(1 downto 0);	 -- debounced_bottons in logica positiva
signal 	neg_hps_fpga_reset_n		   : std_logic;							 -- segnale interno di RESET in logica positiva
signal 	inverter_hps_cold_reset    : std_logic; 							 -- FIX BUG MODEL SIM
signal 	inverter_hps_warm_reset    : std_logic; 							 -- FIX BUG MODEL SIM
signal 	inverter_hps_debug_reset   : std_logic; 							 -- FIX BUG MODEL SIM
signal	h2f_user_clock					: std_logic;							 -- 100 MHz user clock by HPS

-- Set di segnali per pilotare la fifo FPGA --> HPS contenente dati scientifici
signal fast_fifo_f2h_data_in	 		 : std_logic_vector(31 downto 0);	 -- Data
signal fast_fifo_f2h_wr_en				 : std_logic;								 -- Write Enable
signal fast_fifo_f2h_full				 : std_logic;								 -- Fifo Full
signal fast_fifo_f2h_addr_csr			 : std_logic_vector(2 downto 0);
signal fast_fifo_f2h_rd_en_csr		 : std_logic;
signal fast_fifo_f2h_data_in_csr		 : std_logic_vector(31 downto 0);
signal fast_fifo_f2h_wr_en_csr		 : std_logic;
signal fast_fifo_f2h_data_out_csr	 : std_logic_vector(31 downto 0);

-- Set di segnali per pilotare la fifo FPGA --> HPS contenente dati di telemetria
signal fifo_f2h_data_in	 		 : std_logic_vector(31 downto 0);	 -- Data
signal fifo_f2h_wr_en			 : std_logic;								 -- Write Enable
signal fifo_f2h_full				 : std_logic;								 -- Fifo Full
signal fifo_f2h_addr_csr		 : std_logic_vector(2 downto 0);
signal fifo_f2h_rd_en_csr		 : std_logic;
signal fifo_f2h_data_in_csr	 : std_logic_vector(31 downto 0);
signal fifo_f2h_wr_en_csr		 : std_logic;
signal fifo_f2h_data_out_csr	 : std_logic_vector(31 downto 0);

-- Set di segnali per pilotare la fifo HPS --> FPGA contenente dati di configurazione
signal fifo_h2f_data_out	 	 : std_logic_vector(31 downto 0);	 -- Data
signal fifo_h2f_rd_en			 : std_logic;								 -- Read Enable
signal fifo_h2f_empty			 : std_logic;								 -- Fifo Empty
signal fifo_h2f_addr_csr		 : std_logic_vector(2 downto 0);
signal fifo_h2f_rd_en_csr		 : std_logic;
signal fifo_h2f_data_in_csr	 : std_logic_vector(31 downto 0);
signal fifo_h2f_wr_en_csr		 : std_logic;
signal fifo_h2f_data_out_csr	 : std_logic_vector(31 downto 0);

-- Set di segnali di interconnessione tra i moduli istanziati
signal warning_rx			 		: std_logic_vector(2 downto 0);		-- Segnale di avviso dei malfunzionamenti del Config_Receiver. "000"-->ok, "001"-->errore sui bit di parità, "010"-->errore nella struttura del pacchetto (word missed), "100"-->errore generico (ad esempio se la macchina finisce in uno stato non precisato).
signal sFIFO_DATA_sup_out		: std_logic_vector(31 downto 0);		-- Dati in uscita dalla FIFO a monte del FastData_Transmitter
signal sFIFO_EMPTY_sup			: std_logic;								-- "Empty" della FIFO a monte del FastData_Transmitter
signal sFIFO_AEMPTY_sup			: std_logic;								-- "Almost Empty" della FIFO a monte del FastData_Transmitter
signal sFIFO_RE_sup				: std_logic;								-- "Read Enable" della FIFO a monte del FastData_Transmitter
signal sFIFO_AFULL_inf			: std_logic;								-- "Almost Full" della FIFO a valle del FastData_Transmitter
signal sFIFO_AFULL_sup			: std_logic;								-- "Almost Full" della FIFO a monte del FastData_Transmitter
signal sDATA						: std_logic_vector(31 downto 0);		-- Dato pseudocasuale in uscita dal generatore PRBS a 32 bit
signal sDATA_VALID				: std_logic;								-- Consistenza del dato pseudocasuale in uscita dal generatore PRBS a 32 bit


begin
  -- connection of internal logics ----------------------------
  fpga_clk_50   <= FPGA_CLK1_50;
  stm_hw_events <= "000000000000000" & SW & fpga_led_internal & fpga_debounced_buttons;

  neg_fpga_debounced_buttons	 <= not fpga_debounced_buttons;  -- Siccome i bottoni dell'FPGA lavorano in logica negata mentre i nostri moduli in logica positiva, invertiamo il loro comportamento.
  --neg_hps_fpga_reset_n			 <= not hps_fpga_reset_n;

  -- Il reset fornito dal soc_system utilizza la logica negata. Invertiamo il valore per adattarlo ai nostri moduli, che invece lavorano in logica positva.
  sync_stage_i : sync_stage
  generic map (
    pSTAGES => 3
    )
  port map (
    iCLK => h2f_user_clock,
    iRST => '0',
    iD   => not hps_fpga_reset_n,
    oQ   => neg_hps_fpga_reset_n
    );


  inverter_hps_cold_reset  <= not hps_cold_reset;   --FIX BUG MODEL SIM
  inverter_hps_warm_reset  <= not hps_warm_reset;   --FIX BUG MODEL SIM
  inverter_hps_debug_reset <= not hps_debug_reset;  --FIX BUG MODEL SIM

  --!@brief HPS instance
  SoC_inst : soc_system port map (
    --Clock&Reset
    clk_clk                               => FPGA_CLK1_50,  -- clk.clk
    reset_reset_n                         => hps_fpga_reset_n,  -- reset.reset_n
    --HPS ddr3
    memory_mem_a                          => HPS_DDR3_ADDR,  --  memory.mem_a
    memory_mem_ba                         => HPS_DDR3_BA,  -- .mem_ba
    memory_mem_ck                         => HPS_DDR3_CK_P,  -- .mem_ck
    memory_mem_ck_n                       => HPS_DDR3_CK_N,  -- .mem_ck_n
    memory_mem_cke                        => HPS_DDR3_CKE,  -- .mem_cke
    memory_mem_cs_n                       => HPS_DDR3_CS_N,  -- .mem_cs_n
    memory_mem_ras_n                      => HPS_DDR3_RAS_N,  -- .mem_ras_n
    memory_mem_cas_n                      => HPS_DDR3_CAS_N,  -- .mem_cas_n
    memory_mem_we_n                       => HPS_DDR3_WE_N,  -- .mem_we_n
    memory_mem_reset_n                    => HPS_DDR3_RESET_N,  -- .mem_reset_n
    memory_mem_dq                         => HPS_DDR3_DQ,  -- .mem_dq
    memory_mem_dqs                        => HPS_DDR3_DQS_P,  -- .mem_dqs
    memory_mem_dqs_n                      => HPS_DDR3_DQS_N,  -- .mem_dqs_n
    memory_mem_odt                        => HPS_DDR3_ODT,  -- .mem_odt
    memory_mem_dm                         => HPS_DDR3_DM,  -- .mem_dm
    memory_oct_rzqin                      => HPS_DDR3_RZQ,  -- .oct_rzqin
    --HPS ethernet
    hps_0_hps_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK,  -- hps_0_hps_io.hps_io_emac1_inst_TX_CLK
    hps_0_hps_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0),  -- .hps_io_emac1_inst_TXD0
    hps_0_hps_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1),  -- .hps_io_emac1_inst_TXD1
    hps_0_hps_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2),  -- .hps_io_emac1_inst_TXD2
    hps_0_hps_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3),  -- .hps_io_emac1_inst_TXD3
    hps_0_hps_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0),  -- .hps_io_emac1_inst_RXD0
    hps_0_hps_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO,  -- .hps_io_emac1_inst_MDIO
    hps_0_hps_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC,  -- .hps_io_emac1_inst_MDC
    hps_0_hps_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV,  -- .hps_io_emac1_inst_RX_CTL
    hps_0_hps_io_hps_io_emac1_inst_TX_CTL => HPS_ENET_TX_EN,  -- .hps_io_emac1_inst_TX_CTL
    hps_0_hps_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK,  -- .hps_io_emac1_inst_RX_CLK
    hps_0_hps_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1),  -- .hps_io_emac1_inst_RXD1
    hps_0_hps_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2),  -- .hps_io_emac1_inst_RXD2
    hps_0_hps_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3),  -- .hps_io_emac1_inst_RXD3
    --HPS SD card
    hps_0_hps_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD,  -- .hps_io_sdio_inst_CMD
    hps_0_hps_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0),  -- .hps_io_sdio_inst_D0
    hps_0_hps_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1),  -- .hps_io_sdio_inst_D1
    hps_0_hps_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK,  -- .hps_io_sdio_inst_CLK
    hps_0_hps_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2),  -- .hps_io_sdio_inst_D2
    hps_0_hps_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3),  -- .hps_io_sdio_inst_D3
    --HPS USB
    hps_0_hps_io_hps_io_usb1_inst_D0      => HPS_USB_DATA(0),  -- .hps_io_usb1_inst_D0
    hps_0_hps_io_hps_io_usb1_inst_D1      => HPS_USB_DATA(1),  -- .hps_io_usb1_inst_D1
    hps_0_hps_io_hps_io_usb1_inst_D2      => HPS_USB_DATA(2),  -- .hps_io_usb1_inst_D2
    hps_0_hps_io_hps_io_usb1_inst_D3      => HPS_USB_DATA(3),  -- .hps_io_usb1_inst_D3
    hps_0_hps_io_hps_io_usb1_inst_D4      => HPS_USB_DATA(4),  -- .hps_io_usb1_inst_D4
    hps_0_hps_io_hps_io_usb1_inst_D5      => HPS_USB_DATA(5),  -- .hps_io_usb1_inst_D5
    hps_0_hps_io_hps_io_usb1_inst_D6      => HPS_USB_DATA(6),  -- .hps_io_usb1_inst_D6
    hps_0_hps_io_hps_io_usb1_inst_D7      => HPS_USB_DATA(7),  -- .hps_io_usb1_inst_D7
    hps_0_hps_io_hps_io_usb1_inst_CLK     => HPS_USB_CLKOUT,  -- .hps_io_usb1_inst_CLK
    hps_0_hps_io_hps_io_usb1_inst_STP     => HPS_USB_STP,  -- .hps_io_usb1_inst_STP
    hps_0_hps_io_hps_io_usb1_inst_DIR     => HPS_USB_DIR,  -- .hps_io_usb1_inst_DIR
    hps_0_hps_io_hps_io_usb1_inst_NXT     => HPS_USB_NXT,  -- .hps_io_usb1_inst_NXT
    --HPS SPI
    hps_0_hps_io_hps_io_spim1_inst_CLK    => HPS_SPIM_CLK,  -- .hps_io_spim1_inst_CLK
    hps_0_hps_io_hps_io_spim1_inst_MOSI   => HPS_SPIM_MOSI,  -- .hps_io_spim1_inst_MOSI
    hps_0_hps_io_hps_io_spim1_inst_MISO   => HPS_SPIM_MISO,  -- .hps_io_spim1_inst_MISO
    hps_0_hps_io_hps_io_spim1_inst_SS0    => HPS_SPIM_SS,  -- .hps_io_spim1_inst_SS0
    --HPS UART
    hps_0_hps_io_hps_io_uart0_inst_RX     => HPS_UART_RX,  -- .hps_io_uart0_inst_RX
    hps_0_hps_io_hps_io_uart0_inst_TX     => HPS_UART_TX,  -- .hps_io_uart0_inst_TX
    --HPS I2C1
    hps_0_hps_io_hps_io_i2c0_inst_SDA     => HPS_I2C0_SDAT,  -- .hps_io_i2c0_inst_SDA
    hps_0_hps_io_hps_io_i2c0_inst_SCL     => HPS_I2C0_SCLK,  -- .hps_io_i2c0_inst_SCL
    --HPS I2C2
    hps_0_hps_io_hps_io_i2c1_inst_SDA     => HPS_I2C1_SDAT,  -- .hps_io_i2c1_inst_SDA
    hps_0_hps_io_hps_io_i2c1_inst_SCL     => HPS_I2C1_SCLK,  -- .hps_io_i2c1_inst_SCL
    --GPIO
    hps_0_hps_io_hps_io_gpio_inst_GPIO09  => HPS_CONV_USB_N,  -- .hps_io_gpio_inst_GPIO09
    hps_0_hps_io_hps_io_gpio_inst_GPIO35  => HPS_ENET_INT_N,  -- .hps_io_gpio_inst_GPIO35
    hps_0_hps_io_hps_io_gpio_inst_GPIO40  => HPS_LTC_GPIO,  -- .hps_io_gpio_inst_GPIO40
    hps_0_hps_io_hps_io_gpio_inst_GPIO53  => HPS_LED,  -- .hps_io_gpio_inst_GPIO53
    hps_0_hps_io_hps_io_gpio_inst_GPIO54  => HPS_KEY,  -- .hps_io_gpio_inst_GPIO54
    hps_0_hps_io_hps_io_gpio_inst_GPIO61  => HPS_GSENSOR_INT,  -- .hps_io_gpio_inst_GPIO61
    --FPGA Partion
    led_pio_external_connection_export    => fpga_led_internal,  -- led_pio_external_connection.export
    dipsw_pio_external_connection_export  => SW,  -- dipsw_pio_external_connection.export
    button_pio_external_connection_export => fpga_debounced_buttons,  -- button_pio_external_connection.export
    hps_0_h2f_reset_reset_n               => hps_fpga_reset_n,  -- hps_0_h2f_reset.reset_n
    hps_0_f2h_cold_reset_req_reset_n      => inverter_hps_cold_reset,  -- hps_0_f2h_cold_reset_req.reset_n                   (BUG MODEL SIM FIXED)
    hps_0_f2h_debug_reset_req_reset_n     => inverter_hps_debug_reset,  -- hps_0_f2h_debug_reset_req.reset_n                 (BUG MODEL SIM FIXED)
    hps_0_f2h_stm_hw_events_stm_hwevents  => stm_hw_events,  -- hps_0_f2h_stm_hw_events.stm_hwevents
    hps_0_f2h_warm_reset_req_reset_n      => inverter_hps_warm_reset,  -- hps_0_f2h_warm_reset_req.reset_n                   (BUG MODEL SIM FIXED)
	 hps_0_h2f_user0_clock_clk  				=> h2f_user_clock,       -- hps_0_h2f_user0_clock.clk

    --Fifo Partion
   fast_fifo_fpga_to_hps_clk_clk          => h2f_user_clock,          --      fast_fifo_fpga_to_hps_clk.clk
   fast_fifo_fpga_to_hps_rst_reset_n      => '1',       --      fast_fifo_fpga_to_hps_rst.reset_n
	 fast_fifo_fpga_to_hps_in_writedata			=> fast_fifo_f2h_data_in, 			 --	  fifo_fpga_to_hps_in.writedata
	 fast_fifo_fpga_to_hps_in_write				=> fast_fifo_f2h_wr_en,     		 -- 								.write
    fast_fifo_fpga_to_hps_in_waitrequest		=> fast_fifo_f2h_full,				 -- 								.waitrequest
    fast_fifo_fpga_to_hps_in_csr_address		=> fast_fifo_f2h_addr_csr,			 -- fifo_fpga_to_hps_in_csr.address
    fast_fifo_fpga_to_hps_in_csr_read			=> fast_fifo_f2h_rd_en_csr,	    -- 								.read
    fast_fifo_fpga_to_hps_in_csr_writedata	=> fast_fifo_f2h_data_in_csr,		 -- 								.writedata
    fast_fifo_fpga_to_hps_in_csr_write			=> fast_fifo_f2h_wr_en_csr,		 -- 								.write
    fast_fifo_fpga_to_hps_in_csr_readdata		=> fast_fifo_f2h_data_out_csr,	 -- 								.readdata

   fifo_fpga_to_hps_clk_clk               => h2f_user_clock,               --           fifo_fpga_to_hps_clk.clk
   fifo_fpga_to_hps_rst_reset_n           => '1',           --           fifo_fpga_to_hps_rst.reset_n
	 fifo_fpga_to_hps_in_writedata		 => fifo_f2h_data_in, 			 --	  fast_fifo_fpga_to_hps_in.writedata
	 fifo_fpga_to_hps_in_write				 => fifo_f2h_wr_en,     		 -- 									  .write
	 fifo_fpga_to_hps_in_waitrequest		 => fifo_f2h_full,				 -- 								     .waitrequest
	 fifo_fpga_to_hps_in_csr_address		 => fifo_f2h_addr_csr,			 -- fast_fifo_fpga_to_hps_in_csr.address
 	 fifo_fpga_to_hps_in_csr_read			 => fifo_f2h_rd_en_csr,		    -- 								     .read
	 fifo_fpga_to_hps_in_csr_writedata	 => fifo_f2h_data_in_csr,		 -- 								     .writedata
	 fifo_fpga_to_hps_in_csr_write		 => fifo_f2h_wr_en_csr,			 -- 								     .write
	 fifo_fpga_to_hps_in_csr_readdata	 => fifo_f2h_data_out_csr,		 -- 								     .readdata

   fifo_hps_to_fpga_clk_clk => h2f_user_clock,  --fifo_hps_to_fpga_clk.clk
   fifo_hps_to_fpga_rst_reset_n => '1',  --fifo_hps_to_fpga_rst.reset_n
	 fifo_hps_to_fpga_out_readdata		 => fifo_h2f_data_out,			 --	  fifo_fpga_to_hps_in.writedata
	 fifo_hps_to_fpga_out_read				 => fifo_h2f_rd_en,         	 -- 						      .write
	 fifo_hps_to_fpga_out_waitrequest	 => fifo_h2f_empty,				 --						 	   .waitrequest
	 fifo_hps_to_fpga_out_csr_address	 => fifo_h2f_addr_csr,			 -- fifo_fpga_to_hps_in_csr.address
	 fifo_hps_to_fpga_out_csr_read		 => fifo_h2f_rd_en_csr,			 --							   .read
	 fifo_hps_to_fpga_out_csr_writedata	 => fifo_h2f_data_in_csr,		 -- 								.writedata
	 fifo_hps_to_fpga_out_csr_write		 => fifo_h2f_wr_en_csr,			 -- 								.write
	 fifo_hps_to_fpga_out_csr_readdata	 => fifo_h2f_data_out_csr		 -- 								.readdata
	 );

  --!@brief Debounce logic to clean out glitches within 1ms
  debounce_inst : debounce generic map(
    WIDTH         => 2,
    POLARITY      => "LOW",
    TIMEOUT       => 50000,  -- at 50Mhz this is a debounce time of 1ms
    TIMEOUT_WIDTH => 16                 -- ceil(log2(TIMEOUT))
    ) port map (
      clk      => fpga_clk_50,
      reset_n  => hps_fpga_reset_n,
      data_in  => KEY,
      data_out => fpga_debounced_buttons
      );

  --!@brief Source/Probe megawizard instance
  hps_reset_inst : hps_reset port map(
    probe      => '0',
    source_clk => fpga_clk_50,
    source     => hps_reset_req
    );

  --!@brief Edge detector
  pulse_cold_reset : altera_edge_detector generic map(
    PULSE_EXT             => 6,
    EDGE_TYPE             => 1,
    IGNORE_RST_WHILE_BUSY => 1
    ) port map (
      clk       => fpga_clk_50,
      rst_n     => hps_fpga_reset_n,
      signal_in => hps_reset_req(0),
      pulse_out => hps_cold_reset
      );

  --!@brief Edge detector
  pulse_warm_reset : altera_edge_detector generic map (
    PULSE_EXT             => 2,
    EDGE_TYPE             => 1,
    IGNORE_RST_WHILE_BUSY => 1
    ) port map (
      clk       => fpga_clk_50,
      rst_n     => hps_fpga_reset_n,
      signal_in => hps_reset_req(1),
      pulse_out => hps_warm_reset
      );

  --!@brief Edge detector
  pulse_debug_reset : altera_edge_detector generic map(
    PULSE_EXT             => 32,
    EDGE_TYPE             => 1,
    IGNORE_RST_WHILE_BUSY => 1
    ) port map (
      clk       => fpga_clk_50,
      rst_n     => hps_fpga_reset_n,
      signal_in => hps_reset_req(2),
      pulse_out => hps_debug_reset
      );

	-- Interfaccia di comunicazione tra FPGA e HPS per i dati di controllo
	HPS_interface : HPS_intf
	generic map(AF_HK_FIFO => cF2H_AFULL)
	port map(
				iCLK_intf			=> h2f_user_clock,
				iRST_intf			=> neg_hps_fpga_reset_n,
				iFWV_intf			=> PGDAQ_SHA,
				iFIFO_H2F_WR		=> fifo_h2f_empty,
				iFIFO_H2F_DATA		=> fifo_h2f_data_out,
				oFIFO_H2F_RE		=> fifo_h2f_rd_en,
				oFIFO_H2F_WARN		=> warning_rx,
				iREGISTER_ARRAY	=> ((others => '0'),(others => '0'), '0'),
				iHKREADER_START	=> '1',
				iFIFO_F2H_LEVEL	=> fifo_f2h_data_out_csr,
				oFIFO_F2H_WE		=> fifo_f2h_wr_en,
				oFIFO_F2H_DATA		=> fifo_f2h_data_in
				);

	-- Generatore di dati pseudocasuali a 32 bit
	data_generator_proc : Test_Unit
	port map(
				iCLK			=> h2f_user_clock,
				iRST			=> neg_hps_fpga_reset_n,
				iEN			=> not sFIFO_AFULL_sup,
				oDATA			=> sDATA,
				oDATA_VALID	=> sDATA_VALID
				);

	-- FIFO a cavallo tra il PRBS e il FastData_Transmitter
	fifo_monte : parametric_fifo_synch
	generic map(
					 pWIDTH       => 32,
					 pDEPTH       => 4096,
					 pUSEDW_WIDTH => ceil_log2(4096),
					 pAEMPTY_VAL  => 2,
					 pAFULL_VAL   => 4086,
					 pSHOW_AHEAD  => "OFF"
					)
	port map(
				iCLK    => h2f_user_clock,
				iRST    => neg_hps_fpga_reset_n,
				-- control interface
				oAEMPTY => sFIFO_AEMPTY_sup,
				oEMPTY  => sFIFO_EMPTY_sup,
				oAFULL  => sFIFO_AFULL_sup,
				iRD_REQ => sFIFO_RE_sup,
				iWR_REQ => sDATA_VALID,
				-- data interface
				iDATA   => sDATA,
				oQ      => sFIFO_DATA_sup_out
				);

	-- Trasmettitore dati veloci
	 FIFO_f2h_fast_transmitter : FastData_Transmitter
	 port map(
			    iCLK 					=> h2f_user_clock,
			    iRST 					=> neg_hps_fpga_reset_n,
			    -- Enable
			    iEN 						=> '1',
			    -- Settings Packet
			    iSettingLength 		=> x"0000006e",
			    iFirmwareVersion 	=> x"12345678",
			    iSettingTrigNum		=> x"00000001",
			    iSettingTrigDet	 	=> x"23",
			    iSettingTrigID		=> x"45",
			    iSettingIntTime		=> x"1a1a1a1a1b1b1b1b",
			    iSettingExtTime 		=> x"2a2a2a2a2b2b2b2b",
			    -- Fifo Management
			    iFIFO_DATA				=> sFIFO_DATA_sup_out,
			    iFIFO_EMPTY 			=> sFIFO_EMPTY_sup,
			    iFIFO_AEMPTY			=> sFIFO_AEMPTY_sup,
			    oFIFO_RE 				=> sFIFO_RE_sup,
			    oFIFO_DATA 			=> fast_fifo_f2h_data_in,
			    iFIFO_AFULL 			=> sFIFO_AFULL_inf,
			    oFIFO_WE				=> fast_fifo_f2h_wr_en,
			    -- Output Flag
			    oBUSY	 				=> open,
			    oWARNING				=> open
			    );

	-- Generazione del segnale di Almost Full della FIFO a valle del FastData_Transmitter in funzione del livello di riempimento della stessa
	Almost_Full_proc : process (fast_fifo_f2h_data_out_csr)
	begin
		if (fast_fifo_f2h_data_out_csr > cFastF2H_AFULL) then
			sFIFO_AFULL_inf <= '1';	-- Se il livello della FIFO è maggiore o uguale della soglia di almost full  ----> sFIFO_AFULL_inf = '1'
		else
			sFIFO_AFULL_inf <= '0';	-- Altrimenti, sFifoAfull = '0'
		end if;
	end process;


	-- Data Flow per il controllo della FIFO di Housekeeping
	fifo_f2h_addr_csr		<= "000";	--> fifo_f2h_data_out_csr = Level_Fifo
	fifo_f2h_rd_en_csr	<= '1';		--> Aggiorna Level_Fifo ogni ciclo di clock

	-- Data Flow per il controllo della FIFO Fast_Data
	fast_fifo_f2h_addr_csr		<= "000";	--> fast_fifo_f2h_data_out_csr = Level_Fifo
	fast_fifo_f2h_rd_en_csr		<= '1';		--> Aggiorna Level_Fifo ogni ciclo di clock


end architecture;
