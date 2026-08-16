#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
/*
 * cbx2.kernel — CB Formulation 2
 *
 * Separate from cbis.kernel and from cbx.kernel (PR #230).
 * Constructs Lane I by k → C → p, X-rays W/N/L independently,
 * verdicts W → I → N → L, homes only on R.
 * Letters keep ES-LETTER-v1. Does not prove Erdős–Straus.
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

#define DEFAULT_STEP 50000ull
#define DEFAULT_F 11ull
#define DEFAULT_KI 400ull
#define DEFAULT_EN 300ull
#define DEFAULT_AL 400ull

typedef struct {
    uint64_t ps[16];
    int es[16];
    int n;
} fac_t;

typedef struct {
    uint64_t F, Ki, En, Al;
} grade_t;

typedef struct {
    uint64_t scanned_through;
    uint64_t start_factor;
    uint64_t letters_found;
    uint64_t covered;
    uint64_t dropped;
    uint64_t windows;
    uint64_t home_S;
    uint64_t w_linear, w_r, w_fab;
    uint64_t home_r, home_fab;
    uint64_t i_hits, n_hits, l_hits;
    uint64_t i_constructed;
    grade_t g;
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
static int live_tty, use_color, dash_stream, dash_go;
static char evline[5][100];
static int evn;
static uint64_t dash_i, dash_w, dash_n, dash_l, dash_work_n;
static struct timespec dash_t0, dash_run0;
static int dash_painted, dash_dirty, dash_col;
static const seed_t *dash_sp;
static uint64_t dash_step_v, dash_sweep0, dash_home0;
static int dash_do_sweep, dash_do_home;

static void die(const char *m) {
    fprintf(stderr, "cbx2.kernel: %s\n", m);
    exit(1);
}

static void on_stop(int sig) {
    (void)sig;
    halt_flag = 1;
}

/* ---- SHA-256 / ES-LETTER-v1 ---- */

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

static int jacobi64(int64_t a, uint64_t n) {
    if (n == 0 || (n & 1) == 0) return 0;
    a %= (int64_t)n;
    if (a < 0) a += (int64_t)n;
    int s = 1;
    uint64_t aa = (uint64_t)a;
    while (aa) {
        while ((aa & 1) == 0) {
            aa >>= 1;
            uint64_t m8 = n & 7;
            if (m8 == 3 || m8 == 5) s = -s;
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
    static const uint64_t bases[] = {
        2ull, 325ull, 9375ull, 28178ull, 450775ull, 9780504ull, 1795265022ull};
    for (int i = 0; i < 7; i++)
        if (!mr_check(n, bases[i])) return 0;
    return 1;
}

static uint64_t pollard_rho(uint64_t n) {
    if ((n & 1) == 0) return 2;
    if (n % 3 == 0) return 3;
    for (uint64_t c = 1; c < 32; c++) {
        uint64_t x = 2, y = 2, d = 1;
        while (d == 1) {
            x = (mul_mod(x, x, n) + c) % n;
            y = (mul_mod(y, y, n) + c) % n;
            y = (mul_mod(y, y, n) + c) % n;
            uint64_t diff = x > y ? x - y : y - x;
            d = gcd64(diff, n);
        }
        if (d != n) return d;
    }
    return 0;
}

static void factor_push(fac_t *f, uint64_t p) {
    for (int i = 0; i < f->n; i++) {
        if (f->ps[i] == p) {
            f->es[i]++;
            return;
        }
    }
    if (f->n == 16) die("too many factors");
    f->ps[f->n] = p;
    f->es[f->n] = 1;
    f->n++;
}

static void factor_rec(uint64_t n, fac_t *f) {
    if (n == 1) return;
    if (is_prime64(n)) {
        factor_push(f, n);
        return;
    }
    uint64_t d = pollard_rho(n);
    if (!d || d == n) {
        for (uint64_t p = 5; p <= n / p; p += 2) {
            if (n % p == 0) {
                d = p;
                break;
            }
        }
        if (!d || d == n) {
            factor_push(f, n);
            return;
        }
    }
    factor_rec(d, f);
    factor_rec(n / d, f);
}

static int factor64(uint64_t n, fac_t *f) {
    f->n = 0;
    while ((n & 1) == 0) {
        factor_push(f, 2);
        n >>= 1;
    }
    while (n % 3 == 0) {
        factor_push(f, 3);
        n /= 3;
    }
    if (n > 1) factor_rec(n, f);
    for (int i = 0; i < f->n; i++)
        for (int j = i + 1; j < f->n; j++)
            if (f->ps[j] < f->ps[i]) {
                uint64_t tp = f->ps[i];
                int te = f->es[i];
                f->ps[i] = f->ps[j];
                f->es[i] = f->es[j];
                f->ps[j] = tp;
                f->es[j] = te;
            }
    return f->n;
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

static int delta_zero(const fac_t *f, uint64_t C, uint64_t k) {
    if (gcd64(C, k) != 1) return 0;
    if (box_has(f, k, k - 1)) return 1;
    uint64_t cinv = modpow_signed(C % k, -1, k);
    if (!cinv) return 0;
    uint64_t four_inv = (k + 1) / 4;
    uint64_t tau_i = (k - mul_mod(four_inv, cinv, k)) % k;
    return box_has(f, k, tau_i);
}

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

static int try_any_fab(uint64_t p, uint64_t F) {
    if (F < 1) F = DEFAULT_F;
    if (F > 11) F = 11;
    for (int a = 1; a <= (int)F; a++)
        for (int b = 1; b <= (int)F; b++)
            if (try_fab(p, a, b)) return 1;
    return 0;
}

static int in_sigma1(uint64_t n) {
    if (n < 2) return n == 1;
    fac_t f;
    factor64(n, &f);
    for (int i = 0; i < f.n; i++)
        if ((f.ps[i] & 3) != 1) return 0;
    return 1;
}

static int in_R(uint64_t p) {
    if (!is_hard(p) || !is_prime64(p)) return 0;
    return in_sigma1(p + 4) && in_sigma1(4 * p + 1);
}

/* Recognition form of Lane I — verify / fallback only. */
static uint64_t first_k_recognize(uint64_t p, uint64_t Ki) {
    for (uint64_t k = 3; k <= Ki; k += 4) {
        if (halt_flag) return 0;
        if (gcd64(k, p) != 1) continue;
        if ((p + k) % 4) continue;
        uint64_t C = (p + k) / 4;
        fac_t f;
        factor64(C, &f);
        if (delta_zero(&f, C, k)) return k;
    }
    return 0;
}

static int in_nr_cover(uint64_t p, uint64_t En) {
    for (int i = 0; i < nprimes; i++) {
        uint64_t ell = primes[i];
        if (ell < 11 || ell == p) continue;
        if (ell > En) break;
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

static int in_lopez_cover(uint64_t p, uint64_t Al) {
    for (uint64_t k = 1; k <= Al; k++) {
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

/* ---- paths / seed ---- */

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

static seed_t default_seed(uint64_t start, grade_t g) {
    seed_t s;
    memset(&s, 0, sizeof s);
    s.scanned_through = start;
    s.start_factor = start;
    s.g = g;
    return s;
}

static seed_t load_seed(void) {
    seed_t s;
    memset(&s, 0, sizeof s);
    s.g.F = DEFAULT_F;
    s.g.Ki = DEFAULT_KI;
    s.g.En = DEFAULT_EN;
    s.g.Al = DEFAULT_AL;
    FILE *f = fopen(seed_path, "r");
    if (!f) return s;
    char line[256];
    while (fgets(line, sizeof line, f)) {
        uint64_t v = 0;
        if (sscanf(line, "scanned_through=%" SCNu64, &v) == 1) s.scanned_through = v;
        else if (sscanf(line, "start_factor=%" SCNu64, &v) == 1) s.start_factor = v;
        else if (sscanf(line, "letters_found=%" SCNu64, &v) == 1) s.letters_found = v;
        else if (sscanf(line, "covered=%" SCNu64, &v) == 1) s.covered = v;
        else if (sscanf(line, "dropped=%" SCNu64, &v) == 1) s.dropped = v;
        else if (sscanf(line, "windows=%" SCNu64, &v) == 1) s.windows = v;
        else if (sscanf(line, "home_S=%" SCNu64, &v) == 1) s.home_S = v;
        else if (sscanf(line, "w_linear=%" SCNu64, &v) == 1) s.w_linear = v;
        else if (sscanf(line, "w_r=%" SCNu64, &v) == 1) s.w_r = v;
        else if (sscanf(line, "w_fab=%" SCNu64, &v) == 1) s.w_fab = v;
        else if (sscanf(line, "home_r=%" SCNu64, &v) == 1) s.home_r = v;
        else if (sscanf(line, "home_fab=%" SCNu64, &v) == 1) s.home_fab = v;
        else if (sscanf(line, "i_hits=%" SCNu64, &v) == 1) s.i_hits = v;
        else if (sscanf(line, "n_hits=%" SCNu64, &v) == 1) s.n_hits = v;
        else if (sscanf(line, "l_hits=%" SCNu64, &v) == 1) s.l_hits = v;
        else if (sscanf(line, "i_constructed=%" SCNu64, &v) == 1) s.i_constructed = v;
        else if (sscanf(line, "F=%" SCNu64, &v) == 1) s.g.F = v;
        else if (sscanf(line, "K_I=%" SCNu64, &v) == 1) s.g.Ki = v;
        else if (sscanf(line, "E_N=%" SCNu64, &v) == 1) s.g.En = v;
        else if (sscanf(line, "A_L=%" SCNu64, &v) == 1) s.g.Al = v;
    }
    fclose(f);
    if (!s.g.F) s.g.F = DEFAULT_F;
    if (!s.g.Ki) s.g.Ki = DEFAULT_KI;
    if (!s.g.En) s.g.En = DEFAULT_EN;
    if (!s.g.Al) s.g.Al = DEFAULT_AL;
    return s;
}

static void save_seed(const seed_t *s) {
    char tmp[800];
    snprintf(tmp, sizeof tmp, "%s.tmp", seed_path);
    FILE *f = fopen(tmp, "w");
    if (!f) die("cannot write seed");
    fprintf(f,
            "kernel=cbx2\n"
            "scanned_through=%" PRIu64 "\n"
            "start_factor=%" PRIu64 "\n"
            "letters_found=%" PRIu64 "\n"
            "covered=%" PRIu64 "\n"
            "dropped=%" PRIu64 "\n"
            "windows=%" PRIu64 "\n"
            "home_S=%" PRIu64 "\n"
            "w_linear=%" PRIu64 "\n"
            "w_r=%" PRIu64 "\n"
            "w_fab=%" PRIu64 "\n"
            "home_r=%" PRIu64 "\n"
            "home_fab=%" PRIu64 "\n"
            "i_hits=%" PRIu64 "\n"
            "n_hits=%" PRIu64 "\n"
            "l_hits=%" PRIu64 "\n"
            "i_constructed=%" PRIu64 "\n"
            "F=%" PRIu64 "\n"
            "K_I=%" PRIu64 "\n"
            "E_N=%" PRIu64 "\n"
            "A_L=%" PRIu64 "\n",
            s->scanned_through, s->start_factor, s->letters_found, s->covered, s->dropped,
            s->windows, s->home_S, s->w_linear, s->w_r, s->w_fab, s->home_r, s->home_fab,
            s->i_hits, s->n_hits, s->l_hits, s->i_constructed, s->g.F, s->g.Ki, s->g.En,
            s->g.Al);
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

/* ---- dashboard ---- */

static int color_ok(void) {
    const char *no = getenv("NO_COLOR");
    if (no && no[0]) return 0;
    const char *force = getenv("CLICOLOR_FORCE");
    if (force && force[0] && strcmp(force, "0") != 0) return 1;
    const char *term = getenv("TERM");
    if (term && !strcmp(term, "dumb")) return 0;
    return isatty(1);
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
    d_s(use_color ? D_BLD D_CYN : "", "  cbx2.kernel");
    d_s(D_DIM, "  formulation 2");
    if (halt_flag)
        d_s(use_color ? D_BLD D_YEL : "", "  STOPPING");
    else
        d_s(D_DIM, "  running");
    d_nl();
    d_fmt(D_DIM, "  Γ=(F=%" PRIu64 ", K_I=%" PRIu64 ", E_N=%" PRIu64 ", A_L=%" PRIu64 ")",
          s->g.F, s->g.Ki, s->g.En, s->g.Al);
    d_nl();
    d_s(D_GRN, "  LETTER");
    d_s(D_DIM, " only    sweep ");
    d_s(sweep ? D_CYN : D_DIM, sweep ? "on " : "off");
    d_s(D_DIM, "   home ");
    d_s(home ? D_MAG : D_DIM, home ? "on " : "off");
    d_nl();
    d_fmt(D_DIM, "  sweep     %" PRIu64 "    step %" PRIu64, s->scanned_through, step);
    d_nl();
    d_fmt(D_MAG, "  home S    %" PRIu64, s->home_S);
    d_nl();
    d_fmt(D_CYN, "  construct I  %" PRIu64 "   window I %" PRIu64, s->i_constructed, dash_i);
    d_nl();
    d_fmt(D_BLU, "  xray W %" PRIu64 "  N %" PRIu64 "  L %" PRIu64, dash_w, dash_n, dash_l);
    d_nl();
    d_fmt(D_YEL, "  linear %" PRIu64 "  R %" PRIu64 "  fab %" PRIu64, s->w_linear,
          s->w_r + s->home_r, s->w_fab + s->home_fab);
    d_nl();
    d_s(D_DIM, "  collected ");
    d_fmt(s->letters_found ? D_BLD D_GRN : D_GRN, "%" PRIu64, s->letters_found);
    d_nl();
    d_s(D_DIM, "  latest");
    d_nl();
    if (!evn) {
        d_s(D_DIM, "    (quiet)");
        d_nl();
    } else {
        for (int i = 0; i < evn; i++) {
            d_s(D_DIM, "    ");
            d_s(strstr(evline[i], "COLLECTED") ? D_GRN : D_YEL, evline[i]);
            d_nl();
        }
    }
    for (int i = evn ? evn : 1; i < 4; i++) d_nl();
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
    if (live_tty && dash_sp) dash_draw(dash_sp, dash_step_v, dash_do_sweep, dash_do_home);
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

static void save_letter(uint64_t n, const grade_t *g) {
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
            "**Kernel:** cbx2.kernel\n"
            "**Letter id:** `L-%s`\n"
            "**n:** %" PRIu64 "\n"
            "**Finite grade:** Γ=(F=%" PRIu64 ", K_I=%" PRIu64 ", E_N=%" PRIu64 ", A_L=%" PRIu64
            ")\n\n"
            "Constructed I missed, and independent W/N/L missed. "
            "The number is the same `ES-LETTER-v1` identity as cbis.kernel.\n\n"
            "Erdős–Straus remains open. A letter is not a counterexample.\n",
            hex, n, g->F, g->Ki, g->En, g->Al);
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

static int cmp_u64(const void *a, const void *b) {
    uint64_t x = *(const uint64_t *)a, y = *(const uint64_t *)b;
    return (x > y) - (x < y);
}

static int find_hp(const uint64_t *hp, int nh, uint64_t p) {
    uint64_t key = p;
    uint64_t *hit = bsearch(&key, hp, (size_t)nh, sizeof(uint64_t), cmp_u64);
    if (!hit) return -1;
    return (int)(hit - hp);
}

static uint64_t first_congruent(uint64_t lo, uint64_t mod, uint64_t residue) {
    uint64_t rem = lo % mod;
    uint64_t add = (residue + mod - rem) % mod;
    if (lo > UINT64_MAX - add) return UINT64_MAX;
    return lo + add;
}

/*
 * Construct I on (lo, hi]: k → C → p = 4C-k.
 * C ≡ (h+k)/4 (mod 210) for each hard class h.
 * first_i[i] = k_I* or 0.
 */
static uint64_t construct_I(uint64_t lo, uint64_t hi, uint64_t Ki, const uint64_t *hp, int nh,
                           uint32_t *first_i) {
    uint64_t marks = 0;
    if (hi <= lo || nh == 0 || Ki < 3) return 0;
    for (uint64_t k = 3; k <= Ki && !halt_flag; k += 4) {
        for (int hi_h = 0; hi_h < HARD_N && !halt_flag; hi_h++) {
            uint64_t h = (uint64_t)HARD[hi_h];
            uint64_t cres = ((h + k) / 4) % 210;
            uint64_t cmin = (lo + k) / 4 + 1;
            uint64_t cmax;
            if (hi > UINT64_MAX - k)
                cmax = UINT64_MAX / 4;
            else
                cmax = (hi + k) / 4;
            if (cmin < 1) cmin = 1;
            uint64_t C = first_congruent(cmin, 210, cres);
            for (; C <= cmax && C != UINT64_MAX && !halt_flag; ) {
                if (C > UINT64_MAX / 4) break;
                uint64_t p = 4 * C - k;
                int idx = find_hp(hp, nh, p);
                if (idx < 0) {
                    if (C > UINT64_MAX - 210) break;
                    C += 210;
                    continue;
                }
                if (first_i[idx]) {
                    if (C > UINT64_MAX - 210) break;
                    C += 210;
                    continue;
                }
                if (gcd64(C, k) != 1) {
                    if (C > UINT64_MAX - 210) break;
                    C += 210;
                    continue;
                }
                fac_t f;
                factor64(C, &f);
                if (delta_zero(&f, C, k)) {
                    first_i[idx] = (uint32_t)k;
                    marks++;
                }
                if (C > UINT64_MAX - 210) break;
                C += 210;
            }
        }
    }
    return marks;
}

static void collect_hard(uint64_t lo, uint64_t hi, uint64_t **hp, int *nh) {
    int cap = (int)((hi - lo) / 8 + 32);
    uint64_t *a = malloc((size_t)cap * sizeof(uint64_t));
    if (!a) die("oom window");
    int n = 0;
    uint64_t n0 = lo < 6 ? 6 : lo;
    for (uint64_t p = n0 + 1; p <= hi && !halt_flag; p++) {
        if (is_hard(p) && is_prime64(p)) {
            if (n == cap) {
                cap *= 2;
                a = realloc(a, (size_t)cap * sizeof(uint64_t));
                if (!a) die("oom window grow");
            }
            a[n++] = p;
        }
        if (p == UINT64_MAX) break;
        if (live_tty && (p & 4095ull) == 0ull) {
            dash_work_n = p;
            if (dash_due(0) && dash_sp)
                dash_draw(dash_sp, dash_step_v, dash_do_sweep, dash_do_home);
        }
    }
    *hp = a;
    *nh = n;
}

static void sieve_window(uint64_t lo, uint64_t hi, seed_t *seed) {
    if (hi <= lo) return;
    uint64_t *hp = NULL;
    int nh = 0;
    collect_hard(lo, hi, &hp, &nh);
    uint32_t *first_i = calloc((size_t)nh + 1, sizeof(uint32_t));
    if (!first_i) die("oom first_i");
    uint64_t constructed = construct_I(lo, hi, seed->g.Ki, hp, nh, first_i);
    seed->i_constructed += constructed;
    dash_i = constructed;

    uint64_t w_here = 0, n_here = 0, l_here = 0;
    for (int i = 0; i < nh && !halt_flag; i++) {
        uint64_t p = hp[i];
        int lin = try_4p_plus_1(p) || try_p_plus_4(p);
        int w = 0;
        if (lin) {
            seed->w_linear++;
            w = 1;
        } else {
            seed->w_r++;
            if (try_any_fab(p, seed->g.F)) {
                seed->w_fab++;
                w = 1;
            }
        }
        if (w) w_here++;
        if (first_i[i]) seed->i_hits++;
        int n = in_nr_cover(p, seed->g.En);
        if (n) {
            seed->n_hits++;
            n_here++;
        }
        int l = in_lopez_cover(p, seed->g.Al);
        if (l) {
            seed->l_hits++;
            l_here++;
        }
        int stacked = w || first_i[i] || n || l;
        if (stacked) {
            seed->dropped++;
            seed->covered++;
        } else {
            dash_note("IDENTIFIED  n=%" PRIu64 "  %s  construct+xray miss", p,
                      spectrum_of(p) >= 0 ? SPEC_NAME[spectrum_of(p)] : "?");
            if (!live_tty && dash_go)
                say_event(D_YEL, "TARGET IDENTIFIED  n=%" PRIu64 "  via=cbx2", p);
            save_letter(p, &seed->g);
            seed->letters_found++;
        }
    }
    dash_w = w_here;
    dash_n = n_here;
    dash_l = l_here;
    if (!live_tty && dash_stream) {
        printf("cbx2  window  I=%" PRIu64 "  W=%" PRIu64 "  N=%" PRIu64 "  L=%" PRIu64
               "  hard=%d\n",
               constructed, w_here, n_here, l_here, nh);
        fflush(stdout);
    }
    free(first_i);
    free(hp);
}

static void prosecute_residual(uint64_t p, seed_t *seed, const char *via) {
    uint32_t first = 0;
    uint64_t hp[1] = {p};
    uint32_t fi[1] = {0};
    construct_I(p - 1, p, seed->g.Ki, hp, 1, fi);
    first = fi[0];
    if (!first) first = (uint32_t)first_k_recognize(p, seed->g.Ki);
    int w = try_4p_plus_1(p) || try_p_plus_4(p) || try_any_fab(p, seed->g.F);
    int n = in_nr_cover(p, seed->g.En);
    int l = in_lopez_cover(p, seed->g.Al);
    if (first) seed->i_hits++;
    if (n) seed->n_hits++;
    if (l) seed->l_hits++;
    if (w || first || n || l) {
        seed->dropped++;
        seed->covered++;
        dash_note("DROPPED  n=%" PRIu64 "  %s", p, via);
        return;
    }
    dash_note("IDENTIFIED  n=%" PRIu64 "  %s", p, via);
    save_letter(p, &seed->g);
    seed->letters_found++;
}

static void home_batch(uint64_t span, seed_t *seed) {
    if (span < 4) span = DEFAULT_STEP;
    uint64_t S0 = seed->home_S < 5 ? 5 : seed->home_S;
    if ((S0 & 3) != 1) S0 += (1u - (S0 & 3)) & 3;
    uint64_t S1 = S0 + span;
    if (S1 < S0) S1 = UINT64_MAX;
    for (uint64_t S = S0; S <= S1 && !halt_flag; S += 4) {
        if (!in_sigma1(S)) continue;
        if (S <= 4) continue;
        uint64_t p = S - 4;
        if (!is_hard(p) || !is_prime64(p)) continue;
        if (!in_sigma1(4 * p + 1)) continue;
        seed->home_r++;
        if (try_any_fab(p, seed->g.F)) {
            seed->home_fab++;
            seed->dropped++;
            seed->covered++;
            continue;
        }
        prosecute_residual(p, seed, "home");
    }
    seed->home_S = S1;
}

static grade_t parse_grade(uint64_t F, uint64_t Ki, uint64_t En, uint64_t Al, uint64_t kmax) {
    grade_t g;
    g.F = F ? F : DEFAULT_F;
    g.Ki = Ki ? Ki : DEFAULT_KI;
    g.En = En ? En : DEFAULT_EN;
    g.Al = Al ? Al : DEFAULT_AL;
    if (kmax) {
        g.Ki = kmax;
        g.Al = kmax;
    }
    return g;
}

static void cmd_go(int want_random, uint64_t step, grade_t g, int sweep, int home,
                   int want_scroll) {
    seed_t seed;
    int have = access(seed_path, F_OK) == 0;
    if (have) {
        seed = load_seed();
        if (want_random)
            fprintf(stderr, "cbx2: seed exists; resuming at %" PRIu64 " (--random ignored)\n",
                    seed.scanned_through);
        if (seed.g.F != g.F || seed.g.Ki != g.Ki || seed.g.En != g.En || seed.g.Al != g.Al)
            fprintf(stderr,
                    "cbx2: seed grade Γ=(%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%" PRIu64
                    ") kept; command grade ignored\n",
                    seed.g.F, seed.g.Ki, seed.g.En, seed.g.Al);
    } else if (want_random) {
        seed = default_seed(random_start(), g);
        fprintf(stderr, "cbx2: new session, random start %" PRIu64 "\n", seed.start_factor);
    } else {
        seed = default_seed(0, g);
        fprintf(stderr, "cbx2: new session, start 0\n");
    }
    if (!step) step = DEFAULT_STEP;
    save_seed(&seed);
    dash_go = 1;
    use_color = color_ok();
    live_tty = isatty(1) && !want_scroll;
    dash_stream = !live_tty && want_scroll;
    dash_painted = 0;
    dash_dirty = 0;
    evn = 0;
    dash_sweep0 = seed.scanned_through;
    dash_home0 = seed.home_S;
    clock_gettime(CLOCK_MONOTONIC, &dash_t0);
    clock_gettime(CLOCK_MONOTONIC, &dash_run0);
    dash_bind(&seed, step, sweep, home);
    if (live_tty)
        dash_draw(&seed, step, sweep, home);
    else {
        printf("cbx2.kernel  formulation 2  LETTER only\n");
        printf("  Γ=(F=%" PRIu64 ", K_I=%" PRIu64 ", E_N=%" PRIu64 ", A_L=%" PRIu64 ")\n",
               seed.g.F, seed.g.Ki, seed.g.En, seed.g.Al);
        printf("  modes  sweep=%s  home=%s\n", sweep ? "on" : "off", home ? "on" : "off");
        fflush(stdout);
    }
    while (!halt_flag) {
        if (sweep) {
            uint64_t lo = seed.scanned_through;
            uint64_t hi = lo + step;
            if (hi < lo) hi = UINT64_MAX;
            sieve_window(lo, hi, &seed);
            seed.scanned_through = hi;
            seed.windows++;
            if (hi == UINT64_MAX && !home) break;
        }
        if (home && !halt_flag) home_batch(step, &seed);
        save_seed(&seed);
        if (live_tty) {
            if (dash_due(halt_flag)) dash_draw(&seed, step, sweep, home);
        } else if ((seed.windows % 20) == 0) {
            printf("cbx2  totals  scanned=%" PRIu64 "  home_S=%" PRIu64 "  collected=%" PRIu64
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
    say_event(D_DIM, "cbx2: saved sweep=%" PRIu64 "  home_S=%" PRIu64 "  collected=%" PRIu64,
              seed.scanned_through, seed.home_S, seed.letters_found);
}

static void cmd_status(void) {
    seed_t s = load_seed();
    printf("{\"kernel\":\"cbx2.kernel\",\"program\":\"ES+\","
           "\"start_factor\":%" PRIu64 ",\"scanned_through\":%" PRIu64 ",\"home_S\":%" PRIu64
           ",\"letters_found\":%" PRIu64 ",\"i_constructed\":%" PRIu64 ",\"F\":%" PRIu64
           ",\"K_I\":%" PRIu64 ",\"E_N\":%" PRIu64 ",\"A_L\":%" PRIu64 "}\n",
           s.start_factor, s.scanned_through, s.home_S, s.letters_found, s.i_constructed, s.g.F,
           s.g.Ki, s.g.En, s.g.Al);
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

static int stacked_cover(uint64_t p, const grade_t *g) {
    if (!is_hard(p) || !is_prime64(p)) return 0;
    if (try_4p_plus_1(p) || try_p_plus_4(p) || try_any_fab(p, g->F)) return 1;
    if (first_k_recognize(p, g->Ki)) return 1;
    if (in_nr_cover(p, g->En)) return 1;
    if (in_lopez_cover(p, g->Al)) return 1;
    return 0;
}

static void cmd_solve(uint64_t n) {
    grade_t g = parse_grade(0, 0, 0, 0, 0);
    if (n < 2) die("n >= 2");
    if (!is_hard(n) || !is_prime64(n)) {
        printf("{\"kernel\":\"cbx2.kernel\",\"letter\":false,\"n\":%" PRIu64
               ",\"reason\":\"not a Mordell-hard prime\"}\n",
               n);
        return;
    }
    uint64_t ki = first_k_recognize(n, g.Ki);
    int r = in_R(n);
    int lin = try_4p_plus_1(n) || try_p_plus_4(n);
    int fab = try_any_fab(n, g.F);
    int nr = in_nr_cover(n, g.En);
    int lp = in_lopez_cover(n, g.Al);
    int letter = !(lin || fab || ki || nr || lp);
    printf("{\"kernel\":\"cbx2.kernel\",\"letter\":%s,\"n\":%" PRIu64
           ",\"in_R\":%s,\"linear\":%s,\"fab\":%s,\"k_I\":%" PRIu64 ",\"N\":%s,\"L\":%s}\n",
           letter ? "true" : "false", n, r ? "true" : "false", lin ? "true" : "false",
           fab ? "true" : "false", ki, nr ? "true" : "false", lp ? "true" : "false");
}

static void cmd_probe(uint64_t n) {
    cmd_solve(n);
}

static int cmd_verify(uint64_t hi, uint64_t Ki) {
    if (hi < 10) hi = 100000;
    if (Ki < 3) Ki = 80;
    uint64_t *hp = NULL;
    int nh = 0;
    collect_hard(0, hi, &hp, &nh);
    uint32_t *first_i = calloc((size_t)nh + 1, sizeof(uint32_t));
    if (!first_i) die("oom verify");
    construct_I(0, hi, Ki, hp, nh, first_i);
    int mism = 0;
    for (int i = 0; i < nh; i++) {
        uint64_t rec = first_k_recognize(hp[i], Ki);
        if ((uint64_t)first_i[i] != rec) {
            fprintf(stderr, "cbx2: mismatch n=%" PRIu64 " construct=%u recognize=%" PRIu64 "\n",
                    hp[i], first_i[i], rec);
            mism++;
        }
    }
    printf("cbx2 verify  hi=%" PRIu64 "  K_I=%" PRIu64 "  hard=%d  mismatches=%d\n", hi, Ki, nh,
           mism);
    free(first_i);
    free(hp);
    return mism ? 1 : 0;
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
        fprintf(stderr, "cbx2: sha256 mismatch\n");
        return 1;
    }
    if (!is_prime64(2) || !is_prime64(1000003ull) || is_prime64(1000005ull)) {
        fprintf(stderr, "cbx2: primality self-test failed\n");
        return 1;
    }
    uint64_t a = 1000003ull, b = 1000033ull, n = a * b;
    fac_t f;
    factor64(n, &f);
    if (f.n != 2 || f.ps[0] != a || f.ps[1] != b) {
        fprintf(stderr, "cbx2: Pollard-rho factorization self-test failed\n");
        return 1;
    }
    grade_t g = parse_grade(0, 0, 0, 0, 0);
    static const uint64_t known[] = {1009, 2521, 9601, 10369, 9658489};
    for (size_t i = 0; i < sizeof known / sizeof known[0]; i++) {
        if (!stacked_cover(known[i], &g)) {
            fprintf(stderr, "cbx2: known solvable %" PRIu64 " not in cover\n", known[i]);
            return 1;
        }
    }
    if (!in_sigma1(13) || in_sigma1(15) || in_sigma1(21)) {
        fprintf(stderr, "cbx2: Sigma_1 test failed\n");
        return 1;
    }
    if (!in_R(2521) || in_R(1009)) {
        fprintf(stderr, "cbx2: R classification failed\n");
        return 1;
    }
    if (cmd_verify(3000, 80)) {
        fprintf(stderr, "cbx2: inverse/recognition disagree below 3000\n");
        return 1;
    }
    seed_t tmp;
    memset(&tmp, 0, sizeof tmp);
    tmp.g = g;
    char old_letters[768];
    snprintf(old_letters, sizeof old_letters, "%s", letters_dir);
    snprintf(letters_dir, sizeof letters_dir, "/tmp/cbx2-self-letters");
    mkdir(letters_dir, 0755);
    uint64_t before = tmp.letters_found;
    sieve_window(0, 3000, &tmp);
    snprintf(letters_dir, sizeof letters_dir, "%s", old_letters);
    if (tmp.letters_found != before) {
        fprintf(stderr, "cbx2: emitted a letter below 3000\n");
        return 1;
    }
    if (tmp.dropped == 0) {
        fprintf(stderr, "cbx2: marked nothing below 3000\n");
        return 1;
    }
    printf("cbx2 self-test OK\n");
    return 0;
}

static void usage(void) {
    fprintf(stderr,
            "cbx2.kernel — CB Formulation 2 (construct I, X-ray W/N/L, verdict, home R)\n"
            "  cbx2                     same as go (start 0, or resume)\n"
            "  cbx2 go [--random] [--home-only] [--sweep-only] [--scroll]\n"
            "  cbx2 go --k-max K --step N --fab F --i-max KI --n-max EN --l-max AL\n"
            "  cbx2 probe N\n"
            "  cbx2 verify --hi X --i-max K\n"
            "  cbx2 status | letters | solve N | self-test\n"
            "Separate from cbis.kernel and cbx.kernel. Same ES-LETTER-v1 numbers.\n"
            "Erdős–Straus remains open.\n");
}

int main(int argc, char **argv) {
    resolve_root();
    build_sieve(1000003ull);
    signal(SIGINT, on_stop);
    signal(SIGTERM, on_stop);

    const char *cmd = "go";
    int want_random = 0, want_scroll = 0;
    uint64_t arg = 0, opt_kmax = 0, opt_step = 0;
    uint64_t opt_F = 0, opt_Ki = 0, opt_En = 0, opt_Al = 0, opt_hi = 0;
    int do_sweep = 1, do_home = 1;
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
        else if (!strcmp(argv[i], "--scroll")) want_scroll = 1;
        else if (!strcmp(argv[i], "--k-max") && i + 1 < argc)
            opt_kmax = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--step") && i + 1 < argc)
            opt_step = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--fab") && i + 1 < argc)
            opt_F = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc)
            opt_Ki = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--n-max") && i + 1 < argc)
            opt_En = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--l-max") && i + 1 < argc)
            opt_Al = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--hi") && i + 1 < argc)
            opt_hi = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--home-only")) {
            do_home = 1;
            do_sweep = 0;
        } else if (!strcmp(argv[i], "--sweep-only")) {
            do_sweep = 1;
            do_home = 0;
        } else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            usage();
            return 0;
        } else {
            usage();
            return 2;
        }
    }

    grade_t g = parse_grade(opt_F, opt_Ki, opt_En, opt_Al, opt_kmax);

    if (!strcmp(cmd, "go") || !strcmp(cmd, "continue")) {
        cmd_go(want_random, opt_step, g, do_sweep, do_home, want_scroll);
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
    if (!strcmp(cmd, "solve") || !strcmp(cmd, "probe")) {
        if (arg < 2) {
            usage();
            return 2;
        }
        if (!strcmp(cmd, "probe"))
            cmd_probe(arg);
        else
            cmd_solve(arg);
        return 0;
    }
    if (!strcmp(cmd, "verify")) return cmd_verify(opt_hi ? opt_hi : arg, opt_Ki ? opt_Ki : 80);
    if (!strcmp(cmd, "self-test")) return cmd_self_test();
    usage();
    return 2;
}
