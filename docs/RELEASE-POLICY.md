# CENTL release and branch policy

CENTL uses one product umbrella and three long-lived branches with deliberately
different responsibilities. **Oasis quality is a promotion standard, not a
requirement imposed on every branch or every development commit.**

## Product umbrella

- `CENTL` is the product name.
- `CENTL-SCi`, `CENTL-MIRAGE`, `CENTL-CARAVAN`, `Caramels`, and related names are
  subsystems or feature generations under the CENTL umbrella.
- Public stable product claims are derived from the `oasis` branch.

## The three long-lived branches

### `oasis` — standard product

`oasis` is the authoritative stable-product branch. It is the only long-lived
branch required to satisfy the complete Oasis qualification standard.

Code promoted to `oasis` must satisfy the repository's full release gates,
including the applicable formatting, build, deterministic-test, verification,
integrity, security, documentation, packaging, reproducibility, and release
requirements. An Oasis declaration applies only after those gates succeed.

`oasis` is not the primary experimentation surface. New speculative work should
mature elsewhere before promotion.

### `mirage` — development and research laboratory

`mirage` is the development, experimentation, and research branch. New features,
prototypes, speculative mathematics, architecture experiments, self-development
work, and other incomplete ideas should normally mature here.

`mirage` intentionally uses a lighter gate than `oasis`. It should retain basic
engineering protections needed to keep development useful, such as preventing
obvious repository corruption and catching appropriate build, syntax, test, or
security failures, but **a Mirage commit is not required to meet the complete
Oasis standard**.

A failure to satisfy an Oasis-only qualification check does not by itself make a
Mirage experiment invalid. The strict standard becomes mandatory when work is
proposed for promotion to `oasis`.

#### Oasis is the Mirage baseline

Every newly declared Oasis release becomes the new floor from which Mirage
development continues. After an Oasis release is established, `mirage` must be
reconciled onto that exact Oasis source baseline before new development proceeds.
Mirage may then diverge forward again with experimental work.

This rule is intentionally one-way:

```text
qualified Oasis baseline
          |
          +------> Mirage begins here
                     |
                     +--> experiments / research / new features
```

Mirage never makes an older stable baseline authoritative merely because it has
unique development commits. Unique Mirage work should be replayed, merged, or
otherwise reconciled on top of the new Oasis baseline when it remains useful.

### `main` — complete developer and research distribution

`main` is the comprehensive source line for developers and researchers who want
the whole CENTL codebase. It may contain the stable Oasis baseline together with
Mirage-originated experimental facilities, research material, and integration
work.

`main` is not itself an Oasis declaration and is not required to satisfy every
Oasis-only gate merely because it contains the full tree.

The main README and other flagship product surfaces must treat `oasis` as the
authoritative source for stable product identity: recommended release/version,
supported stable capabilities, installation claims, release badges, and other
standard-product statements should reflect what is established on `oasis`.
Experimental capabilities present through Mirage or main must be identified as
such and must not silently inherit Oasis assurance.

## Promotion model

The normal direction of maturity is:

```text
feature/research work
        |
        v
     mirage
        |
        | stabilize + satisfy Oasis qualification
        v
      oasis
        |
        v
 stable release/tag
```

After a new Oasis release, the cycle restarts by making that Oasis commit the
Mirage baseline.

`main` is the integrated distribution view rather than a maturity rung. It can
receive and expose both stable and experimental work according to repository
integration needs.

The governing rule is:

> **Oasis is a promotion state, not a property of every commit.**

## Continuous integration policy

CI should be branch-aware.

- **`oasis`** runs the complete Oasis gate and must remain strict.
- **`mirage`** runs a development gate optimized for useful feedback and rapid
  iteration without pretending experimental work is release-ready.
- **`main`** runs integration checks appropriate to the complete source tree, but
  Oasis-only qualification failures must not be treated as proof that the stable
  Oasis product is broken.
- Promotion from `mirage` or another development line into `oasis` must run the
  complete Oasis gate regardless of what lighter checks passed earlier.

Required security boundaries must never be bypassed merely for convenience. The
lighter Mirage policy concerns release qualification and development friction, not
permission to knowingly introduce dangerous behavior into shared infrastructure.

## Installation channels

Oasis and Mirage are separate install channels.

- Oasis is the default user installation and owns the conventional `centl`,
  `centl-physics`, and `centl-sci` commands.
- Mirage is an opt-in development installation and uses `mirage-centl`,
  `mirage-centl-physics`, and `mirage-centl-sci` so it can coexist with Oasis.
- Installing Mirage must never silently replace the active Oasis commands.
- A Mirage package is a development snapshot, not an Oasis declaration.

Prebuilt channel transport is independent of GitHub release identity. Qualified
Oasis bytes and rolling Mirage bytes may be served from the machine-oriented
`distribution` branch while stable release identity remains attached only to
qualified Oasis tags.

## Pull-request targeting

- Experimental features and research normally target `mirage`.
- Release hardening, qualification repairs, and explicitly prepared promotions
  target `oasis`.
- Repository-wide integration, documentation, tooling, or work whose purpose is
  the comprehensive developer/research distribution may target `main`.
- Short-lived feature/fix branches should be deleted after their work is merged or
  intentionally abandoned, unless retained as a documented archival reference.

## Releases and versioning

Stable CENTL releases are cut from qualified `oasis` commits and use normal
Semantic Versioning tags such as `v0.14.0`.

`v0.14.0` is the first Oasis foundation point for the current public release
history. Earlier releases and tags are historical development material rather
than part of the active public release line.

**Oasis is not a SemVer component.** It is the quality declaration attached to a
release whose source has passed the Oasis gate. Public wording may use
`CENTL vX.Y.Z` or `CENTL OASIS vX.Y.Z` when emphasizing the release line.

Mirage work may use development identifiers where useful, but experimental branch
state must not be presented as an Oasis release merely because it carries a
version-like label.

## Documentation authority

When documents disagree about branch roles, this policy controls. Repository maps,
contributor instructions, CI documentation, release notes, and the main README
should be kept consistent with it.
