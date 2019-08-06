# ---------------------------------------------------------------- 
# --
# -- Title    : Create *.MSC from *.BIT
# -- Author   : Alexander Kapitanov
# -- Company  : AO "Insys"
# -- E-mail   : sallador@bk.ru
# --
# ----------------------------------------------------------------
# -- Description :
# --
# -- This script allows you create *.msc file without setting
# -- parameters. You should only change MSC format.
# -- 
# -- For example: -format mcs -size 32 -interface SPIx4
# -- 
# ---------------------------------------------------------------- 
# Go to project directory
cd [get_property DIRECTORY [current_project]]
cd ..

# Get implementation set
set ImpNum [current_run -implementation]

# Implementation directory, top name, bit file
set VivTop [lindex [find_top] 0]
set VivDir [get_property DIRECTORY [current_project]]
set VivName [get_property NAME [current_project]]
set VivBit $VivDir/$VivName.runs/$ImpNum/$VivTop.bit

# Change 'date format'
set VivList [split "[clock format [clock seconds] -format %D]" {/}
set NewDate "_[lindex $VivList 2]_[lindex $VivList 0]_[lindex $VivList 1]"

# MCS file directory
set VivMSC [pwd]/$VivTop$NewDate.msc

# Create MSC file
write_cfgmem  -format mcs -size 32 -interface SPIx4 -loadbit "up 0x00000000 $VivBit" -checksum -force -file "$VivMSC"
