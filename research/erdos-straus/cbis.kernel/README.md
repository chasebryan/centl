# cbis.kernel

**CB Inverse Sieve.** The ES+ engine. Entirely C.

It builds the inverse signed-box cover \(\mathcal C_K\) and keeps only
the complement: the letter spectrum \(\Lambda_K\). GREAT is not stored.
It does not prove Erdős–Straus.

The name follows `cbap` (CB + a short method tag). It is not
`newcbap`. The method is the sieve in
[`../ES-plus/LETTER-EQUATION.md`](../ES-plus/LETTER-EQUATION.md).

## What it does

Each window is a **spectrum × lane matrix**. Rows are the three
Mordell-hard CRT pairs from cbap. Columns are separate algorithms that
write into one shared cover. A letter is a prime no lane marked.

| lane | source | job |
| --- | --- | --- |
| **W** | bb / CC window | \(4p+1\), \(p+4\), \(fab(a,b\le 11)\). Runs first. |
| **I** | ES+ signed box | \(\delta_k\) on survivors, every admissible \(k\le K\). |
| **N** | CC / cbap NR | external-nonresidue and aligned shifts; \(k\) may exceed \(K\). |
| **L** | Type A/B | López prime-modulus traps. A hit is a real witness. |

W kills almost every GREAT. I, N, and L only see the unmarked residual.
The cover only grows. The letter stamp does not regress.

```sh
./cbis go --k-max 400 --step 50000
```

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
