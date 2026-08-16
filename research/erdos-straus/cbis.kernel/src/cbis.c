#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
/*
 * cbis.kernel — CB Inverse Sieve
 *
 * ES+ engine. Builds the inverse signed-box cover C_K and keeps the
 * complement Λ_K. Letters only. Does not prove Erdős–Straus.
 *
 * Spectrum × lane matrix (sweep) plus R-homing.
 * R = {hard p : p+4 and 4p+1 have only prime factors ≡ 1 (mod 4)}.
 * Sweep still walks from 0. Home generates only R. Cover only grows.
 */
#include <inttypes.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define DASH_W 68
#define D_RST "\033[0m"
#define D_DIM "\033[2m"
#define D_BLD "\033[1m"
#define D_GRN "\033[32m"
#define D_YEL "\033[33m"
#define D_BLU "\033[34m"
#define D_MAG "\033[35m"
#define D_CYN "\033[36m"

#define HARD_N 6
static const int HARD[HARD_N] = {1, 121, 169, 289, 361, 529};
static const int SPEC[3][2] = {{1, 121}, {169, 289}, {361, 529}};
static const char *SPEC_NAME[3] = {"A", "B", "C"};
#define SPEC_N 3
#define LANE_N 4
enum { LANE_W = 0, LANE_I = 1, LANE_NR = 2, LANE_LP = 3 };
static const char *LANE_NAME[LANE_N] = {"W", "I", "N", "L"};

#define DEFAULT_STEP 50000ull
#define DEFAULT_KMAX 400ull
#define NR_ELL_MAX 300ull

typedef struct {
    uint64_t ps[16];
    int es[16];
    int n;
} fac_t;

typedef struct {
    uint64_t scanned_through;
    uint64_t start_factor;
    uint64_t letters_found;
    uint64_t covered;
    uint64_t dropped;
    uint64_t kmax;
    uint64_t windows;
    uint64_t home_S;     /* cursor on S = p+4, S ≡ 1 (mod 4) */
    uint64_t w_linear;   /* 4p+1 or p+4 */
    uint64_t w_r;        /* hard primes in R */
    uint64_t w_fab;      /* R finished by fab */
    uint64_t home_r;     /* R primes found by homing */
    uint64_t home_fab;
} seed_t;

static uint8_t *sieve;
static uint32_t *primes;
static int nprimes;
static uint64_t sieve_n;
static volatile sig_atomic_t halt_flag;
static char root_dir[768];
static char letters_dir[768];
static char seed_path[768];
static char journal_path[768];
static int live_tty;
static int use_color;
static int dash_stream;
static int dash_go;
static char evline[5][100];
static int evn;
static uint64_t dash_cell[SPEC_N][LANE_N];
static uint64_t dash_home_r, dash_home_fab, dash_work_n;
static struct timespec dash_t0, dash_run0;
static int dash_painted, dash_dirty;
static const seed_t *dash_sp;
static uint64_t dash_step_v, dash_sweep0, dash_home0;
static int dash_do_sweep, dash_do_home;
static int dash_col;

static void die(const char *m) {
    fprintf(stderr, "cbis.kernel: %s\n", m);
    exit(1);
}

static void on_stop(int sig) {
    (void)sig;
    halt_flag = 1;
}

/* ---- SHA-256, ES-LETTER-v1 ---- */

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

/* ---- arithmetic ---- */

static int is_hard(uint64_t p) {
    int r = (int)(p % 840);
    for (int i = 0; i < HARD_N; i++)
        if (r == HARD[i]) return 1;
    return 0;
}

static int spectrum_of(uint64_t p) {
    int r = (int)(p % 840);
    for (int s = 0; s < SPEC_N; s++)
        if (r == SPEC[s][0] || r == SPEC[s][1]) return s;
    return -1;
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

static uint64_t modpow_signed(uint64_t a, int64_t e, uint64_t m) {
    if (e >= 0) return pow_mod(a, (uint64_t)e, m);
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
    return pow_mod((uint64_t)t, (uint64_t)(-e), m);
}

static int dfs_box(const fac_t *f, int i, uint64_t val, uint64_t mod, uint64_t target) {
    if (i == f->n) return val == target;
    int e = f->es[i];
    uint64_t p = f->ps[i];
    for (int z = -e; z <= e; z++) {
        uint64_t nv = mul_mod(val, modpow_signed(p, z, mod), mod);
        if (dfs_box(f, i + 1, nv, mod, target)) return 1;
    }
    return 0;
}

static int box_has(const fac_t *f, uint64_t k, uint64_t target) {
    if (k < 2) return 0;
    return dfs_box(f, 0, 1 % k, k, target % k);
}

/* δ_k(C)=0 iff a Type I or Type II hit exists. */
static int delta_zero(const fac_t *f, uint64_t C, uint64_t k) {
    if (gcd64(C, k) != 1) return 0;
    if (box_has(f, k, k - 1)) return 1; /* τ_II = -1 */
    uint64_t cinv = modpow_signed(C % k, -1, k);
    if (!cinv) return 0;
    uint64_t four_inv = (k + 1) / 4; /* k ≡ 3 (mod 4) */
    uint64_t tau_i = (k - mul_mod(four_inv, cinv, k)) % k;
    return box_has(f, k, tau_i);
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

static int factor64(uint64_t n, fac_t *f) {
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
            if (f->n == 16) die("too many factors");
            f->ps[f->n] = p;
            f->es[f->n] = e;
            f->n++;
        }
        if (n == 1) return f->n;
    }
    if (n > 1) {
        if (f->n == 16) die("too many factors");
        f->ps[f->n] = n;
        f->es[f->n] = 1;
        f->n++;
    }
    return f->n;
}

/* ---- W_K: cheap window (GREAT; mark only) ---- */

static uint64_t divisor_in_class(uint64_t n, uint64_t mod, uint64_t residue) {
    fac_t f;
    factor64(n, &f);
    uint64_t *val = calloc(mod, sizeof(uint64_t));
    uint8_t *have = calloc(mod, 1);
    if (!val || !have) die("oom class");
    have[1 % mod] = 1;
    val[1 % mod] = 1;
    uint64_t tgt = residue % mod;
    for (int i = 0; i < f.n; i++) {
        uint64_t q = f.ps[i];
        int e = f.es[i];
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

static int in_window_set(uint64_t p) {
    if (try_4p_plus_1(p) || try_p_plus_4(p)) return 1;
    return try_any_fab(p);
}

/* Σ₁: every prime factor is ≡ 1 (mod 4). */
static int in_sigma1(uint64_t n) {
    if (n < 2) return n == 1;
    fac_t f;
    factor64(n, &f);
    for (int i = 0; i < f.n; i++)
        if ((f.ps[i] & 3) != 1) return 0;
    return 1;
}

/* R: hard prime whose 4p+1 and p+4 both live in Σ₁. */
static int in_R(uint64_t p) {
    if (!is_hard(p) || !is_prime64(p)) return 0;
    return in_sigma1(p + 4) && in_sigma1(4 * p + 1);
}

/* Lane I: signed-box cover at every admissible k ≤ K (recognition form of C_K). */
static int in_signed_box_cover(uint64_t p, uint64_t K) {
    for (uint64_t k = 3; k <= K; k += 4) {
        if (halt_flag) return 0;
        if (gcd64(k, p) != 1) continue;
        if ((p + k) % 4) continue;
        uint64_t C = (p + k) / 4;
        fac_t f;
        factor64(C, &f);
        if (delta_zero(&f, C, k)) return 1;
    }
    return 0;
}

/* Lane N: CC/cbap external-NR shifts. May use k > K; strengthens the cover. */
static int in_nr_cover(uint64_t p) {
    for (int i = 0; i < nprimes; i++) {
        uint64_t ell = primes[i];
        if (ell < 11 || ell == p) continue;
        if (ell > NR_ELL_MAX) break;
        if (jacobi64((int64_t)ell, p) != -1) continue;
        if ((ell & 3) == 3 && gcd64(ell, p) == 1 && (p + ell) % 4 == 0) {
            uint64_t C = (p + ell) / 4;
            fac_t f;
            factor64(C, &f);
            if (delta_zero(&f, C, ell)) return 1;
        }
        uint64_t k = (4 * ell - (p % (4 * ell))) % (4 * ell);
        if (k == 0) k = 4 * ell;
        if (gcd64(k, p) == 1 && (p + k) % 4 == 0) {
            uint64_t C = (p + k) / 4;
            fac_t f;
            factor64(C, &f);
            if (delta_zero(&f, C, k)) return 1;
        }
    }
    return 0;
}

/* Lane L: López Type A/B prime-modulus traps. A hit is a real ES witness. */
static int in_lopez_cover(uint64_t p, uint64_t K) {
    for (uint64_t k = 1; k <= K; k++) {
        uint64_t m = 4 * k - 1;
        if (!is_prime64(m)) continue;
        for (uint64_t e = 1; e * e <= k; e++) {
            if (k % e) continue;
            uint64_t ds[2] = {e, k / e};
            int nd = (e * e == k) ? 1 : 2;
            for (int t = 0; t < nd; t++) {
                uint64_t d = ds[t];
                uint64_t a = (m - (d % m)) % m;
                uint64_t b = (m - ((4 * d) % m)) % m;
                uint64_t r = p % m;
                if (r == a || r == b) return 1;
            }
        }
    }
    return 0;
}

/* ---- letters / seed ---- */

static void resolve_root(void) {
    char exe[768];
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
    char state[768];
    snprintf(state, sizeof state, "%s/state", root_dir);
    mkdir(state, 0755);
}

static seed_t default_seed(uint64_t start) {
    seed_t s;
    memset(&s, 0, sizeof s);
    s.scanned_through = start;
    s.start_factor = start;
    s.kmax = DEFAULT_KMAX;
    s.home_S = 5;
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
        else if (sscanf(line, "covered=%" SCNu64, &v) == 1) s.covered = v;
        else if (sscanf(line, "dropped=%" SCNu64, &v) == 1) s.dropped = v;
        else if (sscanf(line, "kmax=%" SCNu64, &v) == 1) s.kmax = v;
        else if (sscanf(line, "windows=%" SCNu64, &v) == 1) s.windows = v;
        else if (sscanf(line, "home_S=%" SCNu64, &v) == 1) s.home_S = v;
        else if (sscanf(line, "w_linear=%" SCNu64, &v) == 1) s.w_linear = v;
        else if (sscanf(line, "w_r=%" SCNu64, &v) == 1) s.w_r = v;
        else if (sscanf(line, "w_fab=%" SCNu64, &v) == 1) s.w_fab = v;
        else if (sscanf(line, "home_r=%" SCNu64, &v) == 1) s.home_r = v;
        else if (sscanf(line, "home_fab=%" SCNu64, &v) == 1) s.home_fab = v;
    }
    fclose(f);
    if (!s.kmax) s.kmax = DEFAULT_KMAX;
    if (!s.home_S) s.home_S = 5;
    return s;
}

static void save_seed(const seed_t *s) {
    char tmp[800];
    snprintf(tmp, sizeof tmp, "%s.tmp", seed_path);
    FILE *f = fopen(tmp, "w");
    if (!f) return;
    fprintf(f,
            "kernel=cbis\n"
            "scanned_through=%" PRIu64 "\n"
            "start_factor=%" PRIu64 "\n"
            "letters_found=%" PRIu64 "\n"
            "covered=%" PRIu64 "\n"
            "dropped=%" PRIu64 "\n"
            "kmax=%" PRIu64 "\n"
            "windows=%" PRIu64 "\n"
            "home_S=%" PRIu64 "\n"
            "w_linear=%" PRIu64 "\n"
            "w_r=%" PRIu64 "\n"
            "w_fab=%" PRIu64 "\n"
            "home_r=%" PRIu64 "\n"
            "home_fab=%" PRIu64 "\n",
            s->scanned_through, s->start_factor, s->letters_found, s->covered, s->dropped,
            s->kmax, s->windows, s->home_S, s->w_linear, s->w_r, s->w_fab, s->home_r,
            s->home_fab);
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
    return 1000000ull + (r % 9999999000ull);
}

static int color_ok(void) {
    const char *no = getenv("NO_COLOR");
    if (no && no[0]) return 0;
    const char *force = getenv("CLICOLOR_FORCE");
    if (force && force[0] && strcmp(force, "0") != 0) return 1;
    const char *term = getenv("TERM");
    if (term && !strcmp(term, "dumb")) return 0;
    return isatty(1);
}

static const char *lane_color(int lane) {
    switch (lane) {
    case LANE_W:
        return D_BLU;
    case LANE_I:
        return D_GRN;
    case LANE_NR:
        return D_CYN;
    case LANE_LP:
        return D_MAG;
    default:
        return D_DIM;
    }
}

static const char *spec_color(int spec) {
    if (spec == 0) return D_CYN;
    if (spec == 1) return D_YEL;
    if (spec == 2) return D_MAG;
    return D_DIM;
}

static const char *event_color(const char *s) {
    if (strstr(s, "COLLECTED")) return D_GRN;
    if (strstr(s, "IDENTIFIED")) return D_YEL;
    if (strstr(s, "DROPPED")) return D_DIM;
    return D_RST;
}

static void fmt_u(char *out, size_t cap, uint64_t v) {
    char tmp[32];
    int n = snprintf(tmp, sizeof tmp, "%" PRIu64, v);
    int spaces = n > 0 ? (n - 1) / 3 : 0;
    if (n < 0 || (size_t)n + (size_t)spaces + 1 > cap) {
        snprintf(out, cap, "%" PRIu64, v);
        return;
    }
    int i = n - 1;
    int j = n + spaces;
    out[j] = 0;
    int g = 0;
    while (i >= 0) {
        out[--j] = tmp[i--];
        g++;
        if (g == 3 && i >= 0) {
            out[--j] = ' ';
            g = 0;
        }
    }
}

static void fmt_hms(char out[24], double sec) {
    if (sec < 0) sec = 0;
    unsigned long t = (unsigned long)sec;
    unsigned h = (unsigned)(t / 3600u);
    unsigned m = (unsigned)((t % 3600u) / 60u);
    unsigned s = (unsigned)(t % 60u);
    if (h > 99)
        snprintf(out, 24, "%luh", t / 3600ul);
    else
        snprintf(out, 24, "%02u:%02u:%02u", h, m, s);
}

static double dash_elapsed(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (double)(now.tv_sec - dash_run0.tv_sec) +
           (double)(now.tv_nsec - dash_run0.tv_nsec) / 1000000000.0;
}

static int dash_rows(void) {
    struct winsize ws;
    if (ioctl(1, TIOCGWINSZ, &ws) == 0 && ws.ws_row > 0) return (int)ws.ws_row;
    return 24;
}

static void d_s(const char *color, const char *s) {
    if (use_color && color && color[0]) fputs(color, stdout);
    fputs(s, stdout);
    if (use_color && color && color[0]) fputs(D_RST, stdout);
    dash_col += (int)strlen(s);
}

static void d_fmt(const char *color, const char *fmt, ...) {
    char buf[DASH_W + 8];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    d_s(color, buf);
}

static void d_nl(void) {
    while (dash_col < DASH_W) {
        putchar(' ');
        dash_col++;
    }
    putchar('\n');
    dash_col = 0;
}

static void dash_note(const char *fmt, ...) {
    char buf[100];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    if (evn < 5) {
        snprintf(evline[evn++], sizeof evline[0], "%s", buf);
    } else {
        for (int i = 0; i < 4; i++) memcpy(evline[i], evline[i + 1], sizeof evline[0]);
        snprintf(evline[4], sizeof evline[0], "%s", buf);
    }
    dash_dirty = 1;
}

static int dash_due(int force) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    long ms = (long)(now.tv_sec - dash_t0.tv_sec) * 1000 +
              (now.tv_nsec - dash_t0.tv_nsec) / 1000000;
    if (!force && !dash_dirty && ms < 250) return 0;
    dash_t0 = now;
    dash_dirty = 0;
    return 1;
}

static void dash_draw(const seed_t *s, uint64_t step, int sweep, int home) {
    if (!live_tty || !s) return;
    fputs("\033[?25l", stdout);
    if (!dash_painted) {
        fputs("\033[2J\033[H", stdout);
        dash_painted = 1;
    } else {
        fputs("\033[H", stdout);
    }
    dash_col = 0;

    char n_sweep[32], n_home[32], n_k[32], n_step[32], n_win[32];
    char n_lin[32], n_r[32], n_fab[32], n_let[32], n_hr[32], n_hf[32];
    char n_cell[SPEC_N][LANE_N][16], clock[24], rate_s[40], rate_h[40];
    fmt_u(n_sweep, sizeof n_sweep, s->scanned_through);
    fmt_u(n_home, sizeof n_home, s->home_S);
    fmt_u(n_k, sizeof n_k, s->kmax);
    fmt_u(n_step, sizeof n_step, step);
    fmt_u(n_win, sizeof n_win, s->windows);
    fmt_u(n_lin, sizeof n_lin, s->w_linear);
    fmt_u(n_r, sizeof n_r, s->w_r + s->home_r);
    fmt_u(n_fab, sizeof n_fab, s->w_fab + s->home_fab);
    fmt_u(n_let, sizeof n_let, s->letters_found);
    fmt_u(n_hr, sizeof n_hr, dash_home_r);
    fmt_u(n_hf, sizeof n_hf, dash_home_fab);
    for (int lane = 0; lane < LANE_N; lane++)
        for (int sp = 0; sp < SPEC_N; sp++)
            fmt_u(n_cell[sp][lane], sizeof n_cell[sp][lane], dash_cell[sp][lane]);

    double sec = dash_elapsed();
    fmt_hms(clock, sec);
    if (sec >= 1.0) {
        uint64_t rs = (uint64_t)((double)(s->scanned_through - dash_sweep0) / sec);
        uint64_t rh = (uint64_t)((double)(s->home_S - dash_home0) / sec);
        char tmp[32];
        fmt_u(tmp, sizeof tmp, rs);
        snprintf(rate_s, sizeof rate_s, "%s/s", tmp);
        fmt_u(tmp, sizeof tmp, rh);
        snprintf(rate_h, sizeof rate_h, "%s/s", tmp);
    } else {
        snprintf(rate_s, sizeof rate_s, "—");
        snprintf(rate_h, sizeof rate_h, "—");
    }

    int compact = dash_rows() < 20;

    d_s(use_color ? D_BLD D_CYN : "", "  cbis.kernel");
    d_s(D_DIM, "  ES+ letter engine");
    d_fmt(D_DIM, "  %s  ", clock);
    if (halt_flag)
        d_s(use_color ? D_BLD D_YEL : "", "STOPPING");
    else
        d_s(D_DIM, "running");
    d_nl();

    d_s(D_GRN, "  LETTER");
    d_s(D_DIM, " only    sweep ");
    d_s(sweep ? D_CYN : D_DIM, sweep ? "on " : "off");
    d_s(D_DIM, "   home ");
    d_s(home ? D_MAG : D_DIM, home ? "on " : "off");
    d_nl();

    if (compact) {
        d_s(D_DIM, "  sweep ");
        d_s("", n_sweep);
        d_s(D_DIM, "  S ");
        d_s(D_MAG, n_home);
        d_s(D_DIM, "  letters ");
        d_s(s->letters_found ? D_GRN : D_DIM, n_let);
        d_s(D_DIM, "  ");
        d_s(D_DIM, rate_s);
        d_nl();
        d_s(D_DIM, "  ");
        for (int lane = 0; lane < LANE_N; lane++) {
            d_fmt(lane_color(lane), "%s ", LANE_NAME[lane]);
            for (int sp = 0; sp < SPEC_N; sp++) {
                d_fmt(spec_color(sp), "%s%s", n_cell[sp][lane],
                      sp + 1 < SPEC_N ? " " : "");
            }
            if (lane + 1 < LANE_N) d_s(D_DIM, "  ");
        }
        d_nl();
        if (evn)
            d_fmt(event_color(evline[evn - 1]), "  %s", evline[evn - 1]);
        else
            d_s(D_DIM, "  (quiet)");
        d_nl();
        d_s(D_DIM, "  Ctrl+C  save both cursors");
        d_nl();
        fflush(stdout);
        return;
    }

    d_s(D_DIM, "  sweep     ");
    d_s("", n_sweep);
    d_s(D_DIM, "    ");
    d_s(D_DIM, rate_s);
    if (dash_work_n > s->scanned_through && sweep) {
        char now[32];
        fmt_u(now, sizeof now, dash_work_n);
        d_s(D_DIM, "  now ");
        d_s(D_DIM, now);
    }
    d_nl();
    d_s(D_DIM, "  home S    ");
    d_s(D_MAG, n_home);
    d_s(D_DIM, "    ");
    d_s(D_DIM, rate_h);
    d_nl();
    d_s(D_DIM, "  K ");
    d_s("", n_k);
    d_s(D_DIM, "     step ");
    d_s("", n_step);
    d_s(D_DIM, "     windows ");
    d_s("", n_win);
    d_nl();
    d_nl();

    d_s(D_DIM, "  linear    ");
    d_s(D_BLU, n_lin);
    d_nl();
    d_s(D_DIM, "  R         ");
    d_s(D_YEL, n_r);
    d_nl();
    d_s(D_DIM, "  fab       ");
    d_s(D_CYN, n_fab);
    d_nl();
    d_s(D_DIM, "  collected ");
    d_s(s->letters_found ? D_BLD D_GRN : D_GRN, n_let);
    d_nl();
    d_nl();

    d_s(D_DIM, "  last window");
    d_s(D_DIM, "                 home batch");
    d_nl();
    for (int lane = 0; lane < LANE_N; lane++) {
        d_s(D_DIM, "  ");
        d_fmt(lane_color(lane), "%s", LANE_NAME[lane]);
        d_s("", "   ");
        for (int sp = 0; sp < SPEC_N; sp++) {
            d_fmt(spec_color(sp), "%s ", SPEC_NAME[sp]);
            d_fmt("", "%-4s", n_cell[sp][lane]);
            if (sp + 1 < SPEC_N) d_s("", " ");
        }
        if (lane == 0) {
            d_s(D_DIM, "    R    ");
            d_s(D_YEL, n_hr);
        } else if (lane == 1) {
            d_s(D_DIM, "    fab  ");
            d_s(D_CYN, n_hf);
        }
        d_nl();
    }
    d_nl();
    d_s(D_DIM, "  latest");
    d_nl();
    if (!evn) {
        d_s(D_DIM, "    (quiet)");
        d_nl();
    } else {
        for (int i = 0; i < evn; i++) {
            d_s(D_DIM, "    ");
            d_s(event_color(evline[i]), evline[i]);
            d_nl();
        }
    }
    /* Keep a fixed event block so the frame does not jump. */
    for (int i = evn; i < 5; i++) {
        if (!evn && i == 0) continue;
        d_nl();
    }
    d_s(D_DIM, "  Ctrl+C  save both cursors");
    d_nl();
    fflush(stdout);
}

static void dash_bind(const seed_t *s, uint64_t step, int sweep, int home) {
    dash_sp = s;
    dash_step_v = step;
    dash_do_sweep = sweep;
    dash_do_home = home;
}

static void dash_kick(void) {
    if (live_tty && dash_sp)
        dash_draw(dash_sp, dash_step_v, dash_do_sweep, dash_do_home);
}

static void dash_pulse(uint64_t n) {
    dash_work_n = n;
    if (live_tty && dash_due(0) && dash_sp)
        dash_draw(dash_sp, dash_step_v, dash_do_sweep, dash_do_home);
}

static void dash_done(void) {
    if (live_tty) fputs("\033[?25h\n", stdout);
}

static void say_event(const char *color, const char *fmt, ...) {
    char buf[192];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    if (use_color && color) fputs(color, stdout);
    fputs(buf, stdout);
    if (use_color && color) fputs(D_RST, stdout);
    putchar('\n');
    fflush(stdout);
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

static void save_letter(uint64_t n, uint64_t kmax) {
    char key[160];
    char hex[33];
    snprintf(key, sizeof key, "ES-LETTER-v1\nrule=unsolved_after_search\nn=%" PRIu64 "\nextra=\n",
             n);
    sha256_hex16(key, hex);
    char path[820];
    snprintf(path, sizeof path, "%s/L-%s.md", letters_dir, hex);
    if (access(path, F_OK) == 0) return;
    FILE *f = fopen(path, "w");
    if (!f) die("cannot write letter");
    fprintf(f,
            "# LETTER — unsolved_after_search\n\n"
            "**Grade:** LETTER\n"
            "**Kernel:** cbis.kernel\n"
            "**Letter id:** `L-%s`\n"
            "**n:** %" PRIu64 "\n"
            "**Cover bound K:** %" PRIu64 "\n\n"
            "This prime is outside the inverse signed-box cover "
            "\\(\\mathcal C_K\\) and outside \\(W_K\\). "
            "That is the ES+ letter spectrum. The number is the same "
            "`ES-LETTER-v1` identity as bb.kernel. Finding it by the inverse "
            "sieve does not weaken the stamp.\n\n"
            "Erdős–Straus remains open. A letter is not a counterexample.\n",
            hex, n, kmax);
    fclose(f);
    char note[256];
    snprintf(note, sizeof note, "TARGET COLLECTED  L-%s  n=%" PRIu64, hex, n);
    journal(note);
    dash_note("TARGET COLLECTED  L-%s  n=%" PRIu64, hex, n);
    if (live_tty)
        dash_kick();
    else if (dash_go)
        say_event(D_GRN, "TARGET COLLECTED  L-%s  n=%" PRIu64, hex, n);
}

static int mark_lane(uint8_t *marked, uint64_t cell[SPEC_N][LANE_N], int i, int spec,
                     int lane) {
    if (marked[i]) return 0;
    marked[i] = 1;
    if (spec >= 0) cell[spec][lane]++;
    return 1;
}

/*
 * Spectrum × lane matrix on one window.
 *   rows  A,B,C  — Mordell-hard CRT pairs (cbap)
 *   cols  W      — bb/CC window (4p+1, p+4, fab)
 *         I      — ES+ signed-box C_K (recognition on survivors)
 *         N      — CC/cbap NR-aligned shifts (k may exceed K)
 *         L      — López prime-modulus traps
 * W runs first. I, N, L see only unmarked primes. Shared complement = letters.
 */
static void sieve_window(uint64_t lo, uint64_t hi, uint64_t K, seed_t *seed) {
    if (hi <= lo) return;
    int cap = (int)((hi - lo) / 8 + 32);
    uint64_t *hp = malloc((size_t)cap * sizeof(uint64_t));
    uint8_t *marked = calloc((size_t)cap, 1);
    int8_t *spec_of = malloc((size_t)cap);
    if (!hp || !marked || !spec_of) die("oom window");
    int nh = 0;
    uint64_t n0 = lo < 6 ? 6 : lo;
    for (uint64_t n = n0 + 1; n <= hi && !halt_flag; n++) {
        if (is_hard(n) && is_prime64(n)) {
            if (nh == cap) {
                cap *= 2;
                hp = realloc(hp, (size_t)cap * sizeof(uint64_t));
                marked = realloc(marked, (size_t)cap);
                spec_of = realloc(spec_of, (size_t)cap);
                if (!hp || !marked || !spec_of) die("oom window grow");
                memset(marked + nh, 0, (size_t)(cap - nh));
            }
            hp[nh] = n;
            spec_of[nh] = (int8_t)spectrum_of(n);
            nh++;
        }
        if (live_tty && (n & 4095ull) == 0ull) dash_pulse(n);
        if (n == UINT64_MAX) break;
    }

    uint64_t cell[SPEC_N][LANE_N];
    memset(cell, 0, sizeof cell);
    uint64_t marks = 0;

    /* Lane W — split: linear vs R vs fab-on-R. */
    for (int i = 0; i < nh && !halt_flag; i++) {
        int lin = try_4p_plus_1(hp[i]) || try_p_plus_4(hp[i]);
        if (lin) {
            seed->w_linear++;
            marks += (uint64_t)mark_lane(marked, cell, i, spec_of[i], LANE_W);
            continue;
        }
        seed->w_r++;
        if (try_any_fab(hp[i])) {
            seed->w_fab++;
            marks += (uint64_t)mark_lane(marked, cell, i, spec_of[i], LANE_W);
        }
    }

    /* Survivors of W are in R and missed fab. I, then N, then L. */
    for (int i = 0; i < nh && !halt_flag; i++) {
        if (marked[i]) continue;
        int sp = spec_of[i];
        dash_note("IDENTIFIED  n=%" PRIu64 "  %s  sweep", hp[i],
                  sp >= 0 ? SPEC_NAME[sp] : "?");
        if (!live_tty && dash_go)
            say_event(D_YEL, "TARGET IDENTIFIED  n=%" PRIu64 "  spectrum=%s  via=sweep", hp[i],
                      sp >= 0 ? SPEC_NAME[sp] : "?");
        if (in_signed_box_cover(hp[i], K)) {
            marks += (uint64_t)mark_lane(marked, cell, i, sp, LANE_I);
            continue;
        }
        if (in_nr_cover(hp[i])) {
            marks += (uint64_t)mark_lane(marked, cell, i, sp, LANE_NR);
            continue;
        }
        if (in_lopez_cover(hp[i], K)) {
            marks += (uint64_t)mark_lane(marked, cell, i, sp, LANE_LP);
            continue;
        }
        save_letter(hp[i], K);
        seed->letters_found++;
    }

    for (int i = 0; i < nh; i++)
        if (marked[i]) seed->dropped++;
    seed->covered += marks;
    memcpy(dash_cell, cell, sizeof dash_cell);
    if (!live_tty && dash_stream) {
        printf("cbis  matrix   ");
        for (int lane = 0; lane < LANE_N; lane++) {
            printf("%s[", LANE_NAME[lane]);
            for (int s = 0; s < SPEC_N; s++) {
                printf("%s%" PRIu64 "%s", SPEC_NAME[s], cell[s][lane],
                       s + 1 < SPEC_N ? " " : "");
            }
            printf("]%s", lane + 1 < LANE_N ? "  " : "\n");
        }
        printf("cbis  sweep   linear=%" PRIu64 "  R=%" PRIu64 "  fab=%" PRIu64 "\n",
               seed->w_linear, seed->w_r, seed->w_fab);
        fflush(stdout);
    }
    free(hp);
    free(marked);
    free(spec_of);
}

/* After a W-miss (must be in R): I, then N, then L. */
static void prosecute_residual(uint64_t p, uint64_t K, seed_t *seed, const char *via) {
    int sp = spectrum_of(p);
    dash_note("IDENTIFIED  n=%" PRIu64 "  %s  %s", p, sp >= 0 ? SPEC_NAME[sp] : "?", via);
    if (!live_tty && dash_go)
        say_event(D_YEL, "TARGET IDENTIFIED  n=%" PRIu64 "  spectrum=%s  via=%s", p,
                  sp >= 0 ? SPEC_NAME[sp] : "?", via);
    if (in_signed_box_cover(p, K) || in_nr_cover(p) || in_lopez_cover(p, K)) {
        seed->dropped++;
        seed->covered++;
        dash_note("DROPPED  n=%" PRIu64 "  I/N/L", p);
        if (!live_tty && dash_go)
            say_event(D_DIM, "TARGET DROPPED     n=%" PRIu64 "  (I/N/L)", p);
        else if (live_tty)
            dash_kick();
        return;
    }
    save_letter(p, K);
    seed->letters_found++;
}

/*
 * Homing walk on S = p+4.
 * S ≡ 1 (mod 4). Require S in Σ₁ and 4p+1 in Σ₁. Then p is in R.
 * fab, then I/N/L. This is the missile: it never visits linear W-hits.
 */
static void home_batch(uint64_t span, uint64_t K, seed_t *seed) {
    if (span < 4) span = DEFAULT_STEP;
    uint64_t S0 = seed->home_S < 5 ? 5 : seed->home_S;
    if ((S0 & 3) != 1) S0 += (1u - (S0 & 3)) & 3;
    uint64_t S1 = S0 + span;
    if (S1 < S0) S1 = UINT64_MAX;
    uint64_t r_here = 0, fab_here = 0;
    for (uint64_t S = S0; S <= S1 && !halt_flag; S += 4) {
        if (!in_sigma1(S)) continue;
        if (S <= 4) continue;
        uint64_t p = S - 4;
        if (!is_hard(p) || !is_prime64(p)) continue;
        if (!in_sigma1(4 * p + 1)) continue;
        seed->home_r++;
        r_here++;
        if (live_tty) dash_pulse(S);
        if (try_any_fab(p)) {
            seed->home_fab++;
            seed->dropped++;
            seed->covered++;
            fab_here++;
            continue;
        }
        prosecute_residual(p, K, seed, "home");
    }
    seed->home_S = S1;
    dash_home_r = r_here;
    dash_home_fab = fab_here;
    if (!live_tty && dash_stream) {
        printf("cbis  home    S=%" PRIu64 "  R=%" PRIu64 "  fab=%" PRIu64 "  batch_R=%" PRIu64
               "  batch_fab=%" PRIu64 "\n",
               seed->home_S, seed->home_r, seed->home_fab, r_here, fab_here);
        fflush(stdout);
    }
}

static void cmd_go(int want_random, uint64_t step, uint64_t kmax_arg, int sweep,
                   int home, int want_scroll) {
    seed_t seed;
    int have = access(seed_path, F_OK) == 0;
    if (have) {
        seed = load_seed();
        if (want_random)
            fprintf(stderr, "cbis: seed exists; resuming at %" PRIu64 " (--random ignored)\n",
                    seed.scanned_through);
    } else if (want_random) {
        seed = default_seed(random_start());
        fprintf(stderr, "cbis: new session, random start %" PRIu64 "\n", seed.start_factor);
    } else {
        seed = default_seed(0);
        fprintf(stderr, "cbis: new session, start 0\n");
    }
    if (kmax_arg) seed.kmax = kmax_arg;
    if (!step) step = DEFAULT_STEP;
    save_seed(&seed);
    dash_go = 1;
    use_color = color_ok();
    live_tty = isatty(1) && !want_scroll;
    dash_stream = !live_tty && want_scroll;
    dash_painted = 0;
    dash_dirty = 0;
    dash_work_n = 0;
    evn = 0;
    memset(dash_cell, 0, sizeof dash_cell);
    dash_home_r = dash_home_fab = 0;
    dash_sweep0 = seed.scanned_through;
    dash_home0 = seed.home_S;
    clock_gettime(CLOCK_MONOTONIC, &dash_t0);
    clock_gettime(CLOCK_MONOTONIC, &dash_run0);
    dash_bind(&seed, step, sweep, home);
    if (live_tty) {
        dash_draw(&seed, step, sweep, home);
    } else {
        printf("cbis.kernel  ES+  LETTER only\n");
        printf("  modes  sweep=%s  home=%s\n", sweep ? "on" : "off", home ? "on" : "off");
        printf("  start %" PRIu64 "  scanned %" PRIu64 "  home_S=%" PRIu64 "\n",
               seed.start_factor, seed.scanned_through, seed.home_S);
        fflush(stdout);
    }
    while (!halt_flag) {
        if (sweep) {
            uint64_t lo = seed.scanned_through;
            uint64_t hi = lo + step;
            if (hi < lo) hi = UINT64_MAX;
            sieve_window(lo, hi, seed.kmax, &seed);
            seed.scanned_through = hi;
            seed.windows++;
            if (hi == UINT64_MAX && !home) break;
        }
        if (home && !halt_flag) home_batch(step, seed.kmax, &seed);
        save_seed(&seed);
        if (live_tty) {
            if (dash_due(halt_flag)) dash_draw(&seed, step, sweep, home);
        } else if ((seed.windows % 20) == 0) {
            printf("cbis  totals  scanned=%" PRIu64 "  home_S=%" PRIu64 "  collected=%" PRIu64
                   "\n",
                   seed.scanned_through, seed.home_S, seed.letters_found);
            fflush(stdout);
        }
        if (sweep && seed.scanned_through == UINT64_MAX && home && seed.home_S == UINT64_MAX)
            break;
    }
    save_seed(&seed);
    dash_draw(&seed, step, sweep, home);
    dash_done();
    say_event(D_DIM, "cbis: saved sweep=%" PRIu64 "  home_S=%" PRIu64 "  collected=%" PRIu64,
              seed.scanned_through, seed.home_S, seed.letters_found);
}

static void cmd_status(void) {
    seed_t s = load_seed();
    printf("{\"kernel\":\"cbis.kernel\",\"program\":\"ES+\","
           "\"start_factor\":%" PRIu64 ",\"scanned_through\":%" PRIu64 ",\"home_S\":%" PRIu64
           ",\"letters_found\":%" PRIu64 ",\"linear\":%" PRIu64 ",\"R\":%" PRIu64
           ",\"fab\":%" PRIu64 ",\"K\":%" PRIu64 "}\n",
           s.start_factor, s.scanned_through, s.home_S, s.letters_found, s.w_linear,
           s.w_r + s.home_r, s.w_fab + s.home_fab, s.kmax ? s.kmax : DEFAULT_KMAX);
}

static void cmd_letters(void) {
    FILE *j = fopen(journal_path, "r");
    if (!j) {
        printf("(no letters collected yet)\n");
        return;
    }
    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof buf, j)) > 0) fwrite(buf, 1, n, stdout);
    fclose(j);
}

static int in_cover_forward(uint64_t p, uint64_t K) {
    if (!is_hard(p) || !is_prime64(p)) return 0;
    if (in_window_set(p)) return 1;
    if (in_signed_box_cover(p, K)) return 1;
    if (in_nr_cover(p)) return 1;
    if (in_lopez_cover(p, K)) return 1;
    return 0;
}

static void cmd_solve(uint64_t n) {
    if (n < 2) die("n >= 2");
    if (!is_hard(n) || !is_prime64(n)) {
        printf("{\"kernel\":\"cbis.kernel\",\"letter\":false,\"n\":%" PRIu64
               ",\"reason\":\"not a Mordell-hard prime\"}\n",
               n);
        return;
    }
    int r = in_R(n);
    int lin = try_4p_plus_1(n) || try_p_plus_4(n);
    int fab = try_any_fab(n);
    if (in_cover_forward(n, DEFAULT_KMAX)) {
        printf("{\"kernel\":\"cbis.kernel\",\"letter\":false,\"n\":%" PRIu64
               ",\"in_R\":%s,\"linear\":%s,\"fab\":%s}\n",
               n, r ? "true" : "false", lin ? "true" : "false", fab ? "true" : "false");
        return;
    }
    printf("{\"kernel\":\"cbis.kernel\",\"letter\":true,\"n\":%" PRIu64
           ",\"in_R\":%s,\"rule\":\"unsolved_after_search\"}\n",
           n, r ? "true" : "false");
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
        fprintf(stderr, "cbis: sha256 mismatch\n");
        return 1;
    }
    static const uint64_t known[] = {1009, 2521, 9601, 10369, 9658489};
    for (size_t i = 0; i < sizeof known / sizeof known[0]; i++) {
        if (!in_cover_forward(known[i], DEFAULT_KMAX)) {
            fprintf(stderr, "cbis: known solvable %" PRIu64 " not in cover\n", known[i]);
            return 1;
        }
    }
    if (!in_sigma1(13) || in_sigma1(15) || in_sigma1(21)) {
        fprintf(stderr, "cbis: Sigma_1 test failed\n");
        return 1;
    }
    if (!in_R(2521)) {
        fprintf(stderr, "cbis: 2521 must lie in R\n");
        return 1;
    }
    if (in_R(1009)) {
        fprintf(stderr, "cbis: 1009 is linear, must not lie in R\n");
        return 1;
    }
    /* Inverse window from 0 must mark 2521, not collect it. */
    seed_t tmp;
    memset(&tmp, 0, sizeof tmp);
    tmp.kmax = DEFAULT_KMAX;
    char old_letters[768];
    snprintf(old_letters, sizeof old_letters, "%s", letters_dir);
    snprintf(letters_dir, sizeof letters_dir, "/tmp/cbis-self-letters");
    mkdir(letters_dir, 0755);
    uint64_t before = tmp.letters_found;
    sieve_window(0, 3000, DEFAULT_KMAX, &tmp);
    snprintf(letters_dir, sizeof letters_dir, "%s", old_letters);
    if (tmp.letters_found != before) {
        fprintf(stderr, "cbis: inverse sieve emitted a letter below 3000\n");
        return 1;
    }
    if (tmp.dropped == 0) {
        fprintf(stderr, "cbis: inverse sieve marked nothing below 3000\n");
        return 1;
    }
    printf("cbis self-test OK\n");
    return 0;
}

static void usage(void) {
    fprintf(stderr,
            "cbis.kernel — CB Inverse Sieve (ES+ letter spectrum)\n"
            "  cbis                 same as go (start 0, or resume)\n"
            "  cbis go              start at 0 the first time; then resume\n"
            "  cbis go --random     first session at a random n; later resumes\n"
            "  cbis go --k-max K --step N\n"
            "  cbis go --home-only     R-homing only (p+4 in Sigma_1)\n"
            "  cbis go --sweep-only    0-to-infinity matrix only\n"
            "  cbis go --scroll        line log instead of the live panel\n"
            "  cbis status\n"
            "  cbis letters\n"
            "  cbis solve N\n"
            "  cbis self-test\n"
            "Letters only. Same ES-LETTER-v1 numbers. Erdős–Straus remains open.\n");
}

int main(int argc, char **argv) {
    resolve_root();
    build_sieve(1000003ull);
    signal(SIGINT, on_stop);
    signal(SIGTERM, on_stop);

    const char *cmd = "go";
    int want_random = 0;
    uint64_t arg = 0;
    uint64_t opt_kmax = 0;
    uint64_t opt_step = 0;
    int do_sweep = 1, do_home = 1;
    int want_scroll = 0;
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
        else if (!strcmp(argv[i], "--k-max") && i + 1 < argc)
            opt_kmax = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--step") && i + 1 < argc)
            opt_step = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--home-only")) {
            do_home = 1;
            do_sweep = 0;
        } else if (!strcmp(argv[i], "--sweep-only")) {
            do_sweep = 1;
            do_home = 0;
        } else if (!strcmp(argv[i], "--scroll")) {
            want_scroll = 1;
        } else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            usage();
            return 0;
        } else {
            usage();
            return 2;
        }
    }

    if (!strcmp(cmd, "go") || !strcmp(cmd, "continue")) {
        cmd_go(want_random, opt_step, opt_kmax, do_sweep, do_home, want_scroll);
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
