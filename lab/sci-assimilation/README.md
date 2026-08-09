# CENTL-SCi assimilation loop

This directory is the handoff surface between local CENTL-SCi qualification and the next engineering pass.

`make sci-assimilate` runs the native verification/test/build gates, the deterministic product corpus, and—when `SCI_SERVER_URL` is set—the forced resident-model corpus. It writes:

- `latest.json` — machine-readable evidence, timings, observed IR/results, failure classes, and gates.
- `latest.md` — compact human summary intended for GitHub Actions job summaries and review.

`make sci-assimilate-publish` runs the same harness, validates a freshly generated report, commits only those two report files, and pushes the current branch. It refuses to publish directly to `main` unless `CENTL_SCI_ALLOW_MAIN_REPORT=1` is explicitly set.

The publisher can also own the resident-model lifecycle. Set `SCI_MODEL=/path/to/model.gguf` instead of `SCI_SERVER_URL`; it starts the hardened loopback server, waits for `/health`, runs the complete battery, and stops the server on exit. If an explicit server is already running, use `SCI_SERVER_URL` instead so the harness never silently assumes which model is behind an occupied port.

The report source commit is recorded before the report commit. GitHub validation therefore requires the recorded source commit to be an ancestor of the committed report.

## Gate semantics

- `native`: F* extraction plus formatting/lint, native tests, and native build passed. `--full` also includes the existing hardening suite.
- `product`: every deterministic/product fixture behaved exactly as contracted, including cases that must defer rather than overclaim.
- `model_safety`: forced-model safety/scope fixtures passed. This is a hard gate when model qualification is enabled.
- `model_full_qualification`: every forced-model fixture passed. This is evidence rather than a publication gate while student models are still being qualified.

A generic student model is never promoted to mathematical authority by this harness. All admitted execution still crosses the validated SCi IR and existing CENTL/CENTL Physics boundary.

## One-command local student run

```sh
make sci-assimilate-publish \
  SCI_MODEL="$HOME/Models/CENTL-SCi/qwen2.5-0.5b-instruct-q4_k_m.gguf" \
  SCI_MODEL_LABEL=Qwen2.5-0.5B-Instruct-Q4_K_M
```

If a resident server is already running:

```sh
make sci-assimilate-publish \
  SCI_SERVER_URL=http://127.0.0.1:8080 \
  SCI_MODEL_LABEL=Qwen2.5-0.5B-Instruct-Q4_K_M
```

For the larger native hardening pass, add:

```sh
SCI_ASSIMILATION_ARGS=--full
```

Do not hand-edit `latest.json` or `latest.md`; regenerate them from the harness.
