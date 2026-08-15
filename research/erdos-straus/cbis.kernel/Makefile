CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=

.PHONY: all clean check

all: cbis
	mkdir -p letters state

cbis: src/cbis.c
	$(CC) $(CFLAGS) -o $@ src/cbis.c $(LDFLAGS)
	mkdir -p letters state

check: cbis
	./cbis self-test
	./cbis solve 1009
	./cbis solve 2521
	./cbis solve 9658489

clean:
	rm -f cbis
