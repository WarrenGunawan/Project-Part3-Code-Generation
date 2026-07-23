CC = g++
CFLAGS = -g -O0 -std=c++11

SRC  = lib.cpp                        # list of C++ source files
OBJS = $(patsubst %.cpp, %.o, $(SRC)) # list of object files


miniL: miniL-lex.o miniL-parser.o $(OBJS)
	$(CC) $^ -o $@

.PHONY: test clean

test: miniL
	bash tests/run_tests.sh

%.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@

miniL-lex.cpp: mini_l.lex miniL-parser.cpp
	flex -o $@ $< 

miniL-parser.cpp: mini_l.y
	bison -d -v -o $@ $<

clean:
	rm -f *.o miniL-lex.cpp miniL-parser.cpp miniL-parser.hpp stack.hh *.output *.dot *.vcg miniL
