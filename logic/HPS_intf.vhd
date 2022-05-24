--!@file HPS_intf.vhd
--!brief Accorpamento dei moduli Config_Receiver, registerArray e hkReader
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.paperoPackage.all;

--!@copydoc HPS_intf.vhd
entity HPS_intf is
  generic(
    pGW_VER : std_logic_vector(31 downto 0)  --!Main gateware version
    );
  port(
    iCLK                : in  std_logic;   --!Main clock
    iRST                : in  std_logic;   --!Main reset
    iRST_REG            : in  std_logic;   --!arrayRegister reset
    --Config RX
    oCR_WARNING         : out std_logic_vector(2 downto 0);  --!Config_Receiver Warnings
    --HK Reader
    iHK_RDR_CNT         : in  tControlIn;  --!Config_Receiver control interface
    iHK_RDR_INT_START   : in  std_logic;   --!Internal start of Config_Receiver
    --F2H Fast
    iF2HFAST_CNT        : in  tControlIn;  --!FastTX Control
    oF2HFAST_MD_RD      : out std_logic;   --!Read for METADATA FIFO
    iF2HFAST_METADATA   : in  tF2hMetadata;  --!Packet header information
    oF2HFAST_BUSY       : out std_logic;   --!FastTX Busy
    oF2HFAST_WARNING    : out std_logic;   --!FastTX Errors
    --Register array
    iREG_ARRAY          : in  tRegArray;   --!Register array
    oREG_CONFIG_RX      : out tRegIntf;    --!Configurations from HPS
    --FDI_FIFO
    iFDI_FIFO           : in  tFifo32Out;  --!FDI FIFO output signals
    oFDI_FIFO_RD        : out std_logic;   --!FDI FIFO read request
    --FIFO H2F
    iFIFO_H2F_EMPTY     : in  std_logic;   --!H2F HK Wait Request
    iFIFO_H2F_DATA      : in  std_logic_vector(31 downto 0);  --!H2F HK Data RX
    oFIFO_H2F_RE        : out std_logic;   --!H2F HK Read Request
    --FIFO F2H
    iFIFO_F2H_AFULL     : in  std_logic;   --!F2H Slow Almost Full
    oFIFO_F2H_WE        : out std_logic;   --!F2H Slow Write Request
    oFIFO_F2H_DATA      : out std_logic_vector(31 downto 0);  --!F2H Slow q
    --FIFO F2H FAST
    iFIFO_F2HFAST_AFULL : in  std_logic;   --!F2H Fast Almost Full
    oFIFO_F2HFAST_WE    : out std_logic;   --!F2H Fast Write Request
    oFIFO_F2HFAST_DATA  : out std_logic_vector(31 downto 0)  --!F2H Fast q
    );
end HPS_intf;

--!@copydoc Config_Receiver.vhd
architecture Behavior of HPS_intf is

  signal sCrAddr : std_logic_vector(15 downto 0);  -- Indirizzo del registro in cui memorizzare il dato di configurazione

begin
  --!@brief Receive config data
  h2f_config_rx : Config_Receiver
    port map(
      CR_CLK_in               => iCLK,
      CR_RST_in               => iRST_REG,
      CR_FIFO_WAIT_REQUEST_in => iFIFO_H2F_EMPTY,
      CR_DATA_in              => iFIFO_H2F_DATA,
      CR_FWV_in               => pGW_VER,
      CR_FIFO_READ_EN_out     => oFIFO_H2F_RE,
      CR_DATA_out             => oREG_CONFIG_RX.reg,
      CR_ADDRESS_out          => sCrAddr,
      CR_DATA_VALID_out       => oREG_CONFIG_RX.we,
      CR_WARNING_out          => oCR_WARNING
      );
  oREG_CONFIG_RX.addr <= sCrAddr(cHPS_REG_ADDR - 1 downto 0);

  --!@brief Telemetries (HK) read and send
  f2h_tx : hkReader
    generic map(
      pFIFO_WIDTH => 32,
      pPARITY     => "EVEN",
      pGW_VER     => pGW_VER
      )
    port map(
      iCLK        => iCLK,
      iRST        => iRST,
      iCNT        => iHK_RDR_CNT,
      oCNT        => open,
      iINT_START  => iHK_RDR_INT_START,
      iREG_ARRAY  => iREG_ARRAY,
      oFIFO_DATA  => oFIFO_F2H_DATA,
      oFIFO_WR    => oFIFO_F2H_WE,
      iFIFO_AFULL => iFIFO_F2H_AFULL
      );

  --!@brief Scientific data transmitter
  f2h_fast_tx : FastData_Transmitter
    generic map(
      pGW_VER => pGW_VER
      )
    port map(
      iCLK         => iCLK,
      iRST         => iRST,
      -- Enable
      iEN          => iF2HFAST_CNT.en,
      -- Settings Packet
      oMETADATA_RD => oF2HFAST_MD_RD,
      iMETADATA    => iF2HFAST_METADATA,
      -- Fifo Management
      iFIFO_DATA   => iFDI_FIFO.q,
      iFIFO_EMPTY  => iFDI_FIFO.empty,
      iFIFO_AEMPTY => iFDI_FIFO.aEmpty,
      oFIFO_RE     => oFDI_FIFO_RD,
      --F2H Fast
      iFIFO_AFULL  => iFIFO_F2HFAST_AFULL,
      oFIFO_WE     => oFIFO_F2HFAST_WE,
      oFIFO_DATA   => oFIFO_F2HFAST_DATA,
      --Output Flags
      oBUSY        => oF2HFAST_BUSY,
      oWARNING     => oF2HFAST_WARNING
      );


end architecture;
