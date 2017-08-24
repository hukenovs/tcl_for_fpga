# tcl_for_fpga
TCL scripts for FPGA (Xilinx)

1. create_project.tcl - Create Xilinx Vivado project, find some files and add it into the project. Run synthesis, implementation.
2. upgrade_vivado_ips.tcl - Find vivado IP Cores, check for update, update them and run synth for IP cores.
3. vivado_clock_iter.tcl - Open synth project, report clock iteraction, find UNSAFE clock groups, analyze report file and set TIG (FALSE_PATH constraints) to several clock groups if needed. Save XDC file, re-run synth and check timing again.
4. vivado_ip_upgrade.tcl - Similar /2. Find vivado IP Cores, check for update, update them and run synth for IP cores. Also disable old XCO files (from xilinx ISE format).
