// Per produrre la IR che sarà l'input del nostro ottimizzatore:
//
// 	clang -O2 -S -emit-llvm -c FILENAME.c -o FILENAME.ll
//
// Per lanciare il nostro passo di analisi come unico passo dell'ottimizzatore:
//
//	opt -load-pass-plugin=lib/libTestPass.so -passes=test-pass -disable-output FILENAME.ll
//
// Il flag `-disable-output` evita la generazione di bytecode in output (non ci serve,
// il nostro passo non trasforma la IR e non genera output)
//

int g;

// Nome della funzione: g_incr
// Numero di Argomenti: 1
// Numero di chiamate: 0
// Numero di BB: 1
// Numero di Istruzioni: 4
int g_incr(int c) {
  g += c;
  return g;
}

// Nome della funzione: loop
// Numero di Argomenti: 3
// Numero di chiamate: 0
// Numero di BB: 3
// Numero di Istruzioni: 10
int loop(int a, int b, int c) {
  int i, ret = 0;

  for (i = a; i < b; i++) {
    g_incr(c);
  }

  return ret + g;
}
