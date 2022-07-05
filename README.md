# TCL Scripts for FPGA
Useful TCL scripts for FPGA projects based on Vivado and Vivado HLS (Xilinx).

> Break free from the daily routine!  

License: MIT

### Main information

| **Title**         | TCL scripts for Vivado |
| -- | -- |
| **Author**        | [Alexander Kapitanov](https://www.linkedin.com/in/hukenovs) |
| **Language**      | TCL                    |
| **Vendor**        | Xilinx                 |
| **Project**       | [Habr](https://habr.com/ru/post/308962/) |
| **Release Date**  | 10 May 2016            |
| **Update  Date**  | 06 Nov 2019            |

1. **create_project.tcl** - Create Xilinx Vivado project, find some files and add it into the project. Run synthesis, implementation.
2. **upgrade_vivado_ips.tcl** - Find vivado IP Cores, check for update, update them and run synth for IP cores.
3. **vivado_clock_iter.tcl** - Open synth project, report clock iteraction, find UNSAFE clock groups, analyze report file and set **TIG** (_FALSE_PATH_ constraints) to several clock groups if needed. Save XDC file, re-run synth and check timing again.
4. **vivado_ip_upgrade.tcl** - Similar p/2. Find vivado IP Cores, check for update, update them and run synth for IP cores. Also disable old XCO files (from xilinx ISE format) for AO "Insys" projects.
5. **create_fft_ips.tcl** - Useful script for fast creating FFT cores in Vivado (GUI or bash mode).
6. **create_mcs.tcl** - Auto-create .msc from .bit file.
7. **modify_top_info.tcl** - Pre-synthesis modification for top level file. Calculate current Date & Time, check SVN Revision & Modification and find Build (FPGA implementation counter). Read & write this parameters into the top level file (VHDL or Verilog source).
