#include <stdint.h>
#include <stdio.h>
#include "hash.h"

#define START_OFFSET 0x2000UL
#define END_OFFSET (16UL*1024*1024)

int main(void)
{
	printf("@%lx\n", START_OFFSET);

	for (uint64_t i = START_OFFSET; i < END_OFFSET; i += 8) {
		uint64_t val = hash_64(i, 64);

		for (unsigned long j = 0; j < 8; j++) {
			printf("%02X ", (val >> (j*8) & 0xff));
		}

		if (i & 0xf)
			printf("\n");
	}
}
