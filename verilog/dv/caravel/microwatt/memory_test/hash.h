#ifndef __HASH_H
#define __HASH_H

#define GOLDEN_RATIO_64 0x61C8864680B583EBull

static inline uint64_t hash_64(uint64_t val, uint32_t bits)
{
	return val * GOLDEN_RATIO_64 >> (64 - bits);
}
#endif
