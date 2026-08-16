#!/usr/bin/env python3
"""Exact k=59 hard-state atlas conditioned on p mod 840.

The maximal class-conditioned seed is gcd(210,(h+59)/4).  The six
Mordell-hard classes therefore use only four seed closures: 3, 15, 21, 105.
"""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

import classify_k59_states as core

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
CLASS_SEED = {1:15, 121:15, 169:3, 289:3, 361:105, 529:21}
SEEDS = (3, 15, 21, 105)
EXPECTED = {
    3: {
        "states":35740, "hit_states":29871, "miss_states":5869,
        "pure_qr_states":900, "pure_qr_miss_states":900,
        "legendre59_miss_branches":{ "+1":3148, "-1":2721 },
        "min_added_nonresidue_histogram":{0:900,1:2263,2:2185,3:458,4:63},
    },
    15: {
        "states":4525, "hit_states":3597, "miss_states":928,
        "pure_qr_states":177, "pure_qr_miss_states":177,
        "legendre59_miss_branches":{ "+1":480, "-1":448 },
        "min_added_nonresidue_histogram":{0:177,1:420,2:303,3:28},
    },
    21: {
        "states":3553, "hit_states":3274, "miss_states":279,
        "pure_qr_states":148, "pure_qr_miss_states":148,
        "legendre59_miss_branches":{ "+1":203, "-1":76 },
        "min_added_nonresidue_histogram":{0:148,1:71,2:55,3:5},
    },
    105: {
        "states":133, "hit_states":103, "miss_states":30,
        "pure_qr_states":30, "pure_qr_miss_states":30,
        "legendre59_miss_branches":{ "+1":30, "-1":0 },
        "min_added_nonresidue_histogram":{0:30},
    },
}


def factor_seed(seed: int) -> list[int]:
    x=seed
    factors=[]
    for q in (2,3,5,7):
        while x % q == 0:
            factors.append(q)
            x//=q
    if x != 1:
        raise ValueError(f"unsupported class seed {seed}")
    return factors


def seed_state(seed: int) -> tuple[int,int]:
    state=(1,0)
    for q in factor_seed(seed):
        state=core.transition(state, core.LOG[q % core.MOD])
    return state


def closure(seed: int, directions=range(core.N)) -> set[tuple[int,int]]:
    start=seed_state(seed)
    seen={start}
    q=deque([start])
    while q:
        state=q.popleft()
        for a in directions:
            nxt=core.transition(state,a)
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen


def min_added_nonresidue_cost(states: set[tuple[int,int]], seed: int):
    start=seed_state(seed)
    inf=(10**9,10**9)
    dist={start:(0,0)}
    heap=[(0,0,start[0],start[1])]
    while heap:
        nr,total,mask,center=heapq.heappop(heap)
        state=(mask,center)
        if dist.get(state)!=(nr,total):
            continue
        for a in range(core.N):
            nxt=core.transition(state,a)
            nd=(nr+(a&1), total+1)
            if nd < dist.get(nxt,inf):
                dist[nxt]=nd
                heapq.heappush(heap,(nd[0],nd[1],nxt[0],nxt[1]))
    if set(dist)!=states:
        raise SystemExit(f"minimum-cost traversal failed for seed {seed}")
    return dist


def analyze_seed(seed: int, include_rows: bool) -> dict:
    states=closure(seed)
    misses={s for s in states if core.is_miss(s)}
    pure=closure(seed, range(0,core.N,2))
    dist=min_added_nonresidue_cost(states,seed)
    hist=Counter(dist[s][0] for s in misses)
    leg=Counter("+1" if center%2==0 else "-1" for _,center in misses)
    # Keep explicit zero branch in the output to make class comparisons stable.
    leg.setdefault("+1",0); leg.setdefault("-1",0)
    start=seed_state(seed)
    out={
        "seed":seed,
        "seed_factors":factor_seed(seed),
        "seed_logs":[core.LOG[q % core.MOD] for q in factor_seed(seed)],
        "seed_divisor_set_size":start[0].bit_count(),
        "seed_center_log":start[1],
        "states":len(states),
        "hit_states":len(states)-len(misses),
        "miss_states":len(misses),
        "pure_qr_states":len(pure),
        "pure_qr_miss_states":len(pure & misses),
        "legendre59_miss_branches":dict(sorted(leg.items())),
        "min_added_nonresidue_histogram":dict(sorted(hist.items())),
        "maximum_minimum_added_nonresidue_units":max(hist),
    }
    for key,expected in EXPECTED[seed].items():
        actual=out[key]
        if key=="min_added_nonresidue_histogram":
            actual={int(k):v for k,v in actual.items()}
        if actual!=expected:
            raise SystemExit(
                f"seed {seed} regression changed: {key}: {actual!r} != {expected!r}"
            )
    if include_rows:
        out["miss_rows"]=[
            {
                "center_log":center,
                "center_residue":pow(core.PRIMITIVE_ROOT,center,core.MOD),
                "legendre59":"+1" if center%2==0 else "-1",
                "divisor_logs":[a for a in range(core.N) if (mask>>a)&1],
                "min_added_nonresidue_units":dist[(mask,center)][0],
            }
            for mask,center in sorted(misses,key=lambda s:(s[1],s[0]))
        ]
    return out


def analyze(include_rows: bool) -> dict:
    seed_reports={str(seed):analyze_seed(seed,include_rows) for seed in SEEDS}
    # Every refined seed contains the universal seed 3, so its closure must sit
    # inside the universal forced-3 closure.
    universal=closure(3)
    subset_checks={str(seed): closure(seed) <= universal for seed in SEEDS}
    if not all(subset_checks.values()):
        raise SystemExit(f"class closure escaped universal forced-3 closure: {subset_checks}")
    return {
        "analysis":"k59-class-conditioned-hard-state-atlas-v1",
        "hard_classes":list(HARD_CLASSES),
        "class_seed":{str(h):CLASS_SEED[h] for h in HARD_CLASSES},
        "distinct_seeds":list(SEEDS),
        "seed_reports":seed_reports,
        "all_class_closures_subset_of_universal_forced3":subset_checks,
        "claim":(
            "exact hard-class superset closures from maximal p mod 840 seeds; "
            "no finite-prime extrapolation and no claim that every abstract state is realized"
        ),
    }


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--json",action="store_true")
    ap.add_argument("--table",action="store_true")
    args=ap.parse_args()
    report=analyze(args.table)
    if args.json:
        print(json.dumps(report,indent=2,sort_keys=True))
    else:
        print("k=59 class-conditioned hard-state atlas")
        for seed in SEEDS:
            r=report["seed_reports"][str(seed)]
            print(
                f"seed={seed:3d} states={r['states']:5d} misses={r['miss_states']:4d} "
                f"NR={r['min_added_nonresidue_histogram']}"
            )
    return 0


if __name__=="__main__":
    raise SystemExit(main())
