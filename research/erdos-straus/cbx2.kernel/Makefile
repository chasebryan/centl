CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=

.PHONY: all clean check

all: cbx2
	mkdir -p letters state

cbx2: src/cbx2.c
	$(CC) $(CFLAGS) -o $@ src/cbx2.c $(LDFLAGS)
	mkdir -p letters state

check: cbx2
	./cbx2 self-test
	./cbx2 solve 1009
	./cbx2 solve 2521
	./cbx2 solve 9658489
	./cbx2 verify --hi 3000 --i-max 80

clean:
	rm -f cbx2
