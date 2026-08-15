#!/usr/bin/env python3
"""Independent reconstruction and direct-novelty verification of a DSC counterexample.

This verifier does not take the target constants as axioms. It starts from
three ancestry-minimal q=3 local factor pairs of the three modulo-9 species,
CRT-glues their target coordinates, reconstructs the target factor pair and
candidate progression, verifies the three-class union cover, and then checks
every earlier layer for a direct shadow.

Its direct-shadow enumeration deliberately differs from the C++ primary:
- first prune uses only tau(j) <= 2*sqrt(j), hence q_j <= 4*floor(sqrt(j))
  is necessary for full coverage;
- surviving j are factored independently by trial division;
- exact T_j is reconstructed before the final class-by-class test.
"""
from __future__ import annotations

import argparse
import json
import math
from functools import lru_cache
from pathlib import Path


def divisors(n: int) -> list[int]:
    lo, hi = [], []
    for d in range(1, math.isqrt(n)+1):
        if n%d == 0:
            lo.append(d)
            if d*d != n:
                hi.append(n//d)
    return lo + hi[::-1]


@lru_cache(maxsize=None)
def trap_set(j: int) -> frozenset[int]:
    m=4*j-1
    return frozenset(r for e in divisors(j) for r in ((-e)%m,(-4*e)%m))


def crt_pair(a: int,m: int,b: int,n: int) -> tuple[int,int]:
    g=math.gcd(m,n)
    if (b-a)%g:
        raise ValueError("incompatible CRT")
    mm,nn=m//g,n//g
    step=0 if nn==1 else (((b-a)//g)*pow(mm,-1,nn))%nn
    mod=m*nn
    return (a+m*step)%mod,mod


def crt_many(congs: list[tuple[int,int]]) -> tuple[int,int]:
    a,m=congs[0]
    a%=m
    for b,n in congs[1:]:
        a,m=crt_pair(a,m,b,n)
    return a,m


def ancestry_minimal(j: int,u: int) -> bool:
    m=4*j-1
    for mi in divisors(m):
        if mi<3 or mi>=m or mi%4!=3:
            continue
        i=(mi+1)//4
        if u%mi in trap_set(i):
            return False
    return True


def factor_trial(n: int, primes: list[int]) -> list[tuple[int,int]]:
    x=n; out=[]
    for p in primes:
        if p*p>x:
            break
        if x%p==0:
            e=0
            while x%p==0:
                x//=p; e+=1
            out.append((p,e))
    if x>1:
        out.append((x,1))
    return out


def divisor_list_from_factor(fac: list[tuple[int,int]]) -> list[int]:
    ds=[1]
    for p,e in fac:
        old=ds
        ds=[]
        pe=1
        for _ in range(e+1):
            ds.extend(d*pe for d in old)
            pe*=p
    return ds


def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,default=Path("dsc-counterexample-output"))
    args=ap.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)

    # One local factor pair of each q=3 mod-9 species.
    # (w,a) products are m_j+1 and each associated trap is ancestry-minimal.
    local=[
        {"p":11,"j":25,"w":20,"a":5,"u":79,"class":1},   # (2,5) mod 9
        {"p":31,"j":70,"w":14,"a":20,"u":265,"class":0}, # (5,2) mod 9
        {"p":83,"j":187,"w":44,"a":17,"u":703,"class":2},# (8,8) mod 9
    ]

    W,B=crt_many([(row["w"]%row["p"],row["p"]) for row in local])
    A,B2=crt_many([(row["a"]%row["p"],row["p"]) for row in local])
    assert B==B2==11*31*83
    assert (W,A)==(23450,764)
    assert (W*A-1)%B==0

    M=W*A-1
    assert M%4==3
    k=(M+1)//4
    assert k==4478950
    # A is divisible by 4, so W is a plain divisor of k and -W is a target trap.
    assert A%4==0 and k%W==0
    t=(M-W)%M
    assert t in trap_set(k)
    assert math.gcd(t,M)==1

    h=1
    r,L=crt_pair(h,840,t,M)
    assert L==math.lcm(840,M)==5016423720
    assert r==1236166681

    union=0
    row_checks=[]
    for row in local:
        j=row["j"]; m=4*j-1
        assert row["w"]*row["a"]==m+1
        assert (m-row["w"])%m==row["u"]
        assert row["u"] in trap_set(j)
        assert ancestry_minimal(j,row["u"])
        q=m//math.gcd(L,m)
        assert q==3
        classes=[]
        for s in range(3):
            if (r+L*s)%m in trap_set(j):
                classes.append(s)
        assert row["class"] in classes
        union |= 1<<row["class"]
        row_checks.append({**row,"q":q,"actual_hit_classes":classes})
    assert union==7

    # Independent exhaustive direct-shadow scan.
    lim=math.isqrt(k)+2
    primes=[]
    for n in range(2,lim+1):
        if all(n%p for p in primes if p*p<=n):
            primes.append(n)

    crude_survivors=0
    exact_size_survivors=0
    direct=[]
    for j in range(1,k):
        m=4*j-1
        q=m//math.gcd(L,m)
        # tau(j) <= 2*floor(sqrt(j)); hence |T_j|<=2*tau(j)<=4*floor(sqrt(j)).
        if q>4*math.isqrt(j):
            continue
        crude_survivors+=1
        fac=factor_trial(j,primes)
        ds=divisor_list_from_factor(fac)
        T={(-e)%m for e in ds}
        T.update((-4*e)%m for e in ds)
        if q>len(T):
            continue
        exact_size_survivors+=1
        if all((r+L*s)%m in T for s in range(q)):
            direct.append({"j":j,"m":m,"q":q,"trap_size":len(T)})

    result={
        "status":"independent reconstructed DSC counterexample verification",
        "local_rows":row_checks,
        "target_factor_pair":[W,A],
        "target_required_modulus":B,
        "k":k,"m":M,"h":h,"t":t,"r":r,"L":L,
        "q3_union_mask":union,
        "earlier_layers":k-1,
        "crude_sqrt_bound_survivors":crude_survivors,
        "exact_trap_size_survivors":exact_size_survivors,
        "direct_shadow_sources":len(direct),
        "direct_shadow_rows":direct,
        "verdict":"DIRECTLY_NOVEL_UNION_SHADOW" if not direct else "DIRECT_SHADOWED",
        "claim_boundary":(
            "This falsifies Direct-Shadow Completeness if the independent and primary exact checks agree. "
            "It does not falsify Lopez Type A/B coverage or the Erdos-Straus conjecture."
        ),
    }
    (args.out/"dsc-counterexample-independent-verifier.json").write_text(
        json.dumps(result,indent=2,sort_keys=True)+"\n"
    )
    print(json.dumps(result,indent=2,sort_keys=True))
    if direct:
        raise SystemExit(2)


if __name__=="__main__":
    main()
