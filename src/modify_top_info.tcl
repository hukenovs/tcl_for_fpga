# ---------------------------------------------------------------- 
# --
# -- Title    : Change Build, Date & Time, SVN Revision
# -- Author   : Alexander Kapitanov
# -- E-mail   : sallador@bk.ru
# --            
# ----------------------------------------------------------------  
# --
# -- Description : Automatically change build, date & time, check 
# --                SVN revision and modification into the project 
# --                for Xilinx Vivado projects.
# --
# ----------------------------------------------------------------  
# --
# -- HOW-TO:
# -- 
# -- Step 0: Move this TCL script to src/tcl directory
# -- 
# -- proj_dir
# --   - src
# --       - top
# --       - ips
# --       - vhdl
# --       - verilog
# --       - bd
# --       - tcl
# --   - viv
# --       - synth
# --       - impl
# -- 
# -- Step 1: Change your top file (add some constants):
# --
# -- -- You should use four constants for this purpose:
# -- constant FPGA_YYYY      : std_logic_vector(15 downto 0):=x"07E3"; -- SET_FPGA_YYYY
# -- constant FPGA_MMDD      : std_logic_vector(15 downto 0):=x"0B06"; -- SET_FPGA_MMDD
# -- constant FPGA_BUILD     : std_logic_vector(15 downto 0):=x"1A61"; -- SET_FPGA_BUILD
# -- constant FPGA_SVNREV    : std_logic_vector(15 downto 0):=x"0EC1"; -- SET_FPGA_SVNREV
# -- constant FPGA_SVNMOD    : std_logic_vector(15 downto 0):=x"0001"; -- SET_FPGA_SVNMOD
# --
# --
# -- constant top_info:  rom_top:=
# -- (
# -- --
# --     0 => FPGA_BUILD,
# --     1 => FPGA_ID,
# --     2 => FPGA_YYYY,
# --     3 => FPGA_MMDD,
# --     4 => FPGA_SVNREV,
# --     5 => FPGA_SVNMOD,
# --     6 to 15 => x"0000
# -- --
# -- ):
# --
# -- 
# -- Step 2: Change your Synthesis settings:
# -- 
# --     Just add this script to tcl.pre field (pre-step tcl hook)
# -- or
# --     >> set_property STEPS.SYNTH_DESIGN.TCL.PRE {PATH_TO_TCL} [get_runs synth_1]
# --
# --
# -- Run and enjoy!
# --
# ----------------------------------------------------------------  

# Stage 0: Set top module PATH and getpatterns
# set TopPath [get_files "[get_property top [current_fileset]].vhd"]
# set TopPath [get_files "[get_property top [current_fileset]].v"]

set TclPath [file dirname [file normalize [info script]]]
set TopDir [string range $TclPath 0 [string last / $TclPath]-1]

set TopFile $TopDir/top/*.vhd
set TopPath [glob $TopFile]

set SysTime [clock seconds]
set BldHexStr " "


# Calculate Time and Date
set FpgaYY [clock format $SysTime -format {%Y}]
set FpgaMM [expr [clock format $SysTime -format {%m}] << 8]
set FpgaDD [clock format $SysTime -format {%d}]
set FpgaMD [expr $FpgaMM + $FpgaDD]

# Calculate SVN Revision
set DirSVN [string range $TclPath 0 [string last / $TclPath]-5]
cd $DirSVN

# set InfoSVN [exec svn info]
set LineSVN [split [exec svn info] "\n"]

foreach line $LineSVN {
   if [regexp {Last Changed Rev: } $line ] {
      set FPGA_SVNREV [lindex [split $line] 3]
   }
}

set StatusSVN [split [exec svn status] "\n"]

set FPGA_SVNMOD 0
foreach var $StatusSVN {
    if {[string index $var 0] == "M"} {
        set FPGA_SVNMOD 1
        break
    }
}


# Stage 1: Read file line by line
set TestFile [open $TopPath r]
set lines [split [read $TestFile] "\n"]
close $TestFile


# Stage 2: Parse top file and change Date & Time & Build
set TestRptId [open $TopPath w]

foreach line $lines {
    # Year
    if {[string first "SET_FPGA_YYYY" $line] != -1} {
        regsub {"(.*?)"} $line \"[format %4.4X $FpgaYY]\" line
    }

    # Month & Day
    if {[string first "SET_FPGA_MMDD" $line] != -1} {
        regsub {"(.*?)"} $line \"[format %4.4X $FpgaMD]\" line
    }

    # Build
    if {[string first "SET_FPGA_BUILD" $line] != -1} {
        # Find old build, convert to int -> hex -> make new build
        regexp {([0-9a-fA-F]{4})} $line -> BldHexStr
        scan $BldHexStr %x buildInt
        regsub {"(.*?)"} $line \"[format %4.4X [expr {$buildInt + 1}]]\" line
    }

    # Revision
    if {[string first "SET_FPGA_SVNREV" $line] != -1} {
        regsub {"(.*?)"} $line \"[format %4.4X $FPGA_SVNREV]\" line  
    }

    # Check Modification
    if {[string first "SET_FPGA_SVNMOD" $line] != -1} {
        regsub {"(.*?)"} $line \"[format %4.4X $FPGA_SVNMOD]\" line  
    }

    puts $TestRptId $line
}

close $TestRptId


# Stage 3: Reset synthesis design and re-run synth
# reset_run synth_1
# launch_runs synth_1 -jobs 4
# wait_on_run synth_1
# set_property needs_refresh false [get_runs synth_1]
