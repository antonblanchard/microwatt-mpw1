#include "lfsr32.h"
#include <stdint.h>

#define LFSR_32 ((1 << (32-1)) | (1 << (22-1)) | (1 << (2-1)) | (1 << (1-1)))

uint32_t lfsr32(uint32_t prev)
{
	uint32_t lsb = prev & 1;

	prev >>= 1;
	if (lsb == 1)
		prev ^= LFSR_32;

	return prev;
}
