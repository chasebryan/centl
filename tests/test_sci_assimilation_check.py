#!/usr/bin/env python3
"""Regression tests for scripts/sci-assimilation-check.py

These tests create hermetic temporary git repositories to exercise ancestry
semantics without depending on the centl repo history.

Run: python3 tests/test_sci_assimilation_check.py
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts" / "sci-assimilation-check.py"
PY = sys.executable


def run_cmd(cmd, cwd=None, check=True):
    return subprocess.run(cmd, cwd=cwd, check=check, capture_output=True, text=True)


def init_repo(path: Path):
    run_cmd(["git", "init", "-b", "main"], cwd=path)
    run_cmd(["git", "config", "user.email", "test@example.com"], cwd=path)
    run_cmd(["git", "config", "user.name", "Test User"], cwd=path)


def commit_file(path: Path, filename: str, content: str, msg: str):
    fp = path / filename
    fp.write_text(content, encoding="utf-8")
    run_cmd(["git", "add", filename], cwd=path)
    run_cmd(["git", "commit", "-m", msg], cwd=path)
    sha = run_cmd(["git", "rev-parse", "HEAD"], cwd=path).stdout.strip()
    return sha


def make_report_json(path: Path, source_commit: str, product_pass=True, model_enabled=False):
    report = {
        "schema_version": 1,
        "report_kind": "centl-sci-assimilation",
        "sci_version": "0.0.1",
        "git": {"commit": source_commit},
        "product": {
            "summary": {"total": 1, "passed": 1 if product_pass else 0},
            "cases": [{"name": "case1", "pass": product_pass}],
        },
        "gates": {
            "native": True if product_pass else False,
            "product": True if product_pass else False,
            "model_safety": True,
            "model_full_qualification": False,
        },
        "model": {"enabled": model_enabled, "summary": {"total": 0, "passed": 0}, "cases": []},
    }
    path.write_text(json.dumps(report), encoding="utf-8")


def run_checker(report_path: Path, extra_args=None, cwd=None):
    args = [PY, str(CHECKER)]
    if extra_args:
        args += extra_args
    args.append(str(report_path))
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def main():
    failures = 0
    tmpdir = tempfile.mkdtemp(prefix="sci-check-test-")
    t = Path(tmpdir)
    try:
        repo = t / "repo"
        repo.mkdir()
        init_repo(repo)
        # initial commit
        commit_file(repo, "init.txt", "init", "init")
        # branch feature with a commit
        run_cmd(["git", "checkout", "-b", "feature"], cwd=repo)
        commit_feature = commit_file(repo, "feature.txt", "feature", "feature commit")
        # checkout main and make a different commit so feature commit is not an ancestor
        run_cmd(["git", "checkout", "main"], cwd=repo)
        commit_main = commit_file(repo, "main.txt", "main", "main commit")

        # A. Structural validation: historical report (source not ancestor) passes structural check
        report_path = t / "reportA.json"
        make_report_json(report_path, commit_feature, product_pass=True)
        rc, out, err = run_checker(report_path, cwd=repo)
        print("Test A: rc=", rc)
        if rc != 0:
            print("Test A failed: expected rc=0\n", out, err)
            failures += 1

        # B. Same report fails when --require-source-ancestor
        rc, out, err = run_checker(report_path, ["--require-source-ancestor"], cwd=repo)
        print("Test B: rc=", rc)
        if rc == 0:
            print("Test B failed: expected non-zero (ancestor required)\n", out, err)
            failures += 1

        # C. Report whose source commit is current HEAD passes with --require-source-ancestor
        report_path_c = t / "reportC.json"
        make_report_json(report_path_c, commit_main, product_pass=True)
        rc, out, err = run_checker(report_path_c, ["--require-source-ancestor"], cwd=repo)
        print("Test C: rc=", rc)
        if rc != 0:
            print("Test C failed: expected rc=0\n", out, err)
            failures += 1

        # D. Malformed SHA fails
        report_path_d = t / "reportD.json"
        # invalid short sha
        make_report_json(report_path_d, "deadbeef", product_pass=True)
        rc, out, err = run_checker(report_path_d, cwd=repo)
        print("Test D: rc=", rc)
        if rc == 0:
            print("Test D failed: expected non-zero for malformed SHA\n", out, err)
            failures += 1

        # E. --require-product-gates implies strong provenance: non-ancestor report should fail even
        rc, out, err = run_checker(report_path, ["--require-product-gates"], cwd=repo)
        print("Test E: rc=", rc)
        if rc == 0:
            print("Test E failed: expected non-zero when product gates requested on non-ancestor report\n", out, err)
            failures += 1

        # Also ensure that --require-product-gates passes when report source is HEAD and gates are passing
        rc, out, err = run_checker(report_path_c, ["--require-product-gates"], cwd=repo)
        print("Test E2: rc=", rc)
        if rc != 0:
            print("Test E2 failed: expected rc=0 when product gates requested and source is HEAD\n", out, err)
            failures += 1

        # Additional structural negative tests required by the task:
        # a) unsupported/wrong schema_version fails
        report_a = t / "report_a_schema.json"
        make_report_json(report_a, commit_feature, product_pass=True)
        # mutate to wrong schema_version
        j = json.loads(report_a.read_text(encoding='utf-8'))
        j['schema_version'] = 2
        report_a.write_text(json.dumps(j), encoding='utf-8')
        rc, out, err = run_checker(report_a, cwd=repo)
        print("Test a (schema_version): rc=", rc)
        if rc == 0:
            print("Test a failed: expected non-zero for unsupported schema_version\n", out, err)
            failures += 1

        # b) product summary total mismatch fails
        report_b = t / "report_b_total_mismatch.json"
        make_report_json(report_b, commit_feature, product_pass=True)
        j = json.loads(report_b.read_text(encoding='utf-8'))
        j['product']['summary']['total'] = 2
        report_b.write_text(json.dumps(j), encoding='utf-8')
        rc, out, err = run_checker(report_b, cwd=repo)
        print("Test b (total mismatch): rc=", rc)
        if rc == 0:
            print("Test b failed: expected non-zero for product total mismatch\n", out, err)
            failures += 1

        # c) product summary passed mismatch fails
        report_c = t / "report_c_passed_mismatch.json"
        make_report_json(report_c, commit_feature, product_pass=True)
        j = json.loads(report_c.read_text(encoding='utf-8'))
        j['product']['summary']['passed'] = 0
        report_c.write_text(json.dumps(j), encoding='utf-8')
        rc, out, err = run_checker(report_c, cwd=repo)
        print("Test c (passed mismatch): rc=", rc)
        if rc == 0:
            print("Test c failed: expected non-zero for product passed mismatch\n", out, err)
            failures += 1

        # d) missing required gate fails
        report_d2 = t / "report_d_missing_gate.json"
        make_report_json(report_d2, commit_feature, product_pass=True)
        j = json.loads(report_d2.read_text(encoding='utf-8'))
        # remove "product" gate
        del j['gates']['product']
        report_d2.write_text(json.dumps(j), encoding='utf-8')
        rc, out, err = run_checker(report_d2, cwd=repo)
        print("Test d (missing gate): rc=", rc)
        if rc == 0:
            print("Test d failed: expected non-zero for missing gate\n", out, err)
            failures += 1

        # e) current-HEAD report with --require-product-gates fails when native or product gate is false
        report_e_native = t / "report_e_native_false.json"
        make_report_json(report_e_native, commit_main, product_pass=True)
        j = json.loads(report_e_native.read_text(encoding='utf-8'))
        j['gates']['native'] = False
        report_e_native.write_text(json.dumps(j), encoding='utf-8')
        rc, out, err = run_checker(report_e_native, ["--require-product-gates"], cwd=repo)
        print("Test e1 (native false): rc=", rc)
        if rc == 0:
            print("Test e1 failed: expected non-zero when native gate is false under --require-product-gates\n", out, err)
            failures += 1

        report_e_product = t / "report_e_product_false.json"
        make_report_json(report_e_product, commit_main, product_pass=True)
        j = json.loads(report_e_product.read_text(encoding='utf-8'))
        j['gates']['product'] = False
        report_e_product.write_text(json.dumps(j), encoding='utf-8')
        rc, out, err = run_checker(report_e_product, ["--require-product-gates"], cwd=repo)
        print("Test e2 (product false): rc=", rc)
        if rc == 0:
            print("Test e2 failed: expected non-zero when product gate is false under --require-product-gates\n", out, err)
            failures += 1

        # f) model.enabled=true with model_safety=false fails under --require-product-gates
        report_f = t / "report_f_model_safety_false.json"
        make_report_json(report_f, commit_main, product_pass=True, model_enabled=True)
        j = json.loads(report_f.read_text(encoding='utf-8'))
        # model_safety gate false
        j['gates']['model_safety'] = False
        # ensure model summary/cases consistent
        j['model'] = {"enabled": True, "summary": {"total": 1, "passed": 1}, "cases": [{"name": "m1", "pass": True}]}
        report_f.write_text(json.dumps(j), encoding='utf-8')
        rc, out, err = run_checker(report_f, ["--require-product-gates"], cwd=repo)
        print("Test f (model_safety false): rc=", rc)
        if rc == 0:
            print("Test f failed: expected non-zero when model_safety is false under --require-product-gates\n", out, err)
            failures += 1

    finally:
        shutil.rmtree(tmpdir)

    if failures:
        print(f"{failures} test(s) failed")
        sys.exit(2)
    print("All tests passed")


if __name__ == "__main__":
    main()
