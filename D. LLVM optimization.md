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
- inlining
- LICM - Loop Independent Code Motion - of `g` increment
- DCE - Dead Code Elimination - of the loop
- GVN - Global Value Numbering

https://en.wikipedia.org/wiki/Value_numbering