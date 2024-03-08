Useremo LLVM17

# Build di LLVM
```bash
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install ../../src
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