CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=

.PHONY: all clean check

all: cbap
	mkdir -p letters state

cbap: src/cbap.c
	$(CC) $(CFLAGS) -o $@ src/cbap.c $(LDFLAGS)
	mkdir -p letters state

check: cbap
	./cbap self-test
	./cbap solve 1009
	./cbap solve 2521
	./cbap solve 9658489

clean:
	rm -f cbap
