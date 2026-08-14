# FCF Camps

**Status:** authoritative FCF stay policy
**Scope:** durable, bounded stays when a new Oasis cannot honestly be declared
**SemVer effect:** none
**Oasis assurance effect:** none
**Publication authority:** none

> A Camp is a place to stay. It is not an Oasis.

## Verdict first

Oasis is **not dead**. Oasis is the steadily advanced stable snapshot of
the current `main` and `mirage` trees. It is made by placing that tree on
the current oasis tip so Oasis does not regress, passing the complete
gate, and fast-forwarding `oasis`. After that, development continues on
`mirage` and `main`.

The last completed Oasis remains authoritative until a later snapshot
closes that chain. Camps do not close the path, weaken it, or inherit it.

A Camp is still the named stay for inhabiting work that is not (yet) the
next Oasis snapshot. Camp #1 remains occupied on `main` and `mirage`.
Occupying a Camp does not mean Oasis can never be made from the stable
tree.

What is true of an unpromoted laboratory checkout:

- it is not on `oasis`;
- it is not an Oasis declaration merely because it matches the snapshot
  tree;
- laboratory surfaces do not inherit Oasis by proximity.

Declaring Oasis still requires the official snapshot, the complete gate,
an unchanged fast-forward, the SemVer tag, and qualified bytes.

## Definition

An **FCF Camp** is a named, bounded, inspectable stay in the desert. FCF uses
a Camp when an expedition has produced real work that people may inhabit, but
that work cannot honestly be declared an Oasis release.

The canonical short definition is:

> **FCF Camp:** a durable stay for work that is real enough to keep and honest
> enough not to call Oasis.

A Camp names **habitation**, not qualification.

## Desert vocabulary

These terms remain independent. None substitutes for the evidence required by
another.

```text
MIRAGE        = where uncertain work can develop
Secret Oasis  = a deliberate search for unusually valuable directions
Wellspring    = a foundational, generative finding
Camp          = a durable stay when Oasis cannot be declared
Oasis         = a qualified stable-product release
```

Al-Tih already says Oasis is not scheduled and must be earned. A Camp is the
named waystation for that epoch. See [`MIRAGE-AL-TIH.md`](MIRAGE-AL-TIH.md)
and [`OASIS.md`](OASIS.md).

## What a Camp is not

A Camp is not:

- an Oasis release or Oasis candidate declaration;
- a CENTL SemVer identity such as `vX.Y.Z`, or a substitute for Oasis;
- a Wellspring;
- a full product promotion of `mirage` or `main`;
- permission to skip, weaken, or rewrite Oasis gates;
- a change to the signed join-caravan scheme;
- a website visual redesign;
- a claim that v0.14.0 has been superseded.

If a sentence would be false after replacing "Camp" with "Oasis," the Camp
record is lying.

## When to occupy a Camp

Pitch a Camp only when all of the following are true:

1. Oasis inspect reports blockers that this checkout cannot honestly
   clear without weakening a gate or dropping the oasis tip.
2. The work is still worth keeping as a stayable laboratory line.
3. The bounds can be written down: what is inside the camp, what remains
   experimental, and what remains forbidden.
4. Occupying the camp does not require a false Oasis, Wellspring, or release
   declaration.

Failure to find Oasis is not failure of the research process. A Camp records
that fact instead of inventing a promotion.

## Camp invariants

- `declaration` is always false for Oasis and for Camp-as-Oasis.
- `origin/oasis` should be an ancestor of the camp identity. If it is not,
  that is a camp defect, not an excused regression.
- Existing Oasis tests, installer channels, and supported command surfaces
  stay.
- Site visual design stays as intended.
- The signed join-caravan installer, invite schema, and `join.html` stay.
- Inspect commands may occupy or describe a Camp. They may never declare
  Oasis.

## Official path remains

```text
feature / research work
         |
         v
      mirage
         |
         +---- occupied Camp (stay; not a release)
         |
         | inhabit / integrate
         v
       main
         |
         | linear snapshot on the oasis tip
         | satisfy the complete Oasis gate
         v
       oasis
         |
         v
 stable release / tag
         |
         v
 continue on mirage and main
```

Leaving a Camp toward Oasis still requires the official Oasis path. Occupying
a Camp does not shorten it.

## Named camp artifacts

A Camp may publish a **named stay artifact** on GitHub under a tag of the
form `fcf-camp-NNN`. That tag is a snapshot of the occupied stay. It is not
`vX.Y.Z`, it is not latest Oasis, and it must not be marked as an Oasis
release.

The artifact may attach the camp source tree, a SHA-256 manifest, and notes
that list which surfaces are inherited from the published Oasis and which
remain laboratory. It must not rebuild or replace the Oasis native bytes.

## Inspection

```sh
centl-mirage camps
centl-mirage camps CAMP-001
scripts/oasis.py --inspect
```

These commands report published Oasis identity, camp occupation, and blockers.
They never declare Oasis.

Durable records live under [`docs/camps/`](camps/README.md).
