/*
 * cbx_runtime.c — signal-atomic runtime for cbx.kernel 0.1.0
 *
 * The arithmetic/search core lives in cbx.c. We include it as one
 * translation unit and replace the operator loop so an entered target is
 * always completed before a stop signal is honored. This runtime also adds
 * finite --iterations runs, same-run writer locking, crash-tail repair,
 * exact grade serialization, and uint64-safe external-NR Jacobi evaluation.
 */
#define main cbx_core_main
#include "cbx.c"
#undef main

#include <dirent.h>
#include <fcntl.h>
#include <sys/file.h>

static void resolve_root_portable(const char *argv0) {
    char exe[768];
    ssize_t m = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (m > 0) {
        exe[m] = 0;
    } else {
        if (!argv0 || !realpath(argv0, exe)) snprintf(exe, sizeof exe, "%s", argv0 ? argv0 : ".");
    }
    char *slash = strrchr(exe, '/');
    if (slash) {
        *slash = 0;
        snprintf(root_dir, sizeof root_dir, "%s", exe);
    } else {
        snprintf(root_dir, sizeof root_dir, ".");
    }
    char p[900];
    snprintf(p, sizeof p, "%s/state", root_dir); mkdir(p, 0755);
    snprintf(p, sizeof p, "%s/observations", root_dir); mkdir(p, 0755);
    snprintf(p, sizeof p, "%s/letters", root_dir); mkdir(p, 0755);
}

static uint64_t parse_u64_value(const char *name, const char *text) {
    errno = 0;
    char *end = NULL;
    unsigned long long v = strtoull(text, &end, 10);
    if (errno || !end || *end) die("invalid %s: %s", name, text);
    return (uint64_t)v;
}

static double parse_scale_value(const char *text) {
    errno = 0;
    char *end = NULL;
    double v = strtod(text, &end);
    if (errno || !end || *end || !isfinite(v) || v <= 0.0) die("invalid policy-scale: %s", text);
    return v;
}

static seed_t load_seed_runtime(const char *run, int *exists) {
    grade_t dg = default_grade();
    seed_t s = default_seed(&dg);
    char path[900], obs[900], grades[900];
    paths_for(run, path, obs, grades);
    FILE *f = fopen(path, "r");
    if (!f) {
        *exists = 0;
        return s;
    }
    *exists = 1;
    char line[256];
    while (fgets(line, sizeof line, f)) {
        uint64_t v;
        unsigned u;
        double d;
        char pol[64];
        if (sscanf(line, "sweep=%" SCNu64, &v) == 1) s.sweep = v;
        else if (sscanf(line, "home_S=%" SCNu64, &v) == 1) s.home_S = v;
        else if (sscanf(line, "observations=%" SCNu64, &v) == 1) s.observations = v;
        else if (sscanf(line, "unique_letters=%" SCNu64, &v) == 1) s.unique_letters = v;
        else if (sscanf(line, "windows=%" SCNu64, &v) == 1) s.windows = v;
        else if (sscanf(line, "fab_max=%u", &u) == 1) s.grade.fab_max = u;
        else if (sscanf(line, "i_max=%" SCNu64, &v) == 1) s.grade.i_max = v;
        else if (sscanf(line, "n_ell_max=%" SCNu64, &v) == 1) s.grade.n_ell_max = v;
        else if (sscanf(line, "l_max=%" SCNu64, &v) == 1) s.grade.l_max = v;
        else if (sscanf(line, "policy=%63s", pol) == 1) {
            policy_t p;
            if (parse_policy(pol, &p)) s.grade.policy = p;
        } else if (sscanf(line, "policy_scale=%lf", &d) == 1) {
            s.grade.policy_scale = d;
        }
    }
    fclose(f);
    if (s.home_S != UINT64_MAX && (s.home_S & 3) != 1) {
        uint64_t add = (1u - (s.home_S & 3)) & 3;
        s.home_S = s.home_S > UINT64_MAX - add ? UINT64_MAX : s.home_S + add;
    }
    return s;
}

static int acquire_run_lock(const char *run) {
    char path[900];
    snprintf(path, sizeof path, "%s/state/%s.lock", root_dir, run);
    int fd = open(path, O_RDWR | O_CREAT, 0644);
    if (fd < 0) die("cannot open run lock: %s", strerror(errno));
    if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
        close(fd);
        die("run '%s' already has an active writer; use another --run name", run);
    }
    if (ftruncate(fd, 0) == 0) {
        dprintf(fd, "%ld\n", (long)getpid());
        fsync(fd);
    }
    return fd;
}

static void release_run_lock(int fd) {
    if (fd < 0) return;
    flock(fd, LOCK_UN);
    close(fd);
}

static uint64_t count_run_letter_markers(const char *run) {
    char dirpath[900], prefix[256];
    snprintf(dirpath, sizeof dirpath, "%s/state", root_dir);
    snprintf(prefix, sizeof prefix, "%s.L-", run);
    DIR *d = opendir(dirpath);
    if (!d) return 0;
    uint64_t n = 0;
    struct dirent *de;
    size_t plen = strlen(prefix);
    while ((de = readdir(d)) != NULL)
        if (!strncmp(de->d_name, prefix, plen)) n++;
    closedir(d);
    return n;
}

static void repair_observation_tail(const char *run) {
    char sp[900], op[900], gp[900];
    paths_for(run, sp, op, gp);
    int fd = open(op, O_RDWR);
    if (fd < 0) {
        if (errno == ENOENT) return;
        die("cannot inspect observation stream: %s", strerror(errno));
    }
    off_t end = lseek(fd, 0, SEEK_END);
    if (end <= 0) {
        close(fd);
        return;
    }
    char c;
    if (pread(fd, &c, 1, end - 1) == 1 && c == '\n') {
        close(fd);
        return;
    }
    off_t pos = end;
    while (pos > 0) {
        pos--;
        if (pread(fd, &c, 1, pos) != 1) break;
        if (c == '\n') {
            if (ftruncate(fd, pos + 1) != 0) die("cannot trim partial observation tail");
            fsync(fd);
            close(fd);
            return;
        }
    }
    if (ftruncate(fd, 0) != 0) die("cannot reset partial observation stream");
    fsync(fd);
    close(fd);
}

static int jacobi_u64(uint64_t a, uint64_t n) {
    if (!n || !(n & 1)) return 0;
    a %= n;
    int s = 1;
    while (a) {
        while ((a & 1) == 0) {
            a >>= 1;
            uint64_t m = n & 7;
            if (m == 3 || m == 5) s = -s;
        }
        uint64_t t = a;
        a = n;
        n = t;
        if ((a & 3) == 3 && (n & 3) == 3) s = -s;
        a %= n;
    }
    return n == 1 ? s : 0;
}

static int lane_i_first_atomic(uint64_t p, uint64_t K, probe_t *o) {
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

static int lane_n_first_atomic(uint64_t p, uint64_t E, uint64_t *oell, uint64_t *oshift) {
    for (uint64_t ell = 11; ell <= E; ell += 2) {
        if (!is_prime64(ell) || ell == p) goto next_ell;
        if (jacobi_u64(ell, p) != -1) goto next_ell;
        if ((ell & 3) == 3 && gcd64(ell, p) == 1 && p <= UINT64_MAX - ell &&
            (p + ell) % 4 == 0) {
            uint64_t C = (p + ell) / 4;
            fac_t f;
            factor64(C, &f);
            if (delta_zero(&f, C, ell)) {
                if (oell) *oell = ell;
                if (oshift) *oshift = ell;
                return 1;
            }
        }
        if (ell <= UINT64_MAX / 4) {
            uint64_t m = 4 * ell;
            uint64_t k = (m - (p % m)) % m;
            if (k == 0) k = m;
            if (gcd64(k, p) == 1 && p <= UINT64_MAX - k && (p + k) % 4 == 0) {
                uint64_t C = (p + k) / 4;
                fac_t f;
                factor64(C, &f);
                if (delta_zero(&f, C, k)) {
                    if (oell) *oell = ell;
                    if (oshift) *oshift = k;
                    return 1;
                }
            }
        }
next_ell:
        if (ell > UINT64_MAX - 2) break;
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
    o.n_hit = lane_n_first_atomic(p, g->n_ell_max, &o.n_ell, &o.n_shift);
    o.l_hit = lane_l_first(p, g->l_max, &o.l_first, &o.l_modulus);
    o.production_letter = !(o.linear || o.fab || o.i_hit || o.n_hit || o.l_hit);
    return o;
}

static void print_probe_json_exact(FILE *f, const probe_t *o, const grade_t *g,
                                   const char *via, const char *run) {
    char lid[33] = "";
    if (o->production_letter) letter_id(o->n, lid);
    fprintf(f,
            "{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"run\":\"%s\","
            "\"via\":\"%s\",\"n\":%" PRIu64 ",\"hard\":%s,\"prime\":%s,\"spectrum\":",
            VERSION, run, via, o->n, o->hard ? "true" : "false", o->prime ? "true" : "false");
    if (o->spectrum >= 0) fprintf(f, "\"%s\"", SPEC_NAME[o->spectrum]);
    else fputs("null", f);
    fprintf(f,
            ",\"grade\":{\"fab_max\":%u,\"i_max\":%" PRIu64 ",\"i_realized\":%" PRIu64
            ",\"n_ell_max\":%" PRIu64 ",\"l_max\":%" PRIu64
            ",\"policy\":\"%s\",\"policy_scale\":%.17g}",
            g->fab_max, g->i_max, o->i_bound, g->n_ell_max, g->l_max,
            policy_name(g->policy), g->policy_scale);
    fprintf(f,
            ",\"W\":{\"linear\":%s,\"R\":%s,\"fab\":%s,\"fab_a\":%u,\"fab_b\":%u}",
            o->linear ? "true" : "false", o->in_R ? "true" : "false",
            o->fab ? "true" : "false", o->fab_a, o->fab_b);
    fprintf(f,
            ",\"I\":{\"hit\":%s,\"first_k\":%" PRIu64 ",\"omega\":%d,\"Omega\":%u,"
            "\"box_size\":%" PRIu64 "}",
            o->i_hit ? "true" : "false", o->i_first, o->i_omega, o->i_Omega, o->i_box_size);
    fprintf(f, ",\"N\":{\"hit\":%s,\"ell\":%" PRIu64 ",\"shift\":%" PRIu64 "}",
            o->n_hit ? "true" : "false", o->n_ell, o->n_shift);
    fprintf(f, ",\"L\":{\"hit\":%s,\"first_a\":%" PRIu64 ",\"modulus\":%" PRIu64 "}",
            o->l_hit ? "true" : "false", o->l_first, o->l_modulus);
    fprintf(f, ",\"production_letter\":%s", o->production_letter ? "true" : "false");
    if (o->production_letter) fprintf(f, ",\"letter_id\":\"L-%s\"", lid);
    fputs("}\n", f);
}

static int store_letter_once_exact(const probe_t *o, const grade_t *g,
                                   const char *run, const char *via) {
    char hex[33];
    letter_id(o->n, hex);
    char marker[900];
    snprintf(marker, sizeof marker, "%s/state/%s.L-%s", root_dir, run, hex);
    if (access(marker, F_OK) == 0) return 0;

    char letter_path[900];
    snprintf(letter_path, sizeof letter_path, "%s/letters/L-%s.md", root_dir, hex);
    int lfd = open(letter_path, O_WRONLY | O_CREAT | O_EXCL, 0644);
    if (lfd >= 0) {
        dprintf(lfd,
                "# LETTER — unsolved_after_search\n\n**Grade:** LETTER\n"
                "**Kernel identity:** ES-LETTER-v1\n**Letter id:** `L-%s`\n**n:** %" PRIu64
                "\n\nThis content-addressed identity denotes the unsolved-after-search event for this prime. "
                "Exact finite search grades are recorded separately in `GRADES.jsonl`.\n\n"
                "Erdős–Straus remains open. A finite letter is not a counterexample.\n",
                hex, o->n);
        fsync(lfd);
        close(lfd);
    } else if (errno != EEXIST) {
        die("cannot write letter: %s", strerror(errno));
    }

    char sp[900], op[900], gp[900];
    paths_for(run, sp, op, gp);
    int gfd = open(gp, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (gfd < 0) die("cannot append grade ledger: %s", strerror(errno));
    if (flock(gfd, LOCK_EX) != 0) die("cannot lock grade ledger");
    dprintf(gfd,
            "{\"letter_id\":\"L-%s\",\"n\":%" PRIu64 ",\"run\":\"%s\",\"via\":\"%s\","
            "\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"fab_max\":%u,"
            "\"i_max\":%" PRIu64 ",\"i_realized\":%" PRIu64 ",\"n_ell_max\":%" PRIu64
            ",\"l_max\":%" PRIu64 ",\"policy\":\"%s\",\"policy_scale\":%.17g}\n",
            hex, o->n, run, via, VERSION, g->fab_max, g->i_max, o->i_bound,
            g->n_ell_max, g->l_max, policy_name(g->policy), g->policy_scale);
    fsync(gfd);
    flock(gfd, LOCK_UN);
    close(gfd);

    int mfd = open(marker, O_WRONLY | O_CREAT | O_EXCL, 0644);
    if (mfd < 0) {
        if (errno == EEXIST) return 0;
        die("cannot write run letter marker: %s", strerror(errno));
    }
    dprintf(mfd, "%" PRIu64 "\n", o->n);
    fsync(mfd);
    close(mfd);
    return 1;
}

static void record_probe_runtime(const probe_t *o, const grade_t *g, const char *run,
                                 const char *via, seed_t *s, int print) {
    char sp[900], op[900], gp[900];
    paths_for(run, sp, op, gp);
    FILE *f = fopen(op, "a");
    if (!f) die("cannot append observations");
    print_probe_json_exact(f, o, g, via, run);
    fclose(f);
    s->observations++;
    if (o->production_letter && store_letter_once_exact(o, g, run, via)) s->unique_letters++;
    if (print) print_probe_json_exact(stdout, o, g, via, run);
}

static void sweep_batch_atomic(seed_t *s, uint64_t step, const char *run) {
    if (s->sweep == UINT64_MAX) return;
    uint64_t lo = s->sweep;
    uint64_t hi = lo + step;
    if (hi < lo) hi = UINT64_MAX;
    uint64_t n = lo < 6 ? 7 : lo + 1;
    uint64_t last = lo;

    for (; n <= hi && !halt_flag; n++) {
        if (is_hard(n) && is_prime64(n)) {
            probe_t o = probe_one_atomic(n, &s->grade);
            record_probe_runtime(&o, &s->grade, run, "sweep", s, 0);
        }
        last = n;
        if (n == UINT64_MAX) break;
    }

    s->sweep = halt_flag ? last : hi;
    if (s->sweep == hi) s->windows++;
}

static void home_batch_atomic(seed_t *s, uint64_t span, const char *run) {
    if (s->home_S == UINT64_MAX) return;
    uint64_t S0 = s->home_S < 5 ? 5 : s->home_S;
    if ((S0 & 3) != 1) {
        uint64_t add = (1u - (S0 & 3)) & 3;
        if (S0 > UINT64_MAX - add) {
            s->home_S = UINT64_MAX;
            return;
        }
        S0 += add;
    }
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
                record_probe_runtime(&o, &s->grade, run, "home", s, 0);
            }
        }
        next = S > UINT64_MAX - 4 ? UINT64_MAX : S + 4;
        if (S >= S1 || S > UINT64_MAX - 4) break;
        S += 4;
    }
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
            "Grades are immutable inside an existing named run. One writer is allowed per run name.\n",
            VERSION);
}

static int self_test_runtime(void) {
    if (self_test() != 0) return 1;
    if (jacobi_u64(11, 2521) != -1) die("uint64 Jacobi self-test");
    grade_t g = default_grade();
    probe_t p = probe_one_atomic(2521, &g);
    if (!p.n_hit || p.n_ell != 11 || p.n_shift != 31) die("atomic NR self-test");
    puts("cbx runtime self-test OK");
    return 0;
}

int main(int argc, char **argv) {
    resolve_root_portable(argc > 0 ? argv[0] : NULL);
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
            arg = parse_u64_value("n", argv[i++]);
    }
    for (; i < argc; i++) {
        if (!strcmp(argv[i], "--run") && i + 1 < argc) run = argv[++i];
        else if (!strcmp(argv[i], "--step") && i + 1 < argc) step = parse_u64_value("step", argv[++i]);
        else if (!strcmp(argv[i], "--iterations") && i + 1 < argc) max_iterations = parse_u64_value("iterations", argv[++i]);
        else if (!strcmp(argv[i], "--random")) randomize = 1;
        else if (!strcmp(argv[i], "--sweep-only")) { sweep = 1; home = 0; }
        else if (!strcmp(argv[i], "--home-only")) { sweep = 0; home = 1; }
        else if (!strcmp(argv[i], "--fab-max") && i + 1 < argc) {
            uint64_t v = parse_u64_value("fab-max", argv[++i]);
            if (v == 0 || v > 64) die("fab-max must be 1..64");
            cli.fab_max = (unsigned)v;
            grade_touched = 1;
        }
        else if (!strcmp(argv[i], "--i-max") && i + 1 < argc) { cli.i_max = parse_u64_value("i-max", argv[++i]); grade_touched = 1; }
        else if (!strcmp(argv[i], "--n-ell-max") && i + 1 < argc) { cli.n_ell_max = parse_u64_value("n-ell-max", argv[++i]); grade_touched = 1; }
        else if (!strcmp(argv[i], "--l-max") && i + 1 < argc) { cli.l_max = parse_u64_value("l-max", argv[++i]); grade_touched = 1; }
        else if (!strcmp(argv[i], "--k-max") && i + 1 < argc) {
            uint64_t k = parse_u64_value("k-max", argv[++i]);
            cli.i_max = k; cli.l_max = k; grade_touched = 1;
        }
        else if (!strcmp(argv[i], "--k-policy") && i + 1 < argc) { if (!parse_policy(argv[++i], &cli.policy)) die("unknown k policy"); grade_touched = 1; }
        else if (!strcmp(argv[i], "--policy-scale") && i + 1 < argc) { cli.policy_scale = parse_scale_value(argv[++i]); grade_touched = 1; }
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { usage_runtime(); return 0; }
        else { usage_runtime(); return 2; }
    }

    if (!valid_run(run) || strlen(run) > 128) die("run name must be 1..128 letters, digits, - or _");
    if (!cli.fab_max || cli.fab_max > 64) die("fab-max must be 1..64");
    if (cli.i_max < 3 || !cli.n_ell_max || !cli.l_max || !isfinite(cli.policy_scale) || cli.policy_scale <= 0)
        die("invalid grade");

    if (!strcmp(cmd, "self-test")) return self_test_runtime();

    if (!strcmp(cmd, "probe") || !strcmp(cmd, "solve")) {
        if (arg < 2) die("probe/solve requires n >= 2");
        grade_t pg = cli;
        if (!grade_touched) {
            int pex = 0;
            seed_t ps = load_seed_runtime(run, &pex);
            if (pex) pg = ps.grade;
        }
        probe_t o = probe_one_atomic(arg, &pg);
        print_probe_json_exact(stdout, &o, &pg, "probe", run);
        return 0;
    }

    if (!strcmp(cmd, "status")) {
        int ex = 0;
        seed_t s = load_seed_runtime(run, &ex);
        if (!ex) {
            printf("{\"kernel\":\"cbx.kernel\",\"run\":\"%s\",\"exists\":false}\n", run);
            return 0;
        }
        s.unique_letters = count_run_letter_markers(run);
        printf("{\"kernel\":\"cbx.kernel\",\"version\":\"%s\",\"run\":\"%s\","
               "\"sweep\":%" PRIu64 ",\"home_S\":%" PRIu64 ",\"observations\":%" PRIu64
               ",\"unique_letters\":%" PRIu64 ",\"windows\":%" PRIu64
               ",\"fab_max\":%u,\"i_max\":%" PRIu64 ",\"n_ell_max\":%" PRIu64
               ",\"l_max\":%" PRIu64 ",\"policy\":\"%s\",\"policy_scale\":%.17g}\n",
               VERSION, run, s.sweep, s.home_S, s.observations, s.unique_letters, s.windows,
               s.grade.fab_max, s.grade.i_max, s.grade.n_ell_max, s.grade.l_max,
               policy_name(s.grade.policy), s.grade.policy_scale);
        return 0;
    }

    if (strcmp(cmd, "go") && strcmp(cmd, "continue")) { usage_runtime(); return 2; }

    int lock_fd = acquire_run_lock(run);
    repair_observation_tail(run);

    int ex = 0;
    seed_t s = load_seed_runtime(run, &ex);
    if (ex) {
        if (grade_touched && !same_grade(&s.grade, &cli))
            die("grade mismatch for existing run '%s'; use a new --run name", run);
        if (randomize) fprintf(stderr, "cbx: existing run '%s'; --random ignored\n", run);
    } else {
        s = default_seed(&cli);
        if (randomize) s.sweep = random_start();
        save_seed(run, &s);
    }
    s.unique_letters = count_run_letter_markers(run);
    if (!step) step = DEFAULT_STEP;

    fprintf(stderr,
            "cbx: run=%s sweep=%s home=%s grade=(F=%u,I=%" PRIu64 ",N=%" PRIu64
            ",L=%" PRIu64 ",policy=%s,scale=%.17g)\n",
            run, sweep ? "on" : "off", home ? "on" : "off", s.grade.fab_max,
            s.grade.i_max, s.grade.n_ell_max, s.grade.l_max,
            policy_name(s.grade.policy), s.grade.policy_scale);

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
    release_run_lock(lock_fd);
    return 0;
}