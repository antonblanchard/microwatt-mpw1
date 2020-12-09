#include <stdbool.h>

#include "../../defs.h"

static void inline mgmt_engine_io_setup(bool jtag, bool external_bus)
{
	// Set LA[65] as output to act as a reset pin for microwatt and
	// LA[66] as output to specify reset location (RAM or FLASH)
	reg_la2_ena = 0xFFFFFFF9;

	// Put microwatt into reset and tell it to fetch from flash
	reg_la2_data = 0x00000002 | 0x00000004;

	// Set up the housekeeping SPI to be connected internally so
	// that external pin changes don't affect it.
	reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
					// connect to housekeeping SPI

	// Communicate status with test case over GPIO 7 and 37
	reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;

	// Signal to the tb that we are alive
	reg_mprj_datal = GPIO1_MGMT_ENGINE_START;

	// Configure UART
	reg_mprj_io_5 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_6 = GPIO_MODE_USER_STD_OUTPUT;

	// 7 unused

	// Configure SPI
	reg_mprj_io_8 = GPIO_MODE_USER_STD_OUTPUT;		// CSB
	reg_mprj_io_9 = GPIO_MODE_USER_STD_OUTPUT;		// SCK
	reg_mprj_io_10 = GPIO_MODE_USER_STD_BIDIRECTIONAL;	// IO0/MOSI
	reg_mprj_io_11 = GPIO_MODE_USER_STD_BIDIRECTIONAL;	// IO1/MISO
	reg_mprj_io_12 = GPIO_MODE_USER_STD_BIDIRECTIONAL;	// IO2
	reg_mprj_io_13 = GPIO_MODE_USER_STD_BIDIRECTIONAL;	// IO3

	// Configure JTAG
	if (jtag) {
		// Overlaps our testbench status bits
		reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;		// TDO
		reg_mprj_io_15 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;	// TMS
		reg_mprj_io_16 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;	// TCK
		reg_mprj_io_17 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;	// TDI
	}

	// Configure external bus
	if (external_bus) {
		reg_mprj_io_18 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_19 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_20 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_21 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_22 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_23 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_24 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_25 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_26 = GPIO_MODE_USER_STD_OUTPUT;
		reg_mprj_io_27 = GPIO_MODE_USER_STD_OUTPUT;
	}
	reg_mprj_io_28 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_29 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_30 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_31 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_32 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_33 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_34 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_35 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_36 = GPIO_MODE_USER_STD_INPUT_PULLDOWN;

	// 37 unused

	// Now, apply the configuration
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1)
		/* Do Nothing */;

	// Configure LA bits 0-31 as inputs from Microwatt
	reg_la0_ena = 0xFFFFFFFF;	// [31:0]

	// Configure LA bits 63-32 as outputs from Microwatt
	reg_la1_ena = 0x00000000;	// [63:32]
}
