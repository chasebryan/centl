# CentL26 approved-design contract

Status: enforced baseline for the user-approved CentL26 interface.

This contract prevents the approved CentL26 visual design from drifting during
backend, packaging, or capability work. It does not claim that a hash proves a
design is good. Human review establishes the approved design; the contract then
proves that the reviewed source bytes remain unchanged.

## Protected surface

[`design/centl26/approved-design.json`](../design/centl26/approved-design.json)
binds SHA-256 digests to the complete visual source boundary:

- the CentL26 workbench CSS;
- the server-rendered workbench template;
- the interaction and layout-state JavaScript;
- the macOS application icon in vector and packaged raster form.

The same manifest independently records semantic invariants for the properties
that define the approved experience: the white visual palette, CentL26 blue and
scientific status colors, a full-viewport application frame, no document-level
scrolling, collapsed advanced panes on first launch, internal notebook scrolling,
the command palette, and FCF identity.

Exact hashes catch every byte change. Semantic checks make the most important
design decisions legible and prevent a routine digest refresh from silently
discarding them.

## Normal verification

Run the focused gate:

```sh
make centl26-design-check
```

Run its regression tests:

```sh
make centl26-design-contract-test
```

`make quality` includes the focused gate. `make centl26-app` checks it before
packaging the native application, and the standard `make test` target includes
the contract regression suite. The protected surface and its contract are owned
by the repository owner through `CODEOWNERS`. The dedicated GitHub workflow runs
the gate and regression tests whenever a protected visual source or contract file
changes.

A hash failure is not an instruction to refresh the manifest. It means that the
approved interface changed and requires either restoration or intentional review.

## Intentional design-update workflow

1. Make the proposed visual change on a dedicated branch.
2. Confirm that the contract fails for the expected protected file.
3. Exercise the complete initial, result, palette, explorer, inspector, console,
   error, exact, bounded, physics, and research states.
4. Review at both baseline laptop viewports: `1366x768` and `1440x900`. Confirm
   that the page itself does not scroll, notebook results scroll internally, the
   first-launch layout remains calm, keyboard focus remains visible, and reduced
   motion remains usable.
5. Obtain explicit approval from the product/design owner. Ordinary refactoring
   approval is not visual-design approval.
6. Record the approved bytes against the continuing CentL26 release channel and
   a concrete reason:

   ```sh
   make centl26-design-approve \
     DESIGN_VERSION=CentL26 \
     DESIGN_REASON='Approved refinement of the notebook result hierarchy.'
   ```

7. Inspect the protected source diff and manifest diff together. The manifest
   must change only for files actually reviewed, the release must remain
   `CentL26`, and
   the change note must describe the approved visual decision.
8. Run `make centl26-design-contract-test`, `make centl26-design-check`, and the
   normal CentL26 build/test gates before committing the visual sources and
   manifest in the same change.

The approval command requires an explicit version, reason, and
`--confirm-visual-review` (supplied by the Make target). It refreshes only file
digests and approval metadata. It will refuse to update the manifest when a
semantic invariant has been removed. Changing an invariant requires a deliberate
manifest edit, matching documentation, and the same explicit visual approval.

## Contract implementation

[`scripts/centl26-design-contract.py`](../scripts/centl26-design-contract.py)
uses only the Python standard library. It rejects duplicate manifest keys,
unsorted or unsafe source paths, symlinks, malformed hashes, missing sources,
semantic violations, and byte drift. Manifest updates are canonical JSON and are
written atomically without timestamps, so equal approved inputs produce equal
contract output.

[`tests/test_centl26_design_contract.py`](../tests/test_centl26_design_contract.py)
proves that the checked-in baseline passes, unapproved drift fails, semantic
regressions cannot be approved by refreshing hashes, intentional reviewed updates
work in an isolated fixture, and update mode cannot run without explicit visual
review confirmation.
