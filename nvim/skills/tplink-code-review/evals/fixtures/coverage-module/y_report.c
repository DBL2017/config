#include "module.h"

#include <stdio.h>

void *report_worker(void *argument)
{
    (void)argument;
    for (uint32_t iteration = 0U; iteration < 10000U; iteration++)
    {
        const uint32_t generation = read_generation();

        if (generation_is_current(9999U, generation))
        {
            fputs("fixture: final generation observed\n", stdout);
            break;
        }
    }
    return NULL;
}
