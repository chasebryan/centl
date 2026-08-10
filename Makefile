FSTAR ?= fstar.exe
JULIA ?= julia
OPAM ?= opam
PYTHON ?= python3
OPAM_SWITCH ?= centl
INTEGRITY_MANIFEST ?= _build/integrity/SHA256SUMS
RELEASE_DIR ?= dist
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

.PHONY: all format format-fix fmt lint quality licensing-check install-interface-check integrity-self-test \
	integrity-source supply-chain-check supply-chain-sync supply-chain-audit \
	supply-chain-snapshot-opam supply-chain-snapshot-julia supply-chain-preserve \
	offline-rebuild capsule-build capsule-run release-sign release-verify verify \
	extract native-build native-test adversarial-test fuzz-test metamorphic-test \
	sanitizer-test performance-test hardening-test differential-test sci-model-test \
	sci-interface-check sci-assimilate sci-assimilate-full sci-assimilate-publish \
	build test release clean

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

licensing-check:
	sh scripts/check-licensing

install-interface-check:
	$(PYTHON) scripts/install-interface-check.py

integrity-self-test:
	$(PYTHON) scripts/integrity.py self-test

integrity-source: integrity-self-test
	mkdir -p "$(dir $(INTEGRITY_MANIFEST))"
	$(PYTHON) scripts/integrity.py source-manifest --output "$(INTEGRITY_MANIFEST)"
	$(PYTHON) scripts/integrity.py hash "$(INTEGRITY_MANIFEST)" > "$(INTEGRITY_MANIFEST).sha256"

supply-chain-check:
	$(PYTHON) scripts/supply-chain-check.py

supply-chain-sync:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	@if [ -n "$(MODEL)" ]; then \
		sh scripts/supply-chain sync "$(MIRROR)" "$(MODEL)"; \
	else \
		sh scripts/supply-chain sync "$(MIRROR)"; \
	fi

supply-chain-audit:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	sh scripts/supply-chain audit "$(MIRROR)"

supply-chain-snapshot-opam:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	CENTL_OPAM_SWITCH="$(OPAM_SWITCH)" sh scripts/supply-chain snapshot-opam "$(MIRROR)"

supply-chain-snapshot-julia:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	JULIA="$(JULIA)" sh scripts/supply-chain snapshot-julia "$(MIRROR)"

supply-chain-preserve:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	git diff --quiet -- && git diff --cached --quiet -- || { \
		echo "tracked worktree must be clean before preservation" >&2; exit 2; \
	}
	$(MAKE) integrity-source supply-chain-check
	@if [ -n "$(MODEL)" ]; then \
		sh scripts/supply-chain sync "$(MIRROR)" "$(MODEL)"; \
	else \
		sh scripts/supply-chain sync "$(MIRROR)"; \
	fi
	CENTL_OPAM_SWITCH="$(OPAM_SWITCH)" sh scripts/supply-chain snapshot-opam "$(MIRROR)"
	JULIA="$(JULIA)" sh scripts/supply-chain snapshot-julia "$(MIRROR)"
	mkdir -p "$(MIRROR)/project"
	cp "$(INTEGRITY_MANIFEST)" "$(MIRROR)/project/SOURCE-SHA256SUMS"
	$(PYTHON) scripts/integrity.py hash "$(MIRROR)/project/SOURCE-SHA256SUMS" \
		> "$(MIRROR)/project/SOURCE-SHA256SUMS.sha256"
	git rev-parse HEAD > "$(MIRROR)/project/SOURCE-COMMIT"
	sh scripts/supply-chain audit "$(MIRROR)"

offline-rebuild:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	CENTL_OPAM_SWITCH="$(OPAM_SWITCH)" sh scripts/offline-rebuild "$(MIRROR)"

capsule-build:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	sh scripts/capsule-build "$(MIRROR)"

capsule-run:
	test -n "$(MIRROR)" || { echo "MIRROR=/path/to/centl-mirror is required" >&2; exit 2; }
	sh scripts/capsule-run "$(MIRROR)"

release-sign:
	test -n "$(FCF_SIGNIFY_SECRET_KEY)" || { echo "FCF_SIGNIFY_SECRET_KEY is required" >&2; exit 2; }
	test -n "$(FCF_SIGNIFY_PUBLIC_KEY)" || { echo "FCF_SIGNIFY_PUBLIC_KEY is required" >&2; exit 2; }
	FCF_SIGNIFY_SECRET_KEY="$(FCF_SIGNIFY_SECRET_KEY)" \
	FCF_SIGNIFY_PUBLIC_KEY="$(FCF_SIGNIFY_PUBLIC_KEY)" \
		sh scripts/release-sign "$(RELEASE_DIR)"

release-verify:
	test -n "$(FCF_SIGNIFY_PUBLIC_KEY)" || { echo "FCF_SIGNIFY_PUBLIC_KEY is required" >&2; exit 2; }
	FCF_SIGNIFY_PUBLIC_KEY="$(FCF_SIGNIFY_PUBLIC_KEY)" \
		sh scripts/release-verify "$(RELEASE_DIR)"

quality: format lint licensing-check install-interface-check integrity-source supply-chain-check

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

sci-interface-check: native-build
	$(PYTHON) scripts/sci-interface-check.py

sci-assimilate:
	CENTL_SCI_SERVER_URL= CENTL_SCI_MODEL= \
		$(PYTHON) scripts/sci-assimilate.py \
		--server-url "$(SCI_SERVER_URL)" \
		--model-label "$(SCI_MODEL_LABEL)" \
		--fast-repeats "$(SCI_ASSIMILATION_FAST_REPEATS)" \
		--model-repeats "$(SCI_ASSIMILATION_MODEL_REPEATS)" \
		$(SCI_ASSIMILATION_ARGS)
	$(PYTHON) scripts/sci-interface-check.py

sci-assimilate-full:
	CENTL_SCI_SERVER_URL= CENTL_SCI_MODEL= \
		$(PYTHON) scripts/sci-assimilate.py \
		--server-url "$(SCI_SERVER_URL)" \
		--model-label "$(SCI_MODEL_LABEL)" \
		--full \
		--fast-repeats "$(SCI_ASSIMILATION_FAST_REPEATS)" \
		--model-repeats "$(SCI_ASSIMILATION_MODEL_REPEATS)" \
		$(SCI_ASSIMILATION_ARGS)
	$(PYTHON) scripts/sci-interface-check.py

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
