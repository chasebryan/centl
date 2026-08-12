# Free Computation Foundation Preservation Plan

> **Preserve enough of free computing that it can still be understood, verified, built, booted, repaired, and continued.**

The Free Computation Foundation (FCF) treats preservation as part of its technical mission.

The objective is not merely to keep copies of individual programs. FCF should preserve the source, knowledge, toolchains, operating environments, provenance, and reconstruction evidence required for future developers and researchers to recover meaningful free-computing systems even when upstream hosts, package indexes, accounts, vendors, or institutions disappear.

This plan is intentionally broader than CENTL. CENTL and CARAVAN provide immediate engineering reasons to build the preservation machinery, but the long-term preservation target is the free-computing ecosystem itself.

## Preservation principle

A preserved object should remain useful after its original distribution channel is gone.

Where practical and legally permitted, preservation should therefore capture more than a downloaded file:

- exact source and release identity;
- original upstream provenance;
- cryptographic digests and release signatures;
- license and redistribution status;
- build and installation instructions;
- dependency and toolchain relationships;
- documentation, manuals, release notes, and errata;
- source-control history when it materially improves reconstruction;
- representative binaries or installation media when useful for historical verification or recovery;
- known-good build environments, manifests, and reproducibility evidence; and
- enough surrounding context to explain what the object is and how it was used.

The guiding rule is:

> **Preserve context, not only bytes.**

## Core preservation domains

### 1. Operating systems and kernels

FCF should preserve important free operating-system and kernel lineages, including:

- **Linux**;
- **Linux-libre**;
- **Trisquel GNU/Linux**;
- **OpenBSD**;
- **FreeBSD**; and
- historically or technically important GNU operating-system work, including GNU Hurd and associated components where practical.

Linux and Linux-libre are separate preservation targets. Preserving Linux-libre does not replace preservation of the broader Linux kernel lineage, and preserving Linux does not replace the historical and technical value of Linux-libre.

For complete systems and distributions, preservation should seek source packages, release/install media, package metadata, checksums, signatures, build recipes, manuals, release notes, errata, and repository state where licensing permits.

### 2. GNU developer toolchain and foundational utilities

A source archive is of limited value if the tools required to understand and rebuild it have vanished.

FCF should therefore preserve the GNU development environment and other foundational free tools required to reconstruct software, including where applicable:

- GCC;
- GNU binutils;
- glibc;
- GDB;
- GNU Make;
- Bash;
- GNU Coreutils;
- Autoconf;
- Automake;
- Libtool;
- Texinfo;
- M4;
- Diffutils;
- Findutils;
- Grep;
- Sed;
- Gawk;
- Tar;
- Patch; and
- related GNU build, shell, documentation, and development utilities.

Preservation should include compatible historical versions and dependency relationships when those versions are necessary to reproduce older systems.

### 3. Free-software books, manuals, and institutional knowledge

FCF should seek to preserve the published technical and historical knowledge surrounding free software, including **FSF and GNU books, manuals, essays, historical documents, developer references, and other educational material**.

This corpus matters because software without its surrounding knowledge can become technically present but practically unintelligible.

Preservation and redistribution are not the same permission. Every item must retain its license and rights metadata. FCF should:

- preserve full copies when archival possession is lawful and appropriate;
- distribute copies publicly only when redistribution rights permit it;
- retain provenance, bibliographic metadata, hashes, and acquisition records even when public redistribution is not permitted; and
- never use CARAVAN publication as a way to bypass copyright, license, trademark, privacy, export, or contractual restrictions.

### 4. Package ecosystems and source dependencies

FCF should preserve build-critical and historically important package material rather than assume package registries will exist forever.

This includes source archives, package-index state, dependency metadata, lockfiles, build recipes, and signatures needed to reconstruct admitted software.

For CENTL, the existing **FCF Dependency Chest** is the first concrete implementation of this principle. The Chest remains focused on immutable, authenticated dependency and recovery crates required for CENTL and related FCF systems. It is a subset of the broader preservation mission, not the limit of it.

### 5. Programming languages, compilers, and interpreters

FCF should consider preservation of foundational free language implementations and their build ecosystems, particularly where they are required by preserved systems or have substantial historical value.

Relevant families may include C, C++, Scheme/Lisp, OCaml, Python, Perl, Rust, and others according to technical dependency, historical importance, licensing, and preservation capacity.

For each admitted language ecosystem, the useful preservation unit may include compiler/interpreter source, standard libraries, package metadata, bootstrap dependencies, documentation, and representative conformance or regression suites.

### 6. Boot, firmware, and low-level system freedom

Long-term software preservation should account for the path between hardware and operating system.

FCF should consider preservation of free or substantially free boot and firmware projects and their documentation, including:

- coreboot;
- Libreboot;
- GRUB;
- U-Boot;
- SeaBIOS; and
- associated board data, build instructions, utilities, and compatibility documentation where redistribution is lawful.

This domain is especially important for machines intentionally maintained as long-lived preservation hosts.

### 7. Networking, storage, and developer infrastructure

A reconstructable computing environment also requires the software that lets developers communicate, retrieve source, inspect systems, and store data.

FCF should consider preservation of foundational freely licensed projects such as version-control tools, secure remote-access software, DNS and HTTP implementations, transfer utilities, synchronization tools, databases, filesystems, recovery tools, editors, shells, debuggers, and documentation systems.

Admission should be based on technical importance and preservation value rather than attempting to mirror every free project indiscriminately.

### 8. Standards and specifications

Where licensing and distribution terms permit, FCF should retain specifications required to understand preserved interfaces and formats, including relevant Internet RFCs, ABI and executable-format documentation, filesystem specifications, language specifications, protocol documentation, and other reconstruction-critical standards.

If a specification cannot lawfully be redistributed, the archive should preserve metadata identifying the exact document and version needed for reconstruction.

### 9. Free hardware knowledge

Where practical, FCF should preserve freely licensed hardware knowledge that materially supports durable computing: schematics, firmware source, FPGA projects, board documentation, repair information, open instruction-set material, and hardware compatibility records.

RISC-V and other open hardware ecosystems may be appropriate preservation targets when their artifacts satisfy FCF provenance and licensing requirements.

## Admission policy

Preservation must be curated and evidence-backed rather than an uncontrolled web crawl.

An FCF preservation admission should record, as applicable:

1. what the artifact or corpus is;
2. why it is technically or historically worth preserving;
3. its exact upstream identity and acquisition provenance;
4. cryptographic identity of preserved bytes;
5. license, copyright, trademark, privacy, export, and redistribution considerations;
6. whether the bytes are `public-approved`, `fcf-preservation-only`, `pending-review`, or otherwise restricted;
7. dependency and reconstruction relationships;
8. signatures, checksums, or other upstream authenticity evidence;
9. FCF verification and admission metadata; and
10. the preservation snapshot or catalog generation that contains it.

No artifact becomes publicly redistributable merely because FCF possesses an archival copy.

## Preserve source and history before convenience

When storage and licensing permit, FCF should prefer preservation material that maximizes future reconstruction:

1. source and exact version-control history;
2. release signatures, hashes, and provenance;
3. dependency and build metadata;
4. manuals and specifications;
5. reproducibility evidence and known-good build environments; and
6. representative binaries or installation media.

Binaries remain valuable for recovery, comparison, and historical study, but source and reconstruction context have higher long-term leverage.

## Verification and authenticity

Preservation should be cryptographically inspectable.

FCF preservation tooling should increasingly automate:

- acquisition recording;
- SHA-256 or stronger maintained digest computation where policy evolves;
- signature and checksum verification;
- license/redistribution metadata capture;
- content-addressed storage;
- manifest generation;
- duplicate detection;
- corruption scanning;
- dependency graph recording;
- reproducibility or rebuild checks where feasible;
- periodic integrity audits; and
- replication-state reporting.

A future archive reader should be able to distinguish:

- bytes acquired from upstream;
- bytes independently verified by FCF;
- bytes reproducibly rebuilt by FCF;
- bytes approved for public redistribution; and
- bytes retained only for controlled preservation.

These states must not be collapsed into a single word such as "trusted."

## CARAVAN relationship

**CARAVAN is the replication and availability layer for this preservation mission.**

The FCF preservation process decides what is admitted, records provenance and rights, and assigns a redistribution class. CARAVAN then makes eligible content harder to lose by distributing exact authenticated objects across approved FCF infrastructure and, where policy permits, volunteer carriers.

The separation of authority remains absolute:

```text
Upstream projects and institutions
            |
            v
   FCF preservation ingest
            |
            v
 provenance / rights / identity review
            |
            v
    FCF preservation catalog
       |               |
       |               +--> preservation-only holdings
       |
       +--> public-approved objects
                    |
                    v
                 CARAVAN
          distributed availability
```

CARAVAN does **not** decide that Linux, Linux-libre, Trisquel, a GNU manual, or any other object belongs in the archive. It carries only objects admitted through FCF preservation policy and only within their permitted redistribution class.

Likewise, the existence of a volunteer copy does not alter the canonical artifact identity, license, historical record, or FCF admission decision.

## Preservation missions and CARAVAN evolution

CARAVAN's current protocol mission classes are implementation-facing categories such as source, releases, semantic, and recovery. The broader FCF preservation plan introduces policy domains rather than silently changing those implemented protocol values.

Future CARAVAN catalog and mission revisions may add preservation-oriented classes for systems, toolchains, knowledge, historical releases, or other corpora. Any such protocol expansion must be versioned, documented, tested, and gated through the normal CARAVAN trust and rollout process.

This prevents documentation from claiming a network capability before the software implements it.

## Geographic and institutional resilience

Long-term preservation should not depend on one account, one provider, one building, or one legal jurisdiction.

As FCF capacity grows, preservation snapshots should be replicated across multiple independent storage systems and, where appropriate, multiple geographic or institutional locations. CARAVAN provides a natural mechanism for distributing eligible public material, while controlled FCF mirrors can retain preservation-only holdings.

Offline or cold-storage copies should be considered for high-value preservation snapshots so an online compromise cannot rewrite every copy simultaneously.

## Recovery drills

An archive that is never restored is only presumed to work.

FCF should periodically perform recovery exercises that attempt to:

- verify a preservation snapshot without its original upstream;
- rebuild selected software using preserved toolchains and dependencies;
- boot or install representative preserved systems in suitable hardware or virtual environments;
- recover documentation and provenance records;
- reconstruct catalog state from retained manifests; and
- demonstrate that at least one independent replica can replace a lost primary copy.

Failures discovered during recovery exercises should become preservation work items rather than being hidden behind best-effort network substitution.

## Initial FCF preservation priority

The first strategic preservation set should concentrate on artifacts that directly support free scientific and developer computing:

1. Linux;
2. Linux-libre;
3. Trisquel GNU/Linux;
4. OpenBSD;
5. FreeBSD;
6. the GNU developer toolchain and foundational utilities;
7. FSF/GNU books, manuals, and technical/historical documentation under their applicable rights;
8. CENTL source, releases, documentation, dependencies, recovery material, and qualified semantic artifacts;
9. boot/firmware projects useful to long-lived free systems, including coreboot and Libreboot; and
10. the preservation metadata, verification tooling, and CARAVAN infrastructure needed to keep all of the above inspectable and recoverable.

This priority list is a compass, not an assertion that every object is already archived or publicly distributable.

## Preservation maturity levels

FCF may describe preservation status with explicit evidence levels rather than a binary archived/not-archived label:

- **Cataloged**: identity, provenance, and rights metadata recorded.
- **Captured**: exact preservation bytes retained by FCF.
- **Verified**: retained bytes pass the applicable digest/signature/provenance checks.
- **Reconstructable**: required build/recovery dependencies and instructions are also preserved.
- **Recovery-proven**: FCF has successfully exercised the applicable rebuild, restore, install, or boot procedure from preserved material.
- **Replicated**: the admitted material exists on multiple independent preservation stores.
- **CARAVAN-distributed**: public-approved material is available through the authenticated CARAVAN distribution layer.

A higher label must require evidence for the preceding properties that matter to that artifact class.

## Scope discipline

FCF preservation is not intended to become an indiscriminate mirror of the Internet.

Priority goes to material that is:

- required to build, verify, recover, or understand FCF software;
- foundational to free operating systems and developer environments;
- historically significant to free computation;
- at meaningful risk of disappearance or dependency rot; or
- necessary to preserve the knowledge required to continue free scientific computing.

Storage capacity, legal rights, verification cost, security, and operator sustainability remain real constraints.

## Final doctrine

FCF preservation exists so future access to free computation is not determined solely by whether today's hosting companies, package services, institutions, accounts, or machines survive.

The preservation record should answer four questions:

1. **What were the bytes?**
2. **Where did they come from?**
3. **What is required to understand and reconstruct them?**
4. **What are we legally and technically permitted to do with them?**

CARAVAN then adds a fifth:

5. **How do we make the permitted record difficult to lose?**

> **Preserve the code. Preserve the tools. Preserve the knowledge. Preserve the path back.**
