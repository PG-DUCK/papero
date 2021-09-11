# Git submodule workflow
1. Clone the repository with the `--recursive` option:
  `git clone --recursive git@bitbucket.org:msfoot/pgdaq.git`
2. To update the repository run:
  ```
  git pull
  git submodule update
  ```
3. If you already have cloned the repository:
  ```
  git submodule init
  git submodule update
  ```
***
# Hog walkthrough
For more information, read the official [documentation](https://hog.readthedocs.io).

- Be sure to clone the repository with the `--recursive` option
- `Top` folder contains all the projects with their configuration files
- From the git root folder run `./Hog/CreateProject.sh pgdaq` to create the quartus project
  + The command regenerates the _.qsys_ modules and includes all the other (_qip_, _vhd_, _v_, ...)
- The Quartus project (_.qpf_) is in the directory `Projects/pgdaq`
- Once the compiling process is over, Hog copies the output _.sof_ file and the reports in the folder `bin`
  + The files are organized in subfolders, named with the commit SHA and the tag
  + Make sure that all changes are committed (at least locally)
  + Create the correspondent incremental tag with the format vX.X.X (e.g. v.1.0.2)
  + These commit SHA and the tag are mapped in two FPGA registers


***
# Registers Content
## Configuration Registers
L'HPS può configurare l'FPGA accedendo a tali registri sia in lettura che in scrittura. La frequenza del clock è: 20 ns.
## Convenzioni
- I bit vanno intesi in logica positiva --> 1 = ON, 0 = OFF.
- Config_FIFO: fifo a valle del Config_Receiver.
- HK_FIFO: fifo a valle del hkReader.
- FastData_FIFO: fifo a valle del FastData_Transmitter.
- PRBS_FIFO: FIFO a cavallo tra la Test_Unit e il FastData_Transmitter.

|  # | Content | Default (hex) |
| -- | ------- | ------- |
| 0  | [31:0]: Riservato | C1A0C1A0 |
| 1  | Stato Top-Level. 1: Start/Stop trigger, 0: Reset(logica FPGA tranne registerArray) | XXXXXXX0 |
| 2  | Units Enable. 1: Test_Unit Enable e data multiplexer, 0: FastData_Transmitter Enable,  | XXXXXXX3 |
| 3  | Telemetria. 2: hkReader Enable, 1: Ricevi periodicamente (1 s) contenuto registerArray anche con Start/Stop=0, 0: Ricevi contenuto attuale del registerArray | XXXXXX02 |
| 4  | CFG trigBusyLogic. [31:4]: Periodo del trigger interno (a multipli di 320 ns), 0: Abilitazione trigger interno | 02faf080 |
| 5  | [7:0] Detector ID | XXXXXXFF |
| 6  | Setting length[31:0]: Lunghezza pacchetto dati scientifici (Payload 32-bit words + 10) | 0000006E |
| 7  | FE-clock  parameters. [31:16] duty cycle and [15:0] divider | 00040028 |
| 8  | ADC-clock parameters. [31:16] duty cycle and [15:0] divider | 00040002 |
| 9  | MSD parameters. 20: internal trigger on, 19:FE test, [18:16]:FE Gs, [15:0]: Trigger-2-Hold Delay (in clock cycles) | 00070145 |
| 16  | Versione del Firmware. [31:0]: SHA dell'ultimo commit |  |
| 17  | Internal Timestamp "high". [31:0]: Numero di clock passati dall'ultimo Reset calcolati internamente (word più significativa) |  |
| 18  | Internal Timestamp "low". [31:0]: Numero di clock passati dall'ultimo Reset calcolati esternamente (word meno significativa) |  |
| 19  | External Timestamp "high". [31:0]: Numero di clock passati dall'ultimo Reset calcolati internamente (word più significativa) |  |
| 20  | External Timestamp "low". [31:0]: Numero di clock passati dall'ultimo Reset calcolati esternamente (word meno significativa) |  |
| 21  | WARNING del sistema. [11:8]: FastData_Transmitter, [7:4]: hkReader, [3:0]: Config_Receiver |  |
| 22  | BUSY del sistema. 12: Stato di Busy, 11: AlmostFull Config_FIFO, 10: AlmostFull HK_FIFO, 9: AlmostFull FastData_FIFO, 8: AlmostFull PRBS_FIFO, [7:0]: Numero di trigger mancati dall'ultimo Reset |  |
| 23  | Trigger counter. [31:0]: Numero di impulsi di trigger dall'ultimo Reset |  |
| 24  | Config_FIFO. [15:0]: Numero di parole presenti nella Config_FIFO |  |
| 25  | HK_FIFO. [15:0]: Numero di parole presenti nella HK_FIFO |  |
| 26  | FastData_FIFO. [15:0]: Numero di parole presenti nella FastData_FIFO |  |
| 27  | PRBS_FIFO. [15:0]: Numero di parole presenti nella PRBS_FIFO |  |
