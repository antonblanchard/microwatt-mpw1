#include "../../defs.h"
#include "../../stub.c"

#include "../include/microwatt_util.h"
#include "../include/mgmt_engine_util.h"

#include "lfsr32.h"

// --------------------------------------------------------

void main(void)
{
	unsigned long lfsr = LFSR32_INIT;

	mgmt_engine_io_setup(false, true);

	// Take microwatt out of reset
	reg_la2_data &= ~0x00000002;

	while (reg_la0_data != LA_MICROWATT_START)
		/* Do Nothing */ ;

	// Signal to TB that microwatt is alive
	reg_mprj_datal = GPIO1_MICROWATT_START;

	for (unsigned long i = 0; i < 10; i++) {
		// Send next LFSR in the sequence to Microwatt
		reg_la1_data = lfsr;

		lfsr = lfsr32(lfsr);

		// Wait for next LFSR in the sequence from Microwatt
		while (reg_la0_data != lfsr)
			/* Do Nothing */ ;

		lfsr = lfsr32(lfsr);
	}

	// Signal success to the TB
	reg_mprj_datal = GPIO1_SUCCESS;

	while (1)
		/* Do Nothing */;
}
