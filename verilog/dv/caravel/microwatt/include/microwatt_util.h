#ifndef __MICROWATT_UTIL_H
#define __MICROWATT_UTIL_H

#include "io.h"

#define LA_REG			0xc8020000

#define LA_MICROWATT_START	0xbadc0ffe
#define LA_MICROWATT_SUCCESS	0x0ddf00d5
#define LA_MICROWATT_FAILURE 	0x71077345

#define GPIO1_MGMT_ENGINE_START	0x00010000
#define GPIO1_MICROWATT_START	0x00020000
#define GPIO1_SUCCESS		0x00030000
#define GPIO1_FAILURE		0x00000000

#ifdef __powerpc64__
static inline void microwatt_alive(void)
{
	writel(LA_MICROWATT_START, LA_REG);
}

static inline void microwatt_success(void)
{
	writel(LA_MICROWATT_SUCCESS, LA_REG);
}

static inline void microwatt_failure(void)
{
	writel(LA_MICROWATT_FAILURE, LA_REG);
}
#endif

#endif
