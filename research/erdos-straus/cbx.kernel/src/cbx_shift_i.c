/*
 * cbx_shift_i.c — finite shift-major Lane-I census for cbx.kernel.
 *
 * Third exact orientation for the same finite cover:
 *
 *     k -> p -> C=(p+k)/4
 *
 * Unlike p-major recognition, the outer loop is the shift. Unlike C-major
 * inversion, it traverses only the active Mordell-hard prime frontier. After
 * each increasing k, newly covered targets are removed from that frontier.
 * This preserves exact minimal first-k semantics while testing whether
 * shift-major batching removes the C-enumeration overhead of inverse-I.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

typedef unsigned __int128 shift_u128;

static const uint64_t SHIFT_HARD[6] = {1, 121, 169, 289, 361, 529};

typedef struct {
    uint64_t p;
    uint64_t first_k;
} shift_target_t;

static uint64_t shift_parse_u64(const char *name, const char *text) {
    errno = 0;
    char *end = NULL;
    unsigned long long v = strtoull(text, &end, 10);
    if (errno || !end || *end) die("invalid %s: %s", name, text);
    return (uint64_t)v;
}

static uint64_t shift_first_congruent(uint64_t lo, uint64_t mod, uint64_t residue) {
    uint64_t rem = lo % mod;
    uint64_t add = (residue + mod - rem) % mod;
    if (lo > UINT64_MAX - add) return UINT64_MAX;
    return lo + add;
}

static void shift_u128_decimal(shift_u128 x, char out[64]) {
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

static int cmp_target_p(const void *aa, const void *bb) {
    const shift_target_t *a = aa;
    const shift_target_t *b = bb;
    return a->p < b->p ? -1 : a->p > b->p ? 1 : 0;
}

static void shift_usage(void) {
    fprintf(stderr,
            "cbx-shift-i — finite shift-major Lane-I census\n"
            "  cbx-shift-i --hi X [--lo L] [--i-max K] [--segment N]\n"
            "              [--verify] [--hits FILE] [--residuals FILE]\n");
}

int main(int argc, char **argv) {
    uint64_t lo = 2;
    uint64_t hi = 0;
    uint64_t K = DEFAULT_I_MAX;
    uint64_t segment = 1000000;
    int verify = 0;
    const char *hits_path = NULL;
    const char *residual_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--lo") && i + 1 < argc) lo = shift_parse_u64("lo", argv[++i]);
        else if (!strcmp(argv[i], "--hi") && i + 1 < argc) hi = shift_parse_u64("hi", argv[++i]);
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) K = shift_parse_u64("i-max", argv[++i]);
        else if (!strcmp(argv[i], "--segment") && i + 1 < argc) segment = shift_parse_u64("segment", argv[++i]);
        else if (!strcmp(argv[i], "--verify")) verify = 1;
        else if (!strcmp(argv[i], "--hits") && i + 1 < argc) hits_path = argv[++i];
        else if (!strcmp(argv[i], "--residuals") && i + 1 < argc) residual_path = argv[++i];
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { shift_usage(); return 0; }
        else { shift_usage(); return 2; }
    }

    if (hi < 2 || hi < lo) die("--hi must be >= max(2,--lo)");
    if (K < 3) die("--i-max must be >= 3");
    if (!segment || segment > 100000000ULL) die("--segment must be in 1..100000000");

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

    shift_u128 hard_total = 0;
    shift_u128 covered_total = 0;
    shift_u128 residual_total = 0;
    shift_u128 active_visits = 0;
    shift_u128 coprime_skips = 0;
    shift_u128 factorizations = 0;
    shift_u128 verification_targets = 0;
    shift_u128 verification_mismatches = 0;

    for (uint64_t seg_lo = lo;;) {
        shift_u128 proposed = (shift_u128)seg_lo + segment - 1;
        uint64_t seg_hi = proposed > hi ? hi : (uint64_t)proposed;

        size_t cap = 256, n = 0;
        shift_target_t *targets = malloc(cap * sizeof(*targets));
        if (!targets) die("shift-major allocation failed");

        for (size_t r = 0; r < 6; r++) {
            uint64_t p = shift_first_congruent(seg_lo, 840, SHIFT_HARD[r]);
            if (p == UINT64_MAX) continue;
            while (p <= seg_hi) {
                if (p >= 2 && is_prime64(p)) {
                    if (n == cap) {
                        if (cap > SIZE_MAX / 2 / sizeof(*targets)) die("shift-major target overflow");
                        cap *= 2;
                        shift_target_t *tmp = realloc(targets, cap * sizeof(*targets));
                        if (!tmp) die("shift-major allocation failed");
                        targets = tmp;
                    }
                    targets[n].p = p;
                    targets[n].first_k = 0;
                    n++;
                    hard_total++;
                }
                if (p > UINT64_MAX - 840) break;
                p += 840;
            }
        }
        qsort(targets, n, sizeof(*targets), cmp_target_p);

        size_t *active = malloc((n ? n : 1) * sizeof(*active));
        size_t *next = malloc((n ? n : 1) * sizeof(*next));
        if (!active || !next) die("shift-major frontier allocation failed");
        for (size_t i = 0; i < n; i++) active[i] = i;
        size_t nactive = n;

        for (uint64_t k = 3; k <= K && nactive;) {
            size_t nnext = 0;
            for (size_t j = 0; j < nactive; j++) {
                size_t idx = active[j];
                uint64_t p = targets[idx].p;
                active_visits++;

                if (gcd64(k, p) != 1) {
                    coprime_skips++;
                    next[nnext++] = idx;
                    continue;
                }
                if (p > UINT64_MAX - k) {
                    next[nnext++] = idx;
                    continue;
                }

                uint64_t C = (p + k) / 4;
                fac_t f;
                factorizations++;
                factor64(C, &f);
                if (delta_zero(&f, C, k)) {
                    targets[idx].first_k = k;
                    covered_total++;
                } else {
                    next[nnext++] = idx;
                }
            }
            size_t *swap = active;
            active = next;
            next = swap;
            nactive = nnext;
            if (k > UINT64_MAX - 4) break;
            k += 4;
        }

        for (size_t i = 0; i < n; i++) {
            uint64_t p = targets[i].p;
            if (targets[i].first_k) {
                if (hits) fprintf(hits, "%" PRIu64 "\t%" PRIu64 "\n", p, targets[i].first_k);
            } else {
                residual_total++;
                if (residuals) fprintf(residuals, "%" PRIu64 "\n", p);
            }

            if (verify) {
                verification_targets++;
                probe_t q;
                memset(&q, 0, sizeof q);
                int forward = lane_i_first(p, K, &q);
                int shift_hit = targets[i].first_k != 0;
                if (forward != shift_hit || (forward && q.i_first != targets[i].first_k)) {
                    verification_mismatches++;
                    fprintf(stderr,
                            "shift-major mismatch p=%" PRIu64 " shift=%d first=%" PRIu64
                            " forward=%d first=%" PRIu64 "\n",
                            p, shift_hit, targets[i].first_k, forward, q.i_first);
                }
            }
        }

        free(next);
        free(active);
        free(targets);

        if (seg_hi == hi || seg_hi == UINT64_MAX) break;
        seg_lo = seg_hi + 1;
    }

    if (hits) fclose(hits);
    if (residuals) fclose(residuals);

    char hard_s[64], covered_s[64], residual_s[64], visits_s[64], skip_s[64], fact_s[64];
    char verify_s[64], mismatch_s[64];
    shift_u128_decimal(hard_total, hard_s);
    shift_u128_decimal(covered_total, covered_s);
    shift_u128_decimal(residual_total, residual_s);
    shift_u128_decimal(active_visits, visits_s);
    shift_u128_decimal(coprime_skips, skip_s);
    shift_u128_decimal(factorizations, fact_s);
    shift_u128_decimal(verification_targets, verify_s);
    shift_u128_decimal(verification_mismatches, mismatch_s);

    printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"mode\":\"shift-I\","
           "\"lo\":%" PRIu64 ",\"hi\":%" PRIu64 ",\"i_max\":%" PRIu64
           ",\"segment\":%" PRIu64 ",\"hard_primes\":%s,"
           "\"covered_hard_primes\":%s,\"residual_hard_primes\":%s,"
           "\"active_visits\":%s,\"coprime_skips\":%s,\"factorizations\":%s,"
           "\"verify\":%s,\"verification_targets\":%s,\"verification_mismatches\":%s}\n",
           VERSION, lo, hi, K, segment, hard_s, covered_s, residual_s, visits_s, skip_s,
           fact_s, verify ? "true" : "false", verify_s, mismatch_s);

    return verification_mismatches ? 1 : 0;
}
