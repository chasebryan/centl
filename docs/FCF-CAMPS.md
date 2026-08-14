# FCF Camps

**Status:** authoritative FCF stay policy
**Scope:** durable, bounded stays when a new Oasis cannot honestly be declared
**SemVer effect:** none
**Oasis assurance effect:** none
**Publication authority:** none

> A Camp is a place to stay. It is not an Oasis.

## Verdict first

Oasis is **not dead**.

CENTL v0.14.0 remains the published Oasis release. A later exact identity can
still earn Oasis if it contains the current oasis tip, satisfies the complete
Oasis gate, and is published by the official human-reviewed path. Camps do not
close that path, weaken it, or inherit it.

What **is** true of the current laboratory expedition is narrower:

- this identity is not on `oasis`;
- it is not a new SemVer product identity;
- its laboratory surfaces exceed the v0.14.0 stable-product boundary;
- release-blocking Security-tab findings still exist on the default branch
  analysis ref until those workflow remediations land;
- declaring Oasis here would require skipping, weakening, or faking a gate.

So Oasis is not possible **for this expedition as a whole**, and it may never
be possible **as a whole**. That is why Camps exist. It is not a reason to
pretend Oasis can never be earned again by a later, thinner, reviewed identity.

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
- a SemVer tag, GitHub Release, or substitute for `vX.Y.Z`;
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

1. Oasis inspect reports blockers that this expedition cannot honestly clear
   as a whole without weakening a gate or dropping the oasis tip.
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
         | later: stabilize + satisfy the complete Oasis gate
         v
       oasis
         |
         v
 stable release / tag
```

Leaving a Camp toward Oasis still requires the official Oasis path. Occupying
a Camp does not shorten it.

## Inspection

```sh
centl-mirage camps
centl-mirage camps CAMP-001
scripts/oasis.py --inspect
```

These commands report published Oasis identity, camp occupation, and blockers.
They never declare Oasis.

Durable records live under [`docs/camps/`](camps/README.md).
