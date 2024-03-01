# Introduzione
Semplificazioni ancora in corso:
- Bison non genera l'AST
- generare un codice intermedio

Funzionamento del compilatore completo: `front-end | LLVM IR | back-end | codice macchina`
Al momento vogliamo che il front-end generi solamente l'AST. Questo dipende dal codice intermedio.
## Architettura
Come strutturare il software? Un'architettura possibile potrebbe essere scanner + parser (con il suo driver). Una soluzione modulare più comprensibile, manutenibile e debuggabile è:
- *scanner* -> file `.ll` compilato da Lex
- *parser* -> generato da Bison (`.yy`), genera l'AST (attenzione all'allocazione di memoria)
- *client* -> un main program che legga il file sorgente e interpreti le opzioni da riga di comando
- *driver* -> classe condivisa tra parser, scanner e driver per la gestione di informazioni; consente di evitare variabili globali. Contesto di esecuzione (ambiente) che contiene dati comuni.

### Client
Accetta due opzioni:
- `-s` scanning trace
- `-p` parsing trace

Si esaminano opzioni e argomenti:
```C++
driver drv();
for (int i=1; i<argc; i++) {
	if (argv[i] == "-p"s) drv.trace_parsing = true;
	else if (argv[i] == "-s"s) drv.trace_scanning = true;
	else if (drv.parse(argv[i])) {
		drv.root->visit();  // esegue una visita all'AST (debugging)
		std::cout << std::endl;
	}
	else return 1;
}
return 0;
```

### Driver
```C++
struct driver {
	driver();
	void scan_begin();  // controllo esistenza e diritti, apertura file
	void scan_end();  // chiusura il file
	bool parse(const std::string &f);  // riferimento a str, rappr nome del file
	
	RootAST *root;  // radice dell'AST
	std::string file;  // scan_begin accederà la variabile
	yy::location location;  // alimentata dallo scanner, utilizzata dal parser

	bool trace_parsing;  // usata dal parser
	bool trace_scanning;  // usata dallo scanner
}
```

#Nota che solo il parser "vede" il file sorgente `scan_begin` e `scan_end` saranno implementati nello scanner.

`parse` può essere implementata direttamente nel modulo driver.

La definizione dei metodi si troverà in moduli diversi.

Si decide di implementare construtture e `parse` in `Driver`:
```C++
driver::driver() : trace_parsing(false), trace_scanning(false) {}

driver::parse(const std::string &f) {
	#Completa 
	parser.parse(*this)  // il prototipo
}
```

#Attenzione alla dipendenza ciclica tra driver e parser. Il parser necessita del driver perché contiene l'ambiente. Il driver ha bisogno del parser per la definizione di `yy::location`; la seconda ragione è che il tipo di ritorno del lexer è definito dal parser.

# Verso l'AST di Kaleidoscope
#Vedi definizione della grammatica LR

Possiamo usare la grammatica ambigua. Disambigua Bison.

## Rappresentazione dell'AST
Si introducono 9 classi:
- Root
	- Seq
	- Prototype
	- Function
	- Expr
		- Number
		- Variable
		- Binary
		- Call
Perché 4 sottoclassi di Expr? per non sovra-dimensionare la classe che rappresenta l'espressione. Sono 4 classi specializzate.

Ad esempio: `f(x + 3)` è parsato come chiamata di funzione il cui figlio sx è `f` e il figlio dx un'espressione binaria che contiene una variabile e un numero.

### Common
```C++
using lexval = std::variant<double, std::string>;  // valore lessicale (literal o nome variabile)
const lexval NONE = 0.0;
```
### RootAST
```C++
struct RootAST {
	virtual ~RootAST() = default;
	virtual RootAST* left() {return nullptr;}
	virtual RootAST* right() {return nullptr;}
	virtual lexval getLexVal() {return NONE;}
	virtual void visit() = 0;
};
```

### NumberExprAST 
```C++
class NumberExprAST : public ExprAST {
	private:
		double val;
	public:
		NumberExprAST(double val) : val(val) {}
		void visit() override { std::cout << val << " "; }
		lexval getLexVal() const { return val; }
}
```

### VariableExprAST
```C++
class VariableExprAST : public ExprAST {
	private:
		std::string name;
	public:
		VariableExprAST(const std::string &name) : val(name) {}
		void visit() override { std::cout << name << " "; }
		lexval getLexVal() const { return val; }
}
```

### BinaryExprAST
```C++
class BinaryExprAST : public ExprAST {
	private:
		char op;
		ExprAST *lhs;
		ExprAST *rhs;
	public:
		BinaryExprAST(char op, ExprAST *lhs, ExprAST rhs *rhs) :
			op(op), lhs(lhs), rhs(rhs) {}
		ExprAST *right() { return rhs; }
		ExprAST *left() { return lhs; }
		void visit() override {
			std::cout << "(" << op << " ";
			if (lhs != nullptr) lhs->visit();
			if (rhs != nullptr) rhs->visit();
			std::cout << ")";
		}
}
```

### CallExprAST
```C++
class CallExprAST {
	private:
		std::string callee;
		std::vector<ExprAST*> args;
	public:
		CallExprAST(std::string callee, std::vector<ExprAST*> args) :
			callee(callee), args(std::move(args)) {}
		lexval getLexVal() const { return callee; }
		void visit() override {
			std::cout << callee << "(";
			for (const auto *arg : args) {
				arg->visit();
			}
			std::cout << ")";
		}
}
```

### SeqAST
#Completa

#Nota tra più punti e virgola attaccati c'è un comando vuoto. Tieni conto nella visita.

### PrototypeAST
#Nota abbiamo un solo tipo di dato, quindi bastano nomi e numero di argomenti (parametri formali).

```C++
class PrototypeAST : public RootAST {
	private:
		std::string name;
		std::vector<std::string> args;
	public:
		PrototypeAST(std::string name, std::vector<std::string> args) :
			name(name), args(std::move(args)) {}
		lexval getLexVal() const { return name; }
		const auto& getArgs() { return args; }
		void visit() override {
			std::cout << "extern " << name << "( ";
			for (const auto &arg : args) {
				std::cout << arg << " ";
			}
			std::cout << ")";
		}
		int argsize() { return args.size(); }
}
```


### FunctionAST
#Completa 

```C++
FunctionAST(BodyType *t) : external(t == nullptr) {}
```

## Parser YY
La composizione di espressioni avrà la seguente forma:
```Bison
exp :
	exp "+" exp { $$ = new BinaryExprAST('+', $1, $2); }
	| exp "-" exp { $$ = new BinaryExprAST('-', $1, $2); }
	| exp "*" exp { $$ = new BinaryExprAST('*', $1, $2); }
	| exp "/" exp { $$ = new BinaryExprAST('/', $1, $2); }
```


Assioma:
```Bison
startsymb:
	program { drv.root = $1; }
```

idseq:
```Bison
#Completa 
```

#Nota il parser è bottom-up.


#Nota in algoritmica si chiama *foresta* la struttura dati composta da più alberi

