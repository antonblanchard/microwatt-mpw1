#include <stdint.h>

#include "microwatt_util.h"
#include "lfsr32.h"

#define LA_OFFSET 0xc8020000

int main(void)
{
	uint32_t lfsr = LFSR32_INIT;

	microwatt_alive();

	while (1) {
		// Wait for next LFSR in the sequence from Microwatt
		while (readl(LA_OFFSET) != lfsr)
			/* Do Nothing */ ;

		lfsr = lfsr32(lfsr);

		// Send next LFSR in the sequence to Microwatt
		writel(lfsr, LA_OFFSET);

		lfsr = lfsr32(lfsr);
	}
}
