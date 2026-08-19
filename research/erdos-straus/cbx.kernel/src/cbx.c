#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
/*
 * cbx.kernel — CB X-ray Kernel
 *
 * Research instrument for ES+. It preserves the cbis production ordering
 * W -> I -> N -> L for verdicts, but evaluates all lanes independently so
 * W hits do not hide signed-box / NR / Lopez depth information.
 *
 * This program does not prove Erdős–Straus. Finite misses are ES-LETTER-v1
 * observations at a concrete search grade, not counterexamples.
 */
#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define VERSION "0.1.0"
#define DEFAULT_STEP 50000ull
#define DEFAULT_FAB_MAX 11u
#define DEFAULT_I_MAX 400ull
#define DEFAULT_N_ELL_MAX 300ull
#define DEFAULT_L_MAX 400ull
#define HARD_N 6
#define SPEC_N 3

static const int HARD[HARD_N] = {1, 121, 169, 289, 361, 529};
static const int SPEC[3][2] = {{1, 121}, {169, 289}, {361, 529}};
static const char *SPEC_NAME[SPEC_N] = {"A", "B", "C"};
static volatile sig_atomic_t halt_flag;
static char root_dir[768];
static uint64_t rng_state = 0x8f3c2d1a9b7e6543ull;

typedef struct {
    uint64_t ps[64];
    unsigned es[64];
    int n;
} fac_t;

typedef enum {
    POLICY_FIXED = 0,
    POLICY_LOG = 1,
    POLICY_LOG2 = 2,
    POLICY_SPECTRUM_LOG = 3
} policy_t;

typedef struct {
    unsigned fab_max;
    uint64_t i_max;
    uint64_t n_ell_max;
    uint64_t l_max;
    policy_t policy;
    double policy_scale;
} grade_t;

typedef struct {
    uint64_t sweep;
    uint64_t home_S; /* next S to visit; always 1 mod 4 */
    uint64_t observations;
    uint64_t unique_letters;
    uint64_t windows;
    grade_t grade;
} seed_t;

typedef struct {
    uint64_t n;
    int hard;
    int prime;
    int spectrum;
    int linear;
    int in_R;
    unsigned fab_a, fab_b;
    int fab;
    uint64_t i_bound;
    uint64_t i_first;
    int i_hit;
    int i_omega;
    unsigned i_Omega;
    uint64_t i_box_size;
    int n_hit;
    uint64_t n_ell;
    uint64_t n_shift;
    int l_hit;
    uint64_t l_first;
    uint64_t l_modulus;
    int production_letter;
} probe_t;

static void die(const char *fmt, ...) {
    va_list ap;
    fprintf(stderr, "cbx.kernel: ");
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
    exit(1);
}

static void on_stop(int sig) {
    (void)sig;
    halt_flag = 1;
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

static uint64_t add_mod(uint64_t a, uint64_t b, uint64_t m) {
    return (uint64_t)(((unsigned __int128)a + b) % m);
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

static uint64_t inv_mod(uint64_t a, uint64_t m) {
    if (!m) return 0;
    __int128 t = 0, nt = 1;
    __int128 r = m, nr = a % m;
    while (nr) {
        uint64_t q = (uint64_t)(r / nr);
        __int128 tt = nt;
        nt = t - (__int128)q * nt;
        t = tt;
        __int128 rr = nr;
        nr = r - (__int128)q * nr;
        r = rr;
    }
    if (r != 1) return 0;
    t %= (__int128)m;
    if (t < 0) t += m;
    return (uint64_t)t;
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
    static const uint32_t small[] = {2,3,5,7,11,13,17,19,23,29,31,37};
    for (size_t i = 0; i < sizeof small / sizeof small[0]; i++) {
        if (n == small[i]) return 1;
        if (n % small[i] == 0) return 0;
    }
    static const uint64_t bases[] = {
        2ull, 325ull, 9375ull, 28178ull, 450775ull, 9780504ull, 1795265022ull
    };
    for (size_t i = 0; i < sizeof bases / sizeof bases[0]; i++)
        if (!mr_check(n, bases[i])) return 0;
    return 1;
}

static uint64_t rng64(void) {
    uint64_t x = rng_state;
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    rng_state = x;
    return x * 2685821657736338717ull;
}

static uint64_t absdiff64(uint64_t a, uint64_t b) { return a > b ? a - b : b - a; }

static uint64_t pollard_rho(uint64_t n) {
    if ((n & 1) == 0) return 2;
    if (n % 3 == 0) return 3;
    for (;;) {
        uint64_t c = 1 + rng64() % (n - 1);
        uint64_t x = 2 + rng64() % (n - 3);
        uint64_t y = x;
        uint64_t d = 1;
        for (uint64_t iter = 0; d == 1 && iter < 2000000ull; iter++) {
            x = add_mod(mul_mod(x, x, n), c, n);
            y = add_mod(mul_mod(y, y, n), c, n);
            y = add_mod(mul_mod(y, y, n), c, n);
            d = gcd64(absdiff64(x, y), n);
        }
        if (d > 1 && d < n) return d;
    }
}

static void sort_u64(uint64_t *a, int n) {
    for (int i = 1; i < n; i++) {
        uint64_t x = a[i];
        int j = i - 1;
        while (j >= 0 && a[j] > x) {
            a[j + 1] = a[j];
            j--;
        }
        a[j + 1] = x;
    }
}

static void factor_rec(uint64_t n, uint64_t *out, int *count) {
    if (n == 1) return;
    if (is_prime64(n)) {
        if (*count >= 64) die("factor stack overflow");
        out[(*count)++] = n;
        return;
    }
    uint64_t d = pollard_rho(n);
    factor_rec(d, out, count);
    factor_rec(n / d, out, count);
}

static int factor64(uint64_t n, fac_t *f) {
    f->n = 0;
    if (n < 2) return 0;
    uint64_t raw[64];
    int nr = 0;
    factor_rec(n, raw, &nr);
    sort_u64(raw, nr);
    for (int i = 0; i < nr;) {
        int j = i + 1;
        while (j < nr && raw[j] == raw[i]) j++;
        f->ps[f->n] = raw[i];
        f->es[f->n] = (unsigned)(j - i);
        f->n++;
        i = j;
    }
    return f->n;
}

static int is_hard(uint64_t p) {
    int r = (int)(p % 840);
    for (int i = 0; i < HARD_N; i++) if (r == HARD[i]) return 1;
    return 0;
}

static int spectrum_of(uint64_t p) {
    int r = (int)(p % 840);
    for (int s = 0; s < SPEC_N; s++)
        if (r == SPEC[s][0] || r == SPEC[s][1]) return s;
    return -1;
}

static int jacobi64(int64_t aa0, uint64_t n) {
    if (!n || !(n & 1)) return 0;
    int64_t aa0m = aa0 % (int64_t)n;
    if (aa0m < 0) aa0m += (int64_t)n;
    uint64_t a = (uint64_t)aa0m;
    int s = 1;
    while (a) {
        while ((a & 1) == 0) {
            a >>= 1;
            uint64_t m = n & 7;
            if (m == 3 || m == 5) s = -s;
        }
        uint64_t t = a; a = n; n = t;
        if ((a & 3) == 3 && (n & 3) == 3) s = -s;
        a %= n;
    }
    return n == 1 ? s : 0;
}

/* ---- signed box ---- */

static int dfs_box(const fac_t *f, int i, uint64_t val, uint64_t mod, uint64_t target) {
    if (i == f->n) return val == target;
    uint64_t p = f->ps[i] % mod;
    uint64_t pinv = inv_mod(p, mod);
    if (!pinv) return 0;
    unsigned e = f->es[i];
    uint64_t cur = 1 % mod;
    for (unsigned j = 0; j < e; j++) cur = mul_mod(cur, pinv, mod);
    for (unsigned z = 0; z <= 2 * e; z++) {
        if (dfs_box(f, i + 1, mul_mod(val, cur, mod), mod, target)) return 1;
        cur = mul_mod(cur, p, mod);
    }
    return 0;
}

static int box_has(const fac_t *f, uint64_t k, uint64_t target) {
    if (k < 2) return 0;
    return dfs_box(f, 0, 1 % k, k, target % k);
}

static int delta_zero(const fac_t *f, uint64_t C, uint64_t k) {
    if (gcd64(C, k) != 1) return 0;
    if (box_has(f, k, k - 1)) return 1;
    uint64_t cinv = inv_mod(C % k, k);
    uint64_t four_inv = inv_mod(4 % k, k);
    if (!cinv || !four_inv) return 0;
    uint64_t tau_i = (k - mul_mod(four_inv, cinv, k)) % k;
    return box_has(f, k, tau_i);
}

static uint64_t box_size(const fac_t *f) {
    uint64_t s = 1;
    for (int i = 0; i < f->n; i++) {
        uint64_t m = 2ull * f->es[i] + 1;
        if (s > UINT64_MAX / m) return UINT64_MAX;
        s *= m;
    }
    return s;
}

static unsigned Omega_of(const fac_t *f) {
    unsigned s = 0;
    for (int i = 0; i < f->n; i++) s += f->es[i];
    return s;
}

/* ---- W and R ---- */

static uint64_t divisor_in_class(uint64_t n, uint64_t mod, uint64_t residue) {
    fac_t f;
    factor64(n, &f);
    uint8_t *have = calloc((size_t)mod, 1);
    uint64_t *val = calloc((size_t)mod, sizeof(uint64_t));
    if (!have || !val) die("oom divisor class");
    have[1 % mod] = 1;
    val[1 % mod] = 1;
    uint64_t target = residue % mod;
    for (int i = 0; i < f.n; i++) {
        uint8_t *nh = calloc((size_t)mod, 1);
        uint64_t *nv = calloc((size_t)mod, sizeof(uint64_t));
        if (!nh || !nv) die("oom divisor class step");
        memcpy(nh, have, (size_t)mod);
        memcpy(nv, val, (size_t)mod * sizeof(uint64_t));
        for (uint64_t r = 0; r < mod; r++) {
            if (!have[r]) continue;
            uint64_t rr = r, vv = val[r];
            for (unsigned e = 0; e < f.es[i]; e++) {
                if (vv > UINT64_MAX / f.ps[i]) break;
                vv *= f.ps[i];
                rr = (rr * (f.ps[i] % mod)) % mod;
                if (!nh[rr]) { nh[rr] = 1; nv[rr] = vv; }
            }
        }
        free(have); free(val); have = nh; val = nv;
        if (have[target]) {
            uint64_t out = val[target];
            free(have); free(val); return out;
        }
    }
    uint64_t out = have[target] ? val[target] : 0;
    free(have); free(val); return out;
}

static int try_p_plus_4(uint64_t p) {
    if (p > UINT64_MAX - 4) return 0;
    uint64_t q = divisor_in_class(p + 4, 4, 3);
    if (!q) return 0;
    uint64_t m = (q + 1) / 4;
    return (mul_mod(m % q, p % q, q) + 1) % q == 0;
}

static int try_4p_plus_1(uint64_t p) {
    if (p > (UINT64_MAX - 1) / 4) return 0;
    uint64_t n = 4 * p + 1;
    uint64_t F = divisor_in_class(n, 4, 3);
    if (!F) return 0;
    uint64_t G = n / F;
    return (G % 4) == 3;
}

static int try_fab(uint64_t p, unsigned a, unsigned b) {
    if (!a || !b || gcd64(a, b) != 1) return 0;
    if (a >= p || b >= p) return 0;
    if (p > (UINT64_MAX - a) / b) return 0;
    uint64_t lin = (uint64_t)a + (uint64_t)b * p;
    uint64_t mod = 4ull * a * b;
    uint64_t target = (mod - (p % mod)) % mod;
    uint64_t k = divisor_in_class(lin, mod, target);
    if (!k) return 0;
    if ((p + k) % mod) return 0;
    return lin % k == 0;
}

static int first_fab(uint64_t p, unsigned F, unsigned *oa, unsigned *ob) {
    for (unsigned a = 1; a <= F; a++) {
        for (unsigned b = 1; b <= F; b++) {
            if (gcd64(a, b) != 1) continue;
            if (try_fab(p, a, b)) {
                if (oa) *oa = a;
                if (ob) *ob = b;
                return 1;
            }
        }
    }
    return 0;
}

static int in_sigma1(uint64_t n) {
    if (n == 1) return 1;
    if (n < 2) return 0;
    fac_t f; factor64(n, &f);
    for (int i = 0; i < f.n; i++) if ((f.ps[i] & 3) != 1) return 0;
    return 1;
}

static int in_R(uint64_t p) {
    if (!is_hard(p) || !is_prime64(p)) return 0;
    if (p > (UINT64_MAX - 1) / 4 || p > UINT64_MAX - 4) return 0;
    return in_sigma1(p + 4) && in_sigma1(4 * p + 1);
}

/* ---- lane depth ---- */

static uint64_t effective_i_bound(uint64_t p, int spec, const grade_t *g) {
    if (g->policy == POLICY_FIXED) return g->i_max;
    double lp = log((double)(p < 3 ? 3 : p));
    double v;
    if (g->policy == POLICY_LOG)
        v = g->policy_scale * lp;
    else if (g->policy == POLICY_LOG2)
        v = g->policy_scale * lp * lp;
    else {
        static const double mult[3] = {1.0, 1.15, 1.30};
        double m = (spec >= 0 && spec < 3) ? mult[spec] : 1.0;
        v = g->policy_scale * m * lp;
    }
    if (v < 3.0) v = 3.0;
    uint64_t k = (uint64_t)ceil(v);
    if (k > g->i_max) k = g->i_max;
    return k;
}

static int lane_i_first(uint64_t p, uint64_t K, probe_t *o) {
    for (uint64_t k = 3; k <= K; k += 4) {
        if (halt_flag) return 0;
        if (gcd64(k, p) != 1) continue;
        if (p > UINT64_MAX - k) break;
        if ((p + k) % 4) continue;
        uint64_t C = (p + k) / 4;
        fac_t f; factor64(C, &f);
        if (delta_zero(&f, C, k)) {
            if (o) {
                o->i_first = k;
                o->i_omega = f.n;
                o->i_Omega = Omega_of(&f);
                o->i_box_size = box_size(&f);
            }
            return 1;
        }
        if (k > UINT64_MAX - 4) break;
    }
    return 0;
}

static int lane_n_first(uint64_t p, uint64_t E, uint64_t *oell, uint64_t *oshift) {
    for (uint64_t ell = 11; ell <= E; ell += 2) {
        if (!is_prime64(ell) || ell == p) continue;
        if (jacobi64((int64_t)ell, p) != -1) continue;
        if ((ell & 3) == 3 && gcd64(ell, p) == 1 && p <= UINT64_MAX - ell && (p + ell) % 4 == 0) {
            uint64_t C = (p + ell) / 4;
            fac_t f; factor64(C, &f);
            if (delta_zero(&f, C, ell)) {
                if (oell) *oell = ell;
                if (oshift) *oshift = ell;
                return 1;
            }
        }
        if (ell > UINT64_MAX / 4) continue;
        uint64_t m = 4 * ell;
        uint64_t k = (m - (p % m)) % m;
        if (k == 0) k = m;
        if (gcd64(k, p) == 1 && p <= UINT64_MAX - k && (p + k) % 4 == 0) {
            uint64_t C = (p + k) / 4;
            fac_t f; factor64(C, &f);
            if (delta_zero(&f, C, k)) {
                if (oell) *oell = ell;
                if (oshift) *oshift = k;
                return 1;
            }
        }
    }
    return 0;
}

static int lane_l_first(uint64_t p, uint64_t A, uint64_t *oa, uint64_t *omod) {
    for (uint64_t aidx = 1; aidx <= A; aidx++) {
        if (aidx > (UINT64_MAX - 1) / 4) break;
        uint64_t m = 4 * aidx - 1;
        if (!is_prime64(m)) continue;
        for (uint64_t e = 1; e <= aidx / e; e++) {
            if (aidx % e) continue;
            uint64_t ds[2] = {e, aidx / e};
            int nd = e == aidx / e ? 1 : 2;
            for (int t = 0; t < nd; t++) {
                uint64_t d = ds[t];
                uint64_t r = p % m;
                uint64_t ra = (m - d % m) % m;
                uint64_t rb = (m - mul_mod(4 % m, d % m, m)) % m;
                if (r == ra || r == rb) {
                    if (oa) *oa = aidx;
                    if (omod) *omod = m;
                    return 1;
                }
            }
        }
    }
    return 0;
}

static probe_t probe_one(uint64_t p, const grade_t *g) {
    probe_t o;
    memset(&o, 0, sizeof o);
    o.n = p;
    o.hard = is_hard(p);
    o.prime = is_prime64(p);
    o.spectrum = spectrum_of(p);
    if (!o.hard || !o.prime) return o;
    o.linear = try_4p_plus_1(p) || try_p_plus_4(p);
    o.in_R = !o.linear && in_R(p);
    o.fab = first_fab(p, g->fab_max, &o.fab_a, &o.fab_b);
    o.i_bound = effective_i_bound(p, o.spectrum, g);
    o.i_hit = lane_i_first(p, o.i_bound, &o);
    o.n_hit = lane_n_first(p, g->n_ell_max, &o.n_ell, &o.n_shift);
    o.l_hit = lane_l_first(p, g->l_max, &o.l_first, &o.l_modulus);
    /* Production order: W includes linear OR fab; then I, N, L. */
    o.production_letter = !(o.linear || o.fab || o.i_hit || o.n_hit || o.l_hit);
    return o;
}

/* ---- SHA-256 for ES-LETTER-v1 compatibility ---- */

typedef struct { uint32_t h[8]; uint64_t bits; uint8_t buf[64]; size_t fill; } sha256_t;
static uint32_t rotr32(uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }
static void sha_init(sha256_t *s) {
    static const uint32_t iv[8] = {0x6a09e667u,0xbb67ae85u,0x3c6ef372u,0xa54ff53au,
        0x510e527fu,0x9b05688cu,0x1f83d9abu,0x5be0cd19u};
    memcpy(s->h, iv, sizeof iv); s->bits = 0; s->fill = 0;
}
static void sha_block(sha256_t *s, const uint8_t *p) {
    static const uint32_t K[64] = {0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4u,0x5b9cca4fu,0x682e6ff3u,0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u};
    uint32_t w[64];
    for (int i=0;i<16;i++) w[i]=((uint32_t)p[4*i]<<24)|((uint32_t)p[4*i+1]<<16)|((uint32_t)p[4*i+2]<<8)|p[4*i+3];
    for (int i=16;i<64;i++){uint32_t s0=rotr32(w[i-15],7)^rotr32(w[i-15],18)^(w[i-15]>>3);uint32_t s1=rotr32(w[i-2],17)^rotr32(w[i-2],19)^(w[i-2]>>10);w[i]=w[i-16]+s0+w[i-7]+s1;}
    uint32_t a=s->h[0],b=s->h[1],c=s->h[2],d=s->h[3],e=s->h[4],f=s->h[5],g=s->h[6],h=s->h[7];
    for(int i=0;i<64;i++){uint32_t S1=rotr32(e,6)^rotr32(e,11)^rotr32(e,25);uint32_t ch=(e&f)^((~e)&g);uint32_t t1=h+S1+ch+K[i]+w[i];uint32_t S0=rotr32(a,2)^rotr32(a,13)^rotr32(a,22);uint32_t maj=(a&b)^(a&c)^(b&c);uint32_t t2=S0+maj;h=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;}
    s->h[0]+=a;s->h[1]+=b;s->h[2]+=c;s->h[3]+=d;s->h[4]+=e;s->h[5]+=f;s->h[6]+=g;s->h[7]+=h;
}
static void sha_update(sha256_t *s,const void *data,size_t n){const uint8_t *p=data;s->bits+=(uint64_t)n*8;while(n){size_t t=64-s->fill;if(t>n)t=n;memcpy(s->buf+s->fill,p,t);s->fill+=t;p+=t;n-=t;if(s->fill==64){sha_block(s,s->buf);s->fill=0;}}}
static void sha_final(sha256_t *s,uint8_t out[32]){s->buf[s->fill++]=0x80;if(s->fill>56){while(s->fill<64)s->buf[s->fill++]=0;sha_block(s,s->buf);s->fill=0;}while(s->fill<56)s->buf[s->fill++]=0;for(int i=7;i>=0;i--)s->buf[s->fill++]=(uint8_t)(s->bits>>(8*i));sha_block(s,s->buf);for(int i=0;i<8;i++){out[4*i]=(uint8_t)(s->h[i]>>24);out[4*i+1]=(uint8_t)(s->h[i]>>16);out[4*i+2]=(uint8_t)(s->h[i]>>8);out[4*i+3]=(uint8_t)s->h[i];}}
static void letter_id(uint64_t n, char hex[33]) { char key[160]; snprintf(key,sizeof key,"ES-LETTER-v1\nrule=unsolved_after_search\nn=%" PRIu64 "\nextra=\n",n); sha256_t s; uint8_t d[32]; sha_init(&s); sha_update(&s,key,strlen(key)); sha_final(&s,d); for(int i=0;i<16;i++)sprintf(hex+2*i,"%02x",d[i]); hex[32]=0; }

/* ---- filesystem / run state ---- */

static void resolve_root(void) {
    char exe[768]; ssize_t m = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (m > 0) { exe[m]=0; char *s=strrchr(exe,'/'); if(s){*s=0; snprintf(root_dir,sizeof root_dir,"%s",exe);} else strcpy(root_dir,"."); }
    else strcpy(root_dir,".");
    char p[900];
    snprintf(p,sizeof p,"%s/state",root_dir); mkdir(p,0755);
    snprintf(p,sizeof p,"%s/observations",root_dir); mkdir(p,0755);
    snprintf(p,sizeof p,"%s/letters",root_dir); mkdir(p,0755);
}

static int valid_run(const char *s) {
    if (!s || !*s) return 0;
    for (; *s; s++) if (!( (*s>='a'&&*s<='z')||(*s>='A'&&*s<='Z')||(*s>='0'&&*s<='9')||*s=='-'||*s=='_' )) return 0;
    return 1;
}

static const char *policy_name(policy_t p) {
    switch(p){case POLICY_FIXED:return "fixed";case POLICY_LOG:return "log";case POLICY_LOG2:return "log2";case POLICY_SPECTRUM_LOG:return "spectrum-log";} return "unknown";
}

static int parse_policy(const char *s, policy_t *p) {
    if(!strcmp(s,"fixed"))*p=POLICY_FIXED; else if(!strcmp(s,"log"))*p=POLICY_LOG; else if(!strcmp(s,"log2"))*p=POLICY_LOG2; else if(!strcmp(s,"spectrum-log"))*p=POLICY_SPECTRUM_LOG; else return 0; return 1;
}

static grade_t default_grade(void) { grade_t g={DEFAULT_FAB_MAX,DEFAULT_I_MAX,DEFAULT_N_ELL_MAX,DEFAULT_L_MAX,POLICY_FIXED,20.0}; return g; }
static seed_t default_seed(const grade_t *g) { seed_t s; memset(&s,0,sizeof s); s.home_S=5; s.grade=*g; return s; }

static void paths_for(const char *run, char seed[900], char obs[900], char grades[900]) {
    snprintf(seed,900,"%s/state/%s.seed",root_dir,run);
    snprintf(obs,900,"%s/observations/%s.jsonl",root_dir,run);
    snprintf(grades,900,"%s/letters/GRADES.jsonl",root_dir);
}

static void save_seed(const char *run, const seed_t *s) {
    char path[900],obs[900],gr[900],tmp[940]; paths_for(run,path,obs,gr); snprintf(tmp,sizeof tmp,"%s.tmp",path);
    FILE *f=fopen(tmp,"w"); if(!f) die("cannot write seed: %s",strerror(errno));
    fprintf(f,"kernel=cbx\nversion=%s\nsweep=%" PRIu64 "\nhome_S=%" PRIu64 "\nobservations=%" PRIu64 "\nunique_letters=%" PRIu64 "\nwindows=%" PRIu64 "\nfab_max=%u\ni_max=%" PRIu64 "\nn_ell_max=%" PRIu64 "\nl_max=%" PRIu64 "\npolicy=%s\npolicy_scale=%.17g\n",VERSION,s->sweep,s->home_S,s->observations,s->unique_letters,s->windows,s->grade.fab_max,s->grade.i_max,s->grade.n_ell_max,s->grade.l_max,policy_name(s->grade.policy),s->grade.policy_scale);
    fclose(f); if(rename(tmp,path)!=0) die("cannot replace seed");
}

static seed_t load_seed(const char *run, int *exists) {
    grade_t dg=default_grade(); seed_t s=default_seed(&dg); char path[900],o[900],gr[900]; paths_for(run,path,o,gr); FILE *f=fopen(path,"r"); if(!f){*exists=0;return s;} *exists=1;
    char line[256]; while(fgets(line,sizeof line,f)){
        uint64_t v; unsigned u; double d; char pol[64];
        if(sscanf(line,"sweep=%" SCNu64,&v)==1)s.sweep=v; else if(sscanf(line,"home_S=%" SCNu64,&v)==1)s.home_S=v; else if(sscanf(line,"observations=%" SCNu64,&v)==1)s.observations=v; else if(sscanf(line,"unique_letters=%" SCNu64,&v)==1)s.unique_letters=v; else if(sscanf(line,"windows=%" SCNu64,&v)==1)s.windows=v; else if(sscanf(line,"fab_max=%u",&u)==1)s.grade.fab_max=u; else if(sscanf(line,"i_max=%" SCNu64,&v)==1)s.grade.i_max=v; else if(sscanf(line,"n_ell_max=%" SCNu64,&v)==1)s.grade.n_ell_max=v; else if(sscanf(line,"l_max=%" SCNu64,&v)==1)s.grade.l_max=v; else if(sscanf(line,"policy=%63s",pol)==1){ policy_t p;if(parse_policy(pol,&p))s.grade.policy=p;} else if(sscanf(line,"policy_scale=%lf",&d)==1)s.grade.policy_scale=d;
    } fclose(f); if((s.home_S&3)!=1)s.home_S += (1u-(s.home_S&3))&3; return s;
}

static int same_grade(const grade_t *a,const grade_t *b){return a->fab_max==b->fab_max&&a->i_max==b->i_max&&a->n_ell_max==b->n_ell_max&&a->l_max==b->l_max&&a->policy==b->policy&&fabs(a->policy_scale-b->policy_scale)<1e-12;}

static void print_probe_json(FILE *f,const probe_t *o,const grade_t *g,const char *via,const char *run) {
    char lid[33]=""; if(o->production_letter) letter_id(o->n,lid);
    fprintf(f,"{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"run\":\"%s\",\"via\":\"%s\",\"n\":%" PRIu64 ",\"hard\":%s,\"prime\":%s,\"spectrum\":%s",VERSION,run,via,o->n,o->hard?"true":"false",o->prime?"true":"false",o->spectrum>=0?"\"":"null");
    if(o->spectrum>=0) fprintf(f,"%s\"",SPEC_NAME[o->spectrum]);
    fprintf(f,",\"grade\":{\"fab_max\":%u,\"i_max\":%" PRIu64 ",\"i_realized\":%" PRIu64 ",\"n_ell_max\":%" PRIu64 ",\"l_max\":%" PRIu64 ",\"policy\":\"%s\",\"policy_scale\":%.8g}",g->fab_max,g->i_max,o->i_bound,g->n_ell_max,g->l_max,policy_name(g->policy),g->policy_scale);
    fprintf(f,",\"W\":{\"linear\":%s,\"R\":%s,\"fab\":%s,\"fab_a\":%u,\"fab_b\":%u}",o->linear?"true":"false",o->in_R?"true":"false",o->fab?"true":"false",o->fab_a,o->fab_b);
    fprintf(f,",\"I\":{\"hit\":%s,\"first_k\":%" PRIu64 ",\"omega\":%d,\"Omega\":%u,\"box_size\":%" PRIu64 "}",o->i_hit?"true":"false",o->i_first,o->i_omega,o->i_Omega,o->i_box_size);
    fprintf(f,",\"N\":{\"hit\":%s,\"ell\":%" PRIu64 ",\"shift\":%" PRIu64 "}",o->n_hit?"true":"false",o->n_ell,o->n_shift);
    fprintf(f,",\"L\":{\"hit\":%s,\"first_a\":%" PRIu64 ",\"modulus\":%" PRIu64 "}",o->l_hit?"true":"false",o->l_first,o->l_modulus);
    fprintf(f,",\"production_letter\":%s",o->production_letter?"true":"false"); if(o->production_letter)fprintf(f,",\"letter_id\":\"L-%s\"",lid); fprintf(f,"}\n");
}

static int store_letter(const probe_t *o,const grade_t *g,const char *run,const char *via) {
    char hex[33];
    letter_id(o->n,hex);
    char path[900];
    snprintf(path,sizeof path,"%s/letters/L-%s.md",root_dir,hex);
    int global_fresh=access(path,F_OK)!=0;
    if(global_fresh){
        FILE *f=fopen(path,"w");
        if(!f)die("cannot write letter");
        fprintf(f,"# LETTER — unsolved_after_search\n\n**Grade:** LETTER\n**Kernel identity:** ES-LETTER-v1\n**Letter id:** `L-%s`\n**n:** %" PRIu64 "\n\nThis content-addressed identity denotes the unsolved-after-search event for this prime. Exact finite search grades are recorded separately in `GRADES.jsonl`.\n\nErdős–Straus remains open. A finite letter is not a counterexample.\n",hex,o->n);
        fclose(f);
    }
    char marker[900];
    snprintf(marker,sizeof marker,"%s/state/%s.L-%s",root_dir,run,hex);
    int run_fresh=access(marker,F_OK)!=0;
    if(run_fresh){FILE *mf=fopen(marker,"w");if(mf){fprintf(mf,"%" PRIu64 "\n",o->n);fclose(mf);}}
    char gp[900],sp[900],op[900];
    paths_for(run,sp,op,gp);
    FILE *gf=fopen(gp,"a");
    if(gf){
        fprintf(gf,"{\"letter_id\":\"L-%s\",\"n\":%" PRIu64 ",\"run\":\"%s\",\"via\":\"%s\",\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"fab_max\":%u,\"i_max\":%" PRIu64 ",\"i_realized\":%" PRIu64 ",\"n_ell_max\":%" PRIu64 ",\"l_max\":%" PRIu64 ",\"policy\":\"%s\",\"policy_scale\":%.8g}\n",hex,o->n,run,via,VERSION,g->fab_max,g->i_max,o->i_bound,g->n_ell_max,g->l_max,policy_name(g->policy),g->policy_scale);
        fclose(gf);
    }
    return run_fresh;
}

static void record_probe(const probe_t *o,const grade_t *g,const char *run,const char *via,seed_t *s,int print) {
    char sp[900],op[900],gp[900]; paths_for(run,sp,op,gp); FILE *f=fopen(op,"a"); if(!f) die("cannot append observations"); print_probe_json(f,o,g,via,run); fclose(f); s->observations++; if(o->production_letter && store_letter(o,g,run,via)) s->unique_letters++; if(print) print_probe_json(stdout,o,g,via,run);
}

static uint64_t random_start(void) {
    uint64_t r=0; FILE *f=fopen("/dev/urandom","rb"); if(f){if(fread(&r,sizeof r,1,f)!=1)r=(uint64_t)time(NULL);fclose(f);}else r=(uint64_t)time(NULL)^(uint64_t)getpid(); return 1000000ull+(r%9999999000ull);
}

static void sweep_batch(seed_t *s,uint64_t step,const char *run) {
    uint64_t lo=s->sweep,hi=lo+step;if(hi<lo)hi=UINT64_MAX;
    uint64_t n=lo<6?7:lo+1;
    for(;n<=hi&&!halt_flag;n++){if(is_hard(n)&&is_prime64(n)){probe_t o=probe_one(n,&s->grade);record_probe(&o,&s->grade,run,"sweep",s,0);} if(n==UINT64_MAX)break;}
    s->sweep=hi;s->windows++;
}

static void home_batch(seed_t *s,uint64_t span,const char *run) {
    uint64_t S0=s->home_S<5?5:s->home_S;
    if((S0&3)!=1)S0+=(1u-(S0&3))&3;
    uint64_t S1=S0+span;
    if(S1<S0)S1=UINT64_MAX;
    if((S1&3)!=1)S1-=(S1-1)&3;
    uint64_t S=S0;
    while(!halt_flag && S<=S1){
        if(in_sigma1(S) && S>4){
            uint64_t p=S-4;
            if(is_hard(p)&&is_prime64(p)&&p<=(UINT64_MAX-1)/4&&in_sigma1(4*p+1)){
                probe_t o=probe_one(p,&s->grade);
                record_probe(&o,&s->grade,run,"home",s,0);
            }
        }
        if(S>=S1 || S>UINT64_MAX-4)break;
        S+=4;
    }
    if(S1>UINT64_MAX-4)s->home_S=UINT64_MAX; else s->home_S=S1+4; /* strict next cursor */
}

static void usage(void) {
    fprintf(stderr,"cbx.kernel %s — CB X-ray Kernel\n"
        "  cbx go [--run NAME] [--step N] [--random] [--sweep-only|--home-only]\n"
        "         [--fab-max F] [--i-max K] [--n-ell-max E] [--l-max A]\n"
        "         [--k-max K] [--k-policy fixed|log|log2|spectrum-log] [--policy-scale C]\n"
        "  cbx probe N [grade options]\n"
        "  cbx solve N [grade options]     (same full X-ray record)\n"
        "  cbx status [--run NAME]\n"
        "  cbx self-test\n"
        "Grades are immutable inside an existing named run. Use another --run for another grade.\n",VERSION);
}

static int self_test(void) {
    if(!is_prime64(2)||!is_prime64(1000003ull)||is_prime64(1000005ull))die("primality self-test");
    uint64_t a=1000003ull,b=1000033ull,n=a*b;fac_t f;factor64(n,&f);if(f.n!=2||f.ps[0]!=a||f.ps[1]!=b)die("Pollard-rho factorization self-test");
    if(!is_hard(1009)||!is_hard(2521)||is_hard(1013))die("hard-class self-test");
    if(in_R(1009))die("1009 must not be R");
    if(!in_R(2521))die("2521 must be R");
    grade_t g=default_grade();probe_t p1=probe_one(1009,&g),p2=probe_one(2521,&g),p3=probe_one(9658489,&g);if(p1.production_letter||p2.production_letter||p3.production_letter)die("known target escaped default production grade");
    if(!p2.fab)die("2521 expected fab hit");
    g.policy=POLICY_LOG;g.policy_scale=10.0;uint64_t e=effective_i_bound(1000003,0,&g);if(e<3||e>g.i_max)die("adaptive policy bound");
    char hex[33];letter_id(2521,hex);if(strlen(hex)!=32)die("letter hash self-test");
    printf("cbx self-test OK\n");return 0;
}

int main(int argc,char **argv){resolve_root();signal(SIGINT,on_stop);signal(SIGTERM,on_stop);rng_state^=(uint64_t)time(NULL)^((uint64_t)getpid()<<32);
    const char *cmd="go",*run="default";uint64_t arg=0,step=DEFAULT_STEP;int randomize=0,sweep=1,home=1;grade_t cli=default_grade();int grade_touched=0;
    int i=1;if(argc>1&&argv[1][0]!='-'){cmd=argv[1];i=2;if((!strcmp(cmd,"probe")||!strcmp(cmd,"solve"))&&i<argc&&argv[i][0]!='-'){arg=strtoull(argv[i++],NULL,10);}}
    for(;i<argc;i++){
        if(!strcmp(argv[i],"--run")&&i+1<argc)run=argv[++i];
        else if(!strcmp(argv[i],"--step")&&i+1<argc)step=strtoull(argv[++i],NULL,10);
        else if(!strcmp(argv[i],"--random"))randomize=1;
        else if(!strcmp(argv[i],"--sweep-only")){sweep=1;home=0;}
        else if(!strcmp(argv[i],"--home-only")){sweep=0;home=1;}
        else if(!strcmp(argv[i],"--fab-max")&&i+1<argc){cli.fab_max=(unsigned)strtoul(argv[++i],NULL,10);grade_touched=1;}
        else if(!strcmp(argv[i],"--i-max")&&i+1<argc){cli.i_max=strtoull(argv[++i],NULL,10);grade_touched=1;}
        else if(!strcmp(argv[i],"--n-ell-max")&&i+1<argc){cli.n_ell_max=strtoull(argv[++i],NULL,10);grade_touched=1;}
        else if(!strcmp(argv[i],"--l-max")&&i+1<argc){cli.l_max=strtoull(argv[++i],NULL,10);grade_touched=1;}
        else if(!strcmp(argv[i],"--k-max")&&i+1<argc){uint64_t k=strtoull(argv[++i],NULL,10);cli.i_max=k;cli.l_max=k;grade_touched=1;}
        else if(!strcmp(argv[i],"--k-policy")&&i+1<argc){if(!parse_policy(argv[++i],&cli.policy))die("unknown k policy");grade_touched=1;}
        else if(!strcmp(argv[i],"--policy-scale")&&i+1<argc){cli.policy_scale=strtod(argv[++i],NULL);grade_touched=1;}
        else if(!strcmp(argv[i],"--help")||!strcmp(argv[i],"-h")){usage();return 0;} else {usage();return 2;}
    }
    if(!valid_run(run))die("run name may contain only letters, digits, - and _");
    if(!cli.fab_max||cli.fab_max>64)die("fab-max must be 1..64");
    if(cli.i_max<3||!cli.n_ell_max||!cli.l_max||cli.policy_scale<=0)die("invalid grade");
    if(!strcmp(cmd,"self-test"))return self_test();
    if(!strcmp(cmd,"probe")||!strcmp(cmd,"solve")){
        if(arg<2)die("probe/solve requires n >= 2");
        grade_t pg=cli;
        if(!grade_touched){int pex=0;seed_t ps=load_seed(run,&pex);if(pex)pg=ps.grade;}
        probe_t o=probe_one(arg,&pg);
        print_probe_json(stdout,&o,&pg,"probe",run);
        return 0;
    }
    if(!strcmp(cmd,"status")){int ex=0;seed_t s=load_seed(run,&ex);if(!ex){printf("{\"kernel\":\"cbx.kernel\",\"run\":\"%s\",\"exists\":false}\n",run);return 0;}printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"run\":\"%s\",\"sweep\":%" PRIu64 ",\"home_S\":%" PRIu64 ",\"observations\":%" PRIu64 ",\"unique_letters\":%" PRIu64 ",\"fab_max\":%u,\"i_max\":%" PRIu64 ",\"n_ell_max\":%" PRIu64 ",\"l_max\":%" PRIu64 ",\"policy\":\"%s\"}\n",VERSION,run,s.sweep,s.home_S,s.observations,s.unique_letters,s.grade.fab_max,s.grade.i_max,s.grade.n_ell_max,s.grade.l_max,policy_name(s.grade.policy));return 0;}
    if(strcmp(cmd,"go")&&strcmp(cmd,"continue")){usage();return 2;}
    int ex=0;seed_t s=load_seed(run,&ex);if(ex){if(grade_touched&&!same_grade(&s.grade,&cli))die("grade mismatch for existing run '%s'; use a new --run name",run);}else{s=default_seed(&cli);if(randomize)s.sweep=random_start();save_seed(run,&s);} if(!step)step=DEFAULT_STEP;
    fprintf(stderr,"cbx: run=%s sweep=%s home=%s grade=(F=%u,I=%" PRIu64 ",N=%" PRIu64 ",L=%" PRIu64 ",policy=%s)\n",run,sweep?"on":"off",home?"on":"off",s.grade.fab_max,s.grade.i_max,s.grade.n_ell_max,s.grade.l_max,policy_name(s.grade.policy));
    while(!halt_flag){
        if(sweep)sweep_batch(&s,step,run);
        if(home&&!halt_flag)home_batch(&s,step,run);
        save_seed(run,&s);
        if((s.windows%20)==0 || halt_flag)fprintf(stderr,"cbx: sweep=%" PRIu64 " home_S=%" PRIu64 " observations=%" PRIu64 " letters=%" PRIu64 "\n",s.sweep,s.home_S,s.observations,s.unique_letters);
        if((sweep&&s.sweep==UINT64_MAX)||(home&&s.home_S==UINT64_MAX))break;
    }
    save_seed(run,&s);return 0;
}
