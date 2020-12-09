#include <stdint.h>

#include "microwatt_util.h"
#include "console.h"
#include "hash.h"

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
	console_init();
	microwatt_alive();

	// gcc will optimise away a NULL pointer access, so start at offset 1
	for (unsigned long i = 1; i < 4096; i += 8)
		*(unsigned long *)i = hash_64(i, 64);

	for (unsigned long i = 1; i < 4096; i+=8) {
		unsigned long exp;
		unsigned long got;

		exp = hash_64(i, 64);
		got = *(unsigned long *)i;

		if (exp != got) {
			print_hex(exp);
			putchar(' ');
			print_hex(got);

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
