#include "module.h"

/* SECURITY-TODO: intentional race fixture; do not ship or execute. */
static uint32_t g_generation = 0U;

void refresh_generation(uint32_t generation)
{
    g_generation = normalize_generation(generation);
}

uint32_t read_generation(void)
{
    return g_generation;
}
