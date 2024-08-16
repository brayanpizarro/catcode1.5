%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"

int yylex(void);
void yyerror(const char *s);
extern FILE *yyin;

#define MAX_VARS 100
struct {
    char *name;
    int value;
} vars[MAX_VARS];
int var_count = 0;

int get_var(char *name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(vars[i].name, name) == 0) {
            return i;
        }
    }
    if (var_count < MAX_VARS) {
        vars[var_count].name = strdup(name);
        vars[var_count].value = 0;
        return var_count++;
    }
    yyerror("Demasiadas variables");
    return -1;
}

void print_string(char *s) {
    int len = strlen(s);
    if (len >= 2 && s[0] == '"' && s[len-1] == '"') {
        printf("%.*s\n", len-2, s+1);
    } else {
        printf("%s\n", s);
    }
}

Statement make_empty_stmt() {
    Statement s = {NULL, NULL};
    return s;
}

Statement make_print_stmt(int value) {
    Statement s;
    s.func = NULL;
    s.string = malloc(20);
    snprintf(s.string, 20, "%d", value);
    return s;
}

Statement make_print_string_stmt(char *str) {
    Statement s;
    s.func = NULL;
    s.string = strdup(str);
    return s;
}

void execute_stmt(Statement s) {
    if (s.func) {
        s.func();
    } else if (s.string) {
        print_string(s.string);
        free(s.string);
    }
}

%}

%union {
    int num;
    char *id;
    Statement stmt;
}

%token <num> NUMBER
%token <id> IDENTIFIER STRING
%token PLUS MINUS TIMES DIVIDE
%token LPAREN RPAREN
%token LT GT LE GE
%token AND OR
%token IF ELSE PRINT
%token ASSIGN

%type <num> expr
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
    statement_list { execute_stmt($1); }
    ;

statement_list:
    statement { $$ = $1; }
    | statement_list statement { 
        execute_stmt($1);
        $$ = $2;
    }
    ;

statement:
    expr ';' { $$ = make_empty_stmt(); }
    | IDENTIFIER ASSIGN expr ';' {
         vars[get_var($1)].value = $3;
         free($1);
         $$ = make_empty_stmt();
     }
    | if_statement { $$ = $1; }
    | PRINT LPAREN expr RPAREN ';' { $$ = make_print_stmt($3); }
    | PRINT LPAREN STRING RPAREN ';' { $$ = make_print_string_stmt($3); free($3); }
    | block { $$ = $1; }
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
    NUMBER { $$ = $1; }
    | IDENTIFIER { $$ = vars[get_var($1)].value; free($1); }
    | expr PLUS expr { $$ = $1 + $3; }
    | expr MINUS expr { $$ = $1 - $3; }
    | expr TIMES expr { $$ = $1 * $3; }
    | expr DIVIDE expr { $$ = $1 / $3; }
    | expr LT expr { $$ = ($1 < $3) ? 1 : 0; }
    | expr GT expr { $$ = ($1 > $3) ? 1 : 0; }
    | expr LE expr { $$ = ($1 <= $3) ? 1 : 0; }
    | expr GE expr { $$ = ($1 >= $3) ? 1 : 0; }
    | expr AND expr { $$ = ($1 && $3) ? 1 : 0; }
    | expr OR expr { $$ = ($1 || $3) ? 1 : 0; }
    | LPAREN expr RPAREN { $$ = $2; }
    | MINUS expr %prec UMINUS { $$ = -$2; }
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