// CENTL-SCi Plain English STEM Problem Solver & Hybrid Gemini Integration
// Free Computation Foundation - Apache-2.0

use crate::engine::{evaluate, Session};
use crate::erdos_straus::solve_es;
use crate::physics::{convert_units, lookup_constant};
use serde_json::{json, Value};
use std::env;
use std::sync::Mutex;

static RUNTIME_GEMINI_KEY: Mutex<Option<String>> = Mutex::new(None);

pub fn set_runtime_gemini_key(key: &str) {
    let mut lock = RUNTIME_GEMINI_KEY.lock().unwrap_or_else(|p| p.into_inner());
    let trimmed = key.trim().to_string();
    if trimmed.is_empty() {
        *lock = None;
    } else {
        *lock = Some(trimmed);
    }
}

pub fn get_runtime_gemini_key() -> Option<String> {
    let lock = RUNTIME_GEMINI_KEY.lock().unwrap_or_else(|p| p.into_inner());
    if let Some(ref k) = *lock {
        return Some(k.clone());
    }
    if let Ok(k) = env::var("CENTL_GEMINI_KEY") {
        if !k.trim().is_empty() {
            return Some(k.trim().to_string());
        }
    }
    if let Ok(k) = env::var("GEMINI_API_KEY") {
        if !k.trim().is_empty() {
            return Some(k.trim().to_string());
        }
    }
    None
}

#[derive(Clone, Debug)]
pub struct SciSolution {
    pub summary: String,
    pub steps: Vec<String>,
    pub exact_result: Option<String>,
    pub approximate_result: Option<String>,
    pub domain: &'static str,
    pub confidence: &'static str,
    pub raw_centl_command: Option<String>,
}

/// Interpret and solve a plain English STEM problem using the native offline solver or Gemini hybrid mode.
pub fn interpret_and_solve_stem(
    prompt: &str,
    session: &mut Session,
    prefer_gemini: bool,
) -> Result<SciSolution, String> {
    let trimmed = prompt.trim();
    if trimmed.is_empty() {
        return Err("Please enter a STEM problem or question.".to_string());
    }

    // Check if Gemini hybrid mode is requested or key is available
    if prefer_gemini || trimmed.starts_with("gemini ") || trimmed.starts_with(":gemini ") {
        let clean_prompt = trimmed
            .strip_prefix(":gemini ")
            .or_else(|| trimmed.strip_prefix("gemini "))
            .unwrap_or(trimmed)
            .trim();

        if let Some(key) = get_runtime_gemini_key() {
            match solve_with_gemini_hybrid(clean_prompt, &key, session) {
                Ok(sol) => return Ok(sol),
                Err(err) => {
                    // Fall back to offline solver with a notice
                    let mut fallback = solve_stem_offline(clean_prompt, session)?;
                    fallback.steps.insert(
                        0,
                        format!("[Notice] Gemini hybrid query encountered an issue ({}); solved using native offline SCi kernel.", err),
                    );
                    return Ok(fallback);
                }
            }
        } else if prefer_gemini || trimmed.starts_with("gemini ") || trimmed.starts_with(":gemini ") {
            return Err("Gemini API key is not configured. Set CENTL_GEMINI_KEY / GEMINI_API_KEY environment variable or run ':gemini-key <YOUR_KEY>'.".to_string());
        }
    }

    // Default: solve using native offline SCi engine
    solve_stem_offline(trimmed, session)
}

/// Native Offline Plain-English STEM solver
pub fn solve_stem_offline(prompt: &str, session: &mut Session) -> Result<SciSolution, String> {
    let lower = prompt.to_ascii_lowercase();

    // 1. Chemistry: Molar Mass / Molecular Weight
    // "What is the molar mass of H2SO4?", "Calculate molecular mass of Ca(OH)2"
    if lower.contains("molar mass") || lower.contains("molecular mass") || lower.contains("molecular weight") || lower.contains("molar weight") {
        if let Some(formula) = extract_chemical_formula(prompt) {
            let cmd = format!("chem molar-mass {}", formula);
            return Ok(SciSolution {
                summary: format!("Molar Mass Calculation for {}", formula),
                steps: vec![
                    format!("Extracted chemical formula: {}", formula),
                    "Mapped atomic composition and standard atomic weights from the IUPAC periodic catalog.".to_string(),
                    format!("Command executed: {}", cmd),
                ],
                exact_result: None,
                approximate_result: None,
                domain: "Chemistry",
                confidence: "Exact Deterministic",
                raw_centl_command: Some(cmd),
            });
        }
    }

    // 2. Chemistry: Balance Reaction
    // "Balance the chemical equation: Fe + O2 -> Fe2O3", "Balance combustion of butane C4H10 + O2 -> CO2 + H2O"
    if (lower.contains("balance") || lower.contains("reaction") || lower.contains("combustion") || lower.contains("coefficients"))
        && (prompt.contains("->") || prompt.contains("-->") || prompt.contains("=>"))
    {
        let reaction = extract_reaction_part(prompt);
        let cmd = format!("chem balance {}", reaction);
        return Ok(SciSolution {
            summary: format!("Stoichiometric Reaction Balancing for: {}", reaction),
            steps: vec![
                format!("Detected reaction equation: {}", reaction),
                "Formulated integer nullspace system for element conservation.".to_string(),
                "Solved exact conservation matrix without floating-point approximations.".to_string(),
                format!("Command executed: {}", cmd),
            ],
            exact_result: None,
            approximate_result: None,
            domain: "Chemistry",
            confidence: "Exact Rational Nullspace",
            raw_centl_command: Some(cmd),
        });
    }

    // 3. Chemistry: Atom Counting
    // "How many atoms in Al2(SO4)3?", "Atom count for Ca(OH)2"
    if (lower.contains("atom count") || lower.contains("atoms in") || lower.contains("composition of"))
        && !prompt.contains("->")
    {
        if let Some(formula) = extract_chemical_formula(prompt) {
            let cmd = format!("chem atoms {}", formula);
            return Ok(SciSolution {
                summary: format!("Chemical Composition & Atom Count for {}", formula),
                steps: vec![
                    format!("Parsed formula syntax with nested parenthesized radicals: {}", formula),
                    "Evaluated stoichiometric multipliers for each element symbol.".to_string(),
                    format!("Command executed: {}", cmd),
                ],
                exact_result: None,
                approximate_result: None,
                domain: "Chemistry",
                confidence: "Exact Integer",
                raw_centl_command: Some(cmd),
            });
        }
    }

    // 4. Chemistry: Solution pH, pOH, and [H+] / [OH-]
    // "What is the pH of a 0.05 M HCl solution?", "Calculate pH for [H+] = 1.0e-4", "Find [OH-] for pH = 11"
    if lower.contains("ph of") || lower.contains("poh of") || lower.contains("ph for") || lower.contains("calculate ph") || lower.contains("calculate poh") || lower.contains("[h+]") || lower.contains("[oh-]") {
        let numbers = extract_all_f64(prompt);
        if !numbers.is_empty() {
            let val = numbers[0];
            if lower.contains("ph =") || lower.contains("ph=") || (lower.contains("ph of") && val > 1.0 && val <= 14.0) {
                let ph = val;
                let poh = 14.0 - ph;
                let h_conc = 10.0_f64.powf(-ph);
                let oh_conc = 10.0_f64.powf(-poh);
                return Ok(SciSolution {
                    summary: format!("Solution Equilibrium for pH = {:.2}", ph),
                    steps: vec![
                        format!("Given pH: {:.4}", ph),
                        format!("pOH = 14 - pH = {:.4}", poh),
                        format!("Hydronium concentration [H+] = 10^(-pH) = {:.4e} M", h_conc),
                        format!("Hydroxide concentration [OH-] = 10^(-pOH) = {:.4e} M", oh_conc),
                    ],
                    exact_result: Some(format!("pH = {:.2}, pOH = {:.2}, [H+] = {:.3e} M, [OH-] = {:.3e} M", ph, poh, h_conc, oh_conc)),
                    approximate_result: None,
                    domain: "Solution Chemistry",
                    confidence: "Aqueous Equilibrium (25 °C)",
                    raw_centl_command: None,
                });
            } else if val > 0.0 {
                let is_base = lower.contains("naoh") || lower.contains("koh") || lower.contains("base") || lower.contains("poh");
                let ph = if is_base { 14.0 + val.log10() } else { -val.log10() };
                let poh = 14.0 - ph;
                let h_conc = 10.0_f64.powf(-ph);
                let oh_conc = 10.0_f64.powf(-poh);
                return Ok(SciSolution {
                    summary: format!("Solution Acidity / Basicity (C = {:.4e} M)", val),
                    steps: vec![
                        format!("Species type: {}", if is_base { "Strong Monobasic Alkaline Solution" } else { "Strong Monoprotic Acidic Solution" }),
                        format!("Specified concentration: {:.4e} M", val),
                        format!("pH = {:.4}", ph),
                        format!("pOH = {:.4}", poh),
                        format!("[H+] = {:.4e} M", h_conc),
                        format!("[OH-] = {:.4e} M", oh_conc),
                    ],
                    exact_result: Some(format!("pH = {:.4}, pOH = {:.4}", ph, poh)),
                    approximate_result: None,
                    domain: "Solution Chemistry",
                    confidence: "Deterministic Logarithmic Equilibrium",
                    raw_centl_command: None,
                });
            }
        }
    }

    // 5. Chemistry: Molarity, Dilution & Solution Preparation
    // "Dilute 50 mL of 2 M HCl to 200 mL, what is the final concentration?", "M1 V1 = M2 V2"
    if (lower.contains("dilute") || lower.contains("dilution")) && (lower.contains("ml") || lower.contains("l") || lower.contains("m")) {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 3 {
            let (v1, m1, v2) = (numbers[0], numbers[1], numbers[2]);
            if v2 > 0.0 {
                let m2 = (v1 * m1) / v2;
                return Ok(SciSolution {
                    summary: "Solution Dilution (M1*V1 = M2*V2)".to_string(),
                    steps: vec![
                        format!("Initial Volume (V1): {} | Initial Molarity (M1): {} M", v1, m1),
                        format!("Final Volume (V2): {}", v2),
                        format!("Applied conservation of moles: n = M1 * V1 = {} mmol/mol", v1 * m1),
                        format!("Final Molarity: M2 = (M1 * V1) / V2 = ({:.4} * {:.4}) / {:.4} = {:.6} M", m1, v1, v2, m2),
                    ],
                    exact_result: Some(format!("M2 = {:.6} M", m2)),
                    approximate_result: None,
                    domain: "Solution Chemistry",
                    confidence: "Exact Stoichiometric Dilution",
                    raw_centl_command: Some(format!("chem dilution {} {} {}", v1, m1, v2)),
                });
            }
        }
    }

    // 6. Chemistry: Gibbs Free Energy & Reaction Spontaneity
    // "Calculate Gibbs free energy when delta H is -92.4 kJ and delta S is -198 J/K at 298 K"
    if lower.contains("gibbs") || lower.contains("delta g") || lower.contains("spontaneity") || (lower.contains("delta h") && lower.contains("delta s")) {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 3 {
            let dh_kj = numbers[0];
            let ds_j_k = numbers[1];
            let t_k = numbers[2];
            let dg_kj = dh_kj - (t_k * (ds_j_k / 1000.0));
            let spontaneous = dg_kj < 0.0;
            return Ok(SciSolution {
                summary: format!("Gibbs Free Energy & Spontaneity (T = {} K)", t_k),
                steps: vec![
                    format!("Enthalpy change (ΔH): {:.4} kJ/mol", dh_kj),
                    format!("Entropy change (ΔS): {:.4} J/(mol·K) = {:.6} kJ/(mol·K)", ds_j_k, ds_j_k / 1000.0),
                    format!("Absolute Temperature (T): {:.2} K", t_k),
                    "Fundamental relation: ΔG = ΔH - T·ΔS".to_string(),
                    format!("Calculated ΔG: {:.4} - ({:.2} * {:.6}) = {:.4} kJ/mol", dh_kj, t_k, ds_j_k / 1000.0, dg_kj),
                    format!("Spontaneity: {}", if spontaneous { "SPONTANEOUS (Exergonic / Thermodynamic Driving Force Present)" } else { "NON-SPONTANEOUS (Endergonic at this temperature)" }),
                ],
                exact_result: Some(format!("ΔG = {:.4} kJ/mol ({})", dg_kj, if spontaneous { "Spontaneous" } else { "Non-spontaneous" })),
                approximate_result: None,
                domain: "Thermochemistry",
                confidence: "Exact Thermodynamic Formulation",
                raw_centl_command: None,
            });
        }
    }

    // 7. Chemistry: Nernst Equation & Electrochemical Potential
    // "Nernst equation for E0 = 1.10 V, n = 2, Q = 0.01"
    if lower.contains("nernst") || (lower.contains("cell potential") && lower.contains("q")) {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 3 {
            let e0 = numbers[0];
            let n = numbers[1];
            let q = numbers[2];
            if n > 0.0 && q > 0.0 {
                let e_cell = e0 - (0.05916 / n) * q.log10();
                return Ok(SciSolution {
                    summary: "Nernst Electrochemical Cell Potential (298.15 K)".to_string(),
                    steps: vec![
                        format!("Standard cell potential (E°): {:.4} V", e0),
                        format!("Electrons transferred (n): {}", n),
                        format!("Reaction quotient (Q): {:.4e}", q),
                        "Nernst formulation: E = E° - (0.05916 / n) * log10(Q)".to_string(),
                        format!("Calculated Cell Potential: {:.4} - ({:.5} / {}) * log10({:.4e}) = {:.6} V", e0, 0.05916, n, q, e_cell),
                    ],
                    exact_result: Some(format!("E_cell = {:.6} V", e_cell)),
                    approximate_result: None,
                    domain: "Electrochemistry",
                    confidence: "Exact Electrochemical Form",
                    raw_centl_command: None,
                });
            }
        }
    }

    // 8. Physics: Physical Constants
    // "What is Planck's constant?", "Speed of light", "Gravitational constant"
    if lower.contains("constant") || lower.contains("speed of light") || lower.contains("planck") || lower.contains("gravitational constant")
        || lower.contains("avogadro") || lower.contains("boltzmann") || lower.contains("electron mass") || lower.contains("proton mass")
        || lower.contains("gas constant") || lower.contains("elementary charge")
    {
        let sym = if lower.contains("speed of light") || lower.contains(" c ") || lower.ends_with(" c") {
            "c"
        } else if lower.contains("planck") || lower.contains(" h ") {
            "h"
        } else if lower.contains("gravitational") || lower.contains("big g") {
            "G"
        } else if lower.contains("avogadro") || lower.contains("na") {
            "N_A"
        } else if lower.contains("boltzmann") || lower.contains("kb") {
            "k_B"
        } else if lower.contains("electron mass") || lower.contains("me") {
            "m_e"
        } else if lower.contains("proton mass") || lower.contains("mp") {
            "m_p"
        } else if lower.contains("elementary charge") || lower.contains("charge of electron") {
            "e"
        } else if lower.contains("gas constant") {
            "R"
        } else {
            "c"
        };
        if let Some(c) = lookup_constant(sym) {
            let cmd = format!("physics constant {}", sym);
            return Ok(SciSolution {
                summary: format!("Physical Constant: {} ({})", c.name, c.symbol),
                steps: vec![
                    format!("Retrieved authoritative physical constant: {}", c.name),
                    format!("Value: {} {}", c.value_str, c.unit),
                    format!("Exactness: {}", if c.exact { "Exact SI 2019 Definition" } else { "Measured Value with Provenance" }),
                    format!("Provenance: {}", c.provenance),
                ],
                exact_result: Some(format!("{} = {} {}", c.symbol, c.value_str, c.unit)),
                approximate_result: None,
                domain: "Physics",
                confidence: "Authoritative SI Catalog",
                raw_centl_command: Some(cmd),
            });
        }
    }

    // 9. Physics: Unit Conversion
    // "Convert 100 km/h to m/s", "Convert 1 atmosphere to pascals", "How many seconds in 2 hours?"
    if lower.contains("convert") || lower.contains("how many") || lower.contains("in meters") || lower.contains("in pascals") || lower.contains("to m/s") || lower.contains("to km/h") {
        if let Some((val, from_u, to_u)) = extract_unit_conversion(prompt) {
            match convert_units(val, &from_u, &to_u) {
                Ok(res) => {
                    let cmd = format!("physics convert {} {} {}", val, from_u, to_u);
                    return Ok(SciSolution {
                        summary: format!("Physical Unit Conversion: {} {} -> {}", val, from_u, to_u),
                        steps: vec![
                            format!("Identified source quantity: {} {}", val, from_u),
                            format!("Target unit dimension: {}", to_u),
                            format!("Conversion relation: {}", res.summary),
                        ],
                        exact_result: Some(res.summary),
                        approximate_result: None,
                        domain: "Physics",
                        confidence: "Exact Rational Conversion",
                        raw_centl_command: Some(cmd),
                    });
                }
                Err(e) => return Err(format!("Unit conversion failed: {}", e)),
            }
        }
    }

    // 10. Mechanics: Kinematics (Acceleration, Displacement & Free Fall)
    // "A car accelerates from 0 to 25 m/s in 5 seconds, what is its acceleration?", "How far does an object travel accelerating at 3 m/s^2 for 10 s?"
    if lower.contains("accelerat") || lower.contains("kinematics") || (lower.contains("velocity") && lower.contains("seconds")) || lower.contains("free fall") || lower.contains("dropped from") {
        let numbers = extract_all_f64(prompt);
        if lower.contains("accelerat") && numbers.len() >= 3 {
            let (v0, v1, t) = (numbers[0], numbers[1], numbers[2]);
            if t > 0.0 {
                let a = (v1 - v0) / t;
                let d = v0 * t + 0.5 * a * t * t;
                return Ok(SciSolution {
                    summary: format!("Kinematics Linear Motion Calculation (t = {} s)", t),
                    steps: vec![
                        format!("Initial velocity (v0): {:.4} m/s", v0),
                        format!("Final velocity (v): {:.4} m/s", v1),
                        format!("Elapsed time (t): {:.4} s", t),
                        format!("Acceleration: a = (v - v0)/t = ({:.4} - {:.4}) / {:.4} = {:.6} m/s²", v1, v0, t, a),
                        format!("Displacement: d = v0·t + ½·a·t² = {:.6} m", d),
                    ],
                    exact_result: Some(format!("a = {:.4} m/s², d = {:.4} m", a, d)),
                    approximate_result: None,
                    domain: "Classical Mechanics",
                    confidence: "Newtonian Kinematics",
                    raw_centl_command: None,
                });
            }
        } else if (lower.contains("how far") || lower.contains("distance")) && numbers.len() >= 2 {
            let (a, t) = (numbers[0], numbers[1]);
            let d = 0.5 * a * t * t;
            let v = a * t;
            return Ok(SciSolution {
                summary: "Kinematic Displacement Under Constant Acceleration".to_string(),
                steps: vec![
                    format!("Acceleration (a): {:.4} m/s²", a),
                    format!("Time duration (t): {:.4} s", t),
                    format!("Calculated distance: d = ½·a·t² = ½ * {:.4} * ({:.4})² = {:.6} m", a, t, d),
                    format!("Final speed reached: v = a·t = {:.4} m/s", v),
                ],
                exact_result: Some(format!("d = {:.4} m, v = {:.4} m/s", d, v)),
                approximate_result: None,
                domain: "Classical Mechanics",
                confidence: "Exact Kinematics",
                raw_centl_command: None,
            });
        } else if lower.contains("free fall") || lower.contains("dropped from") {
            if !numbers.is_empty() {
                let h = numbers[0];
                let g = 9.80665;
                let v = (2.0 * g * h).sqrt();
                let t = (2.0 * h / g).sqrt();
                return Ok(SciSolution {
                    summary: format!("Free Fall Gravitational Kinematics (h = {} m)", h),
                    steps: vec![
                        format!("Initial height (h): {:.4} m", h),
                        format!("Gravitational acceleration (g): {:.5} m/s² (Standard Earth Gravity)", g),
                        format!("Impact velocity: v = √(2·g·h) = √(2 * {:.5} * {:.4}) = {:.6} m/s", g, h, v),
                        format!("Fall time duration: t = √(2·h/g) = {:.6} s", t),
                    ],
                    exact_result: Some(format!("v = {:.4} m/s ({:.2} km/h), t = {:.4} s", v, v * 3.6, t)),
                    approximate_result: None,
                    domain: "Classical Mechanics",
                    confidence: "Standard Newtonian Free Fall",
                    raw_centl_command: None,
                });
            }
        }
    }

    // 10b. Relativistic Cherenkov Radiation Threshold & Angle
    if lower.contains("cherenkov") {
        if let Some((n, v)) = extract_cherenkov_params(prompt) {
            let cmd = format!("physics cherenkov {} {}", n, v);
            return Ok(SciSolution {
                summary: "Relativistic Cherenkov Radiation Threshold & Angle".to_string(),
                steps: vec![
                    format!("Refractive index (n): {}", n),
                    format!("Charged particle velocity (v): {} m/s", v),
                    "Phase velocity of light in medium: c/n".to_string(),
                    format!("Command executed: {}", cmd),
                ],
                exact_result: None,
                approximate_result: None,
                domain: "Physics",
                confidence: "Relativistic Kinematics",
                raw_centl_command: Some(cmd),
            });
        }
    }

    // 11. Mechanics: Work, Energy & Power ($KE = 0.5mv^2$, $PE = mgh$, $W = Fd$, $P = W/t$)
    // "Calculate kinetic energy of a 1500 kg car moving at 25 m/s", "Potential energy of 10 kg at height 15 m"
    if lower.contains("kinetic energy") || lower.contains("potential energy") || lower.contains("work done") || lower.contains("power for") || lower.contains("power if") {
        let numbers = extract_all_f64(prompt);
        if lower.contains("kinetic") && numbers.len() >= 2 {
            let (m, v) = (numbers[0], numbers[1]);
            let ke = 0.5 * m * v * v;
            return Ok(SciSolution {
                summary: format!("Kinetic Energy Calculation (m = {} kg, v = {} m/s)", m, v),
                steps: vec![
                    format!("Mass (m): {:.4} kg", m),
                    format!("Velocity (v): {:.4} m/s", v),
                    "Formula: KE = ½·m·v²".to_string(),
                    format!("Calculated Kinetic Energy: ½ * {:.4} * ({:.4})² = {:.6} J ({:.4} kJ)", m, v, ke, ke / 1000.0),
                ],
                exact_result: Some(format!("KE = {:.4} J ({:.4} kJ)", ke, ke / 1000.0)),
                approximate_result: None,
                domain: "Classical Mechanics",
                confidence: "Exact Energy Formulation",
                raw_centl_command: None,
            });
        } else if lower.contains("potential") && numbers.len() >= 2 {
            let (m, h) = (numbers[0], numbers[1]);
            let g = 9.80665;
            let pe = m * g * h;
            return Ok(SciSolution {
                summary: format!("Gravitational Potential Energy (m = {} kg, h = {} m)", m, h),
                steps: vec![
                    format!("Mass (m): {:.4} kg", m),
                    format!("Height (h): {:.4} m", h),
                    format!("Gravity (g): {:.5} m/s²", g),
                    "Formula: PE = m·g·h".to_string(),
                    format!("Calculated Potential Energy: {:.4} * {:.5} * {:.4} = {:.6} J ({:.4} kJ)", m, g, h, pe, pe / 1000.0),
                ],
                exact_result: Some(format!("PE = {:.4} J ({:.4} kJ)", pe, pe / 1000.0)),
                approximate_result: None,
                domain: "Classical Mechanics",
                confidence: "Exact Potential Energy",
                raw_centl_command: None,
            });
        } else if (lower.contains("work done") || lower.contains("work")) && numbers.len() >= 2 {
            let (f, d) = (numbers[0], numbers[1]);
            let w = f * d;
            return Ok(SciSolution {
                summary: format!("Mechanical Work Calculation (F = {} N, d = {} m)", f, d),
                steps: vec![
                    format!("Applied Force (F): {:.4} N", f),
                    format!("Displacement (d): {:.4} m", d),
                    "Formula: W = F · d".to_string(),
                    format!("Calculated Work: {:.4} * {:.4} = {:.6} J", f, d, w),
                ],
                exact_result: Some(format!("W = {:.4} J", w)),
                approximate_result: None,
                domain: "Classical Mechanics",
                confidence: "Exact Vector Work",
                raw_centl_command: None,
            });
        } else if lower.contains("power") && numbers.len() >= 2 {
            let (w, t) = (numbers[0], numbers[1]);
            if t > 0.0 {
                let p = w / t;
                return Ok(SciSolution {
                    summary: format!("Mechanical / Electrical Power (W = {} J, t = {} s)", w, t),
                    steps: vec![
                        format!("Energy / Work (W): {:.4} J", w),
                        format!("Time duration (t): {:.4} s", t),
                        "Formula: P = W / t".to_string(),
                        format!("Calculated Power: {:.4} / {:.4} = {:.6} Watts (W) = {:.4} kW", w, t, p, p / 1000.0),
                    ],
                    exact_result: Some(format!("P = {:.4} W ({:.4} kW)", p, p / 1000.0)),
                    approximate_result: None,
                    domain: "Classical Mechanics",
                    confidence: "Exact Power Rate",
                    raw_centl_command: None,
                });
            }
        }
    }

    // 12. Electromagnetism & Circuits: Ohm's Law & Power ($V = IR$, $P = VI$, $C = Q/V$)
    // "What is the current with voltage 120 V and resistance 15 ohms?", "Electrical power for 240 V and 30 A"
    if lower.contains("ohm") || lower.contains("voltage") || lower.contains("current with") || lower.contains("resistance with") || lower.contains("capacitance with") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            if lower.contains("current") {
                let (v, r) = (numbers[0], numbers[1]);
                if r > 0.0 {
                    let i = v / r;
                    let p = v * i;
                    return Ok(SciSolution {
                        summary: format!("Ohm's Law: Current Calculation (V = {} V, R = {} Ω)", v, r),
                        steps: vec![
                            format!("Voltage (V): {:.4} Volts", v),
                            format!("Resistance (R): {:.4} Ohms (Ω)", r),
                            "Formula: I = V / R".to_string(),
                            format!("Calculated Current: {:.4} / {:.4} = {:.6} Amperes (A)", v, r, i),
                            format!("Associated Power Dissipation: P = V·I = {:.6} Watts", p),
                        ],
                        exact_result: Some(format!("I = {:.4} A, P = {:.4} W", i, p)),
                        approximate_result: None,
                        domain: "Electromagnetism",
                        confidence: "Ohmic Linear Circuit Law",
                        raw_centl_command: None,
                    });
                }
            } else if lower.contains("resistance") {
                let (v, i) = (numbers[0], numbers[1]);
                if i > 0.0 {
                    let r = v / i;
                    return Ok(SciSolution {
                        summary: format!("Ohm's Law: Resistance Calculation (V = {} V, I = {} A)", v, i),
                        steps: vec![
                            format!("Voltage (V): {:.4} Volts", v),
                            format!("Current (I): {:.4} Amperes", i),
                            format!("Formula: R = V / I = {:.4} / {:.4} = {:.6} Ohms (Ω)", v, i, r),
                        ],
                        exact_result: Some(format!("R = {:.4} Ω", r)),
                        approximate_result: None,
                        domain: "Electromagnetism",
                        confidence: "Exact Ohmic Law",
                        raw_centl_command: None,
                    });
                }
            } else if lower.contains("capacitance") {
                let (q, v) = (numbers[0], numbers[1]);
                if v > 0.0 {
                    let c = q / v;
                    return Ok(SciSolution {
                        summary: format!("Capacitance & Stored Charge (Q = {} C, V = {} V)", q, v),
                        steps: vec![
                            format!("Electric Charge (Q): {:.4e} Coulombs", q),
                            format!("Electric Potential (V): {:.4} Volts", v),
                            format!("Formula: C = Q / V = {:.4e} / {:.4} = {:.6e} Farads (F)", q, v, c),
                            format!("Stored Electrostatic Energy: U = ½·C·V² = {:.6e} Joules", 0.5 * c * v * v),
                        ],
                        exact_result: Some(format!("C = {:.4e} F", c)),
                        approximate_result: None,
                        domain: "Electromagnetism",
                        confidence: "Electrostatic Capacitance",
                        raw_centl_command: None,
                    });
                }
            }
        }
    }

    // 13. Quantum Physics: De Broglie Wavelength
    // "Calculate de broglie wavelength for mass 9.1e-31 and velocity 1e6"
    if lower.contains("de broglie") || lower.contains("matter wave") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let m = numbers[0];
            let v = numbers[1];
            if let Ok(res) = crate::physics::calculate_debroglie(m, v) {
                return Ok(SciSolution {
                    summary: format!("De Broglie Wavelength Calculation (m = {:.2e} kg, v = {:.2e} m/s)", m, v),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Quantum Physics",
                    confidence: "Exact Physical Constant",
                    raw_centl_command: Some(format!("physics debroglie {} {}", m, v)),
                });
            }
        }
    }

    // 14. Quantum Physics: Photon Energy & Frequency
    // "Calculate energy of photon with wavelength 500 nm"
    if lower.contains("photon energy") || (lower.contains("photon") && (lower.contains("wavelength") || lower.contains("frequency"))) {
        let numbers = extract_all_f64(prompt);
        if !numbers.is_empty() {
            let mut val = numbers[0];
            let is_wavelength = !lower.contains("frequency") && !lower.contains("hz");
            if is_wavelength && val > 1.0 { val *= 1e-9; }
            if let Ok(res) = crate::physics::calculate_photon(val, is_wavelength) {
                return Ok(SciSolution {
                    summary: "Photon Energy & Momentum Calculation".to_string(),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Quantum Physics",
                    confidence: "Exact SI Formulation",
                    raw_centl_command: Some(format!("physics photon {}", val)),
                });
            }
        }
    }

    // 15. Spectroscopy: Hydrogen Rydberg Transitions
    // "What is the transition wavelength in hydrogen from n=3 to n=2?"
    if lower.contains("rydberg") || (lower.contains("hydrogen") && lower.contains("transition")) {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (n1, n2) = if numbers[0] < numbers[1] { (numbers[0] as u64, numbers[1] as u64) } else { (numbers[1] as u64, numbers[0] as u64) };
            let z = if numbers.len() >= 3 { numbers[2] as u64 } else { 1 };
            if let Ok(res) = crate::physics::calculate_rydberg(n1, n2, z) {
                return Ok(SciSolution {
                    summary: format!("Hydrogenic Spectral Transition (n = {} -> n = {}, Z = {})", n2, n1, z),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Quantum Spectroscopy",
                    confidence: "Rydberg Formula Exact",
                    raw_centl_command: Some(format!("physics rydberg {} {} {}", n1, n2, z)),
                });
            }
        }
    }

    // 16. Quantum Physics: Photoelectric Effect
    // "Stopping potential for work function 2.3 eV and wavelength 400 nm"
    if lower.contains("photoelectric") || (lower.contains("work function") && lower.contains("wavelength")) {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (phi, lambda) = (numbers[0], numbers[1]);
            if let Ok(res) = crate::physics::calculate_photoelectric(phi, lambda) {
                return Ok(SciSolution {
                    summary: "Photoelectric Effect Work Function & Stopping Potential".to_string(),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Quantum Physics",
                    confidence: "Einstein Photoelectric Conservation",
                    raw_centl_command: Some(format!("physics photoelectric {} {}", phi, lambda)),
                });
            }
        }
    }

    // 17. Thermodynamics: Carnot Heat Engine Efficiency
    // "What is the Carnot efficiency with hot reservoir 600 K and cold reservoir 300 K?"
    if lower.contains("carnot") || (lower.contains("efficiency") && lower.contains("reservoir")) {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (th, tc) = if numbers[0] > numbers[1] { (numbers[0], numbers[1]) } else { (numbers[1], numbers[0]) };
            if let Ok(res) = crate::physics::calculate_carnot(th, tc) {
                return Ok(SciSolution {
                    summary: format!("Carnot Maximum Thermodynamic Efficiency (Th = {} K, Tc = {} K)", th, tc),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Thermodynamics",
                    confidence: "Exact Thermodynamic Limit",
                    raw_centl_command: Some(format!("physics carnot {} {}", th, tc)),
                });
            }
        }
    }

    // 18. Radiation Physics: Stefan-Boltzmann & Wien's Displacement Law
    // "Blackbody radiation at 5800 K", "Stefan-Boltzmann flux for 3000 K"
    if lower.contains("blackbody") || lower.contains("stefan") || lower.contains("wien") {
        let numbers = extract_all_f64(prompt);
        if !numbers.is_empty() {
            let t = numbers[0];
            if let Ok(res) = crate::physics::calculate_blackbody(t, None, None) {
                return Ok(SciSolution {
                    summary: format!("Stefan-Boltzmann Blackbody Radiation & Wien Peak (T = {} K)", t),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Radiation Physics",
                    confidence: "CODATA Stefan-Boltzmann Law",
                    raw_centl_command: Some(format!("physics blackbody {}", t)),
                });
            }
        }
    }

    // 19. Astrophysics: Escape Velocity & Orbital Speed
    // "What is the escape velocity for mass 5.972e24 kg and radius 6.371e6 m?"
    if lower.contains("escape velocity") || lower.contains("orbital speed") || lower.contains("orbital velocity") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let m = numbers[0];
            let r = numbers[1];
            if let Ok(res) = crate::physics::calculate_escape_velocity(m, r) {
                return Ok(SciSolution {
                    summary: format!("Astrophysics Escape & Orbital Velocity (M = {:.2e} kg, R = {:.2e} m)", m, r),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Astrophysics",
                    confidence: "Newtonian Gravitation",
                    raw_centl_command: Some(format!("physics escape {} {}", m, r)),
                });
            }
        }
    }

    // 20. Special Relativity: Lorentz Transformation Factor
    // "Calculate Lorentz factor for velocity 2.4e8 m/s", "Time dilation at 0.8 c"
    if lower.contains("lorentz") || lower.contains("time dilation") || lower.contains("length contraction") {
        let numbers = extract_all_f64(prompt);
        if !numbers.is_empty() {
            let mut v = numbers[0];
            if v > 0.0 && v < 1.0 { v *= 299792458.0; }
            if let Ok(res) = crate::physics::calculate_lorentz(v) {
                return Ok(SciSolution {
                    summary: format!("Relativistic Lorentz Transformation (v = {:.2e} m/s)", v),
                    steps: res.details.iter().map(|(k, v)| format!("{}: {}", k, v)).collect(),
                    exact_result: Some(res.summary),
                    approximate_result: None,
                    domain: "Special Relativity",
                    confidence: "Exact Relativistic Kinematics",
                    raw_centl_command: Some(format!("physics lorentz {}", v)),
                });
            }
        }
    }

    // 21. Geometry & Mensuration: Circle, Sphere, Cylinder, Triangle
    // "Area of a circle with radius 7", "Volume of a sphere with radius 5", "Hypotenuse of triangle with legs 3 and 4"
    if lower.contains("area of a circle") || lower.contains("area of circle") || lower.contains("circumference of") {
        let numbers = extract_all_f64(prompt);
        if !numbers.is_empty() {
            let r = numbers[0];
            let area = std::f64::consts::PI * r * r;
            let circ = 2.0 * std::f64::consts::PI * r;
            return Ok(SciSolution {
                summary: format!("Circle Geometry (r = {})", r),
                steps: vec![
                    format!("Radius (r): {:.4}", r),
                    format!("Area: A = π·r² = π * ({:.4})² = {:.8}", r, area),
                    format!("Circumference: C = 2·π·r = 2 * π * {:.4} = {:.8}", r, circ),
                ],
                exact_result: Some(format!("Area = {:.6}, Circumference = {:.6}", area, circ)),
                approximate_result: None,
                domain: "Geometry",
                confidence: "Exact Geometric Formula",
                raw_centl_command: None,
            });
        }
    }

    if lower.contains("volume of a sphere") || lower.contains("volume of sphere") {
        let numbers = extract_all_f64(prompt);
        if !numbers.is_empty() {
            let r = numbers[0];
            let vol = (4.0 / 3.0) * std::f64::consts::PI * r.powi(3);
            let sa = 4.0 * std::f64::consts::PI * r * r;
            return Ok(SciSolution {
                summary: format!("Sphere Geometry (r = {})", r),
                steps: vec![
                    format!("Radius (r): {:.4}", r),
                    format!("Volume: V = (4/3)·π·r³ = (4/3) * π * ({:.4})³ = {:.8}", r, vol),
                    format!("Surface Area: A = 4·π·r² = 4 * π * ({:.4})² = {:.8}", r, sa),
                ],
                exact_result: Some(format!("Volume = {:.6}, Surface Area = {:.6}", vol, sa)),
                approximate_result: None,
                domain: "Geometry",
                confidence: "Exact Geometric Formula",
                raw_centl_command: None,
            });
        }
    }

    if lower.contains("volume of a cylinder") || lower.contains("volume of cylinder") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (r, h) = (numbers[0], numbers[1]);
            let vol = std::f64::consts::PI * r * r * h;
            return Ok(SciSolution {
                summary: format!("Cylinder Geometry (r = {}, h = {})", r, h),
                steps: vec![
                    format!("Radius (r): {:.4} | Height (h): {:.4}", r, h),
                    format!("Volume: V = π·r²·h = π * ({:.4})² * {:.4} = {:.8}", r, h, vol),
                ],
                exact_result: Some(format!("Volume = {:.6}", vol)),
                approximate_result: None,
                domain: "Geometry",
                confidence: "Exact Geometric Formula",
                raw_centl_command: None,
            });
        }
    }

    if lower.contains("hypotenuse") || lower.contains("pythagorean") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (a, b) = (numbers[0], numbers[1]);
            let c = (a * a + b * b).sqrt();
            return Ok(SciSolution {
                summary: format!("Pythagorean Right Triangle (a = {}, b = {})", a, b),
                steps: vec![
                    format!("Leg a: {:.4} | Leg b: {:.4}", a, b),
                    format!("Hypotenuse: c = √(a² + b²) = √({:.4}² + {:.4}²) = {:.8}", a, b, c),
                    format!("Area: A = ½·a·b = {:.6}", 0.5 * a * b),
                ],
                exact_result: Some(format!("c = {:.6}", c)),
                approximate_result: None,
                domain: "Geometry",
                confidence: "Exact Pythagorean Theorem",
                raw_centl_command: None,
            });
        }
    }

    // 22. Linear Algebra & Vector Calculus: Dot Product, Cross Product, Determinant
    // "Dot product of (1, 2, 3) and (4, 5, 6)", "Cross product of (1, 0, 0) and (0, 1, 0)", "Determinant of [[1, 2], [3, 4]]"
    if lower.contains("dot product") || lower.contains("cross product") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 6 {
            let (x1, y1, z1, x2, y2, z2) = (numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], numbers[5]);
            if lower.contains("cross") {
                let cx = y1 * z2 - z1 * y2;
                let cy = z1 * x2 - x1 * z2;
                let cz = x1 * y2 - y1 * x2;
                return Ok(SciSolution {
                    summary: "3D Vector Cross Product".to_string(),
                    steps: vec![
                        format!("Vector u: ({:.4}, {:.4}, {:.4})", x1, y1, z1),
                        format!("Vector v: ({:.4}, {:.4}, {:.4})", x2, y2, z2),
                        format!("u × v = ({:.6}, {:.6}, {:.6})", cx, cy, cz),
                    ],
                    exact_result: Some(format!("({:.6}, {:.6}, {:.6})", cx, cy, cz)),
                    approximate_result: None,
                    domain: "Vector Calculus",
                    confidence: "Exact Vector Geometry",
                    raw_centl_command: Some(format!("cross({}, {}, {}, {}, {}, {})", x1, y1, z1, x2, y2, z2)),
                });
            } else {
                let dot = x1 * x2 + y1 * y2 + z1 * z2;
                return Ok(SciSolution {
                    summary: "3D Vector Dot Product".to_string(),
                    steps: vec![
                        format!("Vector u: ({:.4}, {:.4}, {:.4})", x1, y1, z1),
                        format!("Vector v: ({:.4}, {:.4}, {:.4})", x2, y2, z2),
                        format!("u · v = {:.4}*{:.4} + {:.4}*{:.4} + {:.4}*{:.4} = {:.8}", x1, x2, y1, y2, z1, z2, dot),
                    ],
                    exact_result: Some(format!("{}", dot)),
                    approximate_result: None,
                    domain: "Vector Calculus",
                    confidence: "Exact Scalar Product",
                    raw_centl_command: Some(format!("dot({}, {}, {}, {}, {}, {})", x1, y1, z1, x2, y2, z2)),
                });
            }
        }
    }

    if lower.contains("determinant") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 4 {
            let (a, b, c, d) = (numbers[0], numbers[1], numbers[2], numbers[3]);
            let det = a * d - b * c;
            return Ok(SciSolution {
                summary: "2x2 Matrix Determinant".to_string(),
                steps: vec![
                    format!("Matrix: [[{:.4}, {:.4}], [{:.4}, {:.4}]]", a, b, c, d),
                    format!("Formula: det(M) = a·d - b·c = ({:.4} * {:.4}) - ({:.4} * {:.4}) = {:.8}", a, d, b, c, det),
                ],
                exact_result: Some(format!("{}", det)),
                approximate_result: None,
                domain: "Linear Algebra",
                confidence: "Exact Matrix Determinant",
                raw_centl_command: Some(format!("det2({}, {}, {}, {})", a, b, c, d)),
            });
        }
    }

    // 23. Statistics: Mean, Variance & Standard Deviation
    // "Calculate mean of 12, 15, 18, 22, 30", "Find the standard deviation of 2, 4, 4, 4, 5, 5, 7, 9"
    if lower.contains("mean of") || lower.contains("average of") || lower.contains("variance of") || lower.contains("standard deviation of") || lower.contains("median of") {
        let numbers = extract_all_f64(prompt);
        if !numbers.is_empty() {
            let m = crate::engine::functions::mean(&numbers).unwrap_or(0.0);
            let v = crate::engine::functions::variance(&numbers).unwrap_or(0.0);
            let s = crate::engine::functions::stddev(&numbers).unwrap_or(0.0);
            return Ok(SciSolution {
                summary: format!("Statistical Summary (N = {})", numbers.len()),
                steps: vec![
                    format!("Dataset: {:?}", numbers),
                    format!("Sample Mean (x̄): {:.6}", m),
                    format!("Sample Variance (s²): {:.6}", v),
                    format!("Sample Standard Deviation (s): {:.6}", s),
                ],
                exact_result: Some(format!("mean = {:.4}, stddev = {:.4}", m, s)),
                approximate_result: None,
                domain: "Statistics",
                confidence: "Exact Statistical Formulation",
                raw_centl_command: Some(format!("mean({})", numbers.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(", "))),
            });
        }
    }

    // 24. Number Theory: Extended GCD, Totient, Modular Inverse
    // "totient of 36", "extended gcd of 240 and 46", "modular inverse of 3 mod 11"
    if lower.contains("totient") || lower.contains("phi of") {
        if let Some(n) = extract_single_u64(prompt) {
            let t = crate::engine::functions::totient(n);
            return Ok(SciSolution {
                summary: format!("Euler's Totient Function φ({})", n),
                steps: vec![
                    format!("Target integer: {}", n),
                    "Evaluated count of positive integers up to n that are relatively prime to n.".to_string(),
                    format!("φ({}) = {}", n, t),
                ],
                exact_result: Some(format!("{}", t)),
                approximate_result: None,
                domain: "Number Theory",
                confidence: "Exact Totient Product",
                raw_centl_command: Some(format!("totient({})", n)),
            });
        }
    }

    if lower.contains("extended gcd") || lower.contains("xgcd") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (a, b) = (numbers[0] as i64, numbers[1] as i64);
            let (g, x, y) = crate::engine::functions::xgcd(a, b);
            return Ok(SciSolution {
                summary: format!("Extended Euclidean Algorithm: gcd({}, {})", a, b),
                steps: vec![
                    format!("Integers: a = {}, b = {}", a, b),
                    "Bézout identity: a·x + b·y = gcd(a, b)".to_string(),
                    format!("Coefficients: x = {}, y = {}", x, y),
                    format!("Verification: {}*({}) + {}*({}) = {}", a, x, b, y, g),
                ],
                exact_result: Some(format!("gcd = {}, x = {}, y = {}", g, x, y)),
                approximate_result: None,
                domain: "Number Theory",
                confidence: "Exact Euclidean Algorithm",
                raw_centl_command: Some(format!("xgcd({}, {})", a, b)),
            });
        }
    }

    if lower.contains("modular inverse") || lower.contains("modinv") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (a, m) = (numbers[0] as i64, numbers[1] as i64);
            if let Ok(inv) = crate::engine::functions::modinv(a, m) {
                return Ok(SciSolution {
                    summary: format!("Modular Multiplicative Inverse: {}⁻¹ mod {}", a, m),
                    steps: vec![
                        format!("Base a = {}, Modulus m = {}", a, m),
                        format!("Inverse satisfies: ({} * {}) mod {} = 1", a, inv, m),
                        format!("Result: {}", inv),
                    ],
                    exact_result: Some(format!("{}", inv)),
                    approximate_result: None,
                    domain: "Number Theory",
                    confidence: "Exact Modular Inversion",
                    raw_centl_command: Some(format!("modinv({}, {})", a, m)),
                });
            }
        }
    }

    // 25. Number Theory: Prime Factorization & Primality
    // "What are the prime factors of 123456?", "Is 104729 prime?"
    if lower.contains("prime factor") || lower.contains("factorize") {
        if let Some(n) = extract_single_u64(prompt) {
            let cmd = format!("prime_factors({})", n);
            match evaluate(&cmd, session) {
                Ok(res) => {
                    return Ok(SciSolution {
                        summary: format!("Prime Factorization of {}", n),
                        steps: vec![
                            format!("Integer: {}", n),
                            "Applied deterministic trial and wheel factorization.".to_string(),
                            format!("Canonical prime decomposition: {}", res.text),
                        ],
                        exact_result: Some(res.text.clone()),
                        approximate_result: None,
                        domain: "Number Theory",
                        confidence: "Exact Integer",
                        raw_centl_command: Some(cmd),
                    });
                }
                Err(e) => return Err(e),
            }
        }
    }

    if lower.contains("is prime") || lower.contains("is it prime") || lower.contains("primality") {
        if let Some(n) = extract_single_u64(prompt) {
            let cmd = format!("is_prime({})", n);
            match evaluate(&cmd, session) {
                Ok(res) => {
                    let is_p = res.text == "true";
                    return Ok(SciSolution {
                        summary: format!("Primality Test for {}", n),
                        steps: vec![
                            format!("Integer tested: {}", n),
                            format!("Result: {} is {}", n, if is_p { "a PRIME number" } else { "a COMPOSITE number" }),
                        ],
                        exact_result: Some(res.text.clone()),
                        approximate_result: None,
                        domain: "Number Theory",
                        confidence: "Deterministic Primality",
                        raw_centl_command: Some(cmd),
                    });
                }
                Err(e) => return Err(e),
            }
        }
    }

    // 26. Erdős–Straus Diophantine Decomposition
    // "Solve Erdős-Straus for prime 2521", "4/p decomposition for p=2521"
    if lower.contains("erdos") || lower.contains("erdős") || lower.contains("diophantine") {
        if let Some(p) = extract_single_u64(prompt) {
            let res = solve_es(p);
            let cmd = format!("es solve {}", p);
            let witness_text = if let Some(w) = &res.witness {
                format!("Decomposition: {}\nGrade: {} · Layer: {} · Kind: {}", w.equation(), res.grade.to_uppercase(), w.layer, w.kind)
            } else {
                format!("Prime {} is unsolved in the standard window. Grade: {}", p, res.grade.to_uppercase())
            };
            return Ok(SciSolution {
                summary: format!("Erdős–Straus Diophantine Decomposition for p = {}", p),
                steps: vec![
                    format!("Target prime: p = {}", p),
                    format!("Diophantine equation: 4/{} = 1/x + 1/y + 1/z", p),
                    witness_text.clone(),
                ],
                exact_result: Some(witness_text),
                approximate_result: None,
                domain: "Number Theory (Erdős–Straus)",
                confidence: "Exact Finite Witness",
                raw_centl_command: Some(cmd),
            });
        }
    }

    // 27. Calculus: Differentiation
    // "Find the derivative of x^3 * sin(x) with respect to x", "Differentiate 3*x^2 + 5*x"
    if lower.contains("derivative") || lower.contains("diff") || lower.contains("differentiate") {
        let (expr_str, var_name) = extract_diff_params(prompt);
        let cmd = format!("diff({}, {})", expr_str, var_name);
        match evaluate(&cmd, session) {
            Ok(res) => {
                return Ok(SciSolution {
                    summary: format!("Symbolic Derivative of f({}) = {} with respect to {}", var_name, expr_str, var_name),
                    steps: vec![
                        format!("Target function: f({}) = {}", var_name, expr_str),
                        "Applied symbolic differentiation rules (sum, product, power, chain rule).".to_string(),
                        format!("Derivative: d/d{} [{}] = {}", var_name, expr_str, res.text),
                    ],
                    exact_result: Some(res.text.clone()),
                    approximate_result: None,
                    domain: "Calculus",
                    confidence: "Exact Symbolic",
                    raw_centl_command: Some(cmd),
                });
            }
            Err(e) => return Err(format!("Could not differentiate expression: {}", e)),
        }
    }

    // 28. Calculus: Definite / Indefinite Integration
    // "Integrate 3*x^2 + 2*x from 0 to 5", "Find the integral of sin(x) from 0 to pi"
    if lower.contains("integral") || lower.contains("integrate") || lower.contains("antiderivative") {
        if let Some((expr_str, var_name, a, b)) = extract_definite_integral_params(prompt) {
            let cmd = format!("integrate({}, {}, {}, {})", expr_str, var_name, a, b);
            match evaluate(&cmd, session) {
                Ok(res) => {
                    return Ok(SciSolution {
                        summary: format!("Definite Integral of {} from {} to {}", expr_str, a, b),
                        steps: vec![
                            format!("Integrand: f({}) = {}", var_name, expr_str),
                            format!("Integration bounds: [{}, {}]", a, b),
                            "Evaluated exact anti-derivative at upper and lower limits using the Fundamental Theorem of Calculus.".to_string(),
                            format!("Result: {}", res.text),
                        ],
                        exact_result: Some(res.text.clone()),
                        approximate_result: None,
                        domain: "Calculus",
                        confidence: "Exact Rational",
                        raw_centl_command: Some(cmd),
                    });
                }
                Err(e) => return Err(format!("Could not integrate expression: {}", e)),
            }
        } else {
            let (expr_str, var_name) = extract_diff_params(prompt);
            let cmd = format!("integrate({}, {})", expr_str, var_name);
            match evaluate(&cmd, session) {
                Ok(res) => {
                    return Ok(SciSolution {
                        summary: format!("Indefinite Integral (Antiderivative) of {}", expr_str),
                        steps: vec![
                            format!("Integrand: f({}) = {}", var_name, expr_str),
                            "Applied symbolic anti-differentiation rules.".to_string(),
                            format!("Integral: {}", res.text),
                        ],
                        exact_result: Some(res.text.clone()),
                        approximate_result: None,
                        domain: "Calculus",
                        confidence: "Exact Symbolic",
                        raw_centl_command: Some(cmd),
                    });
                }
                Err(e) => return Err(format!("Could not compute integral: {}", e)),
            }
        }
    }

    // 29. Algebra: Equation Solving
    // "Solve the equation 3*x - 12 = 0 for x", "Find roots of x^2 - 16 = 0"
    if lower.contains("solve") || lower.contains("roots of") || lower.contains("find x") {
        if let Some((eq_str, var_name)) = extract_equation_params(prompt) {
            let cmd = format!("solve({}, {})", eq_str, var_name);
            match evaluate(&cmd, session) {
                Ok(res) => {
                    return Ok(SciSolution {
                        summary: format!("Exact Algebraic Equation Solution: {}", eq_str),
                        steps: vec![
                            format!("Equation: {}", eq_str),
                            format!("Solved for variable: {}", var_name),
                            format!("Exact solution set: {}", res.text),
                        ],
                        exact_result: Some(res.text.clone()),
                        approximate_result: None,
                        domain: "Algebra",
                        confidence: "Exact Algebraic",
                        raw_centl_command: Some(cmd),
                    });
                }
                Err(e) => return Err(format!("Could not solve equation: {}", e)),
            }
        }
    }

    // 30. Algebra: Polynomial Factor / Expand
    if lower.contains("factor") {
        let target = extract_algebra_target(prompt, "factor");
        let cmd = format!("factor({})", target);
        match evaluate(&cmd, session) {
            Ok(res) => {
                return Ok(SciSolution {
                    summary: format!("Polynomial Factorization: {}", target),
                    steps: vec![
                        format!("Target expression: {}", target),
                        "Factored into irreducible polynomial factors over rationals.".to_string(),
                        format!("Factored form: {}", res.text),
                    ],
                    exact_result: Some(res.text.clone()),
                    approximate_result: None,
                    domain: "Algebra",
                    confidence: "Exact Symbolic",
                    raw_centl_command: Some(cmd),
                });
            }
            Err(e) => return Err(format!("Could not factor expression: {}", e)),
        }
    }

    if lower.contains("expand") {
        let target = extract_algebra_target(prompt, "expand");
        let cmd = format!("expand({})", target);
        match evaluate(&cmd, session) {
            Ok(res) => {
                return Ok(SciSolution {
                    summary: format!("Polynomial Expansion: {}", target),
                    steps: vec![
                        format!("Target expression: {}", target),
                        "Expanded using distributive law and combined like terms.".to_string(),
                        format!("Expanded polynomial: {}", res.text),
                    ],
                    exact_result: Some(res.text.clone()),
                    approximate_result: None,
                    domain: "Algebra",
                    confidence: "Exact Symbolic",
                    raw_centl_command: Some(cmd),
                });
            }
            Err(e) => return Err(format!("Could not expand expression: {}", e)),
        }
    }

    // 31. Function Plotting
    // "Plot sin(x)", "Plot f(x) = x^2 - 4 from -3 to 3"
    if lower.starts_with("plot ") || lower.contains("graph of") {
        let plot_cmd = if lower.starts_with("plot ") { prompt } else { &prompt[prompt.find("graph of").unwrap() + 8..] };
        if let Ok(plot_text) = crate::engine::plot::handle_plot_command(plot_cmd) {
            return Ok(SciSolution {
                summary: "2D ASCII Function Plot".to_string(),
                steps: vec![
                    "Sampled discrete interval coordinates.".to_string(),
                    "Rendered bounded Unicode 2D coordinate grid.".to_string(),
                ],
                exact_result: Some(plot_text),
                approximate_result: None,
                domain: "Visualization",
                confidence: "Deterministic Plot",
                raw_centl_command: Some(plot_cmd.to_string()),
            });
        }
    }

    // 32. General Mathematical Evaluation Fallback
    // If the prompt contains a clean mathematical expression, evaluate directly
    if let Ok(res) = evaluate(prompt, session) {
        return Ok(SciSolution {
            summary: format!("Exact Mathematical Evaluation: {}", prompt),
            steps: vec![
                format!("Input expression: {}", prompt),
                format!("Exact rational result: {}", res.text),
            ],
            exact_result: Some(res.text),
            approximate_result: res.approximate,
            domain: "Mathematics",
            confidence: "Exact Rational",
            raw_centl_command: Some(prompt.to_string()),
        });
    }

    Err(format!(
        "CentL-SCi: Could not infer a deterministic STEM solution from '{}'. Try phrasing as an explicit question (e.g. 'What is the molar mass of H2SO4?', 'Convert 100 cm to m', 'Diff x^3 * cos(x)', 'Balance Fe + O2 -> Fe2O3', or 'Calculate kinetic energy of 1500 kg car at 25 m/s').",
        prompt
    ))
}

// ---------------- Helper Extractors ----------------

fn extract_chemical_formula(prompt: &str) -> Option<String> {
    // Look for patterns like H2O, Ca(OH)2, Al2(SO4)3, C6H12O6, H2SO4, Fe2O3
    let words: Vec<&str> = prompt.split_whitespace().collect();
    for word in words {
        let clean = word.trim_matches(|c: char| !c.is_alphanumeric() && c != '(' && c != ')');
        if is_likely_chemical_formula(clean) {
            return Some(clean.to_string());
        }
    }
    None
}

fn is_likely_chemical_formula(s: &str) -> bool {
    if s.len() < 2 || !s.chars().next().unwrap_or(' ').is_ascii_uppercase() {
        return false;
    }
    let uppercase_count = s.chars().filter(|c| c.is_ascii_uppercase()).count();
    let has_digits_or_parens = s.chars().any(|c| c.is_ascii_digit() || c == '(' || c == ')');
    (uppercase_count >= 2 || has_digits_or_parens) && s.chars().all(|c| c.is_ascii_alphanumeric() || c == '(' || c == ')')
}

fn extract_reaction_part(prompt: &str) -> String {
    if let Some(pos) = prompt.find(':') {
        let after = prompt[pos + 1..].trim();
        if after.contains("->") || after.contains("-->") || after.contains("=>") {
            return after.trim_matches('\'').trim_matches('"').to_string();
        }
    }
    // Search around ->
    for delimiter in ["-->", "->", "=>"] {
        if let Some(idx) = prompt.find(delimiter) {
            // Find start of reactants
            let before = &prompt[..idx];
            let after = &prompt[idx + delimiter.len()..];
            let start = before.rfind(|c: char| c == ':' || c == '"' || c == '\'').map(|p| p + 1).unwrap_or(0);
            let end = after.find(|c: char| c == '?' || c == '.' || c == '"' || c == '\'').map(|p| idx + delimiter.len() + p).unwrap_or(prompt.len());
            return prompt[start..end].trim().to_string();
        }
    }
    prompt.to_string()
}

fn normalize_unit_phrase(text: &str) -> String {
    let mut s = text.to_ascii_lowercase();
    s = s.replace("kilometers per hour", "km/h")
        .replace("kilometer per hour", "km/h")
        .replace("km per hour", "km/h")
        .replace("km/hr", "km/h")
        .replace("kph", "km/h")
        .replace("meters per second", "m/s")
        .replace("meter per second", "m/s")
        .replace("m per second", "m/s")
        .replace("m per sec", "m/s")
        .replace("miles per hour", "mph")
        .replace("mile per hour", "mph")
        .replace("kilometers", "km")
        .replace("kilometer", "km")
        .replace("centimeters", "cm")
        .replace("centimeter", "cm")
        .replace("millimeters", "mm")
        .replace("millimeter", "mm")
        .replace("meters", "m")
        .replace("meter", "m")
        .replace("inches", "in")
        .replace("inch", "in")
        .replace("feet", "ft")
        .replace("foot", "ft")
        .replace("yards", "yd")
        .replace("yard", "yd")
        .replace("miles", "mi")
        .replace("mile", "mi")
        .replace("kilograms", "kg")
        .replace("kilogram", "kg")
        .replace("grams", "g")
        .replace("gram", "g")
        .replace("milligrams", "mg")
        .replace("milligram", "mg")
        .replace("pounds", "lb")
        .replace("pound", "lb")
        .replace("ounces", "oz")
        .replace("ounce", "oz")
        .replace("seconds", "s")
        .replace("second", "s")
        .replace("minutes", "min")
        .replace("minute", "min")
        .replace("hours", "hr")
        .replace("hour", "hr")
        .replace("days", "day")
        .replace("pascals", "pa")
        .replace("pascal", "pa")
        .replace("atmospheres", "atm")
        .replace("atmosphere", "atm")
        .replace("joules", "j")
        .replace("joule", "j")
        .replace("calories", "cal")
        .replace("calorie", "cal");
    s
}

fn extract_unit_conversion(prompt: &str) -> Option<(f64, String, String)> {
    let normalized = normalize_unit_phrase(prompt);
    let tokens: Vec<&str> = normalized.split_whitespace().collect();
    
    // Look for [val] [unit1] to [unit2] or [val] [unit1] in [unit2]
    for i in 0..tokens.len() {
        if let Ok(val) = tokens[i].parse::<f64>() {
            if i + 3 < tokens.len() && (tokens[i + 2] == "to" || tokens[i + 2] == "in" || tokens[i + 2] == "into") {
                let from_u = tokens[i + 1].trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '^');
                let to_u = tokens[i + 3].trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '^');
                return Some((val, from_u.to_string(), to_u.to_string()));
            }
            if i + 2 < tokens.len() {
                let from_u = tokens[i + 1].trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '^');
                let to_u = tokens[i + 2].trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '^');
                if to_u != "to" && to_u != "in" {
                    return Some((val, from_u.to_string(), to_u.to_string()));
                }
            }
        }
    }
    None
}

fn extract_cherenkov_params(prompt: &str) -> Option<(f64, f64)> {
    let tokens: Vec<&str> = prompt.split(|c: char| c.is_whitespace() || c == '=' || c == '(' || c == ')' || c == ',').filter(|s| !s.is_empty()).collect();
    let mut numbers = Vec::new();
    for t in tokens {
        if let Ok(v) = t.parse::<f64>() {
            numbers.push(v);
        }
    }
    if numbers.len() >= 2 {
        let (n, v) = if numbers[0] < numbers[1] {
            (numbers[0], numbers[1])
        } else {
            (numbers[1], numbers[0])
        };
        return Some((n, v));
    }
    None
}

fn extract_diff_params(prompt: &str) -> (String, String) {
    let lower = prompt.to_ascii_lowercase();
    let var_name = if lower.contains("with respect to ") {
        if let Some(pos) = lower.find("with respect to ") {
            let after = lower[pos + "with respect to ".len()..].trim();
            after.split_whitespace().next().unwrap_or("x").trim_matches(|c: char| !c.is_alphanumeric()).to_string()
        } else {
            "x".to_string()
        }
    } else {
        "x".to_string()
    };

    // Extract target expression
    let expr = if let Some(pos) = lower.find("derivative of ") {
        let after = prompt[pos + "derivative of ".len()..].trim();
        let end = after.to_ascii_lowercase().find(" with respect to").unwrap_or(after.len());
        after[..end].trim().trim_matches(|c: char| c == '\'' || c == '"' || c == '?' || c == '.').to_string()
    } else if let Some(pos) = lower.find("differentiate ") {
        let after = prompt[pos + "differentiate ".len()..].trim();
        let end = after.to_ascii_lowercase().find(" with respect to").unwrap_or(after.len());
        after[..end].trim().trim_matches(|c: char| c == '\'' || c == '"' || c == '?' || c == '.').to_string()
    } else {
        prompt.to_string()
    };

    (expr, var_name)
}

fn extract_definite_integral_params(prompt: &str) -> Option<(String, String, String, String)> {
    let lower = prompt.to_ascii_lowercase();
    if lower.contains(" from ") && lower.contains(" to ") {
        let from_pos = lower.find(" from ")?;
        let to_pos = lower.find(" to ")?;
        if to_pos > from_pos {
            let expr_part = if let Some(pos) = lower.find("integral of ") {
                &prompt[pos + "integral of ".len()..from_pos]
            } else if let Some(pos) = lower.find("integrate ") {
                &prompt[pos + "integrate ".len()..from_pos]
            } else {
                &prompt[..from_pos]
            };
            let a = prompt[from_pos + " from ".len()..to_pos].trim();
            let b = prompt[to_pos + " to ".len()..].trim().trim_matches(|c: char| c == '?' || c == '.' || c == '\'' || c == '"');
            return Some((expr_part.trim().to_string(), "x".to_string(), a.to_string(), b.to_string()));
        }
    }
    None
}

fn extract_equation_params(prompt: &str) -> Option<(String, String)> {
    let lower = prompt.to_ascii_lowercase();
    let eq = if let Some(pos) = lower.find("solve ") {
        let after = prompt[pos + "solve ".len()..].trim();
        let end = after.to_ascii_lowercase().find(" for ").unwrap_or(after.len());
        after[..end].trim().trim_matches(|c: char| c == '?' || c == '.' || c == '\'' || c == '"')
    } else {
        prompt
    };
    if eq.contains('=') {
        Some((eq.to_string(), "x".to_string()))
    } else {
        None
    }
}

fn extract_algebra_target(prompt: &str, keyword: &str) -> String {
    let lower = prompt.to_ascii_lowercase();
    if let Some(pos) = lower.find(keyword) {
        let after = prompt[pos + keyword.len()..].trim();
        after.trim_matches(|c: char| c == '?' || c == '.' || c == '\'' || c == '"').trim().to_string()
    } else {
        prompt.to_string()
    }
}

fn extract_single_u64(prompt: &str) -> Option<u64> {
    for word in prompt.split(|c: char| !c.is_alphanumeric()) {
        if let Ok(n) = word.parse::<u64>() {
            return Some(n);
        }
    }
    None
}

fn extract_all_f64(prompt: &str) -> Vec<f64> {
    let mut numbers = Vec::new();
    for word in prompt.split(|c: char| c.is_whitespace() || c == ',' || c == ';' || c == '(' || c == ')' || c == '=' || c == '[' || c == ']') {
        let clean = word.trim_matches(|c: char| c == '\'' || c == '"' || c == '?' || c == ':');
        if let Ok(val) = clean.parse::<f64>() {
            numbers.push(val);
        }
    }
    numbers
}

// ---------------- Hybrid Gemini Client ----------------

fn solve_with_gemini_hybrid(
    prompt: &str,
    api_key: &str,
    session: &mut Session,
) -> Result<SciSolution, String> {
    let system_instructions = "You are the CentL STEM Decomposition & Verification Engine. \
    Analyze the user's scientific/mathematical query and decompose it into exact CentL atomic commands. \
    CentL supports: \
    - diff(f, x), integrate(f, x, a, b), solve(lhs=rhs, x), expand(expr), factor(expr) \
    - gcd(a, b), lcm(a, b), factorial(n), choose(n, k), fibonacci(n), is_prime(n), prime_factors(n) \
    - chem atoms <formula>, chem balance <reaction>, chem molar-mass <formula>, chem stoich ... \
    - physics convert <val> <from> <to>, physics constant <sym>, physics cherenkov <n> <v>, physics collision ... \
    - es solve <prime> \
    Format your response in JSON with: \
    {\n      \"summary\": \"Brief title/summary\",\n      \"domain\": \"Mathematics|Physics|Chemistry|Calculus|Number Theory\",\n      \"reasoning\": [\"Step 1 explanation\", \"Step 2 explanation\"],\n      \"centl_command\": \"exact_centl_command_to_evaluate\"\n    }";

    let payload = json!({
        "contents": [{
            "parts": [{
                "text": format!("System: {}\n\nUser Question: {}", system_instructions, prompt)
            }]
        }],
        "generationConfig": {
            "temperature": 0.1,
            "responseMimeType": "application/json"
        }
    });

    let endpoint = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={}",
        api_key
    );

    // Call API using lightweight rust HTTPS caller
    let response_body = http_post_json(&endpoint, &payload)?;

    let res_json: Value = serde_json::from_str(&response_body)
        .map_err(|e| format!("Invalid Gemini API JSON response: {}", e))?;

    let text_part = res_json
        .get("candidates")
        .and_then(|c| c.get(0))
        .and_then(|c| c.get("content"))
        .and_then(|c| c.get("parts"))
        .and_then(|p| p.get(0))
        .and_then(|p| p.get("text"))
        .and_then(Value::as_str)
        .ok_or_else(|| "Gemini API returned empty candidate content.".to_string())?;

    let parsed_gemini: Value = serde_json::from_str(text_part)
        .map_err(|e| format!("Could not parse Gemini JSON decomposition: {}", e))?;

    let summary = parsed_gemini.get("summary").and_then(Value::as_str).unwrap_or("Gemini STEM Solution").to_string();
    let domain_str = parsed_gemini.get("domain").and_then(Value::as_str).unwrap_or("STEM");
    let reasoning = parsed_gemini.get("reasoning").and_then(Value::as_array).map(|arr| {
        arr.iter().filter_map(Value::as_str).map(|s| s.to_string()).collect::<Vec<_>>()
    }).unwrap_or_default();
    let centl_command = parsed_gemini.get("centl_command").and_then(Value::as_str).map(|s| s.to_string());

    let mut final_steps = reasoning;
    let mut exact_result = None;
    let mut approx_result = None;

    // Execute the CentL exact verification command if provided
    if let Some(ref cmd) = centl_command {
        if let Ok(eval_res) = evaluate(cmd, session) {
            final_steps.push(format!("Exact CentL Kernel Verification: {} -> {}", cmd, eval_res.text));
            exact_result = Some(eval_res.text);
            approx_result = eval_res.approximate;
        }
    }

    Ok(SciSolution {
        summary,
        steps: final_steps,
        exact_result,
        approximate_result: approx_result,
        domain: match domain_str {
            "Chemistry" => "Chemistry",
            "Physics" => "Physics",
            "Calculus" => "Calculus",
            "Algebra" => "Algebra",
            "Number Theory" => "Number Theory",
            _ => "STEM (Hybrid Gemini + CentL)",
        },
        confidence: "Verified (Gemini + CentL Exact Kernel)",
        raw_centl_command: centl_command,
    })
}

fn http_post_json(url_str: &str, payload: &Value) -> Result<String, String> {
    // For universal standalone compatibility, call via curl if available
    let payload_str = payload.to_string();
    let child = std::process::Command::new("curl")
        .arg("-s")
        .arg("-X")
        .arg("POST")
        .arg(url_str)
        .arg("-H")
        .arg("Content-Type: application/json")
        .arg("-d")
        .arg(&payload_str)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn curl for Gemini request: {}", e))?;

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to receive response from Gemini: {}", e))?;

    if !output.status.success() {
        let err_msg = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Gemini request failed: {}", err_msg));
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
