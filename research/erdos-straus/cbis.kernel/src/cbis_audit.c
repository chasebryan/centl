/*
 * cbis-audit — epistemic sidecar for cbis.kernel
 *
 * This deliberately does NOT participate in the W/I/N/L cover and does
 * not change ES-LETTER-v1 identity.  Its job is to keep López Type A/B
 * completeness as a conjecture rather than a hidden kernel axiom.
 *
 * Reuse the exact cbis implementation in one translation unit so the
 * audit sees the same W/I/N/L predicates as the running kernel.
 */
#define main cbis_embedded_main
#include "cbis.c"
#undef main

typedef struct {
    int found;
    uint64_t k;
    uint64_t m;
    uint64_t d;
    uint64_t n;
    char type;
} ab_hit_t;

static uint64_t neg_mod(uint64_t a, uint64_t m) {
    uint64_t r = a % m;
    return r ? m - r : 0;
}

/*
 * Full Type A/B scan through K.
 *
 * Important difference from cbis lane L: lane L intentionally keeps only
 * López prime-modulus traps.  This audit checks every m = 4k-1, prime or
 * composite, so "A/B unseen through K" means exactly that bounded claim.
 */
static ab_hit_t full_ab_through(uint64_t p, uint64_t K) {
    ab_hit_t hit;
    memset(&hit, 0, sizeof hit);

    for (uint64_t k = 1; k <= K; k++) {
        if (k > UINT64_MAX / 4) break;
        uint64_t m = 4 * k - 1;
        uint64_t r = p % m;

        for (uint64_t e = 1; e <= k / e; e++) {
            if (k % e) continue;
            uint64_t ds[2] = {e, k / e};
            int nd = (e == k / e) ? 1 : 2;

            for (int i = 0; i < nd; i++) {
                uint64_t s = ds[i];

                /* Type B: p == -n (mod 4dn-1), n=s, d=k/s. */
                if (r == neg_mod(s, m)) {
                    hit.found = 1;
                    hit.k = k;
                    hit.m = m;
                    hit.d = k / s;
                    hit.n = s;
                    hit.type = 'B';
                    return hit;
                }

                /* Type A: p == -4d (mod 4dn-1), d=s, n=k/s. */
                uint64_t four_d = (uint64_t)(((__uint128_t)4 * s) % m);
                if (r == neg_mod(four_d, m)) {
                    hit.found = 1;
                    hit.k = k;
                    hit.m = m;
                    hit.d = s;
                    hit.n = k / s;
                    hit.type = 'A';
                    return hit;
                }
            }
        }
    }
    return hit;
}

static const char *jbool(int v) { return v ? "true" : "false"; }

static void usage_audit(void) {
    fprintf(stderr,
            "cbis-audit — non-cover Type A/B assumption audit\n"
            "  cbis-audit N [--k-max K]\n"
            "\n"
            "Reports the current W/I/N/L predicates and independently scans\n"
            "all Type A/B layers through K, including composite moduli.\n"
            "It never writes letters or changes cbis.kernel state.\n");
}

int main(int argc, char **argv) {
    uint64_t p = 0;
    uint64_t K = DEFAULT_KMAX;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--k-max") && i + 1 < argc) {
            K = strtoull(argv[++i], NULL, 10);
        } else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            usage_audit();
            return 0;
        } else if (!p) {
            p = strtoull(argv[i], NULL, 10);
        } else {
            usage_audit();
            return 2;
        }
    }

    if (p < 2 || K == 0) {
        usage_audit();
        return 2;
    }

    resolve_root();
    build_sieve(1000003ull);

    int prime = is_prime64(p);
    int hard_prime = is_hard(p) && prime;
    int W = 0, I = 0, N = 0, L = 0;
    if (hard_prime) {
        W = in_window_set(p);
        I = in_signed_box_cover(p, K);
        N = in_nr_cover(p);
        L = in_lopez_cover(p, K);
    }

    ab_hit_t ab = full_ab_through(p, K);
    int current_letter = hard_prime && !(W || I || N || L);
    int ab_unseen = !ab.found;
    int cover_escape = hard_prime && ab_unseen && (W || I || N);

    const char *classification;
    if (!hard_prime)
        classification = "OUTSIDE_CBIS_HARD_PRIME_DOMAIN";
    else if (ab.found)
        classification = "AB_EXPLAINED_THROUGH_K";
    else if (cover_escape)
        classification = "AB_UNSEEN_THROUGH_K_NON_AB_COVER_HIT";
    else
        classification = "AB_UNSEEN_THROUGH_K_CURRENT_LETTER";

    printf("{\"kernel\":\"cbis-audit\",\"n\":%" PRIu64
           ",\"K\":%" PRIu64 ",\"prime\":%s,\"hard_prime\":%s,"
           "\"cover\":{\"W\":%s,\"I\":%s,\"N\":%s,\"L_prime_modulus\":%s},"
           "\"current_letter\":%s,\"full_type_ab\":{\"found\":%s",
           p, K, jbool(prime), jbool(hard_prime), jbool(W), jbool(I), jbool(N), jbool(L),
           jbool(current_letter), jbool(ab.found));

    if (ab.found) {
        printf(",\"type\":\"%c\",\"k\":%" PRIu64 ",\"m\":%" PRIu64
               ",\"d\":%" PRIu64 ",\"n_parameter\":%" PRIu64,
               ab.type, ab.k, ab.m, ab.d, ab.n);
    }

    printf("},\"ab_unseen_through_K\":%s,\"cover_escape_candidate\":%s,"
           "\"classification\":\"%s\","
           "\"type_ab_falsified\":false,"
           "\"note\":\"bounded audit only; failure through K is not proof of no Type A/B witness\"}\n",
           jbool(ab_unseen), jbool(cover_escape), classification);

    return 0;
}
