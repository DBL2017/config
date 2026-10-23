#include "module.h"

int generation_is_current(uint32_t expected, uint32_t observed)
{
    return expected == observed;
}
