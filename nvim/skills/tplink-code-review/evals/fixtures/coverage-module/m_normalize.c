#include "module.h"

uint32_t normalize_generation(uint32_t generation)
{
    return generation % 10000U;
}
