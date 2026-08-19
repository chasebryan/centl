/*
 * cbx_forward_i.c — finite p-first Lane-I reference census for cbx.kernel.
 *
 * This exists to benchmark the constructive inverse-I engine honestly. It
 * performs the ordinary recognition orientation
 *
 *     p -> k -> C=(p+k)/4
 *
 * on exactly the Mordell-hard prime universe and counts how many signed-box
 * factorizations are actually performed before the first hit.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

typedef unsigned __int128 fwd_u128;

static const uint64_t FWD_HARD[6] = {1, 121, 169, 289, 361, 529};

static uint64_t fwd_parse_u64(const char *name, const char *text) {
    errno = 0;
    char *end = NULL;
    unsigned long long v = strtoull(text, &end, 10);
    if (errno || !end || *end) die("invalid %s: %s", name, text);
    return (uint64_t)v;
}

static uint64_t fwd_first_congruent(uint64_t lo, uint64_t mod, uint64_t residue) {
    uint64_t rem = lo % mod;
    uint64_t add = (residue + mod - rem) % mod;
    if (lo > UINT64_MAX - add) return UINT64_MAX;
    return lo + add;
}

static void fwd_u128_decimal(fwd_u128 x, char out[64]) {
    char rev[64];
    size_t n = 0;
    if (!x) {
        strcpy(out, "0");
        return;
    }
    while (x) {
        rev[n++] = (char)('0' + (x % 10));
        x /= 10;
    }
    for (size_t i = 0; i < n; i++) out[i] = rev[n - 1 - i];
    out[n] = 0;
}

static int forward_i_first_count(uint64_t p, uint64_t K, uint64_t *first_k,
                                 fwd_u128 *shift_candidates,
                                 fwd_u128 *factorizations) {
    for (uint64_t k = 3; k <= K;) {
        (*shift_candidates)++;
        if (gcd64(k, p) == 1 && p <= UINT64_MAX - k && (p + k) % 4 == 0) {
            uint64_t C = (p + k) / 4;
            fac_t f;
            (*factorizations)++;
            factor64(C, &f);
            if (delta_zero(&f, C, k)) {
                if (first_k) *first_k = k;
                return 1;
            }
        }
        if (k > UINT64_MAX - 4) break;
        k += 4;
    }
    return 0;
}

static void fwd_usage(void) {
    fprintf(stderr,
            "cbx-forward-i — finite p-first Lane-I reference census\n"
            "  cbx-forward-i --hi X [--lo L] [--i-max K]\n"
            "                [--hits FILE] [--residuals FILE]\n");
}

int main(int argc, char **argv) {
    uint64_t lo = 2;
    uint64_t hi = 0;
    uint64_t K = DEFAULT_I_MAX;
    const char *hits_path = NULL;
    const char *residual_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--lo") && i + 1 < argc) lo = fwd_parse_u64("lo", argv[++i]);
        else if (!strcmp(argv[i], "--hi") && i + 1 < argc) hi = fwd_parse_u64("hi", argv[++i]);
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) K = fwd_parse_u64("i-max", argv[++i]);
        else if (!strcmp(argv[i], "--hits") && i + 1 < argc) hits_path = argv[++i];
        else if (!strcmp(argv[i], "--residuals") && i + 1 < argc) residual_path = argv[++i];
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { fwd_usage(); return 0; }
        else { fwd_usage(); return 2; }
    }

    if (hi < 2 || hi < lo) die("--hi must be >= max(2,--lo)");
    if (K < 3) die("--i-max must be >= 3");

    FILE *hits = NULL;
    FILE *residuals = NULL;
    if (hits_path) {
        hits = fopen(hits_path, "w");
        if (!hits) die("cannot open hit output: %s", strerror(errno));
    }
    if (residual_path) {
        residuals = fopen(residual_path, "w");
        if (!residuals) die("cannot open residual output: %s", strerror(errno));
    }

    fwd_u128 hard_total = 0;
    fwd_u128 covered_total = 0;
    fwd_u128 residual_total = 0;
    fwd_u128 shift_candidates = 0;
    fwd_u128 factorizations = 0;

    for (size_t r = 0; r < 6; r++) {
        uint64_t p = fwd_first_congruent(lo, 840, FWD_HARD[r]);
        if (p == UINT64_MAX) continue;
        while (p <= hi) {
            if (p >= 2 && is_prime64(p)) {
                hard_total++;
                uint64_t first_k = 0;
                if (forward_i_first_count(p, K, &first_k, &shift_candidates, &factorizations)) {
                    covered_total++;
                    if (hits) fprintf(hits, "%" PRIu64 "\t%" PRIu64 "\n", p, first_k);
                } else {
                    residual_total++;
                    if (residuals) fprintf(residuals, "%" PRIu64 "\n", p);
                }
            }
            if (p > UINT64_MAX - 840) break;
            p += 840;
        }
    }

    if (hits) fclose(hits);
    if (residuals) fclose(residuals);

    char hard_s[64], covered_s[64], residual_s[64], shift_s[64], factor_s[64];
    fwd_u128_decimal(hard_total, hard_s);
    fwd_u128_decimal(covered_total, covered_s);
    fwd_u128_decimal(residual_total, residual_s);
    fwd_u128_decimal(shift_candidates, shift_s);
    fwd_u128_decimal(factorizations, factor_s);

    printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"mode\":\"forward-I\","
           "\"lo\":%" PRIu64 ",\"hi\":%" PRIu64 ",\"i_max\":%" PRIu64
           ",\"hard_primes\":%s,\"covered_hard_primes\":%s,\"residual_hard_primes\":%s,"
           "\"shift_candidates\":%s,\"factorizations\":%s}\n",
           VERSION, lo, hi, K, hard_s, covered_s, residual_s, shift_s, factor_s);
    return 0;
}
