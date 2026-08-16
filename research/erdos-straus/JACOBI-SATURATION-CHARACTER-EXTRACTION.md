# Jacobi-kernel saturation and composite character extraction

**Status:** proved general lemma plus exact composite route atlas  
**Date:** 2026-08-16  
**Primary classifier:** `classify_jacobi_saturation_extractions.py`  
**Independent realization regression:** `verify_jacobi_saturation_extractions.py`  
**Depends on:** QR-saturating seed lemma, reciprocity-route barrier, current route-source atlas  
**Claim boundary:** these are conditional fixed-shift and character-extraction theorems. They do not prove a universal shift ceiling or Erdős-Straus.

## 1. Jacobi-kernel saturation lemma

Let k be any odd positive integer with

`k = 3 mod 4`

and `gcd(k,p)=1`. Put

`C_k = (p+k)/4`.

Let S be a mandatory divisor of C_k and write

`H_k = {u in U(k) : Jacobi(u/k)=+1}`.

Assume

`{D mod k : D divides S^2} = H_k`.

Then S is called Jacobi-saturating modulo k.

### Theorem

If S divides C_k and is Jacobi-saturating, fixed k misses if and only if every prime factor ell of C_k satisfies

`Jacobi(ell/k)=+1`.

### Proof

For k=3 mod4,

`Jacobi(-1/k)=-1`.

The Type-I target `-1/4` therefore lies in the negative Jacobi coset.

If a prime factor ell of C_k has Jacobi character -1, multiplying ell by the seed divisors that realize all of H_k realizes the complete negative coset. In particular it realizes the Type-I target, so fixed k hits.

Thus a miss forces every prime factor of C_k into H_k.

Conversely, if every prime factor lies in H_k, every divisor of C_k^2 lies in H_k. Then C_k has positive Jacobi character and `-C_k` has negative character, so neither Type I nor Type II is present. Fixed k misses.

## 2. Character identity at a saturated miss

Modulo k,

`C_k = p/4`.

Since 4 is a square,

`Jacobi(C_k/k)=Jacobi(p/k)`.

Because p is 1 modulo4, Jacobi reciprocity gives

`Jacobi(p/k)=Jacobi(k/p)`.

Therefore every Jacobi-saturated miss forces

`Jacobi(k/p)=+1`.

For prime k this is exactly the QR-saturation promotion rule.

For composite k it gives a product of prime characters. If every odd-exponent prime factor of k except one has a character fixed by the hard class, the remaining prime character is determined exactly.

This is how a composite fixed-shift obstruction can create a new prime routing source.

## 3. Composite saturation atlas through k<=5000

Using the current proved source inventory, the exact scan finds

- 11 single-source composite Jacobi-saturation branches;
- 7 genuine two-source composite Jacobi-saturation branches.

The k=15 branches reproduce the already-known Jacobi-plus support geometry and do not extract a new prime character because both 3 and5 are already controlled by the hard modulus.

The new value lies in composite shifts with one character factor outside 840.

## 4. New extracted prime-character branches

### 4.1 h=121 - q47 route through k=39 extracts q13

Take

`p mod47 = 8`.

Then 47 divides C39. The h=121 class seed at k=39 is10, so the routed seed is

`S = 10*47 = 470`.

Its square-divisor residues fill the entire Jacobi-plus kernel modulo39.

Since

`39 = 3*13`

and h=121 fixes the mod3 contribution positively, a k=39 miss forces

`(13/p)=+1`.

This extends the q13 route mechanism to an h=121 branch.

### 4.2 h=169 - q23 route through k=111 extracts q37

Take

`p mod23 = 4`.

Then 23 divides C111. The h=169 class seed is70, so

`S = 70*23 = 1610`.

The seed is Jacobi-saturating modulo

`111 = 3*37`.

The h=169 class fixes the mod3 character positively. Hence a k=111 miss forces

`(37/p)=+1`.

Thus q37 becomes a new conditional character-routing source.

### 4.3 q11 and q23 through k=51 extract q17 on h=169,289,529

For each of h=169,289,529, impose

`p mod11 = 4`

and

`p mod23 = 18`.

Both 11 and23 divide C51. The class seed is5, so

`S = 5*11*23 = 1265`.

No single routed source saturates k=51, but the pair does. Since

`51 = 3*17`

and all three hard classes fix the mod3 contribution positively, a k=51 miss forces

`(17/p)=+1`.

This creates q17 as a new conditional source on three hard classes.

### 4.4 h=289 - q11 and q47 through k=39 extract q13

With

`p mod11 = 5`

and

`p mod47 = 8`,

both source primes enter C39. The class seed2 becomes

`S = 2*11*47 = 1034`,

which Jacobi-saturates modulo39. A k=39 miss therefore forces

`(13/p)=+1`.

This branch is consistent with the earlier q13 theorem obtained from the q11-to-k39 route, but now has a collective seed explanation.

### 4.5 h=289 - q11 and q31 through k=215 extract q43

Impose

`p mod11 = 5`

and

`p mod31 = 2`.

Then 11 and31 divide C215. The h=289 class seed42 becomes

`S = 42*11*31 = 14322`.

The seed Jacobi-saturates modulo

`215 = 5*43`.

The hard class fixes the mod5 contribution positively, so a k=215 miss forces

`(43/p)=+1`.

Thus q43 becomes a new conditional routing source.

### 4.6 h=529 - q11 and q23 through k=171 extract q19

Impose

`p mod11 = 5`

and

`p mod23 = 13`.

Both factors enter C171. The class seed35 becomes

`S = 35*11*23 = 8855`.

Since

`171 = 3^2*19`,

the square power of3 disappears from the Jacobi character. A k=171 miss therefore forces directly

`(19/p)=+1`.

This promotes q19 on a new h=529 branch.

## 5. Exact extracted-source list

The eight extracted branch entries are

- h=121, k39, source47 residue8 -> q13 positive;
- h=169, k51, sources11/23 residues4/18 -> q17 positive;
- h=169, k111, source23 residue4 -> q37 positive;
- h=289, k39, sources11/47 residues5/8 -> q13 positive;
- h=289, k51, sources11/23 residues4/18 -> q17 positive;
- h=289, k215, sources11/31 residues5/2 -> q43 positive;
- h=529, k51, sources11/23 residues4/18 -> q17 positive;
- h=529, k171, sources11/23 residues5/13 -> q19 positive.

The independent finite regression realizes every branch below p=2,000,000, finds destination misses on every branch, and verifies that every such miss has the extracted positive prime character.

## 6. Strategic consequence

The route graph is no longer restricted to prime fixed shifts serving as character sources.

The exact mechanism is now

`source characters -> routed factors -> composite Jacobi saturation -> composite miss -> extracted prime character -> new source route`.

This generates new moduli such as17,37,43 that were not present in the original small-prime fixed-shift atlas.

The next useful search is recursive: route these extracted primes into new companions, score whether they create QR/Jacobi saturation or shrink an exceptional exact state, and stop branches when a newly saturated destination conflicts with an already fixed negative character or exact residue mask.

Erdős-Straus remains open.
