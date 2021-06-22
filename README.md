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
