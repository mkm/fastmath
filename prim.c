#include "prim.h"

uint64_t adc_u64(uint64_t a, uint64_t b, uint64_t cin, uint64_t* restrict cout)
{
    return a + b; // return __builtin_addcl(a, b, cin, cout);
}
