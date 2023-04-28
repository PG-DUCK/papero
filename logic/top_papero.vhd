--!@file top_papero.vhd
--!@brief Example of top module of the papero FPGA gateware.
--!@details
--!
--!Instantiates HPS, the TDAQ module, and the ancillatry electronics.
--!To add a detector readout:
--!  - Connect the detector interface to the fast interface of the TDAQ module.
--!  - Add the needed pin to the ports and the papero_pins.qsf file.
--!
--!@todo Add reset to the HPS-FPGA fifos
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.intel_package.all;
use work.paperoPackage.all;
use work.basic_package.all;


--!@copydoc top_papero.vhd
entity top_papero is
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
    PAPERO_SHA : std_logic_vector(31 downto 0) := (others => '0');
    PAPERO_VER : std_logic_vector(31 downto 0) := (others => '0')
    );
  port(
    --- CLOCK ------------------------------------------------------------------
    FPGA_CLK1_50 : in std_logic;
    FPGA_CLK2_50 : in std_logic;
    FPGA_CLK3_50 : in std_logic;

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
    SW : in std_logic_vector(3 downto 0);

    --- GPIO -------------------------------------------------------------------
    GPIO_1 : in std_logic_vector(35 downto 0);

    --Central Acquisition side (GPIO_0)
    iBCO_CLK       : in  std_logic;     --GPIO0-16
    iBCO_RST       : in  std_logic;     --GPIO0-0
    iEXT_TRIG      : in  std_logic;     --GPIO0-32
    oBUSY          : out std_logic;     --GPIO0-1
    oTRIG          : out std_logic;     --GPIO0-27

    oHK : out std_logic_vector(30 downto 0)  --All the remainings

    );
end entity top_papero;

--!@copydoc top_papero.vhd
architecture std of top_papero is
  --HPS signals
  signal hps_fpga_reset_n       : std_logic;
  signal fpga_debounced_buttons : std_logic_vector(1 downto 0);
  signal fpga_led_internal      : std_logic_vector(6 downto 0);
  signal hps_reset_req          : std_logic_vector(2 downto 0);
  signal hps_cold_reset         : std_logic;
  signal hps_warm_reset         : std_logic;
  signal hps_debug_reset        : std_logic;
  signal stm_hw_events          : std_logic_vector(27 downto 0);
  signal fpga_clk_50            : std_logic;
  signal sRegAddrPio            : std_logic_vector(31 downto 0);
  signal sRegContentPio         : std_logic_vector(31 downto 0);
  signal sRegAddrInt, sRegAddrSyn : std_logic_vector(31 downto 0);
  signal sRegContentInt, sRegContentSyn : std_logic_vector(31 downto 0);

  -- Auxiliaries
  signal fpga_debounced_buttons_n : std_logic_vector(1 downto 0);  -- debounced buttons (positive logic)
  signal hps_fpga_reset_n_synch   : std_logic;  -- RESET (positive logic)
  signal hps_cold_rst_n           : std_logic;
  signal hps_warm_rst_n           : std_logic;
  signal hps_debug_rst_n          : std_logic;
  signal sClk                     : std_logic;  -- FPGA clock
  signal h2f_clk_50MHz            : std_logic;  -- User clock (50 MHz) from HPS
  signal h2f_clk_96MHz            : std_logic;  -- User clock (96 MHz) from HPS

  -- FPGA --> HPS FIFO for detector output (FastFIFO)
  signal sF2hFastFifoIn  : tFifoCsrIn;
  signal sF2hFastFifoOut : tFifoCsrOut;

  -- FPGA --> HPS FIFO for telemetries
  signal sF2hFifoIn  : tFifoCsrIn;
  signal sF2hFifoOut : tFifoCsrOut;

  -- fifo HPS --> FPGA contenente dati di configurazione
  signal sH2fFifoIn  : tFifoCsrIn;
  signal sH2fFifoOut : tFifoCsrOut;

  -- TDAQ Module
  signal sExtTrigSynch : std_logic;
  signal sMainTrig     : std_logic;
  signal sMainBusy     : std_logic;
  signal sTrgBusiesAnd : std_logic_vector(7 downto 0);
  signal sTrgBusiesOr  : std_logic_vector(7 downto 0);
  signal sRegArray     : tRegArray;

  -- Timestamps
  signal sIntTsEn    : std_logic;
  signal sIntTsRst   : std_logic;
  signal sIntTsCount : std_logic_vector(63 downto 0);
  signal sExtTsEn    : std_logic;
  signal sExtTsRst   : std_logic;
  signal sExtTsCount : std_logic_vector(63 downto 0);

  --Detector interface
  signal sDetIntfRst    : std_logic;
  signal sDetIntfEn     : std_logic;
  signal sDetIntfQ      : std_logic_vector(cREG_WIDTH-1 downto 0);
  signal sDetIntfWe     : std_logic;
  signal sDetIntfAfull  : std_logic;

  signal sCountersRst   : std_logic;
  signal sRegArrayRst   : std_logic;
  signal sRunMode       : std_logic;

  signal sBcoClkReplica : std_logic;
  signal sBcoClkSynch   : std_logic;
  signal sBcoRstReplica : std_logic;
  signal sBcoRstSynch   : std_logic;
  signal sBusy          : std_logic;
  signal sErrors        : std_logic;
  signal sDebug         : std_logic_vector(7 downto 0);

begin
  -----------------------------------------------------------------------------
  -- Sequential assignments ---------------------------------------------------
  -----------------------------------------------------------------------------
  IOFFD : process(sClk)
  begin
    if rising_edge(sClk) then
      oBUSY <= sMainBusy;
      oTRIG <= sMainTrig;
      --Auxiliaries
      LED(7) <= sMainBusy;
      LED(6) <= sMainTrig;
      LED(5) <= sF2hFifoOut.afull;
      LED(4) <= sF2hFastFifoOut.afull;
      LED(3) <= sF2hFifoOut.full;
      LED(2) <= sF2hFastFifoOut.full;
      LED(1) <= sF2hFifoOut.empty;
      LED(0) <= sF2hFastFifoOut.empty;
      
      oHK(30) <= sMainBusy;
      oHK(29) <= sMainTrig;
      oHK(28) <= sF2hFifoOut.afull;
      oHK(27) <= sF2hFastFifoOut.afull;
      oHK(26) <= sF2hFifoOut.full;
      oHK(25) <= sF2hFastFifoOut.full;
      oHK(24) <= sF2hFifoOut.empty;
      oHK(23) <= sF2hFastFifoOut.empty;
      oHK(22) <= sBcoRstReplica;
      oHK(21) <= sBcoClkReplica;
    end if;
  end process IOFFD;


  -----------------------------------------------------------------------------
  -- Combinatorial Assignments ------------------------------------------------
  -----------------------------------------------------------------------------
  fpga_clk_50   <= FPGA_CLK1_50;
  sClk          <= h2f_clk_50MHz;
  stm_hw_events <= "000000000000000" & SW & fpga_led_internal &
                    fpga_debounced_buttons;

  --FPGA buttons work in negated logic, opposite to the internal modules
  fpga_debounced_buttons_n <= not fpga_debounced_buttons;
  oHK(20 downto 0) <= (others => '0');

  
  -----------------------------------------------------------------------------
  -- FPGA TDAQ Modules --------------------------------------------------------
  -----------------------------------------------------------------------------

  --!@brief Wrapper for all of the Trigger and Data Acquisition modules
  TdaqModule_i : TdaqModule
    generic map (
      pFDI_WIDTH => cFDI_WIDTH,
      pFDI_DEPTH => cFDI_DEPTH,
      pGW_VER    => PAPERO_SHA
      )
    port map (
      iCLK                => sClk,
      --
      iRST                => sDetIntfRst,
      iRST_COUNT          => sCountersRst,
      iRST_REG            => sRegArrayRst,
      oREG_ARRAY          => sRegArray,
      iINT_TS             => sIntTsCount,
      iEXT_TS             => sExtTsCount,
      --
      iEXT_TRIG           => sExtTrigSynch,
      oTRIG               => sMainTrig,
      oBUSY               => sMainBusy,
      iTRG_BUSIES_AND     => sTrgBusiesAnd,
      iTRG_BUSIES_OR      => sTrgBusiesOr,
      --
      iFASTDATA_DATA      => sDetIntfQ,
      iFASTDATA_WE        => sDetIntfWe,
      oFASTDATA_AFULL     => sDetIntfAfull,
      --
      iFIFO_H2F_EMPTY     => sH2fFifoOut.empty,
      iFIFO_H2F_DATA      => sH2fFifoOut.q,
      oFIFO_H2F_RE        => sH2fFifoIn.rd,
      --
      iFIFO_F2H_AFULL     => sF2hFifoOut.afull,
      oFIFO_F2H_WE        => sF2hFifoIn.wr,
      oFIFO_F2H_DATA      => sF2hFifoIn.data,
      --
      iFIFO_F2HFAST_AFULL => sF2hFastFifoOut.afull,
      oFIFO_F2HFAST_WE    => sF2hFastFifoIn.wr,
      oFIFO_F2HFAST_DATA  => sF2hFastFifoIn.data
      );

  sTrgBusiesAnd   <= (others => '0');
  sTrgBusiesOr    <= (0 => sDetIntfAfull, others => '0');
  sDetIntfEn      <= not sRegArray(rUNITS_EN)(1);
  sRunMode        <= sRegArray(rGOTO_STATE)(4);

  --!@brief Generate reset pulse for the detector interface
  pulse_detIntf_reset : altera_edge_detector
    generic map(
      PULSE_EXT             => 5,
      EDGE_TYPE             => 1,
      IGNORE_RST_WHILE_BUSY => 0
      )
    port map (
      clk       => sClk,
      rst_n     => hps_fpga_reset_n_synch,
      signal_in => sRegArray(rGOTO_STATE)(0),
      pulse_out => sDetIntfRst
      );
  --!@brief Generate reset pulse for the time-stamp counters
  pulse_counters_reset : altera_edge_detector
    generic map(
      PULSE_EXT             => 1,
      EDGE_TYPE             => 1,
      IGNORE_RST_WHILE_BUSY => 0
      )
    port map (
      clk       => sClk,
      rst_n     => hps_fpga_reset_n_synch,
      signal_in => sRegArray(rGOTO_STATE)(1),
      pulse_out => sCountersRst
      );
  --!@brief Generate reset pulse for register array
  pulse_regArray_reset : altera_edge_detector
    generic map(
      PULSE_EXT             => 5,
      EDGE_TYPE             => 1,
      IGNORE_RST_WHILE_BUSY => 0
      )
    port map (
      clk       => sClk,
      rst_n     => hps_fpga_reset_n_synch,
      signal_in => sRegArray(rGOTO_STATE)(2),
      pulse_out => sRegArrayRst
      );
  

  -----------------------------------------------------------------------------
  --- I/O synchronization and buffering ---------------------------------------
  -----------------------------------------------------------------------------
  BCO_CLK_SYNCH : sync_edge
    generic map (
      pSTAGES => 3
      )
    port map (
      iCLK    => sClk,
      iRST    => '0',
      iD      => iBCO_CLK,
      oQ      => sBcoClkReplica,
      oEDGE_R => sBcoClkSynch
      );

  BCO_RST_SYNCH : sync_edge
    generic map (
      pSTAGES => 3
      )
    port map (
      iCLK => sClk,
      iRST => '0',
      iD   => iBCO_RST,
      oQ   => sBcoRstReplica,
      oEDGE_F => sBcoRstSynch
      );

  --!@brief Synch the trigger to the local clock domain and take the rising edge
  EXT_TRIG_SYNCH : sync_edge
    generic map (
      pSTAGES => 3
      )
    port map (
      iCLK    => sClk,
      iRST    => '0',
      iD      => iEXT_TRIG,
      oEDGE_R => sExtTrigSynch
      );

  sIntTsEn  <= '1';
  sIntTsRst <= sCountersRst or sDetIntfRst
               or not sRunMode;
  --!@brief Internal timestamp counter
  intTimestampCounter : counter
    generic map (
      pOVERLAP  => "Y",
      pBUSWIDTH => 64
      )
    port map (
      iCLK   => sClk,
      iEN    => sIntTsEn,
      iRST   => sIntTsRst,
      iLOAD  => '0',
      iDATA  => (others => '0'),
      oCOUNT => sIntTsCount
      );

  sExtTsEn  <= sBcoClkSynch;
  sExtTsRst <= sBcoRstSynch or sCountersRst
               or sDetIntfRst or not sRunMode;
  --!@brief External timestamp counter
  extTimestampCounter : counter
    generic map (
      pOVERLAP  => "Y",
      pBUSWIDTH => 64
      )
    port map (
      iCLK   => sClk,
      iEN    => sExtTsEn,
      iRST   => sExtTsRst,
      iLOAD  => '0',
      iDATA  => (others => '0'),
      oCOUNT => sExtTsCount
      );

  -----------------------------------------------------------------------------
  -- HPS instance + ancillary -------------------------------------------------
  -----------------------------------------------------------------------------
  
  hps_cold_rst_n  <= not hps_cold_reset;
  hps_warm_rst_n  <= not hps_warm_reset;
  hps_debug_rst_n <= not hps_debug_reset;
  --!@brief HPS instance
  --!@todo Are clock 50MHz and clock 96MHz inverted?
  SoC_inst : soc_system port map (
    --Clock&Reset
    clk_clk                               => fpga_clk_50,  -- clk.clk
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
    hps_0_f2h_cold_reset_req_reset_n      => hps_cold_rst_n,  -- hps_0_f2h_cold_reset_req.reset_n
    hps_0_f2h_debug_reset_req_reset_n     => hps_debug_rst_n,  -- hps_0_f2h_debug_reset_req.reset_n
    hps_0_f2h_stm_hw_events_stm_hwevents  => stm_hw_events,  -- hps_0_f2h_stm_hw_events.stm_hwevents
    hps_0_f2h_warm_reset_req_reset_n      => hps_warm_rst_n,  -- hps_0_f2h_warm_reset_req.reset_n
    hps_0_h2f_user0_clock_clk             => h2f_clk_96MHz,  -- hps_0_h2f_user0_clock.clk
    hps_0_h2f_user1_clock_clk             => h2f_clk_50MHz,  -- hps_0_h2f_user1_clock.clk
    --
    regcontent_pio_export                 => sRegContentPio, -- regcontent_pio.export
    regaddr_pio_export                    => sRegAddrPio,    --    regaddr_pio.export
    --Fifo Partion
    fast_fifo_fpga_to_hps_clk_clk          => sClk,  -- fast_fifo_fpga_to_hps_clk.clk
    fast_fifo_fpga_to_hps_rst_reset_n      => '1',  -- fast_fifo_fpga_to_hps_rst.reset_n
    fast_fifo_fpga_to_hps_in_writedata     => sF2hFastFifoIn.data,  --       fifo_fpga_to_hps_in.writedata
    fast_fifo_fpga_to_hps_in_write         => sF2hFastFifoIn.wr,  --                          .write
    fast_fifo_fpga_to_hps_in_waitrequest   => sF2hFastFifoOut.full,  --                          .waitrequest
    fast_fifo_fpga_to_hps_in_csr_address   => sF2hFastFifoIn.csrAddr,  --   fifo_fpga_to_hps_in_csr.address
    fast_fifo_fpga_to_hps_in_csr_read      => sF2hFastFifoIn.csrRd,  --                          .read
    fast_fifo_fpga_to_hps_in_csr_writedata => sF2hFastFifoIn.csrData,  --                          .writedata
    fast_fifo_fpga_to_hps_in_csr_write     => sF2hFastFifoIn.csrWr,  --                          .write
    fast_fifo_fpga_to_hps_in_csr_readdata  => sF2hFastFifoOut.csrQ,  --                          .readdata

    fifo_fpga_to_hps_clk_clk          => sClk,  --         fifo_fpga_to_hps_clk.clk
    fifo_fpga_to_hps_rst_reset_n      => '1',  --         fifo_fpga_to_hps_rst.reset_n
    fifo_fpga_to_hps_in_writedata     => sF2hFifoIn.data,  --     fast_fifo_fpga_to_hps_in.writedata
    fifo_fpga_to_hps_in_write         => sF2hFifoIn.wr,  --                             .write
    fifo_fpga_to_hps_in_waitrequest   => sF2hFifoOut.full,  --                             .waitrequest
    fifo_fpga_to_hps_in_csr_address   => sF2hFifoIn.csrAddr,  -- fast_fifo_fpga_to_hps_in_csr.address
    fifo_fpga_to_hps_in_csr_read      => sF2hFifoIn.csrRd,  --                             .read
    fifo_fpga_to_hps_in_csr_writedata => sF2hFifoIn.csrData,  --                             .writedata
    fifo_fpga_to_hps_in_csr_write     => sF2hFifoIn.csrWr,  --                             .write
    fifo_fpga_to_hps_in_csr_readdata  => sF2hFifoOut.csrQ,  --                             .readdata

    fifo_hps_to_fpga_clk_clk           => sClk,  --    fifo_hps_to_fpga_clk.clk
    fifo_hps_to_fpga_rst_reset_n       => '1',  --    fifo_hps_to_fpga_rst.reset_n
    fifo_hps_to_fpga_out_readdata      => sH2fFifoOut.q,  --     fifo_fpga_to_hps_in.writedata
    fifo_hps_to_fpga_out_read          => sH2fFifoIn.rd,  --                        .write
    fifo_hps_to_fpga_out_waitrequest   => sH2fFifoOut.empty,  --                        .waitrequest
    fifo_hps_to_fpga_out_csr_address   => sH2fFifoIn.csrAddr,  -- fifo_fpga_to_hps_in_csr.address
    fifo_hps_to_fpga_out_csr_read      => sH2fFifoIn.csrRd,  --                        .read
    fifo_hps_to_fpga_out_csr_writedata => sH2fFifoIn.csrData,  --                        .writedata
    fifo_hps_to_fpga_out_csr_write     => sH2fFifoIn.csrWr,  --                        .write
    fifo_hps_to_fpga_out_csr_readdata  => sH2fFifoOut.csrQ  --                        .readdata
    );

  --!@brief Debounce logic to clean out glitches within 1ms
  debounce_inst : debounce
    generic map(
      WIDTH         => 2,
      POLARITY      => "LOW",
      TIMEOUT       => 50000,  -- at 50Mhz this is a debounce time of 1ms
      TIMEOUT_WIDTH => 16               -- ceil(log2(TIMEOUT))
      )
    port map (
      clk      => fpga_clk_50,
      reset_n  => hps_fpga_reset_n,
      data_in  => KEY,
      data_out => fpga_debounced_buttons
      );

  --!@brief Source/Probe megawizard instance
  hps_reset_inst : hps_reset
    port map(
      probe      => '0',
      source_clk => fpga_clk_50,
      source     => hps_reset_req
      );

  pulse_cold_reset : altera_edge_detector
    generic map(
      PULSE_EXT             => 6,
      EDGE_TYPE             => 1,
      IGNORE_RST_WHILE_BUSY => 1
      )
    port map (
      clk       => fpga_clk_50,
      rst_n     => hps_fpga_reset_n,
      signal_in => hps_reset_req(0),
      pulse_out => hps_cold_reset
      );

  pulse_warm_reset : altera_edge_detector
    generic map (
      PULSE_EXT             => 2,
      EDGE_TYPE             => 1,
      IGNORE_RST_WHILE_BUSY => 1
      )
    port map (
      clk       => fpga_clk_50,
      rst_n     => hps_fpga_reset_n,
      signal_in => hps_reset_req(1),
      pulse_out => hps_warm_reset
      );

  pulse_debug_reset : altera_edge_detector
    generic map(
      PULSE_EXT             => 32,
      EDGE_TYPE             => 1,
      IGNORE_RST_WHILE_BUSY => 1
      )
    port map (
      clk       => fpga_clk_50,
      rst_n     => hps_fpga_reset_n,
      signal_in => hps_reset_req(2),
      pulse_out => hps_debug_reset
      );

  --!@brief synchronize the reset to the FPGA-side clock
  HPS_RST_SYNCH : sync_stage
    generic map (
      pSTAGES => 3
      )
    port map (
      iCLK => sClk,
      iRST => '0',
      iD   => hps_fpga_reset_n,
      oQ   => hps_fpga_reset_n_synch
      );

  --Patch to readout a single reg address
  RegAddrSync_proc : process (sClk)
  begin
    if (rising_edge(sClk)) then
      sRegAddrInt <= sRegAddrPio;
      sRegAddrSyn <= sRegAddrInt;
    end if;
  end process RegAddrSync_proc;

  RegContSync_proc : process (fpga_clk_50)
  begin
    if (rising_edge(fpga_clk_50)) then
      sRegContentInt <= sRegArray(slv2int(sRegAddrSyn(ceil_log2(cREGISTERS)-1 downto 0)));
      sRegContentPio <= sRegContentInt;
    end if;
  end process RegContSync_proc;

  -- Continuosly read the level_fifo of FIFO HK
  sF2hFifoIn.csrWr <= '0';
  sF2hFifoIn.csrData <= (others => '0');
  sF2hFifoIn.csrAddr <= "000"; -- sF2hFifoOut.csrQ = Level_Fifo
  sF2hFifoIn.csrRd   <= '1';   -- Update usedw at every clock cycle
  --!@brief Generate the Almost Full of the F2H housekeeping FIFO with the csr
  F2H_FIFO_AFULL_PROC : process (sF2hFifoOut.csrQ)
  begin
    if (sF2hFifoOut.csrQ > cF2H_AFULL - 1) then
      sF2hFifoOut.afull <= '1';
    else
      sF2hFifoOut.afull <= '0';
    end if;
  end process F2H_FIFO_AFULL_PROC;

  -- Continuosly read the level_fifo of FIFO Fast_Data
  sF2hFastFifoIn.csrWr <= '0';
  sF2hFastFifoIn.csrData <= (others => '0');
  sF2hFastFifoIn.csrAddr <= "000"; -- sF2hFastFifoOut.csrQ = Level_Fifo
  sF2hFastFifoIn.csrRd   <= '1';   -- Update usedw at every clock cycle
  --!@brief Generate the Almost Full of the F2H Fast-Data FIFO with the csr
  F2H_FASTFIFO_AFULL_PROC : process (sF2hFastFifoOut.csrQ)
  begin
    if (sF2hFastFifoOut.csrQ > cFastF2H_AFULL) then
      sF2hFastFifoOut.afull <= '1';
    else
      sF2hFastFifoOut.afull <= '0';
    end if;
  end process F2H_FASTFIFO_AFULL_PROC;

  --Default values for CSR interface of H2F FIFO
  sH2fFifoIn.csrWr <= '0';
  sH2fFifoIn.csrRd <= '0';
  sH2fFifoIn.csrData <= (others => '0');
  sH2fFifoIn.csrAddr <= (others => '0');

end architecture;
