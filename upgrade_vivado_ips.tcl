# ---------------------------------------------------------------- 
# --
# -- Title    : TCL Script for updating Vivado IP Cores 
# -- Author   : Alexander Kapitanov
# -- Company  : Instrumental Systems
# -- E-mail   : kapitanov@insys.ru
# --		   	
# ----------------------------------------------------------------  
# --
# -- Description :    
# -- 
# -- 1. Используется для регенерации IP-ядер при смене типа ПЛИС	
# -- 2.	Расположение скрипта в проекте - ./src/tcl/
# -- 3. Запуск из рабочей директории проекта Vivado
# -- 4. Для синтеза IP-ядер необходимо добавить Stage 5 и 6
# -- 5. Каталог с IP-ядрами должен иметь название: src/ipcores
# -- 6. Каталог с проекта должен иметь название: vivado
# -- 7. Если названия отличаются, поменять значения в параметрах
# --	ProgDir и CoreDir (см. исходный код)
# --	   	
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
				
				#set SizeStr [string length $dirName]
				#set NewFile [string range $subDirFile $SizeStr+1 end]
				lappend fileList $subDirFile
            }
        }
    }
	return $fileList
}
# ---------------------------------------------------------------- 

# Stage 1: Set IP Cores working directory (change if needed)
cd [get_property directory [current_project]]
set WorkDir [pwd]
set ProgDir [string trim $WorkDir "*vivado" ]

# Stage 2: Find name of the actual project
cd ../../
set NewVal [pwd]

set SizeStr [string length $NewVal]
set ProgName [string range $ProgDir $SizeStr+1 end-1]
set ProgFile $WorkDir/$ProgName.ip_user_files

cd [get_property directory [current_project]]

# Stage 3: Create some useful variables for current project
set CoreDir $ProgDir/src/ipcores
set CoreXCI "*.xci"	
	
set basedir $CoreDir
set basepat $CoreXCI	

# Stage 4: Report IP Status and Update IP Cores (change if needed)
report_ip_status -name ip_status 
export_ip_user_files -of_objects [get_ips] -no_script -reset -quiet
#upgrade_ip [get_ips] -log ip_upgrade.log
set IpCores [get_ips]
for {set i 0} {$i < [llength $IpCores]} {incr i} {
	set IpSingle [lindex $IpCores $i]
	
	set locked [get_property IS_LOCKED $IpSingle]
	set upgrade [get_property UPGRADE_VERSIONS $IpSingle]
	if {$upgrade != "" && $locked} {
		upgrade_ip $IpSingle;#-log ip_upgrade.log
	}
}

# !! -- CAREFUL: Regenerate IP Cores if you need this. -- !!

# Stage 5: Find full path for each IP Core
set IpNames [findFiles $basedir $basepat]
set IpLists {}

# Stage 6: Regenerate all IP Cores:
generate_target all [get_files  $IpNames]
for {set i 0} {$i < [llength $IpNames]} {incr i} {
	set IpSingle [lindex $IpNames $i]
	
	export_ip_user_files -of_objects [get_files $IpSingle] -no_script -force -quiet
	create_ip_run [get_files -of_objects [get_fileset sources_1] $IpSingle]
	
	set IpSingle [lindex $IpCores $i]
	set IpSynth $IpSingle
	append IpSynth "_synth_1"
	foreach AllSynth $IpSynth {
		lappend IpLists $AllSynth
	}
	#launch_run  {clk_wiz_tst_synth_1 ctrl_dds60mhz_prog_synth_1 ctrl_mmcm_in60_out300_240_synth_1 ctrl_ramb1024x32_synth_1}
	#export_simulation -of_objects [get_files $IpSingle] -directory $ProgFile/sim_scripts -ip_user_files_dir $ProgFile -ipstatic_source_dir $ProgFile/ipstatic -force -quiet
}

launch_run $IpLists
export_simulation -of_objects [get_files $IpNames] -directory $ProgFile/sim_scripts -ip_user_files_dir $ProgFile -ipstatic_source_dir $ProgFile/ipstatic -force -quiet

# Stage 7: Report IP Status (Control check point)
report_ip_status -name ip_status 