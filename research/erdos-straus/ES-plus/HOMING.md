# The homing equation

A window-layer letter cannot sit on a prime that hits 4p+1 or p+4.
Those two tests fire exactly when 4p+1 or p+4 has a prime factor
≡ 3 (mod 4). So the only primes W can miss are those for which
**both** 4p+1 and p+4 have every prime factor ≡ 1 (mod 4).

Write Sigma_1 for that semigroup, and

    R = { hard primes p : p+4 is in Sigma_1 and 4p+1 is in Sigma_1 }

A W-survivor is a point of R that also evades every fab pair a,b ≤ 11.
That is the missile lock.

Generate R by walking S = p+4 through numbers ≡ 1 (mod 4):

    S in Sigma_1
    p = S-4 is a Mordell-hard prime
    4S-15 = 4p+1 is in Sigma_1

Then fire fab. If fab misses, fire I (signed box), N (NR), L (Lopez).
If those miss, LETTER.

The 0-to-infinity sweep still runs. Homing never visits a linear W-hit.
It spends time only in R, which is about a quarter of the hard primes
and the only place a window-layer letter can live.

See `w-census/W-CENSUS.md` for the split that forced this equation.
