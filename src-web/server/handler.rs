// HTTP Request Dispatcher & Command Execution Handler
// Free Computation Foundation - Apache-2.0

use crate::engine::{evaluate_single, ExecutionResult, HistoryEntry, Session};
use crate::erdos_straus::{run_hunt_window, solve_es, HuntSummary, SolveResult};
use crate::physics::{convert_units, simulate_collision_1d, PhysicsResult};
use serde_json::Value;
use std::env;
use std::io::{self, Read};
use std::process::{Command, ExitStatus, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

#[cfg(unix)]
use std::os::unix::process::CommandExt;

#[cfg(unix)]
unsafe extern "C" {
    #[link_name = "setpgid"]
    fn provider_setpgid(process: i32, group: i32) -> i32;
    #[link_name = "kill"]
    fn provider_kill(process: i32, signal: i32) -> i32;
}

#[cfg(unix)]
const PROVIDER_KILL_SIGNAL: i32 = 9;

const MAX_PROVIDER_OUTPUT_BYTES: usize = 256 * 1024;
const CHEMISTRY_PROVIDER_TIMEOUT: Duration = Duration::from_secs(10);
const PROVIDER_POLL_INTERVAL: Duration = Duration::from_millis(5);

pub struct AppState {
    pub notebooks: Vec<(String, Session)>,
    pub active_notebook: usize,
}

impl AppState {
    pub fn new() -> Self {
        let mut s = Self {
            notebooks: vec![("Notebook 01".to_string(), Session::new())],
            active_notebook: 0,
        };
        s.sync_session_tabs();
        s
    }
    pub fn session(&self) -> &Session { &self.notebooks[self.active_notebook].1 }
    pub fn session_mut(&mut self) -> &mut Session { &mut self.notebooks[self.active_notebook].1 }
    pub fn notebook_name(&self) -> &str { &self.notebooks[self.active_notebook].0 }
    pub fn sync_session_tabs(&mut self) {
        let tabs: Vec<(String, bool)> = self.notebooks.iter().enumerate().map(|(i, (name, _))| {
            (name.clone(), i == self.active_notebook)
        }).collect();
        let active_name = self.notebooks[self.active_notebook].0.clone();
        let session = &mut self.notebooks[self.active_notebook].1;
        session.notebook_name = active_name;
        session.notebook_tabs = tabs;
    }
}

impl Default for AppState {
    fn default() -> Self {
        Self::new()
    }
}

pub fn handle_command(
    raw_cmd: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let stmts = crate::engine::split_statements(raw_cmd);
    if stmts.is_empty() {
        return (None, None, None, None);
    }
    if stmts.len() == 1 {
        return handle_single_command(&stmts[0], state);
    }

    // Multi-statement computation block inside a single cell
    let initial_history_len = state.session().history.len();
    let mut step_outputs: Vec<(String, String)> = Vec::new();
    let mut last_exec: Option<ExecutionResult> = None;
    let mut last_phys: Option<PhysicsResult> = None;
    let mut last_hunt: Option<HuntSummary> = None;
    let mut total_micros = 0u128;

    for (idx, stmt) in stmts.iter().enumerate() {
        let (exec, err, phys, hunt) = handle_single_command(stmt, state);
        if let Some(e) = err {
            state.session_mut().history.truncate(initial_history_len);
            return (None, Some(format!("Step {} ('{}') failed: {}", idx + 1, stmt, e)), None, None);
        }
        if let Some(ref res) = exec {
            total_micros += res.execution_micros;
            step_outputs.push((stmt.clone(), res.text.clone()));
            last_exec = Some(res.clone());
        } else if let Some(ref p) = phys {
            step_outputs.push((stmt.clone(), p.title.clone()));
            last_phys = Some(p.clone());
        } else if let Some(ref h) = hunt {
            step_outputs.push((stmt.clone(), format!("Search range [{}, {}]", h.start_bound, h.end_bound)));
            last_hunt = Some(h.clone());
        } else {
            step_outputs.push((stmt.clone(), "OK".to_string()));
        }
    }

    // Rollback intermediate step history additions so the entire cell is saved as one unified computation
    state.session_mut().history.truncate(initial_history_len);

    let mut block_text = format!("Block Execution ({} steps):\n", stmts.len());
    for (i, (stmt, out)) in step_outputs.iter().enumerate() {
        if out == stmt || out.is_empty() {
            block_text.push_str(&format!("  [{}] {}\n", i + 1, stmt));
        } else if out.lines().count() > 1 {
            block_text.push_str(&format!("  [{}] {}\n    ↳ {}\n", i + 1, stmt, out.replace('\n', "\n    ")));
        } else {
            block_text.push_str(&format!("  [{}] {}  →  {}\n", i + 1, stmt, out));
        }
    }

    let (exact_rat, approx, sym_expr) = if let Some(ref final_res) = last_exec {
        if let Some(ref exact) = final_res.exact_rational {
            block_text.push_str(&format!("\nResult: {}", exact));
        } else if !final_res.text.is_empty() && !final_res.text.contains('\n') {
            block_text.push_str(&format!("\nResult: {}", final_res.text));
        }
        (final_res.exact_rational.clone(), final_res.approximate.clone(), final_res.symbolic_expr.clone())
    } else {
        (None, None, None)
    };

    let combined_res = ExecutionResult {
        text: block_text.clone(),
        exact_rational: exact_rat.clone(),
        approximate: approx.clone(),
        symbolic_expr: sym_expr,
        execution_micros: total_micros,
    };

    state.session_mut().history.push(HistoryEntry {
        command: raw_cmd.trim().to_string(),
        result: block_text,
        exact_repr: exact_rat.map(|r| format!("{}", r)),
        approximate_repr: approx,
        execution_micros: total_micros,
        success: true,
    });

    (Some(combined_res), None, last_phys, last_hunt)
}

pub fn handle_single_command(
    raw_cmd: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let cmd = raw_cmd.trim();
    if cmd.is_empty() {
        return (None, None, None, None);
    }

    if cmd == ":new-notebook" {
        let idx = state.notebooks.len() + 1;
        let name = format!("Notebook {:02}", idx);
        state.notebooks.push((name, Session::new()));
        state.active_notebook = state.notebooks.len() - 1;
        state.sync_session_tabs();
        return (None, None, None, None);
    }
    if cmd.starts_with(":switch-notebook ") {
        if let Ok(idx) = cmd[17..].trim().parse::<usize>() {
            if idx < state.notebooks.len() {
                state.active_notebook = idx;
            }
        }
        state.sync_session_tabs();
        return (None, None, None, None);
    }
    if cmd.starts_with(":close-notebook ") {
        if let Ok(idx) = cmd[16..].trim().parse::<usize>() {
            if idx < state.notebooks.len() && state.notebooks.len() > 1 {
                state.notebooks.remove(idx);
                if state.active_notebook >= state.notebooks.len() {
                    state.active_notebook = state.notebooks.len() - 1;
                }
            }
        }
        state.sync_session_tabs();
        return (None, None, None, None);
    }
    if cmd.starts_with(":rename-notebook ") {
        let new_name = cmd[17..].trim().to_string();
        if !new_name.is_empty() {
            state.notebooks[state.active_notebook].0 = new_name;
        }
        state.sync_session_tabs();
        return (None, None, None, None);
    }

    if cmd == ":save" || cmd == ":save-project" {
        state.sync_session_tabs();
        let total_entries: usize = state.notebooks.iter().map(|(_, s)| s.history.len()).sum();
        let name = state.notebook_name().to_string();
        let res = ExecutionResult {
            text: format!("Project saved successfully (Active: '{}', {} notebook tab(s), {} total calculation(s)).", name, state.notebooks.len(), total_entries),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 0,
        };
        return (Some(res), None, None, None);
    }

    if cmd == ":clear" || cmd == ":clear-history" {
        let name = state.notebook_name().to_string();
        state.notebooks[state.active_notebook].1 = Session::new();
        state.notebooks[state.active_notebook].0 = name;
        state.sync_session_tabs();
        return (None, None, None, None);
    }

    if let Some(key) = cmd.strip_prefix(":gemini-key ").or_else(|| cmd.strip_prefix(":set-gemini-key ")) {
        crate::engine::sci::set_runtime_gemini_key(key.trim());
        let res = ExecutionResult {
            text: "Runtime Gemini API key configured successfully. Status: Active.".to_string(),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 0,
        };
        return (Some(res), None, None, None);
    }

    if let Some(model) = cmd.strip_prefix(":gemini-model ").or_else(|| cmd.strip_prefix(":set-gemini-model ")) {
        crate::engine::sci::set_runtime_gemini_model(model.trim());
        let res = ExecutionResult {
            text: format!("Gemini active model set to '{}'.", model.trim()),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 0,
        };
        return (Some(res), None, None, None);
    }

    if cmd == ":gemini-status" || cmd == ":ai-status" {
        let (configured, key_preview, source, model) = crate::engine::sci::get_gemini_status_info();
        let status_str = if configured {
            format!("=== Gemini AI Co-Pilot Status ===\n• Status: Active & Connected\n• Active Model: {}\n• Credential Source: {}\n• Key Preview: {}\n• Architecture: Strategic Hybrid STEM (Exact-First)", model, source, key_preview.unwrap_or_default())
        } else {
            format!("=== Gemini AI Co-Pilot Status ===\n• Status: Unconfigured (CentL26 Running 100% Offline)\n• Active Model: {}\n• Credential Source: None detected\n• Setup: Set GEMINI_API_KEY environment variable or run ':gemini-key <YOUR_KEY>'.", model)
        };
        let res = ExecutionResult {
            text: status_str,
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 0,
        };
        return (Some(res), None, None, None);
    }

    if cmd == ":examples" {
        let res = ExecutionResult {
            text: "CentL26 Example Catalog:\nDownload the complete 50+ example STEM spreadsheet (CSV) from /download/centl26-examples.csv or open the Explorer Data panel.".to_string(),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 0,
        };
        return (Some(res), None, None, None);
    }

    if cmd == ":release" || cmd == ":version" || cmd == ":releases" {
        let res = ExecutionResult {
            text: "=== CentL26.8.1 Official Release (All Platforms) ===\nVersion: 26.8.1 (Universal Release)\nCapabilities:\n• Multi-Platform Standard: native support for Windows 11, macOS Apple Silicon / Intel, and Debian/Fedora/Arch Linux.\n• STEM Academic Search Engine: omnibar Chrome routing to Google Scholar, arXiv, PubMed, Wolfram MathWorld, OEIS, NIST, and NASA ADS.\n• FCF Knowledge Center & In-App Reader: built-in documentation browser for all FCF manuals, specs, and research theorem preprints.\n• Gemini AI Co-Pilot Resiliency: multi-model auto-fallback (2.5-flash -> 2.0-flash -> 1.5-flash -> 1.5-pro), cross-platform key persistence, and fault-tolerant JSON decomposition.\n• Resilient Multi-Strategy In-App Updater: dual-channel git & GitHub manifest synchronization, isolated build retry, and automated precompiled binary fallback.\n• Clean Library & Binary Architecture: zero compiler build warnings across all packaging targets.\n• Multi-Notebook Tabs & Workspaces: seamlessly organize independent computations in named tabs.\n• Save & Download: export active notebooks to clean Markdown and structured JSON.\n• In-App Programmability (build): define, inspect, and test custom STEM functions & constants in plain English.\n• 2D Function Plotter: multi-line ASCII/Unicode coordinate grid visualization.\n• Dim Mode Theme: toggle between standard light and dimmed matte slate palettes.\n• Smart Multi-Domain Auto-Detector: direct stoichiometry, reactions, physics conversions, and constants.\n• CentL-SCi Natural Language STEM Solver: comprehensive step-by-step offline verified problem solving across chemistry, mechanics, circuits, thermodynamics, geometry, linear algebra, and statistics without external dependencies.\n• Rigorous Interval Numerics: arbitrary-precision interval enclosures and transcendental constants.\n• 50+ STEM Examples Sheet: multi-domain reference dataset available via /download/centl26-examples.csv.".to_string(),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 0,
        };
        return (Some(res), None, None, None);
    }

    // 1. Auto-detected / explicit Chemistry
    if is_auto_detected_chemistry(cmd) {
        return handle_chemistry_command(cmd, state);
    }

    // 2. Auto-detected / explicit CPS
    if is_auto_detected_cps(cmd) {
        return handle_cps_command(cmd, state);
    }

    // 3. Auto-detected / explicit Physics
    if is_auto_detected_physics(cmd) {
        return handle_physics_command(cmd, state);
    }

    // 4. Auto-detected / explicit Erdős–Straus
    if is_auto_detected_es(cmd) {
        return handle_es_command(cmd, state);
    }

    // 5. Development Workbench & In-App Programmability (BUILD / MIRAGE)
    if is_auto_detected_build(cmd) {
        return handle_build_command(cmd, state);
    }

    // 6. Preservation & Retrieval (CARAVAN)
    if has_command_prefix(cmd, "caravan") {
        return handle_caravan_command(cmd, state);
    }

    // 7. Auto-detected / explicit SCi (Natural Language STEM / Gemini)
    if is_auto_detected_sci(cmd) {
        return handle_sci_command(cmd, state);
    }

    // 8. Rigorous approximation boundary
    if is_approximation_command(cmd) {
        return match run_canonical_approx(cmd) {
            Ok(result) => {
                state.session_mut().history.push(HistoryEntry {
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

    // 9. Exact Mathematical Evaluator (with smart SCi plain-English fallback)
    match evaluate_single(cmd, state.session_mut()) {
        Ok(result) => (Some(result), None, None, None),
        Err(error) => {
            if cmd.contains(' ') {
                if let Ok(solution) = crate::engine::sci::solve_stem_offline(cmd, state.session_mut()) {
                    let mut formatted = format!("SCi Solution [{} · {}]:\n{}\n", solution.domain, solution.confidence, solution.summary);
                    for s in &solution.steps {
                        formatted.push_str(&format!("\n• {}", s));
                    }
                    if let Some(ref exact) = solution.exact_result {
                        formatted.push_str(&format!("\n\nExact Result: {}", exact));
                    }
                    if let Some(ref approx) = solution.approximate_result {
                        formatted.push_str(&format!("\nApproximate Bound: {}", approx));
                    }
                    let res = ExecutionResult {
                        text: formatted.clone(),
                        exact_rational: None,
                        approximate: solution.approximate_result,
                        symbolic_expr: None,
                        execution_micros: 0,
                    };
                    state.session_mut().history.push(HistoryEntry {
                        command: cmd.to_string(),
                        result: formatted,
                        exact_repr: None,
                        approximate_repr: None,
                        execution_micros: 0,
                        success: true,
                    });
                    return (Some(res), None, None, None);
                }
            }
            (None, Some(error), None, None)
        }
    }
}

fn is_auto_detected_chemistry(cmd: &str) -> bool {
    let trimmed = cmd.trim();
    if has_command_prefix(trimmed, "chem") || has_command_prefix(trimmed, "chemistry") {
        return true;
    }
    let lower = trimmed.to_ascii_lowercase();
    let chem_ops = [
        "atoms", "balance", "stoich", "limiting", "molar-mass", "molarmass", "mass",
        "particles", "moles", "spread", "concentration", "dilution", "yield", "gas",
        "charge", "thermo"
    ];
    for op in chem_ops {
        if has_command_prefix(&lower, op) {
            return true;
        }
    }
    if (trimmed.contains("->") || trimmed.contains("-->") || trimmed.contains("=>"))
        && !trimmed.starts_with("diff")
        && !trimmed.starts_with("integrate")
        && !trimmed.starts_with("approx")
        && !trimmed.starts_with("solve")
    {
        return true;
    }
    false
}

fn is_auto_detected_physics(cmd: &str) -> bool {
    let trimmed = cmd.trim();
    if has_command_prefix(trimmed, "physics") {
        return true;
    }
    let lower = trimmed.to_ascii_lowercase();
    let parts: Vec<&str> = lower.split_whitespace().collect();
    if parts.is_empty() {
        return false;
    }
    if parts[0] == "convert" || parts[0] == "unit" {
        if parts.len() == 4 || (parts.len() == 5 && (parts[3] == "to" || parts[3] == "in" || parts[3] == "into")) {
            return true;
        }
        return false;
    }
    let physics_ops = [
        "collision", "cherenkov", "gravity", "constant", "units",
        "debroglie", "photon", "rydberg", "photoelectric", "carnot", "blackbody", "escape", "orbit", "lorentz"
    ];
    for op in physics_ops {
        if has_command_prefix(&lower, op) || lower == *op {
            return true;
        }
    }
    false
}

fn is_auto_detected_es(cmd: &str) -> bool {
    let trimmed = cmd.trim();
    if trimmed.starts_with("es ") || trimmed == "es" || trimmed.starts_with("erdos ") {
        return true;
    }
    let parts: Vec<&str> = trimmed.split_whitespace().collect();
    if parts.len() >= 2 && parts[0] == "solve" {
        if parts[1].parse::<u64>().is_ok() && !trimmed.contains('=') && !trimmed.contains(',') && !trimmed.contains('(') {
            return true;
        }
    }
    if parts.len() >= 2 && (parts[0] == "probe" || parts[0] == "hunt") {
        return true;
    }
    false
}

fn is_auto_detected_cps(cmd: &str) -> bool {
    let trimmed = cmd.trim();
    has_command_prefix(trimmed, "cps") || has_command_prefix(trimmed, "preflight")
}

fn is_auto_detected_sci(cmd: &str) -> bool {
    let trimmed = cmd.trim();
    if has_command_prefix(trimmed, "sci") || has_command_prefix(trimmed, "gemini") || has_command_prefix(trimmed, ":gemini")
        || has_command_prefix(trimmed, "ai") || has_command_prefix(trimmed, ":ai")
    {
        return true;
    }
    let lower = trimmed.to_ascii_lowercase();
    if lower.ends_with('?') {
        return true;
    }
    let sci_prefixes = [
        "what is", "what are", "what's", "how many", "how much", "how far", "how fast", "how long",
        "calculate", "compute", "determine", "find the", "find all", "find a", "find an", "find ", "give me", "show me", "tell me",
        "differentiate", "derive", "integrate the", "integrate f", "integrate ", "balance the", "balance ",
        "explain", "solve for", "solve the", "solve ", "show that", "is it prime", "is prime", "convert ",
        "area of", "volume of", "circumference of", "perimeter of", "hypotenuse of", "dot product", "cross product",
        "determinant of", "inverse of", "mean of", "median of", "variance of", "standard deviation of",
        "totient of", "prime factors of", "stopping potential", "stopping voltage", "de broglie",
        "carnot", "blackbody", "stefan", "escape velocity", "orbital speed", "lorentz", "photoelectric",
        "the square root", "the cube root", "the derivative", "the integral", "the sum", "the product",
        "the difference", "the quotient", "the molar mass", "the molecular mass", "the molecular weight",
        "the atomic mass", "the atomic weight", "the atomic number", "the kinetic energy",
        "the potential energy", "the speed of", "the velocity", "the force", "the acceleration", "the momentum",
        "square root of", "cube root of", "sqrt of", "cbrt of", "sum of", "product of", "difference between", "quotient of",
        "half of", "quarter of", "one half of", "one third of", "two thirds of", "three quarters of",
        "please calculate", "please compute", "please find", "please evaluate", "please ",
        "can you calculate", "can you find", "can you compute", "can you tell me", "can you ",
        "could you calculate", "could you find", "could you ", "i need to calculate", "i need to find"
    ];
    for prefix in sci_prefixes {
        if lower.starts_with(prefix) {
            return true;
        }
    }
    if lower.split_whitespace().count() >= 2 && (
        lower.contains(" divided by ") || lower.contains(" multiplied by ") || lower.contains(" to the power of ")
        || lower.contains(" percent of ") || lower.contains(" percent off ") || lower.contains(" percent ")
        || lower.contains(" times ") || lower.contains(" minus ") || lower.contains(" plus ")
        || lower.contains(" squared") || lower.contains(" cubed")
        || lower.contains("accelerat") || lower.contains("velocity") || lower.contains("kinetic energy")
        || lower.contains("potential energy") || lower.contains("free fall") || lower.contains("molar mass")
        || lower.contains("molarity") || lower.contains("dilut") || lower.contains("gibbs") || lower.contains("nernst")
        || lower.contains("ohm") || lower.contains("capacitance") || lower.contains("photon") || lower.contains("rydberg")
    ) {
        return true;
    }
    false
}

fn is_auto_detected_build(command: &str) -> bool {
    let trimmed = command.trim();
    has_command_prefix(trimmed, "build")
        || has_command_prefix(trimmed, "mirage")
        || trimmed.starts_with("fn ")
        || trimmed.starts_with("function ")
        || trimmed.starts_with("def ")
        || (trimmed.starts_with("const ") && trimmed.contains('='))
}

fn handle_es_command(
    raw_cmd: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let cmd = if raw_cmd.starts_with("es ") || raw_cmd.starts_with("erdos ") {
        raw_cmd.split_whitespace().skip(1).collect::<Vec<_>>().join(" ")
    } else if raw_cmd == "es" {
        String::new()
    } else {
        raw_cmd.to_string()
    };
    let parts: Vec<&str> = cmd.split_whitespace().collect();
    if parts.is_empty() {
        let summary = run_hunt_window(1000, 500, 20);
        record_hunt_history(raw_cmd, &summary, state);
        return (None, None, None, Some(summary));
    }
    match parts[0] {
        "solve" | "probe" => {
            if parts.len() >= 2 {
                if let Ok(n) = parts[1].parse::<u64>() {
                    let res = solve_es(n);
                    let mut witness_text = if let Some(witness) = &res.witness {
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
                    if let Some(letter_number) = &res.letter_number {
                        witness_text.push_str(&format!("\nLetter ID: #{}", letter_number));
                    }
                    let execution = ExecutionResult {
                        text: witness_text,
                        exact_rational: None,
                        approximate: None,
                        symbolic_expr: None,
                        execution_micros: res.execution_micros,
                    };
                    record_solve_history(raw_cmd, &execution, &res, state);
                    return (Some(execution), None, None, None);
                }
            }
            (None, Some("Usage: es solve <prime_integer>".to_string()), None, None)
        }
        "hunt" | "go" => {
            let from = if parts.len() >= 2 {
                parts[1].parse::<u64>().unwrap_or(20000)
            } else {
                20000
            };
            let summary = run_hunt_window(from, 5000, 50);
            record_hunt_history(raw_cmd, &summary, state);
            (None, None, None, Some(summary))
        }
        "status" => {
            let summary = run_hunt_window(1000, 1000, 30);
            record_hunt_history(raw_cmd, &summary, state);
            (None, None, None, Some(summary))
        }
        _ => (None, Some("Usage: es solve <p> | es hunt [from] | es status".to_string()), None, None)
    }
}

fn handle_physics_command(
    raw_cmd: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let cmd = if has_command_prefix(raw_cmd, "physics") {
        raw_cmd["physics".len()..].trim()
    } else {
        raw_cmd.trim()
    };
    let parts: Vec<&str> = cmd.split_whitespace().collect();
    if parts.is_empty() {
        return (
            None,
            Some(
                "Usage: physics convert <value> <from> <to> | physics constant <sym> | physics units | physics cherenkov <n> <v> | physics gravity m=.. p=.. v=.. g=.. dt=.. steps=.. | physics collision m1=.. v1=.. m2=.. v2=.. [e=..]"
                    .to_string(),
            ),
            None,
            None,
        );
    }

    if parts[0] == "convert" || parts[0] == "unit" {
        let (val_str, from_u, to_u) = if parts.len() == 4 {
            (parts[1], parts[2], parts[3])
        } else if parts.len() == 5 && (parts[3] == "to" || parts[3] == "in" || parts[3] == "into") {
            (parts[1], parts[2], parts[4])
        } else {
            return (
                None,
                Some("Usage: convert <value> <from_unit> <to_unit> (or convert <value> <from> to <to>)".to_string()),
                None,
                None,
            );
        };
        let value = match val_str.parse::<f64>() {
            Ok(value) => value,
            Err(_) => {
                return (
                    None,
                    Some(format!("Invalid physics value: {}", val_str)),
                    None,
                    None,
                )
            }
        };
        let started = Instant::now();
        return match convert_units(value, from_u, to_u) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "units" {
        let started = Instant::now();
        let result = crate::physics::list_units_catalog();
        record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
        return (None, None, Some(result), None);
    }

    if parts[0] == "constant" {
        if parts.len() != 2 {
            return (
                None,
                Some("Usage: constant <symbol> (e.g. constant c, constant h, constant G)".to_string()),
                None,
                None,
            );
        }
        let sym = parts[1];
        let started = Instant::now();
        if let Some(c) = crate::physics::lookup_constant(sym) {
            let result = PhysicsResult {
                title: format!("Physical Constant: {} ({})", c.symbol, c.name),
                details: vec![
                    ("Symbol".to_string(), c.symbol.to_string()),
                    ("Name".to_string(), c.name.to_string()),
                    ("Value".to_string(), format!("{} {}", c.value_str, c.unit)),
                    ("Exactness".to_string(), if c.exact { "Exact definition".to_string() } else { "Measured / Derived".to_string() }),
                    ("Provenance".to_string(), c.provenance.to_string()),
                ],
                summary: format!("{} = {} {}", c.symbol, c.value_str, c.unit),
                verified: true,
            };
            record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
            return (None, None, Some(result), None);
        } else {
            return (
                None,
                Some(format!("Unknown physical constant: {}. Use 'physics units' to see available constants.", sym)),
                None,
                None,
            );
        }
    }

    if parts[0] == "cherenkov" {
        if parts.len() != 3 {
            return (
                None,
                Some("Usage: cherenkov <refractive_index> <particle_speed_m_per_s>".to_string()),
                None,
                None,
            );
        }
        let n = match parts[1].parse::<f64>() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid refractive index: {}", parts[1])), None, None),
        };
        let v = match parts[2].parse::<f64>() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid particle speed: {}", parts[2])), None, None),
        };
        let started = Instant::now();
        return match crate::physics::calculate_cherenkov(n, v) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "gravity" {
        let mass = named_f64(&parts[1..], "m").or_else(|| named_f64(&parts[1..], "mass")).unwrap_or(1.0);
        let pos = named_vec3(&parts[1..], "p").or_else(|| named_vec3(&parts[1..], "pos")).or_else(|| named_vec3(&parts[1..], "position")).unwrap_or((0.0, 0.0, 0.0));
        let vel = named_vec3(&parts[1..], "v").or_else(|| named_vec3(&parts[1..], "vel")).or_else(|| named_vec3(&parts[1..], "velocity")).unwrap_or((0.0, 0.0, 0.0));
        let grav = named_vec3(&parts[1..], "g").or_else(|| named_vec3(&parts[1..], "grav")).or_else(|| named_vec3(&parts[1..], "gravity")).unwrap_or((0.0, 0.0, -9.80665));
        let dt = named_f64(&parts[1..], "dt").unwrap_or(0.01);
        let steps = named_u64(&parts[1..], "steps").or_else(|| named_u64(&parts[1..], "n")).unwrap_or(100);

        let started = Instant::now();
        return match crate::physics::simulate_gravity_trajectory(mass, pos, vel, grav, dt, steps) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "collision" {
        let m1 = named_f64(&parts[1..], "m1");
        let v1 = named_f64(&parts[1..], "v1");
        let m2 = named_f64(&parts[1..], "m2");
        let v2 = named_f64(&parts[1..], "v2");
        let restitution = named_f64(&parts[1..], "e")
            .or_else(|| named_f64(&parts[1..], "restitution"))
            .unwrap_or(1.0);

        let (Some(m1), Some(v1), Some(m2), Some(v2)) = (m1, v1, m2, v2) else {
            return (
                None,
                Some(
                    "Usage: collision m1=<mass> v1=<velocity> m2=<mass> v2=<velocity> [e=<0..1>]"
                        .to_string(),
                ),
                None,
                None,
            );
        };

        let started = Instant::now();
        return match simulate_collision_1d(m1, v1, m2, v2, restitution) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "debroglie" {
        if parts.len() < 3 {
            return (None, Some("Usage: physics debroglie <mass_kg> <velocity_m_s>".to_string()), None, None);
        }
        let m: f64 = match parts[1].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid mass: {}", parts[1])), None, None),
        };
        let v: f64 = match parts[2].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid velocity: {}", parts[2])), None, None),
        };
        let started = Instant::now();
        return match crate::physics::calculate_debroglie(m, v) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "photon" {
        if parts.len() < 2 {
            return (None, Some("Usage: physics photon <wavelength_m_or_nm> [hz|nm|m]".to_string()), None, None);
        }
        let mut val: f64 = match parts[1].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid photon value: {}", parts[1])), None, None),
        };
        let is_wavelength = if parts.len() >= 3 && parts[2].eq_ignore_ascii_case("hz") {
            false
        } else {
            if val > 1.0 { val *= 1e-9; } // Assume nm if > 1.0
            true
        };
        let started = Instant::now();
        return match crate::physics::calculate_photon(val, is_wavelength) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "rydberg" {
        if parts.len() < 3 {
            return (None, Some("Usage: physics rydberg <n1_lower> <n2_upper> [Z]".to_string()), None, None);
        }
        let n1: u64 = match parts[1].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid n1: {}", parts[1])), None, None),
        };
        let n2: u64 = match parts[2].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid n2: {}", parts[2])), None, None),
        };
        let z: u64 = if parts.len() >= 4 { parts[3].parse().unwrap_or(1) } else { 1 };
        let started = Instant::now();
        return match crate::physics::calculate_rydberg(n1, n2, z) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "photoelectric" {
        if parts.len() < 3 {
            return (None, Some("Usage: physics photoelectric <work_function_eV> <wavelength_nm>".to_string()), None, None);
        }
        let phi: f64 = match parts[1].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid work function: {}", parts[1])), None, None),
        };
        let lambda: f64 = match parts[2].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid wavelength: {}", parts[2])), None, None),
        };
        let started = Instant::now();
        return match crate::physics::calculate_photoelectric(phi, lambda) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "carnot" {
        if parts.len() < 3 {
            return (None, Some("Usage: physics carnot <Th_kelvin> <Tc_kelvin>".to_string()), None, None);
        }
        let th: f64 = match parts[1].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid Th: {}", parts[1])), None, None),
        };
        let tc: f64 = match parts[2].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid Tc: {}", parts[2])), None, None),
        };
        let started = Instant::now();
        return match crate::physics::calculate_carnot(th, tc) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "blackbody" {
        if parts.len() < 2 {
            return (None, Some("Usage: physics blackbody <temperature_K> [area_m2] [emissivity]".to_string()), None, None);
        }
        let t: f64 = match parts[1].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid temperature: {}", parts[1])), None, None),
        };
        let area: Option<f64> = parts.get(2).and_then(|s| s.parse().ok());
        let eps: Option<f64> = parts.get(3).and_then(|s| s.parse().ok());
        let started = Instant::now();
        return match crate::physics::calculate_blackbody(t, area, eps) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "escape" {
        if parts.len() < 3 {
            return (None, Some("Usage: physics escape <mass_kg> <radius_m>".to_string()), None, None);
        }
        let m: f64 = match parts[1].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid mass: {}", parts[1])), None, None),
        };
        let r: f64 = match parts[2].parse() {
            Ok(v) => v,
            Err(_) => return (None, Some(format!("Invalid radius: {}", parts[2])), None, None),
        };
        let started = Instant::now();
        return match crate::physics::calculate_escape_velocity(m, r) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    if parts[0] == "lorentz" {
        if parts.len() < 2 {
            return (None, Some("Usage: physics lorentz <velocity_m_s>".to_string()), None, None);
        }
        let v: f64 = match parts[1].parse() {
            Ok(val) => val,
            Err(_) => return (None, Some(format!("Invalid velocity: {}", parts[1])), None, None),
        };
        let started = Instant::now();
        return match crate::physics::calculate_lorentz(v) {
            Ok(result) => {
                record_physics_history(raw_cmd, &result, started.elapsed().as_micros(), state);
                (None, None, Some(result), None)
            }
            Err(error) => (None, Some(error), None, None),
        };
    }

    (
        None,
        Some(
            "Usage: physics convert <value> <from> <to> | physics constant <sym> | physics units | physics debroglie <m> <v> | physics photon <λ> | physics rydberg <n1> <n2> | physics carnot <Th> <Tc> | physics blackbody <T> | physics escape <M> <R> | physics lorentz <v> | physics collision .."
                .to_string(),
        ),
        None,
        None,
    )
}

fn is_approximation_command(command: &str) -> bool {
    let trimmed = command.trim_start();
    let Some(rest) = trimmed.strip_prefix("approx") else {
        return false;
    };
    rest.trim_start().starts_with('(')
}

fn run_canonical_approx(command: &str) -> Result<ExecutionResult, String> {
    let engine = super::capabilities::canonical_math_provider().command;
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
    let enclosure = stdout
        .strip_prefix('≈')
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .unwrap_or(stdout.as_str())
        .to_string();

    Ok(ExecutionResult {
        text: stdout,
        exact_rational: None,
        approximate: Some(enclosure),
        symbolic_expr: None,
        execution_micros: started.elapsed().as_micros(),
    })
}

#[derive(Debug)]
struct ChemistryOutcome {
    summary: String,
    evidence: String,
}

fn has_command_prefix(command: &str, prefix: &str) -> bool {
    command == prefix
        || command
            .strip_prefix(prefix)
            .is_some_and(|rest| rest.starts_with(char::is_whitespace))
}

fn handle_chemistry_command(
    command: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let args = match chemistry_provider_args(command) {
        Ok(args) => args,
        Err(error) => return (None, Some(error), None, None),
    };
    let provider = super::capabilities::chemistry_provider().command;
    let started = Instant::now();
    match run_chemistry_with(&provider, &args) {
        Ok(outcome) => {
            let elapsed = started.elapsed().as_micros();
            let result = ExecutionResult {
                text: outcome.summary.clone(),
                exact_rational: None,
                approximate: None,
                symbolic_expr: None,
                execution_micros: elapsed,
            };
            state.session_mut().history.push(HistoryEntry {
                command: command.to_string(),
                result: outcome.summary,
                exact_repr: Some(outcome.evidence),
                approximate_repr: None,
                execution_micros: elapsed,
                success: true,
            });
            (Some(result), None, None, None)
        }
        Err(error) => (None, Some(error), None, None),
    }
}

fn chemistry_provider_args(command: &str) -> Result<Vec<String>, String> {
    let body = if has_command_prefix(command, "chemistry") {
        command["chemistry".len()..].trim()
    } else if has_command_prefix(command, "chem") {
        command["chem".len()..].trim()
    } else {
        command.trim()
    };
    let mut tokens = tokenize_command_args(body);
    if tokens.is_empty() {
        return Err("Usage: chem <operation> [args...]".to_string());
    }

    if (body.contains("->") || body.contains("-->") || body.contains("=>"))
        && !tokens[0].eq_ignore_ascii_case("balance")
        && !tokens[0].eq_ignore_ascii_case("stoich")
        && !tokens[0].eq_ignore_ascii_case("limiting")
    {
        return Ok(vec!["balance".to_string(), strip_matching_quotes(body).to_string()]);
    }
    let operation = tokens.remove(0).to_ascii_lowercase();
    match operation.as_str() {
        "atoms" => {
            if tokens.len() != 1 {
                return Err("Usage: chem atoms <formula>".to_string());
            }
            let formula = strip_matching_quotes(&tokens[0]);
            if formula.chars().any(char::is_whitespace) {
                return Err("A chemical formula cannot contain whitespace.".to_string());
            }
            Ok(vec!["atoms".to_string(), formula.to_string()])
        }
        "balance" => {
            if tokens.is_empty() {
                return Err("Usage: chem balance <reaction>".to_string());
            }
            let joined = tokens.join(" ");
            let reaction = strip_matching_quotes(&joined);
            Ok(vec!["balance".to_string(), reaction.to_string()])
        }
        "particles" => {
            let mut args = vec!["particles".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "moles" => {
            let mut args = vec!["moles".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "stoich" => {
            let mut args = vec!["stoich".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "limiting" => {
            let mut args = vec!["limiting".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "spread" => {
            let mut args = vec!["spread".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "constant" => {
            if tokens.is_empty() {
                return Err("Usage: chem constant <symbol>".to_string());
            }
            Ok(vec!["constant".to_string(), strip_matching_quotes(&tokens[0]).to_string()])
        }
        "molar-mass" | "molarmass" | "mass" => {
            if tokens.is_empty() {
                return Err("Usage: chem molar-mass <formula>".to_string());
            }
            Ok(vec!["molar-mass".to_string(), strip_matching_quotes(&tokens[0]).to_string()])
        }
        "concentration" => {
            let mut args = vec!["concentration".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "dilution" => {
            let mut args = vec!["dilution".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "yield" => {
            let mut args = vec!["yield".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "gas" => {
            let mut args = vec!["gas".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "charge" => {
            let mut args = vec!["charge".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        "thermo" => {
            let mut args = vec!["thermo".to_string()];
            for t in tokens {
                args.push(strip_matching_quotes(&t).to_string());
            }
            Ok(args)
        }
        _ => Err(
            "Qualified CentL26 chemistry operations: chem atoms <formula> | chem balance <reaction> | chem constant <sym> | chem molar-mass <formula> | chem concentration <moles> <vol> | chem dilution <c1> <v1> <v2> | chem yield <act> <theo> | chem gas <n> <T> <V> | chem charge <n> | chem particles [exact|measured] <moles> | chem moles [exact|measured] <entities> | chem stoich <rxn> <src> <mol> <tgt> | chem limiting <rxn> <species=mol>... | chem spread <unit> <vals>... | chem thermo <rxn> <species=H>..."
                .to_string(),
        ),
    }
}

fn tokenize_command_args(input: &str) -> Vec<String> {
    let mut tokens = Vec::new();
    let mut current = String::new();
    let mut in_single_quote = false;
    let mut in_double_quote = false;

    for c in input.chars() {
        match c {
            '\'' if !in_double_quote => {
                in_single_quote = !in_single_quote;
            }
            '"' if !in_single_quote => {
                in_double_quote = !in_double_quote;
            }
            c if c.is_whitespace() && !in_single_quote && !in_double_quote => {
                if !current.is_empty() {
                    tokens.push(current.clone());
                    current.clear();
                }
            }
            _ => {
                current.push(c);
            }
        }
    }
    if !current.is_empty() {
        tokens.push(current);
    }
    tokens
}

fn strip_matching_quotes(value: &str) -> &str {
    if value.len() >= 2 {
        let bytes = value.as_bytes();
        if (bytes[0] == b'\'' && bytes[value.len() - 1] == b'\'')
            || (bytes[0] == b'"' && bytes[value.len() - 1] == b'"')
        {
            return &value[1..value.len() - 1];
        }
    }
    value
}

fn run_chemistry_with(provider: &str, args: &[String]) -> Result<ChemistryOutcome, String> {
    run_chemistry_with_timeout(provider, args, CHEMISTRY_PROVIDER_TIMEOUT)
}

#[derive(Debug)]
struct ProviderProcessOutput {
    status: ExitStatus,
    stdout: Vec<u8>,
    stderr: Vec<u8>,
}

fn run_chemistry_with_timeout(
    provider: &str,
    args: &[String],
    timeout: Duration,
) -> Result<ChemistryOutcome, String> {
    let output = run_bounded_provider(provider, args, timeout)?;
    let parsed_payload = serde_json::from_slice::<Value>(&output.stdout);
    if !output.status.success() {
        if let Ok(payload) = &parsed_payload {
            if let Some(message) = chemistry_protocol_error(payload) {
                return Err(message);
            }
        }
        let stderr = String::from_utf8_lossy(&output.stderr);
        let stderr = bounded_provider_message(stderr.trim());
        return Err(if stderr.is_empty() {
            format!(
                "CENTL Chemistry provider failed with status {}",
                output.status
            )
        } else {
            format!("CENTL Chemistry provider failed: {stderr}")
        });
    }

    let payload = parsed_payload
        .map_err(|error| format!("CENTL Chemistry returned invalid protocol JSON: {error}"))?;
    if payload.get("version").and_then(Value::as_u64) != Some(1) {
        return Err("CENTL Chemistry returned an unsupported protocol version.".to_string());
    }

    let (capability, summary) = match payload.get("kind").and_then(Value::as_str) {
        Some("chemical_formula") => {
            let operand = args.get(1).map(String::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", summarize_formula(&payload, operand)?)
        }
        Some("balanced_reaction") => {
            let operand = args.get(1).map(String::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", summarize_balanced_reaction(&payload, operand)?)
        }
        Some("moles_to_entities") => {
            let entities = payload.get("entities").and_then(Value::as_str).unwrap_or("");
            let moles = payload.get("moles").and_then(Value::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", format!("{} mol = {} entities (N_A exact)", moles, entities))
        }
        Some("entities_to_moles") => {
            let entities = payload.get("entities").and_then(Value::as_str).unwrap_or("");
            let moles = payload.get("moles").and_then(Value::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", format!("{} entities = {} mol", entities, moles))
        }
        Some("stoichiometric_amount_conversion") => {
            let src_mol = payload.get("source_moles").and_then(Value::as_str).unwrap_or("");
            let src_spec = payload.get("source_species").and_then(Value::as_str).unwrap_or("");
            let tgt_mol = payload.get("target_moles").and_then(Value::as_str).unwrap_or("");
            let tgt_spec = payload.get("target_species").and_then(Value::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", format!("{} mol {} → {} mol {}", src_mol, src_spec, tgt_mol, tgt_spec))
        }
        Some("limiting_reagent_amount_result") => {
            let reagent = payload.get("limiting_reagent").and_then(Value::as_str).unwrap_or("");
            let extent = payload.get("extent_moles").and_then(Value::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", format!("Limiting reagent: {} (reaction extent = {} mol)", reagent, extent))
        }
        Some("chemistry_sample_spread") => {
            let mean = payload.get("mean").and_then(Value::as_str).unwrap_or("");
            let std_dev = payload.get("sample_standard_deviation").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", format!("Sample statistics: mean = {} {}, std dev = {} {}", mean, unit, std_dev, unit))
        }
        Some("derived_chemistry_constant") => {
            let sym = payload.get("symbol").and_then(Value::as_str).unwrap_or("");
            let val = payload.get("value").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("");
            let def = payload.get("definition").and_then(Value::as_str).unwrap_or("");
            ("org.fcf.centl.chemistry.compute", format!("{} = {} {} ({})", sym, val, unit, def))
        }
        Some("molar_mass_interval") => {
            let formula = payload.get("formula").and_then(Value::as_str).unwrap_or("");
            let lower = payload.get("lower").and_then(Value::as_str).unwrap_or("");
            let upper = payload.get("upper").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("g/mol");
            let text = if lower == upper {
                format!("M({}) = {} {}", formula, lower, unit)
            } else {
                format!("M({}) = [{}, {}] {}", formula, lower, upper, unit)
            };
            ("org.fcf.centl.chemistry.compute", text)
        }
        Some("concentration") => {
            let val = payload.get("value").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("mol/L");
            ("org.fcf.centl.chemistry.compute", format!("Concentration = {} {}", val, unit))
        }
        Some("dilution") => {
            let val = payload.get("final_concentration").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("mol/L");
            ("org.fcf.centl.chemistry.compute", format!("Final Concentration = {} {}", val, unit))
        }
        Some("percent_yield") => {
            let val = payload.get("percentage").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("%");
            ("org.fcf.centl.chemistry.compute", format!("Percent Yield = {} {}", val, unit))
        }
        Some("ideal_gas_pressure") => {
            let val = payload.get("pressure").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("Pa");
            ("org.fcf.centl.chemistry.compute", format!("Pressure = {} {}", val, unit))
        }
        Some("faraday_charge") => {
            let val = payload.get("charge").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("C");
            ("org.fcf.centl.chemistry.compute", format!("Charge = {} {}", val, unit))
        }
        Some("reaction_enthalpy") => {
            let val = payload.get("enthalpy").and_then(Value::as_str).unwrap_or("");
            let unit = payload.get("unit").and_then(Value::as_str).unwrap_or("kJ/mol");
            ("org.fcf.centl.chemistry.compute", format!("ΔH°_rxn = {} {}", val, unit))
        }
        Some(other) => {
            return Err(format!("CENTL Chemistry returned an unrecognized result kind: {}.", other));
        }
        None => {
            return Err("CENTL Chemistry protocol response omitted kind.".to_string());
        }
    };

    let evidence_document = serde_json::json!({
        "schema": "centl26.chemistry-evidence/1",
        "capability": capability,
        "request": {
            "operation": args[0],
            "operand": args[1],
        },
        "provider": chemistry_provider_identity(provider),
        "host": {
            "product": "CentL26",
            "build_commit": super::build_commit(),
        },
        "response": payload,
    });
    let evidence = serde_json::to_string_pretty(&evidence_document)
        .map_err(|error| format!("Could not preserve chemistry evidence: {}", error))?;
    Ok(ChemistryOutcome { summary, evidence })
}

fn run_bounded_provider(
    provider: &str,
    args: &[String],
    timeout: Duration,
) -> Result<ProviderProcessOutput, String> {
    let mut command = Command::new(provider);
    command
        .arg("--json")
        .args(args)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    #[cfg(unix)]
    unsafe {
        command.pre_exec(|| {
            if provider_setpgid(0, 0) == 0 {
                Ok(())
            } else {
                Err(io::Error::last_os_error())
            }
        });
    }
    let mut child = command.spawn().map_err(|error| {
        format!(
            "CENTL Chemistry provider unavailable ({}): {}",
            provider, error
        )
    })?;
    let provider_group = child.id();

    let stdout = child
        .stdout
        .take()
        .ok_or_else(|| "CENTL Chemistry provider stdout was unavailable.".to_string())?;
    let stderr = child
        .stderr
        .take()
        .ok_or_else(|| "CENTL Chemistry provider stderr was unavailable.".to_string())?;
    let output_exceeded = Arc::new(AtomicBool::new(false));
    let stdout_exceeded = Arc::clone(&output_exceeded);
    let stderr_exceeded = Arc::clone(&output_exceeded);
    let stdout_reader = thread::spawn(move || read_bounded_stream(stdout, stdout_exceeded));
    let stderr_reader = thread::spawn(move || read_bounded_stream(stderr, stderr_exceeded));

    let deadline = Instant::now() + timeout;
    let status = loop {
        match child.try_wait() {
            Ok(Some(status)) => {
                terminate_provider_group(provider_group);
                break Ok(status);
            }
            Ok(None) if output_exceeded.load(Ordering::Acquire) => {
                terminate_provider_group(provider_group);
                let _ = child.kill();
                let _ = child.wait();
                break Err(
                    "CENTL Chemistry provider response exceeded the 256 KiB limit.".to_string(),
                );
            }
            Ok(None) if Instant::now() >= deadline => {
                terminate_provider_group(provider_group);
                let _ = child.kill();
                let _ = child.wait();
                break Err(format!(
                    "CENTL Chemistry provider exceeded its {} second execution limit.",
                    timeout.as_secs_f64()
                ));
            }
            Ok(None) => thread::sleep(PROVIDER_POLL_INTERVAL),
            Err(error) => {
                terminate_provider_group(provider_group);
                let _ = child.kill();
                let _ = child.wait();
                break Err(format!(
                    "CENTL Chemistry provider status could not be read: {error}"
                ));
            }
        }
    };

    let stdout = join_provider_reader(stdout_reader, "stdout")?;
    let stderr = join_provider_reader(stderr_reader, "stderr")?;
    let status = status?;
    if output_exceeded.load(Ordering::Acquire)
        || stdout.len() > MAX_PROVIDER_OUTPUT_BYTES
        || stderr.len() > MAX_PROVIDER_OUTPUT_BYTES
    {
        return Err("CENTL Chemistry provider response exceeded the 256 KiB limit.".to_string());
    }
    Ok(ProviderProcessOutput {
        status,
        stdout,
        stderr,
    })
}

fn terminate_provider_group(process_group: u32) {
    #[cfg(unix)]
    if let Ok(process_group) = i32::try_from(process_group) {
        unsafe {
            let _ = provider_kill(-process_group, PROVIDER_KILL_SIGNAL);
        }
    }
    #[cfg(not(unix))]
    let _ = process_group;
}

fn read_bounded_stream<R: Read>(mut reader: R, exceeded: Arc<AtomicBool>) -> io::Result<Vec<u8>> {
    let mut captured = Vec::with_capacity(8192);
    let mut chunk = [0u8; 8192];
    loop {
        let count = reader.read(&mut chunk)?;
        if count == 0 {
            return Ok(captured);
        }
        let remaining = (MAX_PROVIDER_OUTPUT_BYTES + 1).saturating_sub(captured.len());
        if remaining > 0 {
            captured.extend_from_slice(&chunk[..count.min(remaining)]);
        }
        if captured.len() > MAX_PROVIDER_OUTPUT_BYTES || count > remaining {
            exceeded.store(true, Ordering::Release);
        }
    }
}

fn join_provider_reader(
    reader: thread::JoinHandle<io::Result<Vec<u8>>>,
    stream_name: &str,
) -> Result<Vec<u8>, String> {
    reader
        .join()
        .map_err(|_| format!("CENTL Chemistry provider {stream_name} reader failed."))?
        .map_err(|error| {
            format!("CENTL Chemistry provider {stream_name} could not be read: {error}")
        })
}

fn chemistry_protocol_error(payload: &Value) -> Option<String> {
    if payload.get("version").and_then(Value::as_u64) != Some(1)
        || payload.get("kind").and_then(Value::as_str) != Some("chemistry_error")
    {
        return None;
    }
    let code = payload.get("code")?.as_str()?;
    let message = payload.get("error")?.as_str()?;
    if code.is_empty()
        || code.len() > 96
        || !code
            .bytes()
            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'_')
    {
        return None;
    }
    Some(format!(
        "CENTL Chemistry refused the request [{code}]: {}",
        bounded_provider_message(message)
    ))
}

fn bounded_provider_message(message: &str) -> String {
    const MAX_MESSAGE_CHARS: usize = 512;
    let mut characters = message.chars();
    let bounded: String = characters.by_ref().take(MAX_MESSAGE_CHARS).collect();
    if characters.next().is_some() {
        format!("{bounded}…")
    } else {
        bounded
    }
}

fn chemistry_provider_identity(provider: &str) -> Value {
    let configured_binary: String = provider.chars().take(1024).collect();
    let mut identity = serde_json::json!({
        "id": "centl-chem",
        "configured_binary": configured_binary,
        "protocol_version": 1,
    });
    let Some(manifest_path) = env::var_os("CENTL26_PROVIDER_MANIFEST") else {
        return identity;
    };
    let Ok(file) = std::fs::File::open(manifest_path) else {
        return identity;
    };
    let mut bytes = Vec::new();
    if file
        .take((MAX_PROVIDER_OUTPUT_BYTES + 1) as u64)
        .read_to_end(&mut bytes)
        .is_err()
        || bytes.len() > MAX_PROVIDER_OUTPUT_BYTES
    {
        return identity;
    }
    let Ok(manifest) = serde_json::from_slice::<Value>(&bytes) else {
        return identity;
    };
    let Some(record) = manifest
        .get("providers")
        .and_then(Value::as_array)
        .and_then(|providers| {
            providers
                .iter()
                .find(|item| item.get("id").and_then(Value::as_str) == Some("centl-chem"))
        })
    else {
        return identity;
    };
    if let Some(object) = identity.as_object_mut() {
        object.insert("inventory_record".to_string(), record.clone());
        if let Some(commit) = manifest.get("build_commit").and_then(Value::as_str) {
            object.insert(
                "inventory_build_commit".to_string(),
                Value::String(commit.to_string()),
            );
        }
    }
    identity
}

fn summarize_formula(payload: &Value, requested_formula: &str) -> Result<String, String> {
    let formula = required_json_string(payload, "formula")?;
    if formula != requested_formula.trim() {
        return Err("CENTL Chemistry formula evidence did not match the request.".to_string());
    }
    let atoms = payload
        .get("atoms")
        .and_then(Value::as_array)
        .ok_or_else(|| "CENTL Chemistry formula evidence omitted atom counts.".to_string())?;
    if atoms.is_empty() {
        return Err("CENTL Chemistry formula evidence contained no atoms.".to_string());
    }
    let mut counts = Vec::with_capacity(atoms.len());
    let mut previous_element: Option<&str> = None;
    for atom in atoms {
        let element = required_json_string(atom, "element")?;
        if !valid_element_symbol(element)
            || previous_element.is_some_and(|previous| previous >= element)
        {
            return Err(
                "CENTL Chemistry formula evidence contained invalid or duplicate elements."
                    .to_string(),
            );
        }
        let count = required_json_string(atom, "count")?;
        canonical_positive_decimal(count)?;
        counts.push(format!("{}={}", element, count));
        previous_element = Some(element);
    }
    Ok(format!("{} — {}", formula, counts.join(" · ")))
}

#[derive(Debug, Eq, PartialEq)]
struct RequestedSpecies {
    formula: String,
    input_coefficient: String,
}

fn summarize_balanced_reaction(
    payload: &Value,
    requested_reaction: &str,
) -> Result<String, String> {
    if payload.get("verified").and_then(Value::as_bool) != Some(true) {
        return Err("CENTL Chemistry did not verify atom conservation.".to_string());
    }
    let equation = required_json_string(payload, "equation")?;
    let (requested_reactants, requested_products) = parse_requested_reaction(requested_reaction)?;
    let coefficients = payload
        .get("coefficients")
        .ok_or_else(|| "CENTL Chemistry omitted canonical coefficients.".to_string())?;
    let reactant_coefficients = positive_decimal_array(coefficients, "reactants")?;
    let product_coefficients = positive_decimal_array(coefficients, "products")?;
    if reactant_coefficients.len() != requested_reactants.len()
        || product_coefficients.len() != requested_products.len()
    {
        return Err(
            "CENTL Chemistry coefficient dimensions did not match the request.".to_string(),
        );
    }

    let evidence = payload
        .get("stoichiometric_evidence")
        .ok_or_else(|| "CENTL Chemistry omitted stoichiometric evidence.".to_string())?;
    if evidence.get("sign_convention").and_then(Value::as_str)
        != Some("reactants_positive_products_negative")
    {
        return Err("CENTL Chemistry returned an unsupported matrix sign convention.".to_string());
    }
    let columns = evidence
        .get("columns")
        .ok_or_else(|| "CENTL Chemistry omitted reaction column evidence.".to_string())?;
    validate_species_columns(columns, "reactants", &requested_reactants)?;
    validate_species_columns(columns, "products", &requested_products)?;

    let expected_equation = render_verified_equation(
        &reactant_coefficients,
        &requested_reactants,
        &product_coefficients,
        &requested_products,
    );
    if equation != expected_equation {
        return Err(
            "CENTL Chemistry equation did not match its coefficients and request.".to_string(),
        );
    }

    let element_values = evidence
        .get("elements")
        .and_then(Value::as_array)
        .ok_or_else(|| "CENTL Chemistry omitted element-row evidence.".to_string())?;
    if element_values.is_empty() {
        return Err("CENTL Chemistry returned no element rows.".to_string());
    }
    let mut elements = Vec::with_capacity(element_values.len());
    for value in element_values {
        let element = value
            .as_str()
            .ok_or_else(|| "CENTL Chemistry element rows must be text.".to_string())?;
        if !valid_element_symbol(element)
            || elements
                .last()
                .is_some_and(|previous: &&str| *previous >= element)
        {
            return Err("CENTL Chemistry element rows were invalid or duplicated.".to_string());
        }
        elements.push(element);
    }

    let matrix = evidence
        .get("matrix")
        .and_then(Value::as_array)
        .ok_or_else(|| "CENTL Chemistry omitted its exact stoichiometric matrix.".to_string())?;
    if matrix.len() != elements.len() {
        return Err("CENTL Chemistry matrix row count did not match its elements.".to_string());
    }
    let conservation = payload
        .get("conservation")
        .and_then(Value::as_array)
        .ok_or_else(|| "CENTL Chemistry omitted conservation evidence.".to_string())?;
    if conservation.len() != elements.len() {
        return Err("CENTL Chemistry conservation rows did not match its elements.".to_string());
    }

    let column_count = requested_reactants.len() + requested_products.len();
    for (row_index, row_value) in matrix.iter().enumerate() {
        let row = row_value
            .as_array()
            .ok_or_else(|| "CENTL Chemistry matrix rows must be arrays.".to_string())?;
        if row.len() != column_count {
            return Err("CENTL Chemistry matrix column count was inconsistent.".to_string());
        }
        let mut computed_reactants = "0".to_string();
        let mut computed_products = "0".to_string();
        for (index, coefficient) in reactant_coefficients.iter().enumerate() {
            let entry = row[index]
                .as_str()
                .ok_or_else(|| "CENTL Chemistry matrix entries must be text.".to_string())?;
            let atom_count = canonical_nonnegative_decimal(entry)?;
            computed_reactants = decimal_add(
                &computed_reactants,
                &decimal_multiply(atom_count, coefficient),
            );
        }
        for (index, coefficient) in product_coefficients.iter().enumerate() {
            let entry = row[requested_reactants.len() + index]
                .as_str()
                .ok_or_else(|| "CENTL Chemistry matrix entries must be text.".to_string())?;
            let atom_count = canonical_nonpositive_decimal_magnitude(entry)?;
            computed_products = decimal_add(
                &computed_products,
                &decimal_multiply(atom_count, coefficient),
            );
        }

        let item = conservation[row_index]
            .as_object()
            .ok_or_else(|| "CENTL Chemistry conservation rows must be objects.".to_string())?;
        let element = item.get("element").and_then(Value::as_str).ok_or_else(|| {
            "CENTL Chemistry conservation evidence omitted an element.".to_string()
        })?;
        let reported_reactants =
            item.get("reactants")
                .and_then(Value::as_str)
                .ok_or_else(|| {
                    "CENTL Chemistry conservation evidence omitted reactant counts.".to_string()
                })?;
        let reported_products = item
            .get("products")
            .and_then(Value::as_str)
            .ok_or_else(|| {
                "CENTL Chemistry conservation evidence omitted product counts.".to_string()
            })?;
        canonical_positive_decimal(reported_reactants)?;
        canonical_positive_decimal(reported_products)?;
        if element != elements[row_index]
            || item.get("verified").and_then(Value::as_bool) != Some(true)
            || reported_reactants != reported_products
            || reported_reactants != computed_reactants
            || reported_products != computed_products
        {
            return Err(
                "CENTL Chemistry conservation evidence failed independent verification."
                    .to_string(),
            );
        }
    }

    Ok(format!(
        "{}\nAtom conservation verified across {}.",
        equation.replace(" -> ", " → "),
        elements.join(", ")
    ))
}

fn parse_requested_reaction(
    reaction: &str,
) -> Result<(Vec<RequestedSpecies>, Vec<RequestedSpecies>), String> {
    let Some((left, right)) = reaction.trim().split_once("->") else {
        return Err("CENTL Chemistry request omitted its reaction arrow.".to_string());
    };
    if right.contains("->") {
        return Err("CENTL Chemistry request contained multiple reaction arrows.".to_string());
    }
    let reactants = parse_requested_species_side(left)?;
    let products = parse_requested_species_side(right)?;
    Ok((reactants, products))
}

fn parse_requested_species_side(side: &str) -> Result<Vec<RequestedSpecies>, String> {
    let species = side
        .split('+')
        .map(parse_requested_species)
        .collect::<Result<Vec<_>, String>>()?;
    if species.is_empty() {
        return Err("CENTL Chemistry request contained an empty reaction side.".to_string());
    }
    Ok(species)
}

fn parse_requested_species(value: &str) -> Result<RequestedSpecies, String> {
    let value = value.trim();
    if value.is_empty() {
        return Err("CENTL Chemistry request contained an empty species.".to_string());
    }
    let digit_count = value.bytes().take_while(u8::is_ascii_digit).count();
    let (coefficient, formula) = if digit_count == 0 {
        ("1".to_string(), value)
    } else {
        (
            normalize_positive_decimal(&value[..digit_count])?,
            value[digit_count..].trim(),
        )
    };
    if formula.is_empty() {
        return Err(
            "CENTL Chemistry request contained a coefficient without a formula.".to_string(),
        );
    }
    Ok(RequestedSpecies {
        formula: formula.to_string(),
        input_coefficient: coefficient,
    })
}

fn positive_decimal_array<'a>(payload: &'a Value, field: &str) -> Result<Vec<&'a str>, String> {
    let values = payload
        .get(field)
        .and_then(Value::as_array)
        .ok_or_else(|| format!("CENTL Chemistry coefficient list was missing: {field}."))?;
    if values.is_empty() {
        return Err(format!(
            "CENTL Chemistry coefficient list was empty: {field}."
        ));
    }
    values
        .iter()
        .map(|value| {
            let text = value
                .as_str()
                .ok_or_else(|| format!("CENTL Chemistry coefficients must be text: {field}."))?;
            canonical_positive_decimal(text)
        })
        .collect()
}

fn validate_species_columns(
    columns: &Value,
    field: &str,
    expected: &[RequestedSpecies],
) -> Result<(), String> {
    let values = columns
        .get(field)
        .and_then(Value::as_array)
        .ok_or_else(|| format!("CENTL Chemistry reaction columns were missing: {field}."))?;
    if values.len() != expected.len() {
        return Err(format!(
            "CENTL Chemistry reaction column count did not match: {field}."
        ));
    }
    for (value, expected_species) in values.iter().zip(expected) {
        let formula = required_json_string(value, "formula")?;
        let coefficient = required_json_string(value, "input_coefficient")?;
        canonical_positive_decimal(coefficient)?;
        if formula != expected_species.formula || coefficient != expected_species.input_coefficient
        {
            return Err(
                "CENTL Chemistry reaction columns did not match the submitted reaction."
                    .to_string(),
            );
        }
    }
    Ok(())
}

fn render_verified_equation(
    reactant_coefficients: &[&str],
    reactants: &[RequestedSpecies],
    product_coefficients: &[&str],
    products: &[RequestedSpecies],
) -> String {
    fn render_side(coefficients: &[&str], species: &[RequestedSpecies]) -> String {
        coefficients
            .iter()
            .zip(species)
            .map(|(coefficient, species)| {
                if *coefficient == "1" {
                    species.formula.clone()
                } else {
                    format!("{} {}", coefficient, species.formula)
                }
            })
            .collect::<Vec<_>>()
            .join(" + ")
    }
    format!(
        "{} -> {}",
        render_side(reactant_coefficients, reactants),
        render_side(product_coefficients, products)
    )
}

fn valid_element_symbol(value: &str) -> bool {
    let bytes = value.as_bytes();
    (1..=3).contains(&bytes.len())
        && bytes[0].is_ascii_uppercase()
        && bytes[1..].iter().all(u8::is_ascii_lowercase)
}

fn canonical_positive_decimal(value: &str) -> Result<&str, String> {
    if value.is_empty()
        || value.len() > 4096
        || value.as_bytes()[0] == b'0'
        || !value.bytes().all(|byte| byte.is_ascii_digit())
    {
        return Err(
            "CENTL Chemistry evidence contained a non-canonical positive integer.".to_string(),
        );
    }
    Ok(value)
}

fn canonical_nonnegative_decimal(value: &str) -> Result<&str, String> {
    if value == "0" {
        return Ok(value);
    }
    canonical_positive_decimal(value)
}

fn canonical_nonpositive_decimal_magnitude(value: &str) -> Result<&str, String> {
    if value == "0" {
        return Ok(value);
    }
    let magnitude = value.strip_prefix('-').ok_or_else(|| {
        "CENTL Chemistry product matrix entries must be non-positive integers.".to_string()
    })?;
    canonical_positive_decimal(magnitude)
}

fn normalize_positive_decimal(value: &str) -> Result<String, String> {
    if value.is_empty() || !value.bytes().all(|byte| byte.is_ascii_digit()) {
        return Err("CENTL Chemistry request contained an invalid coefficient.".to_string());
    }
    let normalized = value.trim_start_matches('0');
    if normalized.is_empty() {
        return Err("CENTL Chemistry request coefficients must be positive.".to_string());
    }
    Ok(normalized.to_string())
}

fn decimal_add(left: &str, right: &str) -> String {
    let mut carry = 0u16;
    let mut result = Vec::with_capacity(left.len().max(right.len()) + 1);
    let mut left_digits = left.bytes().rev();
    let mut right_digits = right.bytes().rev();
    loop {
        let left_digit = left_digits.next().map(|byte| (byte - b'0') as u16);
        let right_digit = right_digits.next().map(|byte| (byte - b'0') as u16);
        if left_digit.is_none() && right_digit.is_none() && carry == 0 {
            break;
        }
        let sum = left_digit.unwrap_or(0) + right_digit.unwrap_or(0) + carry;
        result.push((sum % 10) as u8 + b'0');
        carry = sum / 10;
    }
    result.reverse();
    String::from_utf8(result).expect("decimal addition emits ASCII")
}

fn decimal_multiply(left: &str, right: &str) -> String {
    if left == "0" || right == "0" {
        return "0".to_string();
    }
    const LIMB_DIGITS: usize = 9;
    const BASE: u128 = 1_000_000_000;
    fn limbs(value: &str) -> Vec<u128> {
        let mut result = Vec::with_capacity((value.len() + LIMB_DIGITS - 1) / LIMB_DIGITS);
        let mut end = value.len();
        while end > 0 {
            let start = end.saturating_sub(LIMB_DIGITS);
            result.push(
                value[start..end]
                    .parse::<u128>()
                    .expect("validated decimal limb"),
            );
            end = start;
        }
        result
    }

    let left_limbs = limbs(left);
    let right_limbs = limbs(right);
    let mut product = vec![0u128; left_limbs.len() + right_limbs.len()];
    for (left_index, left_limb) in left_limbs.iter().enumerate() {
        for (right_index, right_limb) in right_limbs.iter().enumerate() {
            product[left_index + right_index] += left_limb * right_limb;
        }
    }
    for index in 0..product.len() - 1 {
        let carry = product[index] / BASE;
        product[index] %= BASE;
        product[index + 1] += carry;
    }
    while product.last() == Some(&0) {
        product.pop();
    }
    let mut reversed = product.into_iter().rev();
    let mut rendered = reversed.next().expect("nonzero product").to_string();
    for limb in reversed {
        rendered.push_str(&format!("{limb:09}"));
    }
    rendered
}

fn required_json_string<'a>(payload: &'a Value, field: &str) -> Result<&'a str, String> {
    payload
        .get(field)
        .and_then(Value::as_str)
        .ok_or_else(|| format!("CENTL Chemistry evidence omitted {}.", field))
}

fn record_physics_history(
    command: &str,
    result: &PhysicsResult,
    execution_micros: u128,
    state: &mut AppState,
) {
    let evidence = serde_json::json!({
        "schema": "centl26.domain-evidence/1",
        "capability": "org.fcf.centl.physics.compute",
        "provider": "centl26.physics",
        "host_build_commit": super::build_commit(),
        "representation": "binary64-deterministic-model",
        "response": {
            "title": result.title,
            "details": result.details,
            "summary": result.summary,
            "verified": result.verified,
        }
    });
    state.session_mut().history.push(HistoryEntry {
        command: command.to_string(),
        result: result.summary.clone(),
        exact_repr: Some(
            serde_json::to_string_pretty(&evidence)
                .expect("serde_json::Value evidence is always serializable"),
        ),
        approximate_repr: Some(
            "Deterministic binary64 model; inspect the preserved verification evidence."
                .to_string(),
        ),
        execution_micros,
        success: true,
    });
}

fn record_solve_history(
    command: &str,
    execution: &ExecutionResult,
    solve: &SolveResult,
    state: &mut AppState,
) {
    let evidence = serde_json::json!({
        "schema": "centl26.domain-evidence/1",
        "capability": "org.fcf.centl.research.erdos_straus/solve",
        "provider": "centl26.research",
        "host_build_commit": super::build_commit(),
        "response": solve_result_evidence(solve),
    });
    let exact_witness = solve
        .witness
        .as_ref()
        .is_some_and(|witness| witness.verified && witness.verify());
    state.session_mut().history.push(HistoryEntry {
        command: command.to_string(),
        result: execution.text.clone(),
        exact_repr: Some(
            serde_json::to_string_pretty(&evidence)
                .expect("serde_json::Value evidence is always serializable"),
        ),
        approximate_repr: (!exact_witness).then(|| {
            "Bounded solver status; absence of a witness is not a universal conclusion.".to_string()
        }),
        execution_micros: solve.execution_micros,
        success: true,
    });
}

fn record_hunt_history(command: &str, hunt: &HuntSummary, state: &mut AppState) {
    let findings: Vec<Value> = hunt.findings.iter().map(solve_result_evidence).collect();
    let evidence = serde_json::json!({
        "schema": "centl26.domain-evidence/1",
        "capability": "org.fcf.centl.research.erdos_straus/hunt",
        "provider": "centl26.research",
        "host_build_commit": super::build_commit(),
        "bounded": true,
        "response": {
            "start_bound": hunt.start_bound.to_string(),
            "end_bound": hunt.end_bound.to_string(),
            "primes_checked": hunt.primes_checked.to_string(),
            "great_count": hunt.great_count.to_string(),
            "good_count": hunt.good_count.to_string(),
            "letter_count": hunt.letter_count.to_string(),
            "unsolved_count": hunt.unsolved_count.to_string(),
            "execution_millis": hunt.execution_millis.to_string(),
            "findings": findings,
        }
    });
    let summary = format!(
        "Window ({}, {}] · {} primes · {} great · {} good · {} letters · {} unsolved",
        hunt.start_bound,
        hunt.end_bound,
        hunt.primes_checked,
        hunt.great_count,
        hunt.good_count,
        hunt.letter_count,
        hunt.unsolved_count
    );
    state.session_mut().history.push(HistoryEntry {
        command: command.to_string(),
        result: summary,
        exact_repr: Some(
            serde_json::to_string_pretty(&evidence)
                .expect("serde_json::Value evidence is always serializable"),
        ),
        approximate_repr: Some(format!(
            "Bounded search over ({}, {}]; exact witnesses are preserved in evidence.",
            hunt.start_bound, hunt.end_bound
        )),
        execution_micros: hunt.execution_millis.saturating_mul(1000),
        success: true,
    });
}

fn solve_result_evidence(solve: &SolveResult) -> Value {
    let witness = solve.witness.as_ref().map(|witness| {
        serde_json::json!({
            "n": witness.n.to_string(),
            "x": witness.x.to_string(),
            "y": witness.y.to_string(),
            "z": witness.z.to_string(),
            "equation": witness.equation(),
            "method": witness.method,
            "layer": witness.layer,
            "kind": witness.kind,
            "provider_verified": witness.verified,
            "broker_verified": witness.verify(),
        })
    });
    serde_json::json!({
        "solved": solve.solved,
        "n": solve.n.to_string(),
        "grade": solve.grade,
        "letter_number": solve.letter_number,
        "execution_micros": solve.execution_micros.to_string(),
        "witness": witness,
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

fn named_u64(parts: &[&str], name: &str) -> Option<u64> {
    parts.iter().find_map(|part| {
        let (key, value) = part.split_once('=')?;
        if key.eq_ignore_ascii_case(name) {
            value.parse::<u64>().ok()
        } else {
            None
        }
    })
}

fn named_vec3(parts: &[&str], name: &str) -> Option<(f64, f64, f64)> {
    parts.iter().find_map(|part| {
        let (key, value) = part.split_once('=')?;
        if key.eq_ignore_ascii_case(name) {
            let coords: Vec<&str> = value.split(',').collect();
            if coords.len() == 3 {
                let x = coords[0].trim().parse::<f64>().ok()?;
                let y = coords[1].trim().parse::<f64>().ok()?;
                let z = coords[2].trim().parse::<f64>().ok()?;
                Some((x, y, z))
            } else {
                None
            }
        } else {
            None
        }
    })
}

fn handle_cps_command(
    command: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let body = command["cps".len()..].trim();
    let tokens = tokenize_command_args(body);
    if tokens.is_empty() || tokens[0] != "preflight" {
        return (
            None,
            Some("Usage: cps preflight [measured|exact] FORMULA=MOLES ...".to_string()),
            None,
            None,
        );
    }
    let provider = super::capabilities::cps_provider().command;
    let started = Instant::now();
    let output = match run_bounded_provider(&provider, &tokens, CHEMISTRY_PROVIDER_TIMEOUT) {
        Ok(out) => out,
        Err(error) => {
            return (
                None,
                Some(format!("CENTL Chemical Process Systems (CPS) engine unavailable: {}", error)),
                None,
                None,
            );
        }
    };
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return (
            None,
            Some(if stderr.is_empty() {
                format!("CPS preflight failed with status {}", output.status)
            } else {
                stderr.trim().to_string()
            }),
            None,
            None,
        );
    }
    let payload: Value = match serde_json::from_slice(&output.stdout) {
        Ok(v) => v,
        Err(e) => return (None, Some(format!("CPS returned invalid protocol JSON: {}", e)), None, None),
    };
    let species_count = payload.get("species").and_then(Value::as_array).map(|a| a.len()).unwrap_or(0);
    let total_moles = payload.get("total_species_moles").and_then(Value::as_str).unwrap_or("0");
    let summary = format!("CPS Preflight: composition validated ({} species, {} total mol).", species_count, total_moles);
    let evidence_doc = serde_json::json!({
        "schema": "centl26.cps-evidence/1",
        "capability": "org.fcf.centl.cps.preflight",
        "request": command,
        "provider": provider,
        "host": {
            "product": "CentL26",
            "build_commit": super::build_commit(),
        },
        "response": payload,
    });
    let evidence = serde_json::to_string_pretty(&evidence_doc).unwrap_or_default();
    let elapsed = started.elapsed().as_micros();
    let result = ExecutionResult {
        text: summary.clone(),
        exact_rational: None,
        approximate: None,
        symbolic_expr: None,
        execution_micros: elapsed,
    };
    state.session_mut().history.push(HistoryEntry {
        command: command.to_string(),
        result: summary,
        exact_repr: Some(evidence),
        approximate_repr: None,
        execution_micros: elapsed,
        success: true,
    });
    (Some(result), None, None, None)
}

fn handle_sci_command(
    command: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let body = if command.starts_with("sci ") {
        command["sci ".len()..].trim()
    } else if command.starts_with(":gemini ") {
        command[":gemini ".len()..].trim()
    } else if command.starts_with("gemini ") {
        command["gemini ".len()..].trim()
    } else if command.starts_with(":ai ") {
        command[":ai ".len()..].trim()
    } else if command.starts_with("ai ") {
        command["ai ".len()..].trim()
    } else {
        command.trim()
    };
    let prefer_gemini = command.starts_with(":gemini") || command.starts_with("gemini")
        || command.starts_with(":ai") || command.starts_with("ai");
    let provider = super::capabilities::sci_provider().command;
    let started = Instant::now();

    // 1. Try external centl-sci provider if available and not explicitly preferring Gemini
    if !prefer_gemini {
        if let Ok(output) = run_bounded_provider(&provider, &["--json".to_string(), body.to_string()], CHEMISTRY_PROVIDER_TIMEOUT) {
            if output.status.success() {
                if let Ok(payload) = serde_json::from_slice::<Value>(&output.stdout) {
                    let summary = payload.get("summary").and_then(Value::as_str).or_else(|| payload.get("answer").and_then(Value::as_str)).unwrap_or("SCi interpretation completed.").to_string();
                    let evidence_doc = serde_json::json!({
                        "schema": "centl26.sci-evidence/1",
                        "capability": "org.fcf.centl.sci.interpret",
                        "request": command,
                        "provider": provider,
                        "host": {
                            "product": "CentL26",
                            "build_commit": super::build_commit(),
                        },
                        "response": payload,
                    });
                    let evidence = serde_json::to_string_pretty(&evidence_doc).unwrap_or_default();
                    let elapsed = started.elapsed().as_micros();
                    let result = ExecutionResult {
                        text: summary.clone(),
                        exact_rational: None,
                        approximate: None,
                        symbolic_expr: None,
                        execution_micros: elapsed,
                    };
                    state.session_mut().history.push(HistoryEntry {
                        command: command.to_string(),
                        result: summary,
                        exact_repr: Some(evidence),
                        approximate_repr: None,
                        execution_micros: elapsed,
                        success: true,
                    });
                    return (Some(result), None, None, None);
                }
            }
        }
    }

    // 2. Native Offline SCi Solver & Hybrid Gemini STEM Solver
    match crate::engine::sci::interpret_and_solve_stem(body, state.session_mut(), prefer_gemini) {
        Ok(solution) => {
            let elapsed = started.elapsed().as_micros();
            let mut formatted_text = format!("SCi Solution [{} · {}]:\n{}\n", solution.domain, solution.confidence, solution.summary);
            for step in &solution.steps {
                formatted_text.push_str(&format!("\n• {}", step));
            }
            if let Some(ref exact) = solution.exact_result {
                formatted_text.push_str(&format!("\n\nExact Result: {}", exact));
            }
            if let Some(ref approx) = solution.approximate_result {
                formatted_text.push_str(&format!("\nApproximate Bound: {}", approx));
            }

            let evidence_doc = serde_json::json!({
                "schema": "centl26.sci-evidence/1",
                "capability": "org.fcf.centl.sci.interpret",
                "request": command,
                "provider": if prefer_gemini { "gemini-hybrid" } else { "centl-sci-native" },
                "domain": solution.domain,
                "confidence": solution.confidence,
                "raw_command": solution.raw_centl_command,
                "host": {
                    "product": "CentL26",
                    "build_commit": super::build_commit(),
                },
                "solution": {
                    "summary": solution.summary,
                    "steps": solution.steps,
                    "exact_result": solution.exact_result,
                    "approximate_result": solution.approximate_result
                }
            });
            let evidence = serde_json::to_string_pretty(&evidence_doc).unwrap_or_default();
            let result = ExecutionResult {
                text: formatted_text.clone(),
                exact_rational: None,
                approximate: solution.approximate_result,
                symbolic_expr: None,
                execution_micros: elapsed,
            };
            state.session_mut().history.push(HistoryEntry {
                command: command.to_string(),
                result: formatted_text,
                exact_repr: Some(evidence),
                approximate_repr: None,
                execution_micros: elapsed,
                success: true,
            });
            (Some(result), None, None, None)
        }
        Err(err) => (None, Some(err), None, None),
    }
}

fn handle_build_command(
    command: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let started = Instant::now();
    // 1. Run native in-app extension builder
    match crate::engine::extensions::handle_build_command(command, state.session_mut()) {
        Ok(outcome) => {
            let mut formatted = format!("=== {} ===\n{}\n", outcome.title, outcome.summary);
            for step in &outcome.steps {
                formatted.push_str(&format!("  {}\n", step));
            }
            if let Some(ref exact) = outcome.exact_result {
                formatted.push_str(&format!("\nResult: {}\n", exact));
            }
            let formatted_text = formatted.trim().to_string();
            let elapsed = started.elapsed().as_micros();
            let result = ExecutionResult {
                text: formatted_text.clone(),
                exact_rational: None,
                approximate: None,
                symbolic_expr: None,
                execution_micros: elapsed,
            };
            let evidence = serde_json::to_string(&outcome.evidence).unwrap_or_else(|_| "{}".to_string());
            state.session_mut().history.push(HistoryEntry {
                command: command.to_string(),
                result: formatted_text,
                exact_repr: Some(evidence),
                approximate_repr: None,
                execution_micros: elapsed,
                success: true,
            });
            (Some(result), None, None, None)
        }
        Err(err) => {
            // 2. Fallback to external provider if requested
            let body = command
                .strip_prefix("build")
                .or_else(|| command.strip_prefix("mirage"))
                .unwrap_or(command)
                .trim();
            let tokens = tokenize_command_args(body);
            let provider = super::capabilities::mirage_provider().command;
            if let Ok(output) = run_bounded_provider(&provider, &tokens, CHEMISTRY_PROVIDER_TIMEOUT) {
                if output.status.success() {
                    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
                    let elapsed = started.elapsed().as_micros();
                    let result = ExecutionResult {
                        text: stdout.clone(),
                        exact_rational: None,
                        approximate: None,
                        symbolic_expr: None,
                        execution_micros: elapsed,
                    };
                    state.session_mut().history.push(HistoryEntry {
                        command: command.to_string(),
                        result: stdout,
                        exact_repr: None,
                        approximate_repr: None,
                        execution_micros: elapsed,
                        success: true,
                    });
                    return (Some(result), None, None, None);
                }
            }
            (None, Some(err), None, None)
        }
    }
}

fn handle_caravan_command(
    command: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let body = command.strip_prefix("caravan").unwrap_or(command).trim();
    let tokens = tokenize_command_args(body);
    let provider = super::capabilities::canonical_math_provider().command;
    let mut args = vec!["caravan".to_string()];
    args.extend(tokens);
    let started = Instant::now();
    let output = match run_bounded_provider(&provider, &args, CHEMISTRY_PROVIDER_TIMEOUT) {
        Ok(out) => out,
        Err(error) => {
            return (
                None,
                Some(format!("CENTL Caravan provider unavailable: {}", error)),
                None,
                None,
            );
        }
    };
    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
    if !output.status.success() {
        return (
            None,
            Some(if stderr.is_empty() {
                format!("Caravan failed with status {}", output.status)
            } else {
                stderr
            }),
            None,
            None,
        );
    }
    let text = if stdout.is_empty() {
        "Caravan inspection completed.".to_string()
    } else {
        stdout
    };
    let elapsed = started.elapsed().as_micros();
    let result = ExecutionResult {
        text: text.clone(),
        exact_rational: None,
        approximate: None,
        symbolic_expr: None,
        execution_micros: elapsed,
    };
    state.session_mut().history.push(HistoryEntry {
        command: command.to_string(),
        result: text,
        exact_repr: None,
        approximate_repr: None,
        execution_micros: elapsed,
        success: true,
    });
    (Some(result), None, None, None)
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
    page.push_str(
        "  <header class=\"masthead home-masthead\" id=\"centl-hub\" tabindex=\"-1\" autofocus>\n",
    );
    page.push_str(&format!("    <div class=\"brand\"><a href=\"{}index.html#top\"><strong>FCF</strong><span>Free Computation Foundation</span><small>Free for science.</small></a></div>\n", rel));
    page.push_str("  </header>\n");
    page.push_str("  <div class=\"layout\">\n");
    page.push_str("    <nav aria-label=\"Primary\">\n");
    page.push_str("      <h2>CENTL &amp; Hub</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str("        <li><a href=\"/hub#top\">CENTL Work Area</a></li>\n");
    page.push_str(&format!(
        "        <li><a href=\"{}centl.html#top\">About CENTL</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}research-erdos-straus.html#top\">Erdős–Straus Hunt</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}software.html#top\">Software Suite</a></li>\n",
        rel
    ));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Documentation</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!(
        "        <li><a href=\"{}docs.html#top\">Documentation Portal</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}manuals/install.html#top\">Installation Guide</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}manuals/numerics.html#top\">Numerical Contract</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}manuals/syntax.html#top\">Syntax &amp; Functions</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}manuals/sci.html#top\">CENTL-SCi &amp; Physics</a></li>\n",
        rel
    ));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Research</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!(
        "        <li><a href=\"{}research.html#top\">Research Library</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}research-erdos-straus.html#top\">Erdős–Straus Program</a></li>\n",
        rel
    ));
    page.push_str(&format!("        <li><a href=\"{}bryan-recursive-entanglement-calculus.html#top\">BREC v1.0 Calculus</a></li>\n", rel));
    page.push_str("      </ul>\n");
    page.push_str("      <h2>Foundation</h2>\n");
    page.push_str("      <ul>\n");
    page.push_str(&format!(
        "        <li><a href=\"{}about.html#top\">About FCF</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}funding.html#top\">Funding &amp; Sponsors</a></li>\n",
        rel
    ));
    page.push_str(&format!(
        "        <li><a href=\"{}mirrors.html#top\">The Bazaar</a></li>\n",
        rel
    ));
    page.push_str(
        "        <li><a href=\"https://github.com/chasebryan/centl\">GitHub Repository</a></li>\n",
    );
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
            notebooks: vec![("Notebook 01".to_string(), Session::new())], active_notebook: 0,
        };
        let (_, error, physics, _) = handle_command("physics nonsense", &mut state);
        assert!(error.is_some());
        assert!(physics.is_none());
    }

    #[test]
    fn physics_and_research_runs_preserve_typed_restart_evidence() {
        let mut state = AppState {
            notebooks: vec![("Notebook 01".to_string(), Session::new())], active_notebook: 0,
        };
        let (_, error, physics, _) = handle_command("physics convert 100 cm m", &mut state);
        assert!(error.is_none());
        assert!(physics.is_some());
        assert_eq!(state.session().history.len(), 1);
        assert!(state.session().history[0]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("org.fcf.centl.physics.compute"));
        assert!(state.session().history[0].approximate_repr.is_some());

        let (solve, error, _, _) = handle_command("es solve 1009", &mut state);
        assert!(error.is_none());
        assert!(solve.is_some());
        assert_eq!(state.session().history.len(), 2);
        assert!(state.session().history[1]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("broker_verified"));

        let (_, error, _, hunt) = handle_command("es", &mut state);
        assert!(error.is_none());
        assert!(hunt.is_some());
        assert_eq!(state.session().history.len(), 3);
        assert!(state.session().history[2]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("org.fcf.centl.research.erdos_straus/hunt"));
        assert!(state.session().history[2]
            .approximate_repr
            .as_deref()
            .unwrap()
            .contains("Bounded search"));
    }

    #[test]
    fn clear_resets_the_web_session_without_rendering_a_result() {
        let mut state = AppState {
            notebooks: vec![("Notebook 01".to_string(), Session::new())], active_notebook: 0,
        };
        state.session_mut().history.push(HistoryEntry {
            command: "2 + 2".to_string(),
            result: "4".to_string(),
            exact_repr: None,
            approximate_repr: None,
            execution_micros: 1,
            success: true,
        });
        let (result, error, physics, hunt) = handle_command(":clear", &mut state);
        assert!(state.session().history.is_empty());
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

    #[test]
    fn chemistry_commands_lower_to_a_bounded_qualified_protocol() {
        assert_eq!(
            chemistry_provider_args("chem atoms Ca(OH)2").unwrap(),
            vec!["atoms", "Ca(OH)2"]
        );
        assert_eq!(
            chemistry_provider_args("chem balance Fe + O2 -> Fe2O3").unwrap(),
            vec!["balance", "Fe + O2 -> Fe2O3"]
        );
        assert_eq!(
            chemistry_provider_args("chemistry balance 'C2H6 + O2 -> CO2 + H2O'").unwrap(),
            vec!["balance", "C2H6 + O2 -> CO2 + H2O"]
        );
        assert_eq!(
            chemistry_provider_args("chem molar-mass H2O").unwrap(),
            vec!["molar-mass", "H2O"]
        );
        assert!(chemistry_provider_args("chem unknown-operation H2O").is_err());
        assert!(chemistry_provider_args("chem atoms Ca (OH)2").is_err());
        assert!(!has_command_prefix("chemical", "chem"));
    }

    #[test]
    fn chemistry_protocol_requires_verified_conservation() {
        let valid = serde_json::json!({
            "version": 1,
            "kind": "balanced_reaction",
            "equation": "4 Fe + 3 O2 -> 2 Fe2O3",
            "coefficients": {
                "reactants": ["4", "3"],
                "products": ["2"]
            },
            "stoichiometric_evidence": {
                "elements": ["Fe", "O"],
                "columns": {
                    "reactants": [
                        {"formula": "Fe", "input_coefficient": "1"},
                        {"formula": "O2", "input_coefficient": "1"}
                    ],
                    "products": [
                        {"formula": "Fe2O3", "input_coefficient": "1"}
                    ]
                },
                "matrix": [["1", "0", "-2"], ["0", "2", "-3"]],
                "sign_convention": "reactants_positive_products_negative"
            },
            "verified": true,
            "conservation": [
                {"element": "Fe", "reactants": "4", "products": "4", "verified": true},
                {"element": "O", "reactants": "6", "products": "6", "verified": true}
            ]
        });
        assert_eq!(
            summarize_balanced_reaction(&valid, "Fe + O2 -> Fe2O3").unwrap(),
            "4 Fe + 3 O2 → 2 Fe2O3\nAtom conservation verified across Fe, O."
        );

        let mut inconsistent = valid.clone();
        inconsistent["conservation"][0]["products"] = Value::String("5".to_string());
        assert!(summarize_balanced_reaction(&inconsistent, "Fe + O2 -> Fe2O3").is_err());

        let mut wrong_request = valid.clone();
        wrong_request["stoichiometric_evidence"]["columns"]["reactants"][0]["formula"] =
            Value::String("Cu".to_string());
        assert!(summarize_balanced_reaction(&wrong_request, "Fe + O2 -> Fe2O3").is_err());

        let unverified = serde_json::json!({
            "version": 1,
            "kind": "balanced_reaction",
            "equation": "Fe + O2 -> Fe2O3",
            "verified": false,
            "conservation": []
        });
        assert!(summarize_balanced_reaction(&unverified, "Fe + O2 -> Fe2O3").is_err());
    }

    #[cfg(unix)]
    #[test]
    fn chemistry_adapter_consumes_machine_json_without_a_shell() {
        use std::fs;
        use std::os::unix::fs::PermissionsExt;

        let path = env::temp_dir().join(format!("centl26-fake-chemistry-{}", std::process::id()));
        fs::write(
            &path,
            "#!/bin/sh\nprintf '%s\\n' '{\"version\":1,\"kind\":\"chemical_formula\",\"formula\":\"Ca(OH)2\",\"atoms\":[{\"element\":\"Ca\",\"count\":\"1\"},{\"element\":\"H\",\"count\":\"2\"},{\"element\":\"O\",\"count\":\"2\"}]}'\n",
        )
        .unwrap();
        let mut permissions = fs::metadata(&path).unwrap().permissions();
        permissions.set_mode(0o700);
        fs::set_permissions(&path, permissions).unwrap();

        let outcome = run_chemistry_with(
            path.to_str().unwrap(),
            &["atoms".to_string(), "Ca(OH)2".to_string()],
        )
        .unwrap();
        assert_eq!(outcome.summary, "Ca(OH)2 — Ca=1 · H=2 · O=2");
        assert!(outcome
            .evidence
            .contains("\"schema\": \"centl26.chemistry-evidence/1\""));
        assert!(outcome.evidence.contains("\"operation\": \"atoms\""));
        assert!(outcome.evidence.contains("\"chemical_formula\""));
        assert!(outcome.evidence.contains("\"count\": \"2\""));

        let _ = fs::remove_file(path);
    }

    #[cfg(unix)]
    #[test]
    fn chemistry_provider_is_time_and_output_bounded() {
        use std::fs;
        use std::os::unix::fs::PermissionsExt;

        let timeout_path =
            env::temp_dir().join(format!("centl26-fake-chem-timeout-{}", std::process::id()));
        fs::write(&timeout_path, "#!/bin/sh\nsleep 2 &\nwait\n").unwrap();
        let mut permissions = fs::metadata(&timeout_path).unwrap().permissions();
        permissions.set_mode(0o700);
        fs::set_permissions(&timeout_path, permissions).unwrap();
        let started = Instant::now();
        let error = run_chemistry_with_timeout(
            timeout_path.to_str().unwrap(),
            &["atoms".to_string(), "H2O".to_string()],
            Duration::from_millis(30),
        )
        .unwrap_err();
        assert!(error.contains("execution limit"), "{error}");
        assert!(
            started.elapsed() < Duration::from_millis(500),
            "provider descendant held pipes past the deadline"
        );
        let _ = fs::remove_file(timeout_path);

        let output_path =
            env::temp_dir().join(format!("centl26-fake-chem-output-{}", std::process::id()));
        fs::write(
            &output_path,
            "#!/bin/sh\nwhile :; do printf '0123456789abcdef0123456789abcdef'; done\n",
        )
        .unwrap();
        let mut permissions = fs::metadata(&output_path).unwrap().permissions();
        permissions.set_mode(0o700);
        fs::set_permissions(&output_path, permissions).unwrap();
        let error = run_chemistry_with_timeout(
            output_path.to_str().unwrap(),
            &["atoms".to_string(), "H2O".to_string()],
            Duration::from_secs(2),
        )
        .unwrap_err();
        assert!(error.contains("256 KiB"), "{error}");
        let _ = fs::remove_file(output_path);
    }

    #[cfg(unix)]
    #[test]
    fn chemistry_protocol_errors_remain_machine_identified() {
        use std::fs;
        use std::os::unix::fs::PermissionsExt;

        let path = env::temp_dir().join(format!("centl26-fake-chem-error-{}", std::process::id()));
        fs::write(
            &path,
            "#!/bin/sh\nprintf '%s\\n' '{\"version\":1,\"kind\":\"chemistry_error\",\"code\":\"unknown_element\",\"error\":\"unknown element Xx\"}'\nexit 1\n",
        )
        .unwrap();
        let mut permissions = fs::metadata(&path).unwrap().permissions();
        permissions.set_mode(0o700);
        fs::set_permissions(&path, permissions).unwrap();
        let error = run_chemistry_with(
            path.to_str().unwrap(),
            &["atoms".to_string(), "Xx".to_string()],
        )
        .unwrap_err();
        assert!(error.contains("[unknown_element]"), "{error}");
        assert!(error.contains("unknown element Xx"), "{error}");
        let _ = fs::remove_file(path);
    }

    #[cfg(unix)]
    #[test]
    fn canonical_approximation_uses_engine_output() {
        use std::fs;
        use std::os::unix::fs::PermissionsExt;

        let path = env::temp_dir().join(format!("centl-web-fake-engine-{}", std::process::id()));
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
            Some("[9.3248e157, 9.3249e157]")
        );
        assert!(result.execution_micros > 0);

        let _ = fs::remove_file(path);
    }

    #[test]
    fn legacy_centl_hub_fragment_now_targets_the_page_top() {
        let html = render_full_page("<p>body</p>", "test", "");
        assert!(html.contains(
            "<header class=\"masthead home-masthead\" id=\"centl-hub\" tabindex=\"-1\" autofocus>"
        ));
    }

    #[test]
    fn physics_extended_commands_execute_accurately() {
        let mut state = AppState::new();

        // 1. Constants
        let (_exec, err, phys, _) = handle_command("physics constant c", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        let phys = phys.unwrap();
        assert!(phys.summary.contains("299792458"));

        // 2. Units catalog
        let (_exec, err, phys, _) = handle_command("physics units", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().title.contains("Physical Units"));

        // 3. Cherenkov radiation
        let (_exec, err, phys, _) = handle_command("physics cherenkov 1.33 2.5e8", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        let phys = phys.unwrap();
        assert!(phys.summary.contains("Emission active"));
        assert!(phys.verified);

        // 4. Gravity trajectory simulation
        let (_exec, err, phys, _) = handle_command(
            "physics gravity m=1.0 p=0,0,10 v=10,0,0 g=0,0,-9.8 dt=0.1 steps=20",
            &mut state,
        );
        assert!(err.is_none());
        assert!(phys.is_some());
        let phys = phys.unwrap();
        assert!(phys.title.contains("Gravitational Trajectory Simulation"));
        assert!(phys.verified);

        // 5. De Broglie Wavelength
        let (_exec, err, phys, _) = handle_command("physics debroglie 9.10938e-31 2.187e6", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().summary.contains("nm"));

        // 6. Carnot efficiency
        let (_exec, err, phys, _) = handle_command("physics carnot 600 300", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().summary.contains("50.00%"));

        // 7. Escape velocity
        let (_exec, err, phys, _) = handle_command("physics escape 5.9722e24 6.371e6", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().summary.contains("11.19 km/s"));

        // 8. Lorentz factor
        let (_exec, err, phys, _) = handle_command("physics lorentz 2.4e8", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().summary.contains("γ = 1.66"));
    }

    #[test]
    fn mathematical_engine_extensions_evaluate_correctly() {
        let mut state = AppState::new();

        // Variable assignment and resolution
        let (res, err, _, _) = handle_command("x = 42", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "x = 42");

        let (res, err, _, _) = handle_command("x * 2", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "84");

        // :vars command
        let (res, err, _, _) = handle_command(":vars", &mut state);
        assert!(err.is_none());
        assert!(res.unwrap().text.contains("x = 42"));

        // Prime testing and factorization
        let (res, err, _, _) = handle_command("is_prime(1009)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "true");

        let (res, err, _, _) = handle_command("is_prime(1008)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "false");

        let (res, err, _, _) = handle_command("factors(28)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "1, 2, 4, 7, 14, 28");

        let (res, err, _, _) = handle_command("prime_factors(360)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "2^3 * 3^2 * 5");

        // Combinatorics
        let (res, err, _, _) = handle_command("choose(10, 3)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "120");

        let (res, err, _, _) = handle_command("permutations(5, 2)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "20");

        // Polynomial expand and factor with unbound symbolic variable
        let (res, err, _, _) = handle_command("expand((t - 2) * (t + 3))", &mut state);
        assert!(err.is_none());
        let expanded = res.unwrap().text;
        assert!(expanded.contains("t^2") || expanded.contains("t * t") || expanded.contains("t"));

        // Extended Number Theory & Linear Algebra
        let (res, err, _, _) = handle_command("xgcd(240, 46)", &mut state);
        assert!(err.is_none());
        assert!(res.unwrap().text.contains("gcd = 2"));

        let (res, err, _, _) = handle_command("modinv(3, 11)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "4");

        let (res, err, _, _) = handle_command("totient(36)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "12");

        let (res, err, _, _) = handle_command("det2(4, 7, 2, 6)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "10");

        let (res, err, _, _) = handle_command("dot(1, 2, 3, 4, 5, 6)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "32");

        let (res, err, _, _) = handle_command("cross(1, 0, 0, 0, 1, 0)", &mut state);
        assert!(err.is_none());
        assert!(res.unwrap().text.contains("1.000000"));

        let (res, err, _, _) = handle_command("mean(10, 20, 30)", &mut state);
        assert!(err.is_none());
        assert!(res.unwrap().text.contains("20.00000000"));

        // 2D Plotting
        let (res, err, _, _) = handle_command("plot sin(x) from -3.14 to 3.14", &mut state);
        assert!(err.is_none(), "err was: {:?}", err);
        assert!(res.unwrap().text.contains("Function Plot: f(x) = sin(x)"));
        assert!(state.session().history.last().unwrap().result.contains("┌"));
        assert!(state.session().history.last().unwrap().result.contains("●"));

        let (res, err, _, _) = handle_command("plot x^3 - 3*x from -2.5 to 2.5", &mut state);
        assert!(err.is_none(), "err was: {:?}", err);
        assert!(res.unwrap().text.contains("Function Plot: f(x) = x^3 - 3*x"));
        assert!(state.session().history.last().unwrap().result.contains("┌"));
        assert!(state.session().history.last().unwrap().result.contains("●"));

        // Assertions & verification
        let (res, err, _, _) = handle_command("assert(1 + 1 = 2)", &mut state);
        assert!(err.is_none());
        assert_eq!(res.unwrap().text, "assert(1 + 1 = 2): verified");

        let (res, err, _, _) = handle_command("assert(1 + 1 = 3)", &mut state);
        assert!(err.is_none());
        assert!(res.unwrap().text.contains("refuted"));
    }

    #[test]
    fn chemistry_expanded_operation_lowering_handles_all_variants() {
        assert_eq!(
            chemistry_provider_args("chem particles exact 2").unwrap(),
            vec!["particles", "exact", "2"]
        );
        assert_eq!(
            chemistry_provider_args("chem moles measured 6.022e23").unwrap(),
            vec!["moles", "measured", "6.022e23"]
        );
        assert_eq!(
            chemistry_provider_args("chem constant F").unwrap(),
            vec!["constant", "F"]
        );
        assert_eq!(
            chemistry_provider_args("chem concentration 0.5 1.0").unwrap(),
            vec!["concentration", "0.5", "1.0"]
        );
        assert_eq!(
            chemistry_provider_args("chem dilution 1.0 0.5 2.0").unwrap(),
            vec!["dilution", "1.0", "0.5", "2.0"]
        );
        assert_eq!(
            chemistry_provider_args("chem yield 85 100").unwrap(),
            vec!["yield", "85", "100"]
        );
        assert_eq!(
            chemistry_provider_args("chem gas 1 300 0.024").unwrap(),
            vec!["gas", "1", "300", "0.024"]
        );
        assert_eq!(
            chemistry_provider_args("chem spread g 1.0 1.1 0.9").unwrap(),
            vec!["spread", "g", "1.0", "1.1", "0.9"]
        );
        // Auto-detected without 'chem' prefix
        assert_eq!(
            chemistry_provider_args("stoich measured 'C2H6 + O2 -> CO2 + H2O' C2H6 3 CO2").unwrap(),
            vec!["stoich", "measured", "C2H6 + O2 -> CO2 + H2O", "C2H6", "3", "CO2"]
        );
        assert_eq!(
            chemistry_provider_args("balance Fe + O2 -> Fe2O3").unwrap(),
            vec!["balance", "Fe + O2 -> Fe2O3"]
        );
        assert_eq!(
            chemistry_provider_args("Fe + O2 -> Fe2O3").unwrap(),
            vec!["balance", "Fe + O2 -> Fe2O3"]
        );
    }

    #[test]
    fn auto_detection_and_sci_problem_solver_work() {
        let mut state = AppState::new();

        // Physics auto-detection without 'physics' prefix
        let (_, err, phys, _) = handle_command("convert 100 cm m", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().summary.contains("1.00000000 m"));

        let (_, err, phys, _) = handle_command("convert 100 cm to m", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().summary.contains("1.00000000 m"));

        let (_, err, phys, _) = handle_command("constant c", &mut state);
        assert!(err.is_none());
        assert!(phys.is_some());
        assert!(phys.unwrap().summary.contains("299792458"));

        // Erdős-Straus auto-detection without 'es' prefix
        let (res, err, _, _) = handle_command("solve 2521", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("4/2521"));

        // SCi plain English STEM problem solver
        let (res, err, _, _) = handle_command("What is the molar mass of Ca(OH)2?", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("Molar Mass Calculation for Ca(OH)2"));

        let (res, err, _, _) = handle_command("Find the derivative of x^4 * cos(x) with respect to x", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("Symbolic Derivative"));

        let (res, err, _, _) = handle_command("Convert 100 kilometers per hour to meters per second", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("Unit Conversion"));

        // In-App Programmability & Build Extensions
        let (res, err, _, _) = handle_command("build fn KineticEnergy(m, v) = 1/2 * m * v^2", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("User Extension Built: KineticEnergy"));

        let (res, err, _, _) = handle_command("KineticEnergy(10, 5)", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert_eq!(res.unwrap().text, "125");

        let (res, err, _, _) = handle_command("build a formula for potential energy PotEnergy(m, g, h) = m * g * h", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("User Extension Built: PotEnergy"));

        let (res, err, _, _) = handle_command("PotEnergy(2, 9.8, 5)", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("98"));

        let (res, err, _, _) = handle_command("build list", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("KineticEnergy"));

        // Gemini AI Configuration & Status Commands
        let (res, err, _, _) = handle_command(":gemini-key AIzaSyTestKey1234567890", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("Active"));

        let (res, err, _, _) = handle_command(":gemini-model gemini-2.5-pro", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("gemini-2.5-pro"));

        let (res, err, _, _) = handle_command(":gemini-status", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        let status_text = res.unwrap().text;
        assert!(status_text.contains("Active & Connected"));
        assert!(status_text.contains("gemini-2.5-pro"));

        // Extended Offline SCi Problem Solving Tests
        let (res, err, _, _) = handle_command("What is the pH of a 0.05 M HCl solution?", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("pH ="));

        let (res, err, _, _) = handle_command("Dilute 50 mL of 2 M HCl to 200 mL, what is the final concentration?", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("0.5"));

        let (res, err, _, _) = handle_command("Calculate Gibbs free energy when delta H is -92.4 kJ and delta S is -198 J/K at 298 K", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("Spontaneous"));

        let (res, err, _, _) = handle_command("A car accelerates from 0 to 25 m/s in 5 seconds, what is its acceleration?", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("5.0000 m/s²"));

        let (res, err, _, _) = handle_command("What is the current with voltage 120 V and resistance 15 ohms?", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("8.0000 A"));

        let (res, err, _, _) = handle_command("Area of a circle with radius 7", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("153.93"));

        let (res, err, _, _) = handle_command("Hypotenuse of right triangle with legs 3 and 4", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("5.0000"));

        let (res, err, _, _) = handle_command("Dot product of (1, 2, 3) and (4, 5, 6)", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("32"));

        let (res, err, _, _) = handle_command("Determinant of [[1, 2], [3, 4]]", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("-2"));

        let (res, err, _, _) = handle_command("Mean of 10, 20, 30, 40, 50", &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        assert!(res.unwrap().text.contains("30"));
    }

    #[test]
    fn test_notebook_tabs_and_export() {
        let mut state = AppState::new();
        assert_eq!(state.notebooks.len(), 1);
        assert_eq!(state.notebook_name(), "Notebook 01");

        // Run calculation in Notebook 01
        handle_command("1 + 1", &mut state);
        assert_eq!(state.session().history.len(), 1);

        // Create new notebook
        handle_command(":new-notebook", &mut state);
        assert_eq!(state.notebooks.len(), 2);
        assert_eq!(state.active_notebook, 1);
        assert_eq!(state.notebook_name(), "Notebook 02");
        assert_eq!(state.session().history.len(), 0);

        // Rename Notebook 02
        handle_command(":rename-notebook Orbital Mechanics", &mut state);
        assert_eq!(state.notebook_name(), "Orbital Mechanics");

        // Run calculation in Orbital Mechanics
        handle_command("2 + 2", &mut state);
        assert_eq!(state.session().history.len(), 1);

        // Export markdown, notebook json, and full project json
        let md = export_notebook_markdown(&state);
        assert!(md.contains("# Orbital Mechanics"));
        assert!(md.contains("2 + 2"));

        let json = export_notebook_json(&state);
        assert!(json.contains("Orbital Mechanics"));
        assert!(json.contains("2 + 2"));

        let proj = export_project_json(&state);
        assert!(proj.contains("centl26.project/1"));
        assert!(proj.contains("Orbital Mechanics"));
        assert!(proj.contains("1 + 1"));

        // Save command
        let (save_res, save_err, _, _) = handle_command(":save", &mut state);
        assert!(save_err.is_none());
        assert!(save_res.is_some());
        assert!(save_res.unwrap().text.contains("Project saved successfully"));

        // Switch back to notebook 0
        handle_command(":switch-notebook 0", &mut state);
        assert_eq!(state.active_notebook, 0);
        assert_eq!(state.session().history.len(), 1);
        assert_eq!(state.session().history[0].command, "1 + 1");

        // Close notebook 1
        handle_command(":close-notebook 1", &mut state);
        assert_eq!(state.notebooks.len(), 1);
        assert_eq!(state.active_notebook, 0);
    }

    #[test]
    fn test_multistatement_cell_execution() {
        let mut state = AppState::new();

        // 1. Multi-line arithmetic block
        let script = "a = 15\nb = 25\nc = a * b + 10\nc / 2";
        let (res, err, _, _) = handle_command(script, &mut state);
        assert!(err.is_none());
        assert!(res.is_some());
        let r = res.unwrap();
        assert!(r.text.contains("Block Execution (4 steps):"));
        assert!(r.text.contains("[1] a = 15"));
        assert!(r.text.contains("[2] b = 25"));
        assert!(r.text.contains("[3] c = a * b + 10  →  c = 385"));
        assert!(r.text.contains("[4] c / 2  →  385/2"));
        assert!(r.text.contains("Result: 385/2"));
        assert_eq!(r.exact_rational.as_ref().map(|x| format!("{}", x)), Some("385/2".to_string()));

        // Check that session retained the variables
        assert!(state.session().variables.contains_key("a"));
        assert!(state.session().variables.contains_key("b"));
        assert!(state.session().variables.contains_key("c"));

        // 2. Semicolon-delimited single line
        let semi_script = "x = 5; y = 12; sqrt(x^2 + y^2)";
        let (res2, err2, _, _) = handle_command(semi_script, &mut state);
        assert!(err2.is_none());
        assert!(res2.is_some());
        let r2 = res2.unwrap();
        assert!(r2.text.contains("Block Execution (3 steps):"));
        assert!(r2.text.contains("Result: 13"));

        // 3. Comments support
        let comment_script = "# Setup physics calculation\nm = 1000\n// velocity in m/s\nv = 20\n1/2 * m * v^2";
        let (res3, err3, _, _) = handle_command(comment_script, &mut state);
        assert!(err3.is_none());
        assert!(res3.is_some());
        let r3 = res3.unwrap();
        assert!(r3.text.contains("Result: 200000"));
    }

    #[test]
    fn test_repo_root_and_executable_discovery() {
        let root = find_repo_root();
        assert!(root.is_some());
        assert!(root.unwrap().join("Cargo.toml").exists());

        // Cargo / git discovery should resolve
        let cargo = find_executable("cargo");
        assert!(cargo.is_some());
    }

    #[test]
    fn test_version_comparison_and_update_detection() {
        assert!(is_version_newer("26.8.2", "26.8.1"));
        assert!(is_version_newer("v26.9.0", "26.8.1"));
        assert!(is_version_newer("27.0.0", "26.8.1"));
        assert!(!is_version_newer("26.8.1", "26.8.1"));
        assert!(!is_version_newer("v26.8.1", "26.8.1"));
        assert!(!is_version_newer("26.8.0", "26.8.1"));
        assert!(!is_version_newer("26.7.3", "26.8.1"));
    }
}

pub const CURRENT_VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn is_version_newer(remote: &str, current: &str) -> bool {
    let parse_parts = |v: &str| -> Vec<u64> {
        v.trim_start_matches('v')
            .split('.')
            .map(|p| p.chars().take_while(|c| c.is_ascii_digit()).collect::<String>())
            .filter_map(|s| s.parse::<u64>().ok())
            .collect()
    };
    let r = parse_parts(remote);
    let c = parse_parts(current);
    if r.is_empty() || c.is_empty() {
        return false;
    }
    for (rp, cp) in r.iter().zip(c.iter()) {
        if rp > cp {
            return true;
        } else if rp < cp {
            return false;
        }
    }
    r.len() > c.len()
}

pub fn handle_update_check() -> serde_json::Value {
    let git_status = check_git_update_available();
    let latest_version = git_status.latest_tag.clone().unwrap_or_else(|| format!("v{}", CURRENT_VERSION));
    
    serde_json::json!({
        "schema": "centl26.update-check/1",
        "product": "CentL26",
        "version": CURRENT_VERSION,
        "latest_version": latest_version,
        "release_name": format!("CentL26 {}", latest_version),
        "release_tag": latest_version,
        "build_commit": super::build_commit(),
        "status": if git_status.update_available { "update_available" } else { "up_to_date" },
        "update_available": git_status.update_available,
        "channel": "main",
        "message": if git_status.update_available {
            if git_status.commits_behind > 0 {
                format!("New update found! ({} new commit(s) on origin/main). Click Update to sync and build.", git_status.commits_behind)
            } else {
                format!("New update available: {} (current: v{}). Click Update to sync and build.", latest_version, CURRENT_VERSION)
            }
        } else {
            format!("CentL26 v{} is up to date.", CURRENT_VERSION)
        }
    })
}

pub struct GitUpdateStatus {
    pub update_available: bool,
    pub commits_behind: usize,
    pub latest_tag: Option<String>,
}

pub fn find_repo_root() -> Option<std::path::PathBuf> {
    // 1. Check current working directory
    if let Ok(cwd) = env::current_dir() {
        if cwd.join("Cargo.toml").exists() {
            return Some(cwd);
        }
    }

    // 2. Check executable directory and ancestor directories
    if let Ok(exe_path) = env::current_exe() {
        let mut cur = exe_path.parent();
        while let Some(dir) = cur {
            if dir.join("Cargo.toml").exists() {
                return Some(dir.to_path_buf());
            }
            cur = dir.parent();
        }
    }

    None
}

pub fn find_executable(name: &str) -> Option<std::path::PathBuf> {
    let mut candidates = Vec::new();

    if let Ok(home) = env::var("HOME").or_else(|_| env::var("USERPROFILE")) {
        let cargo_bin = std::path::Path::new(&home).join(".cargo").join("bin");
        candidates.push(cargo_bin.join(name));
        #[cfg(windows)]
        candidates.push(cargo_bin.join(format!("{}.exe", name)));
    }

    candidates.push(std::path::PathBuf::from(format!("/opt/homebrew/bin/{}", name)));
    candidates.push(std::path::PathBuf::from(format!("/usr/local/bin/{}", name)));
    candidates.push(std::path::PathBuf::from(format!("/usr/bin/{}", name)));
    candidates.push(std::path::PathBuf::from(format!("/bin/{}", name)));

    for candidate in candidates {
        if candidate.is_file() {
            return Some(candidate);
        }
    }

    None
}

pub fn create_system_command(name: &str) -> std::process::Command {
    let exe_path = find_executable(name).unwrap_or_else(|| std::path::PathBuf::from(name));
    let mut cmd = std::process::Command::new(&exe_path);

    // Augment PATH for macOS GUI apps / non-login shells
    let mut path_entries = Vec::new();
    if let Ok(home) = env::var("HOME").or_else(|_| env::var("USERPROFILE")) {
        path_entries.push(format!("{}/.cargo/bin", home));
    }
    path_entries.push("/opt/homebrew/bin".to_string());
    path_entries.push("/usr/local/bin".to_string());
    path_entries.push("/usr/bin".to_string());
    path_entries.push("/bin".to_string());
    if let Ok(existing) = env::var("PATH") {
        path_entries.push(existing);
    }
    cmd.env("PATH", path_entries.join(":"));

    if let Some(root) = find_repo_root() {
        cmd.current_dir(root);
    }

    cmd
}

pub fn check_git_update_available() -> GitUpdateStatus {
    // 1. Check local/remote git commits if inside repository
    let mut count = 0;
    if find_repo_root().is_some() {
        let _ = create_system_command("git")
            .args(["fetch", "origin", "main", "--quiet"])
            .output();

        let local_head = create_system_command("git")
            .args(["rev-parse", "HEAD"])
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default();

        let remote_head = create_system_command("git")
            .args(["rev-parse", "origin/main"])
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default();

        if !local_head.is_empty() && !remote_head.is_empty() && local_head != remote_head {
            let count_output = create_system_command("git")
                .args(["rev-list", "--count", "HEAD..origin/main"])
                .output()
                .map(|o| String::from_utf8_lossy(&o.stdout).trim().parse::<usize>().unwrap_or(0))
                .unwrap_or(0);
            count = count_output;
        }
    }

    // 2. Dual-channel online check:
    // Channel A: Query rate-limit-free GitHub raw Cargo.toml manifest (no API rate limiting!)
    let mut github_newer = false;
    let mut latest_discovered_ver = None;

    if let Some(curl) = find_executable("curl") {
        if let Ok(output) = std::process::Command::new(&curl)
            .args([
                "-sS",
                "-m", "3",
                "-A", "CentL26-Updater",
                "https://raw.githubusercontent.com/chasebryan/CentL/main/Cargo.toml",
            ])
            .output()
        {
            if output.status.success() {
                let toml_str = String::from_utf8_lossy(&output.stdout);
                for line in toml_str.lines() {
                    let trimmed = line.trim();
                    if trimmed.starts_with("version =") {
                        if let Some(v) = trimmed.split('"').nth(1) {
                            if is_version_newer(v, CURRENT_VERSION) {
                                github_newer = true;
                                latest_discovered_ver = Some(format!("v{}", v));
                            }
                            break;
                        }
                    }
                }
            }
        }

        // Channel B: GitHub Releases API fallback
        if !github_newer {
            if let Ok(output) = std::process::Command::new(&curl)
                .args([
                    "-sS",
                    "-m", "3",
                    "-A", "CentL26-Updater",
                    "https://api.github.com/repos/chasebryan/CentL/releases/latest",
                ])
                .output()
            {
                if output.status.success() {
                    if let Ok(json_str) = String::from_utf8(output.stdout) {
                        if let Ok(release_val) = serde_json::from_str::<serde_json::Value>(&json_str) {
                            if let Some(tag) = release_val["tag_name"].as_str() {
                                if is_version_newer(tag, CURRENT_VERSION) {
                                    github_newer = true;
                                    latest_discovered_ver = Some(tag.to_string());
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    GitUpdateStatus {
        update_available: count > 0 || github_newer,
        commits_behind: count,
        latest_tag: latest_discovered_ver,
    }
}

pub fn execute_repo_update() -> serde_json::Value {
    let repo_root = match find_repo_root() {
        Some(r) => r,
        None => {
            return serde_json::json!({
                "success": false,
                "updated": false,
                "message": "CentL26 is running outside of a git repository clone. To update standalone binary packages, download the latest release from https://github.com/chasebryan/centl/releases"
            });
        }
    };

    // 1. Fast stash if worktree is dirty
    let status_out = create_system_command("git").args(["status", "--porcelain"]).output();
    let is_dirty = status_out.as_ref().map(|s| !s.stdout.is_empty()).unwrap_or(false);
    if is_dirty {
        let _ = create_system_command("git").args(["stash", "save", "-u", "centl26-autoupdate-stash"]).output();
    }

    // 2. Fast pull origin main
    let pull = create_system_command("git").args(["pull", "--ff-only", "origin", "main"]).output();
    let pull_success = match pull {
        Ok(ref o) if o.status.success() => true,
        _ => {
            create_system_command("git").args(["pull", "origin", "main"]).output().map(|o| o.status.success()).unwrap_or(false)
        }
    };

    // 3. Compile or retrieve fresh binary
    let mut build_success = false;

    if find_executable("cargo").is_some() {
        // Strategy A: Standard release build
        let build = create_system_command("cargo")
            .args(["build", "--release", "--bin", "centl26"])
            .output();

        if let Ok(ref b_out) = build {
            if b_out.status.success() {
                build_success = true;
            }
        }

        // Strategy B: If standard build failed (e.g. target/ hardlink or permission lock), retry with isolated target dir
        if !build_success {
            let isolated_target = repo_root.join("target/update-build");
            let retry_build = create_system_command("cargo")
                .args(["build", "--release", "--bin", "centl26", "--target-dir", isolated_target.to_str().unwrap_or("target/update-build")])
                .output();

            if let Ok(ref b_out) = retry_build {
                if b_out.status.success() {
                    let src_bin = isolated_target.join("release/centl26");
                    let dst_bin = repo_root.join("target/release/centl26");
                    if src_bin.exists() {
                        let _ = std::fs::create_dir_all(repo_root.join("target/release"));
                        let _ = std::fs::copy(&src_bin, &dst_bin);
                        build_success = true;
                    }
                }
            }
        }
    }

    // Strategy C: Precompiled binary fallback via GitHub releases if compilation could not complete
    if !build_success {
        if let Some(curl) = find_executable("curl") {
            let tmp_dir = std::env::temp_dir().join("centl26-autoupdate");
            let _ = std::fs::create_dir_all(&tmp_dir);

            #[cfg(target_os = "macos")]
            let (asset_name, is_zip) = ("CentL26-macOS-arm64.zip", true);
            #[cfg(target_os = "linux")]
            let (asset_name, is_zip) = ("CentL26-Linux-x86_64.tar.gz", false);
            #[cfg(target_os = "windows")]
            let (asset_name, is_zip) = ("CentL26-Windows-x64.zip", true);

            let download_url = format!("https://github.com/chasebryan/centl/releases/latest/download/{}", asset_name);
            let downloaded_file = tmp_dir.join(asset_name);

            let download_res = std::process::Command::new(&curl)
                .args([
                    "-sSL",
                    "-m", "30",
                    "-A", "CentL26-Updater",
                    "-o", downloaded_file.to_str().unwrap_or(""),
                    &download_url,
                ])
                .output();

            if let Ok(d_out) = download_res {
                if d_out.status.success() && downloaded_file.exists() {
                    let unpack_res = if is_zip {
                        std::process::Command::new("unzip")
                            .args(["-o", downloaded_file.to_str().unwrap_or(""), "-d", tmp_dir.to_str().unwrap_or("")])
                            .output()
                    } else {
                        std::process::Command::new("tar")
                            .args(["-xzf", downloaded_file.to_str().unwrap_or(""), "-C", tmp_dir.to_str().unwrap_or("")])
                            .output()
                    };

                    if let Ok(u_out) = unpack_res {
                        if u_out.status.success() {
                            let mut candidate_bin = tmp_dir.join("CentL26.app/Contents/Resources/bin/centl26");
                            if !candidate_bin.exists() {
                                candidate_bin = tmp_dir.join("CentL26-Linux-x86_64/centl26");
                            }
                            if !candidate_bin.exists() {
                                candidate_bin = tmp_dir.join("CentL26-Windows-x64/centl26.exe");
                            }

                            if candidate_bin.exists() {
                                let target_bin = repo_root.join("target/release/centl26");
                                let _ = std::fs::create_dir_all(repo_root.join("target/release"));
                                let _ = std::fs::copy(&candidate_bin, &target_bin);
                                build_success = true;
                            }
                        }
                    }
                }
            }
            let _ = std::fs::remove_dir_all(&tmp_dir);
        }
    }

    if build_success {
        // High-speed .app bundle sync without slow full rebuild script
        let app_bundle = repo_root.join("build/centl26/macos/CentL26.app");
        let target_bin = repo_root.join("target/release/centl26");
        if cfg!(target_os = "macos") && app_bundle.exists() && target_bin.exists() {
            let app_bin = app_bundle.join("Contents/Resources/bin/centl26");
            let _ = std::fs::copy(&target_bin, &app_bin);
            let _ = create_system_command("codesign")
                .args(["-s", "-", "--force", app_bundle.to_str().unwrap_or_default()])
                .output();
        }

        serde_json::json!({
            "success": true,
            "updated": true,
            "message": if pull_success { "CentL26 updated to latest version and synchronized successfully! Reloading..." } else { "CentL26 rebuilt successfully with latest release optimizations! Reloading..." }
        })
    } else {
        serde_json::json!({
            "success": false,
            "updated": false,
            "message": "Update encountered a build lock. Please update manually with 'git pull origin main && cargo build --release' or download the binary release from https://github.com/chasebryan/centl/releases/latest"
        })
    }
}

pub fn export_notebook_markdown(state: &AppState) -> String {
    let name = state.notebook_name();
    let session = state.session();
    let mut md = format!("# {}\n\nExported from CentL26 v{}\n\n", name, CURRENT_VERSION);
    for entry in &session.history {
        md.push_str(&format!("## `{}`\n\n", entry.command));
        md.push_str(&format!("**Result:** {}\n\n", entry.result));
        if let Some(ref exact) = entry.exact_repr {
            md.push_str(&format!("**Exact:** `{}`\n\n", exact));
        }
        md.push_str("---\n\n");
    }
    md
}

pub fn export_notebook_json(state: &AppState) -> String {
    let name = state.notebook_name();
    let session = state.session();
    let entries: Vec<String> = session.history.iter().map(|e| {
        format!("{{\"command\":{},\"result\":{},\"exact\":{}}}",
            serde_json_str(&e.command),
            serde_json_str(&e.result),
            e.exact_repr.as_ref().map(|s| serde_json_str(s)).unwrap_or("null".to_string())
        )
    }).collect();
    format!("{{\"schema\":\"centl26.notebook/1\",\"name\":{},\"version\":{},\"entries\":[{}]}}",
        serde_json_str(name), serde_json_str(CURRENT_VERSION), entries.join(","))
}

pub fn export_project_json(state: &AppState) -> String {
    let mut notebooks_json = Vec::new();
    for (name, session) in &state.notebooks {
        let entries: Vec<String> = session.history.iter().map(|e| {
            format!("{{\"command\":{},\"result\":{},\"exact\":{}}}",
                serde_json_str(&e.command),
                serde_json_str(&e.result),
                e.exact_repr.as_ref().map(|s| serde_json_str(s)).unwrap_or("null".to_string())
            )
        }).collect();
        notebooks_json.push(format!(
            "{{\"name\":{},\"entries\":[{}]}}",
            serde_json_str(name),
            entries.join(",")
        ));
    }
    format!(
        "{{\"schema\":\"centl26.project/1\",\"version\":{},\"active_notebook\":{},\"notebooks\":[{}]}}",
        serde_json_str(CURRENT_VERSION),
        state.active_notebook,
        notebooks_json.join(",")
    )
}

fn serde_json_str(s: &str) -> String {
    format!("\"{}\"" , s.replace('\\', "\\\\").replace('"', "\\\"").replace('\n', "\\n").replace('\r', "\\r").replace('\t', "\\t"))
}
