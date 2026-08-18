// High-Aesthetic Zero-JavaScript HTML Template & Component Renderer for CENTL
// Free Computation Foundation - Apache-2.0

use crate::engine::{ExecutionResult, Session};
use crate::erdos_straus::HuntSummary;
use crate::physics::PhysicsResult;

pub struct PageConfig {
    pub title: String,
    pub active_tab: String,
    pub relative_root: String,
}

pub fn render_centl_work_area(
    current_input: &str,
    last_result: Option<&ExecutionResult>,
    last_error: Option<&str>,
    last_physics: Option<&PhysicsResult>,
    last_hunt: Option<&HuntSummary>,
    session: &Session,
    action_url: &str,
) -> String {
    let mut html = String::new();
    let latest_result_is_in_history = last_result.is_some_and(|result| {
        session.history.last().is_some_and(|entry| {
            entry.result == result.text && entry.execution_micros == result.execution_micros
        })
    });

    html.push_str(r#"<div class="centl-work-area" id="centl-hub">"#);
    html.push_str(r#"<div class="centl-work-header">"#);
    html.push_str(r#"<div class="work-header-left">"#);
    html.push_str(r#"<span class="status-dot"></span>"#);
    html.push_str(r#"<strong class="terminal-title">CENTL v0.15.0 Al-Nur · Exact Calculation Hub</strong>"#);
    html.push_str(r#"</div>"#);
    html.push_str(r#"<div class="work-header-right">"#);
    html.push_str(r#"<span class="badge-oasis">Oasis Standard</span>"#);
    html.push_str(r#"<span class="badge-zerojs">Zero JavaScript</span>"#);
    html.push_str(r#"</div>"#);
    html.push_str(r#"</div>"#);

    // Quick Operation Category Tabs (Pure HTML form submissions)
    html.push_str(r#"<div class="quick-op-bar" aria-label="Quick operations">"#);
    html.push_str(&format!(r#"<form method="POST" action="{}#centl-hub" class="quick-form">"#, action_url));
    html.push_str(r#"<span class="quick-label">Presets:</span>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="diff(x^3 * sin(x), x)" class="btn-preset">d/dx(x³·sin x)</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="integrate(3*x^2 + 2*x + 1, x, 0, 5)" class="btn-preset">∫(3x²+2x+1)dx</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="solve(3*x^2 - 12 = 0, x)" class="btn-preset">solve(3x²-12=0)</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="approx(pi, 50)" class="btn-preset">approx(π, 50)</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="fibonacci(60)" class="btn-preset">fibonacci(60)</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="es solve 1009" class="btn-preset btn-hunt">es solve 1009</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="physics convert 100 cm m" class="btn-preset btn-phys">physics convert</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value="physics collision m1=2 v1=10 m2=4 v2=-5" class="btn-preset btn-phys">physics collision</button>"#);
    html.push_str(r#"</form>"#);
    html.push_str(r#"</div>"#);

    // The screen has a fixed viewport. History scrolls inside it instead of growing the page.
    html.push_str(r#"<div class="terminal-screen" role="region" aria-label="CENTL Terminal Output" style="height:clamp(360px,52vh,520px);min-height:0;max-height:none;overflow-y:auto;overscroll-behavior:contain;scrollbar-gutter:stable;">"#);

    if session.history.is_empty() && last_result.is_none() && last_error.is_none() && last_physics.is_none() && last_hunt.is_none() {
        html.push_str(r#"<div class="terminal-welcome">"#);
        html.push_str(r#"<p class="welcome-text"><strong>CENTL exact mathematical interpreter ready.</strong></p>"#);
        html.push_str(r#"<p class="welcome-hint">Type any mathematics, scientific expression, or hunt command below. Exact values remain exact. Approximations carry justified enclosures.</p>"#);
        html.push_str(r#"<div class="terminal-examples">"#);
        html.push_str(r#"<code>2^128 - 1</code> · <code>1/3 + 5/7</code> · <code>solve(x^2 - 5x + 6 = 0, x)</code> · <code>es solve 1009</code>"#);
        html.push_str(r#"</div>"#);
        html.push_str(r#"</div>"#);
    }

    for entry in &session.history {
        html.push_str(r#"<div class="history-item">"#);
        html.push_str(&format!(r#"<div class="history-cmd"><span class="prompt-symbol">centl&gt;</span> <code>{}</code></div>"#, escape_html(&entry.command)));
        html.push_str(&format!(r#"<div class="history-output"><pre>{}</pre>"#, escape_html(&entry.result)));
        if let Some(approx) = &entry.approximate_repr {
            html.push_str(&format!(r#"<div class="enclosure-badge">≈ {}</div>"#, escape_html(approx)));
        }
        html.push_str(&format!(r#"<div class="history-meta">receipt: exact · schema: 1 · {} µs</div>"#, entry.execution_micros));
        html.push_str(r#"</div>"#);
        html.push_str(r#"</div>"#);
    }

    if let Some(err) = last_error {
        html.push_str(r#"<div class="output-block output-error">"#);
        html.push_str(&format!(r#"<div class="error-title"><strong>Computation Error:</strong></div><pre>{}</pre>"#, escape_html(err)));
        html.push_str(r#"</div>"#);
    } else if let Some(phys) = last_physics {
        html.push_str(r#"<div class="output-block output-physics">"#);
        html.push_str(&format!(r#"<div class="phys-title"><strong>{}</strong> <span class="badge-verified">VERIFIED</span></div>"#, escape_html(&phys.title)));
        html.push_str(r#"<table class="phys-table">"#);
        for (key, value) in &phys.details {
            html.push_str(&format!(r#"<tr><th>{}</th><td>{}</td></tr>"#, escape_html(key), escape_html(value)));
        }
        html.push_str(r#"</table>"#);
        html.push_str(&format!(r#"<div class="phys-summary"><strong>Result:</strong> {}</div>"#, escape_html(&phys.summary)));
        html.push_str(r#"</div>"#);
    } else if let Some(hunt) = last_hunt {
        html.push_str(r#"<div class="output-block output-hunt">"#);
        html.push_str(r#"<div class="hunt-title"><strong>Erdős–Straus Public Hunt Window Summary</strong> <span class="badge-hunt">ACTIVE HUNT</span></div>"#);
        html.push_str(&format!(r#"<p>Scanned interval: <strong>({}, {}]</strong> · Primes checked: <strong>{}</strong></p>"#, hunt.start_bound, hunt.end_bound, hunt.primes_checked));
        html.push_str(r#"<div class="hunt-stats">"#);
        html.push_str(&format!(r#"<span class="stat-pill stat-great">GREAT: {}</span>"#, hunt.great_count));
        html.push_str(&format!(r#"<span class="stat-pill stat-good">GOOD: {}</span>"#, hunt.good_count));
        html.push_str(&format!(r#"<span class="stat-pill stat-letter">LETTER: {}</span>"#, hunt.letter_count));
        html.push_str(&format!(r#"<span class="stat-pill stat-unsolved">UNSOLVED: {}</span>"#, hunt.unsolved_count));
        html.push_str(r#"</div>"#);
        if !hunt.findings.is_empty() {
            html.push_str(r#"<div class="hunt-findings-list">"#);
            html.push_str(r#"<h4>Notable Findings:</h4>"#);
            for finding in &hunt.findings {
                let equation = finding
                    .witness
                    .as_ref()
                    .map(|witness| witness.equation())
                    .unwrap_or_else(|| "Unsolved in window".to_string());
                let letter = finding
                    .letter_number
                    .as_ref()
                    .map(|id| format!(" · Letter #{}", id))
                    .unwrap_or_default();
                html.push_str(&format!(r#"<div class="finding-row"><span class="finding-grade">[{}]</span> <code>n={}</code>: {} <small>{}</small></div>"#, finding.grade.to_uppercase(), finding.n, equation, letter));
            }
            html.push_str(r#"</div>"#);
        }
        html.push_str(r#"</div>"#);
    } else if let Some(result) = last_result {
        // Mathematical evaluate() results are already appended to session history.
        // Render this block only for result-producing commands that bypass that history path.
        if !latest_result_is_in_history {
            html.push_str(r#"<div class="output-block output-success">"#);
            html.push_str(&format!(r#"<div class="output-value"><span class="output-tag">[EXACT RESULT]</span> <strong class="result-text">{}</strong></div>"#, escape_html(&result.text)));
            if let Some(approx) = &result.approximate {
                html.push_str(&format!(r#"<div class="output-approx"><span class="approx-tag">[ENCLOSURE]</span> {}</div>"#, escape_html(approx)));
            }
            html.push_str(&format!(r#"<div class="output-receipt"><span>Execution time: {} µs</span><span>Status: Verified Exact</span><span>Receipt Schema: 1</span></div>"#, result.execution_micros));
            html.push_str(r#"</div>"#);
        }
    }

    html.push_str(r#"</div>"#);

    html.push_str(&format!(r#"<form method="POST" action="{}#centl-hub" class="centl-prompt-form">"#, action_url));
    html.push_str(r#"<div class="input-row">"#);
    html.push_str(r#"<span class="input-prompt">centl&gt;</span>"#);
    html.push_str(&format!(
        r#"<input type="text" name="cmd" value="{}" placeholder="Enter expression, solve(...), diff(...), physics ..., es solve <p>, or :syntax" autocomplete="off" class="cmd-input">"#,
        escape_html(current_input)
    ));
    html.push_str(r#"<button type="submit" class="btn-calculate">Calculate</button>"#);
    html.push_str(r#"<button type="submit" name="cmd" value=":clear" class="btn-clear">Clear</button>"#);
    html.push_str(r#"</div>"#);
    html.push_str(r#"</form>"#);

    html.push_str(r#"</div>"#);
    html
}

fn escape_html(value: &str) -> String {
    value
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::{HistoryEntry, Session};

    #[test]
    fn work_area_uses_a_bounded_terminal_viewport() {
        let session = Session::new();
        let html = render_centl_work_area("", None, None, None, None, &session, "/hub");
        assert!(html.contains("height:clamp(360px,52vh,520px)"));
        assert!(html.contains("overflow-y:auto"));
        assert!(html.contains("action=\"/hub#centl-hub\""));
    }

    #[test]
    fn latest_math_result_is_not_rendered_twice() {
        let mut session = Session::new();
        let result = ExecutionResult {
            text: "44".to_string(),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 42,
        };
        session.history.push(HistoryEntry {
            command: "22 + 22".to_string(),
            result: "44".to_string(),
            exact_repr: None,
            approximate_repr: None,
            execution_micros: 42,
            success: true,
        });
        let html = render_centl_work_area("", Some(&result), None, None, None, &session, "/hub");
        assert_eq!(html.matches(">44</pre>").count(), 1);
        assert!(!html.contains("[EXACT RESULT]"));
    }
}
