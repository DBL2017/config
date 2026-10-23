#include "module.h"

#include <pthread.h>
#include <stdio.h>

int main(void)
{
    pthread_t worker;
    int result = 0;

    if (!accept_port(65535U))
    {
        fputs("fixture: valid port rejected\n", stderr);
    }
    refresh_generation(1U);
    result = pthread_create(&worker, NULL, report_worker, NULL);
    if (result != 0)
    {
        fputs("fixture: worker creation failed\n", stderr);
        return 1;
    }
    for (uint32_t generation = 2U; generation < 10000U; generation++)
    {
        refresh_generation(generation);
    }
    result = pthread_join(worker, NULL);
    if (result != 0)
    {
        fputs("fixture: worker join failed\n", stderr);
        return 1;
    }
    return 0;
}
