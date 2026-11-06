#include "contract.h"

#include <stdio.h>
#include <string.h>

/* Intentional boundary defects for static review; never execute this file. */

int bad_bonjour(const char *name)
{
    char service_name[128] = {0};

    strcpy(service_name, name);
    strcat(service_name, ".local");
    consume_service_name(service_name);
    return 0;
}

int good_bonjour(const char *name)
{
    char service_name[128] = {0};
    const int length = snprintf(service_name, sizeof(service_name),
                                "%s.local", name);

    if ((length < 0) || ((size_t)length >= sizeof(service_name)))
    {
        return -1;
    }
    consume_service_name(service_name);
    return 0;
}

int bad_response(const ReviewJson *response)
{
    const ReviewJson *result = review_field(response, "result");
    const ReviewJson *clients = review_field(result, "clientList");

    return clients->kind;
}

int good_response(const ReviewJson *response)
{
    const ReviewJson *result = review_field(response, "result");
    if ((result == NULL) || (result->kind != REVIEW_OBJECT))
    {
        return -1;
    }
    const ReviewJson *clients = review_field(result, "clientList");
    if ((clients == NULL) || (clients->kind != REVIEW_ARRAY))
    {
        return -1;
    }
    return 0;
}

int bad_state_line(const char *line)
{
    char package[16] = {0};
    char section[16] = {0};
    char state[6] = {0};

    sscanf(line, "%[^.].%[^.=]=%5s", package, section, state);
    return 0;
}

int good_state_line(const char *line)
{
    char package[16] = {0};
    char section[16] = {0};
    char state[6] = {0};

    if (sscanf(line, "%15[^.].%15[^.=]=%5s", package, section, state) != 3)
    {
        return -1;
    }
    if ((strcmp(package, "fing") != 0) || (strlen(section) != 12)
        || (strcmp(state, "state") != 0))
    {
        return -1;
    }
    return 0;
}

#ifdef LEGACY_INPUT_PATH
int legacy_name(const char *name)
{
    char service_name[8] = {0};

    strcpy(service_name, name);
    consume_service_name(service_name);
    return 0;
}
#endif
