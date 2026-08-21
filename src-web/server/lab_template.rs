// CentL26 standalone scientific work environment.
// The renderer is intentionally quiet by default; advanced tools use progressive disclosure.

use crate::engine::{ExecutionResult, Session};
use crate::erdos_straus::HuntSummary;
use crate::physics::PhysicsResult;

pub const LAB_CSS: &str = include_str!("lab.css");
pub const LAB_JS: &str = include_str!("lab.js");
pub const CAPABILITY_REGISTRY: &str = include_str!("centl26-capabilities.json");

pub fn render_lab_page(workbench: &str) -> String {
    format!(
        r##"<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="CentL26 — the private scientific work environment from the Free Computation Foundation.">
  <meta name="color-scheme" content="light">
  <title>CentL26</title>
  <link rel="stylesheet" href="/lab.css">
  <script src="/lab.js" defer></script>
</head>
<body class="hide-explorer hide-inspector hide-console">
  <a class="skip-link" href="#workspace-canvas">Skip to workspace</a>
  <div class="centl26-app">
    <header class="app-bar">
      <a class="product-lockup" href="/" aria-label="CentL26 home">
        <span class="product-mark">C26</span>
        <span><strong>CentL26</strong><small>Free Computation Foundation</small></span>
      </a>
      <div class="workspace-path"><button type="button" data-toggle-explorer>Untitled workspace</button><span>/</span><strong>Notebook 01</strong></div>
      <button class="command-center" type="button" data-open-palette><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="8.5" cy="8.5" r="5.5"></circle><path d="m13 13 4 4"></path></svg><span>Search or run anything</span><kbd>⌘ K</kbd></button>
      <div class="app-actions">
        <span class="kernel-state"><i></i><span><strong>Core ready</strong><small>Local</small></span></span>
        <button class="quiet-action" type="button" data-toggle-inspector title="Open context inspector" aria-label="Open context inspector"><svg viewBox="0 0 20 20" aria-hidden="true"><rect x="3" y="3" width="14" height="14" rx="2"></rect><path d="M12 3v14"></path></svg></button>
        <button class="run-action" type="button" data-run-active><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5 8 5-8 5Z"></path></svg><span>Run</span></button>
      </div>
    </header>

    <div class="app-body">
      <nav class="activity-rail" aria-label="CentL26 areas">
        <div>
          <button class="rail-button is-active" type="button" data-focus-cell data-label="Work" aria-label="Work"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 4h12v12H4z"></path><path d="M7 8h6M7 11h4"></path></svg></button>
          <button class="rail-button" type="button" data-toggle-explorer data-label="Projects" aria-label="Projects"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M3 5h5l2 2h7v9H3z"></path></svg></button>
          <button class="rail-button" type="button" data-open-palette data-label="Tools" aria-label="Tools"><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="10" cy="10" r="6"></circle><path d="M10 6v8M6 10h8"></path></svg></button>
          <button class="rail-button" type="button" data-open-palette data-label="Data" aria-label="Data"><svg viewBox="0 0 20 20" aria-hidden="true"><ellipse cx="10" cy="5" rx="6" ry="2.5"></ellipse><path d="M4 5v5c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5V5M4 10v5c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5v-5"></path></svg></button>
          <button class="rail-button" type="button" data-open-palette data-label="Models" aria-label="Models"><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="10" cy="10" r="2"></circle><ellipse cx="10" cy="10" rx="8" ry="3.5"></ellipse><ellipse cx="10" cy="10" rx="3.5" ry="8" transform="rotate(45 10 10)"></ellipse></svg></button>
          <button class="rail-button" type="button" data-open-palette data-label="Research" aria-label="Research"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M7 3h6M8 3v5l-4 7c-.5 1 .1 2 1.3 2h9.4c1.2 0 1.8-1 1.3-2l-4-7V3"></path><path d="M6.5 13h7"></path></svg></button>
          <button class="rail-button" type="button" data-open-palette data-label="Build" aria-label="Build"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5-4 5 4 5M13 5l4 5-4 5M11.5 3 8.5 17"></path></svg></button>
        </div>
        <div>
          <button class="rail-button" type="button" data-toggle-console data-label="Trace" aria-label="Trace"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m4 6 4 4-4 4M10 15h6"></path></svg></button>
          <span class="fcf-rail" aria-label="Free Computation Foundation">FCF</span>
        </div>
      </nav>
      {workbench}
    </div>

    <footer class="status-bar">
      <span><i></i>CentL26 Core</span>
      <span class="status-spacer"></span>
      <span>Exact-first</span>
      <span>Local</span>
      <span>CentL26</span>
      <span class="fcf-status" title="Free Computation Foundation">FCF</span>
    </footer>
  </div>

  <div class="command-palette" hidden>
    <div class="palette-dialog" role="dialog" aria-modal="true" aria-labelledby="palette-label">
      <h2 class="sr-only" id="palette-label">CentL26 commands</h2>
      <div class="palette-search"><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="8.5" cy="8.5" r="5.5"></circle><path d="m13 13 4 4"></path></svg><input id="palette-search" role="combobox" aria-label="Search CentL26 commands" aria-autocomplete="list" aria-controls="palette-results" aria-expanded="true" placeholder="Search tools, commands, files, and settings…" autocomplete="off"><kbd>esc</kbd></div>
      <div class="palette-results" id="palette-results" role="listbox" aria-label="Available commands">
        <p>Suggested tools</p>
        <button type="button" role="option" tabindex="-1" data-command="1/3 + 5/7"><span class="palette-icon exact">ℚ</span><span><strong>Exact calculation</strong><small>Arbitrary-precision mathematics</small></span><kbd>Math</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="solve(x^2 - 5*x + 6 = 0, x)"><span class="palette-icon symbolic">x</span><span><strong>Solve an equation</strong><small>Symbolic algebra</small></span><kbd>Math</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="diff(x^3 * sin(x), x)"><span class="palette-icon symbolic">∂</span><span><strong>Differentiate</strong><small>Symbolic calculus</small></span><kbd>Math</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="approx(pi, 50)"><span class="palette-icon bounded">≈</span><span><strong>Rigorous enclosure</strong><small>Justified numerical precision</small></span><kbd>Numeric</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="physics convert 100 cm m"><span class="palette-icon physics">Δ</span><span><strong>Physics workbench</strong><small>Typed quantities and mechanics</small></span><kbd>Physics</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="es solve 1009"><span class="palette-icon research">p</span><span><strong>Research kernel</strong><small>Erdős–Straus exact probe</small></span><kbd>Research</kbd></button>
        <p>Workspace</p>
        <button type="button" role="option" tabindex="-1" data-palette-action="focus"><span class="palette-icon neutral">＋</span><span><strong>New computation</strong><small>Focus the active work cell</small></span><kbd>⌘ ↵</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="inspector"><span class="palette-icon neutral">◇</span><span><strong>Toggle inspector</strong><small>Evidence, variables, and receipts</small></span><kbd>View</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="console"><span class="palette-icon neutral">›_</span><span><strong>Toggle execution trace</strong><small>Kernel and protocol events</small></span><kbd>View</kbd></button>
      </div>
    </div>
  </div>
</body>
</html>"##
    )
}

pub fn render_lab_workbench(
    current_input: &str,
    last_result: Option<&ExecutionResult>,
    last_error: Option<&str>,
    last_physics: Option<&PhysicsResult>,
    last_hunt: Option<&HuntSummary>,
    session: &Session,
) -> String {
    let (run_label, run_class, executor, assurance) = run_metadata(
        last_result,
        last_error,
        last_physics,
        last_hunt,
        session.history.last().map(|entry| entry.command.as_str()),
    );
    let has_work = !session.history.is_empty()
        || last_result.is_some()
        || last_error.is_some()
        || last_physics.is_some()
        || last_hunt.is_some();

    let mut html = String::new();
    html.push_str(r#"<main class="workbench-shell" id="notebook">"#);
    render_explorer(&mut html, session);

    html.push_str(r#"<section class="workspace-center"><div class="document-strip"><button class="document-tab is-active" type="button" data-focus-cell aria-current="page"><span class="document-dot"></span><span>Notebook 01</span></button><span></span><button class="strip-action" type="button" data-toggle-explorer title="Toggle workspace" aria-label="Toggle workspace"><svg viewBox="0 0 20 20" aria-hidden="true"><rect x="3" y="3" width="14" height="14" rx="2"></rect><path d="M8 3v14"></path></svg></button><button class="strip-action" type="button" data-toggle-inspector title="Toggle inspector" aria-label="Toggle inspector"><svg viewBox="0 0 20 20" aria-hidden="true"><rect x="3" y="3" width="14" height="14" rx="2"></rect><path d="M12 3v14"></path></svg></button></div>"#);
    html.push_str(r#"<div class="workspace-toolbar"><div><button class="toolbar-button" type="button" data-focus-cell><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M10 4v12M4 10h12"></path></svg>New cell</button><button class="toolbar-button" type="button" data-open-palette><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 5h12M4 10h12M4 15h8"></path></svg>Tools</button></div><div><label class="mode-control"><span>Mode</span><select aria-label="CentL26 interaction mode"><option>Auto</option><option>Math</option><option>Physics</option><option>Research</option><option>Build</option></select></label><button class="toolbar-icon" type="button" data-toggle-inspector title="Open workspace context" aria-label="Open workspace context"><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="10" cy="10" r="3"></circle><path d="M10 2v2M10 16v2M2 10h2M16 10h2M4.3 4.3l1.4 1.4M14.3 14.3l1.4 1.4M15.7 4.3l-1.4 1.4M5.7 14.3l-1.4 1.4"></path></svg></button></div></div>"#);

    html.push_str(r#"<div class="workspace-canvas" id="workspace-canvas">"#);
    if has_work {
        html.push_str(r#"<div class="notebook-feed"><header class="notebook-header"><div><span>Notebook</span><h1>Notebook 01</h1></div><div><small>Session</small><strong>Local · exact-first</strong></div></header>"#);
        render_notebook_results(
            &mut html,
            last_result,
            last_error,
            last_physics,
            last_hunt,
            session,
        );
        html.push_str(r#"</div>"#);
        render_composer(&mut html, current_input, false);
    } else {
        render_start_surface(&mut html, current_input);
    }
    html.push_str(r#"</div>"#);
    render_console(&mut html, session);
    html.push_str(r#"</section>"#);

    render_inspector(
        &mut html, run_label, run_class, executor, assurance, session,
    );
    html.push_str(r#"</main>"#);
    html
}

fn render_explorer(html: &mut String, session: &Session) {
    html.push_str(r#"<aside class="explorer-pane"><header class="pane-header"><div><span>Workspace</span><small>Local project</small></div><button type="button" data-toggle-explorer aria-label="Close workspace">×</button></header><div class="explorer-body"><div class="project-card"><span class="project-mark">C26</span><span><strong>Untitled workspace</strong><small>Autosaved locally</small></span></div><section class="tree-group"><h2>Work</h2><button class="tree-row is-selected" type="button" data-focus-cell><span class="tree-icon notebook">N</span><span>Notebook 01</span><i></i></button><button class="tree-row" type="button" data-focus-cell><span class="tree-icon notebook">N</span><span>Scratch</span></button></section><section class="tree-group"><h2>Objects</h2><button class="tree-row" type="button" data-open-palette><span class="tree-icon data">D</span><span>Datasets</span><em>0</em></button><button class="tree-row" type="button" data-open-palette><span class="tree-icon model">M</span><span>Models</span><em>0</em></button><button class="tree-row" type="button" data-toggle-inspector><span class="tree-icon receipt">R</span><span>Receipts</span><em>"#);
    html.push_str(&session.history.len().to_string());
    html.push_str(r#"</em></button><button class="tree-row" type="button" data-open-palette><span class="tree-icon build">B</span><span>Extensions</span><em>0</em></button></section></div><footer class="explorer-footer"><span><i></i><span><strong>CentL26 Core</strong><small>Ready · local</small></span></span></footer></aside>"#);
}

fn render_start_surface(html: &mut String, current_input: &str) {
    html.push_str(r#"<section class="start-surface"><div class="start-mark">C26</div><p class="start-kicker">CentL26 workspace</p><h1>What are you working on?</h1><p class="start-copy">Begin with a question, an exact expression, a physical model, or a research task.</p>"#);
    render_composer(html, current_input, true);
    html.push_str(r#"<div class="starter-row"><span>Try</span><button type="button" data-fill="solve(x^2 - 5*x + 6 = 0, x)">Solve an equation</button><button type="button" data-fill="diff(x^3 * sin(x), x)">Differentiate</button><button type="button" data-fill="physics convert 100 cm m">Convert units</button><button type="button" data-fill="es solve 1009">Research probe</button></div><p class="start-shortcut"><kbd>⌘ K</kbd> opens every tool, file, and command</p></section>"#);
}

fn render_composer(html: &mut String, current_input: &str, prominent: bool) {
    let class = if prominent {
        "active-cell composer prominent-composer"
    } else {
        "active-cell composer docked-composer"
    };
    html.push_str(&format!(r#"<form method="POST" action="/run#notebook" data-centl-form class="{}"><input type="hidden" name="lab_action" value="calculate"><textarea name="cmd" id="active-command" rows="2" spellcheck="false" aria-label="CentL26 instruction" placeholder="Ask CentL26 or enter canonical input…">"#, class));
    html.push_str(&escape_html(current_input));
    html.push_str(r#"</textarea><div class="composer-footer"><div><button class="composer-mode" type="button" data-open-palette title="Choose a CentL26 tool"><span>Auto</span><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 8 3 3 3-3"></path></svg></button><button class="composer-clear" type="button" data-clear-session title="Clear notebook and start fresh">Clear</button></div><div><span class="run-hint">Ctrl ↵</span><button class="composer-run" type="submit" aria-label="Run computation"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5 8 5-8 5Z"></path></svg></button></div></div></form>"#);
}

fn render_console(html: &mut String, session: &Session) {
    html.push_str(r#"<section class="trace-console" aria-label="Execution trace"><header><strong>Trace</strong><button type="button" data-toggle-console aria-label="Close trace">×</button></header><div class="trace-lines" aria-live="polite"><p><span>core</span><b>ready</b>CentL26 local capability broker attached</p>"#);
    if let Some(entry) = session.history.last() {
        html.push_str(&format!(r#"<p><span>run</span><b class="trace-success">done</b><code>{}</code> admitted in {} µs</p>"#, escape_html(&entry.command), entry.execution_micros));
    } else {
        html.push_str(r#"<p><span>session</span><b>idle</b>Waiting for the first instruction</p>"#);
    }
    html.push_str(r#"</div></section>"#);
}

fn render_inspector(
    html: &mut String,
    run_label: &str,
    run_class: &str,
    executor: &str,
    assurance: &str,
    session: &Session,
) {
    html.push_str(r#"<aside class="inspector-pane"><header class="pane-header"><div><span>Context</span><small>Current selection</small></div><button type="button" data-toggle-inspector aria-label="Close inspector">×</button></header><div class="inspector-tabs" role="tablist" aria-label="Context views"><button class="is-active" type="button" role="tab" aria-selected="true" aria-controls="inspector-result" data-inspector-tab="result">Result</button><button type="button" role="tab" aria-selected="false" aria-controls="inspector-variables" data-inspector-tab="variables">Variables</button><button type="button" role="tab" aria-selected="false" aria-controls="inspector-evidence" data-inspector-tab="evidence">Evidence</button></div><div class="inspector-body"><section class="context-section" id="inspector-result" role="tabpanel" data-inspector-panel="result"><h2>Execution</h2><div class="run-state "#);
    html.push_str(run_class);
    html.push_str(r#""><i></i><span><small>Status</small><strong>"#);
    html.push_str(run_label);
    html.push_str(r#"</strong></span></div><dl class="context-list"><div><dt>Executor</dt><dd>"#);
    html.push_str(executor);
    html.push_str(r#"</dd></div><div><dt>Assurance</dt><dd>"#);
    html.push_str(assurance);
    html.push_str(r#"</dd></div><div><dt>Scope</dt><dd>Local only</dd></div></dl></section><section class="context-section" id="inspector-variables" role="tabpanel" data-inspector-panel="variables" hidden><h2>Symbols</h2><div class="symbol-list">"#);
    let mut variables: Vec<_> = session.variables.iter().collect();
    variables.sort_by(|(left, _), (right, _)| left.cmp(right));
    for (name, value) in variables.into_iter().take(8) {
        html.push_str(&format!(
            r#"<div><code>{}</code><span>{}</span></div>"#,
            escape_html(name),
            escape_html(&value.to_string())
        ));
    }
    html.push_str(r#"</div></section><section class="context-section" id="inspector-evidence" role="tabpanel" data-inspector-panel="evidence" hidden><h2>Recent receipts</h2><div class="receipt-list">"#);
    if session.history.is_empty() {
        html.push_str(r#"<p class="empty-context">Receipts appear after admitted work.</p>"#);
    } else {
        for (index, entry) in session.history.iter().rev().take(5).enumerate() {
            let kind = if entry.approximate_repr.is_some() {
                "bounded"
            } else {
                "exact"
            };
            html.push_str(&format!(r#"<button type="button" data-command="{}" title="Run again"><span>{:02}</span><span><strong>{}</strong><small>{} · {} µs</small></span></button>"#, escape_html(&entry.command), session.history.len().saturating_sub(index), escape_html(&entry.command), kind, entry.execution_micros));
        }
    }
    html.push_str(r#"</div><div class="assurance-note"><span>◇</span><p><strong>Honesty is structural.</strong> Unsupported work stays visible; bounded results never masquerade as exact values.</p></div></section></div></aside>"#);
}

fn render_notebook_results(
    html: &mut String,
    last_result: Option<&ExecutionResult>,
    last_error: Option<&str>,
    last_physics: Option<&PhysicsResult>,
    last_hunt: Option<&HuntSummary>,
    session: &Session,
) {
    for (index, entry) in session.history.iter().enumerate() {
        let kind = if entry.approximate_repr.is_some() {
            "Bounded"
        } else {
            "Exact"
        };
        html.push_str(&format!(r#"<article class="result-cell"><div class="cell-index"><span>[{}]</span><button type="button" data-command="{}" title="Run again" aria-label="Run cell {} again"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5 8 5-8 5Z"></path></svg></button></div><div class="cell-content"><div class="source-line"><code>{}</code></div><div class="result-output"><header><span>Result</span><div><small class="kind-{}">{}</small><small>{} µs</small></div></header><pre>{}</pre>"#, index + 1, escape_html(&entry.command), index + 1, escape_html(&entry.command), kind.to_lowercase(), kind, entry.execution_micros, escape_html(&entry.result)));
        if let Some(enclosure) = &entry.approximate_repr {
            html.push_str(&format!(
                r#"<p class="enclosure-line"><span>≈</span>{}</p>"#,
                escape_html(enclosure)
            ));
        }
        html.push_str(r#"</div></div></article>"#);
    }

    if let Some(error) = last_error {
        html.push_str(&format!(r#"<article class="system-result error-result"><span class="system-icon">!</span><div><small>Not admitted</small><h3>Review the instruction</h3><pre>{}</pre><p>No result or certainty claim was created.</p></div></article>"#, escape_html(error)));
    } else if let Some(physics) = last_physics {
        html.push_str(&format!(r#"<article class="system-result physics-result"><span class="system-icon">Δ</span><div><small>Typed physics result</small><h3>{}</h3><table>"#, escape_html(&physics.title)));
        for (key, value) in &physics.details {
            html.push_str(&format!(
                r#"<tr><th>{}</th><td>{}</td></tr>"#,
                escape_html(key),
                escape_html(value)
            ));
        }
        html.push_str(&format!(
            r#"</table><p class="system-summary"><strong>Result</strong>{}</p></div></article>"#,
            escape_html(&physics.summary)
        ));
    } else if let Some(hunt) = last_hunt {
        html.push_str(&format!(r#"<article class="system-result research-result"><span class="system-icon">p</span><div><small>Research kernel</small><h3>Window ({}, {}]</h3><div class="metric-row"><span><strong>{}</strong>primes</span><span><strong>{}</strong>great</span><span><strong>{}</strong>good</span><span><strong>{}</strong>letters</span><span><strong>{}</strong>unsolved</span></div></div></article>"#, hunt.start_bound, hunt.end_bound, hunt.primes_checked, hunt.great_count, hunt.good_count, hunt.letter_count, hunt.unsolved_count));
    } else if session.history.is_empty() && last_result.is_some() {
        if let Some(result) = last_result {
            html.push_str(&format!(r#"<article class="system-result exact-result"><span class="system-icon">=</span><div><small>CentL26 result</small><h3>{}</h3><p>{} µs · admitted</p></div></article>"#, escape_html(&result.text), result.execution_micros));
        }
    }
}

fn run_metadata(
    result: Option<&ExecutionResult>,
    error: Option<&str>,
    physics: Option<&PhysicsResult>,
    hunt: Option<&HuntSummary>,
    command: Option<&str>,
) -> (&'static str, &'static str, &'static str, &'static str) {
    if error.is_some() {
        (
            "Needs review",
            "is-error",
            "No result admitted",
            "Unresolved",
        )
    } else if physics.is_some() {
        ("Complete", "is-physics", "CENTL Physics", "Deterministic")
    } else if hunt.is_some() {
        (
            "Complete",
            "is-research",
            "Research kernel",
            "Bounded search",
        )
    } else if result.is_some()
        && command.is_some_and(|value| {
            value == "chem"
                || value == "chemistry"
                || value.starts_with("chem ")
                || value.starts_with("chemistry ")
        })
    {
        (
            "Ready",
            "is-exact",
            "CENTL Chemistry",
            "Exact conservation",
        )
    } else if result.is_some_and(|value| value.approximate.is_some()) {
        ("Ready", "is-bounded", "Numerical core", "Rigorous bound")
    } else if result.is_some() {
        ("Ready", "is-exact", "Exact core", "Exact / symbolic")
    } else {
        ("Ready", "is-idle", "Capability broker", "Not evaluated")
    }
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

    #[test]
    fn centl26_is_quiet_offline_and_work_focused() {
        let session = Session::new();
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);
        assert!(html.contains("What are you working on?"));
        assert!(html.contains("hide-explorer hide-inspector hide-console"));
        assert!(html.contains("CentL26"));
        assert!(html.contains("Free Computation Foundation"));
        assert!(!html.contains("https://"));
    }

    #[test]
    fn command_palette_reaches_each_current_execution_kernel() {
        let session = Session::new();
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);
        assert!(html.contains("diff(x^3 * sin(x), x)"));
        assert!(html.contains("physics convert 100 cm m"));
        assert!(html.contains("es solve 1009"));
        assert!(html.contains("approx(pi, 50)"));
    }

    #[test]
    fn capability_registry_distinguishes_available_from_planned_work() {
        assert!(CAPABILITY_REGISTRY.contains("org.fcf.centl.math.evaluate"));
        assert!(CAPABILITY_REGISTRY.contains("org.fcf.centl.physics.compute"));
        assert!(CAPABILITY_REGISTRY.contains("org.fcf.centl.chemistry.compute"));
        assert!(CAPABILITY_REGISTRY.contains("integration-planned"));
        assert!(CAPABILITY_REGISTRY.contains("Free Computation Foundation"));
    }

    #[test]
    fn chemistry_results_keep_their_authoritative_executor_identity() {
        use crate::engine::HistoryEntry;

        let result = ExecutionResult {
            text: "4 Fe + 3 O2 → 2 Fe2O3".to_string(),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 12,
        };
        let mut session = Session::new();
        session.history.push(HistoryEntry {
            command: "chem balance Fe + O2 -> Fe2O3".to_string(),
            result: result.text.clone(),
            exact_repr: Some("{\"verified\":true}".to_string()),
            approximate_repr: None,
            execution_micros: 12,
            success: true,
        });
        let html = render_lab_workbench("", Some(&result), None, None, None, &session);
        assert!(html.contains("CENTL Chemistry"));
        assert!(html.contains("Exact conservation"));
        assert!(!html.contains("Exact core</dd>"));
    }

    #[test]
    fn symbol_inspector_order_is_deterministic() {
        let session = Session::new();
        let html = render_lab_workbench("", None, None, None, None, &session);
        let e = html.find("<code>e</code>").unwrap();
        let pi = html.find("<code>pi</code>").unwrap();
        let tau = html.find("<code>tau</code>").unwrap();
        assert!(e < pi && pi < tau);
    }
}
