# Mathematician onboarding 🧮 📐

This page is deliberately narrow. It is for mathematicians who want to use CENTL for **pure mathematics** and do not want to learn the rest of the repository first.

If that is you, you can ignore CENTL Physics, CARAVAN, networking, repository infrastructure, release engineering, and contributor workflows unless you later choose to explore them.

## The 60-second route

Install the qualified Oasis product on GNU/Linux x86_64:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install --channel oasis
```

Check the exact arithmetic contract:

```sh
centl '0.1 + 0.2'
```

Expected result:

```text
3/10
```

Then try a few mathematical operations:

```sh
centl 'solve(x^2 - 5*x + 6 = 0, x)'
centl 'diff(x^3 + 2*x + 1, x)'
centl 'integrate(x^2, x = 0, 1)'
centl 'approx(sqrt(2), 30)'
centl verify --left '0.1 + 0.2' --relation equal --right '3/10'
```

If you prefer to state problems in ordinary language, start CENTL-SCi:

```sh
centl-sci
```

and select mathematics-first interaction:

```text
:mode math
```

You are now on the mathematics path. Nothing else in CENTL is required reading before you begin.

## Which command should a mathematician use?

### `centl` — the authoritative mathematical engine

Use `centl` when you want direct, deterministic mathematical input and output.

Examples:

```sh
centl 'simplify(2*x + 3*x)'
centl 'expand((x + 1)^3)'
centl 'factor(x^2 - 1)'
centl 'solve(2*x + 3 = 11, x)'
centl 'substitute(x^2 + 1, x = 3)'
centl 'diff(sin(x) + x^3, x)'
centl 'integrate(3*x^2 + 2*x + 1, x)'
centl 'assuming(x / x, x != 0)'
```

### `centl-sci` — the mathematics interpreter

Use `centl-sci` when you want to describe a supported mathematical task in ordinary language while keeping CENTL as the authoritative evaluator.

Examples:

```text
MATH> what is 0.1 plus 0.2
MATH> solve x squared minus 5x plus 6 equals zero
MATH> approximate sqrt(2) to 30 significant digits
MATH> verify 0.1 + 0.2 equals 3/10
```

CENTL-SCi is not a second mathematics engine. It interprets the request, constructs a validated problem representation, and dispatches the admitted operation to CENTL. A semantic model is not required for deterministic supported paths.

For more evidence about how a request was interpreted and executed, use the SCi details and explanation surfaces:

```sh
centl-sci --details 'Solve x squared minus 5x plus 6 equals zero.'
centl-sci --explain 'Verify 0.1 + 0.2 equals 3/10.'
```

## The mathematical contract you should understand

CENTL is **exact-first**.

A finite decimal literal is an exact rational value, not an IEEE floating-point approximation. Therefore:

```text
0.1        = 1/10
1.2300     = 123/100
0.1 + 0.2  = 3/10
```

Exact inputs remain exact whenever the mathematical result is represented by CENTL's exact domain.

When you explicitly request an approximation, CENTL uses a bounded enclosure and prints digits only when the enclosure justifies them. An approximate answer is therefore a claim with a numerical evidence boundary, not a decorative decimal rendering.

Unsupported work is also part of the contract. CENTL does not silently turn an unsupported operation into a guessed answer. A residual symbolic expression or an `unsupported`, `unknown`, or unresolved status means exactly that.

## What mathematics is useful today?

### Exact arithmetic

CENTL supports arbitrary-precision integers and exact rational arithmetic. Finite decimal input is treated exactly.

### Exact symbolic polynomial algebra

For supported univariate rational polynomials, CENTL can simplify, expand, factor within its documented factorization classes, and perform exact coefficient arithmetic.

Polynomial expansion is deliberately bounded. Unsupported transformations remain visible rather than being reported as successful algebra.

### Equations

CENTL solves admitted linear equations and real quadratic equations with exact rational coefficients. Irrational real quadratic roots can remain in exact symbolic square-root form.

Higher-degree or unsupported equations remain unresolved rather than being guessed numerically.

### Differentiation

CENTL has exact derivative rules for arithmetic, integer powers, and supported functions including trigonometric, inverse trigonometric, hyperbolic, exponential, logarithmic, and square-root forms.

When no verified rule is available, the derivative remains visible as an unsupported residual expression.

### Integration

CENTL performs exact indefinite and definite integration for its admitted rational-coefficient univariate polynomial domain.

For example:

```sh
centl 'integrate(x^2, x = 0, 1)'
```

returns:

```text
1/3
```

This is exact polynomial integration, not numerical quadrature. General symbolic integration is not implied.

### Substitution and explicit assumptions

You can substitute exact expressions and attach local assumptions without hiding them:

```sh
centl 'substitute(x^2 + 1, x = 3)'
centl 'assuming(x / x, x != 0)'
```

CENTL preserves assumptions in the result rather than silently widening the mathematical domain of an identity.

### Rigorous approximation

Use:

```sh
centl 'approx(pi)'
centl 'approx(sqrt(2), 50)'
```

The explicit digit request is a requirement to justify those digits. If CENTL cannot establish the requested precision within its resource limits, it reports that instead of inventing a cleaner-looking decimal.

### Closed mathematical claim verification

For closed comparisons, use the verifier directly:

```sh
centl verify --left '1/3' --relation less_than --right '1/2'
```

or through SCi:

```text
MATH> check whether 1/3 < 1/2
```

`verified` and `refuted` are established outcomes. `unknown` and `invalid` remain unresolved outcomes, not hidden guesses.

## What should you *not* assume?

CENTL is not claiming to be a universal computer algebra system or a general theorem prover.

In particular, do not assume that it currently provides:

- arbitrary symbolic integration;
- arbitrary higher-degree equation solving;
- a general algebraic-number scalar backend for every expression;
- automatic proof of quantified free-variable theorems from ordinary language;
- success merely because an expression was returned unchanged;
- approximate digits beyond what the returned enclosure establishes.

The refusal boundary is intentional. CENTL would rather leave mathematics unresolved than manufacture mathematical certainty.

## Recommended mathematician workflow

1. **Use `centl` first** when you know the formal expression you want evaluated.
2. **Use `centl-sci` in `MATH` mode** when ordinary mathematical language is faster or more natural.
3. **Keep exact forms exact** unless approximation is part of your actual task.
4. **Read the resolution status**, not only the displayed expression.
5. **Use `--details` or `--explain`** when you need to inspect SCi's interpretation path.
6. **Treat unsupported or unknown results as information**, not as an invitation to infer a missing answer.

## Read next, and only when you need it

- [Numerical contract](NUMERICS.md) — exactness, enclosures, precision, comparisons, and failure semantics.
- [Exact symbolic algebra](ALGEBRA.md) — simplification, expansion, factoring, assumptions, and equations.
- [Symbolic calculus](CALCULUS.md) — differentiation, integration, and substitution.
- [CENTL-SCi](SCI.md) — mathematics-first natural-language interaction and evidence surfaces.
- [Installation](INSTALL.md) — channels, offline installation, and source builds.

That is the complete starting map for a mathematician. The rest of the repository can stay outside your working set until your mathematics actually requires it.
