# Dual ledger: proof ⊕ disproof

The observatory now classifies every prime on **two ledgers**. Approximates never certify.

## Tickets

| Ticket | Side | What it is |
|---|---|---|
| **Class proof** | Proof | Infinite residue identity (even, 4p+3, 3p+2, 8p+5). Density 7/8. |
| **Instance proof** | Proof | One verified \(4/p=1/x+1/y+1/z\). Does not prove the conjecture. |
| **Certified counterexample** | Disproof | Divisor-complete search emptied \(x\in[\lfloor n/4\rfloor+1,\lfloor 3n/4\rfloor]\) for \(n\le 10^4\). One ticket ends the game. |
| **Incomplete residual** | Residual | Menu miss, region not complete. God's Letter lives here. Not a disproof. |

## Weighing

- One certified counterexample outweighs every instance proof.
- Instance piles do not prove Erdős–Straus.
- Covered density is Dirichlet 7/8, residual Mordell 6/192 = 1/32.
- Game is `OPEN` until a covering of the six Mordell classes **or** one certified counterexample.

## Approximates

Floating-point \(4/n \approx 1/x+1/y+1/z\) is **never** a certificate. `approximate_identity_is_certificate` is identically false. Only `4xyz = n(xy+xz+yz)` in `BigInt`.

## Expansion engines

After the signed-box corridor misses:

1. Two-target \(k\equiv 3\pmod 4\), \(x=(n+k)/4\), exact split of \(k\).
2. For \(n\le 10^4\), divisor-complete search using \((Ay-nx)(Az-nx)=n^2 x^2\).

A proof of ES is still a covering of \(\{1,121,169,289,361,529\}\pmod{840}\). This machine decides instances and files honest tickets. It does not vote the conjecture true.
