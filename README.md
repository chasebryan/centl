![Free Computation Foundation - FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL MIRAGE

**The development, research, and experimentation branch for CENTL.**

> Good maths should be free.

This branch is where CENTL is allowed to move quickly.

New features, speculative mathematics, prototypes, architecture experiments,
CENTL-SCi self-development work, MIRAGE capabilities, CARAVAN research, interface
ideas, and other incomplete work should normally mature here before they are
considered for the standard product.

## This is not the stable product branch

`mirage` intentionally does **not** have to satisfy every Oasis release gate on
every commit.

It retains development protections needed to keep the branch useful, including
appropriate compilation, dedicated tests, whitespace checks, and security
boundaries, but experimental work is not required to impersonate a finished
release.

A failed Oasis-only qualification check does not by itself invalidate a Mirage
experiment. The complete Oasis standard becomes mandatory when work is proposed
for promotion to the stable-product branch.

> **Oasis is a promotion state, not a property of every commit.**

The canonical policy is [docs/RELEASE-POLICY.md](docs/RELEASE-POLICY.md).

## Branch model

CENTL has three long-lived branches:

- [`oasis`](https://github.com/chasebryan/centl/tree/oasis) is the authoritative
  standard product. It receives the complete Oasis qualification gate and is the
  source for stable release identity and flagship product claims.
- `mirage` is this development and research laboratory. It is intentionally more
  permissive so new ideas can be built and tested without premature release
  constraints.
- [`main`](https://github.com/chasebryan/centl/tree/main) is the comprehensive
  developer and research distribution containing the broad CENTL codebase.

The ordinary maturity path is:

```text
feature / research work
         |
         v
      mirage
         |
         | stabilize + complete Oasis qualification
         v
       oasis
         |
         v
 stable release / tag
```

`main` is the integrated distribution view, not another maturity stage.

## What belongs here

Mirage is the preferred home for work such as:

- new mathematical or physics capabilities that still need validation;
- CENTL-SCi interaction experiments and self-extension mechanisms;
- CENTL-MIRAGE recursive development and synthesis research;
- CARAVAN laboratory and protocol experimentation;
- prototypes, alternate algorithms, performance experiments, and new interfaces;
- dependency or architecture investigations;
- research implementations whose final stable contract has not yet been decided;
- experiments intended to fail, teach, or expose better designs.

Experimental status must remain honest. A prototype should not be documented as a
stable CENTL capability merely because it builds or passes a local test.

## Development gate

Mirage CI is deliberately lighter than Oasis CI. It is designed to answer questions
such as:

- does the relevant development surface compile;
- do its dedicated tests still pass;
- did the change introduce obvious repository corruption or whitespace damage;
- are required security boundaries still intact;
- is the experiment healthy enough for further research?

It is **not** intended to answer the stronger release question:

> Is this exact state ready to be called an Oasis release?

That question belongs to `oasis`.

## Working on Mirage

Experimental pull requests should normally target `mirage`.

Use short-lived feature branches when a change benefits from isolated review, then
merge the work into Mirage while it continues to mature. When a feature is ready
for the standard product, prepare a deliberate promotion to `oasis` and satisfy the
complete Oasis gate there.

Do not weaken core safety boundaries merely because Mirage is more permissive. The
lighter policy reduces release friction, not engineering responsibility.

## Running development source

GNU/Linux is the reference platform for current CENTL development.

From a development checkout:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make native-build
make native-test
```

Run the broader verification path when the change requires it:

```sh
make test
```

Subsystem-specific experiments may have additional commands documented under
`docs/` or their test directories.

## Want the standard product instead?

Use the authoritative Oasis branch rather than Mirage:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install
```

Mirage should not be presented to ordinary users as the stable installation line.

## Documentation

Development documentation evolves with the branch. Important starting points
include:

- [Branch and release policy](docs/RELEASE-POLICY.md)
- [CENTL-SCi](docs/SCI.md)
- [Caramels BUILD and self-extension](docs/CARAMELS-BUILD.md)
- [CENTL-MIRAGE](docs/CENTL-MIRAGE.md)
- [CENTL CARAVAN](docs/CARAVAN.md)
- [Syntax](docs/SYNTAX.md)
- [Mathematics](docs/MATHEMATICS.md)
- [Numerical contract](docs/NUMERICS.md)
- [Physics](docs/PHYSICS.md)
- [Verification](docs/VERIFICATION.md)
- [Architecture](docs/DESIGN.md)
- [Roadmap](docs/ROADMAP.md)

For the broad integrated repository view, use the README on `main`. For stable
product claims, use `oasis`.

## License

FCF-owned CENTL software is licensed under the **Apache License 2.0**
(`Apache-2.0`). Project documentation is licensed under **CC BY 4.0** where
identified, while official FCF/CENTL branding is governed separately so forks
remain free without being mistaken for official releases.

See [LICENSING.md](LICENSING.md), [TRADEMARKS.md](TRADEMARKS.md), and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the complete license map.

Developed under the **Free Computation Foundation**.

> **Free for science.**
