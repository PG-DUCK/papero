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
# Register Array Content
## Configuration Registers
With these registers, the HPS configures all the modules of the FPGA. HPS have read/write access, while FPGA read-only.

|  # | Content | Default (hex) |
| -- | ------- | ------------- |
| 0  | Reset, Start, Stop: |  XXXXXX00 |
|    | 4: Start/Stop trigger | 0 |
|    | 2: Reset regArray | 0 |
|    | 1: Reset counters | 0 |
|    | 0: Reset FPGA logic, regArray excluded  | 0 |
| 1  | Enable and configuration of TdaqModule Units: | XXXXX001 |
|    | [9:8]: Test Unit configuration | 0 |
|    | 6: hkReader Enable | 0 |
|    | 5: Periodically (1s) receive content of regArray | 0 |
|    | 4: Read content of the regArray, instantaneously | 0 |
|    | 1: Enable/Disable_n for Test Unit and Detector Interface. If '0', enable Detector Interface and disable Test Unit | 0 |
|    | 0: FastData_Transmitter Enable | 1 |
| 2  | Configuration of trigger and busy logic: | 02faf080 |
|    | [31:4]: Period of internal trigger, in 320 ns units. Default period of 1 second | 02faf080 |
|    | 1: Calibration flag: if asserted, change the events' header flag to calibration| 0 |
|    | 0: Enable internal trigger | 0 |
| 3  | [15:0] Detector ID | XXXXF0CA |
| 4  | Length of the scientific-data packet in number of 32-bit words (note that the header is 10 words long) | 0000028A |
| 5  | IDE1140 clock parameters: | 00110022 |
|    | [31:16]: Duty cycle (in system-clock cycles) | 0011 |
|    | [15:0]: Period (in system-clock cycles) | 0022 |
| 6  | AD7276 clock parameters: | 00010002 |
|    | [31:16]: Duty cycle (in system-clock cycles) | 0001 |
|    | [15:0]: Period (in system-clock cycles) | 0002 |
| 7  | MSD-specific parameters | 01070145 |
|    | 8: AD7276 Fast Mode support | 1 |
|    | [15:0]: Trigger-2-Hold Delay (in clock cycles) | 0145 |


## Status Registers
The FPGA writes its status in these registers. FPGA has read/write access, while HPS read-only. 

|  #  | Content | Default (hex) |
| --- | ------- | ------------- |
| 16 | Gateware version: SHA of the git commit that generate the current system   | |
| 17 | Internal timestamp MSBs: Number of system-clock's ticks from the last reset | |
| 18 | Internal timestamp LSBs | |
| 19 | External timestamp MSBs: Number of external clock's ticks from the last reset | |
| 20 | External timestamp LSBs | |
| 21 | Warnings: | 00000000 |
|    | 8: FD  TX: Generic warning | |
|    | 2: CFG RX: GW version mismatch | |
|    | 1: CFG RX: Header or trailer fixed-words missing | |
|    | 0: CFG RX: CRC or parity-bits mismatch  | |
| 22 | Busy and full flags: | 00000000 |
|    | 31: General busy flag  | |
|    | 28: testUnit busy | |
|    | [27:20]: AND inputs of the trigBusy unit | |
|    | [19:12]: OR  inputs of the trigBusy unit | |
|    | 11: FD TX busy | |
|    | 10: HK FIFO almost full | |
|    |  9: Fast FIFO almost full | |
|    |  8: FDI FIFO almost full | |
|    | [7:0]: Triggers occurred when busy asserted | |
| 23 | External trigger counter | |
| 24 | Internal trigger counter | |
| 25 | [15:0]: testUnit PRBS FIFO used words | |
| 31 | Piumone: control word | C1A0C1A0 |