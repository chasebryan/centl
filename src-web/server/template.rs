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

    // Quick Operation Category Tabs (Pure HTML Form submissions)
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

    // Main Terminal Output Display
    html.push_str(r#"<div class="terminal-screen" role="region" aria-label="CENTL Terminal Output">"#);

    if session.history.is_empty() && last_result.is_none() && last_error.is_none() && last_physics.is_none() && last_hunt.is_none() {
        html.push_str(r#"<div class="terminal-welcome">"#);
        html.push_str(r#"<p class="welcome-text"><strong>CENTL exact mathematical interpreter ready.</strong></p>"#);
        html.push_str(r#"<p class="welcome-hint">Type any mathematics, scientific expression, or hunt command below. Exact values remain exact. Approximations carry justified enclosures.</p>"#);
        html.push_str(r#"<div class="terminal-examples">"#);
        html.push_str(r#"<code>2^128 - 1</code> · <code>1/3 + 5/7</code> · <code>solve(x^2 - 5x + 6 = 0, x)</code> · <code>es solve 1009</code>"#);
        html.push_str(r#"</div>"#);
        html.push_str(r#"</div>"#);
    }

    // Render session history stack
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

    // Render latest execution result (if active)
    if let Some(err) = last_error {
        html.push_str(r#"<div class="output-block output-error">"#);
        html.push_str(&format!(r#"<div class="error-title"><strong>Computation Error:</strong></div><pre>{}</pre>"#, escape_html(err)));
        html.push_str(r#"</div>"#);
    } else if let Some(res) = last_result {
        html.push_str(r#"<div class="output-block output-success">"#);
        html.push_str(&format!(r#"<div class="output-value"><span class="output-tag">[EXACT RESULT]</span> <strong class="result-text">{}</strong></div>"#, escape_html(&res.text)));
        if let Some(approx) = &res.approximate {
            html.push_str(&format!(r#"<div class="output-approx"><span class="approx-tag">[ENCLOSURE]</span> {}</div>"#, escape_html(approx)));
        }
        html.push_str(&format!(r#"<div class="output-receipt"><span>Execution time: {} µs</span><span>Status: Verified Exact</span><span>Receipt Schema: 1</span></div>"#, res.execution_micros));
        html.push_str(r#"</div>"#);
    } else if let Some(phys) = last_physics {
        html.push_str(r#"<div class="output-block output-physics">"#);
        html.push_str(&format!(r#"<div class="phys-title"><strong>{}</strong> <span class="badge-verified">VERIFIED</span></div>"#, escape_html(&phys.title)));
        html.push_str(r#"<table class="phys-table">"#);
        for (k, v) in &phys.details {
            html.push_str(&format!(r#"<tr><th>{}</th><td>{}</td></tr>"#, escape_html(k), escape_html(v)));
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
            for f in &hunt.findings {
                let eq = f.witness.as_ref().map(|w| w.equation()).unwrap_or_else(|| "Unsolved in window".to_string());
                let letter_str = f.letter_number.as_ref().map(|id| format!(" · Letter #{}", id)).unwrap_or_default();
                html.push_str(&format!(r#"<div class="finding-row"><span class="finding-grade">[{}]</span> <code>n={}</code>: {} <small>{}</small></div>"#, f.grade.to_uppercase(), f.n, eq, letter_str));
            }
            html.push_str(r#"</div>"#);
        }
        html.push_str(r#"</div>"#);
    }

    html.push_str(r#"</div>"#); // end terminal-screen

    // Command Input Form (Zero-JS POST/GET form)
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

    html.push_str(r#"</div>"#); // end centl-work-area
    html
}

fn escape_html(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}
