# GREAT — escaped_small_theorems

**Grade:** GREAT
**Rules that fired:** escaped_small_theorems, certified_hard_witness
**When:** 20260815T093532Z

## What was found

```text
4/12721 = 1/3231 + 1/202476 + 1/7727091588
```

| field | value |
|---|---|
| n or p | 12721 |
| layer | window |
| method | fab(1,3) |
| kind | fab |
| k | None |
| bound | None |

## Why this was filed

The small proved shifts (k = 3, 7, 11, 15 and the p+4 / 4p+1 filters) all missed. A later construction still found a solution. That is the remaining shape of the conjecture: hard primes that escape the easy theorems.

An explicit Egyptian-fraction identity for a Mordell-hard prime, checked by the exact integer test 4xyz = n(yz+xz+xy).

## How to check

If there are three denominators x, y, z, confirm the integer identity

```text
4 · x · y · z  =  n · (y z + x z + x y)
```

with any exact calculator (including `centl es solve n`). Do not trust a
floating-point check. A hunt summary with unsolved = 0 is coverage of a
finite interval, not a proof of the conjecture.

## Claim boundary

Erdős–Straus remains open unless a LETTER file named `universal_strike`
points at a complete deposited proof.
