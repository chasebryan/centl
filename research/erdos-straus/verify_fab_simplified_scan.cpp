#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <numeric>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

using i64=long long;
using i128=__int128_t;
static std::vector<int> P;

static bool prime_trial(i64 n){
    if(n<2) return false;
    for(int p:P){ if(1LL*p*p>n) break; if(n%p==0) return n==p; }
    return true;
}

static std::vector<std::pair<i64,int>> factor(i64 n){
    std::vector<std::pair<i64,int>> f;
    for(int p:P){
        if(1LL*p*p>n) break;
        if(n%p==0){int e=0;while(n%p==0){n/=p;++e;}f.push_back({p,e});}
    }
    if(n>1)f.push_back({n,1});
    return f;
}

static void gen_divs(const std::vector<std::pair<i64,int>>&f,int i,i64 cur,std::vector<i64>&out){
    if(i==(int)f.size()){out.push_back(cur);return;}
    auto [p,e]=f[i]; i64 pe=1;
    for(int a=0;a<=e;++a){gen_divs(f,i+1,cur*pe,out);pe*=p;}
}

static bool direct_fab_hit(i64 n,int a,int b){
    i64 N=a+1LL*b*n;
    auto f=factor(N); std::vector<i64> ds; gen_divs(f,0,1,ds);
    for(i64 k:ds){
        if(k%4!=3) continue;
        i64 q=N/k;
        i128 s=(i128)q*(n+k);
        if(s%(4LL*b)!=0) continue;
        i128 z=(i128)n*q*(n+k);
        if(z%(4LL*a)!=0) continue;
        return true;
    }
    return false;
}

int main(int argc,char**argv){
    i64 LIMIT=argc>1?std::stoll(argv[1]):1000000000LL;
    std::string out=argc>2?argv[2]:"fab-simplified-independent.json";
    int CMAX=argc>3?std::stoi(argv[3]):11;

    int bound=(int)std::sqrt((long double)CMAX*LIMIT+CMAX)+10;
    std::vector<bool>s(bound+1,true);s[0]=s[1]=false;
    for(int i=2;i<=bound;++i)if(s[i]){
        P.push_back(i);
        if(1LL*i*i<=bound)for(i64 j=1LL*i*i;j<=bound;j+=i)s[(size_t)j]=false;
    }

    std::vector<std::pair<int,int>> pairs;
    for(int a=1;a<=CMAX;++a)for(int b=1;b<=CMAX;++b){
        bool axis=(a==1||b==1);
        bool plane=(std::gcd(a,b)==1 && ((a&1)!=(b&1)));
        if(axis||plane)pairs.push_back({a,b});
    }
    std::sort(pairs.begin(),pairs.end(),[](auto x,auto y){
        int cx=std::max(x.first,x.second),cy=std::max(y.first,y.second);
        if(cx!=cy)return cx<cy;
        if(x.first*x.second!=y.first*y.second)return x.first*x.second<y.first*y.second;
        return x<y;
    });

    const int H[6]={1,121,169,289,361,529};
    i64 hard=0,survivors=0; std::vector<i64> examples;
    for(i64 base=0;base<=LIMIT;base+=840){
        for(int h:H){
            i64 n=base+h;
            if(n<5||n>LIMIT||!prime_trial(n))continue;
            ++hard; bool hit=false;
            for(auto [a,b]:pairs){
                if(a==n)continue;
                if(direct_fab_hit(n,a,b)){hit=true;break;}
            }
            if(!hit){++survivors;if(examples.size()<30)examples.push_back(n);}
        }
    }

    std::ofstream f(out);
    f<<"{\n  \"status\": \"independent original-fab verification of simplified subsystem\",\n";
    f<<"  \"limit\": "<<LIMIT<<",\n  \"parameter_bound\": "<<CMAX<<",\n";
    f<<"  \"hard_primes_checked\": "<<hard<<",\n  \"survivors\": "<<survivors<<",\n  \"survivor_examples\": [";
    for(size_t i=0;i<examples.size();++i){if(i)f<<", ";f<<examples[i];}
    f<<"],\n  \"verdict\": \""<<(survivors==0?"ZERO_SURVIVORS":"SURVIVORS_FOUND")<<"\"\n}\n";
    std::cerr<<"independent limit="<<LIMIT<<" hard="<<hard<<" survivors="<<survivors<<"\n";
    return survivors==0?0:2;
}
