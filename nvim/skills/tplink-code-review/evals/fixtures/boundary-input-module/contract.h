#ifndef BOUNDARY_INPUT_CONTRACT_H
#define BOUNDARY_INPUT_CONTRACT_H

/* Deliberately defective, static-review-only fixture. Never link or execute. */

typedef enum
{
    REVIEW_OBJECT,
    REVIEW_ARRAY
} ReviewKind;

typedef struct REVIEW_JSON_STRU
{
    ReviewKind kind;
} ReviewJson;

/*
 * Names are terminated and may contain 0..127 printable characters.
 * State lines are terminated and may contain up to 511 arbitrary characters.
 * Responses are parsed objects; required fields may be absent or mistyped.
 * review_field returns a borrowed pointer, or NULL for absent fields/objects.
 */
const ReviewJson *review_field(const ReviewJson *object, const char *name);
void consume_service_name(const char *name);

#endif
