#include <stdint.h>

#include "console.h"
#include "microwatt_util.h"

int main(void)
{
	console_init();

	microwatt_alive();

	/* Echo everything we receive back */
	while (1) {
		unsigned char c = getchar();
		putchar(c);
		if (c == 13) // if CR send LF
			putchar(10);
	}
}
