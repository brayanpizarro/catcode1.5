%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"

int yylex(void);
void yyerror(const char *s);
extern FILE *yyin;

#define MAX_VARS 100
Variable vars[MAX_VARS];
int var_count = 0;

int get_var(char *name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            return i;
        }
    }
    if (var_count < MAX_VARS) {
        vars[var_count].name = strdup(name);
        return var_count++;
    }
    yyerror("Demasiadas variables");
    return -1;
}

void print_var(struct Statement s) {
    int index = s.index;
    if (index < 0 || index >= var_count) {
        return;
    }
    switch(vars[index].type) {
        case TYPE_INT:
            printf("%d\n", vars[index].value.i_val);
            break;
        case TYPE_FLOAT:
            printf("%.6f\n", vars[index].value.f_val);
            break;
        case TYPE_BOOL:
            printf("%s\n", vars[index].value.b_val ? "true" : "false");
            break;
        case TYPE_STRING:
            printf("%s\n", vars[index].value.s_val);
            break;
        default:
            break;
    }
}

void print_string(struct Statement s) {
    printf("%s\n", s.string);
    free(s.string);
}

struct Statement make_empty_stmt() {
    struct Statement s = {NULL, 0, NULL};
    return s;
}

struct Statement make_print_stmt(int index) {
    struct Statement s;
    s.func = print_var;
    s.index = index;
    return s;
}

struct Statement make_print_string_stmt(char *str) {
    struct Statement s;
    s.func = print_string;
    s.string = strdup(str);
    return s;
}

void execute_stmt(struct Statement stmt) {
    if (stmt.func) {
        stmt.func(stmt);
    }
}

int is_float_int(int value) {
    return 0;
}

int is_float_float(float value) {
    return 1;
}

float to_float_int(int value) {
    return (float)value;
}

float to_float_float(float value) {
    return value;
}

%}

%union {
    int ival;
    float fval;
    char *id;
    struct Statement stmt;
}

%token <ival> INT_VAL BOOL_VAL
%token <fval> FLOAT_VAL
%token <id> IDENTIFIER STRING
%token PLUS MINUS TIMES DIVIDE
%token LPAREN RPAREN
%token LT GT LE GE
%token AND OR
%token IF ELSE PRINT
%token ASSIGN
%token INT_TYPE FLOAT_TYPE BOOL_TYPE

%type <ival> expr
%type <stmt> statement
%type <stmt> statement_list
%type <stmt> block
%type <stmt> if_statement

%left OR
%left AND
%left LT GT LE GE
%left PLUS MINUS
%left TIMES DIVIDE
%right UMINUS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

program:
    statement_list { 
        execute_stmt($1);
    }
    ;

statement_list:
    statement { 
        $$ = $1; 
    }
    | statement_list statement { 
        execute_stmt($1);
        $$ = $2;
    }
    ;

statement:
    INT_TYPE IDENTIFIER ASSIGN expr ';' {
        int index = get_var($2);
        vars[index].type = TYPE_INT;
        vars[index].value.i_val = $4;
        free($2);
        $$ = make_empty_stmt();
    }
    | FLOAT_TYPE IDENTIFIER ASSIGN expr ';' {
        int index = get_var($2);
        vars[index].type = TYPE_FLOAT;
        vars[index].value.f_val = $4;
        free($2);
        $$ = make_empty_stmt();
    }
    | BOOL_TYPE IDENTIFIER ASSIGN expr ';' {
        int index = get_var($2);
        vars[index].type = TYPE_BOOL;
        vars[index].value.b_val = $4 != 0;
        free($2);
        $$ = make_empty_stmt();
    }
    | IDENTIFIER ASSIGN expr ';' {
        int index = get_var($1);
        switch(vars[index].type) {
            case TYPE_INT:
                vars[index].value.i_val = $3;
                break;
            case TYPE_FLOAT:
                vars[index].value.f_val = $3;
                break;
            case TYPE_BOOL:
                vars[index].value.b_val = $3 != 0;
                break;
        }
        free($1);
        $$ = make_empty_stmt();
    }
    | if_statement { 
        $$ = $1; 
    }
    | PRINT LPAREN IDENTIFIER RPAREN ';' { 
        int index = get_var($3);
        $$ = make_print_stmt(index); 
        free($3); 
    }
    | PRINT LPAREN STRING RPAREN ';' { 
        $$ = make_print_string_stmt($3); 
        free($3); 
    }
    | block { 
        $$ = $1; 
    }
    ;

block:
    '{' statement_list '}' { $$ = $2; }
    ;

if_statement:
    IF LPAREN expr RPAREN statement %prec LOWER_THAN_ELSE
    {
        if ($3) {
            $$ = $5;
        } else {
            $$ = make_empty_stmt();
        }
    }
    | IF LPAREN expr RPAREN statement ELSE statement
    {
        if ($3) {
            $$ = $5;
        } else {
            $$ = $7;
        }
    }
    ;
 
expr:
    INT_VAL { 
        $$ = $1; 
    }
    | FLOAT_VAL { 
        $$ = $1; 
    }
    | BOOL_VAL { 
        $$ = $1; 
    }
    | IDENTIFIER { 
        int index = get_var($1);
        if (index < 0 || index >= var_count) {
            yyerror("Índice de variable inválido");
            $$ = 0;
        } else {
            switch (vars[index].type) {
                case TYPE_INT:
                    $$ = vars[index].value.i_val;
                    break;
                case TYPE_FLOAT:
                    $$ = vars[index].value.f_val;
                    break;
                case TYPE_BOOL:
                    $$ = vars[index].value.b_val ? 1 : 0;
                    break;
                default:
                    yyerror("Tipo de variable desconocido");
                    $$ = 0;
            }
        }
        free($1);
    }
    | expr PLUS expr { 
        if (is_float_float($1) || is_float_float($3))
            $$ = to_float_float($1) + to_float_float($3);
        else
            $$ = $1 + $3;
    }
    | expr MINUS expr { 
        $$ = $1 - $3; 
    }
    | expr TIMES expr { 
        $$ = $1 * $3; 
    }
    | expr DIVIDE expr { 
        $$ = $1 / $3; 
    }
    | expr LT expr { 
        $$ = ($1 < $3) ? 1 : 0; 
    }
    | expr GT expr { 
        $$ = ($1 > $3) ? 1 : 0; 
    }
    | expr LE expr { 
        $$ = ($1 <= $3) ? 1 : 0; 
    }
    | expr GE expr { 
        $$ = ($1 >= $3) ? 1 : 0; 
    }
    | expr AND expr { 
        $$ = ($1 && $3) ? 1 : 0; 
    }
    | expr OR expr { 
        $$ = ($1 || $3) ? 1 : 0; 
    }
    | LPAREN expr RPAREN { 
        $$ = $2; 
    }
    | MINUS expr %prec UMINUS { 
        $$ = -$2; 
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s archivo_de_entrada\n", argv[0]);
        return 1;
    }

    FILE *input_file = fopen(argv[1], "r");
    if (!input_file) {
        fprintf(stderr, "No se pudo abrir el archivo %s\n", argv[1]);
        return 1;
    }

    yyin = input_file;
    yyparse();
    fclose(input_file);
    return 0;
}
