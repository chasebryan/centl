use crate::engine::{evaluate, ExecutionResult, Session};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::Instant;

#[derive(Clone, Debug, PartialEq)]
pub enum ExtensionKind {
    Function,
    Unit,
    Constant,
    Macro,
    Pipeline,
    Brainstorm,
}

impl std::fmt::Display for ExtensionKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ExtensionKind::Function => write!(f, "Function"),
            ExtensionKind::Unit => write!(f, "Unit"),
            ExtensionKind::Constant => write!(f, "Constant"),
            ExtensionKind::Macro => write!(f, "Macro"),
            ExtensionKind::Pipeline => write!(f, "Pipeline"),
            ExtensionKind::Brainstorm => write!(f, "Brainstorm"),
        }
    }
}

#[derive(Clone, Debug)]
pub struct UserExtension {
    pub name: String,
    pub kind: ExtensionKind,
    pub params: Vec<String>,
    pub body: String,
    pub description: String,
    pub doc: String,
    pub call_count: u64,
}

impl UserExtension {
    pub fn to_json(&self) -> Value {
        json!({
            "name": self.name,
            "kind": format!("{}", self.kind),
            "params": self.params,
            "body": self.body,
            "description": self.description,
            "doc": self.doc,
            "call_count": self.call_count,
        })
    }
}

static USER_EXTENSIONS: Mutex<Option<HashMap<String, UserExtension>>> = Mutex::new(None);

fn with_extensions_mut<F, R>(f: F) -> R
where
    F: FnOnce(&mut HashMap<String, UserExtension>) -> R,
{
    let mut lock = USER_EXTENSIONS.lock().unwrap_or_else(|p| p.into_inner());
    if lock.is_none() {
        *lock = Some(HashMap::new());
    }
    f(lock.as_mut().unwrap())
}

fn with_extensions<F, R>(f: F) -> R
where
    F: FnOnce(&HashMap<String, UserExtension>) -> R,
{
    let mut lock = USER_EXTENSIONS.lock().unwrap_or_else(|p| p.into_inner());
    if lock.is_none() {
        *lock = Some(HashMap::new());
    }
    f(lock.as_ref().unwrap())
}

pub fn register_extension(ext: UserExtension) {
    with_extensions_mut(|map| {
        map.insert(ext.name.to_ascii_lowercase(), ext);
    });
}

pub fn get_extension(name: &str) -> Option<UserExtension> {
    with_extensions(|map| map.get(&name.trim().to_ascii_lowercase()).cloned())
}

pub fn list_extensions() -> Vec<UserExtension> {
    with_extensions(|map| {
        let mut list: Vec<UserExtension> = map.values().cloned().collect();
        list.sort_by(|a, b| a.name.cmp(&b.name));
        list
    })
}

pub fn extension_count() -> usize {
    with_extensions(|map| map.len())
}

pub fn remove_extension(name: &str) -> bool {
    with_extensions_mut(|map| map.remove(&name.trim().to_ascii_lowercase()).is_some())
}

pub fn clear_extensions() {
    with_extensions_mut(|map| map.clear());
}

pub fn export_extensions_json() -> String {
    let list: Vec<Value> = list_extensions().into_iter().map(|e| e.to_json()).collect();
    serde_json::to_string_pretty(&list).unwrap_or_else(|_| "[]".to_string())
}

#[derive(Clone, Debug)]
pub struct BuildOutcome {
    pub title: String,
    pub summary: String,
    pub steps: Vec<String>,
    pub exact_result: Option<String>,
    pub evidence: Value,
    pub execution_micros: u128,
}

/// Evaluates a user-defined function call if the name matches a registered extension.
pub fn try_eval_user_function(name: &str, args: &[String], session: &mut Session) -> Option<Result<ExecutionResult, String>> {
    let mut ext = get_extension(name)?;
    if ext.kind != ExtensionKind::Function {
        return None;
    }
    if ext.params.len() != args.len() {
        return Some(Err(format!(
            "Extension '{}' expects {} arguments ({:?}), but {} were provided.",
            ext.name,
            ext.params.len(),
            ext.params,
            args.len()
        )));
    }

    // Increment call count
    ext.call_count += 1;
    register_extension(ext.clone());

    // Substitute parameters in body expression
    let mut substituted = ext.body.clone();
    for (param, arg) in ext.params.iter().zip(args.iter()) {
        substituted = substitute_param(&substituted, param, arg);
    }

    let started = Instant::now();
    let res = evaluate(&substituted, session);
    match res {
        Ok(mut exec_res) => {
            exec_res.execution_micros = started.elapsed().as_micros();
            Some(Ok(exec_res))
        }
        Err(err) => Some(Err(format!("Error executing extension '{}': {}", ext.name, err))),
    }
}

fn substitute_param(expr: &str, param: &str, value: &str) -> String {
    let mut result = String::new();
    let chars: Vec<char> = expr.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        if chars[i].is_ascii_alphabetic() || chars[i] == '_' {
            let mut j = i;
            while j < chars.len() && (chars[j].is_ascii_alphanumeric() || chars[j] == '_') {
                j += 1;
            }
            let word: String = chars[i..j].iter().collect();
            if word == param {
                result.push_str(&format!("({})", value));
            } else {
                result.push_str(&word);
            }
            i = j;
        } else {
            result.push(chars[i]);
            i += 1;
        }
    }
    result
}

/// Main Build command dispatcher: handles both natural language extension requests and explicit commands.
pub fn handle_build_command(prompt: &str, session: &mut Session) -> Result<BuildOutcome, String> {
    let started = Instant::now();
    let body = if prompt.starts_with("build ") {
        prompt["build ".len()..].trim()
    } else if prompt.starts_with("mirage ") {
        prompt["mirage ".len()..].trim()
    } else if prompt == "build" || prompt == "mirage" {
        ""
    } else {
        prompt.trim()
    };

    if body.is_empty() || body.eq_ignore_ascii_case("help") {
        return Ok(BuildOutcome {
            title: "CentL26 In-App Programmability & Extension Workbench".to_string(),
            summary: "CentL26 is designed to be hackable and extensible from inside the notebook. Speak or write your ideas in plain English or use explicit builder syntax.".to_string(),
            steps: vec![
                "• build fn KE(m, v) = 1/2 * m * v^2  (Define a reusable mathematical function)".to_string(),
                "• build unit au = 149597870700 m  (Define a custom physical unit)".to_string(),
                "• build const alpha = 1/137.036  (Define a custom scientific constant)".to_string(),
                "• build a formula for gravitational potential energy PE(m, g, h) = m * g * h".to_string(),
                "• build list  (View all active custom programs)".to_string(),
                "• build inspect <name>  (Examine extension source and test receipts)".to_string(),
                "• build test <name> <args...>  (Verify your extension against exact engine)".to_string(),
                "• build export  (Export your extensions in JSON schema)".to_string(),
                "• build clear  (Clear registered extensions)".to_string(),
            ],
            exact_result: Some(format!("{} active extensions registered", extension_count())),
            evidence: json!({
                "schema": "centl26.build-manifest/1",
                "active_extensions": extension_count(),
            }),
            execution_micros: started.elapsed().as_micros(),
        });
    }

    let lower = body.to_ascii_lowercase();

    // 1. List extensions
    if lower == "list" || lower == "extensions" || lower == "status" || lower == "all" {
        let exts = list_extensions();
        let mut steps = Vec::new();
        if exts.is_empty() {
            steps.push("No custom extensions registered in this session yet. Create one with 'build fn ...' or plain English.".to_string());
        } else {
            for ext in &exts {
                steps.push(format!("• [{}] {} - {}: {}", ext.kind, ext.name, ext.description, ext.doc));
            }
        }
        return Ok(BuildOutcome {
            title: format!("Registered User Extensions ({})", exts.len()),
            summary: format!("Total {} custom programs actively wired into the computation engine.", exts.len()),
            steps,
            exact_result: Some(format!("{} active", exts.len())),
            evidence: json!({
                "schema": "centl26.build-manifest/1",
                "extensions": exts.iter().map(|e| e.to_json()).collect::<Vec<_>>(),
            }),
            execution_micros: started.elapsed().as_micros(),
        });
    }

    // 2. Clear extensions
    if lower == "clear" || lower == "reset" {
        clear_extensions();
        return Ok(BuildOutcome {
            title: "User Extensions Cleared".to_string(),
            summary: "All active custom programs and extensions have been reset to pristine state.".to_string(),
            steps: vec!["Cleared session extension table.".to_string()],
            exact_result: Some("0 active extensions".to_string()),
            evidence: json!({ "schema": "centl26.build-manifest/1", "active_extensions": 0 }),
            execution_micros: started.elapsed().as_micros(),
        });
    }

    // 3. Export extensions
    if lower == "export" || lower == "export json" {
        let json_str = export_extensions_json();
        return Ok(BuildOutcome {
            title: "Export User Extensions".to_string(),
            summary: format!("Exported {} active extensions as JSON.", extension_count()),
            steps: vec![json_str.clone()],
            exact_result: Some(json_str),
            evidence: json!({ "schema": "centl26.build-manifest/1", "count": extension_count() }),
            execution_micros: started.elapsed().as_micros(),
        });
    }

    // 4. Inspect extension
    if lower.starts_with("inspect ") || lower.starts_with("show ") || lower.starts_with("view ") {
        let name = body.split_whitespace().nth(1).unwrap_or("").trim();
        if let Some(ext) = get_extension(name) {
            return Ok(BuildOutcome {
                title: format!("Extension Inspection: {}", ext.name),
                summary: format!("{}: {}", ext.kind, ext.description),
                steps: vec![
                    format!("Signature: {}", ext.doc),
                    format!("Parameters: {:?}", ext.params),
                    format!("Body expression: {}", ext.body),
                    format!("Invocations during session: {}", ext.call_count),
                ],
                exact_result: Some(ext.body.clone()),
                evidence: json!({
                    "schema": "centl26.build-manifest/1",
                    "extension": ext.to_json(),
                }),
                execution_micros: started.elapsed().as_micros(),
            });
        } else {
            return Err(format!("Extension '{}' not found in session registry. Use 'build list' to view all active extensions.", name));
        }
    }

    // 5. Remove extension
    if lower.starts_with("remove ") || lower.starts_with("delete ") || lower.starts_with("rm ") {
        let name = body.split_whitespace().nth(1).unwrap_or("").trim();
        if remove_extension(name) {
            return Ok(BuildOutcome {
                title: format!("Extension Removed: {}", name),
                summary: format!("Custom program '{}' was removed from the active registry.", name),
                steps: vec![format!("Unregistered '{}'. Remaining extensions: {}.", name, extension_count())],
                exact_result: Some(format!("Remaining: {}", extension_count())),
                evidence: json!({ "schema": "centl26.build-manifest/1", "removed": name }),
                execution_micros: started.elapsed().as_micros(),
            });
        } else {
            return Err(format!("Could not find extension '{}' to remove.", name));
        }
    }

    // 6. Test extension
    if lower.starts_with("test ") {
        let test_body = body[5..].trim();
        let (name, args) = if let Some(open_p) = test_body.find('(') {
            let n = test_body[..open_p].trim();
            let close_p = test_body.rfind(')').unwrap_or(test_body.len());
            let inner = &test_body[open_p + 1..close_p];
            let a: Vec<String> = inner.split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect();
            (n, a)
        } else {
            let parts: Vec<&str> = test_body.split_whitespace().collect();
            if parts.is_empty() {
                return Err("Usage: build test <extension_name> [arg1] [arg2]...".to_string());
            }
            let n = parts[0];
            let a: Vec<String> = parts[1..].iter().map(|s| s.to_string()).collect();
            (n, a)
        };
        match try_eval_user_function(name, &args, session) {
            Some(Ok(res)) => {
                return Ok(BuildOutcome {
                    title: format!("Extension Test Verified: {}({})", name, args.join(", ")),
                    summary: format!("Executed exact calculation with user extension '{}'.", name),
                    steps: vec![
                        format!("Inputs: {:?}", args),
                        format!("Exact result: {}", res.text),
                    ],
                    exact_result: Some(res.text),
                    evidence: json!({
                        "schema": "centl26.build-manifest/1",
                        "test_target": name,
                        "inputs": args,
                    }),
                    execution_micros: started.elapsed().as_micros(),
                });
            }
            Some(Err(e)) => return Err(e),
            None => return Err(format!("Extension '{}' not found or is not a callable function.", name)),
        }
    }

    // 7. Parse function definition: fn name(p1, p2) = expr OR plain English function synthesis
    if let Some(ext) = parse_function_definition(body) {
        let name = ext.name.clone();
        let doc = ext.doc.clone();
        let desc = ext.description.clone();
        let params = ext.params.clone();
        let body_expr = ext.body.clone();

        register_extension(ext.clone());

        return Ok(BuildOutcome {
            title: format!("User Extension Built: {}", name),
            summary: format!("Successfully synthesized and registered {}: '{}'", ext.kind, name),
            steps: vec![
                format!("Signature: {}", doc),
                format!("Parameters: {:?}", params),
                format!("Body: {}", body_expr),
                format!("Description: {}", desc),
                format!("You can now use '{}(...)' directly in your notebook calculations!", name),
            ],
            exact_result: Some(format!("Registered: {}", doc)),
            evidence: json!({
                "schema": "centl26.build-manifest/1",
                "registered": ext.to_json(),
                "status": "ready",
            }),
            execution_micros: started.elapsed().as_micros(),
        });
    }

    // 8. Parse custom constant definition: const name = expr
    if let Some(ext) = parse_constant_definition(body) {
        let name = ext.name.clone();
        let body_expr = ext.body.clone();
        register_extension(ext.clone());

        return Ok(BuildOutcome {
            title: format!("Custom Constant Built: {}", name),
            summary: format!("Registered scientific constant '{}' = {}", name, body_expr),
            steps: vec![
                format!("Constant: {}", name),
                format!("Value expression: {}", body_expr),
                format!("Available across your math and physics workflows."),
            ],
            exact_result: Some(format!("{} = {}", name, body_expr)),
            evidence: json!({
                "schema": "centl26.build-manifest/1",
                "registered": ext.to_json(),
            }),
            execution_micros: started.elapsed().as_micros(),
        });
    }

    // 9. Brainstorming / Conversational Extension Ideas
    if lower.contains("how would") || lower.contains("brainstorm") || lower.contains("idea") || lower.contains("design a") || lower.contains("model") {
        return Ok(BuildOutcome {
            title: "CentL26 Extension Brainstorming".to_string(),
            summary: format!("Brainstormed architectural plan for: \"{}\"", body),
            steps: vec![
                "1. Model Parameters: Identify physical and mathematical invariants (mass, velocity, constants, time step).".to_string(),
                "2. Symbolic Representation: Express core governing differential equations or algebraic formulas.".to_string(),
                "3. Custom Extension Synthesis: Register via 'build fn ...' to enable one-line notebook execution.".to_string(),
                format!("Suggested Next Command: build fn Model(x) = x^2 + 2*x + 1"),
            ],
            exact_result: Some("Brainstorm synthesis completed.".to_string()),
            evidence: json!({
                "schema": "centl26.build-manifest/1",
                "mode": "brainstorm",
                "query": body,
            }),
            execution_micros: started.elapsed().as_micros(),
        });
    }

    Err(format!(
        "Could not parse extension definition from: \"{}\".\nExamples:\n• build fn KE(m, v) = 1/2 * m * v^2\n• build a formula for kinetic energy KE(m, v) = 0.5 * m * v^2\n• build const G_earth = 9.80665\n• build list",
        body
    ))
}

fn parse_function_definition(text: &str) -> Option<UserExtension> {
    let clean = text.trim();

    // Syntax 1: fn Name(a, b) = expr  or  function Name(a, b) = expr  or  def Name(a, b) = expr
    let decl = if let Some(rest) = clean.strip_prefix("fn ") {
        rest
    } else if let Some(rest) = clean.strip_prefix("function ") {
        rest
    } else if let Some(rest) = clean.strip_prefix("def ") {
        rest
    } else if let Some(rest) = clean.strip_prefix("program ") {
        rest
    } else {
        clean
    };

    // Check if there is an '=' sign
    if let Some((sig_part, body_part)) = decl.split_once('=') {
        let sig = sig_part.trim();
        let body = body_part.trim();

        // Extract name and params from sig like "KE(m, v)" or "a formula for kinetic energy KE(m, v)"
        if let Some((name, params)) = extract_fn_sig(sig) {
            let desc = if sig.contains("formula for") || sig.contains("function to") || sig.contains("program to") {
                sig.to_string()
            } else {
                format!("User-defined function {}({})", name, params.join(", "))
            };
            return Some(UserExtension {
                name: name.clone(),
                kind: ExtensionKind::Function,
                params: params.clone(),
                body: body.to_string(),
                description: desc,
                doc: format!("{}({}) = {}", name, params.join(", "), body),
                call_count: 0,
            });
        }
    }

    None
}

fn extract_fn_sig(sig: &str) -> Option<(String, Vec<String>)> {
    let open = sig.rfind('(')?;
    let close = sig.rfind(')')?;
    if close <= open {
        return None;
    }

    let before_open = sig[..open].trim();
    // Name is the last word before '('
    let name = before_open.split_whitespace().last()?.trim();
    if name.is_empty() || !name.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') {
        return None;
    }

    let params_str = &sig[open + 1..close];
    let params: Vec<String> = params_str
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    Some((name.to_string(), params))
}

fn parse_constant_definition(text: &str) -> Option<UserExtension> {
    let clean = text.trim();
    let decl = if let Some(rest) = clean.strip_prefix("const ") {
        rest
    } else if let Some(rest) = clean.strip_prefix("constant ") {
        rest
    } else {
        return None;
    };

    if let Some((name_part, body_part)) = decl.split_once('=') {
        let name = name_part.trim().to_string();
        let body = body_part.trim().to_string();
        if !name.is_empty() && name.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') {
            return Some(UserExtension {
                name: name.clone(),
                kind: ExtensionKind::Constant,
                params: Vec::new(),
                body: body.clone(),
                description: format!("User-defined constant {}", name),
                doc: format!("const {} = {}", name, body),
                call_count: 0,
            });
        }
    }

    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn user_extension_lifecycle_and_evaluation() {
        let mut session = Session::new();

        // 1. Register a kinetic energy function via build syntax
        let outcome = handle_build_command("build fn KE(m, v) = 1/2 * m * v^2", &mut session).unwrap();
        assert_eq!(outcome.title, "User Extension Built: KE");
        assert!(extension_count() >= 1);

        // 2. Inspect
        let inspect = handle_build_command("build inspect KE", &mut session).unwrap();
        assert!(inspect.steps.iter().any(|s| s.contains("Signature: KE(m, v) = 1/2 * m * v^2")));

        // 3. Test execution
        let test_res = handle_build_command("build test KE 10 5", &mut session).unwrap();
        assert_eq!(test_res.exact_result.unwrap(), "125");

        // 4. Direct function execution via try_eval_user_function
        let direct_res = try_eval_user_function("KE", &["4".to_string(), "3".to_string()], &mut session).unwrap().unwrap();
        assert_eq!(direct_res.text, "18");

        // 5. Natural language build syntax
        let nl_res = handle_build_command("build a formula for potential energy PE(m, g, h) = m * g * h", &mut session).unwrap();
        assert_eq!(nl_res.title, "User Extension Built: PE");

        let pe_eval = try_eval_user_function("PE", &["2".to_string(), "9.8".to_string(), "5".to_string()], &mut session).unwrap().unwrap();
        assert!(pe_eval.text.contains("98"));

        // 6. List and export
        let list_res = handle_build_command("build list", &mut session).unwrap();
        assert!(list_res.steps.len() >= 2);

        let export_res = handle_build_command("build export", &mut session).unwrap();
        assert!(export_res.exact_result.unwrap().contains("KE"));

        // 7. Remove
        let rm_res = handle_build_command("build remove KE", &mut session).unwrap();
        assert!(rm_res.title.contains("Extension Removed"));
        assert!(get_extension("KE").is_none());
    }
}
