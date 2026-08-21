// HTTP Request Dispatcher & Command Execution Handler
// Free Computation Foundation - Apache-2.0

use crate::engine::{evaluate, ExecutionResult, HistoryEntry, Session};
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
    pub session: Session,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            session: Session::new(),
        }
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

    // Exact-first chemistry is executed by the authoritative CENTL Chemistry
    // provider. CentL26 consumes its machine protocol and records the complete
    // protocol response as evidence; the Rust host does not duplicate chemical
    // parsing, balancing, or conservation semantics.
    if has_command_prefix(cmd, "chem") || has_command_prefix(cmd, "chemistry") {
        return handle_chemistry_command(cmd, state);
    }

    // Chemical Process Systems (CPS) Command Handler
    if has_command_prefix(cmd, "cps") {
        return handle_cps_command(cmd, state);
    }

    // Scientific Problem Interpretation (SCi) Command Handler
    if has_command_prefix(cmd, "sci") {
        return handle_sci_command(cmd, state);
    }

    // Development Workbench (MIRAGE) Command Handler
    if has_command_prefix(cmd, "mirage") {
        return handle_mirage_command(cmd, state);
    }

    // Preservation & Retrieval (CARAVAN) Command Handler
    if has_command_prefix(cmd, "caravan") {
        return handle_caravan_command(cmd, state);
    }

    // 1. Erdős–Straus Command Handler
    if cmd.starts_with("es ") || cmd == "es" || cmd.starts_with("erdos ") {
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        if parts.len() == 1 {
            let summary = run_hunt_window(1000, 500, 20);
            record_hunt_history(cmd, &summary, state);
            return (None, None, None, Some(summary));
        }
        match parts[1] {
            "solve" | "probe" => {
                if parts.len() >= 3 {
                    if let Ok(n) = parts[2].parse::<u64>() {
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
                        record_solve_history(cmd, &execution, &res, state);
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
                record_hunt_history(cmd, &summary, state);
                return (None, None, None, Some(summary));
            }
            "status" => {
                let summary = run_hunt_window(1000, 1000, 30);
                record_hunt_history(cmd, &summary, state);
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
            let started = Instant::now();
            return match convert_units(value, parts[3], parts[4]) {
                Ok(result) => {
                    record_physics_history(cmd, &result, started.elapsed().as_micros(), state);
                    (None, None, Some(result), None)
                }
                Err(error) => (None, Some(error), None, None),
            };
        }

        if parts.len() >= 2 && parts[1] == "units" {
            let started = Instant::now();
            let result = crate::physics::list_units_catalog();
            record_physics_history(cmd, &result, started.elapsed().as_micros(), state);
            return (None, None, Some(result), None);
        }

        if parts.len() >= 2 && parts[1] == "constant" {
            if parts.len() != 3 {
                return (
                    None,
                    Some("Usage: physics constant <symbol>".to_string()),
                    None,
                    None,
                );
            }
            let sym = parts[2];
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
                record_physics_history(cmd, &result, started.elapsed().as_micros(), state);
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

        if parts.len() >= 2 && parts[1] == "cherenkov" {
            if parts.len() != 4 {
                return (
                    None,
                    Some("Usage: physics cherenkov <refractive_index> <particle_speed_m_per_s>".to_string()),
                    None,
                    None,
                );
            }
            let n = match parts[2].parse::<f64>() {
                Ok(v) => v,
                Err(_) => return (None, Some(format!("Invalid refractive index: {}", parts[2])), None, None),
            };
            let v = match parts[3].parse::<f64>() {
                Ok(v) => v,
                Err(_) => return (None, Some(format!("Invalid particle speed: {}", parts[3])), None, None),
            };
            let started = Instant::now();
            return match crate::physics::calculate_cherenkov(n, v) {
                Ok(result) => {
                    record_physics_history(cmd, &result, started.elapsed().as_micros(), state);
                    (None, None, Some(result), None)
                }
                Err(error) => (None, Some(error), None, None),
            };
        }

        if parts.len() >= 2 && parts[1] == "gravity" {
            let mass = named_f64(&parts[2..], "m").or_else(|| named_f64(&parts[2..], "mass")).unwrap_or(1.0);
            let pos = named_vec3(&parts[2..], "p").or_else(|| named_vec3(&parts[2..], "pos")).or_else(|| named_vec3(&parts[2..], "position")).unwrap_or((0.0, 0.0, 0.0));
            let vel = named_vec3(&parts[2..], "v").or_else(|| named_vec3(&parts[2..], "vel")).or_else(|| named_vec3(&parts[2..], "velocity")).unwrap_or((0.0, 0.0, 0.0));
            let grav = named_vec3(&parts[2..], "g").or_else(|| named_vec3(&parts[2..], "grav")).or_else(|| named_vec3(&parts[2..], "gravity")).unwrap_or((0.0, 0.0, -9.80665));
            let dt = named_f64(&parts[2..], "dt").unwrap_or(0.01);
            let steps = named_u64(&parts[2..], "steps").or_else(|| named_u64(&parts[2..], "n")).unwrap_or(100);

            let started = Instant::now();
            return match crate::physics::simulate_gravity_trajectory(mass, pos, vel, grav, dt, steps) {
                Ok(result) => {
                    record_physics_history(cmd, &result, started.elapsed().as_micros(), state);
                    (None, None, Some(result), None)
                }
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

            let started = Instant::now();
            return match simulate_collision_1d(m1, v1, m2, v2, restitution) {
                Ok(result) => {
                    record_physics_history(cmd, &result, started.elapsed().as_micros(), state);
                    (None, None, Some(result), None)
                }
                Err(error) => (None, Some(error), None, None),
            };
        }

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
            state.session.history.push(HistoryEntry {
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
    } else {
        command["chem".len()..].trim()
    };
    let mut tokens = tokenize_command_args(body);
    if tokens.is_empty() {
        return Err("Usage: chem <operation> [args...]".to_string());
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
    state.session.history.push(HistoryEntry {
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
    state.session.history.push(HistoryEntry {
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
    state.session.history.push(HistoryEntry {
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
    state.session.history.push(HistoryEntry {
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
    let body = command.strip_prefix("sci ").unwrap_or(command).trim();
    let provider = super::capabilities::sci_provider().command;
    let started = Instant::now();
    let output = match run_bounded_provider(&provider, &["--json".to_string(), body.to_string()], CHEMISTRY_PROVIDER_TIMEOUT) {
        Ok(out) => out,
        Err(error) => {
            return (
                None,
                Some(format!("CENTL-SCi scientific interpretation engine unavailable: {}", error)),
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
                format!("SCi interpretation failed with status {}", output.status)
            } else {
                stderr.trim().to_string()
            }),
            None,
            None,
        );
    }
    let payload: Value = match serde_json::from_slice(&output.stdout) {
        Ok(v) => v,
        Err(e) => return (None, Some(format!("SCi returned invalid protocol JSON: {}", e)), None, None),
    };
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
    state.session.history.push(HistoryEntry {
        command: command.to_string(),
        result: summary,
        exact_repr: Some(evidence),
        approximate_repr: None,
        execution_micros: elapsed,
        success: true,
    });
    (Some(result), None, None, None)
}

fn handle_mirage_command(
    command: &str,
    state: &mut AppState,
) -> (
    Option<ExecutionResult>,
    Option<String>,
    Option<PhysicsResult>,
    Option<HuntSummary>,
) {
    let body = command.strip_prefix("mirage").unwrap_or(command).trim();
    let tokens = tokenize_command_args(body);
    let provider = super::capabilities::mirage_provider().command;
    let started = Instant::now();
    let output = match run_bounded_provider(&provider, &tokens, CHEMISTRY_PROVIDER_TIMEOUT) {
        Ok(out) => out,
        Err(error) => {
            return (
                None,
                Some(format!("CENTL-MIRAGE development engine unavailable: {}", error)),
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
                format!("MIRAGE failed with status {}", output.status)
            } else {
                stderr
            }),
            None,
            None,
        );
    }
    let text = if stdout.is_empty() {
        "MIRAGE command completed.".to_string()
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
    state.session.history.push(HistoryEntry {
        command: command.to_string(),
        result: text,
        exact_repr: None,
        approximate_repr: None,
        execution_micros: elapsed,
        success: true,
    });
    (Some(result), None, None, None)
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
    state.session.history.push(HistoryEntry {
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
            session: Session::new(),
        };
        let (_, error, physics, _) = handle_command("physics nonsense", &mut state);
        assert!(error.is_some());
        assert!(physics.is_none());
    }

    #[test]
    fn physics_and_research_runs_preserve_typed_restart_evidence() {
        let mut state = AppState {
            session: Session::new(),
        };
        let (_, error, physics, _) = handle_command("physics convert 100 cm m", &mut state);
        assert!(error.is_none());
        assert!(physics.is_some());
        assert_eq!(state.session.history.len(), 1);
        assert!(state.session.history[0]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("org.fcf.centl.physics.compute"));
        assert!(state.session.history[0].approximate_repr.is_some());

        let (solve, error, _, _) = handle_command("es solve 1009", &mut state);
        assert!(error.is_none());
        assert!(solve.is_some());
        assert_eq!(state.session.history.len(), 2);
        assert!(state.session.history[1]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("broker_verified"));

        let (_, error, _, hunt) = handle_command("es", &mut state);
        assert!(error.is_none());
        assert!(hunt.is_some());
        assert_eq!(state.session.history.len(), 3);
        assert!(state.session.history[2]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("org.fcf.centl.research.erdos_straus/hunt"));
        assert!(state.session.history[2]
            .approximate_repr
            .as_deref()
            .unwrap()
            .contains("Bounded search"));
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
            chemistry_provider_args("chem charge 2").unwrap(),
            vec!["charge", "2"]
        );
        assert_eq!(
            chemistry_provider_args("chem stoich '2 H2 + O2 -> 2 H2O' H2 4 H2O").unwrap(),
            vec!["stoich", "2 H2 + O2 -> 2 H2O", "H2", "4", "H2O"]
        );
        assert_eq!(
            chemistry_provider_args("chem limiting '2 H2 + O2 -> 2 H2O' H2=4 O2=1").unwrap(),
            vec!["limiting", "2 H2 + O2 -> 2 H2O", "H2=4", "O2=1"]
        );
        assert_eq!(
            chemistry_provider_args("chem spread g 1.0 1.1 0.9").unwrap(),
            vec!["spread", "g", "1.0", "1.1", "0.9"]
        );
    }
}

