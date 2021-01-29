set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) RAM_512x64

set ::env(VERILOG_FILES) "\
	$script_dir/src/DFFRAM.v
	$script_dir/src/DFFRAMBB.v
	$script_dir/src/RAM_512x64.v"

set ::env(CLOCK_PORT) "CLK"
set ::env(CLOCK_PERIOD) "15"
set ::env(CLOCK_NET) $::env(CLOCK_PORT)

set ::env(CLOCK_TREE_SYNTH) 0

# Required because we are using standard cells
set ::env(SYNTH_READ_BLACKBOX_LIB) 1

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 2800 700"

# Settings for macros
set ::env(DESIGN_IS_CORE) 0
set ::env(FP_PDN_CORE_RING) 0
set ::env(GLB_RT_MAXLAYER) 5

# Tracks are ending up on met5 even with GLB_RT_MAXLAYER set
set ::env(GLB_RT_OBS) "met5 $::env(DIE_AREA)"

# Handle PDN
set ::env(VDD_NETS) [list {vccd1} ]
set ::env(GND_NETS) [list {vssd1} ]

# Tuning
set ::env(PL_OPENPHYSYN_OPTIMIZATIONS) 0
set ::env(PL_TARGET_DENSITY) 0.70
set ::env(CELL_PAD) 0

#set ::env(GLB_RT_L1_ADJUSTMENT) 0.99
#set ::env(GLB_RT_L2_ADJUSTMENT) 0.25
#set ::env(GLB_RT_L3_ADJUSTMENT) 0.25
#set ::env(GLB_RT_L4_ADJUSTMENT) 0.2
#set ::env(GLB_RT_L5_ADJUSTMENT) 0.1
#set ::env(GLB_RT_L6_ADJUSTMENT) 0.1

set ::env(DIODE_INSERTION_STRATEGY) 5

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

if {[catch {exec nproc} result] == 0} {
	set ::env(ROUTING_CORES) $result
} else {
	set ::env(ROUTING_CORES) 4
}
