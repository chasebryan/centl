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
        <span><strong>CentL26</strong><small>Free Computation Foundation</small><small class="product-version">v26.4</small></span>
      </a>
      <div class="workspace-path"><button type="button" data-toggle-explorer title="Toggle workspace explorer">Untitled workspace</button><span>/</span><strong>Notebook 01</strong></div>
      <button class="command-center" type="button" data-open-palette><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="8.5" cy="8.5" r="5.5"></circle><path d="m13 13 4 4"></path></svg><span>Search commands and tools</span><kbd>⌘ K</kbd></button>
      <div class="app-actions">
        <span class="kernel-state"><i></i><span><strong>Ready</strong><small>v26.4</small></span></span>
        <button class="quiet-action" type="button" data-toggle-inspector title="Toggle context inspector" aria-label="Toggle context inspector"><svg viewBox="0 0 20 20" aria-hidden="true"><rect x="3" y="3" width="14" height="14" rx="2"></rect><path d="M12 3v14"></path></svg></button>
        <button class="run-action" type="button" data-run-active><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5 8 5-8 5Z"></path></svg><span>Run</span></button>
      </div>
    </header>

    <div class="app-body">
      <nav class="activity-rail" aria-label="CentL26 areas">
        <div>
          <button class="rail-button is-active" type="button" data-select-area="work" data-label="Work" aria-label="Work" aria-controls="explorer-area-work" aria-current="page" aria-pressed="true"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 4h12v12H4z"></path><path d="M7 8h6M7 11h4"></path></svg></button>
          <button class="rail-button" type="button" data-select-area="projects" data-label="Projects" aria-label="Projects" aria-controls="explorer-area-projects" aria-pressed="false"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M3 5h5l2 2h7v9H3z"></path></svg></button>
          <button class="rail-button" type="button" data-select-area="tools" data-label="Tools" aria-label="Tools" aria-controls="explorer-area-tools" aria-pressed="false"><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="10" cy="10" r="6"></circle><path d="M10 6v8M6 10h8"></path></svg></button>
          <button class="rail-button" type="button" data-select-area="data" data-label="Data" aria-label="Data" aria-controls="explorer-area-data" aria-pressed="false"><svg viewBox="0 0 20 20" aria-hidden="true"><ellipse cx="10" cy="5" rx="6" ry="2.5"></ellipse><path d="M4 5v5c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5V5M4 10v5c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5v-5"></path></svg></button>
          <button class="rail-button" type="button" data-select-area="models" data-label="Models" aria-label="Models" aria-controls="explorer-area-models" aria-pressed="false"><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="10" cy="10" r="2"></circle><ellipse cx="10" cy="10" rx="8" ry="3.5"></ellipse><ellipse cx="10" cy="10" rx="3.5" ry="8" transform="rotate(45 10 10)"></ellipse></svg></button>
          <button class="rail-button" type="button" data-select-area="research" data-label="Research" aria-label="Research" aria-controls="explorer-area-research" aria-pressed="false"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M7 3h6M8 3v5l-4 7c-.5 1 .1 2 1.3 2h9.4c1.2 0 1.8-1 1.3-2l-4-7V3"></path><path d="M6.5 13h7"></path></svg></button>
          <button class="rail-button" type="button" data-select-area="build" data-label="Build" aria-label="Build" aria-controls="explorer-area-build" aria-pressed="false"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5-4 5 4 5M13 5l4 5-4 5M11.5 3 8.5 17"></path></svg></button>
        </div>
        <div>
          <button class="rail-button" type="button" data-toggle-console data-label="Trace" aria-label="Trace"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m4 6 4 4-4 4M10 15h6"></path></svg></button>
          <button class="rail-button fcf-about-button" type="button" data-open-fcf-about aria-label="About Free Computation Foundation">FCF</button>
        </div>
      </nav>
      {workbench}
    </div>

    <footer class="status-bar">
      <span><i></i>v26.4</span>
      <span class="status-spacer"></span>
      <span>Exact · Local</span>
      <button class="status-update" type="button" data-update title="Check for CentL26 updates">Update</button>
      <span class="fcf-status" title="Free Computation Foundation">FCF</span>
    </footer>
  </div>

  <div class="command-palette" hidden>
    <div class="palette-dialog" role="dialog" aria-modal="true" aria-labelledby="palette-label">
      <h2 class="sr-only" id="palette-label">CentL26 commands</h2>
      <div class="palette-search"><svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="8.5" cy="8.5" r="5.5"></circle><path d="m13 13 4 4"></path></svg><input id="palette-search" role="combobox" aria-label="Search CentL26 commands" aria-autocomplete="list" aria-controls="palette-results" aria-expanded="true" placeholder="Search supported tools and commands…" autocomplete="off"><kbd>esc</kbd></div>
      <div class="palette-results" id="palette-results" role="listbox" aria-label="Available commands">
        <p>Suggested tools</p>
        <button type="button" role="option" tabindex="-1" data-command="1/3 + 5/7" data-modes="math" data-requires-capability="org.fcf.centl.math.evaluate"><span class="palette-icon exact">ℚ</span><span><strong>Exact calculation</strong><small>Arbitrary-precision mathematics</small></span><kbd>Math</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="solve(x^2 - 5*x + 6 = 0, x)" data-modes="math" data-requires-capability="org.fcf.centl.math.symbolic"><span class="palette-icon symbolic">x</span><span><strong>Solve an equation</strong><small>Symbolic algebra</small></span><kbd>Math</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="diff(x^3 * sin(x), x)" data-modes="math" data-requires-capability="org.fcf.centl.math.symbolic"><span class="palette-icon symbolic">∂</span><span><strong>Differentiate</strong><small>Symbolic calculus</small></span><kbd>Math</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="approx(pi, 50)" data-modes="math" data-requires-capability="org.fcf.centl.numerics.enclose"><span class="palette-icon bounded">≈</span><span><strong>Rigorous enclosure</strong><small>Justified numerical precision</small></span><kbd>Math</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="physics convert 100 cm m" data-modes="physics" data-requires-capability="org.fcf.centl.physics.compute"><span class="palette-icon physics">Δ</span><span><strong>Physics workbench</strong><small>Typed quantities and mechanics</small></span><kbd>Physics</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="es solve 1009" data-modes="research" data-requires-capability="org.fcf.centl.research.erdos_straus"><span class="palette-icon research">p</span><span><strong>Research kernel</strong><small>Erdős–Straus exact probe</small></span><kbd>Research</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="chem atoms Ca(OH)2" data-modes="chemistry" data-requires-capability="org.fcf.centl.chemistry.compute"><span class="palette-icon exact">Σ</span><span><strong>Exact chemistry</strong><small>Count atoms with the qualified adapter</small></span><kbd>Chemistry</kbd></button>
        <p>Workspace</p>
        <button type="button" role="option" tabindex="-1" data-palette-action="run-input" data-modes="all" hidden><span class="palette-icon neutral">›</span><span><strong>Run entered command</strong><small data-run-input-preview></small></span><kbd>Enter</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="toggle-theme" data-modes="all"><span class="palette-icon neutral">◑</span><span><strong>Toggle dimmed theme</strong><small>Switch between standard and dim color palettes</small></span><kbd>Theme</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="download-examples" data-modes="all"><span class="palette-icon neutral">↓</span><span><strong>Download STEM Examples</strong><small>Complete CSV spreadsheet for chemistry, physics, math</small></span><kbd>CSV</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="new-computation" data-modes="all"><span class="palette-icon neutral">＋</span><span><strong>New computation</strong><small>Clear the draft; preserve notebook history</small></span><kbd>New</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="download-notebook" data-modes="all"><span class="palette-icon neutral">↓</span><span><strong>Download notebook</strong><small>Save current notebook as Markdown</small></span><kbd>Save</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="inspector" data-modes="all"><span class="palette-icon neutral">◇</span><span><strong>Toggle inspector</strong><small>Evidence, variables, and receipts</small></span><kbd>View</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="console" data-modes="all"><span class="palette-icon neutral">›_</span><span><strong>Toggle execution trace</strong><small>Latest local execution status</small></span><kbd>View</kbd></button>
        <button type="button" role="option" tabindex="-1" data-command="build fn KE(m, v) = 1/2 * m * v^2" data-modes="build"><span class="palette-icon exact">b</span><span><strong>In-App Programmability</strong><small>Define custom functions and extensions</small></span><kbd>Build</kbd></button>
        <button type="button" role="option" tabindex="-1" data-palette-action="area-build" data-modes="build"><span class="palette-icon neutral">B</span><span><strong>Open Build status</strong><small>Inspect registered development capabilities</small></span><kbd>Build</kbd></button>
      </div>
    </div>
  </div>

  <div class="fcf-about-modal" hidden>
    <div class="fcf-about-dialog" role="dialog" aria-modal="true" aria-label="About Free Computation Foundation">
      <h2>Free Computation Foundation</h2>
      <p><em>Good maths should be free.</em></p>
      <p>CentL26 is the flagship offline scientific computing environment. Exact rational arithmetic, symbolic algebra, physics, chemistry, and native plain-English STEM intelligence — all running locally on your machine.</p>
      <div class="fcf-about-links">
        <a href="https://freecomputation.org/" target="_blank" rel="noopener">🔗 freecomputation.org</a>
        <a href="https://github.com/sponsors/chasebryan" target="_blank" rel="noopener">💝 Sponsor on GitHub</a>
      </div>
      <footer><span>v26.4 · Apache-2.0</span><button type="button" data-close-fcf-about>Close</button></footer>
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
    render_lab_workbench_with_transient_result(
        current_input,
        last_result,
        last_error,
        last_physics,
        last_hunt,
        false,
        session,
    )
}

pub(crate) fn render_lab_workbench_with_transient_result(
    current_input: &str,
    last_result: Option<&ExecutionResult>,
    last_error: Option<&str>,
    last_physics: Option<&PhysicsResult>,
    last_hunt: Option<&HuntSummary>,
    show_transient_result: bool,
    session: &Session,
) -> String {
    let history_command = if show_transient_result {
        None
    } else {
        session.history.last().map(|entry| entry.command.as_str())
    };
    let history_is_bounded = !show_transient_result
        && session
            .history
            .last()
            .is_some_and(|entry| entry.approximate_repr.is_some());
    let (run_label, run_class, executor, assurance) = run_metadata(
        last_result,
        last_error,
        last_physics,
        last_hunt,
        history_command,
        history_is_bounded,
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
    html.push_str(r#"<div class="workspace-toolbar"><div><button class="toolbar-button" type="button" data-new-computation title="Start a blank computation without clearing notebook history"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M10 4v12M4 10h12"></path></svg>New computation</button><button class="toolbar-button" type="button" data-open-palette><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 5h12M4 10h12M4 15h8"></path></svg>Tools</button></div><div><label class="mode-control"><span>Mode</span><select aria-label="CentL26 interaction mode"><option>Auto</option><option>Math</option><option>Physics</option><option>Research</option><option>Build</option></select></label><button class="toolbar-icon theme-toggle" type="button" data-toggle-theme title="Toggle dimmed theme" aria-label="Toggle dimmed theme"><svg class="theme-icon-sun" viewBox="0 0 20 20" aria-hidden="true"><circle cx="10" cy="10" r="3"></circle><path d="M10 2v2M10 16v2M2 10h2M16 10h2M4.3 4.3l1.4 1.4M14.3 14.3l1.4 1.4M15.7 4.3l-1.4 1.4M5.7 14.3l-1.4 1.4"></path></svg><svg class="theme-icon-moon" viewBox="0 0 20 20" aria-hidden="true"><path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path></svg></button></div></div>"#);

    html.push_str(r#"<div class="workspace-canvas" id="workspace-canvas">"#);
    if has_work {
        html.push_str(r#"<div class="notebook-feed"><header class="notebook-header"><div><span>Notebook</span><h1>Notebook 01</h1></div><div><small>Session</small><strong>Exact · Offline</strong></div></header>"#);
        render_notebook_results(
            &mut html,
            last_result,
            last_error,
            last_physics,
            last_hunt,
            show_transient_result,
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
    let run_count = session.history.len();
    let research_runs = session
        .history
        .iter()
        .filter(|entry| command_is_family(&entry.command, &["es", "erdos"]))
        .count();
    let authored_symbols = session.variables.len().saturating_sub(3);

    html.push_str(r#"<aside class="explorer-pane" data-capabilities-endpoint="/api/capabilities" data-workspace-endpoint="/api/workspace"><header class="pane-header"><div><span data-area-title>Work</span><small data-area-subtitle>Local project</small></div><button type="button" data-toggle-explorer aria-label="Close workspace">×</button></header><div class="explorer-body">"#);

    html.push_str(r#"<section class="explorer-area" id="explorer-area-work" data-area-panel="work" data-area-title="Work" data-area-subtitle="Local project"><div class="project-card"><span class="project-mark">C26</span><span><strong data-workspace-field="project.name">Untitled workspace</strong><small>Autosaved locally</small></span></div><div class="area-metrics"><span><strong data-workspace-field="counts.notebooks">1</strong>notebook</span><span><strong data-workspace-field="counts.receipts">"#);
    html.push_str(&run_count.to_string());
    html.push_str(r#"</strong>receipts</span><span><strong>"#);
    html.push_str(&authored_symbols.to_string());
    html.push_str(r#"</strong>symbols</span></div><section class="tree-group"><h2>Current work</h2><button class="tree-row is-selected" type="button" data-focus-cell><span class="tree-icon notebook">N</span><span>Notebook 01</span><em>"#);
    html.push_str(&run_count.to_string());
    html.push_str(r#"</em></button><button class="tree-row" type="button" data-select-area="data"><span class="tree-icon dataset">D</span><span>Datasets</span><em data-workspace-field="counts.datasets">0</em></button><button class="tree-row" type="button" data-select-area="models"><span class="tree-icon model">M</span><span>Models</span><em data-workspace-field="counts.models">0</em></button><button class="tree-row" type="button" data-select-area="build"><span class="tree-icon build">B</span><span>Extensions</span><em data-workspace-field="counts.extensions">0</em></button><button class="tree-row" type="button" data-open-evidence><span class="tree-icon receipt">R</span><span>Receipts</span><em data-workspace-field="counts.receipts">"#);
    html.push_str(&run_count.to_string());
    html.push_str(r#"</em></button></section></section>"#);

    html.push_str(r#"<section class="explorer-area" id="explorer-area-projects" data-area-panel="projects" data-area-title="Projects" data-area-subtitle="Local storage" hidden><p class="area-summary">This build owns one durable local project. Project switching and import are not registered yet.</p><section class="tree-group"><h2>Open project</h2><button class="tree-row is-selected" type="button" data-select-area="work"><span class="tree-icon notebook">C</span><span data-workspace-field="project.name">Untitled workspace</span><i></i></button></section>"#);
    render_capability_row(html, "org.fcf.centl.project.persist", "Project persistence");
    html.push_str(r#"</section>"#);

    html.push_str(r#"<section class="explorer-area" id="explorer-area-tools" data-area-panel="tools" data-area-title="Tools" data-area-subtitle="Registered capabilities" hidden><p class="area-summary">Only registered execution capabilities are shown as available.</p><div class="capability-list">"#);
    for (id, label) in [
        ("org.fcf.centl.math.evaluate", "Exact mathematics"),
        ("org.fcf.centl.math.symbolic", "Symbolic algebra"),
        ("org.fcf.centl.numerics.enclose", "Rigorous numerics"),
        ("org.fcf.centl.physics.compute", "Typed physics"),
        ("org.fcf.centl.chemistry.compute", "Exact chemistry"),
    ] {
        render_capability_row(html, id, label);
    }
    html.push_str(r#"</div><button class="area-action" type="button" data-open-palette>Open supported commands</button></section>"#);

    html.push_str(r#"<section class="explorer-area" id="explorer-area-data" data-area-panel="data" data-area-title="Data" data-area-subtitle="Project datasets" hidden><div class="area-metrics"><span><strong data-workspace-field="counts.datasets">0</strong>datasets</span></div><p class="area-summary">No dataset object service is registered in this build. Reference STEM example catalogs and templates remain available to download.</p><section class="tree-group"><h2>Reference sheets</h2><a class="tree-row" href="/download/centl26-examples.csv" download="centl26-examples.csv"><span class="tree-icon dataset">CSV</span><span>Download 50+ STEM Examples Sheet</span></a></section><div class="capability-list">"#);
    render_capability_row(html, "org.fcf.centl.data.manage", "Dataset objects");
    html.push_str(r#"</div></section>"#);

    html.push_str(r#"<section class="explorer-area" id="explorer-area-models" data-area-panel="models" data-area-title="Models" data-area-subtitle="Scientific interpretation" hidden><div class="area-metrics"><span><strong data-workspace-field="counts.models">1</strong>model</span></div><p class="area-summary">Native offline SCi problem solver is active across chemistry, mechanics, electromagnetism, quantum physics, thermodynamics, geometry, vectors, number theory, and statistics.</p><div class="capability-list">"#);
    render_capability_row(html, "org.fcf.centl.sci.interpret", "SCi interpreter");
    html.push_str(r#"</div></section>"#);

    html.push_str(r#"<section class="explorer-area" id="explorer-area-research" data-area-panel="research" data-area-title="Research" data-area-subtitle="Bounded kernels" hidden><div class="area-metrics"><span><strong>"#);
    html.push_str(&research_runs.to_string());
    html.push_str(r#"</strong>research runs</span></div><p class="area-summary">The registered Erdős–Straus kernel performs bounded, deterministic probes.</p><div class="capability-list">"#);
    render_capability_row(
        html,
        "org.fcf.centl.research.erdos_straus",
        "Erdős–Straus kernel",
    );
    html.push_str(r#"</div><section class="tree-group"><h2>Start from a supported command</h2><button class="tree-row" type="button" data-select-area="work" data-fill="es solve 1009" data-interaction-mode="Research"><span class="tree-icon receipt">p</span><span>Probe prime 1009</span></button><button class="tree-row" type="button" data-select-area="work" data-fill="es hunt 20000" data-interaction-mode="Research"><span class="tree-icon receipt">p</span><span>Hunt from 20000</span></button></section></section>"#);

    html.push_str(r#"<section class="explorer-area" id="explorer-area-build" data-area-panel="build" data-area-title="Build" data-area-subtitle="Extension workbench" hidden><div class="area-metrics"><span><strong data-workspace-field="counts.extensions">0</strong>extensions</span></div><p class="area-summary">In-app programmability is active. Users can define custom formulas, constants, units, and macros with deterministic execution.</p><div class="capability-list">"#);
    render_capability_row(html, "org.fcf.centl.build.extend", "In-app programmability");
    html.push_str(r#"</div><section class="tree-group"><h2>Start from a custom program</h2><button class="tree-row" type="button" data-select-area="work" data-fill="build fn KE(m, v) = 1/2 * m * v^2" data-interaction-mode="Build"><span class="tree-icon receipt">b</span><span>Define kinetic energy</span></button><button class="tree-row" type="button" data-select-area="work" data-fill="build list" data-interaction-mode="Build"><span class="tree-icon receipt">b</span><span>List user extensions</span></button></section></section></div><footer class="explorer-footer"><span><i></i><span><strong>CentL26 Core</strong><small>Ready · v26.4</small></span></span></footer></aside>"#);
}

fn command_is_family(command: &str, families: &[&str]) -> bool {
    let command = command.trim();
    families.iter().any(|family| {
        command == *family
            || command
                .strip_prefix(family)
                .is_some_and(|rest| rest.starts_with(char::is_whitespace))
    })
}

fn render_capability_row(html: &mut String, capability_id: &str, label: &str) {
    let (status, provider) = capability_details(capability_id);
    html.push_str(&format!(
        r#"<div class="capability-row" data-capability-id="{}" data-status="{}"><span><strong>{}</strong><small data-capability-provider>{}</small></span><em data-capability-status>{}</em></div>"#,
        escape_html(capability_id),
        escape_html(&status),
        escape_html(label),
        escape_html(&provider),
        escape_html(&display_status(&status))
    ));
}

fn capability_details(capability_id: &str) -> (String, String) {
    serde_json::from_str::<serde_json::Value>(CAPABILITY_REGISTRY)
        .ok()
        .and_then(|registry| {
            registry
                .get("capabilities")?
                .as_array()?
                .iter()
                .find(|capability| {
                    capability
                        .get("id")
                        .and_then(serde_json::Value::as_str)
                        .is_some_and(|id| id == capability_id)
                })
                .map(|capability| {
                    (
                        capability
                            .get("status")
                            .and_then(serde_json::Value::as_str)
                            .unwrap_or("unavailable")
                            .to_string(),
                        capability
                            .get("provider")
                            .and_then(serde_json::Value::as_str)
                            .unwrap_or("Not registered")
                            .to_string(),
                    )
                })
        })
        .unwrap_or_else(|| ("unavailable".to_string(), "Not registered".to_string()))
}

fn display_status(status: &str) -> String {
    let normalized = status.replace('-', " ");
    let mut characters = normalized.chars();
    match characters.next() {
        Some(first) => first.to_uppercase().collect::<String>() + characters.as_str(),
        None => "Unavailable".to_string(),
    }
}

fn render_start_surface(html: &mut String, current_input: &str) {
    html.push_str(r#"<section class="start-surface"><div class="start-mark">C26</div><p class="start-kicker">CentL26 workspace</p><h1>What are you working on?</h1><p class="start-copy">Enter a supported expression or choose a qualified scientific tool.</p>"#);
    render_composer(html, current_input, true);
    html.push_str(r#"<div class="starter-row"><span>Try</span><button type="button" data-fill="solve(x^2 - 5*x + 6 = 0, x)" data-interaction-mode="Math">Solve an equation</button><button type="button" data-fill="diff(x^3 * sin(x), x)" data-interaction-mode="Math">Differentiate</button><button type="button" data-fill="physics convert 100 cm m" data-interaction-mode="Physics">Convert units</button><button type="button" data-fill="es solve 1009" data-interaction-mode="Research">Research probe</button></div><p class="start-shortcut"><kbd>⌘ K</kbd> opens supported tools and commands</p></section>"#);
}

fn render_composer(html: &mut String, current_input: &str, prominent: bool) {
    let class = if prominent {
        "active-cell composer prominent-composer"
    } else {
        "active-cell composer docked-composer"
    };
    html.push_str(&format!(r#"<form method="POST" action="/run#notebook" data-centl-form class="{}"><input type="hidden" name="lab_action" value="calculate"><input type="hidden" name="interaction_mode" value="Auto"><textarea name="cmd" id="active-command" rows="2" spellcheck="false" aria-label="CentL26 expression or command" placeholder="Enter a supported expression or command…">"#, class));
    html.push_str(&escape_html(current_input));
    html.push_str(r#"</textarea><div class="composer-footer"><div><button class="composer-mode" type="button" data-open-palette title="Open tools for Auto mode" aria-label="Open tools for Auto mode"><span>Auto tools</span><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 8 3 3 3-3"></path></svg></button><button class="composer-clear" type="button" data-clear-session title="Clear notebook history and saved receipts" aria-label="Clear notebook history and saved receipts">Clear</button></div><div><span class="run-hint">Ctrl/⌘ ↵</span><button class="composer-run" type="submit" aria-label="Run computation"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5 8 5-8 5Z"></path></svg></button></div></div></form>"#);
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
            let (kind, _) = history_kind(entry);
            let receipt_number = session.history.len().saturating_sub(index);
            html.push_str(&format!(r#"<button type="button" data-receipt-target="receipt-detail-{}" title="Inspect preserved evidence" aria-controls="receipt-detail-{}" aria-expanded="{}"{}><span>{:02}</span><span><strong>{}</strong><small>{} · {} µs</small></span></button>"#, receipt_number, receipt_number, index == 0, if index == 0 { r#" class="is-selected""# } else { "" }, receipt_number, escape_html(&entry.command), kind, entry.execution_micros));
        }
    }
    html.push_str(r#"</div><div class="receipt-details">"#);
    for (index, entry) in session.history.iter().rev().take(5).enumerate() {
        let receipt_number = session.history.len().saturating_sub(index);
        let (kind, _) = history_kind(entry);
        html.push_str(&format!(r#"<section class="receipt-detail" id="receipt-detail-{}" data-receipt-detail="receipt-detail-{}"{}><header><strong>Receipt {:02}</strong><small>{} · {} µs</small></header><h3>Command</h3><code>{}</code><h3>Result</h3><pre>{}</pre><h3>Preserved evidence</h3>"#, receipt_number, receipt_number, if index == 0 { "" } else { " hidden" }, receipt_number, kind, entry.execution_micros, escape_html(&entry.command), escape_html(&entry.result)));
        match (&entry.exact_repr, &entry.approximate_repr) {
            (Some(exact), Some(approximate)) => {
                html.push_str(&format!(
                    r#"<pre>{}</pre><p class="receipt-enclosure"><strong>Enclosure</strong>{}</p>"#,
                    escape_html(exact),
                    escape_html(approximate)
                ));
            }
            (Some(exact), None) => {
                html.push_str(&format!(r#"<pre>{}</pre>"#, escape_html(exact)));
            }
            (None, Some(approximate)) => {
                html.push_str(&format!(
                    r#"<p class="receipt-enclosure"><strong>Enclosure</strong>{}</p>"#,
                    escape_html(approximate)
                ));
            }
            (None, None) => html.push_str(
                r#"<p class="empty-context">No structured evidence payload was preserved for this run.</p>"#,
            ),
        }
        html.push_str(r#"</section>"#);
    }
    html.push_str(r#"</div><div class="assurance-note"><span>◇</span><p><strong>Honesty is structural.</strong> Unsupported work stays visible; bounded results never masquerade as exact values.</p></div></section></div></aside>"#);
}

fn render_notebook_results(
    html: &mut String,
    last_result: Option<&ExecutionResult>,
    last_error: Option<&str>,
    last_physics: Option<&PhysicsResult>,
    last_hunt: Option<&HuntSummary>,
    show_transient_result: bool,
    session: &Session,
) {
    let suppress_latest_history_cell = session.history.last().is_some_and(|entry| {
        (last_physics.is_some() && command_is_family(&entry.command, &["physics"]))
            || (last_hunt.is_some() && command_is_family(&entry.command, &["es", "erdos"]))
    });
    let visible_history_len = session
        .history
        .len()
        .saturating_sub(usize::from(suppress_latest_history_cell));
    for (index, entry) in session.history.iter().take(visible_history_len).enumerate() {
        let (kind, kind_class) = history_kind(entry);
        html.push_str(&format!(r#"<article class="result-cell"><div class="cell-index"><span>[{}]</span><button type="button" data-command="{}" data-command-mode="Auto" title="Run again" aria-label="Run cell {} again"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7 5 8 5-8 5Z"></path></svg></button></div><div class="cell-content"><div class="source-line"><code>{}</code></div><div class="result-output"><header><span>Result</span><div><small class="kind-{}">{}</small><small>{} µs</small></div></header><pre>{}</pre>"#, index + 1, escape_html(&entry.command), index + 1, escape_html(&entry.command), kind_class, kind, entry.execution_micros, escape_html(&entry.result)));
        if let Some(enclosure) = &entry.approximate_repr {
            if !result_already_displays_enclosure(&entry.result, enclosure) {
                html.push_str(&format!(
                    r#"<p class="enclosure-line"><span>≈</span>{}</p>"#,
                    escape_html(enclosure)
                ));
            }
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
    } else if (show_transient_result || session.history.is_empty()) && last_result.is_some() {
        if let Some(result) = last_result {
            let (label, disposition) = if show_transient_result {
                ("CentL26 information", "informational")
            } else {
                ("CentL26 result", "admitted")
            };
            html.push_str(&format!(r#"<article class="system-result exact-result"><span class="system-icon">=</span><div><small>{}</small><h3>{}</h3><p>{} µs · {}</p></div></article>"#, label, escape_html(&result.text), result.execution_micros, disposition));
        }
    }
}

fn run_metadata(
    result: Option<&ExecutionResult>,
    error: Option<&str>,
    physics: Option<&PhysicsResult>,
    hunt: Option<&HuntSummary>,
    command: Option<&str>,
    history_is_bounded: bool,
) -> (&'static str, &'static str, &'static str, &'static str) {
    if error.is_some() {
        (
            "Needs review",
            "is-error",
            "No result admitted",
            "Unresolved",
        )
    } else if physics.is_some()
        || command.is_some_and(|value| command_is_family(value, &["physics"]))
    {
        ("Complete", "is-physics", "CENTL Physics", "Deterministic")
    } else if hunt.is_some()
        || command.is_some_and(|value| command_is_family(value, &["es", "erdos"]))
    {
        (
            "Complete",
            "is-research",
            "Research kernel",
            "Bounded search",
        )
    } else if command.is_some_and(|value| command_is_family(value, &["chem", "chemistry"])) {
        ("Ready", "is-exact", "CENTL Chemistry", "Exact conservation")
    } else if result.is_some_and(|value| value.approximate.is_some()) || history_is_bounded {
        ("Ready", "is-bounded", "Numerical core", "Rigorous bound")
    } else if result.is_some() || command.is_some() {
        ("Ready", "is-exact", "Exact core", "Exact / symbolic")
    } else {
        ("Ready", "is-idle", "Capability broker", "Not evaluated")
    }
}

fn history_kind(entry: &crate::engine::HistoryEntry) -> (&'static str, &'static str) {
    if command_is_family(&entry.command, &["physics"]) {
        ("Physics", "physics")
    } else if command_is_family(&entry.command, &["es", "erdos"]) {
        ("Research", "research")
    } else if command_is_family(&entry.command, &["chem", "chemistry"]) {
        ("Chemistry", "chemistry")
    } else if entry.approximate_repr.is_some() {
        ("Bounded", "bounded")
    } else {
        ("Exact", "exact")
    }
}

fn result_already_displays_enclosure(result: &str, enclosure: &str) -> bool {
    let result = result.trim();
    let result = result.strip_prefix('≈').map(str::trim).unwrap_or(result);
    result == enclosure.trim()
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
        assert!(!html.contains("<script src=\"http"));
        assert!(!html.contains("<link rel=\"stylesheet\" href=\"http"));
        assert!(html.contains("freecomputation.org"));
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
        assert!(html.contains("chem atoms Ca(OH)2"));
        assert!(LAB_JS.contains("const exactPresetCommand"));
        assert!(LAB_JS.contains("const prioritizeRunInput"));
        assert!(LAB_CSS.contains(".palette-results > button[hidden] { display: none; }"));
    }

    #[test]
    fn every_product_area_has_a_distinct_honest_explorer_panel() {
        let session = Session::new();
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);

        for area in [
            "work", "projects", "tools", "data", "models", "research", "build",
        ] {
            assert!(html.contains(&format!(r#"data-select-area="{}""#, area)));
            assert!(html.contains(&format!(r#"data-area-panel="{}""#, area)));
            assert!(html.contains(&format!(r#"aria-controls="explorer-area-{}""#, area)));
        }

        assert!(html.contains(
            r#"data-select-area="data"><span class="tree-icon dataset">D</span><span>Datasets"#
        ));
        assert!(html.contains(
            r#"data-select-area="models"><span class="tree-icon model">M</span><span>Models"#
        ));
        assert!(html.contains(
            r#"data-select-area="build"><span class="tree-icon build">B</span><span>Extensions"#
        ));
        assert!(!html.contains(">Scratch<"));
        assert!(html.contains("No dataset object service is registered"));
        assert!(html.contains("Native offline SCi problem solver is active"));
        assert!(html.contains("In-app programmability is active"));
    }

    #[test]
    fn workspace_and_runtime_hydration_hooks_are_rendered() {
        let session = Session::new();
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);

        assert!(html.contains(r#"data-workspace-endpoint="/api/workspace""#));
        assert!(html.contains(r#"data-capabilities-endpoint="/api/capabilities""#));
        assert!(html.contains(r#"data-workspace-field="counts.datasets""#));
        assert!(html.contains(r#"data-requires-capability="org.fcf.centl.numerics.enclose""#));
        assert!(html.contains(r#"data-requires-capability="org.fcf.centl.chemistry.compute""#));
        assert!(html.contains(r#"name="interaction_mode" value="Auto""#));
    }

    #[test]
    fn specialized_latest_card_keeps_full_session_context_without_a_duplicate_feed_cell() {
        use crate::engine::HistoryEntry;

        let command = "physics convert 100 cm m";
        let physics = PhysicsResult {
            title: "Length Unit Conversion".to_string(),
            details: vec![("Output".to_string(), "1.00000000 m".to_string())],
            summary: "100 cm = 1.00000000 m".to_string(),
            verified: true,
        };
        let mut session = Session::new();
        session.history.push(HistoryEntry {
            command: command.to_string(),
            result: physics.summary.clone(),
            exact_repr: Some("preserved-physics-evidence".to_string()),
            approximate_repr: Some("Deterministic binary64 model".to_string()),
            execution_micros: 9,
            success: true,
        });

        let html = render_lab_workbench("", None, None, Some(&physics), None, &session);
        assert_eq!(html.matches(r#"class="result-cell""#).count(), 0);
        assert!(html.contains(r#"class="system-result physics-result""#));
        assert!(html.contains(r#"data-receipt-target="receipt-detail-1""#));
        assert!(html.contains("preserved-physics-evidence"));
        assert!(html.contains("admitted in 9 µs"));
        assert!(html.contains(r#">1</strong>receipts"#));
    }

    #[test]
    fn transient_informational_result_remains_visible_after_prior_work() {
        use crate::engine::HistoryEntry;

        let mut session = Session::new();
        session.history.push(HistoryEntry {
            command: "1 + 1".to_string(),
            result: "2".to_string(),
            exact_repr: Some("2".to_string()),
            approximate_repr: None,
            execution_micros: 1,
            success: true,
        });
        let transient = ExecutionResult {
            text: "CENTL Mathematical Syntax".to_string(),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 2,
        };

        let html = render_lab_workbench_with_transient_result(
            "",
            Some(&transient),
            None,
            None,
            None,
            true,
            &session,
        );
        assert!(html.contains("CENTL Mathematical Syntax"));
        assert!(html.contains("CentL26 information"));
        assert!(html.contains("informational"));
        assert!(html.contains(r#"class="system-result exact-result""#));
    }

    #[test]
    fn canonical_enclosure_is_not_repeated_in_the_notebook_feed() {
        assert!(result_already_displays_enclosure(
            "≈ [1.4142, 1.4143]",
            "[1.4142, 1.4143]"
        ));
        assert!(!result_already_displays_enclosure(
            "1.4142",
            "[1.4142, 1.4143]"
        ));
    }

    #[test]
    fn copy_does_not_promise_unqualified_natural_language() {
        let session = Session::new();
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);

        assert!(html.contains("Enter a supported expression or command"));
        assert!(!html.contains("Ask CentL26"));
        assert!(!html.contains("every tool, file, and command"));
        assert!(!html.contains("Search tools, commands, files, and settings"));
    }

    #[test]
    fn client_reapplies_area_mode_and_inspector_state_after_fragment_runs() {
        for key in [
            "centl26:26.0:area:v1",
            "centl26:26.0:mode:v1",
            "centl26:26.0:inspector-tab:v1",
        ] {
            assert!(LAB_JS.contains(key));
        }

        assert!(LAB_JS.contains("current.replaceWith(next)"));
        assert!(LAB_JS.contains("initializeWorkspace(next)"));
        assert!(LAB_JS.contains("selectArea(selectedArea"));
        assert!(LAB_JS.contains("applyInteractionMode(selectedMode"));
        assert!(LAB_JS.contains("tab.dataset.inspectorTab === selectedInspectorTab"));
    }

    #[test]
    fn every_rendered_button_has_an_explicit_action_contract() {
        use crate::engine::HistoryEntry;

        let mut session = Session::new();
        session.history.push(HistoryEntry {
            command: "1 + 1".to_string(),
            result: "2".to_string(),
            exact_repr: Some("2".to_string()),
            approximate_repr: None,
            execution_micros: 1,
            success: true,
        });
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);
        let action_markers = [
            r#"type="submit""#,
            "data-toggle-",
            "data-select-area",
            "data-open-palette",
            "data-open-evidence",
            "data-run-active",
            "data-update",
            "data-command",
            "data-palette-action",
            "data-new-computation",
            "data-focus-cell",
            "data-fill",
            "data-clear-session",
            "data-receipt-target",
            "data-inspector-tab",
            "data-open-fcf-about",
            "data-close-fcf-about",
        ];

        for rest in html.split("<button").skip(1) {
            let tag = rest.split_once('>').map(|(tag, _)| tag).unwrap();
            assert!(
                action_markers.iter().any(|marker| tag.contains(marker)),
                "button has no explicit action contract: <button{}>",
                tag
            );
        }
    }

    #[test]
    fn new_computation_is_a_non_destructive_blank_draft_action() {
        let session = Session::new();
        let workbench = render_lab_workbench("draft", None, None, None, None, &session);
        let html = render_lab_page(&workbench);

        assert!(html.contains(r#"data-new-computation title="Start a blank computation without clearing notebook history""#));
        assert!(html.contains(r#"data-palette-action="new-computation""#));
        assert!(html.contains("Clear the draft; preserve notebook history"));
        assert!(!html.contains(r#"data-palette-action="focus""#));
        assert!(LAB_JS.contains("function startNewComputation"));
        assert!(LAB_JS.contains(r#"editor.value = "";"#));
        assert!(LAB_JS.contains("removeStorage(draftKey)"));
        assert!(LAB_JS.contains("editor.scrollIntoView({ block: \"nearest\" })"));
        assert!(LAB_JS.contains("syncComposerActions()"));
    }

    #[test]
    fn clear_control_calls_the_persisted_backend_reset() {
        let session = Session::new();
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);

        assert!(html.contains("Clear notebook history and saved receipts"));
        assert!(LAB_JS.contains("function clearNotebook"));
        assert!(LAB_JS.contains(r#"cmd: ":clear""#));
        assert!(LAB_JS.contains("interaction_mode: selectedMode"));
        assert!(LAB_JS.contains("Clear this CentL26 notebook and its saved receipts?"));
        assert!(LAB_JS.contains("window.confirm"));
    }

    #[test]
    fn composer_actions_track_blank_and_non_blank_notebook_state() {
        assert!(LAB_JS.contains("function syncComposerActions"));
        assert!(LAB_JS.contains(r#"[data-run-active], .composer-run"#));
        assert!(LAB_JS.contains(r#"[data-clear-session]"#));
        assert!(LAB_JS.contains("button.disabled = !hasInput"));
        assert!(LAB_JS.contains("button.disabled = !canClear"));
        assert!(LAB_JS.contains("if (!activeEditor()?.value.trim())"));
        assert!(LAB_JS.contains("hasNotebookContent()"));
    }

    #[test]
    fn changing_interaction_mode_does_not_open_the_palette() {
        let change_handler = LAB_JS
            .split_once(r#"document.addEventListener("change""#)
            .and_then(|(_, rest)| rest.split_once(r#"document.addEventListener("keydown""#))
            .map(|(handler, _)| handler)
            .expect("interaction mode change handler");

        assert!(change_handler.contains("applyInteractionMode(mode)"));
        assert!(!change_handler.contains("openPalette"));
    }

    #[test]
    fn updater_uses_only_the_packaged_native_bridge() {
        let session = Session::new();
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);

        assert!(html.contains(r#"data-update title="Check for CentL26 updates""#));
        assert!(LAB_JS.contains("window.webkit?.messageHandlers?.centl26Update"));
        assert!(LAB_JS.contains(r#"postMessage({ action: "check" })"#));
        assert!(LAB_JS.contains("Automatic updates are available in the CentL26 macOS app."));
        assert!(!LAB_JS.contains("window.open"));
        assert!(!LAB_JS.contains("github.com/chasebryan/centl/releases"));
    }

    #[test]
    fn visible_command_shortcuts_choose_compatible_execution_modes() {
        use crate::engine::HistoryEntry;

        let empty_session = Session::new();
        let empty_workbench = render_lab_workbench("", None, None, None, None, &empty_session);
        let empty_html = render_lab_page(&empty_workbench);
        let mut session = Session::new();
        session.history.push(HistoryEntry {
            command: "physics convert 100 cm m".to_string(),
            result: "1 m".to_string(),
            exact_repr: Some("typed evidence".to_string()),
            approximate_repr: None,
            execution_micros: 2,
            success: true,
        });
        let workbench = render_lab_workbench("", None, None, None, None, &session);
        let html = render_lab_page(&workbench);

        assert!(empty_html
            .contains(r#"data-fill="solve(x^2 - 5*x + 6 = 0, x)" data-interaction-mode="Math""#));
        assert!(empty_html
            .contains(r#"data-fill="physics convert 100 cm m" data-interaction-mode="Physics""#));
        assert!(
            empty_html.contains(r#"data-fill="es solve 1009" data-interaction-mode="Research""#)
        );
        assert!(html.contains(r#"data-command-mode="Auto" title="Run again""#));
        assert!(LAB_JS.contains("interactionModes.has(target.dataset.interactionMode)"));
        assert!(LAB_JS.contains("interactionModes.has(target.dataset.commandMode)"));
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
    fn receipt_controls_reveal_preserved_evidence_without_rerunning() {
        use crate::engine::HistoryEntry;

        let mut session = Session::new();
        session.history.push(HistoryEntry {
            command: "chem atoms H2O".to_string(),
            result: "H: 2, O: 1".to_string(),
            exact_repr: Some("preserved-exact-evidence".to_string()),
            approximate_repr: None,
            execution_micros: 8,
            success: true,
        });

        let html = render_lab_workbench("", None, None, None, None, &session);
        let receipt_list = html
            .split_once(r#"<div class="receipt-list">"#)
            .and_then(|(_, rest)| rest.split_once(r#"</div><div class="receipt-details">"#))
            .map(|(list, _)| list)
            .expect("receipt list markup");

        assert!(receipt_list.contains(r#"data-receipt-target="receipt-detail-1""#));
        assert!(!receipt_list.contains("data-command"));
        assert!(html.contains("preserved-exact-evidence"));
        assert!(html.contains("Inspect preserved evidence"));
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
