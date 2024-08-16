#ifndef COMMON_H
#define COMMON_H

typedef struct {
    int (*func)(void);
    char *string;
} Statement;

#endif // COMMON_H