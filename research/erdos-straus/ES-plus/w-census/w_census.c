#define _POSIX_C_SOURCE 200809L
/*
 * Standalone W-clause census. Does not link or edit cbis.kernel.
 *
 * Classifies every Mordell-hard prime in (from, limit] by which W
 * clause hits: 4p+1, p+4, fab(a,b<=11). Reports the first survivor.
 */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const int HARD[6] = {1, 121, 169, 289, 361, 529};

static uint8_t *sieve;
static uint32_t *primes;
static int nprimes;
static uint64_t sieve_n;

static void die(const char *m) {
    fprintf(stderr, "w_census: %s\n", m);
    exit(1);
}

static int is_hard(uint64_t p) {
    int r = (int)(p % 840);
    for (int i = 0; i < 6; i++)
        if (r == HARD[i]) return 1;
    return 0;
}

static void build_sieve(uint64_t n) {
    sieve_n = n;
    sieve = calloc(n + 1, 1);
    if (!sieve) die("oom");
    if (n >= 2) sieve[2] = 1;
    for (uint64_t i = 3; i <= n; i += 2) sieve[i] = 1;
    for (uint64_t i = 3; i * i <= n; i += 2)
        if (sieve[i])
            for (uint64_t j = i * i; j <= n; j += i) sieve[j] = 0;
    nprimes = (n >= 2);
    for (uint64_t i = 3; i <= n; i += 2)
        if (sieve[i]) nprimes++;
    primes = malloc((size_t)nprimes * sizeof(uint32_t));
    if (!primes) die("oom");
    int k = 0;
    if (n >= 2) primes[k++] = 2;
    for (uint64_t i = 3; i <= n; i += 2)
        if (sieve[i]) primes[k++] = (uint32_t)i;
}

static uint64_t gcd64(uint64_t a, uint64_t b) {
    while (b) {
        uint64_t t = a % b;
        a = b;
        b = t;
    }
    return a;
}

static uint64_t mul_mod(uint64_t a, uint64_t b, uint64_t m) {
    return (uint64_t)((unsigned __int128)a * b % m);
}

static uint64_t pow_mod(uint64_t a, uint64_t e, uint64_t m) {
    uint64_t r = 1 % m;
    a %= m;
    while (e) {
        if (e & 1) r = mul_mod(r, a, m);
        a = mul_mod(a, a, m);
        e >>= 1;
    }
    return r;
}

static int mr_check(uint64_t n, uint64_t a) {
    if (a % n == 0) return 1;
    uint64_t d = n - 1;
    int s = 0;
    while ((d & 1) == 0) {
        d >>= 1;
        s++;
    }
    uint64_t x = pow_mod(a, d, n);
    if (x == 1 || x == n - 1) return 1;
    for (int i = 1; i < s; i++) {
        x = mul_mod(x, x, n);
        if (x == n - 1) return 1;
    }
    return 0;
}

static int is_prime64(uint64_t n) {
    if (n < 2) return 0;
    if (sieve && n <= sieve_n) return sieve[n];
    static const uint64_t small[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31};
    for (int i = 0; i < 11; i++) {
        if (n == small[i]) return 1;
        if (n % small[i] == 0) return 0;
    }
    for (int i = 0; i < nprimes; i++) {
        uint64_t p = primes[i];
        if (p > n / p) break;
        if (n % p == 0) return 0;
    }
    static const uint64_t bases[] = {
        2ull, 325ull, 9375ull, 28178ull, 450775ull, 9780504ull, 1795265022ull};
    for (int i = 0; i < 7; i++)
        if (!mr_check(n, bases[i])) return 0;
    return 1;
}

typedef struct {
    uint64_t ps[16];
    int es[16];
    int n;
} fac_t;

static void factor64(uint64_t n, fac_t *f) {
    f->n = 0;
    for (int i = 0; i < nprimes; i++) {
        uint64_t p = primes[i];
        if (p * p > n) break;
        if (n % p == 0) {
            int e = 0;
            while (n % p == 0) {
                n /= p;
                e++;
            }
            f->ps[f->n] = p;
            f->es[f->n] = e;
            f->n++;
        }
        if (n == 1) return;
    }
    if (n > 1) {
        f->ps[f->n] = n;
        f->es[f->n] = 1;
        f->n++;
    }
}

/* True iff n has a prime factor ≡ 3 (mod 4). That prime is a divisor ≡ 3. */
static int has_prime_3mod4(uint64_t n) {
    fac_t f;
    factor64(n, &f);
    for (int i = 0; i < f.n; i++)
        if ((f.ps[i] & 3) == 3) return 1;
    return 0;
}

static uint64_t divisor_in_class(uint64_t n, uint64_t mod, uint64_t residue) {
    fac_t f;
    factor64(n, &f);
    uint64_t *val = calloc(mod, sizeof(uint64_t));
    uint8_t *have = calloc(mod, 1);
    if (!val || !have) die("oom");
    have[1 % mod] = 1;
    val[1 % mod] = 1;
    uint64_t tgt = residue % mod;
    for (int i = 0; i < f.n; i++) {
        uint64_t q = f.ps[i];
        int e = f.es[i];
        uint64_t *nval = calloc(mod, sizeof(uint64_t));
        uint8_t *nhave = calloc(mod, 1);
        if (!nval || !nhave) die("oom");
        memcpy(nval, val, (size_t)mod * sizeof(uint64_t));
        memcpy(nhave, have, (size_t)mod);
        for (uint64_t r = 0; r < mod; r++) {
            if (!have[r]) continue;
            uint64_t v = val[r];
            uint64_t rr = r;
            for (int j = 0; j < e; j++) {
                v *= q;
                rr = (rr * (q % mod)) % mod;
                if (!nhave[rr]) {
                    nhave[rr] = 1;
                    nval[rr] = v;
                }
            }
        }
        free(val);
        free(have);
        val = nval;
        have = nhave;
        if (have[tgt]) {
            uint64_t o = val[tgt];
            free(val);
            free(have);
            return o;
        }
    }
    uint64_t o = have[tgt] ? val[tgt] : 0;
    free(val);
    free(have);
    return o;
}

static int try_p_plus_4(uint64_t p) {
    uint64_t q = divisor_in_class(p + 4, 4, 3);
    if (!q) return 0;
    uint64_t m = (q + 1) / 4;
    return (m * p + 1) % q == 0;
}

static int try_4p_plus_1(uint64_t p) {
    uint64_t n = 4 * p + 1;
    uint64_t F = divisor_in_class(n, 4, 3);
    if (!F) return 0;
    uint64_t G = n / F;
    return (G % 4) == 3;
}

static int try_fab(uint64_t p, int a, int b) {
    if (gcd64((uint64_t)a, (uint64_t)b) != 1) return 0;
    if ((uint64_t)a >= p || (uint64_t)b >= p) return 0;
    uint64_t lin = (uint64_t)a + (uint64_t)b * p;
    uint64_t mod = 4ull * (uint64_t)a * (uint64_t)b;
    uint64_t target = (mod - (p % mod)) % mod;
    uint64_t k = divisor_in_class(lin, mod, target);
    if (!k) return 0;
    if ((p + k) % mod) return 0;
    return lin % k == 0;
}

static const int FAB_PAIRS[][2] = {
    {1, 5}, {5, 1}, {1, 2}, {1, 6}, {3, 2}, {2, 3}, {1, 1}, {1, 3},
    {1, 4}, {1, 7}, {1, 8}, {1, 9}, {1, 10}, {1, 11}, {2, 1}, {2, 5},
    {2, 7}, {2, 9}, {2, 11}, {3, 1}, {3, 4}, {3, 5}, {3, 7}, {3, 8},
    {3, 10}, {3, 11}, {4, 1}, {4, 3}, {4, 5}, {4, 7}, {4, 9}, {4, 11},
    {5, 2}, {5, 3}, {5, 4}, {5, 6}, {5, 7}, {5, 8}, {5, 9}, {5, 11},
    {6, 1}, {6, 5}, {6, 7}, {6, 11}, {7, 1}, {7, 2}, {7, 3}, {7, 4},
    {7, 5}, {7, 6}, {7, 8}, {7, 9}, {7, 10}, {7, 11}, {8, 1}, {8, 3},
    {8, 5}, {8, 7}, {8, 9}, {8, 11}, {9, 1}, {9, 2}, {9, 4}, {9, 5},
    {9, 7}, {9, 8}, {9, 10}, {9, 11}, {10, 1}, {10, 3}, {10, 7}, {10, 9},
    {10, 11}, {11, 1}, {11, 2}, {11, 3}, {11, 4}, {11, 5}, {11, 6},
    {11, 7}, {11, 8}, {11, 9}, {11, 10}};

static int try_any_fab(uint64_t p) {
    int np = (int)(sizeof FAB_PAIRS / sizeof FAB_PAIRS[0]);
    for (int i = 0; i < np; i++)
        if (try_fab(p, FAB_PAIRS[i][0], FAB_PAIRS[i][1])) return 1;
    return 0;
}

/* 4xyz == p(yz+xz+xy) for the p+4 identity, when it claims a hit. */
static int verify_p_plus_4(uint64_t p) {
    uint64_t q = divisor_in_class(p + 4, 4, 3);
    if (!q) return 0;
    uint64_t m = (q + 1) / 4;
    if ((m * p + 1) % q) return 0;
    uint64_t v = (m * p + 1) / q;
    unsigned __int128 x = v;
    unsigned __int128 y = (unsigned __int128)m * p;
    unsigned __int128 z = y * v;
    unsigned __int128 lhs = 4 * x * y * z;
    unsigned __int128 rhs = (unsigned __int128)p * (y * z + x * z + x * y);
    return lhs == rhs;
}

static int verify_4p_plus_1(uint64_t p) {
    uint64_t n = 4 * p + 1;
    uint64_t F = divisor_in_class(n, 4, 3);
    if (!F) return 0;
    uint64_t G = n / F;
    if ((G % 4) != 3) return 0;
    uint64_t u = (F + 1) / 4;
    uint64_t v = (G + 1) / 4;
    unsigned __int128 x = (unsigned __int128)u * v;
    unsigned __int128 y = (unsigned __int128)p * v;
    unsigned __int128 z = (unsigned __int128)p * u;
    unsigned __int128 lhs = 4 * x * y * z;
    unsigned __int128 rhs = (unsigned __int128)p * (y * z + x * z + x * y);
    return lhs == rhs;
}

int main(int argc, char **argv) {
    uint64_t from = 0;
    uint64_t limit = 2000000;
    if (argc >= 2) limit = strtoull(argv[1], NULL, 10);
    if (argc >= 3) {
        from = strtoull(argv[1], NULL, 10);
        limit = strtoull(argv[2], NULL, 10);
    }
    build_sieve(1000003ull);

    uint64_t hard = 0, w = 0, a4p = 0, ap4 = 0, afab = 0;
    uint64_t only4p = 0, onlyp4 = 0, onlyfab = 0;
    uint64_t miss = 0;
    uint64_t first_miss = 0;
    uint64_t first_onlyfab = 0;
    uint64_t both_linear_miss = 0;
    uint64_t p4_semigroup = 0; /* p+4 has no prime factor ≡ 3 (mod 4) */
    uint64_t n4p_semigroup = 0;
    uint64_t checked_id = 0, bad_id = 0;
    uint64_t by_class[6] = {0};
    uint64_t miss_class[6] = {0};

    printf("w_census  (%" PRIu64 ", %" PRIu64 "]\n", from, limit);
    uint64_t n0 = from < 6 ? 6 : from;
    for (uint64_t n = n0 + 1; n <= limit; n++) {
        if (!is_hard(n) || !is_prime64(n)) {
            if (n == UINT64_MAX) break;
            continue;
        }
        hard++;
        int cls = -1;
        int r = (int)(n % 840);
        for (int i = 0; i < 6; i++)
            if (r == HARD[i]) cls = i;
        if (cls >= 0) by_class[cls]++;

        int h4p = try_4p_plus_1(n);
        int hp4 = try_p_plus_4(n);
        int hfab = 0;
        if (!h4p && !hp4) {
            both_linear_miss++;
            hfab = try_any_fab(n);
        }
        if (!has_prime_3mod4(n + 4)) p4_semigroup++;
        if (!has_prime_3mod4(4 * n + 1)) n4p_semigroup++;

        if (h4p) a4p++;
        if (hp4) ap4++;
        if (hfab) afab++;
        if (h4p && !hp4) only4p++;
        if (hp4 && !h4p) onlyp4++;
        if (hfab && !h4p && !hp4) {
            onlyfab++;
            if (!first_onlyfab) first_onlyfab = n;
        }

        int hit = h4p || hp4 || hfab;

        if (hit) {
            w++;
            if (checked_id < 200) {
                if (h4p && !verify_4p_plus_1(n)) bad_id++;
                if (hp4 && !verify_p_plus_4(n)) bad_id++;
                checked_id++;
            }
        } else {
            miss++;
            if (cls >= 0) miss_class[cls]++;
            if (!first_miss) first_miss = n;
            printf("SURVIVOR  p=%" PRIu64 "  class=%d  4p+1=%d  p+4=%d  fab=%d\n",
                   n, HARD[cls < 0 ? 0 : cls], h4p, hp4, hfab);
        }
        if (n == UINT64_MAX) break;
    }

    printf("hard=%" PRIu64 "\n", hard);
    printf("W_hit=%" PRIu64 "  W_miss=%" PRIu64 "  first_miss=%" PRIu64 "\n", w, miss,
           first_miss);
    printf("clause  4p+1=%" PRIu64 "  p+4=%" PRIu64 "  fab_after_linear_miss=%" PRIu64 "\n",
           a4p, ap4, afab);
    printf("only    4p+1=%" PRIu64 "  p+4=%" PRIu64 "  fab=%" PRIu64 "  first_onlyfab=%" PRIu64
           "\n",
           only4p, onlyp4, onlyfab, first_onlyfab);
    printf("linear_both_miss=%" PRIu64 "  (these needed fab or are survivors)\n",
           both_linear_miss);
    printf("p+4 all primes ≡1 (mod 4)=%" PRIu64 "\n", p4_semigroup);
    printf("4p+1 all primes ≡1 (mod 4)=%" PRIu64 "\n", n4p_semigroup);
    printf("identity_checks=%" PRIu64 "  failures=%" PRIu64 "\n", checked_id, bad_id);
    printf("hard by class:");
    for (int i = 0; i < 6; i++) printf("  %d:%" PRIu64, HARD[i], by_class[i]);
    printf("\n");
    return miss ? 1 : 0;
}
