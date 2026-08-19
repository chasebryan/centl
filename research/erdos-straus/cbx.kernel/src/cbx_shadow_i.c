/*
 * cbx_shadow_i.c — exact finite earlier-layer cover search through depth 4.
 *
 * Input is the exact standalone relation file produced by
 *
 *     cbx-standalone-i --sets FILE
 *
 * with lines k<TAB>p. For each layer T_k already contained in the union of
 * earlier layers, this solver searches for an exact cover by at most D
 * earlier layers (D<=4). A negative result at D=4 is an exact finite lower
 * bound of five earlier layers. It is not a universal shadow theorem.
 */
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    uint32_t k;
    uint64_t p;
} rel_t;

typedef struct {
    uint64_t *mask;
    uint32_t k;
} layer_t;

typedef struct {
    const layer_t *layers;
    size_t n_layers;
    size_t n_words;
    size_t target_index;
    int max_depth;
    uint32_t solution[4];
    uint64_t *stack;
} search_t;

static void die(const char *msg) {
    fprintf(stderr, "cbx-shadow-i: %s\n", msg);
    exit(2);
}

static int cmp_u64(const void *aa, const void *bb) {
    uint64_t a = *(const uint64_t *)aa;
    uint64_t b = *(const uint64_t *)bb;
    return a < b ? -1 : a > b ? 1 : 0;
}

static int cmp_rel(const void *aa, const void *bb) {
    const rel_t *a = aa, *b = bb;
    if (a->k != b->k) return a->k < b->k ? -1 : 1;
    return a->p < b->p ? -1 : a->p > b->p ? 1 : 0;
}

static size_t find_u64(const uint64_t *xs, size_t n, uint64_t x) {
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (xs[mid] < x) lo = mid + 1;
        else hi = mid;
    }
    if (lo >= n || xs[lo] != x) die("internal prime-index failure");
    return lo;
}

static uint64_t pop_words(const uint64_t *a, size_t n) {
    uint64_t s = 0;
    for (size_t i = 0; i < n; i++) s += (uint64_t)__builtin_popcountll(a[i]);
    return s;
}

static int empty_words(const uint64_t *a, size_t n) {
    for (size_t i = 0; i < n; i++) if (a[i]) return 0;
    return 1;
}

static int subset_words(const uint64_t *a, const uint64_t *b, size_t n) {
    for (size_t i = 0; i < n; i++) if (a[i] & ~b[i]) return 0;
    return 1;
}

static uint64_t gain_words(const uint64_t *rem, const uint64_t *m, size_t n) {
    uint64_t s = 0;
    for (size_t i = 0; i < n; i++) s += (uint64_t)__builtin_popcountll(rem[i] & m[i]);
    return s;
}

static size_t choose_rare_bit(const search_t *s, const uint64_t *rem,
                              size_t *holders, size_t *n_holders) {
    size_t best_bit = SIZE_MAX;
    size_t best_count = SIZE_MAX;
    size_t target = s->target_index;

    for (size_t wi = 0; wi < s->n_words; wi++) {
        uint64_t w = rem[wi];
        while (w) {
            unsigned b = (unsigned)__builtin_ctzll(w);
            size_t bit = wi * 64 + b;
            size_t count = 0;
            for (size_t li = 0; li < target; li++) {
                if ((s->layers[li].mask[wi] >> b) & 1ULL) count++;
            }
            if (count == 0) {
                *n_holders = 0;
                return bit;
            }
            if (count < best_count) {
                best_count = count;
                best_bit = bit;
                if (count == 1) goto chosen;
            }
            w &= w - 1;
        }
    }

chosen:
    *n_holders = 0;
    if (best_bit == SIZE_MAX) return best_bit;
    size_t wi = best_bit / 64;
    unsigned b = (unsigned)(best_bit % 64);
    for (size_t li = 0; li < target; li++) {
        if ((s->layers[li].mask[wi] >> b) & 1ULL) holders[(*n_holders)++] = li;
    }
    return best_bit;
}

typedef struct { size_t li; uint64_t gain; } branch_t;

static int cmp_branch_desc(const void *aa, const void *bb) {
    const branch_t *a = aa, *b = bb;
    if (a->gain != b->gain) return a->gain > b->gain ? -1 : 1;
    return a->li < b->li ? -1 : a->li > b->li ? 1 : 0;
}

static int dfs_cover(search_t *s, int level, int depth_left) {
    uint64_t *rem = s->stack + (size_t)level * s->n_words;
    if (empty_words(rem, s->n_words)) return 1;
    if (depth_left == 0) return 0;

    uint64_t rem_count = pop_words(rem, s->n_words);
    uint64_t gains[100];
    size_t gn = 0;
    for (size_t li = 0; li < s->target_index; li++) {
        uint64_t g = gain_words(rem, s->layers[li].mask, s->n_words);
        if (g) gains[gn++] = g;
    }
    if (!gn) return 0;
    for (size_t i = 0; i < gn; i++) {
        for (size_t j = i + 1; j < gn; j++) {
            if (gains[j] > gains[i]) {
                uint64_t t = gains[i]; gains[i] = gains[j]; gains[j] = t;
            }
        }
    }
    uint64_t optimistic = 0;
    for (int i = 0; i < depth_left && (size_t)i < gn; i++) optimistic += gains[i];
    if (optimistic < rem_count) return 0;

    size_t holders[100], n_holders = 0;
    choose_rare_bit(s, rem, holders, &n_holders);
    if (!n_holders) return 0;

    branch_t branches[100];
    for (size_t i = 0; i < n_holders; i++) {
        branches[i].li = holders[i];
        branches[i].gain = gain_words(rem, s->layers[holders[i]].mask, s->n_words);
    }
    qsort(branches, n_holders, sizeof(branches[0]), cmp_branch_desc);

    uint64_t *next = s->stack + (size_t)(level + 1) * s->n_words;
    for (size_t bi = 0; bi < n_holders; bi++) {
        size_t li = branches[bi].li;
        const uint64_t *m = s->layers[li].mask;
        for (size_t wi = 0; wi < s->n_words; wi++) next[wi] = rem[wi] & ~m[wi];
        s->solution[level] = s->layers[li].k;
        if (dfs_cover(s, level + 1, depth_left - 1)) return 1;
    }
    return 0;
}

static int find_cover(search_t *s, int depth) {
    const uint64_t *target = s->layers[s->target_index].mask;
    memcpy(s->stack, target, s->n_words * sizeof(uint64_t));
    return dfs_cover(s, 0, depth);
}

static int parse_depth(const char *s) {
    errno = 0;
    char *end = NULL;
    long v = strtol(s, &end, 10);
    if (errno || !end || *end || v < 1 || v > 4) die("--max-depth must be 1..4");
    return (int)v;
}

static void usage(void) {
    fprintf(stderr,
            "cbx-shadow-i --sets FILE [--max-depth 4]\n"
            "Exact finite earlier-layer cover search through depth four.\n");
}

int main(int argc, char **argv) {
    const char *path = NULL;
    int max_depth = 4;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--sets") && i + 1 < argc) path = argv[++i];
        else if (!strcmp(argv[i], "--max-depth") && i + 1 < argc) max_depth = parse_depth(argv[++i]);
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { usage(); return 0; }
        else { usage(); return 2; }
    }
    if (!path) die("--sets FILE is required");

    FILE *f = fopen(path, "r");
    if (!f) die("cannot open relation file");

    size_t cap = 1 << 16, nrel = 0, pcap = 1 << 16, np = 0;
    rel_t *rels = malloc(cap * sizeof(*rels));
    uint64_t *primes = malloc(pcap * sizeof(*primes));
    if (!rels || !primes) die("allocation failure");

    uint32_t min_k = UINT32_MAX, max_k = 0;
    uint64_t p;
    unsigned long ktmp;
    while (fscanf(f, "%lu\t%" SCNu64, &ktmp, &p) == 2) {
        if (ktmp > UINT32_MAX || ktmp < 3 || (ktmp & 3) != 3 || p < 2) die("invalid relation");
        uint32_t k = (uint32_t)ktmp;
        if (nrel == cap) {
            cap *= 2;
            rel_t *tmp = realloc(rels, cap * sizeof(*rels));
            if (!tmp) die("relation allocation failure");
            rels = tmp;
        }
        if (np == pcap) {
            pcap *= 2;
            uint64_t *tmp = realloc(primes, pcap * sizeof(*primes));
            if (!tmp) die("prime allocation failure");
            primes = tmp;
        }
        rels[nrel++] = (rel_t){k, p};
        primes[np++] = p;
        if (k < min_k) min_k = k;
        if (k > max_k) max_k = k;
    }
    if (ferror(f)) die("relation read failure");
    fclose(f);
    if (!nrel) die("empty relation file");

    qsort(rels, nrel, sizeof(*rels), cmp_rel);
    for (size_t i = 1; i < nrel; i++) {
        if (rels[i].k == rels[i-1].k && rels[i].p == rels[i-1].p) die("duplicate relation");
    }

    qsort(primes, np, sizeof(*primes), cmp_u64);
    size_t nunique = 0;
    for (size_t i = 0; i < np; i++) {
        if (!nunique || primes[i] != primes[nunique-1]) primes[nunique++] = primes[i];
    }

    if ((max_k - min_k) % 4) die("non-contiguous admissible layer range");
    size_t n_layers = (size_t)((max_k - min_k) / 4 + 1);
    if (n_layers > 100) die("current exact solver supports at most 100 layers");
    size_t n_words = (nunique + 63) / 64;
    layer_t *layers = calloc(n_layers, sizeof(*layers));
    uint64_t *all_masks = calloc(n_layers * n_words, sizeof(uint64_t));
    if (!layers || !all_masks) die("mask allocation failure");
    for (size_t li = 0; li < n_layers; li++) {
        layers[li].k = min_k + 4 * (uint32_t)li;
        layers[li].mask = all_masks + li * n_words;
    }
    for (size_t ri = 0; ri < nrel; ri++) {
        size_t li = (rels[ri].k - min_k) / 4;
        if (li >= n_layers || layers[li].k != rels[ri].k) die("layer index failure");
        size_t pi = find_u64(primes, nunique, rels[ri].p);
        layers[li].mask[pi / 64] |= 1ULL << (pi % 64);
    }
    for (size_t li = 0; li < n_layers; li++) {
        if (empty_words(layers[li].mask, n_words)) die("missing layer relations");
    }

    uint64_t *prior = calloc(n_words, sizeof(uint64_t));
    uint64_t *stack = calloc((size_t)(max_depth + 1) * n_words, sizeof(uint64_t));
    if (!prior || !stack) die("search allocation failure");

    uint64_t shadowed = 0, no_cover = 0, above107 = 0, above107_no_cover = 0;
    uint64_t counts[5] = {0,0,0,0,0};
    int first_json = 1;
    printf("{\"kernel\":\"cbx.kernel\",\"mode\":\"shadow-I\","
           "\"max_depth\":%d,\"layers\":%zu,\"k_min\":%u,\"k_max\":%u,"
           "\"unique_primes_hit_by_any_layer\":%zu,\"relation_rows\":%zu,\"rows\":[",
           max_depth, n_layers, min_k, max_k, nunique, nrel);

    for (size_t li = 0; li < n_layers; li++) {
        const uint64_t *t = layers[li].mask;
        int full_shadow = li > 0 && subset_words(t, prior, n_words);
        int depth_found = 0;
        search_t s = {layers, n_layers, n_words, li, max_depth, {0,0,0,0}, stack};
        if (full_shadow) {
            shadowed++;
            if (layers[li].k > 107) above107++;
            for (int d = 1; d <= max_depth; d++) {
                if (find_cover(&s, d)) { depth_found = d; counts[d]++; break; }
            }
            if (!depth_found) {
                no_cover++;
                if (layers[li].k > 107) above107_no_cover++;
            }
        }

        if (!first_json) putchar(',');
        first_json = 0;
        printf("{\"k\":%u,\"hits\":%" PRIu64 ",\"fully_shadowed_by_prior_union\":%s,"
               "\"exact_cover_size_if_le_%d\":",
               layers[li].k, pop_words(t, n_words), full_shadow ? "true" : "false", max_depth);
        if (depth_found) printf("%d", depth_found); else fputs("null", stdout);
        fputs(",\"cover\":[", stdout);
        for (int d = 0; d < depth_found; d++) {
            if (d) putchar(',');
            printf("%u", s.solution[d]);
        }
        printf("],\"finite_lower_bound\":%d}", depth_found ? depth_found : (full_shadow ? max_depth + 1 : 0));

        for (size_t wi = 0; wi < n_words; wi++) prior[wi] |= t[wi];
    }

    printf("],\"fully_shadowed_by_prior_union_layers\":%" PRIu64
           ",\"exact_cover_counts\":{\"size_1\":%" PRIu64 ",\"size_2\":%" PRIu64
           ",\"size_3\":%" PRIu64 ",\"size_4\":%" PRIu64 "},"
           "\"no_exact_cover_through_%d_layers\":%" PRIu64
           ",\"above_107\":{\"fully_shadowed_layers\":%" PRIu64
           ",\"no_exact_cover_through_%d_layers\":%" PRIu64 "},"
           "\"claim\":\"exact finite set-cover search only; negative depth-four result gives a finite lower bound of five, not a universal theorem\"}\n",
           shadowed, counts[1], counts[2], counts[3], counts[4], max_depth, no_cover,
           above107, max_depth, above107_no_cover);

    free(stack); free(prior); free(all_masks); free(layers); free(primes); free(rels);
    return 0;
}
