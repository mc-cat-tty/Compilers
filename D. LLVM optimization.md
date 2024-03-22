Useremo LLVM17

# Build di LLVM
```bash
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install ../src/llvm
make -j
```

#Attenzione all'installazione locale

# Syllabus
Cosa vedremo? prima un passo di analisi con LLVM, poi un passo di trasformazione

https://llvm.org/docs/WritingAnLLVMNewPMPass.html
https://llvm.org/docs/WritingAnLLVMPass.html


# Nozioni base LLVM
## Tassonomia di un modulo
- `Module`: file scorribile con un iteratore per ottenere le funzioni.
- `Function`: lista di BasicBlocks + argomenti. Si scorrono con iteratore ottenendo i BB.
- `Basic Block`: lista di `Instruction`
- `Instruction`: opcode + operandi

Eg:
```Cpp
Module M = //...
for (auto f : M) {
	// do smth with f of type <Function>
}
```

## Downcasting
```Cpp
Instruction *i = //...
if (CallInst *call_i = dyn_cast<CallInst>(i)) {
	// Sure that call_i is an handle to a call instruction
}
```

>Un **downcasting** serve a specializzare un'`Instruction`


## Interfacce dei passi
Diverse interfacce per i passi:
- BasicBlockPass: itera sui BB
- CallGraphSCCPass: itera sui nodi del CG
- FunctionPass: itera sulle funzioni
- LoopPass: itera sui loop in ordine inverso di nesting
- ModulePass: itera sui moduli
- RegionPass: itera su una `Region`, ovvero un'aggregazione di BB con la proprietà SESE - Single Entry Single Exit

```
opt -pass1 -pass2 -pass3 x.bc -o y.bc
```

Pass manager del middle-hand. La sequenza di passi si può modificare (override) ricompilando `opt` e passando i parametri `pass`.

`opt` agisce da driver.

https://releases.llvm.org/2.6/docs/LangRef.html
# Generazione IR
```bash
clang -O2 -emit-llvm -S -c src.c -o out.ll
```

Per listare i path in cui sono cercati gli header file: `clang -v`

Per vedere le ottimizzazioni in corso `-Rpass='.*'`

Dato il sorgente:
```c
int g;

int g_incr(int c) {
	g += c;
	return g;
}

int loop(int a, int b, int c) {
	int i, ret = 0;
	for (i = a; i < b; i++) {
		g_incr(c);
	}
	return ret + g;
}
```

Il CFG con O0 diventa:
![[TestPass1BB.png]]

Nella versione ottimizzata con O2 vengono creati solamente 3 BB:
1. verifica che `i = a` sia minore di `b`. Se vero continua al blocco for. Altrimenti salta a 3.
2. viene calcolato `g += (b-a) * c`
3. utilizza un'espressione PHI per scegliere il valore di ritorno

Si notano i seguenti passi di ottimizzazione:
- inlining. **Callsite**: punto della chiamata a funzioneiu
- LICM - Loop Independent Code Motion - of `g` increment
- DCE - Dead Code Elimination - of the loop
- GVN - Global Value Numbering

https://en.wikipedia.org/wiki/Value_numbering

# Primo Passo di Analisi
Tutti i passi ereditano da **CRTP mix-in**: `PassInfoMixin<PassT>`

Ogni passo deve implementare un metodo `PreservedAnalysis run(Function &F, FunctionAnalysisManager &AM)`

Il primo parametro può essere una qualunque unità IR, non per forza una `Function`. Eg. `Module`, `BasicBlock`, `Instruction`

`PreservedAnalysis` segnala al pass manager che l'analisi in quel punto si preserva, mentre in altri punti deve essere rieseguita. Questo è utile nel caso in cui si modifichi, ad esempio, il CFG.

Dove posizionare il passo? `.../include/llvm/Transforms/Utils` per l'header e `.../lib/llvm/Transforms/Utils`

#Ricorda di creare l'header file e di modificare il `CMakeLists.txt` nella sottodirectory di `lib/`

È ora necessario registrare il passo nel *pass manager*: `FUNCTION_PASS("testpass", TestPass())` all'interno del file `.../llvm/lib/Passes/PassRegistry.def`
Aggiungiamo `#include "llvm/Transforms/Utils/TestPass.h"` a `.../lib/Passes/PassBuilder.cpp`

Ora compiliamo: `make opt && make install-opt`

Per runnare il nostro passo:
```bash
clang -O2 -emit-llvm -o -c file.c file.bc
opt -passes=testpass file.bc -o opt_file.bc
```

#Vedi docs su ottimizzazione

https://llvm.org/doxygen/classes.html

Nel caso in cui dovessimo registrare un passo che lavora al livello dei moduli, registreremo `MODULE_PASS("testpass-mod", TestPass())` all'interno del `PassRegistry`.

#Attenzione 
Nota che due passi che lavorano a granularità diverse possono essere definiti all'interno della stessa classe (sfruttando l'overloading dei metodi), ma devono essere registrati con nomi differenti nel registry.
```bash
opt -passes="testpass-module,testpass-function" loop_o0.bc
# O in alternativa
opt -p "testpass-module,testpass-function" loop_o0.bc
```

# Primo Passo di Trasformazione
>La IR in LLVM usa la forma SSA per la quale una variabile non può essere usata più di una volta.

## Dead Stores
Come rilevare *dead stores* nella *DCE* - Dead Code Elimination?
```C
main() {
	int a = 100;  // Questo statement può essere eliminato
	int a = 42;
	printf(a);
}
```

Con una rappresentazione SSA diventerebbe:
```C
main() {
	int a1 = 100;
	int a2 = 200;
	printf(a2);
}
```

`a1` non ha utilizzi. Può essere rimossa.

## User - Use - Value
Supponiamo di voler ottimizzare:
```llvm-ir
%2 = add %1, 0  ; Identità algebrica 
%3 = mul %2, 2
```

Posso rimuovere la prima istruzione a patto di aggiornare gli usi di `%2`, altrimenti programma andrebbe in crash. Devo aggiornare gli utilizzi di `%2` sostituendoli con `%1`.

Le `Instruction` LLVM ereditano da `Value` e `User`. Esiste quindi una gerarchia del tipo:
```
Value -> User -> Instruction
```

Dalla classe `Value` ereditano quasi tutte le altre classi di LLVM. Un nodo `Value` ha:
- `getType()` tipo del valore (integer, fp, etc.)
- `hasName()` verifico se il nome esiste
- `getName()` ottengo il nome

Le `Instruction` giocano il ruolo di `User` e `Usee`. Una istruzione se viene usata, è uno `Usee`; ma è anche `User` di qualche altro valore, che usa come operando.

Per scorrere gli operandi di una istruzione si usano gli iteratori `op_begin` e `op_end`.

Perchè un'istruzione è anche `Usee`? Come abbiamo visto nella prima parte del corso, nella riga di codice `%2 = add %1, 0`, `%2` è la rappresentazione dell'istruzione `add`.
In base al cast effettuato `IstrUser` o `Value`, si ottengono due rappresentazioni diverse.

Per scorrere gli utilizzatori dell'istruzione si usano gli iteratori `user_begin` e `user_end`.
