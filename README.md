# Git submodule workflow
1. Clone the repository with the `--recursive` option:
  `git clone --recursive git@github.com:PerugiaOverNetDAQ/papero.git`
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
- From the git root folder run `./Hog/CreateProject.sh papero` to create the quartus project
  + The command regenerates the _.qsys_ modules and includes all the other (_qip_, _vhd_, _v_, ...)
- The Quartus project (_.qpf_) is in the directory `Projects/papero`
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
| 0  | Stato Top-Level. 4: Start/Stop trigger, 2: Reset regArray, 1: Reset contatori, 0: Reset(logica FPGA tranne registerArray) | XXXXXX00 |
| 1  | Units Enable. [9:8] Test Unit configuration, 6: hkReader Enable, 5: Ricevi periodicamente (1 s) contenuto registerArray, 4: Ricevi contenuto attuale del registerArray, 1: Test_Unit/Detector_n Enable e data multiplexer, 0: FastData_Transmitter Enable,  | XXXXX001 |
| 2  | CFG trigBusyLogic. [31:4]: Periodo del trigger interno (a multipli di 320 ns), 1: Calibrazione, 0: Abilitazione trigger interno | 02faf080 |
| 3  | [15:0] Detector ID | XXXXF0CA |
| 4  | Setting length[31:0]: Lunghezza pacchetto dati scientifici (Payload 32-bit words + 10) | 0000028A |
| 5  | FE-clock  parameters. [31:16] duty cycle and [15:0] divider | 00040028 |
| 6  | ADC-clock parameters. [31:16] duty cycle and [15:0] divider | 00040002 |
| 7  | MSD parameters. [15:0]: Trigger-2-Hold Delay (in clock cycles) | 00070145 |
| 16  | Versione del Gateware. [31:0]: SHA dell'ultimo commit |  |
| 17  | Internal Timestamp "high". [31:0]: Numero di clock passati dall'ultimo Reset calcolati internamente (word più significativa) |  |
| 18  | Internal Timestamp "low". [31:0]: Numero di clock passati dall'ultimo Reset calcolati esternamente (word meno significativa) |  |
| 19  | External Timestamp "high". [31:0]: Numero di clock passati dall'ultimo Reset calcolati internamente (word più significativa) |  |
| 20  | External Timestamp "low". [31:0]: Numero di clock passati dall'ultimo Reset calcolati esternamente (word meno significativa) |  |
| 21  | WARNING del sistema. [11:8]: FastData_Transmitter, [7:4]: hkReader, [3:0]: Config_Receiver |  |
| 22  | BUSY. 31: Busy flag, 28: TestUnit, [27:20] Busies AND, [19:12] Busies OR, 11: FastData TX, 10: HK FIFO aFull, 9: Fast FIFO aFull, 8: FDI FIFO aFull, [7:0] Triggers occurred when busy is asserted |  |
| 23  | External Trigger counter. [31:0]: Numero di impulsi di trigger esterni dall'ultimo Reset |  |
| 24  | Internal Trigger counter. [31:0]: Numero di impulsi di trigger interni dall'ultimo Reset |  |
| 25  | PRBS_FIFO. [15:0]: Numero di parole presenti nella PRBS_FIFO |  |
| 31  | [31:0]: Piumone | C1A0C1A0 |
