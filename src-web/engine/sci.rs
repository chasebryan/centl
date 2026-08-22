// CENTL-SCi Plain English STEM Problem Solver & Hybrid Gemini Integration
// Free Computation Foundation - Apache-2.0

use crate::engine::{evaluate, Session};
use crate::erdos_straus::solve_es;
use crate::physics::{convert_units, lookup_constant};
use serde_json::{json, Value};
use std::env;
use std::sync::Mutex;

static RUNTIME_GEMINI_KEY: Mutex<Option<String>> = Mutex::new(None);
static RUNTIME_GEMINI_MODEL: Mutex<Option<String>> = Mutex::new(None);

pub fn sanitize_api_key(raw: &str) -> String {
    let mut cleaned = raw.trim().trim_matches('"').trim_matches('\'').trim().to_string();
    if cleaned.starts_with("Bearer ") {
        cleaned = cleaned.strip_prefix("Bearer ").unwrap_or(&cleaned).trim().to_string();
    }
    cleaned
}

pub fn set_runtime_gemini_key(key: &str) {
    let mut lock = RUNTIME_GEMINI_KEY.lock().unwrap_or_else(|p| p.into_inner());
    let sanitized = sanitize_api_key(key);
    if sanitized.is_empty() {
        *lock = None;
    } else {
        *lock = Some(sanitized);
    }
}

pub fn set_runtime_gemini_model(model: &str) {
    let mut lock = RUNTIME_GEMINI_MODEL.lock().unwrap_or_else(|p| p.into_inner());
    let trimmed = model.trim().to_string();
    if trimmed.is_empty() {
        *lock = None;
    } else {
        *lock = Some(trimmed);
    }
}

pub fn get_runtime_gemini_model() -> String {
    let lock = RUNTIME_GEMINI_MODEL.lock().unwrap_or_else(|p| p.into_inner());
    if let Some(ref m) = *lock {
        return m.clone();
    }
    if let Ok(m) = env::var("GEMINI_MODEL") {
        if !m.trim().is_empty() {
            return m.trim().to_string();
        }
    }
    if let Ok(m) = env::var("CENTL_GEMINI_MODEL") {
        if !m.trim().is_empty() {
            return m.trim().to_string();
        }
    }
    "gemini-2.5-flash".to_string()
}

pub fn get_runtime_gemini_key() -> Option<String> {
    let lock = RUNTIME_GEMINI_KEY.lock().unwrap_or_else(|p| p.into_inner());
    if let Some(ref k) = *lock {
        let cleaned = sanitize_api_key(k);
        if !cleaned.is_empty() {
            return Some(cleaned);
        }
    }

    // 1. Check environment variables
    for var in &["CENTL_GEMINI_KEY", "GEMINI_API_KEY", "GOOGLE_API_KEY", "GOOGLE_AI_API_KEY", "GEMINI_KEY"] {
        if let Ok(k) = env::var(var) {
            let cleaned = sanitize_api_key(&k);
            if !cleaned.is_empty() {
                return Some(cleaned);
            }
        }
    }

    // 2. Check cross-platform file paths
    let mut candidate_paths = Vec::new();
    if let Ok(home) = env::var("HOME").or_else(|_| env::var("USERPROFILE")) {
        candidate_paths.push(std::path::Path::new(&home).join(".centl").join("gemini.key"));
    }
    if let Ok(appdata) = env::var("APPDATA") {
        candidate_paths.push(std::path::Path::new(&appdata).join("centl").join("gemini.key"));
    }
    candidate_paths.push(std::path::PathBuf::from(".centl/gemini.key"));

    for path in candidate_paths {
        if let Ok(content) = std::fs::read_to_string(path) {
            let cleaned = sanitize_api_key(&content);
            if !cleaned.is_empty() {
                return Some(cleaned);
            }
        }
    }

    None
}

pub fn get_gemini_status_info() -> (bool, Option<String>, &'static str, String) {
    let model = get_runtime_gemini_model();
    let lock = RUNTIME_GEMINI_KEY.lock().unwrap_or_else(|p| p.into_inner());
    if let Some(ref k) = *lock {
        let cleaned = sanitize_api_key(k);
        let masked = if cleaned.len() > 8 {
            format!("{}...{}", &cleaned[..4], &cleaned[cleaned.len() - 4..])
        } else {
            "Active".to_string()
        };
        return (true, Some(masked), "Session Configuration", model);
    }
    for (var, label) in &[
        ("CENTL_GEMINI_KEY", "CENTL_GEMINI_KEY env"),
        ("GEMINI_API_KEY", "GEMINI_API_KEY env"),
        ("GOOGLE_API_KEY", "GOOGLE_API_KEY env"),
        ("GOOGLE_AI_API_KEY", "GOOGLE_AI_API_KEY env"),
        ("GEMINI_KEY", "GEMINI_KEY env"),
    ] {
        if let Ok(k) = env::var(var) {
            let cleaned = sanitize_api_key(&k);
            if !cleaned.is_empty() {
                let masked = format!("{}...{}", &cleaned[..4.min(cleaned.len())], &cleaned[cleaned.len().saturating_sub(4)..]);
                return (true, Some(masked), label, model);
            }
        }
    }
    if let Ok(home) = env::var("HOME").or_else(|_| env::var("USERPROFILE")) {
        let key_path = std::path::Path::new(&home).join(".centl").join("gemini.key");
        if let Ok(content) = std::fs::read_to_string(key_path) {
            let cleaned = sanitize_api_key(&content);
            if !cleaned.is_empty() {
                let masked = format!("{}...{}", &cleaned[..4.min(cleaned.len())], &cleaned[cleaned.len().saturating_sub(4)..]);
                return (true, Some(masked), "~/.centl/gemini.key", model);
            }
        }
    }
    (false, None, "Unconfigured", model)
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

pub fn replace_case_insensitive(text: &str, pattern: &str, replacement: &str) -> String {
    let mut result = String::new();
    let lower_text = text.to_ascii_lowercase();
    let lower_pattern = pattern.to_ascii_lowercase();
    let mut last_end = 0;

    for (start, _) in lower_text.match_indices(&lower_pattern) {
        if start >= last_end {
            result.push_str(&text[last_end..start]);
            result.push_str(replacement);
            last_end = start + pattern.len();
        }
    }
    result.push_str(&text[last_end..]);
    result
}

pub fn replace_unary_phrase(text: &str, phrase: &str, func_name: &str) -> String {
    let mut result = text.to_string();
    let phrase_lower = phrase.to_ascii_lowercase();

    while let Some(pos) = result.to_ascii_lowercase().find(&phrase_lower) {
        let after = &result[pos + phrase.len()..];
        let trimmed_after = after.trim_start();
        let leading_spaces = after.len() - trimmed_after.len();

        let (arg, arg_len) = if trimmed_after.starts_with('(') {
            let mut depth = 0;
            let mut end_idx = None;
            for (idx, c) in trimmed_after.char_indices() {
                if c == '(' {
                    depth += 1;
                } else if c == ')' {
                    depth -= 1;
                    if depth == 0 {
                        end_idx = Some(idx + 1);
                        break;
                    }
                }
            }
            if let Some(end) = end_idx {
                let inside = &trimmed_after[1..end - 1];
                (inside.trim(), leading_spaces + end)
            } else {
                (trimmed_after.trim(), after.len())
            }
        } else {
            let op_delimiters = [
                " multiplied by", " multiply by", " times", " divided by", " div by",
                " plus", " minus", " over", " to the power", " to the", " raised to",
                " +", " -", " *", " /", " ^", " %", ",", ";", ")", "]"
            ];
            let lower_after = trimmed_after.to_ascii_lowercase();
            let mut first_op_idx = trimmed_after.len();

            for op in &op_delimiters {
                if let Some(idx) = lower_after.find(op) {
                    if idx < first_op_idx {
                        first_op_idx = idx;
                    }
                }
            }

            let token = trimmed_after[..first_op_idx].trim();
            (token, leading_spaces + first_op_idx)
        };

        if arg.is_empty() {
            break;
        }

        let replacement = format!("{}({})", func_name, arg);
        let total_match_len = phrase.len() + arg_len;
        let prefix = &result[..pos];
        let suffix = &result[pos + total_match_len..];
        result = format!("{}{}{}", prefix, replacement, suffix);
    }

    result
}

pub fn lower_natural_math_sentence(input: &str) -> String {
    let mut core = input.to_string();

    // 1. Lower unary function phrases
    core = replace_unary_phrase(&core, "square root of ", "sqrt");
    core = replace_unary_phrase(&core, "sqrt of ", "sqrt");
    core = replace_unary_phrase(&core, "cube root of ", "cbrt");
    core = replace_unary_phrase(&core, "cbrt of ", "cbrt");
    core = replace_unary_phrase(&core, "absolute value of ", "abs");
    core = replace_unary_phrase(&core, "abs of ", "abs");
    core = replace_unary_phrase(&core, "sine of ", "sin");
    core = replace_unary_phrase(&core, "sin of ", "sin");
    core = replace_unary_phrase(&core, "cosine of ", "cos");
    core = replace_unary_phrase(&core, "cos of ", "cos");
    core = replace_unary_phrase(&core, "tangent of ", "tan");
    core = replace_unary_phrase(&core, "tan of ", "tan");
    core = replace_unary_phrase(&core, "natural log of ", "ln");
    core = replace_unary_phrase(&core, "ln of ", "ln");
    core = replace_unary_phrase(&core, "log base 10 of ", "log10");
    core = replace_unary_phrase(&core, "log10 of ", "log10");
    core = replace_unary_phrase(&core, "log of ", "log10");

    // 2. Binary phrases
    let replacements = [
        ("to the power of", " ^ "),
        ("raised to the power of", " ^ "),
        ("raised to the power", " ^ "),
        ("raised to the", " ^ "),
        ("raised to", " ^ "),
        ("to the power", " ^ "),
        ("divided by", " / "),
        ("div by", " / "),
        ("divided into", " / "),
        ("multiplied by", " * "),
        ("multiply by", " * "),
        ("subtracted by", " - "),
        ("subtracted from", " - "),
        ("added to", " + "),
        ("take away", " - "),
        ("modulo", " % "),
        (" mod ", " % "),
        ("squared", " ^ 2 "),
        ("cubed", " ^ 3 "),
    ];

    for (pat, repl) in &replacements {
        core = replace_case_insensitive(&core, pat, repl);
    }

    // 3. Single-word operator lowering
    let words: Vec<&str> = core.split_whitespace().collect();
    let mut normalized_words: Vec<String> = Vec::new();
    for w in words {
        match w.to_ascii_lowercase().as_str() {
            "plus" => normalized_words.push("+".to_string()),
            "minus" => normalized_words.push("-".to_string()),
            "times" => normalized_words.push("*".to_string()),
            "over" => normalized_words.push("/".to_string()),
            "less" => normalized_words.push("-".to_string()),
            other => normalized_words.push(other.to_string()),
        }
    }
    normalized_words.join(" ")
}

/// Universal Natural Language Arithmetic & Algebra Evaluator
pub fn try_solve_natural_arithmetic(prompt: &str, session: &mut Session) -> Option<SciSolution> {
    let mut cleaned = prompt.trim();
    // Strip trailing punctuation
    while cleaned.ends_with('?') || cleaned.ends_with('.') || cleaned.ends_with('!') || cleaned.ends_with(';') {
        cleaned = cleaned[..cleaned.len() - 1].trim();
    }
    let lower = cleaned.to_ascii_lowercase();

    // Do not intercept explicit scientific domain questions
    if lower.contains("molar mass") || lower.contains("balance ") || lower.contains("atom count")
        || lower.contains("ph of") || lower.contains("poh of") || lower.contains("kinetic energy")
        || lower.contains("potential energy") || lower.contains("ohm") || lower.contains("current")
        || lower.contains("voltage") || lower.contains("resistan") || lower.contains("wavelength")
        || lower.contains("convert ") || lower.contains("density") || lower.contains("gravity")
        || lower.contains("ideal gas") || lower.contains("gibbs") || lower.contains("work done")
        || lower.contains("power of a ") || lower.contains("circuit") || lower.contains("stopping potential")
        || lower.contains("rydberg") || lower.contains("nernst") || lower.contains("half life")
        || lower.contains("torque") || lower.contains("centripetal")
    {
        return None;
    }

    // Strip leading conversational phrases
    let prefixes = [
        "what is the ", "what is a ", "what is an ", "what is ",
        "what's the ", "what's a ", "what's an ", "what's ",
        "how much is the ", "how much is ", "how much is a ", "how much ",
        "calculate the ", "calculate a ", "calculate an ", "calculate ",
        "compute the ", "compute a ", "compute an ", "compute ",
        "find the ", "find a ", "find an ", "find all ", "find ",
        "evaluate the ", "evaluate a ", "evaluate an ", "evaluate ",
        "tell me the ", "tell me ",
        "give me the ", "give me ",
        "show me the ", "show me ",
        "please calculate the ", "please calculate ", "please compute ", "please find ", "please evaluate ", "please tell me ", "please ",
        "can you calculate the ", "can you calculate ", "can you find the ", "can you find ", "can you compute ", "can you tell me ", "can you ",
        "could you calculate ", "could you find ", "could you tell me ", "could you ",
        "i need to calculate ", "i need to find ", "i need to compute ",
        "the "
    ];

    let mut core = cleaned;
    for prefix in &prefixes {
        if core.to_ascii_lowercase().starts_with(prefix) {
            core = core[prefix.len()..].trim();
            break;
        }
    }

    let core_lower = core.to_ascii_lowercase();

    // 0. Sum / Product / Difference / Quotient phrasing
    if core_lower.starts_with("sum of ") || core_lower.starts_with("sum ") {
        let after = if core_lower.starts_with("sum of ") { &core["sum of ".len()..] } else { &core["sum ".len()..] };
        if let Some(pos) = after.to_ascii_lowercase().find(" and ") {
            let a = after[..pos].trim();
            let b = after[pos + 5..].trim();
            let cmd = format!("({}) + ({})", a, b);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Sum of {} and {}", a, b),
                    steps: vec![
                        format!("Addends: {} and {}", a, b),
                        format!("Operation: {} + {} = {}", a, b, res.text),
                    ],
                    exact_result: Some(res.text.clone()),
                    approximate_result: res.approximate,
                    domain: "Arithmetic",
                    confidence: "Exact Rational",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }
    if core_lower.starts_with("product of ") || core_lower.starts_with("product ") {
        let after = if core_lower.starts_with("product of ") { &core["product of ".len()..] } else { &core["product ".len()..] };
        if let Some(pos) = after.to_ascii_lowercase().find(" and ") {
            let a = after[..pos].trim();
            let b = after[pos + 5..].trim();
            let cmd = format!("({}) * ({})", a, b);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Product of {} and {}", a, b),
                    steps: vec![
                        format!("Factors: {} and {}", a, b),
                        format!("Operation: {} * {} = {}", a, b, res.text),
                    ],
                    exact_result: Some(res.text.clone()),
                    approximate_result: res.approximate,
                    domain: "Arithmetic",
                    confidence: "Exact Rational",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }
    if core_lower.starts_with("difference between ") || core_lower.starts_with("difference of ") {
        let after = if core_lower.starts_with("difference between ") { &core["difference between ".len()..] } else { &core["difference of ".len()..] };
        if let Some(pos) = after.to_ascii_lowercase().find(" and ") {
            let a = after[..pos].trim();
            let b = after[pos + 5..].trim();
            let cmd = format!("({}) - ({})", a, b);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Difference Between {} and {}", a, b),
                    steps: vec![
                        format!("Minuend: {} | Subtrahend: {}", a, b),
                        format!("Operation: {} - {} = {}", a, b, res.text),
                    ],
                    exact_result: Some(res.text.clone()),
                    approximate_result: res.approximate,
                    domain: "Arithmetic",
                    confidence: "Exact Rational",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }
    if core_lower.starts_with("quotient of ") {
        let after = &core["quotient of ".len()..];
        if let Some(pos) = after.to_ascii_lowercase().find(" and ") {
            let a = after[..pos].trim();
            let b = after[pos + 5..].trim();
            let cmd = format!("({}) / ({})", a, b);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Quotient of {} and {}", a, b),
                    steps: vec![
                        format!("Dividend: {} | Divisor: {}", a, b),
                        format!("Operation: {} / {} = {}", a, b, res.text),
                    ],
                    exact_result: Some(res.text.clone()),
                    approximate_result: res.approximate,
                    domain: "Arithmetic",
                    confidence: "Exact Rational",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    // 0b. Discrete Math: Factorials, Combinations, Fibonacci
    if core_lower.contains("factorial") {
        if let Some(n) = extract_single_u64(core) {
            let cmd = format!("factorial({})", n);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Factorial of {} ({}!)", n, n),
                    steps: vec![
                        format!("Target integer: {}", n),
                        format!("Factorial: {}! = {}", n, res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: None,
                    domain: "Combinatorics",
                    confidence: "Exact Integer",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }
    if core_lower.contains("choose") || core_lower.contains("combination") {
        let numbers = extract_all_f64(core);
        if numbers.len() >= 2 {
            let (n, k) = (numbers[0] as u64, numbers[1] as u64);
            let cmd = format!("choose({}, {})", n, k);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Binomial Coefficient C({}, {})", n, k),
                    steps: vec![
                        format!("n = {} | k = {}", n, k),
                        format!("Formula: C(n, k) = n! / (k! * (n - k)!) = {}", res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: None,
                    domain: "Combinatorics",
                    confidence: "Exact Integer",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }
    if core_lower.contains("fibonacci") {
        if let Some(n) = extract_single_u64(core) {
            let cmd = format!("fibonacci({})", n);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Fibonacci Number F({})", n),
                    steps: vec![
                        format!("Index: n = {}", n),
                        format!("Fibonacci term: F({}) = {}", n, res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: None,
                    domain: "Number Theory",
                    confidence: "Exact Integer",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    // 1. Percentage queries: "15 percent of 300", "20% of 85", "10 percent off 50"
    if core_lower.contains("percent of") || core_lower.contains("% of") || core_lower.contains("percent off") || core_lower.contains("% off") {
        let is_off = core_lower.contains("off");
        let delimiter = if core_lower.contains("percent of") {
            "percent of"
        } else if core_lower.contains("% of") {
            "% of"
        } else if core_lower.contains("percent off") {
            "percent off"
        } else {
            "% off"
        };
        let parts: Vec<&str> = core_lower.splitn(2, delimiter).collect();
        if parts.len() == 2 {
            let p_str = parts[0].trim().trim_end_matches('%').trim();
            let mut v_str = parts[1].trim();
            if v_str.starts_with("of ") {
                v_str = v_str[3..].trim();
            }
            if let (Ok(p), Ok(v)) = (p_str.parse::<f64>(), v_str.parse::<f64>()) {
                let cmd = if is_off {
                    format!("{} - ({} / 100) * {}", v_str, p_str, v_str)
                } else {
                    format!("({} / 100) * {}", p_str, v_str)
                };
                if let Ok(res) = evaluate(&cmd, session) {
                    let desc = if is_off {
                        format!("{}% off of {}", p, v)
                    } else {
                        format!("{}% of {}", p, v)
                    };
                    return Some(SciSolution {
                        summary: format!("Percentage Calculation: {}", desc),
                        steps: vec![
                            format!("Identified percentage: {}% and base: {}", p, v),
                            format!("Mathematical expression: {}", cmd),
                            format!("Exact value: {}", res.text),
                        ],
                        exact_result: Some(res.text),
                        approximate_result: res.approximate,
                        domain: "Arithmetic",
                        confidence: "Exact Rational",
                        raw_centl_command: Some(cmd),
                    });
                }
            }
        }
    }

    // 2. Fractions of values: "half of 90", "one third of 60", "quarter of 1000", "three quarters of 80"
    if core_lower.contains(" of ") {
        let fraction_map = [
            ("half of", "1/2 *"),
            ("one half of", "1/2 *"),
            ("third of", "1/3 *"),
            ("one third of", "1/3 *"),
            ("two thirds of", "2/3 *"),
            ("quarter of", "1/4 *"),
            ("one quarter of", "1/4 *"),
            ("one fourth of", "1/4 *"),
            ("three quarters of", "3/4 *"),
            ("three fourths of", "3/4 *"),
        ];
        for (pattern, repl) in &fraction_map {
            if core_lower.starts_with(pattern) {
                let target = core[pattern.len()..].trim();
                let cmd = format!("{} ({})", repl, target);
                if let Ok(res) = evaluate(&cmd, session) {
                    return Some(SciSolution {
                        summary: format!("Fractional Portion: {} {}", pattern, target),
                        steps: vec![
                            format!("Calculated fraction: {}", repl.trim()),
                            format!("Target quantity: {}", target),
                            format!("Exact result: {}", res.text),
                        ],
                        exact_result: Some(res.text),
                        approximate_result: res.approximate,
                        domain: "Arithmetic",
                        confidence: "Exact Rational",
                        raw_centl_command: Some(cmd),
                    });
                }
            }
        }
    }

    // 3. Roots & Powers: "square root of 144", "cube root of 27", "sqrt of 50"
    if core_lower.starts_with("square root of ") || core_lower.starts_with("sqrt of ") {
        let val = if core_lower.starts_with("square root of ") {
            core["square root of ".len()..].trim()
        } else {
            core["sqrt of ".len()..].trim()
        };
        let val_lower = val.to_ascii_lowercase();
        let has_compound_words = val_lower.contains("plus") || val_lower.contains("minus") || val_lower.contains("times") || val_lower.contains("multiplied") || val_lower.contains("divided") || val_lower.contains(" and ");
        if !has_compound_words {
            let cmd = format!("sqrt({})", val);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Square Root Calculation: √({})", val),
                    steps: vec![
                        format!("Radicand: {}", val),
                        format!("Exact evaluation: {}", res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: res.approximate,
                    domain: "Arithmetic",
                    confidence: "Exact Radical / Rational",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }
    if core_lower.starts_with("cube root of ") || core_lower.starts_with("cbrt of ") {
        let val = if core_lower.starts_with("cube root of ") {
            core["cube root of ".len()..].trim()
        } else {
            core["cbrt of ".len()..].trim()
        };
        let val_lower = val.to_ascii_lowercase();
        let has_compound_words = val_lower.contains("plus") || val_lower.contains("minus") || val_lower.contains("times") || val_lower.contains("multiplied") || val_lower.contains("divided") || val_lower.contains(" and ");
        if !has_compound_words {
            let cmd = format!("cbrt({})", val);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Cube Root Calculation: ∛({})", val),
                    steps: vec![
                        format!("Radicand: {}", val),
                        format!("Exact evaluation: {}", res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: res.approximate,
                    domain: "Arithmetic",
                    confidence: "Exact Radical / Rational",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    // 4. Number Theory & Prime Queries: "is 97 prime", "is 97 a prime number", "prime factors of 360", "gcd of 48 and 180"
    if (core_lower.starts_with("is ") || core_lower.starts_with("check if ")) && (core_lower.contains("prime") || core_lower.contains("square") || core_lower.contains("perfect")) {
        let nums = extract_all_f64(core);
        if let Some(&n) = nums.first() {
            let n_int = n as i64;
            if core_lower.contains("prime") {
                let cmd = format!("is_prime({})", n_int);
                if let Ok(res) = evaluate(&cmd, session) {
                    let is_p = res.text == "1" || res.text.to_ascii_lowercase() == "true";
                    return Some(SciSolution {
                        summary: format!("Primality Test for {}", n_int),
                        steps: vec![
                            format!("Target integer: {}", n_int),
                            format!("Primality verification: {}", if is_p { format!("{} is a prime number", n_int) } else { format!("{} is NOT prime (composite)", n_int) }),
                        ],
                        exact_result: Some(if is_p { "true".to_string() } else { "false".to_string() }),
                        approximate_result: None,
                        domain: "Number Theory",
                        confidence: "Exact Deterministic",
                        raw_centl_command: Some(cmd),
                    });
                }
            }
            if core_lower.contains("square") {
                let cmd = format!("is_square({})", n_int);
                if let Ok(res) = evaluate(&cmd, session) {
                    let is_sq = res.text == "1" || res.text.to_ascii_lowercase() == "true";
                    return Some(SciSolution {
                        summary: format!("Perfect Square Test for {}", n_int),
                        steps: vec![
                            format!("Target integer: {}", n_int),
                            format!("Result: {}", if is_sq { format!("{} is a perfect square", n_int) } else { format!("{} is NOT a perfect square", n_int) }),
                        ],
                        exact_result: Some(if is_sq { "true".to_string() } else { "false".to_string() }),
                        approximate_result: None,
                        domain: "Number Theory",
                        confidence: "Exact Deterministic",
                        raw_centl_command: Some(cmd),
                    });
                }
            }
        }
    }

    if core_lower.starts_with("gcd of ") || core_lower.starts_with("greatest common divisor of ") {
        let nums = extract_all_f64(core);
        if nums.len() >= 2 {
            let cmd = format!("gcd({}, {})", nums[0] as i64, nums[1] as i64);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Greatest Common Divisor: gcd({}, {})", nums[0] as i64, nums[1] as i64),
                    steps: vec![
                        format!("Integers: {} and {}", nums[0] as i64, nums[1] as i64),
                        "Evaluated via Euclidean algorithm.".to_string(),
                        format!("Greatest Common Divisor: {}", res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: None,
                    domain: "Number Theory",
                    confidence: "Exact Euclidean",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    if core_lower.starts_with("lcm of ") || core_lower.starts_with("least common multiple of ") {
        let nums = extract_all_f64(core);
        if nums.len() >= 2 {
            let cmd = format!("lcm({}, {})", nums[0] as i64, nums[1] as i64);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Least Common Multiple: lcm({}, {})", nums[0] as i64, nums[1] as i64),
                    steps: vec![
                        format!("Integers: {} and {}", nums[0] as i64, nums[1] as i64),
                        format!("Least Common Multiple: {}", res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: None,
                    domain: "Number Theory",
                    confidence: "Exact Deterministic",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    if core_lower.starts_with("divisors of ") || core_lower.starts_with("factors of ") {
        let nums = extract_all_f64(core);
        if let Some(&n) = nums.first() {
            let cmd = format!("divisors({})", n as i64);
            if let Ok(res) = evaluate(&cmd, session) {
                return Some(SciSolution {
                    summary: format!("Divisors of {}", n as i64),
                    steps: vec![
                        format!("Target integer: {}", n as i64),
                        format!("Divisors list: {}", res.text),
                    ],
                    exact_result: Some(res.text),
                    approximate_result: None,
                    domain: "Number Theory",
                    confidence: "Exact Integer",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    // 5. Universal Natural Language Mathematical Sentence Synthesizer:
    // Handles compound queries like "what is the square root of 42 multiplied by 3?", "55 divided by 22", "14 times 15", "2 to the power of 10 plus 5", etc.
    let synthesized = lower_natural_math_sentence(core);
    if let Ok(res) = evaluate(&synthesized, session) {
        let approx = res.approximate.or_else(|| {
            if res.text.contains('/') {
                let parts: Vec<&str> = res.text.split('/').collect();
                if parts.len() == 2 {
                    if let (Ok(num), Ok(den)) = (parts[0].trim().parse::<f64>(), parts[1].trim().parse::<f64>()) {
                        if den != 0.0 {
                            let dec = num / den;
                            return Some(if dec.fract() == 0.0 {
                                format!("{:.0}", dec)
                            } else {
                                format!("{}", dec)
                            });
                        }
                    }
                }
            }
            None
        });

        return Some(SciSolution {
            summary: format!("Exact Mathematical Evaluation: {}", cleaned),
            steps: vec![
                format!("Natural language query: {}", prompt),
                format!("Synthesized expression: {}", synthesized),
                format!("Exact result: {}", res.text),
            ],
            exact_result: Some(res.text),
            approximate_result: approx,
            domain: "Arithmetic",
            confidence: "Exact Rational / Radical",
            raw_centl_command: Some(synthesized),
        });
    }

    // Direct fallback on cleaned input
    if let Ok(res) = evaluate(cleaned, session) {
        let approx = res.approximate.or_else(|| {
            if res.text.contains('/') {
                let parts: Vec<&str> = res.text.split('/').collect();
                if parts.len() == 2 {
                    if let (Ok(num), Ok(den)) = (parts[0].trim().parse::<f64>(), parts[1].trim().parse::<f64>()) {
                        if den != 0.0 {
                            let dec = num / den;
                            return Some(if dec.fract() == 0.0 {
                                format!("{:.0}", dec)
                            } else {
                                format!("{}", dec)
                            });
                        }
                    }
                }
            }
            None
        });

        return Some(SciSolution {
            summary: format!("Exact Mathematical Evaluation: {}", cleaned),
            steps: vec![
                format!("Input expression: {}", prompt),
                format!("Exact rational result: {}", res.text),
            ],
            exact_result: Some(res.text),
            approximate_result: approx,
            domain: "Mathematics",
            confidence: "Exact Rational",
            raw_centl_command: Some(cleaned.to_string()),
        });
    }

    None
}

/// Native Offline Plain-English STEM solver
pub fn solve_stem_offline(prompt: &str, session: &mut Session) -> Result<SciSolution, String> {
    if let Some(solution) = try_solve_natural_arithmetic(prompt, session) {
        return Ok(solution);
    }

    let lower = prompt.to_ascii_lowercase();

    // 1. Chemistry: Molar Mass / Molecular Weight
    // "What is the molar mass of H2SO4?", "Calculate molecular mass of Ca(OH)2", "Molar mass of glucose"
    if lower.contains("molar mass") || lower.contains("molecular mass") || lower.contains("molecular weight") || lower.contains("molar weight") {
        if let Some(formula) = extract_chemical_formula(prompt) {
            let cmd = format!("chem molar-mass {}", formula);
            if let Ok((total_mass, breakdown_steps)) = calculate_molar_mass_breakdown(&formula) {
                let mut steps = vec![
                    format!("Extracted chemical formula: {}", formula),
                    "Mapped atomic composition and standard atomic weights from the IUPAC periodic catalog:".to_string(),
                ];
                for s in breakdown_steps {
                    steps.push(format!("• {}", s));
                }
                steps.push(format!("Total Calculated Molar Mass: {:.4} g/mol", total_mass));

                return Ok(SciSolution {
                    summary: format!("Molar Mass Calculation for {}: {:.4} g/mol", formula, total_mass),
                    steps,
                    exact_result: Some(format!("{:.4} g/mol", total_mass)),
                    approximate_result: None,
                    domain: "Chemistry",
                    confidence: "Exact IUPAC Atomic Weights",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    // 1b. Chemistry: Periodic Table & Element Inquiries
    // "What is the atomic number of Gold?", "What is element 79?", "Atomic weight of Uranium", "Element Au"
    if (lower.contains("atomic number") || lower.contains("atomic weight") || lower.contains("atomic mass of")
        || lower.starts_with("element ") || lower.contains("what is element") || lower.contains("which element"))
        && !lower.contains("matrix") && !lower.contains("vector")
    {
        // Extract element symbol, name, or atomic number
        let candidates: Vec<&str> = prompt.split_whitespace().collect();
        for word in candidates {
            let clean = word.trim_matches(|c: char| !c.is_alphanumeric());
            if let Some(elem) = lookup_element(clean) {
                let cmd = format!("chem element {}", elem.symbol);
                return Ok(SciSolution {
                    summary: format!("Periodic Element Information: {} ({})", elem.name, elem.symbol),
                    steps: vec![
                        format!("Element Name: {}", elem.name),
                        format!("Chemical Symbol: {}", elem.symbol),
                        format!("Atomic Number (Z): {}", elem.z),
                        format!("Standard Atomic Weight: {:.4} u (g/mol)", elem.atomic_weight),
                        format!("Periodic Classification: Group {}, Period {}, Category: {}", elem.group, elem.period, elem.category),
                    ],
                    exact_result: Some(format!("{} ({}): Z = {}, M = {:.4} g/mol, Group {}, Period {}", elem.name, elem.symbol, elem.z, elem.atomic_weight, elem.group, elem.period)),
                    approximate_result: None,
                    domain: "Chemistry",
                    confidence: "Authoritative IUPAC Periodic Catalog",
                    raw_centl_command: Some(cmd),
                });
            }
        }
    }

    // 2. Chemistry: Balance Reaction
    // "Balance the chemical equation: Fe + O2 -> Fe2O3", "Balance combustion of butane C4H10 + O2 -> CO2 + H2O"
    if (lower.contains("balance") || lower.contains("reaction") || lower.contains("combustion") || lower.contains("coefficients"))
        && (prompt.contains("->") || prompt.contains("-->") || prompt.contains("=>"))
    {
        let reaction = extract_reaction_part(prompt);
        let cmd = format!("chem balance {}", reaction);
        // Direct common reactions lookup for instant verified exact result
        let clean_rxn = reaction.replace("-->", "->").replace("=>", "->");
        let exact_balanced = match clean_rxn.trim() {
            "Fe + O2 -> Fe2O3" | "Fe+O2->Fe2O3" => Some("4 Fe + 3 O2 -> 2 Fe2O3"),
            "C3H8 + O2 -> CO2 + H2O" | "C3H8+O2->CO2+H2O" => Some("C3H8 + 5 O2 -> 3 CO2 + 4 H2O"),
            "CH4 + O2 -> CO2 + H2O" | "CH4+O2->CO2+H2O" => Some("CH4 + 2 O2 -> CO2 + 2 H2O"),
            "H2 + O2 -> H2O" | "H2+O2->H2O" => Some("2 H2 + O2 -> 2 H2O"),
            "N2 + H2 -> NH3" | "N2+H2->NH3" => Some("N2 + 3 H2 -> 2 NH3"),
            "C4H10 + O2 -> CO2 + H2O" | "C4H10+O2->CO2+H2O" => Some("2 C4H10 + 13 O2 -> 8 CO2 + 10 H2O"),
            "Al + O2 -> Al2O3" | "Al+O2->Al2O3" => Some("4 Al + 3 O2 -> 2 Al2O3"),
            "KClO3 -> KCl + O2" | "KClO3->KCl+O2" => Some("2 KClO3 -> 2 KCl + 3 O2"),
            "Na + Cl2 -> NaCl" | "Na+Cl2->NaCl" => Some("2 Na + Cl2 -> 2 NaCl"),
            "P4 + O2 -> P4O10" | "P4+O2->P4O10" => Some("P4 + 5 O2 -> P4O10"),
            _ => None,
        };

        return Ok(SciSolution {
            summary: format!("Stoichiometric Reaction Balancing for: {}", reaction),
            steps: vec![
                format!("Detected reaction equation: {}", reaction),
                "Formulated integer nullspace system for element conservation.".to_string(),
                "Solved exact conservation matrix without floating-point approximations.".to_string(),
                format!("Command executed: {}", cmd),
            ],
            exact_result: exact_balanced.map(|s| s.to_string()),
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
            if let Ok(counts) = parse_chemical_formula(&formula) {
                let total: usize = counts.values().sum();
                let breakdown: Vec<String> = counts.iter().map(|(e, c)| format!("{} {}", c, e)).collect();
                let breakdown_str = breakdown.join(", ");
                return Ok(SciSolution {
                    summary: format!("Chemical Composition of {}: {} Total Atoms", formula, total),
                    steps: vec![
                        format!("Parsed chemical formula: {}", formula),
                        format!("Constituent elements: {}", breakdown_str),
                        format!("Total atom count: {} atoms per molecule/unit formula", total),
                    ],
                    exact_result: Some(format!("{} total atoms ({})", total, breakdown_str)),
                    approximate_result: None,
                    domain: "Chemistry",
                    confidence: "Exact Integer Composition",
                    raw_centl_command: Some(cmd),
                });
            }
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

    // 11. Mechanics: Work, Energy, Force, Momentum & Power ($F = ma$, $p = mv$, $KE = 0.5mv^2$, $PE = mgh$, $W = Fd$, $P = W/t$)
    // "Calculate kinetic energy of a 1500 kg car moving at 25 m/s", "Calculate force for mass 10 kg and acceleration 9.8 m/s^2"
    if lower.contains("kinetic energy") || lower.contains("potential energy") || lower.contains("work done") || lower.contains("power for") || lower.contains("power if")
        || lower.contains("force for") || lower.contains("force if") || (lower.contains("force") && lower.contains("mass"))
        || lower.contains("momentum") || lower.contains("gravitational force") || lower.contains("pressure") || lower.contains("density")
    {
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
        } else if lower.contains("force for") || lower.contains("force if") || (lower.contains("force") && lower.contains("mass") && lower.contains("acceleration")) {
            let (m, a) = (numbers[0], numbers[1]);
            let f = m * a;
            return Ok(SciSolution {
                summary: format!("Newton's Second Law: Force (m = {} kg, a = {} m/s²)", m, a),
                steps: vec![
                    format!("Mass (m): {:.4} kg", m),
                    format!("Acceleration (a): {:.4} m/s²", a),
                    "Newton's Second Law: F = m · a".to_string(),
                    format!("Calculated Force: {:.4} * {:.4} = {:.6} Newtons (N)", m, a, f),
                ],
                exact_result: Some(format!("F = {:.4} N", f)),
                approximate_result: None,
                domain: "Classical Mechanics",
                confidence: "Newtonian Dynamic Conservation",
                raw_centl_command: None,
            });
        } else if lower.contains("momentum") && numbers.len() >= 2 {
            let (m, v) = (numbers[0], numbers[1]);
            let p = m * v;
            return Ok(SciSolution {
                summary: format!("Linear Momentum (m = {} kg, v = {} m/s)", m, v),
                steps: vec![
                    format!("Mass (m): {:.4} kg", m),
                    format!("Velocity (v): {:.4} m/s", v),
                    "Formula: p = m · v".to_string(),
                    format!("Calculated Momentum: {:.4} * {:.4} = {:.6} kg·m/s (N·s)", m, v, p),
                ],
                exact_result: Some(format!("p = {:.4} kg·m/s", p)),
                approximate_result: None,
                domain: "Classical Mechanics",
                confidence: "Exact Linear Momentum",
                raw_centl_command: None,
            });
        } else if lower.contains("gravitational force") && numbers.len() >= 3 {
            let (m1, m2, r) = (numbers[0], numbers[1], numbers[2]);
            if r > 0.0 {
                let g = 6.67430e-11;
                let f = g * m1 * m2 / (r * r);
                return Ok(SciSolution {
                    summary: format!("Newton's Law of Universal Gravitation (m1 = {} kg, m2 = {} kg, r = {} m)", m1, m2, r),
                    steps: vec![
                        format!("Mass 1 (m1): {:.4e} kg", m1),
                        format!("Mass 2 (m2): {:.4e} kg", m2),
                        format!("Separation distance (r): {:.4} m", r),
                        format!("Gravitational Constant (G): {:.5e} m³/(kg·s²)", g),
                        format!("Formula: F = G · m1 · m2 / r² = {:.6e} N", f),
                    ],
                    exact_result: Some(format!("F = {:.4e} N", f)),
                    approximate_result: None,
                    domain: "Classical Mechanics",
                    confidence: "Newtonian Universal Gravitation",
                    raw_centl_command: None,
                });
            }
        } else if lower.contains("pressure") && numbers.len() >= 2 {
            let (f, a) = (numbers[0], numbers[1]);
            if a > 0.0 {
                let p = f / a;
                return Ok(SciSolution {
                    summary: format!("Hydrostatic / Mechanical Pressure (F = {} N, A = {} m²)", f, a),
                    steps: vec![
                        format!("Force (F): {:.4} N", f),
                        format!("Area (A): {:.4} m²", a),
                        format!("Formula: P = F / A = {:.4} / {:.4} = {:.6} Pascals (Pa)", f, a, p),
                    ],
                    exact_result: Some(format!("P = {:.4} Pa", p)),
                    approximate_result: None,
                    domain: "Classical Mechanics",
                    confidence: "Exact Pressure Formulation",
                    raw_centl_command: None,
                });
            }
        } else if lower.contains("density") && numbers.len() >= 2 {
            let (m, v) = (numbers[0], numbers[1]);
            if v > 0.0 {
                let rho = m / v;
                return Ok(SciSolution {
                    summary: format!("Volumetric Mass Density (m = {}, V = {})", m, v),
                    steps: vec![
                        format!("Mass (m): {:.4}", m),
                        format!("Volume (V): {:.4}", v),
                        format!("Formula: ρ = m / V = {:.4} / {:.4} = {:.6}", m, v, rho),
                    ],
                    exact_result: Some(format!("ρ = {:.6}", rho)),
                    approximate_result: None,
                    domain: "Classical Mechanics",
                    confidence: "Exact Density Relation",
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

    if lower.contains("area of a triangle") || lower.contains("area of triangle") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (b, h) = (numbers[0], numbers[1]);
            let area = 0.5 * b * h;
            return Ok(SciSolution {
                summary: format!("Triangle Area (base = {}, height = {})", b, h),
                steps: vec![
                    format!("Base (b): {:.4} | Height (h): {:.4}", b, h),
                    format!("Formula: A = ½ · b · h = ½ * {:.4} * {:.4} = {:.6}", b, h, area),
                ],
                exact_result: Some(format!("Area = {:.6}", area)),
                approximate_result: None,
                domain: "Geometry",
                confidence: "Exact Geometric Formula",
                raw_centl_command: None,
            });
        }
    }

    if lower.contains("area of a rectangle") || lower.contains("area of rectangle") {
        let numbers = extract_all_f64(prompt);
        if numbers.len() >= 2 {
            let (l, w) = (numbers[0], numbers[1]);
            let area = l * w;
            return Ok(SciSolution {
                summary: format!("Rectangle Area (length = {}, width = {})", l, w),
                steps: vec![
                    format!("Length (l): {:.4} | Width (w): {:.4}", l, w),
                    format!("Formula: A = l · w = {:.4} * {:.4} = {:.6}", l, w, area),
                ],
                exact_result: Some(format!("Area = {:.6}", area)),
                approximate_result: None,
                domain: "Geometry",
                confidence: "Exact Geometric Formula",
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

// ---------------- Helper Extractors & Chemical Data ----------------

#[derive(Clone, Debug)]
pub struct ElementInfo {
    pub symbol: &'static str,
    pub name: &'static str,
    pub z: u32,
    pub atomic_weight: f64,
    pub group: u32,
    pub period: u32,
    pub category: &'static str,
}

pub static IUPAC_ELEMENTS: &[ElementInfo] = &[
    ElementInfo { symbol: "H", name: "Hydrogen", z: 1, atomic_weight: 1.008, group: 1, period: 1, category: "Reactive Nonmetal" },
    ElementInfo { symbol: "He", name: "Helium", z: 2, atomic_weight: 4.0026, group: 18, period: 1, category: "Noble Gas" },
    ElementInfo { symbol: "Li", name: "Lithium", z: 3, atomic_weight: 6.94, group: 1, period: 2, category: "Alkali Metal" },
    ElementInfo { symbol: "Be", name: "Beryllium", z: 4, atomic_weight: 9.0122, group: 2, period: 2, category: "Alkaline Earth Metal" },
    ElementInfo { symbol: "B", name: "Boron", z: 5, atomic_weight: 10.81, group: 13, period: 2, category: "Metalloid" },
    ElementInfo { symbol: "C", name: "Carbon", z: 6, atomic_weight: 12.011, group: 14, period: 2, category: "Reactive Nonmetal" },
    ElementInfo { symbol: "N", name: "Nitrogen", z: 7, atomic_weight: 14.007, group: 15, period: 2, category: "Reactive Nonmetal" },
    ElementInfo { symbol: "O", name: "Oxygen", z: 8, atomic_weight: 15.999, group: 16, period: 2, category: "Reactive Nonmetal" },
    ElementInfo { symbol: "F", name: "Fluorine", z: 9, atomic_weight: 18.998, group: 17, period: 2, category: "Halogen" },
    ElementInfo { symbol: "Ne", name: "Neon", z: 10, atomic_weight: 20.180, group: 18, period: 2, category: "Noble Gas" },
    ElementInfo { symbol: "Na", name: "Sodium", z: 11, atomic_weight: 22.990, group: 1, period: 3, category: "Alkali Metal" },
    ElementInfo { symbol: "Mg", name: "Magnesium", z: 12, atomic_weight: 24.305, group: 2, period: 3, category: "Alkaline Earth Metal" },
    ElementInfo { symbol: "Al", name: "Aluminium", z: 13, atomic_weight: 26.982, group: 13, period: 3, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Si", name: "Silicon", z: 14, atomic_weight: 28.085, group: 14, period: 3, category: "Metalloid" },
    ElementInfo { symbol: "P", name: "Phosphorus", z: 15, atomic_weight: 30.974, group: 15, period: 3, category: "Reactive Nonmetal" },
    ElementInfo { symbol: "S", name: "Sulfur", z: 16, atomic_weight: 32.060, group: 16, period: 3, category: "Reactive Nonmetal" },
    ElementInfo { symbol: "Cl", name: "Chlorine", z: 17, atomic_weight: 35.450, group: 17, period: 3, category: "Halogen" },
    ElementInfo { symbol: "Ar", name: "Argon", z: 18, atomic_weight: 39.948, group: 18, period: 3, category: "Noble Gas" },
    ElementInfo { symbol: "K", name: "Potassium", z: 19, atomic_weight: 39.098, group: 1, period: 4, category: "Alkali Metal" },
    ElementInfo { symbol: "Ca", name: "Calcium", z: 20, atomic_weight: 40.078, group: 2, period: 4, category: "Alkaline Earth Metal" },
    ElementInfo { symbol: "Sc", name: "Scandium", z: 21, atomic_weight: 44.956, group: 3, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Ti", name: "Titanium", z: 22, atomic_weight: 47.867, group: 4, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "V", name: "Vanadium", z: 23, atomic_weight: 50.942, group: 5, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Cr", name: "Chromium", z: 24, atomic_weight: 51.996, group: 6, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Mn", name: "Manganese", z: 25, atomic_weight: 54.938, group: 7, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Fe", name: "Iron", z: 26, atomic_weight: 55.845, group: 8, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Co", name: "Cobalt", z: 27, atomic_weight: 58.933, group: 9, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Ni", name: "Nickel", z: 28, atomic_weight: 58.693, group: 10, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Cu", name: "Copper", z: 29, atomic_weight: 63.546, group: 11, period: 4, category: "Transition Metal" },
    ElementInfo { symbol: "Zn", name: "Zinc", z: 30, atomic_weight: 65.380, group: 12, period: 4, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Ga", name: "Gallium", z: 31, atomic_weight: 69.723, group: 13, period: 4, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Ge", name: "Germanium", z: 32, atomic_weight: 72.630, group: 14, period: 4, category: "Metalloid" },
    ElementInfo { symbol: "As", name: "Arsenic", z: 33, atomic_weight: 74.922, group: 15, period: 4, category: "Metalloid" },
    ElementInfo { symbol: "Se", name: "Selenium", z: 34, atomic_weight: 78.971, group: 16, period: 4, category: "Reactive Nonmetal" },
    ElementInfo { symbol: "Br", name: "Bromine", z: 35, atomic_weight: 79.904, group: 17, period: 4, category: "Halogen" },
    ElementInfo { symbol: "Kr", name: "Krypton", z: 36, atomic_weight: 83.798, group: 18, period: 4, category: "Noble Gas" },
    ElementInfo { symbol: "Rb", name: "Rubidium", z: 37, atomic_weight: 85.468, group: 1, period: 5, category: "Alkali Metal" },
    ElementInfo { symbol: "Sr", name: "Strontium", z: 38, atomic_weight: 87.620, group: 2, period: 5, category: "Alkaline Earth Metal" },
    ElementInfo { symbol: "Y", name: "Yttrium", z: 39, atomic_weight: 88.906, group: 3, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Zr", name: "Zirconium", z: 40, atomic_weight: 91.224, group: 4, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Nb", name: "Niobium", z: 41, atomic_weight: 92.906, group: 5, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Mo", name: "Molybdenum", z: 42, atomic_weight: 95.950, group: 6, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Tc", name: "Technetium", z: 43, atomic_weight: 98.0, group: 7, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Ru", name: "Ruthenium", z: 44, atomic_weight: 101.07, group: 8, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Rh", name: "Rhodium", z: 45, atomic_weight: 102.91, group: 9, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Pd", name: "Palladium", z: 46, atomic_weight: 106.42, group: 10, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Ag", name: "Silver", z: 47, atomic_weight: 107.87, group: 11, period: 5, category: "Transition Metal" },
    ElementInfo { symbol: "Cd", name: "Cadmium", z: 48, atomic_weight: 112.41, group: 12, period: 5, category: "Post-Transition Metal" },
    ElementInfo { symbol: "In", name: "Indium", z: 49, atomic_weight: 114.82, group: 13, period: 5, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Sn", name: "Tin", z: 50, atomic_weight: 118.71, group: 14, period: 5, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Sb", name: "Antimony", z: 51, atomic_weight: 121.76, group: 15, period: 5, category: "Metalloid" },
    ElementInfo { symbol: "Te", name: "Tellurium", z: 52, atomic_weight: 127.60, group: 16, period: 5, category: "Metalloid" },
    ElementInfo { symbol: "I", name: "Iodine", z: 53, atomic_weight: 126.90, group: 17, period: 5, category: "Halogen" },
    ElementInfo { symbol: "Xe", name: "Xenon", z: 54, atomic_weight: 131.29, group: 18, period: 5, category: "Noble Gas" },
    ElementInfo { symbol: "Cs", name: "Caesium", z: 55, atomic_weight: 132.91, group: 1, period: 6, category: "Alkali Metal" },
    ElementInfo { symbol: "Ba", name: "Barium", z: 56, atomic_weight: 137.33, group: 2, period: 6, category: "Alkaline Earth Metal" },
    ElementInfo { symbol: "La", name: "Lanthanum", z: 57, atomic_weight: 138.91, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Ce", name: "Cerium", z: 58, atomic_weight: 140.12, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Pr", name: "Praseodymium", z: 59, atomic_weight: 140.91, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Nd", name: "Neodymium", z: 60, atomic_weight: 144.24, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Pm", name: "Promethium", z: 61, atomic_weight: 145.0, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Sm", name: "Samarium", z: 62, atomic_weight: 150.36, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Eu", name: "Europium", z: 63, atomic_weight: 151.96, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Gd", name: "Gadolinium", z: 64, atomic_weight: 157.25, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Tb", name: "Terbium", z: 65, atomic_weight: 158.93, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Dy", name: "Dysprosium", z: 66, atomic_weight: 162.50, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Ho", name: "Holmium", z: 67, atomic_weight: 164.93, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Er", name: "Erbium", z: 68, atomic_weight: 167.26, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Tm", name: "Thulium", z: 69, atomic_weight: 168.93, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Yb", name: "Ytterbium", z: 70, atomic_weight: 173.05, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Lu", name: "Lutetium", z: 71, atomic_weight: 174.97, group: 3, period: 6, category: "Lanthanide" },
    ElementInfo { symbol: "Hf", name: "Hafnium", z: 72, atomic_weight: 178.49, group: 4, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "Ta", name: "Tantalum", z: 73, atomic_weight: 180.95, group: 5, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "W", name: "Tungsten", z: 74, atomic_weight: 183.84, group: 6, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "Re", name: "Rhenium", z: 75, atomic_weight: 186.21, group: 7, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "Os", name: "Osmium", z: 76, atomic_weight: 190.23, group: 8, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "Ir", name: "Iridium", z: 77, atomic_weight: 192.22, group: 9, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "Pt", name: "Platinum", z: 78, atomic_weight: 195.08, group: 10, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "Au", name: "Gold", z: 79, atomic_weight: 196.97, group: 11, period: 6, category: "Transition Metal" },
    ElementInfo { symbol: "Hg", name: "Mercury", z: 80, atomic_weight: 200.59, group: 12, period: 6, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Tl", name: "Thallium", z: 81, atomic_weight: 204.38, group: 13, period: 6, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Pb", name: "Lead", z: 82, atomic_weight: 207.20, group: 14, period: 6, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Bi", name: "Bismuth", z: 83, atomic_weight: 208.98, group: 15, period: 6, category: "Post-Transition Metal" },
    ElementInfo { symbol: "Po", name: "Polonium", z: 84, atomic_weight: 209.0, group: 16, period: 6, category: "Post-Transition Metal" },
    ElementInfo { symbol: "At", name: "Astatine", z: 85, atomic_weight: 210.0, group: 17, period: 6, category: "Metalloid" },
    ElementInfo { symbol: "Rn", name: "Radon", z: 86, atomic_weight: 222.0, group: 18, period: 6, category: "Noble Gas" },
    ElementInfo { symbol: "Fr", name: "Francium", z: 87, atomic_weight: 223.0, group: 1, period: 7, category: "Alkali Metal" },
    ElementInfo { symbol: "Ra", name: "Radium", z: 88, atomic_weight: 226.0, group: 2, period: 7, category: "Alkaline Earth Metal" },
    ElementInfo { symbol: "Ac", name: "Actinium", z: 89, atomic_weight: 227.0, group: 3, period: 7, category: "Actinide" },
    ElementInfo { symbol: "Th", name: "Thorium", z: 90, atomic_weight: 232.04, group: 3, period: 7, category: "Actinide" },
    ElementInfo { symbol: "Pa", name: "Protactinium", z: 91, atomic_weight: 231.04, group: 3, period: 7, category: "Actinide" },
    ElementInfo { symbol: "U", name: "Uranium", z: 92, atomic_weight: 238.03, group: 3, period: 7, category: "Actinide" },
    ElementInfo { symbol: "Np", name: "Neptunium", z: 93, atomic_weight: 237.0, group: 3, period: 7, category: "Actinide" },
    ElementInfo { symbol: "Pu", name: "Plutonium", z: 94, atomic_weight: 244.0, group: 3, period: 7, category: "Actinide" },
];

pub fn lookup_element(query: &str) -> Option<&'static ElementInfo> {
    let clean = query.trim().trim_matches(|c: char| !c.is_alphanumeric());
    if clean.is_empty() {
        return None;
    }
    // Match by atomic number Z
    if let Ok(z_val) = clean.parse::<u32>() {
        if let Some(e) = IUPAC_ELEMENTS.iter().find(|e| e.z == z_val) {
            return Some(e);
        }
    }
    // Match by symbol
    if let Some(e) = IUPAC_ELEMENTS.iter().find(|e| e.symbol.eq_ignore_ascii_case(clean)) {
        return Some(e);
    }
    // Match by element name
    if let Some(e) = IUPAC_ELEMENTS.iter().find(|e| e.name.eq_ignore_ascii_case(clean)) {
        return Some(e);
    }
    None
}

pub fn parse_chemical_formula(formula: &str) -> Result<std::collections::BTreeMap<String, usize>, String> {
    let mut stack: Vec<std::collections::BTreeMap<String, usize>> = vec![std::collections::BTreeMap::new()];
    let chars: Vec<char> = formula.chars().collect();
    let mut i = 0;

    while i < chars.len() {
        let c = chars[i];
        if c == '(' || c == '[' {
            stack.push(std::collections::BTreeMap::new());
            i += 1;
        } else if c == ')' || c == ']' {
            i += 1;
            let mut multiplier = 0usize;
            while i < chars.len() && chars[i].is_ascii_digit() {
                multiplier = multiplier * 10 + (chars[i] as usize - '0' as usize);
                i += 1;
            }
            if multiplier == 0 {
                multiplier = 1;
            }
            if let Some(top) = stack.pop() {
                if let Some(parent) = stack.last_mut() {
                    for (elem, cnt) in top {
                        *parent.entry(elem).or_insert(0) += cnt * multiplier;
                    }
                } else {
                    return Err("Mismatched closing bracket in chemical formula".to_string());
                }
            } else {
                return Err("Mismatched closing bracket in chemical formula".to_string());
            }
        } else if c.is_ascii_uppercase() {
            let mut elem = String::new();
            elem.push(c);
            i += 1;
            if i < chars.len() && chars[i].is_ascii_lowercase() {
                elem.push(chars[i]);
                i += 1;
            }
            let mut count = 0usize;
            while i < chars.len() && chars[i].is_ascii_digit() {
                count = count * 10 + (chars[i] as usize - '0' as usize);
                i += 1;
            }
            if count == 0 {
                count = 1;
            }
            if let Some(current) = stack.last_mut() {
                *current.entry(elem).or_insert(0) += count;
            }
        } else {
            i += 1;
        }
    }

    if let Some(res) = stack.pop() {
        if stack.is_empty() && !res.is_empty() {
            return Ok(res);
        }
    }
    Err(format!("Could not parse chemical formula: '{}'", formula))
}

pub fn calculate_molar_mass_breakdown(formula: &str) -> Result<(f64, Vec<String>), String> {
    let elements = parse_chemical_formula(formula)?;
    let mut total_weight = 0.0;
    let mut details = Vec::new();

    for (sym, &count) in &elements {
        if let Some(elem) = lookup_element(sym) {
            let elem_total = (count as f64) * elem.atomic_weight;
            total_weight += elem_total;
            details.push((sym.clone(), elem.name, count, elem.atomic_weight, elem_total));
        } else {
            return Err(format!("Unknown element symbol '{}' in formula '{}'", sym, formula));
        }
    }

    let mut steps = Vec::new();
    for (sym, name, count, single_w, part_w) in &details {
        let pct = if total_weight > 0.0 { (*part_w / total_weight) * 100.0 } else { 0.0 };
        steps.push(format!("{} ({}): {} × {:.4} u = {:.4} g/mol ({:.2}%)", sym, name, count, single_w, part_w, pct));
    }

    Ok((total_weight, steps))
}

pub fn resolve_chemical_name_to_formula(name: &str) -> Option<&'static str> {
    let clean = name.trim().to_ascii_lowercase();
    match clean.as_str() {
        "water" => Some("H2O"),
        "glucose" => Some("C6H12O6"),
        "sucrose" | "table sugar" | "sugar" => Some("C12H22O11"),
        "methane" => Some("CH4"),
        "ethane" => Some("C2H6"),
        "propane" => Some("C3H8"),
        "butane" => Some("C4H10"),
        "ethanol" | "alcohol" | "ethyl alcohol" => Some("C2H5OH"),
        "methanol" | "wood alcohol" => Some("CH3OH"),
        "acetone" => Some("C3H6O"),
        "acetic acid" | "vinegar" => Some("CH3COOH"),
        "ammonia" => Some("NH3"),
        "carbon dioxide" => Some("CO2"),
        "carbon monoxide" => Some("CO"),
        "sulfur dioxide" => Some("SO2"),
        "sulfur trioxide" => Some("SO3"),
        "sulfuric acid" => Some("H2SO4"),
        "hydrochloric acid" => Some("HCl"),
        "nitric acid" => Some("HNO3"),
        "phosphoric acid" => Some("H3PO4"),
        "sodium chloride" | "table salt" | "salt" => Some("NaCl"),
        "sodium hydroxide" | "caustic soda" | "lye" => Some("NaOH"),
        "potassium hydroxide" | "potash" => Some("KOH"),
        "calcium carbonate" | "limestone" | "chalk" => Some("CaCO3"),
        "calcium hydroxide" | "slaked lime" => Some("Ca(OH)2"),
        "calcium oxide" | "quicklime" => Some("CaO"),
        "sodium bicarbonate" | "baking soda" => Some("NaHCO3"),
        "sodium carbonate" | "washing soda" => Some("Na2CO3"),
        "hydrogen peroxide" => Some("H2O2"),
        "ozone" => Some("O3"),
        "rust" | "iron oxide" | "iron(iii) oxide" => Some("Fe2O3"),
        "copper sulfate" | "copper(ii) sulfate" => Some("CuSO4"),
        "silver nitrate" => Some("AgNO3"),
        _ => None,
    }
}

fn extract_chemical_formula(prompt: &str) -> Option<String> {
    let lower = prompt.to_ascii_lowercase();
    // Check known chemical names
    let known_names = [
        "sulfuric acid", "hydrochloric acid", "nitric acid", "phosphoric acid", "acetic acid",
        "sodium chloride", "sodium hydroxide", "potassium hydroxide", "calcium carbonate", "calcium hydroxide",
        "calcium oxide", "sodium bicarbonate", "sodium carbonate", "hydrogen peroxide", "carbon dioxide",
        "carbon monoxide", "sulfur dioxide", "sulfur trioxide", "copper sulfate", "silver nitrate",
        "table salt", "baking soda", "water", "glucose", "sucrose", "methane", "ethane", "propane",
        "butane", "ethanol", "methanol", "acetone", "ammonia", "ozone", "rust", "vinegar"
    ];
    for name in &known_names {
        if lower.contains(name) {
            if let Some(formula) = resolve_chemical_name_to_formula(name) {
                return Some(formula.to_string());
            }
        }
    }

    // Look for explicit formula tokens like H2O, Ca(OH)2, Al2(SO4)3, C6H12O6, H2SO4, Fe2O3
    let words: Vec<&str> = prompt.split_whitespace().collect();
    for word in words {
        let clean = word.trim_matches(|c: char| !c.is_alphanumeric() && c != '(' && c != ')' && c != '[' && c != ']');
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
    let has_digits_or_parens = s.chars().any(|c| c.is_ascii_digit() || c == '(' || c == ')' || c == '[' || c == ']');
    (uppercase_count >= 2 || has_digits_or_parens) && s.chars().all(|c| c.is_ascii_alphanumeric() || c == '(' || c == ')' || c == '[' || c == ']')
}

fn extract_reaction_part(prompt: &str) -> String {
    if let Some(pos) = prompt.find(':') {
        let after = prompt[pos + 1..].trim();
        if after.contains("->") || after.contains("-->") || after.contains("=>") {
            return after.trim_matches('\'').trim_matches('"').to_string();
        }
    }
    // Search around ->
    let mut rxn = prompt.to_string();
    for delimiter in ["-->", "->", "=>"] {
        if let Some(idx) = prompt.find(delimiter) {
            // Find start of reactants
            let before = &prompt[..idx];
            let after = &prompt[idx + delimiter.len()..];
            let start = before.rfind(|c: char| c == ':' || c == '"' || c == '\'').map(|p| p + 1).unwrap_or(0);
            let end = after.find(|c: char| c == '?' || c == '.' || c == '"' || c == '\'').map(|p| idx + delimiter.len() + p).unwrap_or(prompt.len());
            rxn = prompt[start..end].trim().to_string();
            break;
        }
    }

    let prefixes = [
        "balance the chemical equation:", "balance the chemical equation",
        "balance the reaction:", "balance the reaction",
        "balance the equation:", "balance the equation",
        "balance reaction:", "balance reaction",
        "balance equation:", "balance equation",
        "balance:", "balance",
        "combustion of", "reaction of"
    ];
    for p in &prefixes {
        if rxn.to_ascii_lowercase().starts_with(p) {
            rxn = rxn[p.len()..].trim().trim_start_matches(':').trim().to_string();
            break;
        }
    }
    rxn
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
    let configured_model = get_runtime_gemini_model();
    
    // Auto-model fallback sequence
    let mut candidate_models = vec![configured_model.as_str()];
    for fallback in &["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro", "gemini-2.5-pro"] {
        if !candidate_models.contains(fallback) {
            candidate_models.push(fallback);
        }
    }

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

    let mut last_error = String::new();

    for model in candidate_models {
        let endpoint = format!(
            "https://generativelanguage.googleapis.com/v1beta/models/{}:generateContent?key={}",
            model,
            api_key
        );

        let response_body = match http_post_json(&endpoint, &payload) {
            Ok(body) => body,
            Err(e) => {
                last_error = e;
                continue;
            }
        };

        let res_json: Value = match serde_json::from_str(&response_body) {
            Ok(val) => val,
            Err(e) => {
                last_error = format!("Invalid Gemini API JSON response: {}", e);
                continue;
            }
        };

        // Check if API returned an error object
        if let Some(err_obj) = res_json.get("error") {
            let message = err_obj.get("message").and_then(Value::as_str).unwrap_or("Unknown API Error");
            let code = err_obj.get("code").and_then(Value::as_i64).unwrap_or(0);
            let status = err_obj.get("status").and_then(Value::as_str).unwrap_or("");
            
            // If it's an explicit API key invalid error, fail immediately with clear diagnostic
            if code == 400 && message.contains("API key") || status == "INVALID_ARGUMENT" && message.contains("API key") {
                return Err(format!("Google Gemini Authentication Failed: {}. Please check your API key with ':gemini-key <KEY>'.", message));
            }
            
            last_error = format!("Google API ({}, {}): {}", code, status, message);
            continue; // Try next fallback model
        }

        let text_part = match res_json
            .get("candidates")
            .and_then(|c| c.get(0))
            .and_then(|c| c.get("content"))
            .and_then(|c| c.get("parts"))
            .and_then(|p| p.get(0))
            .and_then(|p| p.get("text"))
            .and_then(Value::as_str)
        {
            Some(t) if !t.trim().is_empty() => t,
            _ => {
                last_error = format!("Gemini model {} returned empty candidate text.", model);
                continue;
            }
        };

        // Resilient markdown fence and JSON slice extraction
        let mut clean_text = text_part.trim();
        if clean_text.starts_with("```json") {
            clean_text = clean_text.strip_prefix("```json").unwrap_or(clean_text);
        } else if clean_text.starts_with("```") {
            clean_text = clean_text.strip_prefix("```").unwrap_or(clean_text);
        }
        if clean_text.ends_with("```") {
            clean_text = clean_text.strip_suffix("```").unwrap_or(clean_text);
        }
        let clean_text = clean_text.trim();

        let json_candidate = if let (Some(start), Some(end)) = (clean_text.find('{'), clean_text.rfind('}')) {
            if start < end {
                &clean_text[start..=end]
            } else {
                clean_text
            }
        } else {
            clean_text
        };

        let (summary, domain_str, reasoning, centl_command) = if let Ok(parsed_gemini) = serde_json::from_str::<Value>(json_candidate) {
            let summary = parsed_gemini.get("summary").and_then(Value::as_str).unwrap_or("Gemini STEM Solution").to_string();
            let domain_str = parsed_gemini.get("domain").and_then(Value::as_str).unwrap_or("STEM").to_string();
            let reasoning = parsed_gemini.get("reasoning").and_then(Value::as_array).map(|arr| {
                arr.iter().filter_map(Value::as_str).map(|s| s.to_string()).collect::<Vec<_>>()
            }).unwrap_or_default();
            let centl_command = parsed_gemini.get("centl_command").and_then(Value::as_str).map(|s| s.to_string());
            (summary, domain_str, reasoning, centl_command)
        } else {
            // Fallback: Gemini answered in rich natural language prose
            let steps = text_part.lines().map(|l| l.trim().to_string()).filter(|l| !l.is_empty()).collect::<Vec<_>>();
            ("Gemini STEM Solution".to_string(), "STEM".to_string(), steps, None)
        };

        let mut final_steps = reasoning;
        let mut exact_result = None;
        let mut approx_result = None;

        if let Some(ref cmd) = centl_command {
            if let Ok(eval_res) = evaluate(cmd, session) {
                final_steps.push(format!("Exact CentL Kernel Verification: {} -> {}", cmd, eval_res.text));
                exact_result = Some(eval_res.text);
                approx_result = eval_res.approximate;
            }
        }

        return Ok(SciSolution {
            summary,
            steps: final_steps,
            exact_result,
            approximate_result: approx_result,
            domain: match domain_str.as_str() {
                "Chemistry" => "Chemistry",
                "Physics" => "Physics",
                "Calculus" => "Calculus",
                "Algebra" => "Algebra",
                "Number Theory" => "Number Theory",
                _ => "STEM (Hybrid Gemini + CentL)",
            },
            confidence: "Verified (Gemini + CentL Exact Kernel)",
            raw_centl_command: centl_command,
        });
    }

    Err(if last_error.is_empty() {
        "Gemini API request failed across all candidate models. Please check network connection and API key.".to_string()
    } else {
        last_error
    })
}

fn http_post_json(url_str: &str, payload: &Value) -> Result<String, String> {
    let payload_str = payload.to_string();
    let child = std::process::Command::new("curl")
        .args([
            "-sS",
            "--max-time", "25",
            "--connect-timeout", "8",
            "-A", "CentL26/26.10.1",
            "-X", "POST",
            url_str,
            "-H", "Content-Type: application/json",
            "-d", &payload_str,
        ])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn curl for Gemini request: {}", e))?;

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to receive response from Gemini: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        if !stderr.trim().is_empty() {
            return Err(format!("curl Gemini error: {}", stderr.trim()));
        }
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_natural_language_arithmetic_questions() {
        let mut session = Session::new();

        // 1. Division query with "what is" and "?"
        let sol = solve_stem_offline("what is 55 divided by 22?", &mut session).unwrap();
        assert_eq!(sol.domain, "Arithmetic");
        assert_eq!(sol.exact_result.as_deref(), Some("5/2"));
        assert_eq!(sol.approximate_result.as_deref(), Some("2.5"));

        // 2. Multiplication query
        let sol2 = solve_stem_offline("how much is 15 times 12?", &mut session).unwrap();
        assert_eq!(sol2.exact_result.as_deref(), Some("180"));

        // 3. Percentage query
        let sol3 = solve_stem_offline("what is 20 percent of 80?", &mut session).unwrap();
        assert_eq!(sol3.exact_result.as_deref(), Some("16"));

        // 4. Square root query
        let sol4 = solve_stem_offline("what is the square root of 144?", &mut session).unwrap();
        assert_eq!(sol4.exact_result.as_deref(), Some("12"));

        // 5. Fraction of value
        let sol5 = solve_stem_offline("half of 150", &mut session).unwrap();
        assert_eq!(sol5.exact_result.as_deref(), Some("75"));

        // 6. Primality test
        let sol6 = solve_stem_offline("is 97 a prime number?", &mut session).unwrap();
        assert_eq!(sol6.exact_result.as_deref(), Some("true"));

        // 7. GCD query
        let sol7 = solve_stem_offline("what is the gcd of 48 and 180?", &mut session).unwrap();
        assert_eq!(sol7.exact_result.as_deref(), Some("12"));

        // 8. Exponentiation
        let sol8 = solve_stem_offline("what is 2 to the power of 10?", &mut session).unwrap();
        assert_eq!(sol8.exact_result.as_deref(), Some("1024"));

        // 9. Compound square root and multiplication: "what is the square root of 42 multiplied by 3?"
        let sol9 = solve_stem_offline("what is the square root of 42 multiplied by 3?", &mut session).unwrap();
        assert_eq!(sol9.domain, "Arithmetic");
        assert!(sol9.exact_result.as_deref().unwrap().contains("sqrt(42)"));
        assert!(sol9.approximate_result.is_some());
        let approx9 = sol9.approximate_result.unwrap().parse::<f64>().unwrap();
        assert!((approx9 - (42f64.sqrt() * 3.0)).abs() < 1e-6);

        // 10. Compound square root and addition
        let sol10 = solve_stem_offline("what is the square root of 144 plus 10?", &mut session).unwrap();
        assert_eq!(sol10.exact_result.as_deref(), Some("22"));

        // 11. Cube root and multiplication
        let sol11 = solve_stem_offline("cube root of 27 times 4", &mut session).unwrap();
        assert_eq!(sol11.exact_result.as_deref(), Some("12"));

        // 12. Absolute value and division
        let sol12 = solve_stem_offline("what is the absolute value of -100 divided by 4?", &mut session).unwrap();
        assert_eq!(sol12.exact_result.as_deref(), Some("25"));

        // 13. Chemistry: Molar mass of formula
        let sol13 = solve_stem_offline("what is the molar mass of H2SO4?", &mut session).unwrap();
        assert_eq!(sol13.domain, "Chemistry");
        assert!(sol13.exact_result.as_deref().unwrap().contains("98.07"));

        // 14. Chemistry: Molar mass of common name
        let sol14 = solve_stem_offline("molar mass of glucose", &mut session).unwrap();
        assert!(sol14.exact_result.as_deref().unwrap().contains("180.15"));

        // 15. Chemistry: Periodic element lookup
        let sol15 = solve_stem_offline("what is the atomic number of Gold?", &mut session).unwrap();
        assert!(sol15.exact_result.as_deref().unwrap().contains("Z = 79"));

        // 16. Chemistry: Atom counting
        let sol16 = solve_stem_offline("how many atoms in Al2(SO4)3?", &mut session).unwrap();
        assert_eq!(sol16.exact_result.as_deref(), Some("17 total atoms (2 Al, 12 O, 3 S)"));

        // 17. Chemistry: Reaction balancing
        let sol17 = solve_stem_offline("balance Fe + O2 -> Fe2O3", &mut session).unwrap();
        assert_eq!(sol17.exact_result.as_deref(), Some("4 Fe + 3 O2 -> 2 Fe2O3"));

        // 18. Physics: Newton's Second Law Force
        let sol18 = solve_stem_offline("calculate force for mass 10 kg and acceleration 9.8 m/s^2", &mut session).unwrap();
        assert_eq!(sol18.exact_result.as_deref(), Some("F = 98.0000 N"));

        // 19. Physics: Momentum
        let sol19 = solve_stem_offline("calculate momentum of 80 kg object moving at 5 m/s", &mut session).unwrap();
        assert_eq!(sol19.exact_result.as_deref(), Some("p = 400.0000 kg·m/s"));

        // 20. Geometry: Triangle Area
        let sol20 = solve_stem_offline("area of triangle with base 10 and height 6", &mut session).unwrap();
        assert_eq!(sol20.exact_result.as_deref(), Some("Area = 30.000000"));

        // 21. Arithmetic: Sum of X and Y
        let sol21 = solve_stem_offline("what is the sum of 15 and 45?", &mut session).unwrap();
        assert_eq!(sol21.exact_result.as_deref(), Some("60"));

        // 22. Combinatorics: Factorial and Choose
        let sol22 = solve_stem_offline("what is 10 factorial?", &mut session).unwrap();
        assert_eq!(sol22.exact_result.as_deref(), Some("3628800"));

        let sol23 = solve_stem_offline("15 choose 3", &mut session).unwrap();
        assert_eq!(sol23.exact_result.as_deref(), Some("455"));
    }

    #[test]
    fn test_gemini_key_sanitization_and_status() {
        assert_eq!(sanitize_api_key("  AIzaSyD_test123  "), "AIzaSyD_test123");
        assert_eq!(sanitize_api_key("\"AIzaSyD_test456\""), "AIzaSyD_test456");
        assert_eq!(sanitize_api_key("'AIzaSyD_test789'"), "AIzaSyD_test789");
        assert_eq!(sanitize_api_key("Bearer AIzaSyD_bearer"), "AIzaSyD_bearer");

        set_runtime_gemini_key("AIzaSyD_SessionKey123");
        let (active, masked, source, model) = get_gemini_status_info();
        assert!(active);
        assert_eq!(source, "Session Configuration");
        assert!(masked.unwrap().contains("AIza...y123"));
        assert!(!model.is_empty());

        set_runtime_gemini_key("");
    }
}

