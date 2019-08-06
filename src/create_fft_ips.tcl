# ---------------------------------------------------------------------------- 
# --
# -- Title    : Create IPs
# -- Author   : Alexander Kapitanov
# -- Company  : AO "Insys"
# -- E-mail   : sallador@bk.ru
# --
# ---------------------------------------------------------------------------- 
# --
# -- Description :
# --
# -- 1. Используется для быстрого создания FFT IP CORES
# -- 2. Расположение скрипта в проекте - ./src/tcl/
# -- 3. Требуется задать только имя ядра (составное или обычное)
# -- 4. Ядра лежат в каталоге ./src/ip_cores (должен быть создан)
# --
# ----------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2016 Alexander Kapitanov
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ----------------------------------------------------------------------------
set ipForm .xci;
set TclPath [file dirname [file normalize [info script]]]
set NewLoc [string range $TclPath 0 [string last / $TclPath]-5]
set IpLoc $NewLoc/src/ip_cores

set prjName [current_project];

# ---- CHANGE IP CORE NAMES ---- #
set fftName xfft_nat_i16_n;
set fftLast k;

# ---- Create ip cores ---- #
puts $NewLoc;
for {set i 0} {$i < 7} {incr i} {
    set nFFT [expr int([expr pow(2, $i + 10)])];
    set j [expr int([expr pow(2, $i)])];
    set bRAMS [expr $i+3];
    set coreName $fftName$j$fftLast;
    puts $coreName;

    update_ip_catalog
    create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name $coreName -dir $IpLoc
    set_property -dict [list CONFIG.Component_Name $coreName CONFIG.transform_length $nFFT CONFIG.implementation_options {pipelined_streaming_io} CONFIG.scaling_options {unscaled} CONFIG.rounding_modes {convergent_rounding} CONFIG.aresetn {true} CONFIG.output_ordering {natural_order} CONFIG.complex_mult_type {use_mults_performance} CONFIG.butterfly_type {use_xtremedsp_slices} CONFIG.implementation_options {pipelined_streaming_io} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors $bRAMS] [get_ips $coreName]
}

# ---- Set core container enabled ---- #
set ipFFT [get_ips];
for {set i 0} {$i < [llength $ipFFT]} {incr i} {
    set IpSingle [lindex $ipFFT $i]
    set coreContainer [get_property IP_CORE_CONTAINER $IpSingle];
    set coreFile [get_property IP_FILE $IpSingle];
    
    if {$coreContainer > 0} {
        
    } else {
        convert_ips [get_files $coreFile];
        export_ip_user_files -of_objects  [get_files  $coreFile] -sync -lib_map_path [list {modelsim=$NewLocvivado/$prjName.cache/compile_simlib/modelsim} {questa=$NewLocvivado/$prjName.cache/compile_simlib/questa} {riviera=$NewLocvivado/$prjName.cache/compile_simlib/riviera} {activehdl=$NewLocvivado/$prjName.cache/compile_simlib/activehdl}] -force -quiet
    }
}

# # ---- Generate output product ---- #
# for {set i 0} {$i < [llength $ipFFT]} {incr i} {
    # # set coreFile [get_property IP_FILE $IpSingle];
    # set coreFile [get_property NAME $IpSingle];
    # generate_target all [get_files $coreFile];  
# }

# for {set i 0} {$i < [llength $ipFFT]} {incr i} {
    # set coreFile [get_property NAME $IpSingle];
    # export_ip_user_files  -of_objects  [get_files $coreFile] -no_script -sync -force -quiet;
    # create_ip_run [get_files -of_objects [get_fileset sources_1] $coreFile];
# }
# launch_runs -jobs 4 $ipFFT;
