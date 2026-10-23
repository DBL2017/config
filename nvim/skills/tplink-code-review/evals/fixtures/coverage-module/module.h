#ifndef COVERAGE_MODULE_H
#define COVERAGE_MODULE_H

#include <stdint.h>

/* Synthetic review fixture, not production code. */
int accept_port(uint32_t port);
void refresh_generation(uint32_t generation);
uint32_t read_generation(void);
void *report_worker(void *argument);
uint32_t normalize_generation(uint32_t generation);
int generation_is_current(uint32_t expected, uint32_t observed);

#endif
