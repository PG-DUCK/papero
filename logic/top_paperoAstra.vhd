--!@file top_paperoAstra.vhd
--!brief Top module of the papero FPGA gateware
--!@todo Add reset to the HPS-FPGA fifos
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.intel_packageAstra.all;
use work.paperoPackage.all;
use work.basic_package.all;
use work.ASTRApackage.all;


--!@copydoc top_paperoAstra.vhd
entity top_paperoAstra is
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
    PAPEROASTRA_SHA : std_logic_vector(31 downto 0) := (others => '0');
    PAPEROASTRA_VER : std_logic_vector(31 downto 0) := (others => '0')
    );
  port(
    --- CLOCK ------------------------------------------------------------------
    CLOCK_50  : in std_logic;
    CLOCK2_50 : in std_logic;
    CLOCK3_50 : in std_logic;
    CLOCK4_50 : in std_logic;

    --- HPS --------------------------------------------------------------------
    HPS_CONV_USB_N    :inout   std_logic;
    HPS_DDR3_ADDR     :out     std_logic_vector(14 downto 0);
    HPS_DDR3_BA       :out     std_logic_vector(2 downto 0);
    HPS_DDR3_CAS_N    :out     std_logic;
    HPS_DDR3_CKE      :out     std_logic;
    HPS_DDR3_CK_N     :out     std_logic;
    HPS_DDR3_CK_P     :out     std_logic;
    HPS_DDR3_CS_N     :out     std_logic;
    HPS_DDR3_DM       :out     std_logic_vector(3 downto 0);
    HPS_DDR3_DQ       :inout   std_logic_vector(31 downto 0);
    HPS_DDR3_DQS_N    :inout   std_logic_vector(3 downto 0);
    HPS_DDR3_DQS_P    :inout   std_logic_vector(3 downto 0);
    HPS_DDR3_ODT      :out     std_logic;
    HPS_DDR3_RAS_N    :out     std_logic;
    HPS_DDR3_RESET_N  :out     std_logic;
    HPS_DDR3_RZQ      :in      std_logic;
    HPS_DDR3_WE_N     :out     std_logic;
    HPS_ENET_GTX_CLK  :out     std_logic;
    HPS_ENET_INT_N    :inout   std_logic;
    HPS_ENET_MDC      :out     std_logic;
    HPS_ENET_MDIO     :inout   std_logic;
    HPS_ENET_RX_CLK   :in      std_logic;
    HPS_ENET_RX_DATA  :in      std_logic_vector(3 downto 0);
    HPS_ENET_RX_DV    :in      std_logic;
    HPS_ENET_TX_DATA  :out     std_logic_vector(3 downto 0);
    HPS_ENET_TX_EN    :out     std_logic;
    HPS_FLASH_DATA    :inout   std_logic_vector(3 downto 0);
    HPS_FLASH_DCLK    :out     std_logic;
    HPS_FLASH_NCSO    :out     std_logic;
    HPS_GSENSOR_INT   :inout   std_logic;
    HPS_I2C1_SCLK     :inout   std_logic;
    HPS_I2C1_SDAT     :inout   std_logic;
    HPS_I2C2_SCLK     :inout   std_logic;
    HPS_I2C2_SDAT     :inout   std_logic;
    HPS_I2C_CONTROL   :inout   std_logic;
    HPS_KEY           :inout   std_logic;
    HPS_LCM_BK        :inout   std_logic;
    HPS_LCM_D_C       :inout   std_logic;
    HPS_LCM_RST_N     :inout   std_logic;
    HPS_LCM_SPIM_CLK  :out     std_logic;
    HPS_LCM_SPIM_MISO  :in      std_logic;
    HPS_LCM_SPIM_MOSI  :out     std_logic;
    HPS_LCM_SPIM_SS   :out     std_logic;
    HPS_LED           :inout   std_logic;
    HPS_LTC_GPIO      :inout   std_logic;
    HPS_SD_CLK        :out     std_logic;
    HPS_SD_CMD        :inout   std_logic;
    HPS_SD_DATA       :inout   std_logic_vector(3 downto 0);
    HPS_SPIM_CLK      :out     std_logic;
    HPS_SPIM_MISO     :in      std_logic;
    HPS_SPIM_MOSI     :out     std_logic;
    HPS_SPIM_SS       :out     std_logic;
    HPS_UART_RX       :in      std_logic;
    HPS_UART_TX       :out     std_logic;
    HPS_USB_CLKOUT    :in      std_logic;
    HPS_USB_DATA      :inout   std_logic_vector(7 downto 0);
    HPS_USB_DIR       :in      std_logic;
    HPS_USB_NXT       :in      std_logic;
    HPS_USB_STP       :out     std_logic;

    --- KEY --------------------------------------------------------------------
    KEY : in std_logic_vector(3 downto 0);

    --- LED --------------------------------------------------------------------
    LEDR : out std_logic_vector(9 downto 0);

    --- SW ---------------------------------------------------------------------
    SW : in std_logic_vector(9 downto 0);

    --- SEG7--------------------------------------------------------------------
    HEX0 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0);

    --- GPIO -------------------------------------------------------------------
    oHK : out std_logic_vector(22 downto 0);
    iBCO_RST : in std_logic;
    iBCO_CLK : in std_logic;
    iEXT_TRIG : in std_logic;
    oBUSY : out std_logic;
    oBCO_CLK : out std_logic;
    oEXT_TRIG : out std_logic;

    iBCO_RST_RED : in std_logic;
    iBCO_CLK_RED : in std_logic;
    iEXT_TRIG_RED : in std_logic;
    oBUSY_RED : out std_logic;
    oBCO_CLK_RED : out std_logic;
    oEXT_TRIG_RED : out std_logic;

    oTRIG : out std_logic;

    --- HSMC -------------------------------------------------------------------
    HSMC_SCL        : out    std_logic;
    HSMC_SDA        : inout  std_logic;
    HSMC_CLKIN0     : in     std_logic;
    HSMC_CLKOUT0    : out    std_logic;

    oHSMC_CLKOUT_N1 :  out std_logic;
    oHSMC_CLKOUT_P1 :  out std_logic;
    oHSMC_RX_C_n : out std_logic_vector(1 downto 0);
    oHSMC_RX_C_p : out std_logic_vector(1 downto 0);
    oHSMC_RX_B_n : out std_logic_vector(7 downto 0);
    oHSMC_RX_B_p : out std_logic_vector(7 downto 0);
    oHSMC_TX_C_n : out std_logic_vector(4 downto 0);
    oHSMC_TX_C_p : out std_logic_vector(4 downto 0);

    oFASTOR_TX_DISABLE : out std_logic;
    oDEBUG_EN :  out std_logic;
    oPT1 : out std_logic;
    oPT2 : out std_logic;
    oGAIN : out std_logic;
    oPOL : out std_logic;
    oSER_TX_DISABLE : out std_logic;
    oRESET_DIGITAL : out std_logic;

    oPRG_BIT_A : out std_logic;
    oPRG_BIT_B : out std_logic;
    oPRG_RESET : out std_logic;
    oPRG_CLK   : out std_logic;

    --oFASTCLK_n : out std_logic;
    oFASTCLK   : out std_logic;
    --iFASTCLK_RET_n : in std_logic;
    iFASTCLK_RET   : in std_logic;

    --iFASTOR_A_n : in std_logic;
    iFASTOR_A   : in std_logic;
    --iFASTOR_B_n : in std_logic;
    iFASTOR_B   : in std_logic;

    --oHOLD_n : out std_logic;
    oHOLD   : out std_logic;
    --oTP_n : out std_logic;
    oTP   : out std_logic;

    oMUX_SHIFT_CLK : out std_logic;
    oMUX_READRESET : out std_logic;
    iMUX_SHIFT_CLK_RET : in  std_logic;
    iMUX_READRESET_RET :  in  std_logic;

    oADC_CONVERT : out std_logic;

    --iSER_A_n  : in std_logic;
    iSER_A   : in std_logic;
    --iSER_B_n  : in std_logic;
    iSER_B   : in std_logic;
    oSER_SEND : out std_logic;
    oSER_LOAD : out std_logic;
    oSER_SHIFT_CLK : out std_logic;
    iSER_SHIFT_CLK_RET : in  std_logic;
    iSER_SEND_RET :  in  std_logic;

    iSDATA_B  : in std_logic;
    oCS_B : out std_logic;
    oSCLK_B : out std_logic;
    iCS_B_RET : in std_logic;
    iSCLK_B_RET : in std_logic;

    iSDATA_A : in std_logic;
    oCS_A : out std_logic;
    oSCLK_A : out std_logic;
    iCS_A_RET : in std_logic;
    iSCLK_A_RET : in std_logic

    );
end entity top_paperoAstra;

--!@copydoc top_paperoAstra.vhd
architecture std of top_paperoAstra is
  --HPS signals
  signal hps_fpga_reset_n       : std_logic;
  signal fpga_debounced_buttons : std_logic_vector(3 downto 0);
  signal fpga_led_internal      : std_logic_vector(9 downto 0);
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

  -- Ausiliari
  signal fpga_debounced_buttons_n : std_logic_vector(3 downto 0);  -- debounced_bottons in logica positiva
  signal hps_fpga_reset_n_synch   : std_logic;  -- segnale interno di RESET in logica positiva
  signal hps_cold_rst_n           : std_logic;
  signal hps_warm_rst_n           : std_logic;
  signal hps_debug_rst_n          : std_logic;
  signal sClk                     : std_logic;  -- FPGA clock
  signal h2f_clk_50MHz            : std_logic;  -- user clock (50 MHz) from HPS
  signal h2f_clk_96MHz            : std_logic;  -- user clock (96 MHz) from HPS

  -- fifo FPGA --> HPS contenente dati scientifici
  signal fast_fifo_f2h_data_in      : std_logic_vector(31 downto 0);  -- Data
  signal fast_fifo_f2h_wr_en        : std_logic;  -- Write Enable
  signal fast_fifo_f2h_full         : std_logic;  -- Fifo Full
  signal fast_fifo_f2h_afull        : std_logic;  -- Fifo Almost Full
  signal fast_fifo_f2h_addr_csr     : std_logic_vector(2 downto 0);
  signal fast_fifo_f2h_rd_en_csr    : std_logic;
  signal fast_fifo_f2h_data_in_csr  : std_logic_vector(31 downto 0);
  signal fast_fifo_f2h_wr_en_csr    : std_logic;
  signal fast_fifo_f2h_data_out_csr : std_logic_vector(31 downto 0);

  -- fifo FPGA --> HPS contenente dati di telemetria
  signal fifo_f2h_data_in      : std_logic_vector(31 downto 0);  -- Data
  signal fifo_f2h_wr_en        : std_logic;  -- Write Enable
  signal fifo_f2h_full         : std_logic;  -- Fifo Full
  signal fifo_f2h_afull        : std_logic;  -- Fifo Almost Full
  signal fifo_f2h_addr_csr     : std_logic_vector(2 downto 0);
  signal fifo_f2h_rd_en_csr    : std_logic;
  signal fifo_f2h_data_in_csr  : std_logic_vector(31 downto 0);
  signal fifo_f2h_wr_en_csr    : std_logic;
  signal fifo_f2h_data_out_csr : std_logic_vector(31 downto 0);

  -- fifo HPS --> FPGA contenente dati di configurazione
  signal fifo_h2f_data_out     : std_logic_vector(31 downto 0);  -- Data
  signal fifo_h2f_rd_en        : std_logic;                      -- Read Enable
  signal fifo_h2f_empty        : std_logic;                      -- Fifo Empty
  signal fifo_h2f_addr_csr     : std_logic_vector(2 downto 0);
  signal fifo_h2f_rd_en_csr    : std_logic;
  signal fifo_h2f_data_in_csr  : std_logic_vector(31 downto 0);
  signal fifo_h2f_wr_en_csr    : std_logic;
  signal fifo_h2f_data_out_csr : std_logic_vector(31 downto 0);

  -- TDAQ Module
  signal sExtTrig      : std_logic;
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
  signal sDetIntfCfg    : astraConfig;
  signal sDetIntfCntOut : tControlIntfOut;
  signal sDetIntfQ      : std_logic_vector(cREG_WIDTH-1 downto 0);
  signal sDetIntfWe     : std_logic;
  signal sDetIntfAfull  : std_logic;

  signal sCountersRst   : std_logic;
  signal sRegArrayRst   : std_logic;
  signal sRunMode       : std_logic;

  signal sBcoClkSynch   : std_logic;
  signal sBcoRstSynch   : std_logic;
  signal sBusy          : std_logic;
  signal sErrors        : std_logic;
  signal sDebug         : std_logic_vector(7 downto 0);
  signal sPrg           : tPrgIntf;

  signal sFeO           : tFpga2FeIntf;
  signal sFeI           : tFe2FpgaIntf;
  signal sExtAdcO       : tFpga2AdcIntf;
  signal sExtAdcI       : tMultiAdc2FpgaIntf;

begin

  HSMC_SCL  <= '0';
  HSMC_SDA  <= '0';
  HSMC_CLKOUT0  <= '0';
  oHSMC_CLKOUT_N1 <= '0';
  oHSMC_CLKOUT_P1 <= '0';
  oHSMC_RX_C_n <= (others => '0');
  oHSMC_RX_C_p <= (others => '0');
  oHSMC_RX_B_n <= (others => '0');
  oHSMC_RX_B_p <= (others => '0');
  oHSMC_TX_C_n <= (others => '0');
  oHSMC_TX_C_p <= (others => '0');

  oHK <= (others => '0');

  --Local configurations
  oPRG_BIT_A <= sPrg.bitA;
  oPRG_BIT_B <= sPrg.bitB;
  oPRG_RESET <= sPrg.rst;
  oPRG_CLK   <= sPrg.clk;

  --Fast Clock
  oFASTCLK            <= '0';
  --<= iFASTCLK_RET;

  --Discriminator OR output
  --<= iFASTOR_A;
  --<= iFASTOR_B;

  --Analog Readout
  oHOLD               <= sFeO.hold_b;
  oTP                 <= sFeO.test;

  --Analog Multiplexer
  oMUX_SHIFT_CLK      <= sFeo.shiftClk;
  oMUX_READRESET      <= sFeO.readRst;
  sFeI.shiftClkRet    <= iMUX_SHIFT_CLK_RET;
  sFeI.readRstRet     <= iMUX_READRESET_RET;

  --Internal ADC
  oADC_CONVERT        <= '0';

  --Serializer A and B
  oRESET_DIGITAL      <= '0';

  --<= iSER_A;
  --<= iSER_B;
  oSER_SEND           <= '0';
  oSER_LOAD           <= '0';
  oSER_SHIFT_CLK      <= '0';
  --<= iSER_SHIFT_CLK_RET;
  --<= iSER_SEND_RET;

  --External ADC A
  sExtAdcI(1).SData   <= iSDATA_B;
  oCS_B               <= sExtAdcO.Cs;
  oSCLK_B             <= sExtAdcO.SClk;
  sExtAdcI(1).clkRet  <= iCS_B_RET;
  sExtAdcI(1).csRet   <= iSCLK_B_RET;

  --External ADC B
  sExtAdcI(0).SData   <= iSDATA_A;
  oCS_A               <= sExtAdcO.Cs;
  oSCLK_A             <= sExtAdcO.SClk;
  sExtAdcI(0).clkRet  <= iCS_A_RET;
  sExtAdcI(0).csRet   <= iSCLK_A_RET;

  -- connection of internal logics ----------------------------
  fpga_clk_50   <= CLOCK_50;
  sClk          <= h2f_clk_50MHz;
  stm_hw_events <= "0000" & SW & fpga_led_internal & fpga_debounced_buttons;

  fpga_debounced_buttons_n <= not fpga_debounced_buttons;  -- FPGA buttons have inverted logic, our modules straight

  hps_cold_rst_n  <= not hps_cold_reset;
  hps_warm_rst_n  <= not hps_warm_reset;
  hps_debug_rst_n <= not hps_debug_reset;
  --!@brief HPS instance
  SoC_inst : soc_system port map (
    --Clock&Reset
    clk_clk                               => fpga_clk_50,
    reset_reset_n                         => hps_fpga_reset_n,
    --HPS ddr3
    memory_mem_a                          => HPS_DDR3_ADDR,
    memory_mem_ba                         => HPS_DDR3_BA,
    memory_mem_ck                         => HPS_DDR3_CK_P,
    memory_mem_ck_n                       => HPS_DDR3_CK_N,
    memory_mem_cke                        => HPS_DDR3_CKE,
    memory_mem_cs_n                       => HPS_DDR3_CS_N,
    memory_mem_ras_n                      => HPS_DDR3_RAS_N,
    memory_mem_cas_n                      => HPS_DDR3_CAS_N,
    memory_mem_we_n                       => HPS_DDR3_WE_N,
    memory_mem_reset_n                    => HPS_DDR3_RESET_N,
    memory_mem_dq                         => HPS_DDR3_DQ,
    memory_mem_dqs                        => HPS_DDR3_DQS_P,
    memory_mem_dqs_n                      => HPS_DDR3_DQS_N,
    memory_mem_odt                        => HPS_DDR3_ODT,
    memory_mem_dm                         => HPS_DDR3_DM,
    memory_oct_rzqin                      => HPS_DDR3_RZQ,
    --HPS ethernet
    hps_0_hps_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK,
    hps_0_hps_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0),
    hps_0_hps_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1),
    hps_0_hps_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2),
    hps_0_hps_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3),
    hps_0_hps_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0),
    hps_0_hps_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO,
    hps_0_hps_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC,
    hps_0_hps_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV,
    hps_0_hps_io_hps_io_emac1_inst_TX_CTL => HPS_ENET_TX_EN,
    hps_0_hps_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK,
    hps_0_hps_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1),
    hps_0_hps_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2),
    hps_0_hps_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3),
    --HPS QSPI
    hps_0_hps_io_hps_io_qspi_inst_IO0     => HPS_FLASH_DATA(0),
    hps_0_hps_io_hps_io_qspi_inst_IO1     => HPS_FLASH_DATA(1),
    hps_0_hps_io_hps_io_qspi_inst_IO2     => HPS_FLASH_DATA(2),
    hps_0_hps_io_hps_io_qspi_inst_IO3     => HPS_FLASH_DATA(3),
    hps_0_hps_io_hps_io_qspi_inst_SS0     => HPS_FLASH_NCSO,
    hps_0_hps_io_hps_io_qspi_inst_CLK     => HPS_FLASH_DCLK,
    --HPS SD card
    hps_0_hps_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD,
    hps_0_hps_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0),
    hps_0_hps_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1),
    hps_0_hps_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK,
    hps_0_hps_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2),
    hps_0_hps_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3),
    --HPS USB
    hps_0_hps_io_hps_io_usb1_inst_D0      => HPS_USB_DATA(0),
    hps_0_hps_io_hps_io_usb1_inst_D1      => HPS_USB_DATA(1),
    hps_0_hps_io_hps_io_usb1_inst_D2      => HPS_USB_DATA(2),
    hps_0_hps_io_hps_io_usb1_inst_D3      => HPS_USB_DATA(3),
    hps_0_hps_io_hps_io_usb1_inst_D4      => HPS_USB_DATA(4),
    hps_0_hps_io_hps_io_usb1_inst_D5      => HPS_USB_DATA(5),
    hps_0_hps_io_hps_io_usb1_inst_D6      => HPS_USB_DATA(6),
    hps_0_hps_io_hps_io_usb1_inst_D7      => HPS_USB_DATA(7),
    hps_0_hps_io_hps_io_usb1_inst_CLK     => HPS_USB_CLKOUT,
    hps_0_hps_io_hps_io_usb1_inst_STP     => HPS_USB_STP,
    hps_0_hps_io_hps_io_usb1_inst_DIR     => HPS_USB_DIR,
    hps_0_hps_io_hps_io_usb1_inst_NXT     => HPS_USB_NXT,
    --HPS SPI0 -> LCDM
    hps_0_hps_io_hps_io_spim0_inst_CLK     => HPS_LCM_SPIM_CLK,
    hps_0_hps_io_hps_io_spim0_inst_MOSI    => HPS_LCM_SPIM_MOSI,
    hps_0_hps_io_hps_io_spim0_inst_MISO    => HPS_LCM_SPIM_MISO,
    hps_0_hps_io_hps_io_spim0_inst_SS0     => HPS_LCM_SPIM_SS,
    --HPS SPI1
    hps_0_hps_io_hps_io_spim1_inst_CLK    => HPS_SPIM_CLK,
    hps_0_hps_io_hps_io_spim1_inst_MOSI   => HPS_SPIM_MOSI,
    hps_0_hps_io_hps_io_spim1_inst_MISO   => HPS_SPIM_MISO,
    hps_0_hps_io_hps_io_spim1_inst_SS0    => HPS_SPIM_SS,
    --HPS UART
    hps_0_hps_io_hps_io_uart0_inst_RX     => HPS_UART_RX,
    hps_0_hps_io_hps_io_uart0_inst_TX     => HPS_UART_TX,
    --HPS I2C1
    hps_0_hps_io_hps_io_i2c0_inst_SDA     => HPS_I2C1_SDAT,
    hps_0_hps_io_hps_io_i2c0_inst_SCL     => HPS_I2C1_SCLK,
    --HPS I2C2
    hps_0_hps_io_hps_io_i2c1_inst_SDA     => HPS_I2C2_SDAT,
    hps_0_hps_io_hps_io_i2c1_inst_SCL     => HPS_I2C2_SCLK,
    --GPIO
    hps_0_hps_io_hps_io_gpio_inst_GPIO09  => HPS_CONV_USB_N,
    hps_0_hps_io_hps_io_gpio_inst_GPIO35  => HPS_ENET_INT_N,
    hps_0_hps_io_hps_io_gpio_inst_GPIO37  => HPS_LCM_BK,
    hps_0_hps_io_hps_io_gpio_inst_GPIO40  => HPS_LTC_GPIO,
    hps_0_hps_io_hps_io_gpio_inst_GPIO41  => HPS_LCM_D_C,
    hps_0_hps_io_hps_io_gpio_inst_GPIO44  => HPS_LCM_RST_N,
    hps_0_hps_io_hps_io_gpio_inst_GPIO48  => HPS_I2C_CONTROL,
    hps_0_hps_io_hps_io_gpio_inst_GPIO53  => HPS_LED,
    hps_0_hps_io_hps_io_gpio_inst_GPIO54  => HPS_KEY,
    hps_0_hps_io_hps_io_gpio_inst_GPIO61  => HPS_GSENSOR_INT,
    --FPGA Partion
    led_pio_external_connection_export    => fpga_led_internal,
    dipsw_pio_external_connection_export  => SW,
    button_pio_external_connection_export => fpga_debounced_buttons,
    hps_0_h2f_reset_reset_n               => hps_fpga_reset_n,
    hps_0_f2h_cold_reset_req_reset_n      => hps_cold_rst_n,
    hps_0_f2h_debug_reset_req_reset_n     => hps_debug_rst_n,
    hps_0_f2h_stm_hw_events_stm_hwevents  => stm_hw_events,
    hps_0_f2h_warm_reset_req_reset_n      => hps_warm_rst_n,
    hps_0_h2f_user0_clock_clk             => h2f_clk_96MHz,
    hps_0_h2f_user1_clock_clk             => h2f_clk_50MHz,
    --
    regcontent_pio_export                 => sRegContentPio,
    regaddr_pio_export                    => sRegAddrPio,
    --Fifo Partion
    fast_fifo_fpga_to_hps_clk_clk          => sClk,
    fast_fifo_fpga_to_hps_rst_reset_n      => '1',
    fast_fifo_fpga_to_hps_in_writedata     => fast_fifo_f2h_data_in,
    fast_fifo_fpga_to_hps_in_write         => fast_fifo_f2h_wr_en,
    fast_fifo_fpga_to_hps_in_waitrequest   => fast_fifo_f2h_full,
    fast_fifo_fpga_to_hps_in_csr_address   => fast_fifo_f2h_addr_csr,
    fast_fifo_fpga_to_hps_in_csr_read      => fast_fifo_f2h_rd_en_csr,
    fast_fifo_fpga_to_hps_in_csr_writedata => fast_fifo_f2h_data_in_csr,
    fast_fifo_fpga_to_hps_in_csr_write     => fast_fifo_f2h_wr_en_csr,
    fast_fifo_fpga_to_hps_in_csr_readdata  => fast_fifo_f2h_data_out_csr,

    fifo_fpga_to_hps_clk_clk          => sClk,
    fifo_fpga_to_hps_rst_reset_n      => '1',
    fifo_fpga_to_hps_in_writedata     => fifo_f2h_data_in,
    fifo_fpga_to_hps_in_write         => fifo_f2h_wr_en,
    fifo_fpga_to_hps_in_waitrequest   => fifo_f2h_full,
    fifo_fpga_to_hps_in_csr_address   => fifo_f2h_addr_csr,
    fifo_fpga_to_hps_in_csr_read      => fifo_f2h_rd_en_csr,
    fifo_fpga_to_hps_in_csr_writedata => fifo_f2h_data_in_csr,
    fifo_fpga_to_hps_in_csr_write     => fifo_f2h_wr_en_csr,
    fifo_fpga_to_hps_in_csr_readdata  => fifo_f2h_data_out_csr,

    fifo_hps_to_fpga_clk_clk           => sClk,
    fifo_hps_to_fpga_rst_reset_n       => '1',
    fifo_hps_to_fpga_out_readdata      => fifo_h2f_data_out,
    fifo_hps_to_fpga_out_read          => fifo_h2f_rd_en,
    fifo_hps_to_fpga_out_waitrequest   => fifo_h2f_empty,
    fifo_hps_to_fpga_out_csr_address   => fifo_h2f_addr_csr,
    fifo_hps_to_fpga_out_csr_read      => fifo_h2f_rd_en_csr,
    fifo_hps_to_fpga_out_csr_writedata => fifo_h2f_data_in_csr,
    fifo_hps_to_fpga_out_csr_write     => fifo_h2f_wr_en_csr,
    fifo_hps_to_fpga_out_csr_readdata  => fifo_h2f_data_out_csr
    );

  --!@brief Debounce logic to clean out glitches within 1ms
  debounce_inst : debounce
    generic map(
      WIDTH         => 4,
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
  --!@todo Remove this component?
  hps_reset_inst : hps_reset
    port map(
      probe      => '0',
      source_clk => fpga_clk_50,
      source     => hps_reset_req
      );

  --!@brief Edge detector
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

  --!@brief Edge detector
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

  --!@brief Edge detector
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
  fifo_f2h_addr_csr  <= "000"; -- 0: address of Level_Fifo
  fifo_f2h_rd_en_csr <= '1';
  --!@brief Generate the Almost Full of the F2H housekeeping FIFO with the csr
  F2H_HK_AFull_proc : process (fifo_f2h_data_out_csr)
  begin
    if (fifo_f2h_data_out_csr > cF2H_AFULL - 1) then
      fifo_f2h_afull <= '1';
    else
      fifo_f2h_afull <= '0';
    end if;
  end process;

  -- Continuosly read the level_fifo of FIFO Fast_Data
  fast_fifo_f2h_addr_csr  <= "000";  -- 0: address of Level_Fifo
  fast_fifo_f2h_rd_en_csr <= '1';
  --!@brief Generate the Almost Full of the F2H Fast-Data FIFO with the csr
  F2H_Scientific_AFull_proc : process (fast_fifo_f2h_data_out_csr)
  begin
    if (fast_fifo_f2h_data_out_csr > cFastF2H_AFULL) then
      fast_fifo_f2h_afull <= '1';
    else
      fast_fifo_f2h_afull <= '0';
    end if;
  end process;

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

  --!@brief Wrapper for all of the Trigger and Data Acquisition modules
  sTrgBusiesAnd   <= (others => '0');
  sTrgBusiesOr    <= (0 => sDetIntfCntOut.busy, 1 => sDetIntfAfull, others => '0');
  TdaqModule_i : TdaqModule
    generic map (
      pFDI_WIDTH => cFDI_WIDTH,
      pFDI_DEPTH => cFDI_DEPTH,
      pGW_VER    => PAPEROASTRA_SHA
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
      iEXT_TRIG           => iEXT_TRIG,
      oTRIG               => sMainTrig,
      oBUSY               => sMainBusy,
      iTRG_BUSIES_AND     => sTrgBusiesAnd,
      iTRG_BUSIES_OR      => sTrgBusiesOr,
      --
      iFASTDATA_DATA      => sDetIntfQ,
      iFASTDATA_WE        => sDetIntfWe,
      oFASTDATA_AFULL     => sDetIntfAfull,
      --
      iFIFO_H2F_EMPTY     => fifo_h2f_empty,
      iFIFO_H2F_DATA      => fifo_h2f_data_out,
      oFIFO_H2F_RE        => fifo_h2f_rd_en,
      --
      iFIFO_F2H_AFULL     => fifo_f2h_afull,
      oFIFO_F2H_WE        => fifo_f2h_wr_en,
      oFIFO_F2H_DATA      => fifo_f2h_data_in,
      --
      iFIFO_F2HFAST_AFULL => fast_fifo_f2h_afull,
      oFIFO_F2HFAST_WE    => fast_fifo_f2h_wr_en,
      oFIFO_F2HFAST_DATA  => fast_fifo_f2h_data_in
      );

  --!@brief Generate reset pulse for register array
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
  --!@brief Generate reset pulse for register array
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

  sRunMode                <= sRegArray(rGOTO_STATE)(4);
  sDetIntfEn              <= not sRegArray(rUNITS_EN)(1);
  sDetIntfCfg.prgStart    <= sRegArray(rUNITS_EN)(12);
  sDetIntfCfg.feClkDuty   <= sRegArray(rFE_CLK_PARAM)(31 downto 16);
  sDetIntfCfg.feClkDiv    <= sRegArray(rFE_CLK_PARAM)(15 downto 0);
  sDetIntfCfg.adcClkDuty  <= sRegArray(rADC_CLK_PARAM)(31 downto 16);
  sDetIntfCfg.adcClkDiv   <= sRegArray(rADC_CLK_PARAM)(15 downto 0);
  sDetIntfCfg.adcFastMode <= sRegArray(rASTRA_PARAM)(24);
  oFASTOR_TX_DISABLE      <= sRegArray(rASTRA_PARAM)(22);
  oDEBUG_EN               <= sRegArray(rASTRA_PARAM)(21);
  oPT1                    <= sRegArray(rASTRA_PARAM)(20);
  oPT2                    <= sRegArray(rASTRA_PARAM)(19);
  oGAIN                   <= sRegArray(rASTRA_PARAM)(18);
  oPOL                    <= sRegArray(rASTRA_PARAM)(17);
  oSER_TX_DISABLE         <= sRegArray(rASTRA_PARAM)(16);
  sDetIntfCfg.trg2Hold    <= sRegArray(rASTRA_PARAM)(15 downto 0);
  sDetIntfCfg.extendBusy  <= sRegArray(rBUSYADC_PARAM)(31 downto 16);
  sDetIntfCfg.adcDelay    <= sRegArray(rBUSYADC_PARAM)(15 downto 0);
  sDetIntfCfg.prgClkDuty  <= sRegArray(rPRG_CLK_PARAM)(31 downto 16);
  sDetIntfCfg.prgClkDiv   <= sRegArray(rPRG_CLK_PARAM)(15 downto 0);
  sDetIntfCfg.chMask      <= sRegArray(rMASK_A) & sRegArray(rMASK_B);
  sDetIntfCfg.chTpEn      <= sRegArray(rTPEN_A) & sRegArray(rTPEN_B);
  sDetIntfCfg.chDisc      <= sRegArray(rDISC_A) & sRegArray(rDISC_B);
  --!@brief Detector interface. **Reset shall be longer than 2 clock cycles**
  AstraInterface : DetectorInterface
    port map (
      iCLK            => sClk,
      iRST            => sDetIntfRst, --See the instance description
      iEN             => sDetIntfEn,
      iTRIG           => sMainTrig,
      oCNT            => sDetIntfCntOut,
      iASTRA_CONFIG   => sDetIntfCfg,
      oPRG            => sPrg,
      oFE             => sFeO,
      iFE             => sFeI,
      oADC            => sExtAdcO,
      iMULTI_ADC      => sExtAdcI,
      oFASTDATA_DATA  => sDetIntfQ,
      oFASTDATA_WE    => sDetIntfWe,
      iFASTDATA_AFULL => sDetIntfAfull
      );


  --- I/O synchronization and buffering ----------------------------------------
  BCO_CLK_SYNCH : sync_edge
    generic map (
      pSTAGES => 2
      )
    port map (
      iCLK => sClk,
      iRST => '0',
      iD   => iBCO_CLK,
      oQ   => sBcoClkSynch
      );

  BCO_RST_SYNCH : sync_edge
    generic map (
      pSTAGES => 2
      )
    port map (
      iCLK => sClk,
      iRST => '0',
      iD   => iBCO_RST,
      oQ   => sBcoRstSynch
      );

  IOFFD : process(sClk)
  begin
    if rising_edge(sClk) then
      oBUSY     <= sMainBusy;
      oBUSY_RED <= sMainBusy;
      oTRIG     <= sMainTrig;
      
      oBCO_CLK      <= iBCO_CLK;
      oBCO_CLK_RED  <= iBCO_CLK_RED;
      oEXT_TRIG     <= iEXT_TRIG;
      oEXT_TRIG_RED <= iEXT_TRIG_RED;
    end if;
  end process IOFFD;

end architecture;
