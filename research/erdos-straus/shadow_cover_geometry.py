#!/usr/bin/env python3
"""Analyze overlap geometry in a direct-shadow completeness certificate bundle."""
from __future__ import annotations
import argparse, json, math, statistics
from pathlib import Path

HARD=(1,121,169,289,361,529)

def divisors(n):
    a=[]; b=[]
    for d in range(1,math.isqrt(n)+1):
        if n%d==0:
            a.append(d)
            if d*d!=n:b.append(n//d)
    return a+b[::-1]

def trap_set(k):
    m=4*k-1
    return {r for e in divisors(k) for r in ((-e)%m,(-4*e)%m)}

def crt2(a,m,b,n):
    g=math.gcd(m,n)
    if (b-a)%g:return None
    mm,nn=m//g,n//g
    u=0 if nn==1 else (((b-a)//g)*pow(mm,-1,nn))%nn
    return (a+m*u)%(m*nn),m*nn

def constraint_geometry(k,h,t,T):
    r,L=crt2(h,840,t,4*k-1)
    rows=[]
    for j in range(1,k):
        mj=4*j-1; g=math.gcd(L,mj); q=mj//g
        R=set()
        if q==1:
            if any((u-r)%g==0 for u in T[j]):R.add(0)
        else:
            inv=pow((L//g)%q,-1,q)
            for u in T[j]:
                if (u-r)%g==0:R.add((((u-r)//g)*inv)%q)
        if R:rows.append((j,q,R))
    cover_mass=sum(len(R)/q for _,q,R in rows)
    Q=1; new=old=0
    for j,q,R in rows:
        nQ=math.lcm(Q,q)
        if nQ>Q:new+=1
        else:old+=1
        Q=nQ
    return {
        'cover_mass':cover_mass,
        'active_constraints':len(rows),
        'new_coordinate_constraints':new,
        'old_coordinate_constraints':old,
    }

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--input',type=Path,default=Path('direct-shadow-output/direct-shadow-completeness.json'))
    ap.add_argument('--out',type=Path,default=Path('direct-shadow-output'))
    args=ap.parse_args()
    data=json.loads(args.input.read_text())
    K=int(data['parameters']['k_limit'])
    T=[set()]+[trap_set(k) for k in range(1,K+1)]
    rows=[]
    for rec in data['witnesses']:
        g=constraint_geometry(rec['k'],rec['h'],rec['t'],T)
        rows.append({'k':rec['k'],'h':rec['h'],'t':rec['t'],'reduced_witness_s':rec.get('reduced_witness_s')}|g)
    masses=[r['cover_mass'] for r in rows]
    active=[r['active_constraints'] for r in rows]
    new=[r['new_coordinate_constraints'] for r in rows]
    old=[r['old_coordinate_constraints'] for r in rows]
    summary={
        'k_limit':K,'candidate_count':len(rows),
        'cover_mass':{
            'min':min(masses),'median':statistics.median(masses),'mean':statistics.fmean(masses),'max':max(masses),
            'below_one':sum(x<1 for x in masses),'above_one':sum(x>1 for x in masses),
        },
        'active_constraints':{'median':statistics.median(active),'mean':statistics.fmean(active),'max':max(active)},
        'new_coordinate_constraints':{'median':statistics.median(new),'max':max(new)},
        'old_coordinate_constraints':{'median':statistics.median(old),'max':max(old)},
        'highest_cover_mass_candidates':sorted(rows,key=lambda r:(-r['cover_mass'],r['k'],r['h'],r['t']))[:50],
        'interpretation':'A raw union bound explains only candidates with cover_mass < 1. Cover mass > 1 does not imply coverage; verified reduced witnesses show substantial overlap/dependency among the Type A/B pullback constraints.'
    }
    args.out.mkdir(parents=True,exist_ok=True)
    (args.out/'shadow-cover-geometry.json').write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n')
    report='# Shadow-cover geometry diagnostic\n\n'
    report+=f"Candidates: `{len(rows)}` through `k={K}`.\n\n"
    report+=f"Cover mass min/median/mean/max: `{min(masses)}` / `{statistics.median(masses)}` / `{statistics.fmean(masses)}` / `{max(masses)}`.\n\n"
    report+=f"Candidates with cover mass `<1`: `{sum(x<1 for x in masses)}`; `>1`: `{sum(x>1 for x in masses)}`.\n\n"
    report+=f"Active constraints median/mean/max: `{statistics.median(active)}` / `{statistics.fmean(active)}` / `{max(active)}`.\n\n"
    report+=f"Median new-coordinate constraints: `{statistics.median(new)}`; median old-coordinate constraints: `{statistics.median(old)}`.\n\n"
    report+='The verified noncoverage is therefore not a cheap union-bound phenomenon. Most candidates have nominal forbidden mass far above one, so the proof target is the overlap/dependency geometry of the pulled-back Type A/B constraints.\n'
    (args.out/'shadow-cover-geometry-report.md').write_text(report)
    print(report)

if __name__=='__main__':main()
