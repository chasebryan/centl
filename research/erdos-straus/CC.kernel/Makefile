CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=

.PHONY: all clean check

all: cc-kernel
	mkdir -p ledger

cc-kernel: src/cc_kernel.c
	$(CC) $(CFLAGS) -o $@ src/cc_kernel.c $(LDFLAGS)
	mkdir -p ledger

check: cc-kernel
	./cc-kernel solve 1009
	./cc-kernel solve 10369
	./cc-kernel solve 9658489
	./cc-kernel residual 20000

clean:
	rm -f cc-kernel
