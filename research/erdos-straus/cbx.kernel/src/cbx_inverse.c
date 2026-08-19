/*
 * cbx_inverse.c — exact finite inverse signed-box census for cbx.kernel 0.1.0
 *
 * Constructive orientation of ES-plus/LETTER-EQUATION.md:
 *
 *     k -> C -> p = 4C-k.
 *
 * For fixed admissible k and Mordell-hard residue h (mod 840),
 *
 *     C == (h+k)/4 (mod 210).
 *
 * The default target-gated mode still keeps k and C as the outer search,
 * but after p=4C-k is generated it cheaply rejects composite/non-target p
 * and targets already covered by a smaller k before factoring C. Because k
 * is increasing, these gates cannot change cover membership or minimal first
 * k. --strict-c-first preserves the ungated constructive baseline.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

typedef unsigned __int128 u128;

static const uint64_t INV_HARD[6] = {1, 121, 169, 289, 361, 529};

typedef struct {
    u128 c_candidates;
    u128 hard_targets;
    u128 skipped_non_target;
    u128 skipped_covered;
    u128 skipped_non_coprime;
    u128 factorizations;
    u128 delta_hits;
    u128 new_covered;
} layer_stat_t;

static uint64_t inv_parse_u64(const char *name, const char *text) {
    errno = 0;
    char *end = NULL;
    unsigned long long v = strtoull(text, &end, 10);
    if (errno || !end || *end) die("invalid %s: %s", name, text);
    return (uint64_t)v;
}

static uint64_t first_congruent(uint64_t lo, uint64_t mod, uint64_t residue) {
    uint64_t rem = lo % mod;
    uint64_t add = (residue + mod - rem) % mod;
    if (lo > UINT64_MAX - add) return UINT64_MAX;
    return lo + add;
}

static void u128_decimal(u128 x, char out[64]) {
    char rev[64];
    size_t n = 0;
    if (x == 0) {
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

static size_t layer_count_for(uint64_t K) {
    if (K < 3) return 0;
    u128 n = ((u128)K - 3) / 4 + 1;
    if (n > SIZE_MAX / sizeof(layer_stat_t)) die("i-max too large for layer telemetry");
    return (size_t)n;
}

static void write_layer_stats(const char *path, const layer_stat_t *stats, size_t n) {
    FILE *f = fopen(path, "w");
    if (!f) die("cannot open layer telemetry: %s", strerror(errno));
    fputs("k\tC_candidates\thard_targets\tskipped_non_target\tskipped_covered\t"
          "skipped_non_coprime\tfactorizations\tdelta_hits\tnew_covered\n", f);
    for (size_t i = 0; i < n; i++) {
        uint64_t k = 3 + 4 * (uint64_t)i;
        char a[64], b[64], c[64], d[64], e[64], g[64], h[64], j[64];
        u128_decimal(stats[i].c_candidates, a);
        u128_decimal(stats[i].hard_targets, b);
        u128_decimal(stats[i].skipped_non_target, c);
        u128_decimal(stats[i].skipped_covered, d);
        u128_decimal(stats[i].skipped_non_coprime, e);
        u128_decimal(stats[i].factorizations, g);
        u128_decimal(stats[i].delta_hits, h);
        u128_decimal(stats[i].new_covered, j);
        fprintf(f, "%" PRIu64 "\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                k, a, b, c, d, e, g, h, j);
    }
    if (fflush(f) != 0 || fsync(fileno(f)) != 0) die("cannot flush layer telemetry");
    fclose(f);
}

static void inv_usage(void) {
    fprintf(stderr,
            "cbx inverse — exact finite inverse signed-box census\n"
            "  cbx-inverse --hi X [--lo L] [--i-max K] [--segment N]\n"
            "              [--verify] [--strict-c-first|--target-gated]\n"
            "              [--residuals FILE] [--hits FILE] [--layers FILE]\n\n"
            "Defaults: lo=2, i-max=400, segment=1000000, target-gated.\n"
            "--strict-c-first factors every compatible C before target lookup.\n"
            "--target-gated generates p first and skips irrelevant/already-covered targets.\n"
            "--layers writes aggregate per-k work and new-cover telemetry.\n"
            "--verify cross-checks every hard prime against p-first Lane-I recognition.\n");
}

int main(int argc, char **argv) {
    uint64_t lo = 2;
    uint64_t hi = 0;
    uint64_t K = DEFAULT_I_MAX;
    uint64_t segment = 1000000;
    int verify = 0;
    int target_gate = 1;
    const char *residual_path = NULL;
    const char *hits_path = NULL;
    const char *layers_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--lo") && i + 1 < argc) lo = inv_parse_u64("lo", argv[++i]);
        else if (!strcmp(argv[i], "--hi") && i + 1 < argc) hi = inv_parse_u64("hi", argv[++i]);
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) K = inv_parse_u64("i-max", argv[++i]);
        else if (!strcmp(argv[i], "--segment") && i + 1 < argc) segment = inv_parse_u64("segment", argv[++i]);
        else if (!strcmp(argv[i], "--verify")) verify = 1;
        else if (!strcmp(argv[i], "--strict-c-first")) target_gate = 0;
        else if (!strcmp(argv[i], "--target-gated")) target_gate = 1;
        else if (!strcmp(argv[i], "--residuals") && i + 1 < argc) residual_path = argv[++i];
        else if (!strcmp(argv[i], "--hits") && i + 1 < argc) hits_path = argv[++i];
        else if (!strcmp(argv[i], "--layers") && i + 1 < argc) layers_path = argv[++i];
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { inv_usage(); return 0; }
        else { inv_usage(); return 2; }
    }

    if (hi < 2 || hi < lo) die("--hi must be >= max(2,--lo)");
    if (K < 3) die("--i-max must be >= 3");
    if (!segment || segment > 100000000ULL) die("--segment must be in 1..100000000");

    FILE *residuals = NULL;
    FILE *hits = NULL;
    if (residual_path) {
        residuals = fopen(residual_path, "w");
        if (!residuals) die("cannot open residual output: %s", strerror(errno));
    }
    if (hits_path) {
        hits = fopen(hits_path, "w");
        if (!hits) die("cannot open hit output: %s", strerror(errno));
    }

    size_t n_layers = layer_count_for(K);
    layer_stat_t *layer_stats = NULL;
    if (layers_path) {
        layer_stats = calloc(n_layers, sizeof(*layer_stats));
        if (!layer_stats) die("cannot allocate layer telemetry");
    }

    u128 hard_total = 0;
    u128 c_candidates = 0;
    u128 factorizations = 0;
    u128 delta_hits = 0;
    u128 skipped_non_target = 0;
    u128 skipped_covered = 0;
    u128 skipped_non_coprime = 0;
    u128 covered_total = 0;
    u128 residual_total = 0;
    u128 verification_targets = 0;
    u128 verification_mismatches = 0;

    for (uint64_t seg_lo = lo;;) {
        u128 proposed = (u128)seg_lo + (u128)segment - 1;
        uint64_t seg_hi = proposed > hi ? hi : (uint64_t)proposed;
        uint64_t span64 = seg_hi - seg_lo + 1;
        size_t span = (size_t)span64;

        uint8_t *hard_prime = calloc(span, 1);
        uint8_t *covered = calloc(span, 1);
        uint64_t *first_k = calloc(span, sizeof(uint64_t));
        if (!hard_prime || !covered || !first_k) die("inverse segment allocation failed");

        /* Exact finite target universe for this p segment. */
        for (size_t r = 0; r < 6; r++) {
            uint64_t p = first_congruent(seg_lo, 840, INV_HARD[r]);
            if (p == UINT64_MAX) continue;
            while (p <= seg_hi) {
                if (p >= 2 && is_prime64(p)) {
                    hard_prime[(size_t)(p - seg_lo)] = 1;
                    hard_total++;
                }
                if (p > UINT64_MAX - 840) break;
                p += 840;
            }
        }

        size_t layer_index = 0;
        for (uint64_t k = 3; k <= K; layer_index++) {
            layer_stat_t *ls = layer_stats ? &layer_stats[layer_index] : NULL;
            u128 clo128 = ((u128)seg_lo + k + 3) / 4;
            u128 chi128 = ((u128)seg_hi + k) / 4;
            uint64_t C_lo = (uint64_t)clo128;
            uint64_t C_hi = (uint64_t)chi128;

            for (size_t r = 0; r < 6; r++) {
                uint64_t c_res = (uint64_t)((((u128)INV_HARD[r] + k) / 4) % 210);
                uint64_t C = first_congruent(C_lo, 210, c_res);
                if (C == UINT64_MAX) continue;

                while (C <= C_hi) {
                    c_candidates++;
                    if (ls) ls->c_candidates++;

                    u128 fourC = (u128)4 * C;
                    if (fourC >= k) {
                        u128 p128 = fourC - k;
                        if (p128 >= seg_lo && p128 <= seg_hi) {
                            uint64_t p = (uint64_t)p128;
                            size_t idx = (size_t)(p - seg_lo);
                            if (hard_prime[idx] && ls) ls->hard_targets++;

                            if (target_gate) {
                                if (!hard_prime[idx]) {
                                    skipped_non_target++;
                                    if (ls) ls->skipped_non_target++;
                                    goto next_C;
                                }
                                if (covered[idx]) {
                                    skipped_covered++;
                                    if (ls) ls->skipped_covered++;
                                    goto next_C;
                                }
                                /* gcd(C,k)=1 iff gcd(p,k)=1 for odd k. */
                                if (gcd64(C, k) != 1) {
                                    skipped_non_coprime++;
                                    if (ls) ls->skipped_non_coprime++;
                                    goto next_C;
                                }
                            }

                            fac_t f;
                            factorizations++;
                            if (ls) ls->factorizations++;
                            factor64(C, &f);
                            if (delta_zero(&f, C, k)) {
                                delta_hits++;
                                if (ls) ls->delta_hits++;
                                if (hard_prime[idx] && !covered[idx]) {
                                    covered[idx] = 1;
                                    first_k[idx] = k;
                                    covered_total++;
                                    if (ls) ls->new_covered++;
                                }
                            }
                        }
                    }

next_C:
                    if (C > UINT64_MAX - 210) break;
                    C += 210;
                }
            }

            if (k > UINT64_MAX - 4) break;
            k += 4;
        }

        for (size_t idx = 0; idx < span; idx++) {
            if (!hard_prime[idx]) continue;
            uint64_t p = seg_lo + (uint64_t)idx;
            if (covered[idx]) {
                if (hits) fprintf(hits, "%" PRIu64 "\t%" PRIu64 "\n", p, first_k[idx]);
            } else {
                residual_total++;
                if (residuals) fprintf(residuals, "%" PRIu64 "\n", p);
            }

            if (verify) {
                verification_targets++;
                probe_t q;
                memset(&q, 0, sizeof q);
                int forward = lane_i_first(p, K, &q);
                int inverse = covered[idx] != 0;
                if (forward != inverse || (forward && q.i_first != first_k[idx])) {
                    verification_mismatches++;
                    fprintf(stderr,
                            "inverse mismatch p=%" PRIu64 " inverse=%d first=%" PRIu64
                            " forward=%d first=%" PRIu64 "\n",
                            p, inverse, first_k[idx], forward, q.i_first);
                }
            }
        }

        free(first_k);
        free(covered);
        free(hard_prime);

        if (seg_hi == hi || seg_hi == UINT64_MAX) break;
        seg_lo = seg_hi + 1;
    }

    if (residuals) fclose(residuals);
    if (hits) fclose(hits);
    if (layers_path) write_layer_stats(layers_path, layer_stats, n_layers);
    free(layer_stats);

    char hard_s[64], cand_s[64], fact_s[64], delta_s[64], non_target_s[64];
    char covered_skip_s[64], non_coprime_s[64], covered_s[64], residual_s[64];
    char verify_s[64], mismatch_s[64];
    u128_decimal(hard_total, hard_s);
    u128_decimal(c_candidates, cand_s);
    u128_decimal(factorizations, fact_s);
    u128_decimal(delta_hits, delta_s);
    u128_decimal(skipped_non_target, non_target_s);
    u128_decimal(skipped_covered, covered_skip_s);
    u128_decimal(skipped_non_coprime, non_coprime_s);
    u128_decimal(covered_total, covered_s);
    u128_decimal(residual_total, residual_s);
    u128_decimal(verification_targets, verify_s);
    u128_decimal(verification_mismatches, mismatch_s);

    printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"mode\":\"inverse-I\","
           "\"candidate_mode\":\"%s\",\"lo\":%" PRIu64 ",\"hi\":%" PRIu64
           ",\"i_max\":%" PRIu64 ",\"segment\":%" PRIu64
           ",\"hard_primes\":%s,\"C_candidates\":%s,\"factorizations\":%s,"
           "\"delta_hits\":%s,\"skipped_non_target\":%s,\"skipped_covered\":%s,"
           "\"skipped_non_coprime\":%s,\"covered_hard_primes\":%s,"
           "\"residual_hard_primes\":%s,\"layers_recorded\":%s,\"verify\":%s,"
           "\"verification_targets\":%s,\"verification_mismatches\":%s}\n",
           VERSION, target_gate ? "target-gated" : "strict-c-first", lo, hi, K, segment,
           hard_s, cand_s, fact_s, delta_s, non_target_s, covered_skip_s, non_coprime_s,
           covered_s, residual_s, layers_path ? "true" : "false",
           verify ? "true" : "false", verify_s, mismatch_s);

    return verification_mismatches ? 1 : 0;
}
