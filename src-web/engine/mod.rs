// CENTL Mathematical Engine Module
// Free Computation Foundation - Apache-2.0

pub mod functions;
pub mod numerics;
pub mod rational;
pub mod symbolic;

use functions::*;
use numerics::*;
use rational::{BigInt, BigRational};
use symbolic::{Expr, Parser};
use std::collections::HashMap;

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

    // Special REPL commands
    if trimmed.starts_with(':') {
        let elapsed = start_time.elapsed().as_micros();
        match trimmed {
            ":history" => {
                let items: Vec<String> = session.history.iter().map(|h| format!("  {} => {}", h.command, h.result)).collect();
                return Ok(ExecutionResult {
                    text: if items.is_empty() { "No history recorded.".to_string() } else { items.join("\n") },
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
            _ => return Err(format!("unknown command: {}", trimmed)),
        }
    }

    // Parse expression
    let expr = Parser::parse(trimmed)?;

    // Handle high-level commands embedded in expressions
    let result = match &expr {
        Expr::Function(name, args) => match name.as_str() {
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
                let root_strs: Vec<String> = roots.iter().map(|r| format!("{} = {}", var_name, r)).collect();
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
                            approximate: Some(format!("{} (enclosure precision: {} digits)", enclosure.value_str, digits)),
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
                        return Ok(ExecutionResult {
                            text,
                            exact_rational: Some(rat),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        });
                    }
                }
                return Err("factorial requires non-negative integer".to_string());
            }
            "fibonacci" if args.len() == 1 => {
                let arg_eval = eval_expr(&args[0], session)?;
                if let Expr::Number(n) = arg_eval {
                    if n.is_integer() && !n.is_negative() {
                        let u = n.numer.to_i64().unwrap_or(0) as u64;
                        let fib = fibonacci(u)?;
                        let rat = BigRational::from_bigint(fib);
                        let text = format!("{}", rat);
                        return Ok(ExecutionResult {
                            text,
                            exact_rational: Some(rat),
                            approximate: None,
                            symbolic_expr: None,
                            execution_micros: start_time.elapsed().as_micros(),
                        });
                    }
                }
                return Err("fibonacci requires non-negative integer".to_string());
            }
            "gcd" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    let g = BigInt::gcd(&na.numer, &nb.numer);
                    let rat = BigRational::from_bigint(g);
                    let text = format!("{}", rat);
                    return Ok(ExecutionResult {
                        text,
                        exact_rational: Some(rat),
                        approximate: None,
                        symbolic_expr: None,
                        execution_micros: start_time.elapsed().as_micros(),
                    });
                }
                return Err("gcd requires integers".to_string());
            }
            "lcm" if args.len() == 2 => {
                let a = eval_expr(&args[0], session)?;
                let b = eval_expr(&args[1], session)?;
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    let l = BigInt::lcm(&na.numer, &nb.numer);
                    let rat = BigRational::from_bigint(l);
                    let text = format!("{}", rat);
                    return Ok(ExecutionResult {
                        text,
                        exact_rational: Some(rat),
                        approximate: None,
                        symbolic_expr: None,
                        execution_micros: start_time.elapsed().as_micros(),
                    });
                }
                return Err("lcm requires integers".to_string());
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
