// CENTL Mathematical Engine Module
// Free Computation Foundation - Apache-2.0

pub mod extensions;
pub mod functions;
pub mod numerics;
pub mod plot;
pub mod rational;
pub mod sci;
pub mod symbolic;

use functions::*;
use numerics::*;
use rational::{BigInt, BigRational};
use std::collections::HashMap;
use symbolic::{Expr, Parser};

#[derive(Clone, Debug)]
pub struct Session {
    pub variables: HashMap<String, Expr>,
    pub history: Vec<HistoryEntry>,
}

#[derive(Clone, Debug)]
pub struct HistoryEntry {
    pub command: String,
    pub result: String,
    pub exact_repr: Option<String>,
    pub approximate_repr: Option<String>,
    pub execution_micros: u128,
    pub success: bool,
}

impl Session {
    pub fn new() -> Self {
        let mut variables = HashMap::new();
        variables.insert("pi".to_string(), Expr::Constant("pi".to_string()));
        variables.insert("e".to_string(), Expr::Constant("e".to_string()));
        variables.insert("tau".to_string(), Expr::Constant("tau".to_string()));
        Session {
            variables,
            history: Vec::new(),
        }
    }
}

#[derive(Clone, Debug)]
pub struct ExecutionResult {
    pub text: String,
    pub exact_rational: Option<BigRational>,
    pub approximate: Option<String>,
    pub symbolic_expr: Option<Expr>,
    pub execution_micros: u128,
}

pub fn evaluate(input: &str, session: &mut Session) -> Result<ExecutionResult, String> {
    let start_time = std::time::Instant::now();
    let trimmed = input.trim();

    if trimmed.is_empty() {
        return Ok(ExecutionResult {
            text: String::new(),
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: 0,
        });
    }

    // 2D ASCII / Unicode Plotting
    if trimmed.starts_with("plot ") || trimmed.starts_with("plot(") || trimmed == "plot" {
        let plot_text = plot::handle_plot_command(trimmed)?;
        let elapsed = start_time.elapsed().as_micros();
        let res = ExecutionResult {
            text: plot_text,
            exact_rational: None,
            approximate: None,
            symbolic_expr: None,
            execution_micros: elapsed,
        };
        session.history.push(HistoryEntry {
            command: trimmed.to_string(),
            result: "2D Function Plot".to_string(),
            exact_repr: None,
            approximate_repr: None,
            execution_micros: elapsed,
            success: true,
        });
        return Ok(res);
    }

    // Special REPL commands
    if trimmed.starts_with(':') {
        let elapsed = start_time.elapsed().as_micros();
        match trimmed {
            ":history" => {
                let items: Vec<String> = session
                    .history
                    .iter()
                    .map(|h| format!("  {} => {}", h.command, h.result))
                    .collect();
                return Ok(ExecutionResult {
                    text: if items.is_empty() {
                        "No history recorded.".to_string()
                    } else {
                        items.join("\n")
                    },
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: elapsed,
                });
            }
            ":clear-history" | ":clear" => {
                session.history.clear();
                return Ok(ExecutionResult {
                    text: "Calculator history cleared.".to_string(),
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: elapsed,
                });
            }
            ":syntax" => {
                return Ok(ExecutionResult {
                    text: "CENTL Mathematical Syntax:\n  Values: 123, 0.125, 1/3, pi, e, tau\n  Arithmetic: +, -, *, /, ^\n  Functions: sqrt, abs, exp, log, sin, cos, tan, asin, acos, atan, sinh, cosh, tanh\n  Symbolic: diff(f, x), integrate(f, x, a, b), solve(lhs = rhs, x), simplify(f), expand(f), factor(f)\n  Combinatorics: gcd(a, b), lcm(a, b), factorial(n), choose(n, k), fibonacci(n)\n  Approximation: approx(expr, digits)\n  Hunt: es solve <p>, es hunt, es status".to_string(),
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: elapsed,
                });
            }
            ":help" => {
                return Ok(ExecutionResult {
                    text: "CENTL Exact Mathematics & Physics Hub\nEnter any mathematical expression, equation, or command.\nExact integers and fractions are computed without precision loss.\nApproximations carry rigorous justified enclosures.".to_string(),
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: elapsed,
                });
            }
            ":vars" | ":variables" => {
                let mut entries: Vec<String> = session
                    .variables
                    .iter()
                    .map(|(k, v)| format!("  {} = {}", k, v))
                    .collect();
                entries.sort();
                return Ok(ExecutionResult {
                    text: if entries.is_empty() {
                        "No variables defined in session.".to_string()
                    } else {
                        format!("Session Variables:\n{}", entries.join("\n"))
                    },
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: elapsed,
                });
            }
            _ => return Err(format!("unknown command: {}", trimmed)),
        }
    }

    // Check for explicit "define" prefix
    let expr_str = if let Some(stripped) = trimmed.strip_prefix("define ") {
        stripped.trim()
    } else {
        trimmed
    };

    // Parse expression
    let expr = Parser::parse(expr_str)?;

    // Handle variable assignments: var = expr
    if let Expr::Equation(lhs, rhs) = &expr {
        if let Expr::Variable(var_name) = lhs.as_ref() {
            let eval_rhs = eval_expr(rhs, session)?;
            let text = format!("{} = {}", var_name, eval_rhs);
            let exact = match &eval_rhs {
                Expr::Number(n) => Some(n.clone()),
                _ => None,
            };
            session.variables.insert(var_name.clone(), eval_rhs.clone());
            let exec_res = ExecutionResult {
                text,
                exact_rational: exact,
                approximate: None,
                symbolic_expr: Some(Expr::Equation(lhs.clone(), Box::new(eval_rhs))),
                execution_micros: start_time.elapsed().as_micros(),
            };
            session.history.push(HistoryEntry {
                command: trimmed.to_string(),
                result: exec_res.text.clone(),
                exact_repr: exec_res.exact_rational.as_ref().map(|r| format!("{}", r)),
                approximate_repr: None,
                execution_micros: exec_res.execution_micros,
                success: true,
            });
            return Ok(exec_res);
        }
    }

    // Check if the command is a top-level user function call
    if let Expr::Function(name, args) = &expr {
        if let Some(ext) = extensions::get_extension(name) {
            if ext.kind == extensions::ExtensionKind::Function && ext.params.len() == args.len() {
                let evaluated_args: Result<Vec<String>, String> = args.iter().map(|arg| {
                    let eval = eval_expr(arg, session)?;
                    Ok(format!("{}", eval))
                }).collect();
                if let Ok(arg_strs) = evaluated_args {
                    if let Some(res) = extensions::try_eval_user_function(name, &arg_strs, session) {
                        let exec_res = res?;
                        session.history.push(HistoryEntry {
                            command: trimmed.to_string(),
                            result: exec_res.text.clone(),
                            exact_repr: exec_res.exact_rational.as_ref().map(|r| format!("{}", r)),
                            approximate_repr: exec_res.approximate.clone(),
                            execution_micros: exec_res.execution_micros,
                            success: true,
                        });
                        return Ok(exec_res);
                    }
                }
            }
        }
    }

    // Handle high-level commands embedded in expressions
    let result = match &expr {
        Expr::Function(name, args) => match name.as_str() {
            "assert" | "verify" if args.len() >= 1 => {
                let target = &args[0];
                let (lhs, rhs) = match target {
                    Expr::Equation(l, r) => (eval_expr(l, session)?, eval_expr(r, session)?),
                    other => (eval_expr(other, session)?, Expr::num(0)),
                };
                let diff = Expr::Sub(Box::new(lhs.expand()), Box::new(rhs.expand())).simplify();
                let verified = diff.is_zero();
                let text = if verified {
                    format!("assert({}): verified", target)
                } else {
                    format!("assert({}): refuted", target)
                };
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: Some(diff),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "expand" if args.len() == 1 => {
                let eval = eval_expr(&args[0], session)?;
                let exp = eval.expand().simplify();
                let text = format!("{}", exp);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: Some(exp),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "factor" if args.len() >= 1 => {
                let eval = eval_expr(&args[0], session)?;
                let var_name = if args.len() >= 2 {
                    match &args[1] {
                        Expr::Variable(v) => v.as_str(),
                        _ => "x",
                    }
                } else {
                    "x"
                };
                let factored = eval.factor(var_name)?;
                let text = format!("{}", factored);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: Some(factored),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "simplify" if args.len() == 1 => {
                let eval = eval_expr(&args[0], session)?;
                let simplified = eval.simplify();
                let text = format!("{}", simplified);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: Some(simplified),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "choose" | "nCr" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    if na.is_integer() && !na.is_negative() && nb.is_integer() && !nb.is_negative() {
                        let n = na.numer.to_i64().unwrap_or(0) as u64;
                        let k = nb.numer.to_i64().unwrap_or(0) as u64;
                        let c = choose(n, k)?;
                        let rat = BigRational::from_bigint(c);
                        let text = format!("{}", rat);
                        ExecutionResult {
                            text,
                            exact_rational: Some(rat),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("choose requires non-negative integers".to_string());
                    }
                } else {
                    return Err("choose requires integers".to_string());
                }
            }
            "permutations" | "nPr" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    if na.is_integer() && !na.is_negative() && nb.is_integer() && !nb.is_negative() {
                        let n = na.numer.to_i64().unwrap_or(0) as u64;
                        let k = nb.numer.to_i64().unwrap_or(0) as u64;
                        let p = permutations(n, k)?;
                        let rat = BigRational::from_bigint(p);
                        let text = format!("{}", rat);
                        ExecutionResult {
                            text,
                            exact_rational: Some(rat),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("permutations requires non-negative integers".to_string());
                    }
                } else {
                    return Err("permutations requires integers".to_string());
                }
            }
            "is_prime" if args.len() == 1 => {
                let a = eval_expr(&args[0], session)?;
                if let Expr::Number(na) = a {
                    if na.is_integer() && !na.is_negative() {
                        let n = na.numer.to_i64().unwrap_or(0) as u64;
                        let p = is_prime(n);
                        let text = if p { "true".to_string() } else { "false".to_string() };
                        ExecutionResult {
                            text,
                            exact_rational: None,
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("is_prime requires non-negative integer".to_string());
                    }
                } else {
                    return Err("is_prime requires integer".to_string());
                }
            }
            "factors" if args.len() == 1 => {
                let a = eval_expr(&args[0], session)?;
                if let Expr::Number(na) = a {
                    if na.is_integer() && !na.is_negative() {
                        let n = na.numer.to_i64().unwrap_or(0) as u64;
                        let f_list = factors(n);
                        let text = f_list.iter().map(|f| f.to_string()).collect::<Vec<_>>().join(", ");
                        ExecutionResult {
                            text,
                            exact_rational: None,
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("factors requires non-negative integer".to_string());
                    }
                } else {
                    return Err("factors requires integer".to_string());
                }
            }
            "prime_factors" if args.len() == 1 => {
                let a = eval_expr(&args[0], session)?;
                if let Expr::Number(na) = a {
                    if na.is_integer() && !na.is_negative() {
                        let n = na.numer.to_i64().unwrap_or(0) as u64;
                        let pf = prime_factors(n);
                        let parts: Vec<String> = pf.iter().map(|(p, count)| {
                            if *count == 1 {
                                p.to_string()
                            } else {
                                format!("{}^{}", p, count)
                            }
                        }).collect();
                        let text = if parts.is_empty() { "1".to_string() } else { parts.join(" * ") };
                        ExecutionResult {
                            text,
                            exact_rational: None,
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("prime_factors requires non-negative integer".to_string());
                    }
                } else {
                    return Err("prime_factors requires integer".to_string());
                }
            }
            "diff" if args.len() >= 2 => {
                let target = &args[0];
                let var_name = match &args[1] {
                    Expr::Variable(v) => v.as_str(),
                    _ => "x",
                };
                let d = target.diff(var_name);
                ExecutionResult {
                    text: format!("{}", d),
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: Some(d),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "integrate" if args.len() == 2 => {
                let target = &args[0];
                let var_name = match &args[1] {
                    Expr::Variable(v) => v.as_str(),
                    _ => "x",
                };
                let anti = target.integrate(var_name)?;
                ExecutionResult {
                    text: format!("{} + C", anti),
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: Some(anti),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "integrate" if args.len() >= 4 => {
                let target = &args[0];
                let var_name = match &args[1] {
                    Expr::Variable(v) => v.as_str(),
                    _ => "x",
                };
                let lower = &args[2];
                let upper = &args[3];
                let def = target.integrate_definite(var_name, lower, upper)?;
                let text = format!("{}", def);
                let exact = match &def {
                    Expr::Number(n) => Some(n.clone()),
                    _ => None,
                };
                ExecutionResult {
                    text,
                    exact_rational: exact,
                    approximate: None,
                    symbolic_expr: Some(def),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "solve" if args.len() >= 1 => {
                let target = &args[0];
                let var_name = if args.len() >= 2 {
                    match &args[1] {
                        Expr::Variable(v) => v.as_str(),
                        _ => "x",
                    }
                } else {
                    "x"
                };
                let roots = target.solve(var_name)?;
                let root_strs: Vec<String> = roots
                    .iter()
                    .map(|r| format!("{} = {}", var_name, r))
                    .collect();
                ExecutionResult {
                    text: root_strs.join(", "),
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "approx" if args.len() >= 1 => {
                let digits = if args.len() >= 2 {
                    match &args[1] {
                        Expr::Number(n) => n.numer.to_i64().unwrap_or(20) as usize,
                        _ => 20,
                    }
                } else {
                    20
                };
                let evaluated = eval_expr(&args[0], session)?;
                match evaluated {
                    Expr::Number(n) => {
                        let enclosure = Enclosure::from_rational(&n, digits);
                        ExecutionResult {
                            text: enclosure.value_str.clone(),
                            exact_rational: Some(n),
                            approximate: Some(format!(
                                "{} (enclosure precision: {} digits)",
                                enclosure.value_str, digits
                            )),
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    }
                    Expr::Constant(c) if c == "pi" => {
                        let val = compute_pi(digits);
                        ExecutionResult {
                            text: val.clone(),
                            exact_rational: None,
                            approximate: Some(val),
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    }
                    Expr::Constant(c) if c == "e" => {
                        let val = compute_e(digits);
                        ExecutionResult {
                            text: val.clone(),
                            exact_rational: None,
                            approximate: Some(val),
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    }
                    _ => {
                        let text = format!("{}", evaluated);
                        ExecutionResult {
                            text,
                            exact_rational: None,
                            approximate: None,
                            symbolic_expr: Some(evaluated),
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    }
                }
            }
            "factorial" if args.len() == 1 => {
                let arg_eval = eval_expr(&args[0], session)?;
                if let Expr::Number(n) = arg_eval {
                    if n.is_integer() && !n.is_negative() {
                        let u = n.numer.to_i64().unwrap_or(0) as u64;
                        let fact = factorial(u)?;
                        let rat = BigRational::from_bigint(fact);
                        let text = format!("{}", rat);
                        ExecutionResult {
                            text,
                            exact_rational: Some(rat),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("factorial requires non-negative integer".to_string());
                    }
                } else {
                    return Err("factorial requires non-negative integer".to_string());
                }
            }
            "fibonacci" if args.len() == 1 => {
                let arg_eval = eval_expr(&args[0], session)?;
                if let Expr::Number(n) = arg_eval {
                    if n.is_integer() && !n.is_negative() {
                        let u = n.numer.to_i64().unwrap_or(0) as u64;
                        let fib = fibonacci(u)?;
                        let rat = BigRational::from_bigint(fib);
                        let text = format!("{}", rat);
                        ExecutionResult {
                            text,
                            exact_rational: Some(rat),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("fibonacci requires non-negative integer".to_string());
                    }
                } else {
                    return Err("fibonacci requires non-negative integer".to_string());
                }
            }
            "gcd" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    let g = BigInt::gcd(&na.numer, &nb.numer);
                    let rat = BigRational::from_bigint(g);
                    let text = format!("{}", rat);
                    ExecutionResult {
                        text,
                        exact_rational: Some(rat),
                        approximate: None,
                        symbolic_expr: None,
                        execution_micros: start_time.elapsed().as_micros(),
                    }
                } else {
                    return Err("gcd requires integers".to_string());
                }
            }
            "lcm" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    let l = BigInt::lcm(&na.numer, &nb.numer);
                    let rat = BigRational::from_bigint(l);
                    let text = format!("{}", rat);
                    ExecutionResult {
                        text,
                        exact_rational: Some(rat),
                        approximate: None,
                        symbolic_expr: None,
                        execution_micros: start_time.elapsed().as_micros(),
                    }
                } else {
                    return Err("lcm requires integers".to_string());
                }
            }
            "xgcd" | "extgcd" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    if na.is_integer() && nb.is_integer() {
                        let ai = na.numer.to_i64().unwrap_or(0);
                        let bi = nb.numer.to_i64().unwrap_or(0);
                        let (g, x, y) = xgcd(ai, bi);
                        let text = format!("gcd = {}, x = {}, y = {} ({}*{} + {}*{} = {})", g, x, y, ai, x, bi, y, g);
                        ExecutionResult {
                            text,
                            exact_rational: Some(BigRational::from_i64(g)),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("xgcd requires integers".to_string());
                    }
                } else {
                    return Err("xgcd requires integer arguments".to_string());
                }
            }
            "modinv" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    if na.is_integer() && nb.is_integer() {
                        let ai = na.numer.to_i64().unwrap_or(0);
                        let mi = nb.numer.to_i64().unwrap_or(0);
                        let inv = modinv(ai, mi)?;
                        let text = format!("{}", inv);
                        ExecutionResult {
                            text,
                            exact_rational: Some(BigRational::from_i64(inv)),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("modinv requires integers".to_string());
                    }
                } else {
                    return Err("modinv requires integer arguments".to_string());
                }
            }
            "modpow" if args.len() == 3 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                let c = eval_expr(&args[2], session)?;
                if let (Expr::Number(na), Expr::Number(nb), Expr::Number(nc)) = (a, b, c) {
                    if na.is_integer() && nb.is_integer() && nc.is_integer() && !na.is_negative() && !nb.is_negative() && !nc.is_negative() {
                        let base = na.numer.to_i64().unwrap_or(0) as u64;
                        let exp = nb.numer.to_i64().unwrap_or(0) as u64;
                        let m = nc.numer.to_i64().unwrap_or(0) as u64;
                        let res = modpow(base, exp, m);
                        let text = format!("{}", res);
                        ExecutionResult {
                            text,
                            exact_rational: Some(BigRational::from_u64(res)),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("modpow requires non-negative integers".to_string());
                    }
                } else {
                    return Err("modpow requires integer arguments".to_string());
                }
            }
            "totient" | "phi" if args.len() == 1 => {
                let a = eval_expr(&args[0], session)?;
                if let Expr::Number(na) = a {
                    if na.is_integer() && !na.is_negative() {
                        let n = na.numer.to_i64().unwrap_or(0) as u64;
                        let t = totient(n);
                        let text = format!("{}", t);
                        ExecutionResult {
                            text,
                            exact_rational: Some(BigRational::from_u64(t)),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        }
                    } else {
                        return Err("totient requires non-negative integer".to_string());
                    }
                } else {
                    return Err("totient requires integer".to_string());
                }
            }
            "det2" if args.len() == 4 => {
                let a = eval_expr(&args[0], session)?.to_f64()?;
                let b = eval_expr(&args[1], session)?.to_f64()?;
                let c = eval_expr(&args[2], session)?.to_f64()?;
                let d = eval_expr(&args[3], session)?.to_f64()?;
                let res = det2(a, b, c, d);
                let text = format!("{}", res);
                ExecutionResult {
                    text,
                    exact_rational: BigRational::from_f64(res),
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "inv2" if args.len() == 4 => {
                let a = eval_expr(&args[0], session)?.to_f64()?;
                let b = eval_expr(&args[1], session)?.to_f64()?;
                let c = eval_expr(&args[2], session)?.to_f64()?;
                let d = eval_expr(&args[3], session)?.to_f64()?;
                let inv = inv2(a, b, c, d)?;
                let text = format!("[[{:.6}, {:.6}], [{:.6}, {:.6}]]", inv[0], inv[1], inv[2], inv[3]);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "dot" if args.len() == 6 => {
                let x1 = eval_expr(&args[0], session)?.to_f64()?;
                let y1 = eval_expr(&args[1], session)?.to_f64()?;
                let z1 = eval_expr(&args[2], session)?.to_f64()?;
                let x2 = eval_expr(&args[3], session)?.to_f64()?;
                let y2 = eval_expr(&args[4], session)?.to_f64()?;
                let z2 = eval_expr(&args[5], session)?.to_f64()?;
                let dot = dot3((x1, y1, z1), (x2, y2, z2));
                let text = format!("{}", dot);
                ExecutionResult {
                    text,
                    exact_rational: BigRational::from_f64(dot),
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "cross" if args.len() == 6 => {
                let x1 = eval_expr(&args[0], session)?.to_f64()?;
                let y1 = eval_expr(&args[1], session)?.to_f64()?;
                let z1 = eval_expr(&args[2], session)?.to_f64()?;
                let x2 = eval_expr(&args[3], session)?.to_f64()?;
                let y2 = eval_expr(&args[4], session)?.to_f64()?;
                let z2 = eval_expr(&args[5], session)?.to_f64()?;
                let c = cross3((x1, y1, z1), (x2, y2, z2));
                let text = format!("({:.6}, {:.6}, {:.6})", c.0, c.1, c.2);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: None,
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "norm" if args.len() == 3 => {
                let x = eval_expr(&args[0], session)?.to_f64()?;
                let y = eval_expr(&args[1], session)?.to_f64()?;
                let z = eval_expr(&args[2], session)?.to_f64()?;
                let n = norm3((x, y, z));
                let text = format!("{:.8}", n);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: Some(format!("{:.8}", n)),
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "mean" if !args.is_empty() => {
                let mut vals = Vec::new();
                for a in args {
                    vals.push(eval_expr(a, session)?.to_f64()?);
                }
                let m = mean(&vals)?;
                let text = format!("{:.8}", m);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: Some(format!("{:.8}", m)),
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "variance" if !args.is_empty() => {
                let mut vals = Vec::new();
                for a in args {
                    vals.push(eval_expr(a, session)?.to_f64()?);
                }
                let v = variance(&vals)?;
                let text = format!("{:.8}", v);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: Some(format!("{:.8}", v)),
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "stddev" if !args.is_empty() => {
                let mut vals = Vec::new();
                for a in args {
                    vals.push(eval_expr(a, session)?.to_f64()?);
                }
                let s = stddev(&vals)?;
                let text = format!("{:.8}", s);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: Some(format!("{:.8}", s)),
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "normal_pdf" if args.len() == 3 => {
                let x = eval_expr(&args[0], session)?.to_f64()?;
                let mu = eval_expr(&args[1], session)?.to_f64()?;
                let sigma = eval_expr(&args[2], session)?.to_f64()?;
                let pdf = normal_pdf(x, mu, sigma)?;
                let text = format!("{:.8}", pdf);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: Some(format!("{:.8}", pdf)),
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            "normal_cdf" if args.len() == 3 => {
                let x = eval_expr(&args[0], session)?.to_f64()?;
                let mu = eval_expr(&args[1], session)?.to_f64()?;
                let sigma = eval_expr(&args[2], session)?.to_f64()?;
                let cdf = normal_cdf(x, mu, sigma)?;
                let text = format!("{:.8}", cdf);
                ExecutionResult {
                    text,
                    exact_rational: None,
                    approximate: Some(format!("{:.8}", cdf)),
                    symbolic_expr: None,
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
            _ => {
                let eval = eval_expr(&expr, session)?;
                let text = format!("{}", eval);
                let exact = match &eval {
                    Expr::Number(n) => Some(n.clone()),
                    _ => None,
                };
                ExecutionResult {
                    text,
                    exact_rational: exact,
                    approximate: None,
                    symbolic_expr: Some(eval),
                    execution_micros: start_time.elapsed().as_micros(),
                }
            }
        },
        _ => {
            let eval = eval_expr(&expr, session)?;
            let text = format!("{}", eval);
            let exact = match &eval {
                Expr::Number(n) => Some(n.clone()),
                _ => None,
            };
            ExecutionResult {
                text,
                exact_rational: exact,
                approximate: None,
                symbolic_expr: Some(eval),
                execution_micros: start_time.elapsed().as_micros(),
            }
        }
    };

    // Save to session history
    session.history.push(HistoryEntry {
        command: trimmed.to_string(),
        result: result.text.clone(),
        exact_repr: result.exact_rational.as_ref().map(|r| format!("{}", r)),
        approximate_repr: result.approximate.clone(),
        execution_micros: result.execution_micros,
        success: true,
    });

    Ok(result)
}

fn eval_expr(expr: &Expr, session: &Session) -> Result<Expr, String> {
    match expr {
        Expr::Number(n) => Ok(Expr::Number(n.clone())),
        Expr::Constant(c) => Ok(Expr::Constant(c.clone())),
        Expr::Variable(v) => {
            if let Some(val) = session.variables.get(v) {
                Ok(val.clone())
            } else if let Some(ext) = extensions::get_extension(v) {
                if ext.kind == extensions::ExtensionKind::Constant {
                    if let Ok(parsed) = Parser::parse(&ext.body) {
                        eval_expr(&parsed, session)
                    } else {
                        Ok(Expr::Variable(v.clone()))
                    }
                } else {
                    Ok(Expr::Variable(v.clone()))
                }
            } else {
                Ok(Expr::Variable(v.clone()))
            }
        }
        Expr::Neg(inner) => {
            let eval_inner = eval_expr(inner, session)?;
            match eval_inner {
                Expr::Number(n) => Ok(Expr::Number(-n)),
                _ => Ok(Expr::Neg(Box::new(eval_inner))),
            }
        }
        Expr::Add(a, b) => {
            let ea = eval_expr(a, session)?;
            let eb = eval_expr(b, session)?;
            match (ea, eb) {
                (Expr::Number(na), Expr::Number(nb)) => Ok(Expr::Number(&na + &nb)),
                (ea, eb) => Ok(Expr::Add(Box::new(ea), Box::new(eb)).simplify()),
            }
        }
        Expr::Sub(a, b) => {
            let ea = eval_expr(a, session)?;
            let eb = eval_expr(b, session)?;
            match (ea, eb) {
                (Expr::Number(na), Expr::Number(nb)) => Ok(Expr::Number(&na - &nb)),
                (ea, eb) => Ok(Expr::Sub(Box::new(ea), Box::new(eb)).simplify()),
            }
        }
        Expr::Mul(a, b) => {
            let ea = eval_expr(a, session)?;
            let eb = eval_expr(b, session)?;
            match (ea, eb) {
                (Expr::Number(na), Expr::Number(nb)) => Ok(Expr::Number(&na * &nb)),
                (ea, eb) => Ok(Expr::Mul(Box::new(ea), Box::new(eb)).simplify()),
            }
        }
        Expr::Div(a, b) => {
            let ea = eval_expr(a, session)?;
            let eb = eval_expr(b, session)?;
            match (ea, eb) {
                (Expr::Number(na), Expr::Number(nb)) => {
                    if nb.is_zero() {
                        return Err("division by zero in exact rational calculation".to_string());
                    }
                    Ok(Expr::Number(&na / &nb))
                }
                (ea, eb) => Ok(Expr::Div(Box::new(ea), Box::new(eb)).simplify()),
            }
        }
        Expr::Pow(base, exp) => {
            let ebase = eval_expr(base, session)?;
            match ebase {
                Expr::Number(n) => {
                    let res = n.pow(*exp)?;
                    Ok(Expr::Number(res))
                }
                _ => Ok(Expr::Pow(Box::new(ebase), *exp)),
            }
        }
        Expr::Function(name, args) => {
            let mut eval_args = Vec::new();
            for a in args {
                eval_args.push(eval_expr(a, session)?);
            }
            if let Some(ext) = extensions::get_extension(name) {
                if ext.kind == extensions::ExtensionKind::Function && ext.params.len() == eval_args.len() {
                    let mut substituted = ext.body.clone();
                    for (param, arg) in ext.params.iter().zip(eval_args.iter()) {
                        substituted = substituted.replace(param, &format!("({})", arg));
                    }
                    if let Ok(parsed) = Parser::parse(&substituted) {
                        return eval_expr(&parsed, session);
                    }
                }
            }
            if eval_args.len() == 1 {
                if let Expr::Number(n) = &eval_args[0] {
                    if name == "abs" {
                        return Ok(Expr::Number(n.abs()));
                    }
                    if name == "sqrt" && n.denom.is_one() && !n.is_negative() {
                        if let Some(i) = n.numer.to_i64() {
                            let sq = (i as f64).sqrt() as i64;
                            if sq * sq == i {
                                return Ok(Expr::num(sq));
                            }
                        }
                    }
                }
            }
            Ok(Expr::Function(name.clone(), eval_args).simplify())
        }
        Expr::Equation(l, r) => {
            let el = eval_expr(l, session)?;
            let er = eval_expr(r, session)?;
            Ok(Expr::Equation(Box::new(el), Box::new(er)))
        }
    }
}

#[cfg(test)]
mod admission_tests {
    use super::{evaluate, Session};

    #[test]
    fn combinatoric_results_share_the_normal_history_admission_path() {
        for (command, expected) in [
            ("factorial(6)", "720"),
            ("fibonacci(10)", "55"),
            ("gcd(84, 30)", "6"),
            ("lcm(12, 18)", "36"),
        ] {
            let mut session = Session::new();
            let result = evaluate(command, &mut session).unwrap();
            assert_eq!(result.text, expected);
            assert_eq!(session.history.len(), 1, "{command} was not admitted");
            assert_eq!(session.history[0].command, command);
            assert_eq!(session.history[0].result, expected);
        }
    }
}
