CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=

.PHONY: all clean check

all: cbis cbis-audit
	mkdir -p letters state

cbis: src/cbis.c
	$(CC) $(CFLAGS) -o $@ src/cbis.c $(LDFLAGS)
	mkdir -p letters state

cbis-audit: src/cbis_audit.c src/cbis.c
	$(CC) $(CFLAGS) -o $@ src/cbis_audit.c $(LDFLAGS)

check: cbis cbis-audit
	./cbis self-test
	./cbis solve 1009
	./cbis solve 2521
	./cbis solve 9658489
	./cbis-audit 9658489 --k-max 400
	./cbis-audit 9658489 --k-max 3000

clean:
	rm -f cbis cbis-audit
