CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=
PYTHON ?= python3

.PHONY: all clean check escape

all: cbis cbis-audit
	mkdir -p letters state evidence

cbis: src/cbis.c
	$(CC) $(CFLAGS) -o $@ src/cbis.c $(LDFLAGS)
	mkdir -p letters state evidence

cbis-audit: src/cbis_audit.c src/cbis.c
	$(CC) $(CFLAGS) -o $@ src/cbis_audit.c $(LDFLAGS)

escape:
	$(PYTHON) cbis_escape.py --help >/dev/null

check: cbis cbis-audit
	./cbis self-test
	./cbis solve 1009
	./cbis solve 2521
	./cbis solve 9658489
	./cbis-audit 9658489 --k-max 400 | grep -q '"ab_unseen_through_K":true'
	./cbis-audit 9658489 --k-max 3000 | grep -q '"k":2622'
	$(PYTHON) tests/test_model_escape.py
	$(PYTHON) cbis_escape.py 9658489 --ab-k 400 --x-count 8 | grep -q 'GENERAL_ES_WITNESS_AB_UNSEEN_THROUGH_K'
	$(PYTHON) cbis_escape.py 9658489 --ab-k 3000 --x-count 8 | grep -q 'AB_EXPLAINED_THROUGH_K'

clean:
	rm -f cbis cbis-audit
