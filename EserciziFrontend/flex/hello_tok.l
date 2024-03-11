%{
#include <iostream>
using namespace std;
%}

DIG [0-9]
DIG1 [1-9]

%option noyywrap C++

%%
"+" { cout << "operatore" << yytext[0] << endl; }
"-" { cout << "operatore" << yytext[0] << endl; }
{DIG}{DIG}* { cout << "numero " << yytext << endl; }

%%
int main(int argc, char **argv) {
	FlexLexer* lexer = new yyFlexLexer;
	lexer->yylex();
	return 0;
}
