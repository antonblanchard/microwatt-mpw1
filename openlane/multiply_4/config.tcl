set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) multiply_4

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/multiply_4.v"

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "30"
set ::env(CLOCK_NET) $::env(CLOCK_PORT)

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 1000 1000"

# Settings for macros
set ::env(DESIGN_IS_CORE) 0
set ::env(FP_PDN_CORE_RING) 0
set ::env(GLB_RT_MAXLAYER) 5

# Tracks are ending up on met5 even with GLB_RT_MAXLAYER set
set ::env(GLB_RT_OBS) "met5 $::env(DIE_AREA)"

# Handle PDN
set ::env(VDD_NETS) [list {vccd1} {vccd2} {vdda1} {vdda2}]
set ::env(GND_NETS) [list {vssd1} {vssd2} {vssa1} {vssa2}]

# Tuning
set ::env(PL_TARGET_DENSITY) 0.60
set ::env(CELL_PAD) 4

set ::env(SYNTH_STRATEGY) "DELAY 2"

set ::env(GLB_RT_L1_ADJUSTMENT) 0.99
set ::env(GLB_RT_L2_ADJUSTMENT) 0.25
set ::env(GLB_RT_L3_ADJUSTMENT) 0.25
set ::env(GLB_RT_L4_ADJUSTMENT) 0.2
set ::env(GLB_RT_L5_ADJUSTMENT) 0.1
set ::env(GLB_RT_L6_ADJUSTMENT) 0.1

set ::env(DIODE_INSERTION_STRATEGY) 5

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

if {[catch {exec nproc} result] == 0} {
	set ::env(ROUTING_CORES) $result
} else {
	set ::env(ROUTING_CORES) 4
}
