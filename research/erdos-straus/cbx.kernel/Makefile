CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=
LDLIBS ?= -lm
PYTHON ?= python3

.PHONY: all clean check

all: cbx cbx-inverse cbx-forward-i
	mkdir -p state observations letters

cbx: src/cbx_runtime.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_runtime.c $(LDFLAGS) $(LDLIBS)
	mkdir -p state observations letters

cbx-inverse: src/cbx_inverse.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_inverse.c $(LDFLAGS) $(LDLIBS)

cbx-forward-i: src/cbx_forward_i.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_forward_i.c $(LDFLAGS) $(LDLIBS)

check: cbx cbx-inverse cbx-forward-i
	./cbx self-test
	./cbx probe 1009
	./cbx probe 2521
	./cbx probe 9658489
	./cbx-inverse --hi 100000 --i-max 80 --segment 25000 --verify
	./cbx-forward-i --hi 100000 --i-max 80
	$(PYTHON) -m py_compile analyze.py bench_i.py
	$(PYTHON) bench_i.py --hi 20000 --i-max 40 --repeat 1 --no-verify --json >/dev/null
	rm -f state/check.seed observations/check.jsonl
	./cbx go --run check --step 1000 --iterations 2 --sweep-only
	test "$$(sed -n 's/^sweep=//p' state/check.seed)" = "2000"
	rm -f state/check.seed observations/check.jsonl

clean:
	rm -f cbx cbx-inverse cbx-forward-i
	rm -rf __pycache__
