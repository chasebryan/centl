#!/usr/bin/env python3
"""Independent verifier for direct-shadow completeness finite certificates."""
from __future__ import annotations
import argparse, json, math
from pathlib import Path

HARD=(1,121,169,289,361,529)

def divisors(n):
    a=[]; b=[]
    for d in range(1, math.isqrt(n)+1):
        if n%d==0:
            a.append(d)
            if d*d!=n: b.append(n//d)
    return a+b[::-1]

def traps(k):
    m=4*k-1
    out=set()
    for e in divisors(k):
        out.add((-e)%m); out.add((-4*e)%m)
    return out

def crt(a,m,b,n):
    g=math.gcd(m,n)
    if (b-a)%g: return None
    mm=m//g; nn=n//g
    u=0 if nn==1 else (((b-a)//g)*pow(mm,-1,nn))%nn
    return (a+m*u)%(m*nn), m*nn

def direct_shadow(k,h,t,j,T):
    cr=crt(h,840,t,4*k-1)
    if cr is None: return False
    r,L=cr; mj=4*j-1; g=math.gcd(L,mj)
    fibre={u for u in range(r%g,mj,g)}
    return fibre <= T[j]

def verify_witness(rec,T,reduced):
    k,h,t=rec['k'],rec['h'],rec['t']
    if h not in HARD: raise AssertionError('bad hard class')
    m=4*k-1
    if math.gcd(t,m)!=1: raise AssertionError('nonunit target')
    if (t-h)%math.gcd(840,m): raise AssertionError('incompatible target')
    if any(direct_shadow(k,h,t,j,T) for j in range(1,k)):
        raise AssertionError(f"reported direct-novel candidate is directly shadowed: {(k,h,t)}")
    cr=crt(h,840,t,m)
    if cr is None: raise AssertionError('CRT failed')
    r,L=cr
    if (r,L)!=(rec['r'],rec['L']): raise AssertionError('CRT record mismatch')
    s=rec['reduced_witness_s'] if reduced else rec['integer_witness_s']
    x=rec['reduced_witness_x'] if reduced else rec['integer_witness_x']
    if x != r+L*s: raise AssertionError('x != r+Ls')
    if x%840!=h or x%m!=t: raise AssertionError('target progression mismatch')
    for j in range(1,k):
        if x%(4*j-1) in T[j]:
            raise AssertionError(f"witness hits earlier layer {j}: {(k,h,t,s)}")
    if reduced:
        Q=rec['Q']; M=rec['progression_modulus']
        qcheck=1
        for j in range(1,k):
            mj=4*j-1; g=math.gcd(L,mj); q=mj//g
            compatible=any((u-r)%g==0 for u in T[j])
            if compatible: qcheck=math.lcm(qcheck,q)
        if Q!=qcheck or M!=L*Q: raise AssertionError('period mismatch')
        if math.gcd(x,M)!=1: raise AssertionError('reduced witness not reduced')

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--out',type=Path,default=Path('direct-shadow-output')); args=ap.parse_args()
    data=json.loads((args.out/'direct-shadow-completeness.json').read_text())
    K=int(data['parameters']['k_limit'])
    T=[set()]+[traps(k) for k in range(1,K+1)]
    seen=set(); reduced=0
    for rec in data['witnesses']:
        key=(rec['k'],rec['h'],rec['t'])
        if key in seen: raise AssertionError('duplicate candidate record')
        seen.add(key)
        verify_witness(rec,T,False)
        if 'reduced_witness_s' in rec:
            verify_witness(rec,T,True); reduced+=1
    counts=data['counts']
    if len(seen)!=counts['integer_avoiding_witnesses']:
        raise AssertionError('integer witness count mismatch')
    if reduced!=counts['reduced_avoiding_witnesses']:
        raise AssertionError('reduced witness count mismatch')
    if not data['unresolved_integer_candidates'] and counts['integer_avoiding_witnesses']!=counts['direct_novel_candidates']:
        raise AssertionError('claimed finite union-shadow survival is incomplete')
    if not data['unresolved_reduced_candidates'] and counts['reduced_avoiding_witnesses']!=counts['direct_novel_candidates']:
        raise AssertionError('claimed finite prime-realization survival is incomplete')
    summary={
        'verdict':'VERIFIED', 'k_limit':K,
        'direct_novel_candidates_checked':counts['direct_novel_candidates'],
        'integer_witnesses_verified':len(seen),
        'reduced_witnesses_verified':reduced,
        'unresolved_integer_candidates':len(data['unresolved_integer_candidates']),
        'unresolved_reduced_candidates':len(data['unresolved_reduced_candidates'])}
    (args.out/'direct-shadow-independent-verifier.json').write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n')
    print(json.dumps(summary,indent=2,sort_keys=True))

if __name__=='__main__': main()
