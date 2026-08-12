# FCF Dependency Chest

> Upstream is where FCF discovers material. FCF preservation is where CENTL builds from it.

The **FCF Dependency Chest** is the planned preservation and distribution layer for immutable, authenticated copies of the redistributable third-party material required to build, test, recover, and qualify CENTL.

Individual preserved dependency objects are called **crates**.

The Chest exists so an Oasis-capable build does not depend on a third-party release host, mutable URL, certificate path, package index, model hub, or repository being reachable at build time.

## Core contract

A crate is admitted only when FCF can bind all of the following to one immutable identity:

- dependency name and upstream project;
- exact upstream version, commit, or release identity;
- exact SHA-256 digest and byte length;
- original acquisition URL and upstream provenance;
- license and redistribution status;
- the preserved bytes or a documented reason the bytes may not be redistributed;
- FCF admission metadata and signature;
- dependency relationships needed for deterministic reconstruction.

The Chest is content-addressed. A name or version is metadata; the digest is the object identity.

## Build rule

An Oasis-capable or preservation recovery build must not silently substitute a live third-party download for a missing approved crate.

If an admitted dependency is absent, corrupted, unauthorized, rolled back, or no longer matches its declared identity, the build must fail closed and identify the missing crate.

Network acquisition belongs to a separate, explicit FCF ingest/update operation. It is not an implicit recovery-build fallback.

## Initial crate families

The initial Chest should cover every redistributable input needed by the CENTL preservation and recovery path, including where applicable:

- OCaml/opam package archives and the pinned opam repository state;
- Alcotest, Dune, QCheck, Yojson, Zarith, OCamlformat, and their transitive build dependencies;
- F*;
- GMP;
- MPFR;
- FLINT;
- Julia and the preserved Julia/Nemo material;
- llama.cpp source;
- other pinned native build inputs;
- qualified semantic-model artifacts only when redistribution has been explicitly approved.

## CARAVAN relationship

The FCF preservation origin is authoritative for Chest admission. CARAVAN may distribute approved crates by immutable content identity, but a volunteer carrier cannot nominate arbitrary content, alter a crate, or convert the Chest into general-purpose file hosting.

Volunteer mission selection may allow a camel to carry dependency/recovery crates, subject to CARAVAN policy, storage limits, licensing, and authenticated catalog membership.

## Privacy and safety

Crate distribution must not require publication of volunteer IP addresses, hostnames, identities, or a public carrier roster. Normal volunteer carriers remain outbound-oriented and subject to the CARAVAN privacy contract.

## Qualification target

The Chest is ready for Oasis/recovery authority only when CI can perform a representative CENTL build and recovery proof using authenticated Chest material with live third-party dependency acquisition disabled.

The desired failure mode is explicit rather than opportunistic, for example:

```text
FCF DEPENDENCY CHEST FAILURE

Required crate:
  alcotest 1.9.1

Expected identity:
  sha256:<digest>

Status:
  NOT PRESENT IN APPROVED FCF CHEST

Live network substitution:
  REFUSED
```

This preserves both reproducibility and honesty: if FCF has not preserved the required material, CENTL says so instead of quietly trusting whatever the network serves today.
