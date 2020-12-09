#ifndef __LFSR32_H
#define __LFSR32_H

#include <stdint.h>

#define LFSR32_INIT 0x73983355

uint32_t lfsr32(uint32_t prev);

#endif
