/*
 * cbx_runtime.c — signal-atomic runtime for cbx.kernel 0.1.0
 *
 * The arithmetic/search core lives in cbx.c. We include it as one
 * translation unit and replace only the operator loop so an entered target is
 * always completed before a stop signal is honored. This also adds finite
 * --iterations runs for reproducible censuses.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

static int lane_i_first_atomic(uint64_t p, uint64_t K, probe_t *o) {
    /* Once a target is entered, finish its I verdict even after SIGINT/TERM. */
    for (uint64_t k = 3; k <= K; k += 4) {
        if (gcd64(k, p) != 1) continue;
        if (p > UINT64_MAX - k) break;
        if ((p + k) % 4) continue;
        uint64_t C = (p + k) / 4;
        fac_t f;
        factor64(C, &f);
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

static probe_t probe_one_atomic(uint64_t p, const grade_t *g) {
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
    o.i_hit = lane_i_first_atomic(p, o.i_bound, &o);
    o.n_hit = lane_n_first(p, g->n_ell_max, &o.n_ell, &o.n_shift);
    o.l_hit = lane_l_first(p, g->l_max, &o.l_first, &o.l_modulus);
    o.production_letter = !(o.linear || o.fab || o.i_hit || o.n_hit || o.l_hit);
    return o;
}

static void sweep_batch_atomic(seed_t *s, uint64_t step, const char *run) {
    uint64_t lo = s->sweep;
    uint64_t hi = lo + step;
    if (hi < lo) hi = UINT64_MAX;
    uint64_t n = lo < 6 ? 7 : lo + 1;
    uint64_t last = lo;

    for (; n <= hi && !halt_flag; n++) {
        if (is_hard(n) && is_prime64(n)) {
            probe_t o = probe_one_atomic(n, &s->grade);
            record_probe(&o, &s->grade, run, "sweep", s, 0);
        }
        last = n;
        if (n == UINT64_MAX) break;
    }

    /* On interruption, resume immediately after the last fully processed n. */
    s->sweep = halt_flag ? last : hi;
    if (s->sweep == hi) s->windows++;
}

static void home_batch_atomic(seed_t *s, uint64_t span, const char *run) {
    uint64_t S0 = s->home_S < 5 ? 5 : s->home_S;
    if ((S0 & 3) != 1) S0 += (1u - (S0 & 3)) & 3;
    uint64_t S1 = S0 + span;
    if (S1 < S0) S1 = UINT64_MAX;
    if ((S1 & 3) != 1) S1 -= (S1 - 1) & 3;

    uint64_t S = S0;
    uint64_t next = S0;
    while (!halt_flag && S <= S1) {
        if (in_sigma1(S) && S > 4) {
            uint64_t p = S - 4;
            if (is_hard(p) && is_prime64(p) && p <= (UINT64_MAX - 1) / 4 &&
                in_sigma1(4 * p + 1)) {
                probe_t o = probe_one_atomic(p, &s->grade);
                record_probe(&o, &s->grade, run, "home", s, 0);
            }
        }
        next = S > UINT64_MAX - 4 ? UINT64_MAX : S + 4;
        if (S >= S1 || S > UINT64_MAX - 4) break;
        S += 4;
    }

    /* Strict next-S cursor; no skipped suffix after a stop signal. */
    s->home_S = next;
}

static void usage_runtime(void) {
    fprintf(stderr,
            "cbx.kernel %s — CB X-ray Kernel\n"
            "  cbx go [--run NAME] [--step N] [--iterations N] [--random]\n"
            "         [--sweep-only|--home-only]\n"
            "         [--fab-max F] [--i-max K] [--n-ell-max E] [--l-max A]\n"
            "         [--k-max K] [--k-policy fixed|log|log2|spectrum-log]\n"
            "         [--policy-scale C]\n"
            "  cbx probe N [grade options]\n"
            "  cbx solve N [grade options]\n"
            "  cbx status [--run NAME]\n"
            "  cbx self-test\n"
            "An entered target is completed atomically before SIGINT/SIGTERM stops the run.\n"
            "Grades are immutable inside an existing named run.\n",
            VERSION);
}

int main(int argc, char **argv) {
    resolve_root();
    signal(SIGINT, on_stop);
    signal(SIGTERM, on_stop);
    rng_state ^= (uint64_t)time(NULL) ^ ((uint64_t)getpid() << 32);

    const char *cmd = "go", *run = "default";
    uint64_t arg = 0, step = DEFAULT_STEP, max_iterations = 0;
    int randomize = 0, sweep = 1, home = 1;
    grade_t cli = default_grade();
    int grade_touched = 0;

    int i = 1;
    if (argc > 1 && argv[1][0] != '-') {
        cmd = argv[1];
        i = 2;
        if ((!strcmp(cmd, "probe") || !strcmp(cmd, "solve")) && i < argc && argv[i][0] != '-')
            arg = strtoull(argv[i++], NULL, 10);
    }
    for (; i < argc; i++) {
        if (!strcmp(argv[i], "--run") && i + 1 < argc) run = argv[++i];
        else if (!strcmp(argv[i], "--step") && i + 1 < argc) step = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--iterations") && i + 1 < argc) max_iterations = strtoull(argv[++i], NULL, 10);
        else if (!strcmp(argv[i], "--random")) randomize = 1;
        else if (!strcmp(argv[i], "--sweep-only")) { sweep = 1; home = 0; }
        else if (!strcmp(argv[i], "--home-only")) { sweep = 0; home = 1; }
        else if (!strcmp(argv[i], "--fab-max") && i + 1 < argc) { cli.fab_max = (unsigned)strtoul(argv[++i], NULL, 10); grade_touched = 1; }
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) { cli.i_max = strtoull(argv[++i], NULL, 10); grade_touched = 1; }
        else if (!strcmp(argv[i], "--n-ell-max") && i + 1 < argc) { cli.n_ell_max = strtoull(argv[++i], NULL, 10); grade_touched = 1; }
        else if (!strcmp(argv[i], "--l-max") && i + 1 < argc) { cli.l_max = strtoull(argv[++i], NULL, 10); grade_touched = 1; }
        else if (!strcmp(argv[i], "--k-max") && i + 1 < argc) { uint64_t k = strtoull(argv[++i], NULL, 10); cli.i_max = k; cli.l_max = k; grade_touched = 1; }
        else if (!strcmp(argv[i], "--k-policy") && i + 1 < argc) { if (!parse_policy(argv[++i], &cli.policy)) die("unknown k policy"); grade_touched = 1; }
        else if (!strcmp(argv[i], "--policy-scale") && i + 1 < argc) { cli.policy_scale = strtod(argv[++i], NULL); grade_touched = 1; }
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { usage_runtime(); return 0; }
        else { usage_runtime(); return 2; }
    }

    if (!valid_run(run)) die("run name may contain only letters, digits, - and _");
    if (!cli.fab_max || cli.fab_max > 64) die("fab-max must be 1..64");
    if (cli.i_max < 3 || !cli.n_ell_max || !cli.l_max || cli.policy_scale <= 0) die("invalid grade");

    if (!strcmp(cmd, "self-test")) return self_test();

    if (!strcmp(cmd, "probe") || !strcmp(cmd, "solve")) {
        if (arg < 2) die("probe/solve requires n >= 2");
        grade_t pg = cli;
        if (!grade_touched) {
            int pex = 0;
            seed_t ps = load_seed(run, &pex);
            if (pex) pg = ps.grade;
        }
        probe_t o = probe_one_atomic(arg, &pg);
        print_probe_json(stdout, &o, &pg, "probe", run);
        return 0;
    }

    if (!strcmp(cmd, "status")) {
        int ex = 0;
        seed_t s = load_seed(run, &ex);
        if (!ex) {
            printf("{\"kernel\":\"cbx.kernel\",\"run\":\"%s\",\"exists\":false}\n", run);
            return 0;
        }
        printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"run\":\"%s\","
               "\"sweep\":%" PRIu64 ",\"home_S\":%" PRIu64 ",\"observations\":%" PRIu64
               ",\"unique_letters\":%" PRIu64 ",\"fab_max\":%u,\"i_max\":%" PRIu64
               ",\"n_ell_max\":%" PRIu64 ",\"l_max\":%" PRIu64 ",\"policy\":\"%s\"}\n",
               VERSION, run, s.sweep, s.home_S, s.observations, s.unique_letters,
               s.grade.fab_max, s.grade.i_max, s.grade.n_ell_max, s.grade.l_max,
               policy_name(s.grade.policy));
        return 0;
    }

    if (strcmp(cmd, "go") && strcmp(cmd, "continue")) { usage_runtime(); return 2; }

    int ex = 0;
    seed_t s = load_seed(run, &ex);
    if (ex) {
        if (grade_touched && !same_grade(&s.grade, &cli))
            die("grade mismatch for existing run '%s'; use a new --run name", run);
    } else {
        s = default_seed(&cli);
        if (randomize) s.sweep = random_start();
        save_seed(run, &s);
    }
    if (!step) step = DEFAULT_STEP;

    fprintf(stderr,
            "cbx: run=%s sweep=%s home=%s grade=(F=%u,I=%" PRIu64 ",N=%" PRIu64
            ",L=%" PRIu64 ",policy=%s)\n",
            run, sweep ? "on" : "off", home ? "on" : "off", s.grade.fab_max,
            s.grade.i_max, s.grade.n_ell_max, s.grade.l_max, policy_name(s.grade.policy));

    uint64_t iterations = 0;
    while (!halt_flag) {
        if (sweep) sweep_batch_atomic(&s, step, run);
        if (home && !halt_flag) home_batch_atomic(&s, step, run);
        save_seed(run, &s);
        iterations++;
        if ((s.windows % 20) == 0 || halt_flag)
            fprintf(stderr, "cbx: sweep=%" PRIu64 " home_S=%" PRIu64
                            " observations=%" PRIu64 " letters=%" PRIu64 "\n",
                    s.sweep, s.home_S, s.observations, s.unique_letters);
        if (max_iterations && iterations >= max_iterations) break;
        if ((!sweep || s.sweep == UINT64_MAX) && (!home || s.home_S == UINT64_MAX)) break;
    }
    save_seed(run, &s);
    return 0;
}
