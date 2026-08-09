FSTAR ?= fstar.exe
JULIA ?= julia
OPAM ?= opam
PYTHON ?= python3
OPAM_SWITCH ?= centl
DUNE ?= $(shell \
	if command -v dune >/dev/null 2>&1; then command -v dune; \
	elif command -v opam >/dev/null 2>&1; then \
		printf '%s' 'opam exec --switch=$(OPAM_SWITCH) -- dune'; \
	else printf '%s' dune; fi)
FSTAR_GCD := src/fstar/Centl.Gcd.fst
FSTAR_CORE := src/fstar/Centl.Core.fst
FSTAR_POLYNOMIAL_SOUNDNESS := src/fstar/Centl.PolynomialSoundness.fst
FSTAR_CACHE := _build/fstar
GENERATED := src/generated/Centl_Gcd.ml src/generated/Centl_Core.ml \
	src/generated/Centl_PolynomialSoundness.ml
FSTAR_COMMON := --include src/fstar --cache_dir $(FSTAR_CACHE) \
	--hint_dir $(FSTAR_CACHE) --split_queries always --z3rlimit 2
SCI_LLAMA_CLI ?= llama-cli
SCI_TIMEOUT ?= 300
SCI_REPORT ?= sci-model-report.json
SCI_SERVER_URL ?=
SCI_MODEL ?=
SCI_MODEL_LABEL ?= resident-model
SCI_ASSIMILATION_FAST_REPEATS ?= 5
SCI_ASSIMILATION_MODEL_REPEATS ?= 1
SCI_ASSIMILATION_ARGS ?=

.PHONY: all format format-fix fmt lint quality verify extract native-build native-test \
	adversarial-test fuzz-test metamorphic-test sanitizer-test performance-test \
	hardening-test differential-test sci-model-test sci-assimilate \
	sci-assimilate-full sci-assimilate-publish build test release clean

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
		--cache_checked_modules --report_assumes error \
		$(FSTAR_POLYNOMIAL_SOUNDNESS)

extract: verify
	mkdir -p src/generated
	$(FSTAR) $(FSTAR_COMMON) \
		--codegen OCaml --extract Centl.Gcd \
		--odir src/generated $(FSTAR_GCD)
	$(FSTAR) $(FSTAR_COMMON) \
		--codegen OCaml --extract Centl.Core \
		--odir src/generated $(FSTAR_CORE)
	$(FSTAR) $(FSTAR_COMMON) \
		--codegen OCaml --extract Centl.PolynomialSoundness \
		--odir src/generated $(FSTAR_POLYNOMIAL_SOUNDNESS)
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

sci-model-test: build
	test -n "$(MODEL)" || { echo "MODEL=/path/to/model.gguf is required" >&2; exit 2; }
	$(PYTHON) scripts/sci-model-eval.py \
		--model "$(MODEL)" \
		--llama-cli "$(SCI_LLAMA_CLI)" \
		--timeout "$(SCI_TIMEOUT)" \
		--output "$(SCI_REPORT)"

sci-assimilate:
	CENTL_SCI_SERVER_URL="$(SCI_SERVER_URL)" \
	CENTL_SCI_MODEL_LABEL="$(SCI_MODEL_LABEL)" \
		$(PYTHON) scripts/sci-assimilate.py \
		--fast-repeats "$(SCI_ASSIMILATION_FAST_REPEATS)" \
		--model-repeats "$(SCI_ASSIMILATION_MODEL_REPEATS)" \
		$(SCI_ASSIMILATION_ARGS)

sci-assimilate-full:
	CENTL_SCI_SERVER_URL="$(SCI_SERVER_URL)" \
	CENTL_SCI_MODEL_LABEL="$(SCI_MODEL_LABEL)" \
		$(PYTHON) scripts/sci-assimilate.py \
		--full \
		--fast-repeats "$(SCI_ASSIMILATION_FAST_REPEATS)" \
		--model-repeats "$(SCI_ASSIMILATION_MODEL_REPEATS)" \
		$(SCI_ASSIMILATION_ARGS)

sci-assimilate-publish:
	CENTL_SCI_SERVER_URL="$(SCI_SERVER_URL)" \
	CENTL_SCI_MODEL="$(SCI_MODEL)" \
	CENTL_SCI_MODEL_LABEL="$(SCI_MODEL_LABEL)" \
		sh scripts/sci-assimilate-publish \
		--fast-repeats "$(SCI_ASSIMILATION_FAST_REPEATS)" \
		--model-repeats "$(SCI_ASSIMILATION_MODEL_REPEATS)" \
		$(SCI_ASSIMILATION_ARGS)

build: extract native-build

test: extract native-test

release: build
	test -n "$(VERSION)"
	scripts/package-release "$(VERSION)"

clean:
	$(DUNE) clean
