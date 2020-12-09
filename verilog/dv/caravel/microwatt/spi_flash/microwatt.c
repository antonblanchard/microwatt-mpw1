#include <stdint.h>

#include "microwatt_util.h"
#include "console.h"
#include "lfsr32.h"
#include "hash.h"

#define LA_OFFSET 0xc8020000

#define FLASH_BASE 0xf0000000UL

#define FLASH_OFFSET 0x2000
#define FLASH_SIZE (16L*1024*1024)

static void print_hex(unsigned long val)
{
	int i, x;

	for (i = 60; i >= 0; i -= 4) {
		x = (val >> i) & 0xf;
		if (x >= 10)
			putchar(x + 'a' - 10);
		else
			putchar(x + '0');
	}
}

int main(void)
{
	uint32_t lfsr = LFSR32_INIT;

	console_init();
	microwatt_alive();

	for (unsigned long i = 0; i < 16; i++) {
		uint32_t o;
		uint64_t exp;
		uint64_t got;

		o = lfsr % FLASH_SIZE;
		// 16B align for now
		o &= ~15UL;
		if (o < FLASH_OFFSET)
			o += FLASH_OFFSET;
		lfsr = lfsr32(lfsr);

		exp = hash_64(o, 64);

		got = *(uint64_t *)(FLASH_BASE+o);
		if (exp != got) {
			print_hex(exp);
			putchar(' ');
			print_hex(got);
			putchar('\n');
			/* Signal success to management engine */
			microwatt_failure();
			goto out;
		}
	}

	/* Signal success to management engine */
	microwatt_success();

out:
	while (1)
		/* Do Nothing */ ;
}
