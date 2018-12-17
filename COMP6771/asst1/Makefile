SHELL = bash
CXX = g++
CXXFLAGS = -std=c++14 -Wall -Wextra -Werror -O3 -flto
LDFLAGS = -O3 -flto

.PHONY: all clean test

all: wl test
clean:
	rm -f wl *.o

wl: WordLadder.o
	$(CXX) -o $@ $+ $(LDFLAGS)
%.o: %.cpp gsl
	$(CXX) -c -o $@ $< $(CXXFLAGS)

test: test.sh wl wl_ref EnglishWords.dat EnglishWords.txt
	./test.sh sameLength 20
	./test.sh sourceIsDest 5
	./test.sh random 5
