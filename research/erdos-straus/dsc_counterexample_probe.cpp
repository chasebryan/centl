#include <algorithm>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <numeric>
#include <set>
#include <string>
#include <tuple>
#include <unordered_set>
#include <utility>
#include <vector>

using i64 = long long;
using i128 = __int128_t;

static std::vector<std::pair<int,int>> factor_with_spf(int n, const std::vector<int>& spf) {
    std::vector<std::pair<int,int>> out;
    while (n > 1) {
        int p = spf[n], e = 0;
        while (n % p == 0) { n /= p; ++e; }
        out.push_back({p,e});
    }
    return out;
}

static std::vector<int> divisors_from_factor(const std::vector<std::pair<int,int>>& fac) {
    std::vector<int> ds{1};
    for (auto [p,e] : fac) {
        auto old = ds;
        ds.clear();
        i64 pe = 1;
        for (int a=0; a<=e; ++a) {
            for (int d : old) ds.push_back((int)(d*pe));
            pe *= p;
        }
    }
    return ds;
}

static std::unordered_set<i64> trap_set(int j, const std::vector<int>& spf) {
    i64 m = 4LL*j - 1;
    auto ds = divisors_from_factor(factor_with_spf(j, spf));
    std::unordered_set<i64> T;
    T.reserve(ds.size()*3+8);
    for (int e : ds) {
        T.insert((m-e)%m);
        T.insert((m-(4LL*e)%m)%m);
    }
    return T;
}

static bool is_ancestry_minimal(int j, i64 u, const std::vector<int>& spf) {
    i64 m = 4LL*j - 1;
    // m is small for the three selected rows; trial-divide its divisors directly.
    for (i64 d=1; d*d<=m; ++d) {
        if (m%d) continue;
        for (i64 mi : {d, m/d}) {
            if (mi < 3 || mi >= m || mi%4 != 3) continue;
            int i = (int)((mi+1)/4);
            auto Ti = trap_set(i, spf);
            if (Ti.count(u%mi)) return false;
        }
    }
    return true;
}

int main(int argc, char** argv) {
    std::string out_path = argc > 1 ? argv[1] : "dsc-counterexample-primary.json";

    // Constructed target factor pair.
    constexpr i64 W = 23450;
    constexpr i64 A = 764;
    constexpr i64 K = 4478950;
    constexpr i64 M = 17915799;
    constexpr i64 TARG = 17892349;
    constexpr i64 H = 1;
    constexpr i64 R = 1236166681;
    constexpr i64 L = 5016423720;

    if (W*A != M+1 || (M+1)%4 || (M+1)/4 != K) return 2;
    if (K%W != 0) return 3; // W is a plain target trap numerator e|k.
    if ((M-W)%M != TARG) return 4;
    if (std::gcd(TARG,M) != 1) return 5;
    if (R%840 != H || R%M != TARG) return 6;
    if (std::lcm<i64>(840,M) != L) return 7;

    // SPF is also used for the exhaustive earlier-layer scan.
    std::vector<int> spf(K+1);
    std::iota(spf.begin(), spf.end(), 0);
    for (int p=2; 1LL*p*p<=K; ++p) if (spf[p]==p)
        for (i64 x=1LL*p*p; x<=K; x+=p) if (spf[x]==x) spf[x]=p;

    struct Row { int j; i64 u; int cls; i64 w; i64 a; };
    const std::vector<Row> rows = {
        {25, 79, 1, 20, 5},
        {70, 265, 0, 14, 20},
        {187, 703, 2, 44, 17},
    };

    int union_mask = 0;
    for (const auto& row : rows) {
        i64 m = 4LL*row.j - 1;
        if (row.w*row.a != m+1) return 10;
        if ((m-row.w)%m != row.u) return 11;
        if (m/std::gcd(L,m) != 3) return 12;
        auto Tj = trap_set(row.j, spf);
        if (!Tj.count(row.u)) return 13;
        if ((R + (i128)L*row.cls)%m != row.u) return 14;
        if (!is_ancestry_minimal(row.j,row.u,spf)) return 15;
        union_mask |= 1 << row.cls;
    }
    if (union_mask != 7) return 16;

    i64 pruned_by_tau = 0;
    i64 exact_tested = 0;
    i64 direct_sources = 0;
    i64 max_q_tested = 0;
    std::vector<int> direct_js;

    for (int j=1; j<K; ++j) {
        auto fac = factor_with_spf(j, spf);
        int tau = 1;
        for (auto [p,e] : fac) tau *= (e+1);

        i64 m = 4LL*j - 1;
        i64 g = std::gcd(L,m);
        i64 q = m/g;

        // R_j is an injective pullback into T_j, so |R_j|<=|T_j|<=2*tau(j).
        // Full direct coverage requires q<=|R_j|.
        if (q > 2LL*tau) {
            ++pruned_by_tau;
            continue;
        }

        ++exact_tested;
        max_q_tested = std::max(max_q_tested,q);
        auto ds = divisors_from_factor(fac);
        std::unordered_set<i64> Tj;
        Tj.reserve(ds.size()*3+8);
        for (int e : ds) {
            Tj.insert((m-e)%m);
            Tj.insert((m-(4LL*e)%m)%m);
        }
        if ((i64)Tj.size() < q) continue;

        bool all = true;
        i64 rr = R%m, ll = L%m;
        for (i64 s=0; s<q; ++s) {
            i64 x = (rr + (i128)ll*s % m)%m;
            if (!Tj.count(x)) { all=false; break; }
        }
        if (all) {
            ++direct_sources;
            direct_js.push_back(j);
        }
    }

    std::ofstream f(out_path);
    f << "{\n";
    f << "  \"status\": \"exact exhaustive DSC counterexample probe\",\n";
    f << "  \"k\": " << K << ",\n";
    f << "  \"m\": " << M << ",\n";
    f << "  \"h\": " << H << ",\n";
    f << "  \"t\": " << TARG << ",\n";
    f << "  \"r\": " << R << ",\n";
    f << "  \"L\": " << L << ",\n";
    f << "  \"target_factor_pair\": [" << W << ", " << A << "],\n";
    f << "  \"q3_union_mask\": " << union_mask << ",\n";
    f << "  \"earlier_layers\": " << (K-1) << ",\n";
    f << "  \"pruned_by_q_gt_2tau\": " << pruned_by_tau << ",\n";
    f << "  \"exact_direct_candidates_tested\": " << exact_tested << ",\n";
    f << "  \"maximum_q_among_exact_tests\": " << max_q_tested << ",\n";
    f << "  \"direct_shadow_sources\": " << direct_sources << ",\n";
    f << "  \"direct_shadow_js\": [";
    for (size_t n=0;n<direct_js.size();++n) { if (n) f << ", "; f << direct_js[n]; }
    f << "],\n";
    f << "  \"verdict\": \"" << (direct_sources==0 ? "DIRECTLY_NOVEL_UNION_SHADOW" : "DIRECT_SHADOWED") << "\"\n";
    f << "}\n";

    std::cout << "K=" << K
              << " earlier=" << (K-1)
              << " pruned=" << pruned_by_tau
              << " exact=" << exact_tested
              << " direct=" << direct_sources
              << " union_mask=" << union_mask << "\n";

    return direct_sources==0 ? 0 : 20;
}
