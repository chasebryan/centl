CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra
LDFLAGS ?=
LDLIBS ?= -lm
PYTHON ?= python3

.PHONY: all clean check

all: cbx cbx-inverse cbx-forward-i cbx-shift-i cbx-profile-i cbx-standalone-i
	mkdir -p state observations letters

cbx: src/cbx_runtime.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_runtime.c $(LDFLAGS) $(LDLIBS)
	mkdir -p state observations letters

cbx-inverse: src/cbx_inverse.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_inverse.c $(LDFLAGS) $(LDLIBS)

cbx-forward-i: src/cbx_forward_i.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_forward_i.c $(LDFLAGS) $(LDLIBS)

cbx-shift-i: src/cbx_shift_i.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_shift_i.c $(LDFLAGS) $(LDLIBS)

cbx-profile-i: src/cbx_profile_i.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_profile_i.c $(LDFLAGS) $(LDLIBS)

cbx-standalone-i: src/cbx_standalone_i.c src/cbx.c
	$(CC) $(CFLAGS) -o $@ src/cbx_standalone_i.c $(LDFLAGS) $(LDLIBS)

check: cbx cbx-inverse cbx-forward-i cbx-shift-i cbx-profile-i cbx-standalone-i
	./cbx self-test
	./cbx probe 1009
	./cbx probe 2521
	./cbx probe 9658489
	./cbx-inverse --hi 100000 --i-max 80 --segment 25000 --verify
	./cbx-forward-i --hi 100000 --i-max 80
	./cbx-shift-i --hi 100000 --i-max 80 --segment 25000 --verify
	./cbx-profile-i --hi 100000 --i-max 80 --segment 25000 > /tmp/cbx-check-profile.json
	./cbx-standalone-i --hi 20000 --i-max 40 --segment 10000 > /tmp/cbx-check-standalone.json
	$(PYTHON) -m py_compile analyze.py analyze_layers.py analyze_profile.py analyze_standalone.py bench_i.py plan_hybrid.py
	./cbx-inverse --hi 20000 --i-max 40 --segment 10000 --layers /tmp/cbx-check-layers.tsv >/dev/null
	$(PYTHON) analyze_layers.py /tmp/cbx-check-layers.tsv --json >/dev/null
	$(PYTHON) analyze_profile.py /tmp/cbx-check-profile.json --json > /tmp/cbx-check-profile-analysis.json
	$(PYTHON) analyze_standalone.py /tmp/cbx-check-standalone.json --json >/dev/null
	$(PYTHON) plan_hybrid.py /tmp/cbx-check-profile-analysis.json --json >/dev/null
	$(PYTHON) plan_hybrid.py /tmp/cbx-check-profile-analysis.json --c-retention 0.10 --json >/dev/null
	$(PYTHON) bench_i.py --hi 20000 --i-max 40 --repeat 1 --no-verify --json >/dev/null
	rm -f /tmp/cbx-check-layers.tsv /tmp/cbx-check-profile.json /tmp/cbx-check-profile-analysis.json /tmp/cbx-check-standalone.json
	rm -f state/check.seed observations/check.jsonl
	./cbx go --run check --step 1000 --iterations 2 --sweep-only
	test "$$(sed -n 's/^sweep=//p' state/check.seed)" = "2000"
	rm -f state/check.seed observations/check.jsonl

clean:
	rm -f cbx cbx-inverse cbx-forward-i cbx-shift-i cbx-profile-i cbx-standalone-i
	rm -rf __pycache__
