%{
#include <iostream>
using namespace std;
%}

DIG [0-9]
DIG1 [1-9]
PAR [\(\)]
IDCHAR [A-Z_a-z]
SEP [ \t\n]
PUNCT [,;]
OPS [\+\-\*]
%option noyywrap C++

%%
"def" { cout << "keyword: " << yytext << endl; }
"extern" { cout << "keword: " << yytext << endl; }
{OPS} { cout << "operator: " << yytext[0] << endl; }
{PAR} { cout << "parentesi: " << yytext[0] << endl; }
{PUNCT} { cout << "punctuation: " << yytext[0] << endl; } 
{IDCHAR}({IDCHAR}|{DIG})* { cout << "identificatore: " << yytext << endl; }
{DIG}+(\.{DIG}+)? { cout << "numero: " << yytext << endl; }
{SEP} {}

. { cout << "token sconosciuto" << endl; }

%%


int main(int argc, char **argv) {
	FlexLexer* lexer = new yyFlexLexer;
	lexer->yylex();
	return 0;
}
