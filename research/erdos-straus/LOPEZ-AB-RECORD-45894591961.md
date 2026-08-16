# Exact Type A and Erdős–Straus certificate for p = 45,894,591,961

**Status:** exact arithmetic certificate  
**Date:** 2026-08-16  
**Context:** current deepest observed Type A/B first witness in the finite Mordell-hard census through 100 billion  
**Claim boundary:** finite record only; not a universal depth bound.

## Type A data

```text
p = 45,894,591,961
d = 26
n = 509
K = dn = 13,234
m = 4dn-1 = 52,935
q = 866,999
```

The defining congruence is certified by the exact identity

```text
p + 4d
= 45,894,592,065
= 866,999 * 52,935
= q * (4dn-1).
```

Therefore

```text
p == -4d (mod 4dn-1),
```

so this is a López Type A witness.

The bounded layer census finds no Type A or Type B witness for this prime at any `K < 13,234`, and the independent complete square-root auditor returns the same first depth.

## Constructive Type A solution

For a Type A certificate

```text
p = (4dn-1)q - 4d,
```

define

```text
u = nq - 1
v = np.
```

Here

```text
u = 441,302,490
v = 23,360,347,308,149.
```

The standard Type A denominators are

```text
x = du
  = 11,473,864,740

y = dv
  = 607,369,030,011,874

z = duv
  = 268,033,465,293,124,725,766,260.
```

They satisfy the exact rational identity

```text
4 / 45,894,591,961
=
1 / 11,473,864,740
+
1 / 607,369,030,011,874
+
1 / 268,033,465,293,124,725,766,260.
```

No floating-point arithmetic is involved.

## Algebraic verification

The Type A construction reduces to

```text
u(4dn-1) = np+1.
```

For the present values,

```text
441,302,490 * 52,935
=
23,360,347,308,150
=
509 * 45,894,591,961 + 1.
```

Consequently

```text
4dnu = u + np + 1,
```

which after substituting `v=np` is exactly the identity needed for

```text
4/p = 1/(du) + 1/(dv) + 1/(duv).
```

This certificate is attached to the 100-billion Type A/B census as the exact decomposition associated with the current finite depth record.