CC = g++
OBJ = hello_tok.o

hellotok: $(OBJ)
	$(CC) $(OBJ) -o a.out

%.cc: hello_tok.l 
	flex -+ -o hello_tok.cc hello_tok.l


%.o: hello_tok.cc
	$(CC) hello_tok.cc -c -o hello_tok.o


.PHONY: clean
clean:
	rm *.cc *.out $(OBJ)

run:
	./a.out
