FSTAR ?= fstar.exe
JULIA ?= julia
OPAM ?= opam
OPAM_SWITCH ?= centl
DUNE ?= $(shell \
	if command -v dune >/dev/null 2>&1; then command -v dune; \
	elif command -v opam >/dev/null 2>&1; then \
		printf '%s' 'opam exec --switch=$(OPAM_SWITCH) -- dune'; \
	else printf '%s' dune; fi)
FSTAR_GCD := src/fstar/Centl.Gcd.fst
FSTAR_CORE := src/fstar/Centl.Core.fst
FSTAR_POLY_SOUNDNESS := src/fstar/Centl.PolynomialSoundness.fst
FSTAR_POLY_HORNER := src/fstar/Centl.PolynomialHornerSoundness.fst
FSTAR_RATIONAL_RING := src/fstar/Centl.RationalRingSoundness.fst
FSTAR_CACHE := _build/fstar
GENERATED := src/generated/Centl_Gcd.ml src/generated/Centl_Core.ml
FSTAR_COMMON := --include src/fstar --cache_dir $(FSTAR_CACHE) \
	--hint_dir $(FSTAR_CACHE) --split_queries always --z3rlimit 2

.PHONY: all format format-fix fmt lint quality verify extract native-build native-test \
	adversarial-test fuzz-test metamorphic-test sanitizer-test performance-test \
	hardening-test differential-test build test release clean

all: build

format:
	$(DUNE) build @fmt

format-fix:
	$(DUNE) fmt

fmt: format

lint:
	$(DUNE) build @check
	$(OPAM) lint centl.opam
	scripts/check-toolchain-pins

quality: format lint

verify:
	mkdir -p $(FSTAR_CACHE)
	$(FSTAR) $(FSTAR_COMMON) \
		--cache_checked_modules --report_assumes error $(FSTAR_GCD)
	$(FSTAR) $(FSTAR_COMMON) \
		--cache_checked_modules --report_assumes error $(FSTAR_CORE)
	$(FSTAR) $(FSTAR_COMMON) \
		--cache_checked_modules --report_assumes error $(FSTAR_POLY_SOUNDNESS)
	$(FSTAR) $(FSTAR_COMMON) \
		--cache_checked_modules --report_assumes error $(FSTAR_POLY_HORNER)
	$(FSTAR) $(FSTAR_COMMON) \
		--cache_checked_modules --report_assumes error $(FSTAR_RATIONAL_RING)

extract: verify
	mkdir -p src/generated
	$(FSTAR) $(FSTAR_COMMON) \
		--codegen OCaml --extract Centl.Gcd \
		--odir src/generated $(FSTAR_GCD)
	$(FSTAR) $(FSTAR_COMMON) \
		--codegen OCaml --extract Centl.Core \
		--odir src/generated $(FSTAR_CORE)
	@for generated in $(GENERATED); do test -f "$$generated"; done

native-build:
	@for generated in $(GENERATED); do test -f "$$generated"; done
	$(DUNE) build

native-test:
	@for generated in $(GENERATED); do test -f "$$generated"; done
	$(DUNE) runtest

adversarial-test:
	@for generated in $(GENERATED); do test -f "$$generated"; done
	$(DUNE) exec tests/test_adversarial.exe

fuzz-test: adversarial-test
	@for generated in $(GENERATED); do test -f "$$generated"; done
	$(DUNE) exec tests/hardening/fuzz_corpus.exe

metamorphic-test:
	@for generated in $(GENERATED); do test -f "$$generated"; done
	$(DUNE) exec tests/hardening/metamorphic.exe

sanitizer-test:
	scripts/native-sanitizer

performance-test: native-build
	CENTL_BIN="$(CURDIR)/_build/default/src/main.exe" \
		$(DUNE) exec tests/hardening/performance_smoke.exe

hardening-test: fuzz-test metamorphic-test sanitizer-test performance-test

differential-test: build
	$(JULIA) --project=lab/julia lab/julia/differential.jl

build: extract native-build

test: extract native-test

release: build
	test -n "$(VERSION)"
	scripts/package-release "$(VERSION)"

clean:
	$(DUNE) clean