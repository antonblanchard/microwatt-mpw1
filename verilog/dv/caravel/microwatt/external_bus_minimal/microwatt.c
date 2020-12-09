#include <stdint.h>

#include "microwatt_util.h"

#define EXT_BUS_OFFSET 0x40000000

int main(void)
{
	uint64_t *p = (uint64_t *)EXT_BUS_OFFSET;

	microwatt_alive();

	__asm__ __volatile__("");
	*p = 0x5A5A5A5A5A5A5A5A;
	__asm__ __volatile__("");
	*p = 0x0f0f0f0f0f0f0f0f;
	__asm__ __volatile__("");
	*p = 0xACEACEACEACEACEA;
	__asm__ __volatile__("");

	microwatt_success();

	while (1)
		/* Do Nothing */ ;
}
