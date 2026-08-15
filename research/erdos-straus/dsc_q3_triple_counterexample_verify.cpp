// Exact exhaustive verifier for DSC-Q3-TRIPLE-COUNTEREXAMPLE.md
//
// This program checks the explicit k=15,290,696 / h=1 candidate, verifies
// the q=3 triple cover by rows 25,70,187, computes the exact maximum divisor
// count tau(j) for every earlier j, and then exhaustively reconstructs every
// earlier pullback that could possibly be a direct shadow.
//
// A successful run exits 0 and prints a compact JSON record to stdout.

#include <algorithm>
#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <tuple>
#include <unordered_set>
#include <vector>

using u64 = std::uint64_t;
using i128 = __int128_t;

static u64 gcd_u64(u64 a, u64 b) {
    while (b) {
        const u64 t = a % b;
        a = b;
        b = t;
    }
    return a;
}

static long long egcd(long long a, long long b, long long &x, long long &y) {
    if (!b) {
        x = 1;
        y = 0;
        return a;
    }
    long long x1 = 0, y1 = 0;
    const long long g = egcd(b, a % b, x1, y1);
    x = y1;
    y = x1 - y1 * (a / b);
    return g;
}

static u64 invmod(u64 a, u64 m) {
    long long x = 0, y = 0;
    const long long g = egcd(static_cast<long long>(a), static_cast<long long>(m), x, y);
    if (g != 1) throw std::runtime_error("non-invertible modular value");
    long long z = x % static_cast<long long>(m);
    if (z < 0) z += static_cast<long long>(m);
    return static_cast<u64>(z);
}

static std::pair<u64, u64> crt2(u64 a, u64 m, u64 b, u64 n) {
    const u64 g = gcd_u64(m, n);
    const i128 diff = static_cast<i128>(b) - static_cast<i128>(a);
    if (diff % static_cast<i128>(g) != 0) throw std::runtime_error("incompatible CRT");
    const u64 mm = m / g;
    const u64 nn = n / g;
    u64 u = 0;
    if (nn != 1) {
        i128 rhs = diff / static_cast<i128>(g);
        long long rhs_mod = static_cast<long long>(rhs % static_cast<i128>(nn));
        if (rhs_mod < 0) rhs_mod += static_cast<long long>(nn);
        u = static_cast<u64>((static_cast<i128>(rhs_mod) * invmod(mm % nn, nn)) % nn);
    }
    const u64 L = m * nn;
    const u64 r = static_cast<u64>((static_cast<i128>(a) + static_cast<i128>(m) * u) % L);
    return {r, L};
}

static std::vector<u64> divisors(u64 n) {
    std::vector<u64> lo, hi;
    for (u64 d = 1; d * d <= n; ++d) {
        if (n % d == 0) {
            lo.push_back(d);
            if (d * d != n) hi.push_back(n / d);
        }
    }
    std::reverse(hi.begin(), hi.end());
    lo.insert(lo.end(), hi.begin(), hi.end());
    return lo;
}

static bool is_trap(u64 residue, int j) {
    const u64 m = 4ULL * static_cast<u64>(j) - 1;
    for (u64 e : divisors(static_cast<u64>(j))) {
        if (residue == (m - (e % m)) % m) return true;
        if (residue == (m - ((4 * e) % m)) % m) return true;
    }
    return false;
}

static std::vector<u64> pullback(u64 r, u64 L, int j) {
    const u64 m = 4ULL * static_cast<u64>(j) - 1;
    const u64 g = gcd_u64(L, m);
    const u64 q = m / g;
    std::vector<unsigned char> seen(static_cast<std::size_t>(q), 0);
    std::vector<u64> out;
    const u64 inv = q == 1 ? 0 : invmod((L / g) % q, q);
    const u64 rmod = r % m;
    for (u64 e : divisors(static_cast<u64>(j))) {
        const u64 traps[2] = {
            (m - (e % m)) % m,
            (m - ((4 * e) % m)) % m,
        };
        for (u64 u : traps) {
            if (u % g != r % g) continue;
            u64 s = 0;
            if (q != 1) {
                const u64 delta = u >= rmod ? (u - rmod) : (u + m - rmod);
                if (delta % g != 0) throw std::runtime_error("pullback divisibility failure");
                const u64 rhs = (delta / g) % q;
                s = static_cast<u64>((static_cast<i128>(rhs) * inv) % q);
            }
            if (!seen[static_cast<std::size_t>(s)]) {
                seen[static_cast<std::size_t>(s)] = 1;
                out.push_back(s);
            }
        }
    }
    std::sort(out.begin(), out.end());
    return out;
}

static int jacobi(long long aa, long long nn) {
    if (nn <= 0 || (nn % 2) == 0) throw std::runtime_error("bad Jacobi denominator");
    long long a = aa % nn;
    if (a < 0) a += nn;
    long long n = nn;
    int result = 1;
    while (a != 0) {
        while ((a & 1LL) == 0) {
            a >>= 1;
            const long long r = n & 7LL;
            if (r == 3 || r == 5) result = -result;
        }
        std::swap(a, n);
        if ((a & 3LL) == 3 && (n & 3LL) == 3) result = -result;
        a %= n;
    }
    return n == 1 ? result : 0;
}

int main() {
    constexpr int K = 15290696;
    constexpr u64 M = 61162783ULL;
    constexpr u64 TARGET_DIVISOR = 764ULL;
    constexpr u64 T = 61162019ULL;
    constexpr u64 EXPECTED_L = 51376737720ULL;
    constexpr u64 EXPECTED_R = 41284877761ULL;

    static_assert(4ULL * K - 1 == M, "target modulus mismatch");
    if (K % TARGET_DIVISOR != 0) throw std::runtime_error("target divisor does not divide k");
    if ((M - TARGET_DIVISOR) % M != T) throw std::runtime_error("target trap mismatch");
    if (gcd_u64(M, 840) != 1) throw std::runtime_error("target modulus not coprime to 840");

    const auto [r, L] = crt2(1, 840, T, M);
    if (r != EXPECTED_R || L != EXPECTED_L) throw std::runtime_error("CRT regression mismatch");
    if (r % 840 != 1 || r % M != T) throw std::runtime_error("CRT residue mismatch");

    const auto r25 = pullback(r, L, 25);
    const auto r70 = pullback(r, L, 70);
    const auto r187 = pullback(r, L, 187);
    if (r25 != std::vector<u64>{1}) throw std::runtime_error("R25 mismatch");
    if (r70 != std::vector<u64>{2}) throw std::runtime_error("R70 mismatch");
    if (r187 != std::vector<u64>{0}) throw std::runtime_error("R187 mismatch");

    if (jacobi(static_cast<long long>(r), 99) != -1) throw std::runtime_error("Jacobi 99 mismatch");
    if (jacobi(static_cast<long long>(r), 279) != -1) throw std::runtime_error("Jacobi 279 mismatch");
    if (jacobi(static_cast<long long>(r), 747) != -1) throw std::runtime_error("Jacobi 747 mismatch");

    // Exact tau(j) for all 1 <= j < K via a linear sieve.
    const int N = K - 1;
    std::vector<int> lp(N + 1, 0), exponent(N + 1, 0), tau(N + 1, 0), primes;
    tau[1] = 1;
    int max_tau = 1;
    int max_tau_at = 1;
    for (int i = 2; i <= N; ++i) {
        if (lp[i] == 0) {
            lp[i] = i;
            primes.push_back(i);
            exponent[i] = 1;
            tau[i] = 2;
        }
        for (int p : primes) {
            const long long x = 1LL * p * i;
            if (x > N) break;
            lp[static_cast<int>(x)] = p;
            if (p == lp[i]) {
                exponent[static_cast<int>(x)] = exponent[i] + 1;
                tau[static_cast<int>(x)] = tau[i] / (exponent[i] + 1) * (exponent[static_cast<int>(x)] + 1);
                break;
            }
            exponent[static_cast<int>(x)] = 1;
            tau[static_cast<int>(x)] = tau[i] * 2;
        }
        if (tau[i] > max_tau) {
            max_tau = tau[i];
            max_tau_at = i;
        }
    }

    std::size_t exact_cardinality_candidates = 0;
    std::vector<std::tuple<int, u64>> direct_shadows;

    for (int j = 1; j < K; ++j) {
        const u64 m = 4ULL * static_cast<u64>(j) - 1;
        const u64 g = gcd_u64(L, m);
        const u64 q = m / g;
        if (q > static_cast<u64>(2 * max_tau)) continue;
        if (q > static_cast<u64>(2 * tau[j])) continue;
        ++exact_cardinality_candidates;
        const auto R = pullback(r, L, j);
        if (R.size() == q) direct_shadows.emplace_back(j, q);
    }

    if (max_tau != 504 || max_tau_at != 14414400) throw std::runtime_error("tau frontier mismatch");
    if (exact_cardinality_candidates != 297) throw std::runtime_error("candidate count mismatch");
    if (!direct_shadows.empty()) throw std::runtime_error("unexpected direct shadow found");

    std::cout
        << "{\n"
        << "  \"verdict\": \"VERIFIED\",\n"
        << "  \"k\": " << K << ",\n"
        << "  \"M\": " << M << ",\n"
        << "  \"h\": 1,\n"
        << "  \"t\": " << T << ",\n"
        << "  \"r\": " << r << ",\n"
        << "  \"L\": " << L << ",\n"
        << "  \"R25\": [1],\n"
        << "  \"R70\": [2],\n"
        << "  \"R187\": [0],\n"
        << "  \"max_tau_before_k\": " << max_tau << ",\n"
        << "  \"max_tau_at\": " << max_tau_at << ",\n"
        << "  \"exact_direct_shadow_candidates\": " << exact_cardinality_candidates << ",\n"
        << "  \"direct_shadows\": 0\n"
        << "}\n";

    return 0;
}
