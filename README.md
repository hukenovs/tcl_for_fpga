# tcl_for_fpga
Useful TCL scripts for FPGA projects on Vivado (Xilinx).

> Break free from the daily routine!  

License: MIT

### Main information


| **Title**         | TCL scripts for VIVADO|
| -- | -- |
| **Author**        | Alexander Kapitanov   |
| **Contact**       | sallador@bk.ru        |
| **Project lang**  | TCL                   |
| **Vendor**        | Xilinx                |
| **Release Date**  | 10 May 2016           |
| **Update  Date**  | 23 May 2019           |
| **Version**       | 1.1                   |


1. **create_project.tcl** - Create Xilinx Vivado project, find some files and add it into the project. Run synthesis, implementation.
2. **upgrade_vivado_ips.tcl** - Find vivado IP Cores, check for update, update them and run synth for IP cores.
3. **vivado_clock_iter.tcl** - Open synth project, report clock iteraction, find UNSAFE clock groups, analyze report file and set **TIG** (_FALSE_PATH_ constraints) to several clock groups if needed. Save XDC file, re-run synth and check timing again.
4. **vivado_ip_upgrade.tcl** - Similar p/2. Find vivado IP Cores, check for update, update them and run synth for IP cores. Also disable old XCO files (from xilinx ISE format) for AO "Insys" projects.
5. **create_fft_ips.tcl** - Useful script for fast creating FFT cores in Vivado (GUI or bash mode).
6. **create_mcs.tcl** - Auto-create .msc from .bit file.
