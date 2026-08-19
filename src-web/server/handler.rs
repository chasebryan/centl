// HTTP Request Dispatcher & Command Execution Handler
// Free Computation Foundation - Apache-2.0

use crate::engine::{evaluate, ExecutionResult, HistoryEntry, Session};
use crate::erdos_straus::{run_hunt_window, solve_es, HuntSummary};
use crate::physics::{convert_units, simulate_collision_1d, PhysicsResult};
use std::env;
use std::process::Command;
use std::time::Instant;

pub struct AppState {
    pub session: Session,
}

pub fn handle_command(
    raw_cmd: &str,
    state: &mut AppState,
) -> (Option<ExecutionResult>, Option<String>, Option<PhysicsResult>, Option<HuntSummary>) {
    let cmd = raw_cmd.trim();
    if cmd.is_empty() {
        return (None, None, None, None);
    }

    // The web Clear control should behave like a clean reload: reset the full
    // calculation session and render the pristine work area, not a synthetic
    // "history cleared" result block.
    if cmd == ":clear" || cmd == ":clear-history" {
        state.session = Session::new();
        return (None, None, None, None);
    }

    // 1. Erdős–Straus Command Handler
    if cmd.starts_with("es ") || cmd == "es" || cmd.starts_with("erdos ") {
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        if parts.len() == 1 {
            let summary = run_hunt_window(1000, 500, 20);
            return (None, None, None, Some(summary));
        }
        match parts[1] {
            "solve" | "probe" => {
                if parts.len() >= 3 {
                    if let Ok(n) = parts[2].parse::<u64>() {
                        let res = solve_es(n);
                        let witness_text = if let Some(witness) = &res.witness {
                            format!(
                                "{}\nGrade: {} · Layer: {} · Kind: {}",
                                witness.equation(),
                                res.grade.to_uppercase(),
                                witness.layer,
                                witness.kind
                            )
                        } else {
                            format!(
                                "Prime {} is unsolved in the standard window. Grade: {}",
                                n,
                                res.grade.to_uppercase()
                            )
                        };
                        let execution = ExecutionResult {
                            text: witness_text,
                            exact_rational: None,
                            approximate: res.letter_number.map(|id| format!("Letter ID: #{}", id)),
                            symbolic_expr: None,
                            execution_micros: res.execution_micros,
                        };
                        return (Some(execution), None, None, None);
                    }
                }
                return (
                    None,
                    Some("Usage: es solve <prime_integer>".to_string()),
                    None,
                    None,
                );
            }
            "hunt" | "go" => {
                let from = if parts.len() >= 3 {
                    parts[2].parse::<u64>().unwrap_or(20000)
                } else {
                    20000
                };
                let summary = run_hunt_window(from, 5000, 50);
                return (None, None, None, Some(summary));
            }
            "status" => {
                let summary = run_hunt_window(1000, 1000, 30);
                return (None, None, None, Some(summary));
            }
            _ => {
                return (
                    None,
                    Some("Usage: es solve <p> | es hunt [from] | es status".to_string()),
                    None,
                    None,
                );
            }
        }
    }

    // 2. Physics Command Handler
    if cmd.starts_with("physics ") || cmd == "physics" {
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        if parts.len() >= 2 && (parts[1] == "convert" || parts[1] == "unit") {
            if parts.len() != 5 {
                return (
                    None,
                    Some("Usage: physics convert <value> <from_unit> <to_unit>".to_string()),
                    None,
                    None,
                );
            }
            let value = match parts[2].parse::<f64>() {
                Ok(value) => value,
                Err(_) => {
                    return (
                        None,
                        Some(format!("Invalid physics value: {}", parts[2])),
                        None,
                        None,
                    )
                }
            };
            return match convert_units(value, parts[3], parts[4]) {
                Ok(result) => (None, None, Some(result), None),
                Err(error) => (None, Some(error), None, None),
            };
        }

        if parts.len() >= 2 && parts[1] == "collision" {
            let m1 = named_f64(&parts[2..], "m1");
            let v1 = named_f64(&parts[2..], "v1");
            let m2 = named_f64(&parts[2..], "m2");
            let v2 = named_f64(&parts[2..], "v2");
            let restitution = named_f64(&parts[2..], "e")
                .or_else(|| named_f64(&parts[2..], "restitution"))
                .unwrap_or(1.0);

            let (Some(m1), Some(v1), Some(m2), Some(v2)) = (m1, v1, m2, v2) else {
                return (
                    None,
                    Some(
                        "Usage: physics collision m1=<mass> v1=<velocity> m2=<mass> v2=<velocity> [e=<0..1>]"
                            .to_string(),
                    ),
                    None,
                    None,
                );
            };

            return match simulate_collision_1d(m1, v1, m2, v2, restitution) {
                Ok(result) => (None, None, Some(result), None),
                Err(error) => (None, Some(error), None, None),
            };
        }

        return (
            None,
            Some(
                "Usage: physics convert <value> <from_unit> <to_unit> | physics collision m1=<...> v1=<...> m2=<...> v2=<...> [e=<...>]"
                    .to_string(),
            ),
            None,
            None,
        );
    }

    // 3. Rigorous approximation boundary.
    //
    // The Rust web shell deliberately does not maintain a second floating-point
    // approximation implementation. Top-level approx(...) requests are executed
    // by the canonical CENTL executable, whose Arb-backed evaluator owns the
    // rigorous-enclosure contract. This prevents the web UI and native CENTL
    // calculator from drifting into different numerical semantics.
    if is_approximation_command(cmd) {
        return match run_canonical_approx(cmd) {
            Ok(result) => {
                state.session.history.push(HistoryEntry {
                    command: cmd.to_string(),
                    result: result.text.clone(),
                    exact_repr: None,
                    approximate_repr: result.approximate.clone(),
                    execution_micros: result.execution_micros,
                    success: true,
                });
                (Some(result), None, None, None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    // 4. Exact Mathematical Evaluator
    match evaluate(cmd, &mut state.session) {
        Ok(result) => (Some(result), None, None, None),
        Err(error) => (None, Some(error), None, None),
    }
}

fn is_approximation_command(command: &str) -> bool {
    let trimmed = command.trim_start();
    let Some(rest) = trimmed.strip_prefix("approx") else {
        return false;
    };
    rest.trim_start().starts_with('(')
}

fn run_canonical_approx(command: &str) -> Result<ExecutionResult, String> {
    let engine = env::var("CENTL_ENGINE_BIN").unwrap_or_else(|_| "centl".to_string());
    run_canonical_approx_with(&engine, command)
}

fn run_canonical_approx_with(engine: &str, command: &str) -> Result<ExecutionResult, String> {
    let started = Instant::now();
    let output = Command::new(engine)
        .arg("--no-color")
        .arg(command)
        .output()
        .map_err(|error| {
            format!(
                "canonical CENTL approximation backend unavailable ({}): {}",
                engine, error
            )
        })?;

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();

    if !output.status.success() {
        return Err(if stderr.is_empty() {
            format!(
                "canonical CENTL approximation failed with status {}",
                output.status
            )
        } else {
            stderr
        });
    }
    if stdout.is_empty() {
        return Err("canonical CENTL approximation returned no result".to_string());
    }

    Ok(ExecutionResult {
        text: stdout,
        exact_rational: None,
        approximate: Some("canonical CENTL rigorous enclosure".to_string()),
        symbolic_expr: None,
        execution_micros: started.elapsed().as_micros(),
    })
}

fn named_f64(parts: &[&str], name: &str) -> Option<f64> {
    parts.iter().find_map(|part| {
        let (key, value) = part.split_once('=')?;
        if key.eq_ignore_ascii_case(name) {
            value.parse::<f64>().ok()
        } else {
            None
        }
    })
}

pub fn render_full_page(content_html: &str, title: &str, rel: &str) -> String {
    let mut page = String::new();
    page.push_str("<!doctype html>\n<html lang=\"en\">\n<head>\n");
    page.push_str("  <meta charset=\"utf-8\">\n");
    page.push_str("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    page.push_str("  <meta name=\"description\" content=\"Free Computation Foundation: CENTL exact calculator, scientific computation, and public research.\">\n");
    page.push_str(&format!(
        "  <title>{} — Free Computation Foundation</title>\n",
        title
    ));
    page.push_str(&format!(
        "  <link rel=\"stylesheet\" href=\"{}style.css?v=3\">\n",
        rel
    ));
    page.push_str(&format!(
        "  <link rel=\"stylesheet\" href=\"{}library-layout.css?v=2\">\n",
        rel
    ));
    page.push_str("</head>\n<body>\n<div class=\"shell\" id=\"top\">\n");
    page.push_str("  <a class=\"skip\" href=\"#content\">Skip to content</a>\n");
    page.push_str("  <header class=\"masthead home-masthead\" id=\"centl-hub\" tabindex=\"-1\" autofocus>\n");
    page.push_str(&format!("    <div class=\"brand\"><a href=\"{}index.html#top\"><strong>FCF</strong><span>Free Computation Foundation</span><small>Free for science.</small></a></div>\n", rel));
    page.push_str("  </header>\n");
    page.push_str("  <div class=\"layout\">\n");
    page.push_str("    <nav aria-label=\"Primary\">\n");
    page.push_str("      <h2>CENTL &amp; Hub</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str("        <li><a href=\"/hub#top\">CENTL Work Area</a></li>\n");
    page.push_str(&format!("        <li><a href=\"{}centl.html#top\">About CENTL</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}research-erdos-straus.html#top\">Erdős–Straus Hunt</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}software.html#top\">Software Suite</a></li>\n", rel));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Documentation</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!("        <li><a href=\"{}docs.html#top\">Documentation Portal</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/install.html#top\">Installation Guide</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/numerics.html#top\">Numerical Contract</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/syntax.html#top\">Syntax &amp; Functions</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/sci.html#top\">CENTL-SCi &amp; Physics</a></li>\n", rel));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Research</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!("        <li><a href=\"{}research.html#top\">Research Library</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}research-erdos-straus.html#top\">Erdős–Straus Program</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}bryan-recursive-entanglement-calculus.html#top\">BREC v1.0 Calculus</a></li>\n", rel));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Foundation</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!("        <li><a href=\"{}about.html#top\">About FCF</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}funding.html#top\">Funding &amp; Sponsors</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}mirrors.html#top\">The Bazaar</a></li>\n", rel));
    page.push_str("        <li><a href=\"https://github.com/chasebryan/centl\">GitHub Repository</a></li>\n");
    page.push_str("      </ul>\n");
    page.push_str("    </nav>\n");
    page.push_str("    <main id=\"content\">\n");
    page.push_str(&format!("      <img class=\"banner\" src=\"{}assets/fcf-centl-banner.png\" alt=\"Free Computation Foundation and CENTL camel banner\">\n", rel));
    page.push_str(content_html);
    page.push_str("\n    </main>\n");
    page.push_str("  </div>\n");
    page.push_str("  <footer>Free Computation Foundation · Free for science. · Server-rendered HTML/CSS · Zero JavaScript</footer>\n");
    page.push_str("</div>\n</body>\n</html>\n");
    page
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::HistoryEntry;

    #[test]
    fn collision_arguments_are_read_from_the_command() {
        let parts = ["m1=2", "v1=10", "m2=4", "v2=-5", "e=0.5"];
        assert_eq!(named_f64(&parts, "m1"), Some(2.0));
        assert_eq!(named_f64(&parts, "v2"), Some(-5.0));
        assert_eq!(named_f64(&parts, "e"), Some(0.5));
    }

    #[test]
    fn invalid_physics_subcommand_returns_an_error() {
        let mut state = AppState {
            session: Session::new(),
        };
        let (_, error, physics, _) = handle_command("physics nonsense", &mut state);
        assert!(error.is_some());
        assert!(physics.is_none());
    }

    #[test]
    fn clear_resets_the_web_session_without_rendering_a_result() {
        let mut state = AppState {
            session: Session::new(),
        };
        state.session.history.push(HistoryEntry {
            command: "2 + 2".to_string(),
            result: "4".to_string(),
            exact_repr: None,
            approximate_repr: None,
            execution_micros: 1,
            success: true,
        });
        let (result, error, physics, hunt) = handle_command(":clear", &mut state);
        assert!(state.session.history.is_empty());
        assert!(result.is_none());
        assert!(error.is_none());
        assert!(physics.is_none());
        assert!(hunt.is_none());
    }

    #[test]
    fn approximation_detection_accepts_spacing_but_not_similar_names() {
        assert!(is_approximation_command("approx(pi, 20)"));
        assert!(is_approximation_command("approx (pi, 20)"));
        assert!(!is_approximation_command("approximate(pi, 20)"));
        assert!(!is_approximation_command("x + approx(pi, 20)"));
    }

    #[cfg(unix)]
    #[test]
    fn canonical_approximation_uses_engine_output() {
        use std::fs;
        use std::os::unix::fs::PermissionsExt;

        let path = env::temp_dir().join(format!(
            "centl-web-fake-engine-{}",
            std::process::id()
        ));
        fs::write(
            &path,
            "#!/bin/sh\nprintf '%s\\n' '≈ [9.3248e157, 9.3249e157]'\n",
        )
        .unwrap();
        let mut permissions = fs::metadata(&path).unwrap().permissions();
        permissions.set_mode(0o700);
        fs::set_permissions(&path, permissions).unwrap();

        let result = run_canonical_approx_with(
            path.to_str().unwrap(),
            "approx(sqrt(2*pi*100)*(100/e)^100,20)",
        )
        .unwrap();
        assert_eq!(result.text, "≈ [9.3248e157, 9.3249e157]");
        assert_eq!(
            result.approximate.as_deref(),
            Some("canonical CENTL rigorous enclosure")
        );
        assert!(result.execution_micros > 0);

        let _ = fs::remove_file(path);
    }

    #[test]
    fn legacy_centl_hub_fragment_now_targets_the_page_top() {
        let html = render_full_page("<p>body</p>", "test", "");
        assert!(html.contains("<header class=\"masthead home-masthead\" id=\"centl-hub\" tabindex=\"-1\" autofocus>"));
    }
}
