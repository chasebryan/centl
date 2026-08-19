/*
 * cbx_standalone_i.c — exact finite standalone Lane-I layer profiler.
 *
 * Unlike cbx_profile_i.c, which profiles the ordered survivor frontier, this
 * engine evaluates every admissible shift k against the full finite
 * Mordell-hard prime universe independently. It measures intrinsic finite
 * layer strength without allowing smaller shifts to remove targets first.
 *
 * This is deliberately a research profiler. A standalone hit at k does not
 * imply k is a minimal first-hit layer for that target, and a finite zero-hit
 * layer is not a universal redundancy theorem.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

typedef unsigned __int128 stand_u128;

static const uint64_t STAND_HARD[6] = {1, 121, 169, 289, 361, 529};

typedef struct {
    uint64_t p;
    int spectrum;
} stand_target_t;

typedef struct {
    stand_u128 target_visits;
    stand_u128 coprime_skips;
    stand_u128 factorizations;
    stand_u128 hits;
    stand_u128 spectrum_hits[3];
} stand_kstat_t;

static uint64_t stand_parse_u64(const char *name, const char *text) {
    errno = 0;
    char *end = NULL;
    unsigned long long v = strtoull(text, &end, 10);
    if (errno || !end || *end) die("invalid %s: %s", name, text);
    return (uint64_t)v;
}

static uint64_t stand_first_congruent(uint64_t lo, uint64_t mod, uint64_t residue) {
    uint64_t rem = lo % mod;
    uint64_t add = (residue + mod - rem) % mod;
    if (lo > UINT64_MAX - add) return UINT64_MAX;
    return lo + add;
}

static void stand_u128_decimal(stand_u128 x, char out[64]) {
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

static int cmp_stand_target(const void *aa, const void *bb) {
    const stand_target_t *a = aa;
    const stand_target_t *b = bb;
    return a->p < b->p ? -1 : a->p > b->p ? 1 : 0;
}

static void stand_usage(void) {
    fprintf(stderr,
            "cbx-standalone-i — exact finite standalone Lane-I layer profile\n"
            "  cbx-standalone-i --hi X [--lo L] [--i-max K] [--segment N]\n"
            "                   [--sets FILE]\n\n"
            "Every admissible k is evaluated against every hard prime independently.\n"
            "--sets writes one exact hit relation per line as k<TAB>p.\n");
}

int main(int argc, char **argv) {
    uint64_t lo = 2;
    uint64_t hi = 0;
    uint64_t K = DEFAULT_I_MAX;
    uint64_t segment = 1000000;
    const char *sets_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--lo") && i + 1 < argc) lo = stand_parse_u64("lo", argv[++i]);
        else if (!strcmp(argv[i], "--hi") && i + 1 < argc) hi = stand_parse_u64("hi", argv[++i]);
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) K = stand_parse_u64("i-max", argv[++i]);
        else if (!strcmp(argv[i], "--segment") && i + 1 < argc) segment = stand_parse_u64("segment", argv[++i]);
        else if (!strcmp(argv[i], "--sets") && i + 1 < argc) sets_path = argv[++i];
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { stand_usage(); return 0; }
        else { stand_usage(); return 2; }
    }

    if (hi < 2 || hi < lo) die("--hi must be >= max(2,--lo)");
    if (K < 3) die("--i-max must be >= 3");
    if (!segment || segment > 100000000ULL) die("--segment must be in 1..100000000");

    FILE *sets = NULL;
    if (sets_path) {
        sets = fopen(sets_path, "w");
        if (!sets) die("cannot open standalone hit-set output: %s", strerror(errno));
    }

    uint64_t nshifts64 = (K - 3) / 4 + 1;
    if (nshifts64 > SIZE_MAX / sizeof(stand_kstat_t)) die("too many standalone shifts");
    size_t nshifts = (size_t)nshifts64;
    stand_kstat_t *stats = calloc(nshifts, sizeof(*stats));
    if (!stats) die("standalone profile allocation failed");

    stand_u128 hard_total = 0;
    stand_u128 set_relations = 0;

    for (uint64_t seg_lo = lo;;) {
        stand_u128 proposed = (stand_u128)seg_lo + segment - 1;
        uint64_t seg_hi = proposed > hi ? hi : (uint64_t)proposed;

        size_t cap = 256, n = 0;
        stand_target_t *targets = malloc(cap * sizeof(*targets));
        if (!targets) die("standalone target allocation failed");

        for (size_t r = 0; r < 6; r++) {
            uint64_t p = stand_first_congruent(seg_lo, 840, STAND_HARD[r]);
            if (p == UINT64_MAX) continue;
            while (p <= seg_hi) {
                if (p >= 2 && is_prime64(p)) {
                    if (n == cap) {
                        if (cap > SIZE_MAX / 2 / sizeof(*targets)) die("standalone target overflow");
                        cap *= 2;
                        stand_target_t *tmp = realloc(targets, cap * sizeof(*targets));
                        if (!tmp) die("standalone target allocation failed");
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
        qsort(targets, n, sizeof(*targets), cmp_stand_target);

        for (size_t si = 0; si < nshifts; si++) {
            uint64_t k = 3 + 4 * (uint64_t)si;
            stand_kstat_t *st = &stats[si];
            st->target_visits += n;

            for (size_t j = 0; j < n; j++) {
                uint64_t p = targets[j].p;
                if (gcd64(k, p) != 1) {
                    st->coprime_skips++;
                    continue;
                }
                if (p > UINT64_MAX - k) continue;
                uint64_t C = (p + k) / 4;
                fac_t f;
                st->factorizations++;
                factor64(C, &f);
                if (delta_zero(&f, C, k)) {
                    st->hits++;
                    set_relations++;
                    if (targets[j].spectrum >= 0 && targets[j].spectrum < 3)
                        st->spectrum_hits[targets[j].spectrum]++;
                    if (sets && fprintf(sets, "%" PRIu64 "\t%" PRIu64 "\n", k, p) < 0)
                        die("cannot write standalone hit-set relation");
                }
            }
        }

        free(targets);
        if (seg_hi == hi || seg_hi == UINT64_MAX) break;
        seg_lo = seg_hi + 1;
    }

    if (sets) {
        if (fflush(sets) != 0 || fsync(fileno(sets)) != 0)
            die("cannot flush standalone hit-set output");
        fclose(sets);
    }

    char hard_s[64], relation_s[64];
    stand_u128_decimal(hard_total, hard_s);
    stand_u128_decimal(set_relations, relation_s);
    printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\","
           "\"mode\":\"standalone-I\",\"lo\":%" PRIu64 ",\"hi\":%" PRIu64
           ",\"i_max\":%" PRIu64 ",\"segment\":%" PRIu64
           ",\"hard_primes\":%s,\"sets_recorded\":%s,\"set_relations\":%s,\"shifts\":[",
           VERSION, lo, hi, K, segment, hard_s, sets_path ? "true" : "false", relation_s);

    for (size_t si = 0; si < nshifts; si++) {
        stand_kstat_t *st = &stats[si];
        char visit_s[64], skip_s[64], fact_s[64], hit_s[64];
        char a_s[64], b_s[64], c_s[64];
        stand_u128_decimal(st->target_visits, visit_s);
        stand_u128_decimal(st->coprime_skips, skip_s);
        stand_u128_decimal(st->factorizations, fact_s);
        stand_u128_decimal(st->hits, hit_s);
        stand_u128_decimal(st->spectrum_hits[0], a_s);
        stand_u128_decimal(st->spectrum_hits[1], b_s);
        stand_u128_decimal(st->spectrum_hits[2], c_s);
        uint64_t k = 3 + 4 * (uint64_t)si;
        if (si) putchar(',');
        printf("{\"k\":%" PRIu64 ",\"target_visits\":%s,\"coprime_skips\":%s,"
               "\"factorizations\":%s,\"hits\":%s,"
               "\"spectrum_hits\":{\"A\":%s,\"B\":%s,\"C\":%s}}",
               k, visit_s, skip_s, fact_s, hit_s, a_s, b_s, c_s);
    }
    puts("]}");

    free(stats);
    return 0;
}
