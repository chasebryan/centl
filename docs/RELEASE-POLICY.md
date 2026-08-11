# CENTL release and branch policy

This repository uses one product umbrella, two release lines, and at most three
long-lived branches.

## Product umbrella

- `CENTL` is the product name.
- `CENTL-SCi`, `CENTL-MIRAGE`, `CENTL-CARAVAN`, `Caramels+`, and related names
  remain feature or subsystem names under the CENTL umbrella.
- No separate codename is required for the whole product release.

## Release lines

- `OASIS` is the stable release line.
- `MIRAGE` is the experimental and development line.
- Public release notes may name the product as `CENTL vX.Y.Z` or
  `CENTL OASIS vX.Y.Z` when the line matters.

## Branch policy

Long-lived branches are capped at three:

- `main` for the integrated product line.
- `oasis` for release stabilization and qualification.
- `mirage` for experimental and development work.

All other work should live in short-lived branches, pull requests, or tags.

## Versioning

- Product releases use normal semantic versions, for example `v0.15.0`.
- Feature/version pairs stay separate, for example `CENTL-SCi v0.0.2-Caramels+`.
- Tags capture immutable release points; branches are not release artifacts.
