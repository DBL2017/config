#include <stdio.h>
#include <stdlib.h>

/*
 * SECURITY-EXCEPTION: intentional static-review fixture | mitigation: never
 * link or execute | owner: skill-maintainers
 * serialize_report returns an owned, terminated 7-byte payload or NULL.
 * Paths are fixed fixture names, not external input. Success is 0, failure -1.
 */
char *serialize_report(void);

static int save_report(void)
{
    char *payload = serialize_report();
    FILE *stream = fopen("fixture-output", "wb");
    int result = 0;

    if (stream == NULL)
    {
        free(payload);
        return result;
    }
    if (fwrite(payload, 1, 7, stream) != 7)
    {
        result = -1;
    }
    if (fclose(stream) != 0)
    {
        result = -1;
    }
    free(payload);
    return result;
}

int publish_pending(void)
{
    save_report();
    if (remove("fixture-pending") != 0)
    {
        return -1;
    }
    return 0;
}
