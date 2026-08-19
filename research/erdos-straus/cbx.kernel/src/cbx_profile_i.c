/*
 * cbx_profile_i.c — exact finite per-shift Lane-I profiler.
 *
 * Uses the shift-major survivor frontier to measure, for every admissible k:
 * active targets, exact factorizations, first hits, A/B/C first-hit mix, and
 * the number of compatible C values the C-major traversal would enumerate.
 * The profile is intended to drive and falsify hybrid scheduling policies.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

typedef unsigned __int128 prof_u128;

static const uint64_t PROF_HARD[6] = {1, 121, 169, 289, 361, 529};

typedef struct {
    uint64_t p;
    int spectrum;
} prof_target_t;

typedef struct {
    prof_u128 active_visits;
    prof_u128 coprime_skips;
    prof_u128 factorizations;
    prof_u128 first_hits;
    prof_u128 c_candidates;
    prof_u128 spectrum_hits[3];
} prof_kstat_t;

static uint64_t prof_parse_u64(const char *name, const char *text) {
    errno = 0;
    char *end = NULL;
    unsigned long long v = strtoull(text, &end, 10);
    if (errno || !end || *end) die("invalid %s: %s", name, text);
    return (uint64_t)v;
}

static uint64_t prof_first_congruent(uint64_t lo, uint64_t mod, uint64_t residue) {
    uint64_t rem = lo % mod;
    uint64_t add = (residue + mod - rem) % mod;
    if (lo > UINT64_MAX - add) return UINT64_MAX;
    return lo + add;
}

static prof_u128 count_congruent(uint64_t lo, uint64_t hi, uint64_t mod, uint64_t residue) {
    if (lo > hi) return 0;
    uint64_t first = prof_first_congruent(lo, mod, residue);
    if (first == UINT64_MAX || first > hi) return 0;
    return (prof_u128)((hi - first) / mod) + 1;
}

static void prof_u128_decimal(prof_u128 x, char out[64]) {
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

static int cmp_prof_target(const void *aa, const void *bb) {
    const prof_target_t *a = aa;
    const prof_target_t *b = bb;
    return a->p < b->p ? -1 : a->p > b->p ? 1 : 0;
}

static void prof_usage(void) {
    fprintf(stderr,
            "cbx-profile-i — exact finite per-shift Lane-I profile\n"
            "  cbx-profile-i --hi X [--lo L] [--i-max K] [--segment N]\n");
}

int main(int argc, char **argv) {
    uint64_t lo = 2;
    uint64_t hi = 0;
    uint64_t K = DEFAULT_I_MAX;
    uint64_t segment = 1000000;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--lo") && i + 1 < argc) lo = prof_parse_u64("lo", argv[++i]);
        else if (!strcmp(argv[i], "--hi") && i + 1 < argc) hi = prof_parse_u64("hi", argv[++i]);
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) K = prof_parse_u64("i-max", argv[++i]);
        else if (!strcmp(argv[i], "--segment") && i + 1 < argc) segment = prof_parse_u64("segment", argv[++i]);
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { prof_usage(); return 0; }
        else { prof_usage(); return 2; }
    }

    if (hi < 2 || hi < lo) die("--hi must be >= max(2,--lo)");
    if (K < 3) die("--i-max must be >= 3");
    if (!segment || segment > 100000000ULL) die("--segment must be in 1..100000000");

    uint64_t nshifts64 = (K - 3) / 4 + 1;
    if (nshifts64 > SIZE_MAX / sizeof(prof_kstat_t)) die("too many profile shifts");
    size_t nshifts = (size_t)nshifts64;
    prof_kstat_t *stats = calloc(nshifts, sizeof(*stats));
    if (!stats) die("profile allocation failed");

    prof_u128 hard_total = 0;
    prof_u128 covered_total = 0;

    for (uint64_t seg_lo = lo;;) {
        prof_u128 proposed = (prof_u128)seg_lo + segment - 1;
        uint64_t seg_hi = proposed > hi ? hi : (uint64_t)proposed;

        size_t cap = 256, n = 0;
        prof_target_t *targets = malloc(cap * sizeof(*targets));
        if (!targets) die("profile target allocation failed");

        for (size_t r = 0; r < 6; r++) {
            uint64_t p = prof_first_congruent(seg_lo, 840, PROF_HARD[r]);
            if (p == UINT64_MAX) continue;
            while (p <= seg_hi) {
                if (p >= 2 && is_prime64(p)) {
                    if (n == cap) {
                        if (cap > SIZE_MAX / 2 / sizeof(*targets)) die("profile target overflow");
                        cap *= 2;
                        prof_target_t *tmp = realloc(targets, cap * sizeof(*targets));
                        if (!tmp) die("profile target allocation failed");
                        targets = tmp;
                    }
                    targets[n].p = p;
                    targets[n].spectrum = spectrum_of(p);
                    n++;
                    hard_total++;
                }
                if (p > UINT64_MAX - 840) break;
                p += 840;
            }
        }
        qsort(targets, n, sizeof(*targets), cmp_prof_target);

        size_t *active = malloc((n ? n : 1) * sizeof(*active));
        size_t *next = malloc((n ? n : 1) * sizeof(*next));
        if (!active || !next) die("profile frontier allocation failed");
        for (size_t i = 0; i < n; i++) active[i] = i;
        size_t nactive = n;

        for (size_t si = 0; si < nshifts; si++) {
            uint64_t k = 3 + 4 * (uint64_t)si;
            prof_kstat_t *st = &stats[si];
            st->active_visits += nactive;

            /* Count the exact C-major residue-class traversal for this shift. */
            prof_u128 clo128 = ((prof_u128)seg_lo + k + 3) / 4;
            prof_u128 chi128 = ((prof_u128)seg_hi + k) / 4;
            uint64_t C_lo = (uint64_t)clo128;
            uint64_t C_hi = (uint64_t)chi128;
            for (size_t r = 0; r < 6; r++) {
                uint64_t c_res = (uint64_t)((((prof_u128)PROF_HARD[r] + k) / 4) % 210);
                st->c_candidates += count_congruent(C_lo, C_hi, 210, c_res);
            }

            if (!nactive) continue;
            size_t nnext = 0;
            for (size_t j = 0; j < nactive; j++) {
                size_t idx = active[j];
                uint64_t p = targets[idx].p;
                if (gcd64(k, p) != 1) {
                    st->coprime_skips++;
                    next[nnext++] = idx;
                    continue;
                }
                if (p > UINT64_MAX - k) {
                    next[nnext++] = idx;
                    continue;
                }
                uint64_t C = (p + k) / 4;
                fac_t f;
                st->factorizations++;
                factor64(C, &f);
                if (delta_zero(&f, C, k)) {
                    st->first_hits++;
                    if (targets[idx].spectrum >= 0 && targets[idx].spectrum < 3)
                        st->spectrum_hits[targets[idx].spectrum]++;
                    covered_total++;
                } else {
                    next[nnext++] = idx;
                }
            }
            size_t *swap = active;
            active = next;
            next = swap;
            nactive = nnext;
        }

        free(next);
        free(active);
        free(targets);

        if (seg_hi == hi || seg_hi == UINT64_MAX) break;
        seg_lo = seg_hi + 1;
    }

    char hard_s[64], covered_s[64], residual_s[64];
    prof_u128_decimal(hard_total, hard_s);
    prof_u128_decimal(covered_total, covered_s);
    prof_u128_decimal(hard_total - covered_total, residual_s);

    printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"mode\":\"profile-I\","
           "\"lo\":%" PRIu64 ",\"hi\":%" PRIu64 ",\"i_max\":%" PRIu64
           ",\"segment\":%" PRIu64 ",\"hard_primes\":%s,\"covered_hard_primes\":%s,"
           "\"residual_hard_primes\":%s,\"shifts\":[",
           VERSION, lo, hi, K, segment, hard_s, covered_s, residual_s);

    for (size_t si = 0; si < nshifts; si++) {
        prof_kstat_t *st = &stats[si];
        char active_s[64], skip_s[64], fact_s[64], hit_s[64], cand_s[64];
        char a_s[64], b_s[64], c_s[64];
        prof_u128_decimal(st->active_visits, active_s);
        prof_u128_decimal(st->coprime_skips, skip_s);
        prof_u128_decimal(st->factorizations, fact_s);
        prof_u128_decimal(st->first_hits, hit_s);
        prof_u128_decimal(st->c_candidates, cand_s);
        prof_u128_decimal(st->spectrum_hits[0], a_s);
        prof_u128_decimal(st->spectrum_hits[1], b_s);
        prof_u128_decimal(st->spectrum_hits[2], c_s);
        uint64_t k = 3 + 4 * (uint64_t)si;
        if (si) putchar(',');
        printf("{\"k\":%" PRIu64 ",\"active_visits\":%s,\"c_candidates\":%s,"
               "\"coprime_skips\":%s,\"factorizations\":%s,\"first_hits\":%s,"
               "\"spectrum_hits\":{\"A\":%s,\"B\":%s,\"C\":%s}}",
               k, active_s, cand_s, skip_s, fact_s, hit_s, a_s, b_s, c_s);
    }
    puts("]}");

    free(stats);
    return 0;
}
