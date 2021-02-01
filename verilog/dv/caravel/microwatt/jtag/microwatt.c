#include <stdint.h>

#include "console.h"
#include "microwatt_util.h"

int main(void)
{
	console_init();

	microwatt_alive();

	/* Do nothing for JTAG test */
	while (1) {
	}
}
