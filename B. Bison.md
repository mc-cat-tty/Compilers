Nuova alternativa a YACC.
# Homemade parser
La tabella di controllo è molto semplice, esegue l'algoritmo in loop pop, check or sobstitute.
*Solamente per il riconoscimento* il codice dell'algoritmo di controllo è sempre lo stesso.

Si può generare la tabella in due passaggi:
- Elenco dei first and follow
- Tabella di parsing

## Struttura della grammatica
```
LHS1 : RHS
LHS1 : RHS
LHS1 : 'RHS'
LHS2 : RHS
LHS2 : RHS
```

Eliminiamo la pipe; i terminali sono racchiusi tra apici; l'assioma è l'ultima riga; la freccia è sostituita da due punti; epsilon è sostituito da *EPS*

La grammatica viene convertita in una tabella di parsing.

## Rappresentazione della grammatica
La grammatica viene quindi convertita, da uno script in python, in un file header che importerà il codice "checker".

Si può economizzare non inserendo il terminale di destra nella tabella di parsing, è implicitamente definito dalla riga su cui ci si trova.

#Approfondimento 

# Introduzione a Bison
>È un parser nello stesso modo in cui Lex è un tokenizzatore. Gli si da in pasto una grammatica e compila in codice C++.

Bison integra un parser LR -> opera per riduzioni successive.

Cosa dargli in pasto?
- grammatica
- callback da eseguire quando una riduzione viene eseguita

Bison è la version moderna della utility YACC - Yet Another Compiler Compiler (produttore di compilatori).

## Utilizzo
Come si integra? agisce su un flusso di token comodamente generati da Lex o da una subroutine fatta "a mano". Bisogna definire le interazioni.

Si prepara un file con estensione `y` o `yy` (per indicare che genera codice C++) contenente:
1. nomi dei token della grammatica
2. produzioni della grammatica
3. codice da eseguire ad ogni riduzione

Interazione lexer-parser:
- i nomi sono condivisi tra parser e lexer -> include di un file header comune
- flusso dei token da Flex a Bison
- condivisione delle informazioni mostrate in caso di errore. Solo il lexer ha accesso al file sorgente -> conosce riga e colonna dove è avvenuto l'errore

## Direttiva token
Direttiva `%token`: i nomi dei token sono definiti mediante questa direttiva
#Nota token type e token name sono la stessa cosa. Si preferisce la seconda dicitura, in quanto più esplicativa.

A seconda del tipo un token può essere caratterizzato anche da un **valore** detto **semantic** o **lexical value**.

`%token` può assumere forme diverse:
- `%token PLUS "+"` - PLUS è il nome del token da ritornare quando il più viene trovato
- `%token<float> NUMBER "number"` - NUMBER è il nome del token che il lexer ritorna, come prima. *number* è il simbolo terminale.


Bison genera l'header file che Lex dovrà includere. È il parser che comanda.

## Flusso da scanner a parser
### Parametri
Per ora abbiamo usato Lex nel seguente modo:
```C++
FlexLexer *lexer = new yyFlexLexer();  // Si istanzia un tipo derivato
lexer->yylex();  // si invoca il metodo
```

Come personalizzare il comportamento di `yylex`? Voglio innanzitutto che prenda in ingresso dei parametri personalizzati
```C++
#define YY_DECL yy::parser::symbol_type yylex (myclass& myobj)
YY_DECL;
```

Si utilizza la pre-compilazione per cambiare la firma - il prototipo - della funzione di `yylex`

Un macro-processor (M4) espanderà la dichiarazione in-front-of function definition, seguita dal corpo della funzione.

### Comportamento custom
Rimane un problema: cosa fare con questo parametro? Si possono definire pezzi di codice che verranno eseguiti in momenti topici della tokenizzazione.

### Tipo di ritorno
Potrei: ritornare esplicitamente il type name e inserire il valore in una variabile globale, implementata come una union.

Nel parser è necessario usare la direttiva `%define api.token.constructor`
Per ogni token XXX definito nel file `yy` Bison genera una funzione `make_XXX`, che accetta almeno un parametro, ovvero la posizione del token.

`location` è una classe messa a disposizione da Bison; mantiene due posizioni: `begin` e `end`. Ogni posizione mantiene numero di riga e numero di colonna.

Sono implementati diversi metodi:
- `step()` fa avanzare begin fino ad end
- `columns(X)` porta avanti `end` di X colonne
- `lines(X)` manda avanti `end` di X linee

Eg per il token `PLUS`: `yy::parser::make_PLUS()`

### Esempio: interprete per calcolatrice
*Interprete* perché calcola il risultato mentre fa il parsing.

#Completa  sotto
Scanner:
```Lex
// definizioni regolari: regex con nome
id [A-Za-z][A-Za-z_0-9]*
int [0-9]+
blank [ \t]
%{
	// YY_USER_ACTION viene eseguita quando Flex riconosce un token
	// loc è un oggetto di tipo location
	// yyleng è la lunghezza del token
	#define YY_USER_ACTION loc.cloumns(yyleng);
%}
%%
%{
	// Codice eseguito ad ogni invocazione di yylex
	yy::location &loc = location;
	loc.step()
%}
{blank}+ loc.step()
[\n]+ loc.lines(yyleng); loc.step();
")" yy:parser::make_RIGHTPAR(loc);
// tutti gli altri simboli
{int} {
	errno = 0;
	long n = strtol(yytext, NULL, 10);
	// check lunghezza
	return yy::parser::make_NUMBER(n, loc);
}
```

#Attenzione gli errori lessicali sono rari, ad esempio caratteri sporchi/non riconosciuti

#Nota differenza tra coroutine e funzione. Una funzione pura ritorna un risultato deterministico. Una coroutine mantiene uno stato interno.

#Completa  sotto
Parser:
```Bison
%code {
	#include "calc.hpp"
	extern int result;  // chi usa il parser si trova in result il risultato
	extern std::map<std::string, int> variables;
	
}

%%
%start unit; // assioma iniziale aggiuntivo
unit: assignments exp { result = $2; };  // $2 corrisponde al terzo (pos 2) della produzione


%left "+" "-"  // bassa priorità
%left "*" "/"  // alta priorità
exp:
	exp "+" exp { $$ = $1 + $2 }
	| exp "-" exp { $$ = $1 + $2 }
	| exp "-" exp { $$ = $1 - $2 }
	| exp "*" exp { $$ = $1 * $2 }
	| exp "/" exp { $$ = $1 / $2 }
```

Bison è uno strumento avanzato. Riesce a trattare anche grammatiche ambigue, come questa.
Il parser è bottom-up.

#Nota la semplice grammatica sopra definita consente di fare una serie di assegnamenti nel cui RHS si trova una espressione aritmetica

>Quando si automatizza un processo, non lo si fa in modo efficiente, almeno inizialmente. Bison spreca una marea di variabili.

`$N` è una variabile che assume un valore il cui significato è legato all'espressione. Corrisponde alla posizione del simbolo non terminale di cui si vuole catturare il valore.
Il valore della riduzione è `$$`

Il tipo del valore di un identificatore è *stringa*. È per questo che si una una mappa (una qualunque DS associativa) che mantenga il valore delle variabili interne. Si accede alla struttura con l'identificatore della variabile.

Serve un programma driver che utilizzi il codice generato dal parser.