# Small-selector hypothesis for residual Type A/B fiber kernels

**Status:** active proof-mining experiment  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note introduces a falsifiable finite diagnostic. It does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

This note continues the reduction developed in [SHADOW-KERNEL.md](SHADOW-KERNEL.md) and [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md).

## 1. Motivation

The candidatewise search through `k<=1200` found reduced avoiding progressions for all `41,470` directly novel candidates. A separate coordinate analysis showed that every certified solution lies within at most nine guided prime-power coordinate changes of a simple unary-safe basepoint.

Fiber peeling goes further: it removes prime-power coordinates by theorem, without consulting the stored avoiding witness. The remaining obstruction is a small-prime residual kernel.

The next question is deliberately simple:

> Are those residual kernels already satisfiable by a tiny fixed menu of ordinary integer parameter values?

If so, the global-looking covering problem may admit a surprisingly small selector mechanism after the fiber exterior is removed.

## 2. Residual kernel

Fix a directly novel candidate

\[
x=r+Ls.
\]

After exact augmented fiber peeling, suppose the residual prime set is

\[
P_{\rm ker}=\{p_1,\ldots,p_m\}
\]

with residual forbidden constraints

\[
s\bmod q_j\in R_j.
\]

An integer selector `s0` solves the residual kernel if

\[
s_0\bmod q_j\notin R_j
\]

for every residual edge and, for each residual prime `p` not dividing `L`,

\[
r+Ls_0\not\equiv0\pmod p.
\]

Once such a residual assignment is fixed, the exact fiber-peeling theorem extends it backward across the peeled coordinates. Thus a selector that solves the residual kernel gives an independent constructive proof of a reduced avoiding class for that candidate.

## 3. Finite small-selector experiment

The automated analyzer tests the fixed menu

\[
\mathcal S_B=\{0,\pm1,\pm2,\ldots,\pm B\}
\]

in increasing absolute value, with a deterministic tie order.

For each directly novel candidate it records:

- whether fiber peeling already empties the kernel;
- whether some `s0 in S_B` solves the residual kernel;
- the first selector found;
- the smallest absolute selector radius needed;
- the distribution of selectors across all nonempty residual kernels;
- any residual kernels not solved by the finite menu.

The default experimental bound is `B=64`.

A failure of this finite selector menu is **not** a counterexample to DSC-P. It would only mean that this particularly simple post-peeling mechanism is insufficient.

## 4. Why a positive result would matter

Suppose a tiny fixed selector set solved every residual kernel over a large exact range. That would suggest a much stronger theorem architecture than raw witness search:

\[
\boxed{
\text{direct novelty}
\to
\text{fiber peel}
\to
\text{tiny residual kernel}
\to
\text{small selector}
\to
\text{reduced avoiding class}.
}
\]

The computational objective is not to replace proof with a lookup table. It is to identify which local residue values repeatedly survive, then derive the arithmetic reason.

A particularly strong pattern would be the existence of a very small universal set such as

\[
\{0,1,-1,2,-2\}
\]

or another bounded menu independent of `k`. Such an observation would become a theorem target, not a theorem by itself.

## 5. Falsification value

This test can fail cleanly in several useful ways:

1. a residual kernel requires a selector outside the tested range;
2. selector radii grow rapidly with `k`;
3. different kernel signatures require unrelated selector values;
4. the small-selector phenomenon disappears past the current finite frontier.

Any of those outcomes would teach us where the apparent low local complexity breaks.

## 6. Automation

The implementation is [`shadow_small_selector_analyzer.py`](shadow_small_selector_analyzer.py). It reconstructs the pullback system and performs fiber peeling independently of the stored reduced witness. It then tests only the residual kernel against the fixed selector menu.

The direct-shadow GitHub Actions workflow runs this stage before CENTL certification and freezes its JSON/report into the hashed research artifact.

## 7. Current theorem target

The larger target remains DSC-P:

\[
\text{not directly shadowed}
\Longrightarrow
\text{reduced avoiding class}.
\]

The small-selector experiment asks whether the missing proof can be compressed still further:

\[
\boxed{
\text{every residual fiber kernel belongs to a locally solvable family with a bounded selector mechanism.}
}
\]

If the data supports that statement, the next task is to classify the selector by kernel signature and prove why the surviving local residue exists.
