#include "stdint.h"

typedef struct
{
    uint64_t low;
    int64_t high;
} I128;

typedef struct
{
    uint64_t low[2];
    int64_t high;
} I192;

uint64_t freq(uint64_t count);

I128 addArrayI64_simple(int64_t* values, uint64_t length);
I128 addArrayI64_aligned(int64_t* values, uint64_t length);
I128 addArrayI64_unroll(int64_t* values, uint64_t length);
I128 addArrayI64_unrollmore(int64_t* values, uint64_t length);

I192 dotpArrayI64_simple(int64_t* values1, int64_t* values2, uint64_t length);
I192 dotpArrayI64_unroll(int64_t* values1, int64_t* values2, uint64_t length);
I192 dotpArrayI64_chain(int64_t* values1, int64_t* values2, uint64_t length);
