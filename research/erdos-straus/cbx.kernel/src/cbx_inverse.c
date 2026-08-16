/*
 * cbx_inverse.c — exact finite inverse signed-box census for cbx.kernel 0.1.0
 *
 * This is the constructive orientation of ES-plus/LETTER-EQUATION.md:
 *
 *     k -> C -> p = 4C-k.
 *
 * For a fixed admissible k and a Mordell-hard residue h (mod 840),
 *
 *     p == h (mod 840)
 *
 * is equivalent to
 *
 *     C == (h+k)/4 (mod 210),
 *
 * because h == 1 (mod 4) and k == 3 (mod 4). Thus only six C residue
 * classes modulo 210 need to be enumerated for each k.
 *
 * Crucially, delta_k(C) is evaluated before the generated p is looked up in
 * the hard-prime map. That preserves the inverse search orientation instead
 * of silently turning this back into a p-first Lane-I recognizer.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

static const uint64_t INV_HARD[6] = {1, 121, 169, 289, 361, 529};

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

static void inv_usage(void) {
    fprintf(stderr,
            "cbx inverse — exact finite inverse signed-box census\n"
            "  cbx-inverse --hi X [--lo L] [--i-max K] [--segment N]\n"
            "              [--verify] [--residuals FILE] [--hits FILE]\n\n"
            "Defaults: lo=2, i-max=400, segment=1000000. --hi is required.\n"
            "--verify cross-checks every hard prime against the p-first Lane-I recognizer.\n");
}

int main(int argc, char **argv) {
    uint64_t lo = 2;
    uint64_t hi = 0;
    uint64_t K = DEFAULT_I_MAX;
    uint64_t segment = 1000000;
    int verify = 0;
    const char *residual_path = NULL;
    const char *hits_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--lo") && i + 1 < argc) lo = inv_parse_u64("lo", argv[++i]);
        else if (!strcmp(argv[i], "--hi") && i + 1 < argc) hi = inv_parse_u64("hi", argv[++i]);
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) K = inv_parse_u64("i-max", argv[++i]);
        else if (!strcmp(argv[i], "--segment") && i + 1 < argc) segment = inv_parse_u64("segment", argv[++i]);
        else if (!strcmp(argv[i], "--verify")) verify = 1;
        else if (!strcmp(argv[i], "--residuals") && i + 1 < argc) residual_path = argv[++i];
        else if (!strcmp(argv[i], "--hits") && i + 1 < argc) hits_path = argv[++i];
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

    u128 hard_total = 0;
    u128 c_candidates = 0;
    u128 delta_hits = 0;
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

        /* Build only the target universe: Mordell-hard primes in this segment. */
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

        /*
         * True inverse orientation. For every admissible k, enumerate C in
         * the six residue classes forced by the hard p classes. Test delta on
         * C first; only a generated hit is then mapped into the prime target
         * universe.
         */
        for (uint64_t k = 3; k <= K;) {
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
                    fac_t f;
                    factor64(C, &f);
                    if (delta_zero(&f, C, k)) {
                        delta_hits++;
                        u128 fourC = (u128)4 * C;
                        if (fourC >= k) {
                            u128 p128 = fourC - k;
                            if (p128 >= seg_lo && p128 <= seg_hi) {
                                uint64_t p = (uint64_t)p128;
                                size_t idx = (size_t)(p - seg_lo);
                                if (hard_prime[idx] && !covered[idx]) {
                                    covered[idx] = 1;
                                    first_k[idx] = k;
                                    covered_total++;
                                }
                            }
                        }
                    }
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

    char hard_s[64], cand_s[64], delta_s[64], covered_s[64], residual_s[64];
    char verify_s[64], mismatch_s[64];
    u128_decimal(hard_total, hard_s);
    u128_decimal(c_candidates, cand_s);
    u128_decimal(delta_hits, delta_s);
    u128_decimal(covered_total, covered_s);
    u128_decimal(residual_total, residual_s);
    u128_decimal(verification_targets, verify_s);
    u128_decimal(verification_mismatches, mismatch_s);

    printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"mode\":\"inverse-I\","
           "\"lo\":%" PRIu64 ",\"hi\":%" PRIu64 ",\"i_max\":%" PRIu64
           ",\"segment\":%" PRIu64 ",\"hard_primes\":%s,\"C_candidates\":%s,"
           "\"delta_hits\":%s,\"covered_hard_primes\":%s,\"residual_hard_primes\":%s,"
           "\"verify\":%s,\"verification_targets\":%s,\"verification_mismatches\":%s}\n",
           VERSION, lo, hi, K, segment, hard_s, cand_s, delta_s, covered_s, residual_s,
           verify ? "true" : "false", verify_s, mismatch_s);

    return verification_mismatches ? 1 : 0;
}
