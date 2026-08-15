#define _POSIX_C_SOURCE 200809L
/*
 * cbap.kernel — CB-Advanced-Processing
 *
 * Letter-only Erdős–Straus targeting engine.
 * Built from the bb.kernel menu and the CC.kernel attack, rewritten as
 * four C channels. It does not prove the conjecture.
 *
 *   Channel A  ACQUIRE   hard-prime spectra (three CRT pairs mod 840)
 *   Channel B  LOCK      theorem + fab window a,b ≤ 11
 *   Channel C  TRACK     two-target corridor and NR shifts
 *   Channel D  VERDICT   LETTER = TRUE only if A–C all miss
 *
 * GREAT hits (window solves) are dropped. Only LETTER files are kept.
 */
#include <errno.h>
#include <inttypes.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define HARD_N 6
static const int HARD[HARD_N] = {1, 121, 169, 289, 361, 529};
static const int SPEC[3][2] = {{1, 121}, {169, 289}, {361, 529}};
static const char *SPEC_NAME[3] = {"A", "B", "C"};

#define DEFAULT_STEP 50000ull
#define DEFAULT_KMAX 400ull
#define DEFAULT_KMAX_CAP 4000ull

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

typedef struct {
    uint64_t scanned_through;
    uint64_t start_factor;
    uint64_t letters_found;
    uint64_t identified;
    uint64_t dropped;
    uint64_t kmax;
    uint64_t windows;
} seed_t;

static uint8_t *sieve;
static uint32_t *primes;
static int nprimes;
static uint64_t sieve_n;
static volatile sig_atomic_t halt_flag;
static char root_dir[512];
static char letters_dir[512];
static char seed_path[512];
static char journal_path[512];

static void die(const char *m) {
    fprintf(stderr, "cbap.kernel: %s\n", m);
    exit(1);
}

static void on_stop(int sig) {
    (void)sig;
    halt_flag = 1;
}

/* ---- SHA-256 (FIPS 180-4), for ES-LETTER-v1 numbers only ---- */

typedef struct {
    uint32_t h[8];
    uint64_t bits;
    uint8_t buf[64];
    size_t fill;
} sha256_t;

static uint32_t rotr32(uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }

static void sha256_init(sha256_t *s) {
    static const uint32_t iv[8] = {
        0x6a09e667ul, 0xbb67ae85ul, 0x3c6ef372ul, 0xa54ff53aul,
        0x510e527ful, 0x9b05688cul, 0x1f83d9abul, 0x5be0cd19ul};
    memcpy(s->h, iv, sizeof iv);
    s->bits = 0;
    s->fill = 0;
}

static void sha256_block(sha256_t *s, const uint8_t *p) {
    static const uint32_t K[64] = {
        0x428a2f98ul, 0x71374491ul, 0xb5c0fbcful, 0xe9b5dba5ul, 0x3956c25bul,
        0x59f111f1ul, 0x923f82a4ul, 0xab1c5ed5ul, 0xd807aa98ul, 0x12835b01ul,
        0x243185beul, 0x550c7dc3ul, 0x72be5d74ul, 0x80deb1feul, 0x9bdc06a7ul,
        0xc19bf174ul, 0xe49b69c1ul, 0xefbe4786ul, 0x0fc19dc6ul, 0x240ca1ccul,
        0x2de92c6ful, 0x4a7484aaul, 0x5cb0a9dcul, 0x76f988daul, 0x983e5152ul,
        0xa831c66dul, 0xb00327c8ul, 0xbf597fc7ul, 0xc6e00bf3ul, 0xd5a79147ul,
        0x06ca6351ul, 0x14292967ul, 0x27b70a85ul, 0x2e1b2138ul, 0x4d2c6dfcul,
        0x53380d13ul, 0x650a7354ul, 0x766a0abbul, 0x81c2c92eul, 0x92722c85ul,
        0xa2bfe8a1ul, 0xa81a664bul, 0xc24b8b70ul, 0xc76c51a3ul, 0xd192e819ul,
        0xd6990624ul, 0xf40e3585ul, 0x106aa070ul, 0x19a4c116ul, 0x1e376c08ul,
        0x2748774cul, 0x34b0bcb5ul, 0x391c0cb3ul, 0x4ed8aa4aul, 0x5b9cca4ful,
        0x682e6ff3ul, 0x748f82eeul, 0x78a5636ful, 0x84c87814ul, 0x8cc70208ul,
        0x90befffaul, 0xa4506cebul, 0xbef9a3f7ul, 0xc67178f2ul};
    uint32_t w[64];
    for (int i = 0; i < 16; i++)
        w[i] = ((uint32_t)p[4 * i] << 24) | ((uint32_t)p[4 * i + 1] << 16) |
               ((uint32_t)p[4 * i + 2] << 8) | (uint32_t)p[4 * i + 3];
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >> 3);
        uint32_t s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    uint32_t a = s->h[0], b = s->h[1], c = s->h[2], d = s->h[3];
    uint32_t e = s->h[4], f = s->h[5], g = s->h[6], h = s->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + K[i] + w[i];
        uint32_t S0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22);
        uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + maj;
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }
    s->h[0] += a;
    s->h[1] += b;
    s->h[2] += c;
    s->h[3] += d;
    s->h[4] += e;
    s->h[5] += f;
    s->h[6] += g;
    s->h[7] += h;
}

static void sha256_update(sha256_t *s, const void *data, size_t n) {
    const uint8_t *p = data;
    s->bits += (uint64_t)n * 8;
    while (n) {
        size_t take = 64 - s->fill;
        if (take > n) take = n;
        memcpy(s->buf + s->fill, p, take);
        s->fill += take;
        p += take;
        n -= take;
        if (s->fill == 64) {
            sha256_block(s, s->buf);
            s->fill = 0;
        }
    }
}

static void sha256_final(sha256_t *s, uint8_t out[32]) {
    s->buf[s->fill++] = 0x80;
    if (s->fill > 56) {
        while (s->fill < 64) s->buf[s->fill++] = 0;
        sha256_block(s, s->buf);
        s->fill = 0;
    }
    while (s->fill < 56) s->buf[s->fill++] = 0;
    for (int i = 7; i >= 0; i--) s->buf[s->fill++] = (uint8_t)(s->bits >> (8 * i));
    sha256_block(s, s->buf);
    for (int i = 0; i < 8; i++) {
        out[4 * i] = (uint8_t)(s->h[i] >> 24);
        out[4 * i + 1] = (uint8_t)(s->h[i] >> 16);
        out[4 * i + 2] = (uint8_t)(s->h[i] >> 8);
        out[4 * i + 3] = (uint8_t)s->h[i];
    }
}

static void sha256_hex16(const char *text, char hex[33]) {
    sha256_t s;
    uint8_t d[32];
    sha256_init(&s);
    sha256_update(&s, text, strlen(text));
    sha256_final(&s, d);
    for (int i = 0; i < 16; i++) sprintf(hex + 2 * i, "%02x", d[i]);
    hex[32] = 0;
}

/* ---- bigint / arithmetic (same identities as CC.kernel) ---- */

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

static int spectrum_of(uint64_t p) {
    int r = (int)(p % 840);
    for (int s = 0; s < 3; s++)
        if (r == SPEC[s][0] || r == SPEC[s][1]) return s;
    return -1;
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
        int64_t ee = -e;
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
        a = (uint64_t)t;
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
    if (type_ii) big_mul(&w->z, &t1, &p);
    else w->z = t1;
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
    big_set(&w->x, (uint64_t)a * (uint64_t)b);
    big_mul_u64(&w->x, t);
    big_set(&w->y, (uint64_t)a * q);
    big_mul_u64(&w->y, t);
    big_set(&w->z, (uint64_t)b * p);
    big_mul_u64(&w->z, q);
    big_mul_u64(&w->z, t);
    return 1;
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

static int channel_b_lock(uint64_t p, wit_t *w) {
    memset(w, 0, sizeof *w);
    if (try_4p_plus_1(p, w)) return 1;
    if (try_p_plus_4(p, w)) return 1;
    const uint64_t ks[4] = {3, 7, 11, 15};
    for (int i = 0; i < 4; i++) {
        char name[24];
        snprintf(name, sizeof name, "corridor[%" PRIu64 "]", ks[i]);
        if (try_two_target(p, ks[i], w, name, "theorem")) return 1;
    }
    int np = (int)(sizeof FAB_PAIRS / sizeof FAB_PAIRS[0]);
    for (int i = 0; i < np; i++)
        if (try_fab(p, FAB_PAIRS[i][0], FAB_PAIRS[i][1], w)) return 1;
    return 0;
}

static int channel_c_track(uint64_t p, wit_t *w, uint64_t kmax) {
    memset(w, 0, sizeof *w);
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
    return 0;
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

/* ---- paths, seed, letters ---- */

static void resolve_root(void) {
    char exe[512];
    ssize_t m = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (m > 0) {
        exe[m] = 0;
        char *slash = strrchr(exe, '/');
        if (slash) {
            *slash = 0;
            snprintf(root_dir, sizeof root_dir, "%s", exe);
        } else {
            snprintf(root_dir, sizeof root_dir, ".");
        }
    } else {
        snprintf(root_dir, sizeof root_dir, ".");
    }
    snprintf(letters_dir, sizeof letters_dir, "%s/letters", root_dir);
    snprintf(seed_path, sizeof seed_path, "%s/state/seed", root_dir);
    snprintf(journal_path, sizeof journal_path, "%s/letters/JOURNAL.md", root_dir);
    mkdir(letters_dir, 0755);
    char state[512];
    snprintf(state, sizeof state, "%s/state", root_dir);
    mkdir(state, 0755);
}

static seed_t default_seed(uint64_t start) {
    seed_t s;
    memset(&s, 0, sizeof s);
    s.scanned_through = start;
    s.start_factor = start;
    s.kmax = DEFAULT_KMAX;
    return s;
}

static seed_t load_seed(void) {
    seed_t s = default_seed(0);
    FILE *f = fopen(seed_path, "r");
    if (!f) return s;
    char line[256];
    while (fgets(line, sizeof line, f)) {
        uint64_t v;
        if (sscanf(line, "scanned_through=%" SCNu64, &v) == 1) s.scanned_through = v;
        else if (sscanf(line, "start_factor=%" SCNu64, &v) == 1) s.start_factor = v;
        else if (sscanf(line, "letters_found=%" SCNu64, &v) == 1) s.letters_found = v;
        else if (sscanf(line, "identified=%" SCNu64, &v) == 1) s.identified = v;
        else if (sscanf(line, "dropped=%" SCNu64, &v) == 1) s.dropped = v;
        else if (sscanf(line, "kmax=%" SCNu64, &v) == 1) s.kmax = v;
        else if (sscanf(line, "windows=%" SCNu64, &v) == 1) s.windows = v;
    }
    fclose(f);
    if (!s.kmax) s.kmax = DEFAULT_KMAX;
    return s;
}

static void save_seed(const seed_t *s) {
    char tmp[540];
    snprintf(tmp, sizeof tmp, "%s.tmp", seed_path);
    FILE *f = fopen(tmp, "w");
    if (!f) return;
    fprintf(f,
            "kernel=cbap\n"
            "scanned_through=%" PRIu64 "\n"
            "start_factor=%" PRIu64 "\n"
            "letters_found=%" PRIu64 "\n"
            "identified=%" PRIu64 "\n"
            "dropped=%" PRIu64 "\n"
            "kmax=%" PRIu64 "\n"
            "windows=%" PRIu64 "\n",
            s->scanned_through, s->start_factor, s->letters_found, s->identified,
            s->dropped, s->kmax, s->windows);
    fclose(f);
    rename(tmp, seed_path);
}

static uint64_t random_start(void) {
    uint64_t r = 0;
    FILE *u = fopen("/dev/urandom", "rb");
    if (u) {
        if (fread(&r, sizeof r, 1, u) != 1) r = (uint64_t)time(NULL);
        fclose(u);
    } else {
        r = (uint64_t)time(NULL) ^ ((uint64_t)getpid() << 16);
    }
    uint64_t lo = 1000000ull;
    uint64_t hi = 10000000000ull;
    return lo + (r % (hi - lo));
}

static void journal(const char *line) {
    FILE *f = fopen(journal_path, "a");
    if (!f) return;
    time_t now = time(NULL);
    struct tm tm;
    gmtime_r(&now, &tm);
    char ts[32];
    strftime(ts, sizeof ts, "%Y-%m-%dT%H:%M:%SZ", &tm);
    fprintf(f, "- %s  %s\n", ts, line);
    fclose(f);
}

static void letter_key(uint64_t n, const char *rule, char *out, size_t cap) {
    snprintf(out, cap, "ES-LETTER-v1\nrule=%s\nn=%" PRIu64 "\nextra=\n", rule, n);
}

static void save_letter(uint64_t n, int spectrum, uint64_t kmax) {
    char key[160];
    char hex[33];
    letter_key(n, "unsolved_after_search", key, sizeof key);
    sha256_hex16(key, hex);
    char path[600];
    snprintf(path, sizeof path, "%s/L-%s.md", letters_dir, hex);
    if (access(path, F_OK) == 0) return;
    FILE *f = fopen(path, "w");
    if (!f) die("cannot write letter");
    fprintf(f,
            "# LETTER — unsolved_after_search\n\n"
            "**Grade:** LETTER\n"
            "**Kernel:** cbap.kernel\n"
            "**Letter number:** (first 128 bits of SHA-256 of ES-LETTER-v1)\n"
            "**Letter id:** `L-%s`\n"
            "**n:** %" PRIu64 "\n"
            "**Spectrum:** %s  (n ≡ %d or %d mod 840)\n"
            "**Channel D:** LETTER = TRUE\n"
            "**kmax searched:** %" PRIu64 "\n\n"
            "## What was found\n\n"
            "Channel A acquired a Mordell-hard prime on spectrum %s.\n"
            "Channel B (theorem + fab window a,b ≤ 11) missed.\n"
            "Channel C (two-target corridor and NR shifts through kmax) missed.\n"
            "Channel D therefore set LETTER = TRUE and collected this file.\n\n"
            "## How to check\n\n"
            "This is an unsolved alarm, not a counterexample. A later larger\n"
            "k may still produce 4/n = 1/x + 1/y + 1/z. Confirm primality of n\n"
            "and that n ≡ 1, 121, 169, 289, 361, or 529 (mod 840).\n\n"
            "## Claim boundary\n\n"
            "Erdős–Straus remains open. A letter is not a proof.\n",
            hex, n, SPEC_NAME[spectrum], SPEC[spectrum][0], SPEC[spectrum][1], kmax,
            SPEC_NAME[spectrum]);
    fclose(f);
    char note[256];
    snprintf(note, sizeof note, "TARGET COLLECTED  L-%s  n=%" PRIu64 "  spectrum=%s", hex, n,
             SPEC_NAME[spectrum]);
    journal(note);
    printf("TARGET COLLECTED  L-%s  n=%" PRIu64 "  spectrum=%s\n", hex, n, SPEC_NAME[spectrum]);
    fflush(stdout);
}

/* Channel A: next hard prime in (lo, hi] on any of the three spectra. */
static uint64_t channel_a_acquire(uint64_t *cursor, uint64_t hi, int *spec) {
    uint64_t n = *cursor;
    if (n < 6) n = 6;
    for (;;) {
        if (n >= hi) {
            *cursor = hi;
            return 0;
        }
        n++;
        if (!is_hard(n) || !is_prime64(n)) {
            if (n == UINT64_MAX) {
                *cursor = n;
                return 0;
            }
            continue;
        }
        *spec = spectrum_of(n);
        *cursor = n;
        return n;
    }
}

/*
 * D: LETTER is TRUE only if B and C both miss.
 * A window/theorem hit is a GREAT in the old kernels — too common, drop it.
 */
static int channel_d_verdict(uint64_t p, int spec, seed_t *seed) {
    wit_t w;
    if (channel_b_lock(p, &w)) {
        seed->dropped++;
        return 0;
    }
    seed->identified++;
    printf("TARGET IDENTIFIED  n=%" PRIu64 "  spectrum=%s  (window miss)\n", p,
           SPEC_NAME[spec]);
    fflush(stdout);
    char note[160];
    snprintf(note, sizeof note, "TARGET IDENTIFIED  n=%" PRIu64 "  spectrum=%s", p,
             SPEC_NAME[spec]);
    journal(note);
    if (channel_c_track(p, &w, seed->kmax)) {
        seed->dropped++;
        printf("TARGET DROPPED     n=%" PRIu64 "  (channel C solved via %s)\n", p, w.method);
        fflush(stdout);
        return 0;
    }
    save_letter(p, spec, seed->kmax);
    seed->letters_found++;
    if (seed->kmax < DEFAULT_KMAX_CAP) {
        seed->kmax *= 2;
        if (seed->kmax > DEFAULT_KMAX_CAP) seed->kmax = DEFAULT_KMAX_CAP;
    }
    return 1;
}

static void cmd_go(int want_random) {
    seed_t seed;
    int have = access(seed_path, F_OK) == 0;
    if (have) {
        seed = load_seed();
        if (want_random)
            fprintf(stderr, "cbap: seed exists; resuming at %" PRIu64 " (--random ignored)\n",
                    seed.scanned_through);
    } else if (want_random) {
        seed = default_seed(random_start());
        printf("cbap: new session, random start %" PRIu64 "\n", seed.start_factor);
    } else {
        seed = default_seed(0);
        printf("cbap: new session, start 0\n");
    }
    save_seed(&seed);
    printf("cbap.kernel  collect LETTER only\n");
    printf("  start %" PRIu64 "  scanned %" PRIu64 "  kmax %" PRIu64 "\n", seed.start_factor,
           seed.scanned_through, seed.kmax);
    printf("  letters/%s  (Ctrl+C stops and saves)\n", letters_dir);
    fflush(stdout);

    uint64_t step = DEFAULT_STEP;
    while (!halt_flag) {
        uint64_t lo = seed.scanned_through;
        uint64_t hi = lo + step;
        if (hi < lo) hi = UINT64_MAX;
        uint64_t cur = lo;
        int spec = 0;
        uint64_t p;
        while (!halt_flag && (p = channel_a_acquire(&cur, hi, &spec))) {
            channel_d_verdict(p, spec, &seed);
        }
        if (!halt_flag) seed.scanned_through = hi;
        else seed.scanned_through = cur;
        seed.windows++;
        save_seed(&seed);
        printf("cbap  scanned=%" PRIu64 "  identified=%" PRIu64 "  collected=%" PRIu64
               "  dropped=%" PRIu64 "\n",
               seed.scanned_through, seed.identified, seed.letters_found, seed.dropped);
        fflush(stdout);
        if (hi == UINT64_MAX) break;
    }
    save_seed(&seed);
    printf("cbap: saved cursor %" PRIu64 "\n", seed.scanned_through);
}

static void cmd_status(void) {
    seed_t s = load_seed();
    printf("{\"kernel\":\"cbap.kernel\",\"collect\":\"LETTER only\","
           "\"start_factor\":%" PRIu64 ",\"scanned_through\":%" PRIu64
           ",\"letters_found\":%" PRIu64 ",\"identified\":%" PRIu64
           ",\"dropped\":%" PRIu64 ",\"kmax\":%" PRIu64
           ",\"proof_status\":\"open\",\"strike\":false}\n",
           s.start_factor, s.scanned_through, s.letters_found, s.identified, s.dropped,
           s.kmax ? s.kmax : DEFAULT_KMAX);
}

static void cmd_letters(void) {
    FILE *j = fopen(journal_path, "r");
    if (j) {
        char buf[4096];
        size_t n;
        while ((n = fread(buf, 1, sizeof buf, j)) > 0) fwrite(buf, 1, n, stdout);
        fclose(j);
        return;
    }
    printf("(no letters collected yet)\n");
}

static void cmd_solve(uint64_t n) {
    if (n < 2) die("n >= 2");
    int spec = spectrum_of(n);
    if (!is_hard(n) || !is_prime64(n)) {
        printf("{\"kernel\":\"cbap.kernel\",\"letter\":false,\"n\":%" PRIu64
               ",\"reason\":\"not a Mordell-hard prime\"}\n",
               n);
        return;
    }
    wit_t w;
    if (channel_b_lock(n, &w) || channel_c_track(n, &w, DEFAULT_KMAX_CAP)) {
        printf("{\"kernel\":\"cbap.kernel\",\"letter\":false,\"n\":%" PRIu64
               ",\"spectrum\":\"%s\",\"solved\":true,\"method\":\"%s\"}\n",
               n, spec >= 0 ? SPEC_NAME[spec] : "?", w.method);
        return;
    }
    printf("{\"kernel\":\"cbap.kernel\",\"letter\":true,\"n\":%" PRIu64
           ",\"spectrum\":\"%s\",\"rule\":\"unsolved_after_search\"}\n",
           n, spec >= 0 ? SPEC_NAME[spec] : "?");
}

static int cmd_self_test(void) {
    sha256_t s;
    uint8_t d[32];
    sha256_init(&s);
    sha256_final(&s, d);
    static const uint8_t empty[32] = {
        0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14, 0x9a, 0xfb, 0xf4, 0xc8,
        0x99, 0x6f, 0xb9, 0x24, 0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
        0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55};
    if (memcmp(d, empty, 32) != 0) {
        fprintf(stderr, "cbap: sha256 empty digest mismatch\n");
        return 1;
    }
    static const uint64_t known[] = {1009, 2521, 9601, 10369, 9658489};
    for (size_t i = 0; i < sizeof known / sizeof known[0]; i++) {
        uint64_t p = known[i];
        if (!is_prime64(p) || !is_hard(p)) {
            fprintf(stderr, "cbap: %" PRIu64 " should be a hard prime\n", p);
            return 1;
        }
        wit_t w;
        if (!channel_b_lock(p, &w) && !channel_c_track(p, &w, 400)) {
            fprintf(stderr, "cbap: known solvable %" PRIu64 " marked as letter\n", p);
            return 1;
        }
    }
    printf("cbap self-test OK\n");
    return 0;
}

static void usage(void) {
    fprintf(stderr,
            "cbap.kernel — CB-Advanced-Processing (letter targeting)\n"
            "  cbap                 same as go (start 0, or resume)\n"
            "  cbap go              start at 0 the first time; then resume\n"
            "  cbap go --random     first session starts at a random n; later resumes\n"
            "  cbap status\n"
            "  cbap letters         print the collected-letter journal\n"
            "  cbap solve N         LETTER true/false for one n\n"
            "  cbap self-test\n"
            "Letters only. GREAT is not stored. Erdős–Straus remains open.\n");
}

int main(int argc, char **argv) {
    resolve_root();
    build_sieve(1000003ull);
    signal(SIGINT, on_stop);
    signal(SIGTERM, on_stop);

    const char *cmd = "go";
    int want_random = 0;
    uint64_t arg = 0;
    int i = 1;
    if (argc > 1 && argv[1][0] != '-') {
        cmd = argv[1];
        i = 2;
        if (i < argc && argv[i][0] != '-') {
            arg = strtoull(argv[i], NULL, 10);
            i++;
        }
    }
    for (; i < argc; i++) {
        if (!strcmp(argv[i], "--random")) want_random = 1;
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            usage();
            return 0;
        } else {
            usage();
            return 2;
        }
    }

    if (!strcmp(cmd, "go") || !strcmp(cmd, "continue")) {
        cmd_go(want_random);
        return 0;
    }
    if (!strcmp(cmd, "status")) {
        cmd_status();
        return 0;
    }
    if (!strcmp(cmd, "letters")) {
        cmd_letters();
        return 0;
    }
    if (!strcmp(cmd, "solve")) {
        if (arg < 2) {
            usage();
            return 2;
        }
        cmd_solve(arg);
        return 0;
    }
    if (!strcmp(cmd, "self-test")) return cmd_self_test();
    usage();
    return 2;
}
