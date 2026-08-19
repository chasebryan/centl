#!/usr/bin/env python3
"""Independent finite realization regression for the k=59 class-conditioned atlas."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

import classify_k59_class_conditioned_states as atlas
import classify_k59_states as core

MOD=59
TYPE_I=(-pow(4,-1,MOD)) % MOD
EXPECTED_100K={
    1:{"hit":19,"miss":26},
    121:{"hit":22,"miss":28},
    169:{"hit":12,"miss":31},
    289:{"hit":13,"miss":32},
    361:{"hit":23,"miss":17},
    529:{"hit":28,"miss":22},
}


def sieve_flags(n:int)->bytearray:
    bs=bytearray(b"\x01")*(n+1)
    if n>=0: bs[0]=0
    if n>=1: bs[1]=0
    for q in range(2,math.isqrt(n)+1):
        if bs[q]:
            bs[q*q:n+1:q]=b"\x00"*(((n-q*q)//q)+1)
    return bs


def primes_up_to(n:int)->list[int]:
    bs=sieve_flags(n)
    return [q for q in range(2,n+1) if bs[q]]


def factor(n:int,trial:list[int])->dict[int,int]:
    out={}
    x=n
    for q in trial:
        if q*q>x: break
        if x%q: continue
        e=0
        while x%q==0:
            x//=q; e+=1
        out[q]=e
    if x>1: out[x]=out.get(x,0)+1
    return out


def divisor_box(fac:dict[int,int])->set[int]:
    reach={1}
    for q,e in fac.items():
        vals={pow(q,j,MOD) for j in range(2*e+1)}
        reach={(x*y)%MOD for x in reach for y in vals}
    return reach


def state_after_consuming_seed(fac:dict[int,int],seed:int)->tuple[int,int]:
    remaining=dict(fac)
    state=(1,0)
    for q in atlas.factor_seed(seed):
        if remaining.get(q,0)<1:
            raise ValueError(f"factorization missing mandatory seed factor q={q}, seed={seed}")
        state=core.transition(state,core.LOG[q%MOD])
        remaining[q]-=1
        if remaining[q]==0:
            del remaining[q]
    for q,e in remaining.items():
        if q==MOD:
            raise ValueError("nonunit factor 59 in C59")
        a=core.LOG[q%MOD]
        for _ in range(e):
            state=core.transition(state,a)
    return state


def analyze(limit:int)->dict[str,object]:
    flags=sieve_flags(limit)
    hard=[p for p in range(2,limit+1) if flags[p] and p%840 in atlas.HARD_CLASSES]
    trial=primes_up_to(math.isqrt((limit+MOD)//4)+2)
    closures={seed:atlas.closure(seed) for seed in atlas.SEEDS}
    mismatches=[]
    outcomes={h:Counter() for h in atlas.HARD_CLASSES}
    realized_states={h:set() for h in atlas.HARD_CLASSES}

    for p in hard:
        h=p%840
        seed=atlas.CLASS_SEED[h]
        C=(p+MOD)//4
        if C%seed:
            mismatches.append({"kind":"class-seed-missing","p":p,"h":h,"seed":seed,"C":C})
            continue
        fac=factor(C,trial)
        D=divisor_box(fac)
        direct_hit=TYPE_I in D or ((-C)%MOD) in D
        state=state_after_consuming_seed(fac,seed)
        if state not in closures[seed]:
            mismatches.append({
                "kind":"state-outside-class-closure","p":p,"h":h,"seed":seed,"C":C,
            })
            continue
        predicted_hit=not core.is_miss(state)
        if direct_hit!=predicted_hit:
            mismatches.append({
                "kind":"class-state-vs-direct","p":p,"h":h,"seed":seed,"C":C,
                "factorization":fac,"direct_hit":direct_hit,"predicted_hit":predicted_hit,
            })
        outcomes[h]["hit" if direct_hit else "miss"]+=1
        realized_states[h].add(state)

    outcome_json={
        str(h):{"hit":outcomes[h]["hit"],"miss":outcomes[h]["miss"]}
        for h in atlas.HARD_CLASSES
    }
    if limit==100_000:
        actual={h:{"hit":outcomes[h]["hit"],"miss":outcomes[h]["miss"]} for h in atlas.HARD_CLASSES}
        if actual!=EXPECTED_100K:
            mismatches.append({"kind":"100k-outcome-regression","actual":actual,"expected":EXPECTED_100K})

    return {
        "analysis":"k59-class-conditioned-structural-regression-v1",
        "limit":limit,
        "hard_primes":len(hard),
        "outcomes_by_hard_class":outcome_json,
        "realized_state_counts_by_hard_class":{
            str(h):len(realized_states[h]) for h in atlas.HARD_CLASSES
        },
        "class_seed":{str(h):atlas.CLASS_SEED[h] for h in atlas.HARD_CLASSES},
        "mismatches":len(mismatches),
        "mismatch_examples":mismatches[:20],
        "claim":"finite independent realization regression of range-free class-conditioned closures",
    }


def main()->int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--limit",type=int,default=100_000)
    ap.add_argument("--json",action="store_true")
    args=ap.parse_args()
    report=analyze(args.limit)
    if args.json:
        print(json.dumps(report,indent=2,sort_keys=True))
    else:
        for key,value in report.items(): print(f"{key}: {value}")
    return 1 if report["mismatches"] else 0


if __name__=="__main__":
    raise SystemExit(main())
