#define _POSIX_C_SOURCE 200809L
/* CC.kernel — fast Mordell-hard Erdős–Straus witness engine.
 *
 * Explicit two-target / fab / linear search only.
 * Does not prove the conjecture.
 */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define HARD_N 6
static const int HARD[HARD_N] = {1, 121, 169, 289, 361, 529};

typedef struct {
    uint64_t d[8];
    int n;
} big_t;

typedef struct {
    uint64_t p;
    char method[32];
    char kind[16];
    char layer[16];
    uint64_t k, A, B, D, T;
    big_t x, y, z;
} wit_t;

static uint8_t *sieve;
static uint32_t *primes;
static int nprimes;
static uint64_t sieve_n;

static void die(const char *m) {
    fprintf(stderr, "CC.kernel: %s\n", m);
    exit(1);
}

static void big_zero(big_t *a) {
    memset(a, 0, sizeof(*a));
    a->n = 1;
}

static void big_set(big_t *a, uint64_t v) {
    big_zero(a);
    a->d[0] = v;
}

static void big_mul_u64(big_t *a, uint64_t m) {
    unsigned __int128 carry = 0;
    for (int i = 0; i < a->n || carry; i++) {
        if (i == 8) die("bigint overflow");
        if (i >= a->n) {
            a->d[i] = 0;
            a->n = i + 1;
        }
        unsigned __int128 t = (unsigned __int128)a->d[i] * m + carry;
        a->d[i] = (uint64_t)t;
        carry = t >> 64;
    }
}

static void big_mul(big_t *c, const big_t *a, const big_t *b) {
    big_t r;
    memset(&r, 0, sizeof(r));
    r.n = 1;
    for (int i = 0; i < a->n; i++) {
        unsigned __int128 carry = 0;
        for (int j = 0; j < b->n || carry; j++) {
            int k = i + j;
            if (k >= 8) die("bigint overflow");
            unsigned __int128 t = (unsigned __int128)r.d[k] +
                                  (unsigned __int128)a->d[i] * (j < b->n ? b->d[j] : 0) +
                                  carry;
            r.d[k] = (uint64_t)t;
            carry = t >> 64;
            if (k + 1 > r.n) r.n = k + 1;
        }
    }
    *c = r;
}

static void big_add(big_t *a, const big_t *b) {
    unsigned __int128 carry = 0;
    int n = a->n > b->n ? a->n : b->n;
    for (int i = 0; i < n || carry; i++) {
        if (i == 8) die("bigint overflow");
        unsigned __int128 t = carry + (i < a->n ? a->d[i] : 0) + (i < b->n ? b->d[i] : 0);
        a->d[i] = (uint64_t)t;
        carry = t >> 64;
        if (i + 1 > a->n) a->n = i + 1;
    }
}

static int big_cmp(const big_t *a, const big_t *b) {
    int n = a->n > b->n ? a->n : b->n;
    for (int i = n - 1; i >= 0; i--) {
        uint64_t da = i < a->n ? a->d[i] : 0;
        uint64_t db = i < b->n ? b->d[i] : 0;
        if (da > db) return 1;
        if (da < db) return -1;
    }
    return 0;
}

static void big_print(const big_t *a, FILE *f) {
    char buf[160];
    uint64_t tmp[8];
    int n = a->n;
    memcpy(tmp, a->d, sizeof(tmp));
    if (n == 1 && tmp[0] == 0) {
        fputc('0', f);
        return;
    }
    int pos = (int)sizeof(buf) - 1;
    buf[pos] = 0;
    while (n > 1 || tmp[0]) {
        unsigned __int128 rem = 0;
        for (int i = n - 1; i >= 0; i--) {
            unsigned __int128 cur = (rem << 64) | tmp[i];
            tmp[i] = (uint64_t)(cur / 10);
            rem = cur % 10;
        }
        buf[--pos] = (char)('0' + (int)rem);
        while (n > 1 && tmp[n - 1] == 0) n--;
    }
    fputs(buf + pos, f);
}

static int is_hard(uint64_t p) {
    int r = (int)(p % 840);
    for (int i = 0; i < HARD_N; i++)
        if (r == HARD[i]) return 1;
    return 0;
}

static void build_sieve(uint64_t n) {
    sieve_n = n;
    sieve = calloc(n + 1, 1);
    if (!sieve) die("oom sieve");
    if (n >= 2) sieve[2] = 1;
    for (uint64_t i = 3; i <= n; i += 2) sieve[i] = 1;
    for (uint64_t i = 3; i * i <= n; i += 2)
        if (sieve[i])
            for (uint64_t j = i * i; j <= n; j += i) sieve[j] = 0;
    nprimes = 0;
    if (n >= 2) nprimes++;
    for (uint64_t i = 3; i <= n; i += 2)
        if (sieve[i]) nprimes++;
    primes = malloc((size_t)nprimes * sizeof(uint32_t));
    if (!primes) die("oom primes");
    int k = 0;
    if (n >= 2) primes[k++] = 2;
    for (uint64_t i = 3; i <= n; i += 2)
        if (sieve[i]) primes[k++] = (uint32_t)i;
}

static int factor64(uint64_t n, uint64_t *ps, int *es, int cap) {
    int c = 0;
    for (int i = 0; i < nprimes; i++) {
        uint64_t p = primes[i];
        if (p * p > n) break;
        if (n % p == 0) {
            int e = 0;
            while (n % p == 0) {
                n /= p;
                e++;
            }
            if (c == cap) die("too many prime factors");
            ps[c] = p;
            es[c] = e;
            c++;
        }
        if (n == 1) return c;
    }
    if (n > 1) {
        if (c == cap) die("too many prime factors");
        ps[c] = n;
        es[c] = 1;
        c++;
    }
    return c;
}

static uint64_t gcd64(uint64_t a, uint64_t b) {
    while (b) {
        uint64_t t = a % b;
        a = b;
        b = t;
    }
    return a;
}

static int jacobi64(int64_t a, uint64_t n) {
    if (n == 0 || (n & 1) == 0) return 0;
    a %= (int64_t)n;
    if (a < 0) a += (int64_t)n;
    int s = 1;
    uint64_t aa = (uint64_t)a;
    while (aa) {
        while ((aa & 1) == 0) {
            aa >>= 1;
            uint64_t m = n & 7;
            if (m == 3 || m == 5) s = -s;
        }
        uint64_t t = aa;
        aa = n;
        n = t;
        if ((aa & 3) == 3 && (n & 3) == 3) s = -s;
        aa %= n;
    }
    return n == 1 ? s : 0;
}

static uint64_t modpow(uint64_t a, int64_t e, uint64_t m) {
    if (e < 0) {
        /* inverse then positive power */
        int64_t ee = -e;
        uint64_t inv = 0;
        int64_t t = 0, nt = 1;
        int64_t r = (int64_t)m, nr = (int64_t)(a % m);
        while (nr != 0) {
            int64_t q = r / nr;
            int64_t tmp = nt;
            nt = t - q * nt;
            t = tmp;
            tmp = nr;
            nr = r - q * nr;
            r = tmp;
        }
        if (r != 1 && r != -1) return 0;
        if (t < 0) t += (int64_t)m;
        inv = (uint64_t)t;
        a = inv;
        e = ee;
    }
    uint64_t r = 1 % m;
    a %= m;
    uint64_t ue = (uint64_t)e;
    while (ue) {
        if (ue & 1) r = (uint64_t)((__uint128_t)r * a % m);
        a = (uint64_t)((__uint128_t)a * a % m);
        ue >>= 1;
    }
    return r;
}

typedef struct {
    uint64_t ps[16];
    int es[16];
    int n;
} fac_t;

static int dfs_target(const fac_t *f, int i, uint64_t val, uint64_t mod, uint64_t target,
                      int *zs) {
    if (i == f->n) return val == target;
    int e = f->es[i];
    for (int z = -e; z <= e; z++) {
        zs[i] = z;
        uint64_t nv = (uint64_t)((__uint128_t)val * modpow(f->ps[i], z, mod) % mod);
        if (dfs_target(f, i + 1, nv, mod, target, zs)) return 1;
    }
    return 0;
}

static void split_bdt(const fac_t *f, const int *zs, uint64_t *B, uint64_t *D, uint64_t *T) {
    uint64_t b = 1, d = 1, t = 1;
    for (int i = 0; i < f->n; i++) {
        int e = f->es[i], z = zs[i];
        uint64_t p = f->ps[i];
        if (z > 0) {
            for (int j = 0; j < z; j++) b *= p;
            for (int j = 0; j < e - z; j++) t *= p;
        } else if (z < 0) {
            for (int j = 0; j < -z; j++) d *= p;
            for (int j = 0; j < e + z; j++) t *= p;
        } else {
            for (int j = 0; j < e; j++) t *= p;
        }
    }
    *B = b;
    *D = d;
    *T = t;
}

static int fill_xy_type(wit_t *w, int type_ii) {
    /* Type II: x=ABTp, y=BTD, z=ATDp
       Type I:  x=ABTp, y=BTD, z=ATD */
    big_t A, B, D, T, p, t1;
    big_set(&A, w->A);
    big_set(&B, w->B);
    big_set(&D, w->D);
    big_set(&T, w->T);
    big_set(&p, w->p);
    big_mul(&w->x, &A, &B);
    big_mul(&t1, &w->x, &T);
    big_mul(&w->x, &t1, &p);
    big_mul(&w->y, &B, &T);
    big_mul(&t1, &w->y, &D);
    w->y = t1;
    big_mul(&w->z, &A, &T);
    big_mul(&t1, &w->z, &D);
    if (type_ii) {
        big_mul(&w->z, &t1, &p);
    } else {
        w->z = t1;
    }
    /* 4xyz == p(yz+xz+xy) */
    big_t yz, xz, xy, s, lhs, rhs, four;
    big_mul(&yz, &w->y, &w->z);
    big_mul(&xz, &w->x, &w->z);
    big_mul(&xy, &w->x, &w->y);
    s = yz;
    big_add(&s, &xz);
    big_add(&s, &xy);
    big_mul(&rhs, &p, &s);
    big_set(&four, 4);
    big_mul(&lhs, &four, &w->x);
    big_mul(&t1, &lhs, &w->y);
    big_mul(&lhs, &t1, &w->z);
    return big_cmp(&lhs, &rhs) == 0;
}

static int try_two_target(uint64_t p, uint64_t k, wit_t *w, const char *method, const char *layer) {
    if (k < 3 || (k & 3) != 3 || gcd64(k, p) != 1) return 0;
    if ((p + k) % 4) return 0;
    uint64_t C = (p + k) / 4;
    fac_t f;
    f.n = factor64(C, f.ps, f.es, 16);
    for (int i = 0; i < f.n; i++)
        if (gcd64(f.ps[i], k) != 1) return 0;
    int zs[16];
    uint64_t t_ii = (k - 1) % k;
    uint64_t invp = modpow(p, -1, k);
    if (!invp && (p % k) != 0) return 0;
    uint64_t t_i = (k - invp) % k;

    if (dfs_target(&f, 0, 1 % k, k, t_ii, zs)) {
        uint64_t B, D, T;
        split_bdt(&f, zs, &B, &D, &T);
        if ((B + D) % k) return 0;
        w->p = p;
        snprintf(w->method, sizeof w->method, "%s", method);
        snprintf(w->kind, sizeof w->kind, "II");
        snprintf(w->layer, sizeof w->layer, "%s", layer);
        w->k = k;
        w->A = (B + D) / k;
        w->B = B;
        w->D = D;
        w->T = T;
        return fill_xy_type(w, 1);
    }
    if (dfs_target(&f, 0, 1 % k, k, t_i, zs)) {
        uint64_t B, D, T;
        split_bdt(&f, zs, &B, &D, &T);
        if ((uint64_t)(((__uint128_t)D + (__uint128_t)p * B) % k)) return 0;
        w->p = p;
        snprintf(w->method, sizeof w->method, "%s", method);
        snprintf(w->kind, sizeof w->kind, "I");
        snprintf(w->layer, sizeof w->layer, "%s", layer);
        w->k = k;
        w->A = (D + p * B) / k;
        w->B = B;
        w->D = D;
        w->T = T;
        return fill_xy_type(w, 0);
    }
    return 0;
}

static uint64_t divisor_in_class(uint64_t n, uint64_t mod, uint64_t residue) {
    uint64_t ps[16];
    int es[16];
    int c = factor64(n, ps, es, 16);
    /* residue -> one divisor */
    uint64_t *val = calloc(mod, sizeof(uint64_t));
    uint8_t *have = calloc(mod, 1);
    if (!val || !have) die("oom class");
    have[1 % mod] = 1;
    val[1 % mod] = 1;
    uint64_t tgt = residue % mod;
    for (int i = 0; i < c; i++) {
        uint64_t q = ps[i];
        int e = es[i];
        uint64_t *nval = calloc(mod, sizeof(uint64_t));
        uint8_t *nhave = calloc(mod, 1);
        if (!nval || !nhave) die("oom class");
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
            uint64_t out = val[tgt];
            free(val);
            free(have);
            return out;
        }
    }
    uint64_t out = have[tgt] ? val[tgt] : 0;
    free(val);
    free(have);
    return out;
}

static int try_p_plus_4(uint64_t p, wit_t *w) {
    uint64_t q = divisor_in_class(p + 4, 4, 3);
    if (!q) return 0;
    uint64_t m = (q + 1) / 4;
    if ((m * p + 1) % q) return 0;
    uint64_t v = (m * p + 1) / q;
    w->p = p;
    snprintf(w->method, sizeof w->method, "p+4");
    snprintf(w->kind, sizeof w->kind, "linear");
    snprintf(w->layer, sizeof w->layer, "theorem");
    w->k = q;
    w->A = m;
    w->B = 1;
    w->D = 1;
    w->T = v;
    big_set(&w->x, v);
    big_set(&w->y, m * p);
    big_set(&w->z, m * p);
    big_mul_u64(&w->z, v);
    return 1;
}

static int try_4p_plus_1(uint64_t p, wit_t *w) {
    uint64_t n = 4 * p + 1;
    uint64_t F = divisor_in_class(n, 4, 3);
    if (!F) return 0;
    uint64_t G = n / F;
    if ((G % 4) != 3) return 0;
    uint64_t u = (F + 1) / 4;
    uint64_t v = (G + 1) / 4;
    w->p = p;
    snprintf(w->method, sizeof w->method, "4p+1");
    snprintf(w->kind, sizeof w->kind, "linear");
    snprintf(w->layer, sizeof w->layer, "theorem");
    w->k = F;
    w->A = u;
    w->B = v;
    w->D = 1;
    w->T = 1;
    big_set(&w->x, u * v);
    big_set(&w->y, p * v);
    big_set(&w->z, p * u);
    return 1;
}

static int try_fab(uint64_t p, int a, int b, wit_t *w) {
    if (gcd64((uint64_t)a, (uint64_t)b) != 1) return 0;
    if ((uint64_t)a >= p || (uint64_t)b >= p) return 0;
    uint64_t lin = (uint64_t)a + (uint64_t)b * p;
    uint64_t mod = 4ull * (uint64_t)a * (uint64_t)b;
    uint64_t target = (mod - (p % mod)) % mod;
    uint64_t k = divisor_in_class(lin, mod, target);
    if (!k) return 0;
    if ((p + k) % mod) return 0;
    uint64_t t = (p + k) / mod;
    if (lin % k) return 0;
    uint64_t q = lin / k;
    w->p = p;
    snprintf(w->method, sizeof w->method, "fab(%d,%d)", a, b);
    snprintf(w->kind, sizeof w->kind, "fab");
    snprintf(w->layer, sizeof w->layer, "window");
    w->k = k;
    w->A = (uint64_t)a;
    w->B = (uint64_t)b;
    w->D = t;
    w->T = q;
    /* x=abt, y=aqt, z=bpqt */
    big_set(&w->x, (uint64_t)a * (uint64_t)b);
    big_mul_u64(&w->x, t);
    big_set(&w->y, (uint64_t)a * q);
    big_mul_u64(&w->y, t);
    big_set(&w->z, (uint64_t)b * p);
    big_mul_u64(&w->z, q);
    big_mul_u64(&w->z, t);
    return 1;
}

static void emit(const wit_t *w) {
    printf("{\"kernel\":\"CC.kernel\",\"solved\":true,\"p\":%" PRIu64
           ",\"layer\":\"%s\",\"method\":\"%s\",\"kind\":\"%s\"",
           w->p, w->layer, w->method, w->kind);
    if (w->kind[0] == 'I' || strcmp(w->kind, "II") == 0) {
        printf(",\"k\":%" PRIu64 ",\"A\":%" PRIu64 ",\"B\":%" PRIu64 ",\"D\":%" PRIu64
               ",\"T\":%" PRIu64,
               w->k, w->A, w->B, w->D, w->T);
    }
    printf(",\"x\":\"");
    big_print(&w->x, stdout);
    printf("\",\"y\":\"");
    big_print(&w->y, stdout);
    printf("\",\"z\":\"");
    big_print(&w->z, stdout);
    printf("\"}\n");
}

static int solve_through(uint64_t p, wit_t *w, const char *through, uint64_t kmax) {
    int want_th = 1;
    int want_win = strcmp(through, "theorem") != 0;
    int want_se = strcmp(through, "search") == 0;

    if (want_th) {
        if (try_4p_plus_1(p, w)) return 1;
        if (try_p_plus_4(p, w)) return 1;
        const uint64_t ks[4] = {3, 7, 11, 15};
        for (int i = 0; i < 4; i++) {
            char name[24];
            snprintf(name, sizeof name, "corridor[%" PRIu64 "]", ks[i]);
            if (try_two_target(p, ks[i], w, name, "theorem")) return 1;
        }
    }
    if (want_win) {
        static const int pairs[][2] = {
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
        int np = (int)(sizeof pairs / sizeof pairs[0]);
        for (int i = 0; i < np; i++)
            if (try_fab(p, pairs[i][0], pairs[i][1], w)) return 1;
    }
    if (want_se) {
        for (uint64_t h = 4; 4 * h + 3 <= kmax; h++) {
            uint64_t k = 4 * h + 3;
            char name[40];
            snprintf(name, sizeof name, "corridor[%" PRIu64 "]", k);
            if (try_two_target(p, k, w, name, "search")) return 1;
        }
        for (int i = 0; i < nprimes; i++) {
            uint64_t ell = primes[i];
            if (ell < 11 || ell == p) continue;
            if (ell > 300) break;
            if (jacobi64((int64_t)ell, p) != -1) continue;
            if ((ell & 3) == 3) {
                char name[24];
                snprintf(name, sizeof name, "nr-shift[%" PRIu64 "]", ell);
                if (try_two_target(p, ell, w, name, "search")) return 1;
            }
            uint64_t k = (4 * ell - (p % (4 * ell))) % (4 * ell);
            if (k == 0) k = 4 * ell;
            char name[28];
            snprintf(name, sizeof name, "nr-aligned[%" PRIu64 "]", ell);
            if (try_two_target(p, k, w, name, "search")) return 1;
        }
    }
    return 0;
}

static int try_even(uint64_t n, wit_t *w) {
    if (n % 2) return 0;
    uint64_t m = n / 2;
    w->p = n;
    snprintf(w->method, sizeof w->method, "even");
    snprintf(w->kind, sizeof w->kind, "identity");
    snprintf(w->layer, sizeof w->layer, "classical");
    w->k = w->A = w->B = w->D = w->T = 0;
    big_set(&w->x, m);
    big_set(&w->y, m + 1);
    big_set(&w->z, m * (m + 1));
    return 1;
}

static int try_3mod4(uint64_t n, wit_t *w) {
    if (n % 4 != 3) return 0;
    uint64_t m = (n - 3) / 4;
    w->p = n;
    snprintf(w->method, sizeof w->method, "3mod4");
    snprintf(w->kind, sizeof w->kind, "identity");
    snprintf(w->layer, sizeof w->layer, "classical");
    w->k = w->A = w->B = w->D = w->T = 0;
    big_set(&w->x, m + 2);
    big_set(&w->y, (m + 1) * (m + 2));
    big_set(&w->z, n * (m + 1));
    return 1;
}

static int try_2mod3(uint64_t n, wit_t *w) {
    if (n % 3 != 2) return 0;
    uint64_t a = (n + 1) / 3;
    w->p = n;
    snprintf(w->method, sizeof w->method, "2mod3");
    snprintf(w->kind, sizeof w->kind, "identity");
    snprintf(w->layer, sizeof w->layer, "classical");
    w->k = w->A = w->B = w->D = w->T = 0;
    big_set(&w->x, n);
    big_set(&w->y, a);
    big_set(&w->z, n * a);
    return 1;
}

static int try_5mod8(uint64_t n, wit_t *w) {
    if (n % 8 != 5) return 0;
    uint64_t t = (n + 3) / 8;
    w->p = n;
    snprintf(w->method, sizeof w->method, "5mod8");
    snprintf(w->kind, sizeof w->kind, "identity");
    snprintf(w->layer, sizeof w->layer, "classical");
    w->k = w->A = w->B = w->D = w->T = 0;
    big_set(&w->x, 2 * t);
    big_set(&w->y, 2 * t * n);
    big_set(&w->z, n * t);
    return 1;
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

/* Deterministic for every 64-bit n (Jim Sinclair bases). */
static int is_prime64(uint64_t n) {
    if (n < 2) return 0;
    if (sieve && n < sieve_n) return sieve[n];
    static const uint64_t small[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31};
    for (int i = 0; i < 11; i++) {
        if (n == small[i]) return 1;
        if (n % small[i] == 0) return 0;
    }
    for (int i = 0; i < nprimes; i++) {
        uint64_t p = primes[i];
        if (p > n / p) return 1;
        if (n % p == 0) return 0;
    }
    static const uint64_t bases[] = {
        2ull, 325ull, 9375ull, 28178ull, 450775ull, 9780504ull, 1795265022ull
    };
    for (int i = 0; i < 7; i++)
        if (!mr_check(n, bases[i])) return 0;
    return 1;
}

static int solve_any(uint64_t n, wit_t *w, const char *through, uint64_t kmax);

static int solve_any(uint64_t n, wit_t *w, const char *through, uint64_t kmax) {
    memset(w, 0, sizeof *w);
    if (n < 2) return 0;
    if (try_even(n, w) || try_3mod4(n, w) || try_2mod3(n, w) || try_5mod8(n, w))
        return 1;
    if (is_prime64(n)) {
        if (is_hard(n) || n % 4 == 1)
            return solve_through(n, w, through, kmax);
        return 0;
    }
    uint64_t ps[16];
    int es[16];
    int c = factor64(n, ps, es, 16);
    if (c < 1) return 0;
    uint64_t q = ps[0];
    uint64_t scale = n / q;
    if (!solve_any(q, w, through, kmax)) return 0;
    w->p = n;
    snprintf(w->method, sizeof w->method, "scale-from-%" PRIu64, q);
    snprintf(w->kind, sizeof w->kind, "scaled");
    snprintf(w->layer, sizeof w->layer, "classical");
    big_mul_u64(&w->x, scale);
    big_mul_u64(&w->y, scale);
    big_mul_u64(&w->z, scale);
    return 1;
}

typedef struct {
    int hard, th, win, se, miss;
    uint64_t first_miss;
} tallies_t;

static tallies_t tally_hard(uint64_t from, uint64_t limit, uint64_t kmax) {
    tallies_t t;
    memset(&t, 0, sizeof t);
    if (from == UINT64_MAX) return t;
    for (uint64_t n = from + 1; n <= limit; n++) {
        if (n < 7 || !is_hard(n) || !is_prime64(n)) {
            if (n == UINT64_MAX) break;
            continue;
        }
        uint64_t p = n;
        t.hard++;
        wit_t w;
        if (solve_through(p, &w, "theorem", kmax)) {
            t.th++;
        } else if (solve_through(p, &w, "window", kmax) && !strcmp(w.layer, "window")) {
            t.win++;
        } else if (solve_through(p, &w, "search", kmax)) {
            if (!strcmp(w.layer, "search")) t.se++;
            else if (!strcmp(w.layer, "window")) t.win++;
            else t.th++;
        } else {
            t.miss++;
            if (!t.first_miss) t.first_miss = p;
        }
        if (n == UINT64_MAX) break;
    }
    return t;
}

static void ensure_ledger_parent(const char *path) {
    char dir[512];
    snprintf(dir, sizeof dir, "%s", path);
    char *slash = strrchr(dir, '/');
    if (!slash) return;
    *slash = 0;
    mkdir(dir, 0755);
}

static void write_status(const char *path, const tallies_t *t, uint64_t bound,
                         uint64_t kmax, int rounds, int until_proof) {
    ensure_ledger_parent(path);
    FILE *f = fopen(path, "w");
    if (!f) return;
    fprintf(f,
            "{\n"
            "  \"kernel\": \"CC.kernel\",\n"
            "  \"proof_status\": \"open\",\n"
            "  \"strike\": false,\n"
            "  \"reason\": \"Erdős–Straus remains open. Finite coverage is not a universal proof.\",\n"
            "  \"until_proof\": %s,\n"
            "  \"rounds\": %d,\n"
            "  \"last_bound\": %" PRIu64 ",\n"
            "  \"last_kmax\": %" PRIu64 ",\n"
            "  \"hard_seen\": %d,\n"
            "  \"theorem\": %d,\n"
            "  \"window\": %d,\n"
            "  \"search\": %d,\n"
            "  \"unsolved\": %d,\n"
            "  \"first_unsolved\": %" PRIu64 "\n"
            "}\n",
            until_proof ? "true" : "false", rounds, bound, kmax, t->hard, t->th, t->win,
            t->se, t->miss, t->first_miss);
    fclose(f);
}

static void usage(void) {
    fprintf(stderr,
            "CC.kernel — theorem / attack engine for Erdős–Straus\n"
            "  cc-kernel solve N [--k-max N] [--through theorem|window|search]\n"
            "  cc-kernel residual LIMIT [--from P] [--k-max N] [--stream] [--stop-on-letter]\n"
            "  cc-kernel census LIMIT [--from P] [--k-max N]\n"
            "  cc-kernel status\n"
            "  cc-kernel hunt [--until-proof] [--start N] [--max-bound N] [--rounds R] [--k-max N]\n");
}

int main(int argc, char **argv) {
    if (argc < 2) {
        usage();
        return 2;
    }
    const char *cmd = argv[1];
    uint64_t arg = 0;
    uint64_t kmax = 400;
    uint64_t start = 20000;
    uint64_t max_bound = 200000;
    uint64_t from = 0;
    int rounds = 3;
    int until_proof = 0;
    int stop_on_letter = 0;
    int stream = 0;
    const char *through = "search";
    char ledger_buf[512];
    const char *ledger_env = getenv("CC_KERNEL_LEDGER");
    if (ledger_env && ledger_env[0]) {
        snprintf(ledger_buf, sizeof ledger_buf, "%s", ledger_env);
    } else {
        char exe[512];
        ssize_t m = readlink("/proc/self/exe", exe, sizeof exe - 1);
        if (m > 0) {
            exe[m] = 0;
            char *slash = strrchr(exe, '/');
            if (slash) {
                *slash = 0;
                snprintf(ledger_buf, sizeof ledger_buf, "%s/ledger/status.json", exe);
            } else {
                snprintf(ledger_buf, sizeof ledger_buf, "ledger/status.json");
            }
        } else {
            snprintf(ledger_buf, sizeof ledger_buf, "ledger/status.json");
        }
    }
    const char *ledger = ledger_buf;

    int i = 2;
    if (argc > 2 && argv[2][0] != '-') {
        arg = strtoull(argv[2], NULL, 10);
        i = 3;
    }
    for (; i < argc; i++) {
        if (!strcmp(argv[i], "--k-max") && i + 1 < argc) kmax = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--through") && i + 1 < argc) through = argv[++i];
        else if (!strcmp(argv[i], "--start") && i + 1 < argc) start = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--max-bound") && i + 1 < argc) max_bound = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--rounds") && i + 1 < argc) rounds = (int)strtol(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--until-proof")) until_proof = 1;
        else if (!strcmp(argv[i], "--stop-on-letter")) stop_on_letter = 1;
        else if (!strcmp(argv[i], "--stream")) stream = 1;
        else if (!strcmp(argv[i], "--from") && i + 1 < argc) from = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--ledger") && i + 1 < argc) ledger = argv[++i];
        else {
            usage();
            return 2;
        }
    }

    if (!strcmp(cmd, "status")) {
        FILE *f = fopen(ledger, "r");
        if (!f) {
            printf("{\"kernel\":\"CC.kernel\",\"proof_status\":\"open\",\"strike\":false,"
                   "\"reason\":\"no hunt ledger yet; Erdős–Straus remains open\"}\n");
            return 0;
        }
        char buf[4096];
        size_t n = fread(buf, 1, sizeof buf - 1, f);
        fclose(f);
        buf[n] = 0;
        fputs(buf, stdout);
        if (n == 0 || buf[n - 1] != '\n') fputc('\n', stdout);
        return 0;
    }

    /* Small factor base. Residual/hunt walk hard classes and use Miller–Rabin,
       so the hunt is not capped by a prefix sieve. */
    build_sieve(1000003ull);

    if (!strcmp(cmd, "solve")) {
        if (arg < 2) {
            usage();
            return 2;
        }
        wit_t w;
        if (!solve_any(arg, &w, through, kmax)) {
            printf("{\"kernel\":\"CC.kernel\",\"solved\":false,\"n\":%" PRIu64 "}\n", arg);
            return 1;
        }
        emit(&w);
        return 0;
    }

    if (!strcmp(cmd, "hunt")) {
        uint64_t bound = start;
        int r;
        tallies_t last;
        memset(&last, 0, sizeof last);
        for (r = 1;; r++) {
            last = tally_hard(0, bound, kmax);
            write_status(ledger, &last, bound, kmax, r, until_proof);
            printf("{\"kernel\":\"CC.kernel\",\"round\":%d,\"bound\":%" PRIu64
                   ",\"kmax\":%" PRIu64 ",\"hard\":%d,\"theorem\":%d,\"window\":%d,"
                   "\"search\":%d,\"unsolved\":%d,\"first_unsolved\":%" PRIu64
                   ",\"proof_status\":\"open\",\"strike\":false}\n",
                   r, bound, kmax, last.hard, last.th, last.win, last.se, last.miss,
                   last.first_miss);
            fflush(stdout);
            if (last.miss && kmax < 4000) {
                kmax *= 2;
                if (kmax > 4000) kmax = 4000;
                continue;
            }
            if (!until_proof && r >= rounds) break;
            if (until_proof) {
                if (max_bound && bound >= max_bound && last.miss == 0) break;
                if (max_bound && bound >= max_bound) break;
                if (bound >= 2000000) break;
                bound *= 2;
                if (max_bound && bound > max_bound) bound = max_bound;
                continue;
            }
            break;
        }
        printf("{\"kernel\":\"CC.kernel\",\"proof_status\":\"open\",\"strike\":false,"
               "\"reason\":\"Erdős–Straus remains open. A finished hunt is not a proof.\","
               "\"rounds\":%d,\"last_bound\":%" PRIu64 ",\"unsolved\":%d}\n",
               r, bound, last.miss);
        return last.miss ? 1 : 0;
    }

    if (!strcmp(cmd, "residual") || !strcmp(cmd, "census")) {
        int census = !strcmp(cmd, "census");
        uint64_t limit = arg;
        int th_hit = 0, win_hit = 0, se_hit = 0, miss = 0, nhard = 0;
        int complete = 1;
        uint64_t stopped_on = 0;
        int first = 1;
        if (!stream) {
            printf("{\"kernel\":\"CC.kernel\",\"cmd\":\"%s\",\"limit\":%" PRIu64
                   ",\"from\":%" PRIu64 ",\"kmax\":%" PRIu64 ",\"hits\":[\n",
                   cmd, limit, from, kmax);
        }
        uint64_t n = (from == UINT64_MAX) ? UINT64_MAX : from + 1;
        for (; n <= limit; n++) {
            if (n < 7 || !is_hard(n) || !is_prime64(n)) {
                if (n == UINT64_MAX) break;
                continue;
            }
            uint64_t p = n;
            nhard++;
            wit_t w;
            memset(&w, 0, sizeof w);
            int letter = 0;
            if (solve_through(p, &w, "theorem", kmax)) {
                th_hit++;
                if (stream) {
                    printf("{\"kernel\":\"CC.kernel\",\"type\":\"progress\",\"p\":%" PRIu64
                           ",\"layer\":\"theorem\",\"solved\":true}\n",
                           p);
                    fflush(stdout);
                } else if (census) {
                    if (!first) printf(",\n");
                    first = 0;
                    emit(&w);
                }
            } else if (solve_through(p, &w, "window", kmax)) {
                if (!strcmp(w.layer, "window")) {
                    win_hit++;
                    if (stream) {
                        emit(&w);
                        fflush(stdout);
                    } else {
                        if (!first) printf(",\n");
                        first = 0;
                        emit(&w);
                    }
                } else {
                    th_hit++;
                    if (stream) {
                        printf("{\"kernel\":\"CC.kernel\",\"type\":\"progress\",\"p\":%" PRIu64
                               ",\"layer\":\"theorem\",\"solved\":true}\n",
                               p);
                        fflush(stdout);
                    }
                }
            } else if (solve_through(p, &w, "search", kmax)) {
                if (!strcmp(w.layer, "search")) {
                    se_hit++;
                    if (stop_on_letter) letter = 1;
                } else if (!strcmp(w.layer, "window")) {
                    win_hit++;
                } else {
                    th_hit++;
                }
                if (stream) {
                    emit(&w);
                    fflush(stdout);
                } else {
                    if (!first) printf(",\n");
                    first = 0;
                    emit(&w);
                }
            } else {
                miss++;
                if (stream) {
                    printf("{\"kernel\":\"CC.kernel\",\"solved\":false,\"p\":%" PRIu64
                           ",\"mod840\":%" PRIu64 "}\n",
                           p, p % 840);
                    fflush(stdout);
                } else {
                    if (!first) printf(",\n");
                    first = 0;
                    printf("{\"kernel\":\"CC.kernel\",\"solved\":false,\"p\":%" PRIu64
                           ",\"mod840\":%" PRIu64 "}",
                           p, p % 840);
                }
                if (stop_on_letter) letter = 1;
            }
            if (letter) {
                complete = 0;
                stopped_on = p;
                break;
            }
            if (n == UINT64_MAX) break;
        }
        if (stream) {
            printf("{\"kernel\":\"CC.kernel\",\"type\":\"window_done\",\"from\":%" PRIu64
                   ",\"limit\":%" PRIu64 ",\"hard_primes\":%d,\"theorem\":%d,"
                   "\"window\":%d,\"search\":%d,\"unsolved\":%d,\"complete\":%s,"
                   "\"stopped_on\":%" PRIu64 "}\n",
                   from, limit, nhard, th_hit, win_hit, se_hit, miss,
                   complete ? "true" : "false", stopped_on);
            fflush(stdout);
        } else {
            printf("\n],\"hard_primes\":%d,\"theorem\":%d,\"window\":%d,\"search\":%d,"
                   "\"unsolved\":%d,\"complete\":%s,\"stopped_on\":%" PRIu64
                   ",\"claim_boundary\":\"finite witnesses only; not a proof of "
                   "Erdős–Straus\"}\n",
                   nhard, th_hit, win_hit, se_hit, miss,
                   complete ? "true" : "false", stopped_on);
        }
        return miss ? 1 : 0;
    }

    usage();
    return 2;
}
