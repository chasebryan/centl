# cbis.kernel

**CB Inverse Sieve.** The ES+ engine. Entirely C.

It builds the inverse signed-box cover \(\mathcal C_K\) and keeps only
the complement: the letter spectrum \(\Lambda_K\). GREAT is not stored.
It does not prove Erdős–Straus.

The name follows `cbap` (CB + a short method tag). It is not
`newcbap`. The method is the sieve in
[`../ES-plus/LETTER-EQUATION.md`](../ES-plus/LETTER-EQUATION.md).

## What it does

For each window \((L,H]\):

1. Factor every \(C\) that could produce a prime in the window.
2. For each admissible \(k\le K\), if \(\delta_k(C)=0\), mark \(p=4C-k\).
3. Mark the cheap window set \(W_K\) (\(4p+1\), \(p+4\), \(fab(a,b\le 11)\)).
4. Unmarked Mordell-hard primes are letters. They are written at once.

A letter found this way is the same set member as a forward-menu letter
at the same \(K\). The stamp does not regress.

## Commands

First session starts at **0**. Later sessions **resume**. `--random`
sets a random start only when there is no seed yet.

```sh
make
./cbis
./cbis go
./cbis go --random
./cbis status
./cbis letters
./cbis solve 2521
./cbis self-test
```

From the CENTL root:

```sh
./centl es cbis
./centl es cbis go --random
./centl es cbis letters
```

Ctrl+C stops after the current window and writes the seed. Letters live
in `cbis.kernel/letters/`.
