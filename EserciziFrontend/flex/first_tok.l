%{
#include <iostream>
using namespace std;
%}

DIG [0-9]
DIG1 [1-9]
PAR [\(\)\[\]\{\}]
IDCHAR [A-Z_a-z]
SEP [ \t\n]

%option noyywrap C++

%%
"+" { cout << "operatore " << yytext[0] << endl; }
"-" { cout << "operatore " << yytext[0] << endl; }
"=" { cout << "operatore " << yytext[0] << endl; }
{PAR} { cout << "parentesi " << yytext[0] << endl; }
"for" { cout << "keyword " << yytext << endl; }
{DIG1}{DIG}* { cout << "numero " << yytext << endl; }
{IDCHAR}({IDCHAR}|{DIG})* { cout << "identificatore " << yytext << endl; }
{SEP} {}
. { cout << "token sconosciuto" << endl; }

%%
int main(int argc, char **argv) {
	FlexLexer* lexer = new yyFlexLexer;
	lexer->yylex();
	return 0;
}
