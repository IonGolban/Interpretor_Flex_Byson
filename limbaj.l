%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
#include <string.h>


int nr_lines = 1;
int nr_word = 0;


%}

integer ([1-9][0-9]*)|0
id [a-zA-Z_][0-9a-zA-Z_]*
float (([1-9][0-9]*)|0)?\.([0-9]+)
char '.'
string \".*\"

%option noyywrap
%%  
int {nr_word++; return INT;}
float {nr_word++; return FLOAT;}
char {nr_word++; return CHAR;}
string {nr_word++; return STRING;}
bool {nr_word++;return BOOL;}

void {nr_word++;return VOID;}
main {nr_word++;return MAIN;}

structura {nr_word++; return STRUCTURA;}
"->" {nr_word++; return ACCES;}

const {nr_word++; return CONST;}

VAR: {nr_word++;return VAR;}
ARR: {nr_word++;return ARR;}
FUNCTION: {nr_word++;return FUNCTION;}
CALL: {nr_word++; return CALL;}

true {nr_word++;yylval.boolVal=1; return TRUE;}
false {nr_word++;yylval.boolVal=0; return FALSE;}

if {nr_word++;return IF;}
else {nr_word++;return ELSE;}
for {nr_word++;return FOR;}
while {nr_word++;return WHILE;}

"!=" {nr_word++; return INEQUALITY;}
"==" {nr_word++; return EQUALITY;}
"&&" {nr_word++; return AND;}
"||" {nr_word++; return OR;}
">=" {nr_word++; return GTE;}
"<=" {nr_word++; return LTE;}
"<" {nr_word++; return LT;}
">" {nr_word++; return GT;}

"=" {nr_word++; return *yytext;}
";" {nr_word++; return *yytext;}
"(" {nr_word++; return *yytext;}
")" {nr_word++; return *yytext;}
"{" {nr_word++; return *yytext;}
"}" {nr_word++; return *yytext;}
"[" {nr_word++; return *yytext;}
"]" {nr_word++; return *yytext;}
"," {nr_word++; return *yytext;}

Eval {nr_word++;return EVAL;}
TypeOf {nr_word++;return TYPEOF;}


{id} {nr_word++;yylval.varId=strdup(yytext); return ID;}
{float} {nr_word++;yylval.floatVal=atof(yytext); return FLOAT_CONST;}
{integer} {nr_word++;yylval.intVal=atoi(yytext); return INT_CONST;}
{char} {nr_word++;yylval.charVal=yytext[1]; return CHAR_CONST;}
{string} {nr_word++;yylval.strVal=strndup(yytext+1, strlen(yytext)-2); return STR_CONST;}
[ \t] ;
[\n] {nr_lines++; nr_word = 0;}
. {return yytext[0];}

%%