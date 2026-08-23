# Dual ledger: proof ⊕ disproof

Hardness measures tell us where to look. Certificates tell us what is true. Approximates never certify.

## Densities (staged, not complementary)

| Stage | Density among primes |
|---|---|
| Elementary CC cover (even ∪ 4p+3 ∪ 3p+2 ∪ 8p+5) | **7/8** |
| Post-CC residual | **1/8** |
| Intermediate classical modular structure | **3/32** |
| Mordell hard core \(\{1,121,169,289,361,529\}\pmod{840}\) | **1/32** |

`7/8` and `1/32` are **not** a partition. \(7/8 + 3/32 + 1/32 = 1\).

## Tickets

| Ticket | Side | What it is |
|---|---|---|
| **Class theorem** | Proof | One of **four** permanent elementary identities. Not incremented per prime. |
| **Class-covered instance** | Proof | A prime cleared by applying a class theorem. Not a new class proof. |
| **Constructive instance** | Proof | Corridor / two-target \(k\) / complete-search witness. Does not prove ES. |
| **Certified counterexample (DIS)** | Disproof | Divisor-complete search emptied \(x\in[\lfloor n/4\rfloor+1,\lfloor 3n/4\rfloor]\). One ticket ends the game. |
| **Incomplete residual / God's Letter** | Residual | Menu miss; region not complete. Not a disproof. |
| **Victory certificate** | Proof | Uniform covering of the six Mordell classes. None yet. |

## DIS tickets

A DIS artifact must be paranoid: exact \(x_{\min},x_{\max}\), \(x\)-count, completeness theorem/version, factorization algorithm, source commit, primality method, replay hash, content hash, independent verifier status, `approximates_certify: false`. Schema `centl26.erdos_straus.disproof/v2`.

## Weighing

- One certified counterexample outweighs every instance.
- Class-covered instance counts are applications of four theorems, not “a million class proofs.”
- The census through \(10^7\)–\(10^8\) is not a verification record (Salez 2014: \(10^{17}\)).
- Game is `OPEN` until a Mordell covering **or** one DIS ticket.
