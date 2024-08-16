%{
#include "common.h"
#include "parser.tab.h"
#include <string.h>
%}

%%

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return TIMES; }
"/"         { return DIVIDE; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"<"         { return LT; }
">"         { return GT; }
"<="        { return LE; }
">="        { return GE; }
"and"       { return AND; }
"or"        { return OR; }
"GATITO"    { return IF; }
"GATOTE"    { return ELSE; }
"PRINTCAT"  { return PRINT; }
"="         { return ASSIGN; }
"{"         { return '{'; }
"}"         { return '}'; }
";"         { return ';'; }
"MIAU"      { return INT_TYPE; }
"MIAUMIAU"  { return FLOAT_TYPE; }
"GARRITA"   { return BOOL_TYPE; }
"true"      { yylval.ival = 1; return BOOL_VAL; }
"false"     { yylval.ival = 0; return BOOL_VAL; }
[0-9]+      { yylval.ival = atoi(yytext); return INT_VAL; }
[0-9]+\.[0-9]+ { yylval.fval = atof(yytext); return FLOAT_VAL; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.id = strdup(yytext); return IDENTIFIER; }
\"[^\"]*\"  { yylval.id = strdup(yytext); return STRING; }
[ \t\n]     { /* Ignorar espacios en blanco */ }
.           { printf("Carácter no reconocido: %s\n", yytext); }

%%

int yywrap(void) {
    return 1;
}