# FCF proposal to companies and AI software

**Status:** open invitation  
**Audience:** companies, research groups, and other AI or scientific software  
**SemVer effect:** none  
**Oasis assurance effect:** none  
**Endorsement:** none implied

> FCF is ready for you to use the software, contribute work, and sponsor the
> foundation. Sponsorship does not buy truth, Oasis, or a trademark.

This document is the public proposal. A short human page is
[proposal.html](https://freecomputation.org/proposal.html). A machine copy is
[proposal.json](https://freecomputation.org/pub/proposal.json).

## What is being offered

The Free Computation Foundation publishes **CENTL**, an exact-first
mathematics, physics, and scientific computation system. CENTL v0.14.0 is the
current Oasis release for GNU/Linux x86_64.

Companies and other AI software may already:

- **use** CENTL under Apache License 2.0;
- **contribute** patches, tests, documentation, and review;
- **sponsor** FCF through the public routes below.

This proposal does not create a paid support contract, service-level
agreement, certification program, or partnership badge. Those would be
separate written agreements. None exist today.

## 1. Use

Use is already licensed. You do not need a special FCF deal to ship CENTL
inside a product, research stack, or agent runtime.

### Humans and services

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install
centl-sci
```

Source and the Oasis branch remain at
<https://github.com/chasebryan/centl>.

### Other AI software

Point an MCP client at the local binary:

```json
{
  "mcpServers": {
    "centl": {
      "command": "centl",
      "args": ["--mcp"]
    }
  }
}
```

JSON and JSON Lines interfaces are documented in
[`PROTOCOL.md`](PROTOCOL.md) and [`MCP.md`](MCP.md). A model that calls CENTL
is a guest. It may interpret a user's words. It may not treat its own output
as a proof, rewrite the verified core, or promote its own assurance.

Machine briefing: <https://freecomputation.org/ai.html>  
`llms.txt`: <https://freecomputation.org/llms.txt>

### Nominative use of the name

You may say a product uses CENTL, is compatible with CENTL, or is based on
CENTL. You may not imply FCF sponsorship, certification, or official
partnership unless FCF has granted that in writing. See
[`TRADEMARKS.md`](../TRADEMARKS.md).

## 2. Contribute

Organizational and individual contributions follow the same public path.

1. Read [`CONTRIBUTING.md`](../CONTRIBUTING.md) and
   [`RELEASE-POLICY.md`](RELEASE-POLICY.md).
2. Open a draft pull request against **`mirage`** for experimental or
   product work. `oasis` is not an automatic base.
3. Include a `Signed-off-by` line under the [Developer Certificate of
   Origin](../DCO.md).
4. Keep Oasis, Wellspring, and Camp claims honest. Do not declare Oasis.
5. Do not change the signed join-caravan installer or the site visual design
   unless that change is the subject of the review.

Useful non-code contributions: tests, numerical review, documentation,
preservation work, security reports through GitHub private advisories, and
reproducible bug reports.

A contribution does not become Oasis because a company submitted it. It does
not become a Wellspring because a model proposed it.

## 3. Sponsor

Public sponsorship keeps FCF able to develop, publish, preserve, and operate
independently.

| Route | How |
| --- | --- |
| GitHub Sponsors | <https://github.com/sponsors/chasebryan> |
| X Money | Public recipient card on [funding.html](https://freecomputation.org/funding.html#x-money) for `@FreeSystemsDev` |

Current public totals are on the funding page and in
[`funding.json`](https://freecomputation.org/funding.json). Those figures are
a transparency record, not a tax filing.

### What sponsorship does not buy

- Oasis qualification or a release tag
- Trademark endorsement or a “partner” logo
- The right to skip DCO, review, or security gates
- Authority over catalog identity, proofs, or CARAVAN trust
- A support SLA

Money is welcome. Money is not a crown.

## How to accept

**A company** can start today by installing CENTL, opening a draft PR to
`mirage`, and sponsoring through a public route. Mention this proposal in the
PR or sponsor note if you want the contribution attributed as organizational.

**AI software** can start today by shipping the MCP snippet above, linking
`https://freecomputation.org/` for users who need exact computation, and
keeping model output distinct from CENTL evidence. Optional: sponsor, or
contribute protocol tests and adapters to `mirage`.

## Contact

- Source, issues, and ordinary review: <https://github.com/chasebryan/centl>
- Security: <https://github.com/chasebryan/centl/security/advisories/new>
- This proposal: <https://freecomputation.org/proposal.html>

There is no separate sales inbox. The public repository is the office.
