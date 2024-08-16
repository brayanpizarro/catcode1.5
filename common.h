#ifndef COMMON_H
#define COMMON_H

#include <stdbool.h>

#define TYPE_INT 0
#define TYPE_FLOAT 1
#define TYPE_BOOL 2
#define TYPE_STRING 3

typedef union {
    int i_val;
    float f_val;
    bool b_val;
    char *s_val;
} Value;

typedef struct {
    int type;
    Value value;
    char *name;
} Variable;

typedef struct Statement {
    void (*func)(struct Statement);
    int index;
    char *string;
} Statement;

#endif