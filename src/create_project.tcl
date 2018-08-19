# ---------------------------------------------------------------- 
# --
# -- Title    : test_vivado
# -- Author   : Alexander Kapitanov
# -- Company  : Insys
# -- E-mail   : kapitanov@insys.ru
# --		   	
# ---------------------------------------------------------------- 
# -- Description :
# --
# -- 1. Используется для создания проектов с помощью скрипта
# -- 2.	Расположение скрипта в проекте - ./src/tcl/
# -- 3. Для создания проекта надо задать всего три переменных
# -- 	PartDev - тип кристалла ПЛИС	
# -- 	PrjDir - рабочий каталог проекта (БЕЗ ИМЕНИ ПРОЕКТА)
# -- 	TopName - имя названия проекта и файла верхнего уровня
# -- 4. Можно расширить использование скрипта до стадий Synthesis
# --	и Implement. См. Stage 10-11.	   	
# ---------------------------------------------------------------- 
# Useful Procedures and Functions are here
# ---------------------------------------------------------------- 

# findFiles can find files in subdirs and add it into a list
proc findFiles { basedir pattern } {

    # Fix the directory name, this ensures the directory name is in the
    # native format for the platform and contains a final directory seperator
    set basedir [string trimright [file join [file normalize $basedir] { }]]
    set fileList {}
	array set myArray {}
	
    # Look in the current directory for matching files, -type {f r}
    # means ony readable normal files are looked at, -nocomplain stops
    # an error being thrown if the returned list is empty

    foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
        lappend fileList $fileName
    }	
	
    # Now look for any sub direcories in the current directory
    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
        # Recusively call the routine on the sub directory and append any
        # new files to the results
		# put $dirName
	    set subDirList [findFiles $dirName $pattern]
        if { [llength $subDirList] > 0 } {
            foreach subDirFile $subDirList {
				lappend fileList $subDirFile
            }
        }
    }
	return $fileList
}
# ---------------------------------------------------------------- 

# Stage 0: You don't need to set project name and dir path !!!
set TclPath [file dirname [file normalize [info script]]]
set NewLoc [string range $TclPath 0 [string last / $TclPath]-5]

# Stage 1: Specify project settings 
set PartDev "xc7k325tffg900-2"
# set PrjDir "C:/Work/prog/adm"
# set TopName "project_example"
set PrjDir [string range $TclPath 0 [string last / $NewLoc]]
set TopName [string range $NewLoc [string last / $NewLoc]+1 end]

# Stage 2: Auto-complete part for path
set PrjName $TopName.xpr
set SrcDir $PrjDir/$TopName/src
set VivNm "vivado"
set VivDir $PrjDir/$TopName/$VivNm

# Stage 3: Delete trash in project directory
cd $PrjDir/$TopName
pwd

if {[file exists $VivNm] == 1} { 
	file delete -force $VivNm 
}
file mkdir $VivNm
cd $VivDir

# Stage 4: Find sources: *.vhd, *.ngc *.xci *.xco *.xdc etc.
# This stage used instead of: add_files -scan_for_includes $SrcDir
set SrcVHD [findFiles $SrcDir "*.vhd"]
set SrcVer [findFiles $SrcDir "*.v"]
set SrcNGC [findFiles $SrcDir "*.ngc"]
set SrcXCI [findFiles $SrcDir "*.xci"]
set SrcXDC [findFiles $SrcDir "*.xdc"]

# Stage 5: Find PCI-E Module and subdirs for sources for simulation
set SrcPCI [findFiles $SrcDir "cl_pcie*"]
set NewLoc [string range $SrcPCI 0 [string last / $SrcPCI]-6]

set DirAdm $NewLoc/adm_simulation
set DirIps $NewLoc/core
#set DirRtl $NewLoc/rtl
#set DirTop $NewLoc/top

# Stage 6: Find all subdirs for IP cores (VHD, XCO, NGC, EDN)
set PrjAll {}
lappend PrjAll $DirIps $DirAdm $SrcDir/core_v2_ise $SrcDir/core_v4_ise $SrcDir/core_v5_ise $SrcDir/core_v6_ise $SrcDir/core_k7 $SrcDir/TestBench

set SrcSim {}
for {set i 0} {$i < [llength $PrjAll]} {incr i} {
	set SrcXXX [findFiles [lindex $PrjAll $i] "*.vhd"]
	put $SrcXXX
	foreach SrcAdd $SrcXXX {
		lappend SrcSim $SrcAdd
	}
}

# Stage 7: Create project and add source files
create_project -force $TopName $VivDir -part $PartDev
set_property target_language VHDL [current_project]

# Add NGC source files
add_files -norecurse $SrcNGC
# Add XCI source files
add_files -norecurse $SrcXCI
export_ip_user_files -of_objects [get_files $SrcXCI] -force -quiet
# Add VHDL source files
add_files $SrcVHD
# Add XDC source files
add_files -fileset constrs_1 -norecurse $SrcXDC
# Add Verilog source files
# add_files -norecurse $SrcVer

# Stage 8: Set properties and update compile order
set_property top $TopName [current_fileset]
for {set i 0} {$i < [llength $SrcSim]} {incr i} {
	set_property used_in_synthesis false [get_files [lindex $SrcSim $i]]
}

set NgcGlb [findFiles $DirIps "*.ngc"]
for {set i 0} {$i < [llength $NgcGlb]} {incr i} {
	set_property IS_GLOBAL_INCLUDE 1 [get_files [lindex $NgcGlb $i]]
}
set_property IS_GLOBAL_INCLUDE 1 [get_files $SrcPCI]

# Stage 9: Upgrade IP Cores (if needed)
report_ip_status -name ip_status 
set IpCores [get_ips]
for {set i 0} {$i < [llength $IpCores]} {incr i} {
	set IpSingle [lindex $IpCores $i]
	
	set locked [get_property IS_LOCKED $IpSingle]
	set upgrade [get_property UPGRADE_VERSIONS $IpSingle]
	if {$upgrade != "" && $locked} {
		upgrade_ip $IpSingle
	}
}
report_ip_status -name ip_status

# Stage 10: Set properties for Synthesis and Implementation (Custom field)
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.BUFG 0 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 1000 [get_runs synth_1]

set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]

# Stage 11: Launch runs for Synthesis and Implementation (Custom field)

# launch_runs synth_1
# wait_on_run synth_1
# open_run synth_1 -name synth_1
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# open_run impl_1 -name impl_1