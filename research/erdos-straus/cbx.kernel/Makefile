CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?= -lm

.PHONY: all clean check

all: cbx
	mkdir -p state observations letters

cbx: src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx.c $(LDFLAGS)
	mkdir -p state observations letters

check: cbx
	./cbx self-test
	./cbx probe 1009
	./cbx probe 2521
	./cbx probe 9658489

clean:
	rm -f cbx
