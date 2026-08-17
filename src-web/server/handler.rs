// HTTP Request Dispatcher & Command Execution Handler
// Free Computation Foundation - Apache-2.0

use crate::engine::{evaluate, ExecutionResult, Session};
use crate::erdos_straus::{run_hunt_window, solve_es, HuntSummary};
use crate::physics::{convert_units, simulate_collision_1d, PhysicsResult};

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
                        let w_str = if let Some(w) = &res.witness {
                            format!("{}\nGrade: {} · Layer: {} · Kind: {}", w.equation(), res.grade.to_uppercase(), w.layer, w.kind)
                        } else {
                            format!("Prime {} is unsolved in the standard window. Grade: {}", n, res.grade.to_uppercase())
                        };
                        let exec_res = ExecutionResult {
                            text: w_str,
                            exact_rational: None,
                            approximate: res.letter_number.map(|id| format!("Letter ID: #{}", id)),
                            symbolic_expr: None,
                            execution_micros: res.execution_micros,
                        };
                        return (Some(exec_res), None, None, None);
                    }
                }
                return (None, Some("Usage: es solve <prime_integer>".to_string()), None, None);
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
                let summary = run_hunt_window(1000, 500, 20);
                return (None, None, None, Some(summary));
            }
        }
    }

    // 2. Physics Command Handler
    if cmd.starts_with("physics ") || cmd == "physics" {
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        if parts.len() >= 5 && (parts[1] == "convert" || parts[1] == "unit") {
            if let Ok(val) = parts[2].parse::<f64>() {
                match convert_units(val, parts[3], parts[4]) {
                    Ok(res) => return (None, None, Some(res), None),
                    Err(e) => return (None, Some(e), None, None),
                }
            }
        } else if parts.len() >= 2 && parts[1] == "collision" {
            match simulate_collision_1d(2.0, 10.0, 4.0, -5.0, 1.0) {
                Ok(res) => return (None, None, Some(res), None),
                Err(e) => return (None, Some(e), None, None),
            }
        }
        match convert_units(100.0, "cm", "m") {
            Ok(res) => return (None, None, Some(res), None),
            Err(e) => return (None, Some(e), None, None),
        }
    }

    // 3. Exact Mathematical Evaluator
    match evaluate(cmd, &mut state.session) {
        Ok(res) => (Some(res), None, None, None),
        Err(err) => (None, Some(err), None, None),
    }
}

pub fn render_full_page(
    content_html: &str,
    title: &str,
    rel: &str,
) -> String {
    let mut page = String::new();
    page.push_str("<!doctype html>\n<html lang=\"en\">\n<head>\n");
    page.push_str("  <meta charset=\"utf-8\">\n");
    page.push_str("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    page.push_str("  <meta name=\"description\" content=\"Free Computation Foundation: CENTL exact calculator, scientific computation, and public research.\">\n");
    page.push_str(&format!("  <title>{} — Free Computation Foundation</title>\n", title));
    page.push_str(&format!("  <link rel=\"stylesheet\" href=\"{}style.css\">\n", rel));
    page.push_str(&format!("  <link rel=\"stylesheet\" href=\"{}library-layout.css\">\n", rel));
    page.push_str("</head>\n<body>\n<div class=\"shell\">\n");
    page.push_str("  <a class=\"skip\" href=\"#content\">Skip to content</a>\n");
    page.push_str("  <header class=\"masthead home-masthead\">\n");
    page.push_str(&format!("    <div class=\"brand\"><a href=\"{}index.html\"><strong>FCF</strong><span>Free Computation Foundation</span><small>Free for science.</small></a></div>\n", rel));
    page.push_str("  </header>\n");
    page.push_str("  <div class=\"layout\">\n");
    page.push_str("    <nav aria-label=\"Primary\">\n");
    page.push_str("      <h2>CENTL &amp; Hub</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!("        <li><a href=\"{}index.html\">CENTL Work Area</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}centl.html\">About CENTL</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}research-erdos-straus.html#es-hunt\">Erdős–Straus Hunt</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}software.html\">Software Suite</a></li>\n", rel));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Documentation</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!("        <li><a href=\"{}docs.html\">Documentation Portal</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/install.html\">Installation Guide</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/numerics.html\">Numerical Contract</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/syntax.html\">Syntax &amp; Functions</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}manuals/sci.html\">CENTL-SCi &amp; Physics</a></li>\n", rel));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Research</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!("        <li><a href=\"{}research.html\">Research Library</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}research-erdos-straus.html\">Erdős–Straus Program</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}bryan-recursive-entanglement-calculus.html\">BREC v1.0 Calculus</a></li>\n", rel));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Foundation</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!("        <li><a href=\"{}about.html\">About FCF</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}funding.html\">Funding &amp; Sponsors</a></li>\n", rel));
    page.push_str(&format!("        <li><a href=\"{}mirrors.html\">The Bazaar</a></li>\n", rel));
    page.push_str("        <li><a href=\"https://github.com/chasebryan/centl\">GitHub Repository</a></li>\n");
    page.push_str("      </ul>\n");
    page.push_str("    </nav>\n");
    page.push_str("    <main id=\"content\">\n");
    page.push_str(&format!("      <img class=\"banner\" src=\"{}assets/fcf-centl-banner.png\" alt=\"Free Computation Foundation and CENTL camel banner\">\n", rel));
    page.push_str(content_html);
    page.push_str("\n    </main>\n");
    page.push_str("  </div>\n");
    page.push_str("  <footer>Free Computation Foundation · Free for science. · Static HTML/CSS · Zero JavaScript</footer>\n");
    page.push_str("</div>\n</body>\n</html>\n");
    page
}
