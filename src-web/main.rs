// CENTL Web Application & Hub Entrypoint
// Free Computation Foundation - Apache-2.0

pub mod engine;
pub mod erdos_straus;
pub mod physics;
pub mod server;

use engine::{evaluate, Session};
use server::{start_lab_server, start_server};
use std::env;
use std::path::Path;

fn print_help() {
    println!("CentL26 · Free Computation Foundation scientific work environment");
    println!("Usage:");
    println!("  centl-web                     start the Zero-JS web server on port 8080");
    println!("  centl-web --serve [PORT]      start web server on specified port");
    println!("  centl-web eval \"EXPRESSION\"   evaluate a mathematical expression");
    println!("  centl-web es solve <PRIME>    solve 4/p = 1/x + 1/y + 1/z");
    println!("  centl-web es hunt [FROM]      run public Erdős–Straus hunt window");
    println!("  centl-web physics convert V F T convert units");
    println!("  centl26 [PORT]                start the CentL26 local host (default: 2626)");
    println!("  centl-web --lab [PORT]        compatibility entry point for CentL26");
    println!("  centl-lab [PORT]              legacy compatibility alias");
    println!("  --version                     display version");
    println!();
    println!("Server environment:");
    println!("  CENTL_BIND_HOST               bind address (default: 127.0.0.1)");
    println!("  CENTL_SITE_DIR                static site directory (default: ./site or ../site)");
    println!();
    println!("CentL26 always binds to 127.0.0.1 and embeds its application assets.");
}

fn resolve_site_dir() -> Result<String, String> {
    if let Ok(configured) = env::var("CENTL_SITE_DIR") {
        if Path::new(&configured).is_dir() {
            return Ok(configured);
        }
        return Err(format!(
            "CENTL_SITE_DIR does not point to a directory: {}",
            configured
        ));
    }

    for candidate in ["site", "../site"] {
        if Path::new(candidate).is_dir() {
            return Ok(candidate.to_string());
        }
    }

    Err("CENTL site directory not found. Set CENTL_SITE_DIR explicitly.".to_string())
}

fn serve(port: u16) {
    let site_dir = match resolve_site_dir() {
        Ok(path) => path,
        Err(error) => {
            eprintln!("Failed to locate site directory: {}", error);
            std::process::exit(1);
        }
    };
    if let Err(error) = start_server(port, &site_dir) {
        eprintln!("Failed to start server on port {}: {}", port, error);
        std::process::exit(1);
    }
}

fn serve_lab(port: u16) {
    if let Err(error) = start_lab_server(port) {
        eprintln!("Failed to start CentL26 on port {}: {}", port, error);
        std::process::exit(1);
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut session = Session::new();

    if args.iter().any(|arg| arg == "--help" || arg == "-h") {
        print_help();
        return;
    }

    if args.iter().any(|arg| arg == "--version" || arg == "-v") {
        println!("CentL26 26.7.0 · backend compatibility 0.15 Al-Nur");
        return;
    }

    let invoked_as_lab = args
        .first()
        .and_then(|value| Path::new(value).file_stem())
        .and_then(|value| value.to_str())
        .is_some_and(|value| value == "centl-lab" || value == "centl26");
    if invoked_as_lab && (args.len() <= 1 || (args.len() == 2 && args[1].parse::<u16>().is_ok())) {
        let port = args
            .get(1)
            .and_then(|argument| argument.parse::<u16>().ok())
            .unwrap_or(2626);
        serve_lab(port);
        return;
    }

    if args.len() <= 1 {
        serve(8080);
        return;
    }

    match args[1].as_str() {
        "--serve" | "serve" => {
            let port = if args.len() >= 3 {
                args[2].parse::<u16>().unwrap_or(8080)
            } else {
                8080
            };
            serve(port);
        }
        "--lab" | "lab" => {
            let port = if args.len() >= 3 {
                args[2].parse::<u16>().unwrap_or(2626)
            } else {
                2626
            };
            serve_lab(port);
        }
        "--syntax" => {
            let result = evaluate(":syntax", &mut session).unwrap();
            println!("{}", result.text);
        }
        "eval" => {
            if args.len() >= 3 {
                let expression = args[2..].join(" ");
                match evaluate(&expression, &mut session) {
                    Ok(result) => println!("{}", result.text),
                    Err(error) => {
                        if let Ok(solution) = crate::engine::sci::solve_stem_offline(&expression, &mut session) {
                            println!("SCi Solution [{} · {}]:\n{}", solution.domain, solution.confidence, solution.summary);
                            for step in &solution.steps {
                                println!("• {}", step);
                            }
                            if let Some(ref exact) = solution.exact_result {
                                println!("\nExact Result: {}", exact);
                            }
                        } else {
                            eprintln!("Error: {}", error);
                            std::process::exit(1);
                        }
                    }
                }
            } else {
                eprintln!("Usage: centl-web eval \"EXPRESSION\"");
            }
        }
        "physics" | "chem" | "chemistry" | "build" | "sci" | "gemini" => {
            let full_cmd = args[1..].join(" ");
            let mut state = server::handler::AppState::new();
            let (exec, err, phys, hunt) = server::handler::handle_command(&full_cmd, &mut state);
            if let Some(e) = err {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            } else if let Some(p) = phys {
                println!("=== {} ===\n{}\nVerified SI Formulation: {}", p.title, p.summary, p.verified);
                for (k, v) in p.details {
                    println!("• {}: {}", k, v);
                }
            } else if let Some(res) = exec {
                println!("{}", res.text);
            } else if let Some(h) = hunt {
                println!("Hunt Window [{}, {}]: Checked {} primes", h.start_bound, h.end_bound, h.primes_checked);
            }
        }
        _ => {
            let expression = args[1..].join(" ");
            let mut state = server::handler::AppState::new();
            let (exec, err, phys, hunt) = server::handler::handle_command(&expression, &mut state);
            if let Some(res) = exec {
                println!("{}", res.text);
            } else if let Some(p) = phys {
                println!("=== {} ===\n{}\nVerified SI Formulation: {}", p.title, p.summary, p.verified);
                for (k, v) in p.details {
                    println!("• {}: {}", k, v);
                }
            } else if let Some(h) = hunt {
                println!("Hunt Window [{}, {}]: Checked {} primes", h.start_bound, h.end_bound, h.primes_checked);
            } else if let Some(e) = err {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::engine::rational::{BigInt, BigRational};
    use super::engine::{evaluate, Session};
    use super::erdos_straus::solve_es;
    use super::physics::convert_units;

    #[test]
    fn test_rational_arithmetic() {
        let a = BigRational::from_fraction(1, 3);
        let b = BigRational::from_fraction(5, 7);
        let sum = &a + &b;
        assert_eq!(sum, BigRational::from_fraction(22, 21));
    }

    #[test]
    fn test_large_integer_power() {
        let two = BigInt::from_i64(2);
        let p64 = two.pow(64);
        assert_eq!(p64.to_string(), "18446744073709551616");
    }

    #[test]
    fn test_symbolic_differentiation() {
        let mut session = Session::new();
        let result = evaluate("diff(x^3, x)", &mut session).unwrap();
        assert_eq!(result.text, "3 * x^2");
    }

    #[test]
    fn test_symbolic_integration() {
        let mut session = Session::new();
        let result = evaluate("integrate(3*x^2 + 2*x, x, 0, 5)", &mut session).unwrap();
        assert_eq!(result.text, "150");
    }

    #[test]
    fn test_solve_linear_equation() {
        let mut session = Session::new();
        let result = evaluate("solve(3*x - 12 = 0, x)", &mut session).unwrap();
        assert_eq!(result.text, "x = 4");
    }

    #[test]
    fn test_solve_quadratic_equation() {
        let mut session = Session::new();
        let result = evaluate("solve(x^2 - 5*x + 6 = 0, x)", &mut session).unwrap();
        assert!(result.text.contains("x = 3") && result.text.contains("x = 2"));
    }

    #[test]
    fn test_erdos_straus_solver() {
        let result = solve_es(1009);
        assert!(result.solved);
        let witness = result.witness.unwrap();
        assert!(witness.verify());
    }

    #[test]
    fn test_physics_conversion() {
        let result = convert_units(100.0, "cm", "m").unwrap();
        assert_eq!(result.summary, "100 cm = 1.00000000 m");
    }
}
