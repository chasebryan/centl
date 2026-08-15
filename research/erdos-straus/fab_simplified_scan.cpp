#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <map>
#include <numeric>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

using i64 = long long;

static std::vector<int> SMALL_PRIMES;

static std::vector<std::pair<i64,int>> factor_trial(i64 n) {
    std::vector<std::pair<i64,int>> out;
    i64 x=n;
    for (int p: SMALL_PRIMES) {
        if (1LL*p*p>x) break;
        if (x%p==0) {
            int e=0;
            while (x%p==0) { x/=p; ++e; }
            out.push_back({p,e});
        }
    }
    if (x>1) out.push_back({x,1});
    return out;
}

static bool is_prime(i64 n) {
    if (n<2) return false;
    for (int p: SMALL_PRIMES) {
        if (1LL*p*p>n) break;
        if (n%p==0) return n==p;
    }
    return true;
}

static bool divisor_residue_dfs(
    const std::vector<std::pair<i64,int>>& f,
    int idx,
    i64 cur,
    i64 mod,
    i64 target,
    i64 &witness
) {
    if (idx==(int)f.size()) {
        if (cur%mod==target) { witness=cur; return true; }
        return false;
    }
    auto [p,e]=f[idx];
    i64 pe=1;
    for (int a=0;a<=e;++a) {
        if (divisor_residue_dfs(f,idx+1,cur*pe,mod,target,witness)) return true;
        pe*=p;
    }
    return false;
}

struct Pair { int a,b,C; };
struct Hit { bool ok=false; int a=0,b=0,C=0; i64 k=0,q=0; };

static Hit find_hit(i64 p, const std::vector<Pair>& pairs) {
    for (auto pr: pairs) {
        i64 N=pr.a + 1LL*pr.b*p;
        i64 mod=4LL*pr.a*pr.b;
        i64 target=(-p)%mod; if (target<0) target+=mod;
        auto f=factor_trial(N);
        i64 k=0;
        if (divisor_residue_dfs(f,0,1,mod,target,k)) {
            return {true,pr.a,pr.b,pr.C,k,N/k};
        }
    }
    return {};
}

int main(int argc,char**argv) {
    i64 LIMIT = argc>1 ? std::stoll(argv[1]) : 1000000000LL;
    std::string out = argc>2 ? argv[2] : "fab-simplified-primary.json";
    int CMAX = argc>3 ? std::stoi(argv[3]) : 11;

    int prime_bound=(int)std::sqrt((long double)CMAX*LIMIT+CMAX)+10;
    std::vector<bool> sieve(prime_bound+1,true);
    sieve[0]=sieve[1]=false;
    for (int i=2;i<=prime_bound;++i) if (sieve[i]) {
        SMALL_PRIMES.push_back(i);
        if (1LL*i*i<=prime_bound)
            for (i64 j=1LL*i*i;j<=prime_bound;j+=i) sieve[(size_t)j]=false;
    }

    // Exact simplified subsystem: every coprime parameter pair.
    // FAB-COPRIME-PARITY-PLANE.md (historical filename) proves that for
    // gcd(a,b)=1 and prime p>a, the original fab conditions are equivalent to
    // one divisor congruence k | a+bp, k == -p (mod 4ab).
    std::vector<Pair> pairs;
    for (int a=1;a<=CMAX;++a) for (int b=1;b<=CMAX;++b) {
        if (std::gcd(a,b)==1) pairs.push_back({a,b,std::max(a,b)});
    }
    std::sort(pairs.begin(),pairs.end(),[](const Pair&x,const Pair&y){
        if (x.C!=y.C) return x.C<y.C;
        if ((x.a==1)!=(y.a==1)) return x.a==1;
        if ((x.b==1)!=(y.b==1)) return x.b==1;
        if (x.a*x.b!=y.a*y.b) return x.a*x.b<y.a*y.b;
        if (x.a!=y.a) return x.a<y.a;
        return x.b<y.b;
    });

    const int HARR[6]={1,121,169,289,361,529};
    std::map<int,i64> minC_hist;
    i64 hard_primes=0, survivors=0;
    std::vector<i64> survivor_examples;
    std::vector<std::tuple<i64,int,int,i64,i64>> critical11;

    for (i64 block=0; block<=LIMIT; block+=840) {
        for (int h:HARR) {
            i64 p=block+h;
            if (p<5 || p>LIMIT || !is_prime(p)) continue;
            ++hard_primes;
            Hit hit=find_hit(p,pairs);
            if (!hit.ok) {
                ++survivors;
                if (survivor_examples.size()<30) survivor_examples.push_back(p);
            } else {
                ++minC_hist[hit.C];
                if (hit.C==11 && critical11.size()<100)
                    critical11.push_back({p,hit.a,hit.b,hit.k,hit.q});
            }
        }
    }

    std::ofstream f(out);
    f << "{\n";
    f << "  \"status\": \"exact coprime fab-plane scan\",\n";
    f << "  \"limit\": "<<LIMIT<<",\n";
    f << "  \"parameter_bound\": "<<CMAX<<",\n";
    f << "  \"hard_primes_checked\": "<<hard_primes<<",\n";
    f << "  \"survivors\": "<<survivors<<",\n";
    f << "  \"minimal_parameter_bound_histogram\": {";
    bool first=true; for(auto [c,n]:minC_hist){ if(!first)f<<","; first=false; f<<"\n    \""<<c<<"\": "<<n; }
    if(!minC_hist.empty())f<<"\n  "; f<<"},\n";
    f << "  \"survivor_examples\": ["; for(size_t i=0;i<survivor_examples.size();++i){if(i)f<<", ";f<<survivor_examples[i];} f<<"],\n";
    f << "  \"critical_bound_11_examples\": [\n";
    for(size_t i=0;i<critical11.size();++i){ auto [p,a,b,k,q]=critical11[i]; f<<"    {\"p\": "<<p<<", \"a\": "<<a<<", \"b\": "<<b<<", \"k\": "<<k<<", \"q\": "<<q<<"}"<<(i+1<critical11.size()?",":"")<<"\n"; }
    f << "  ],\n";
    f << "  \"verdict\": \""<<(survivors==0?"ZERO_SURVIVORS":"SURVIVORS_FOUND")<<"\"\n";
    f << "}\n";

    std::cerr << "limit="<<LIMIT<<" hard_primes="<<hard_primes<<" survivors="<<survivors<<"\n";
    return survivors==0 ? 0 : 2;
}
