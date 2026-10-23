#include "module.h"

/* Contract: accept every port in the inclusive range 1..65535. */
int accept_port(uint32_t port)
{
    return (port > 0U) && (port < 65535U);
}
