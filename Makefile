FSTAR ?= fstar.exe
OPAM_SWITCH ?= centl
DUNE ?= $(shell \
	if command -v dune >/dev/null 2>&1; then command -v dune; \
	elif command -v opam >/dev/null 2>&1; then \
		printf '%s' 'opam exec --switch=$(OPAM_SWITCH) -- dune'; \
	else printf '%s' dune; fi)
FSTAR_GCD := src/fstar/Centl.Gcd.fst
FSTAR_CORE := src/fstar/Centl.Core.fst
FSTAR_CACHE := _build/fstar
GENERATED := src/generated/Centl_Core.ml
FSTAR_COMMON := --include src/fstar --cache_dir $(FSTAR_CACHE) \
	--hint_dir $(FSTAR_CACHE) --split_queries always --z3rlimit 2

.PHONY: all verify extract build test clean

all: build

verify:
	mkdir -p $(FSTAR_CACHE)
	$(FSTAR) $(FSTAR_COMMON) \
		--cache_checked_modules --report_assumes error $(FSTAR_GCD)
	$(FSTAR) $(FSTAR_COMMON) \
		--cache_checked_modules --report_assumes error $(FSTAR_CORE)

extract: verify
	mkdir -p src/generated
	$(FSTAR) $(FSTAR_COMMON) \
		--codegen OCaml --extract Centl.Gcd \
		--odir src/generated $(FSTAR_GCD)
	$(FSTAR) $(FSTAR_COMMON) \
		--codegen OCaml --extract Centl.Core \
		--odir src/generated $(FSTAR_CORE)
	test -f $(GENERATED)

build: extract
	$(DUNE) build

test: extract
	$(DUNE) runtest

clean:
	$(DUNE) clean
	rm -f src/generated/*.ml src/generated/*.mli
