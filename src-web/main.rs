// CENTL Web Application & Hub Entrypoint
// Free Computation Foundation - Apache-2.0

pub mod engine;
pub mod erdos_straus;
pub mod physics;
pub mod server;

use engine::{evaluate, Session};
use erdos_straus::{run_hunt_window, solve_es};
use physics::convert_units;
use server::start_server;
use std::env;

fn print_help() {
    println!("CENTL v0.15.0 Al-Nur · Exact Mathematics, Physics & Zero-JS Web Hub");
    println!("Usage:");
    println!("  centl-web                     start the Zero-JS web server on port 8080");
    println!("  centl-web --serve [PORT]      start web server on specified port");
    println!("  centl-web eval \"EXPRESSION\"   evaluate a mathematical expression");
    println!("  centl-web es solve <PRIME>    solve 4/p = 1/x + 1/y + 1/z");
    println!("  centl-web es hunt [FROM]      run public Erdős–Straus hunt window");
    println!("  centl-web physics convert V F T convert units");
    println!("  centl-web --syntax            list supported syntax");
    println!("  --version                     display version");
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut session = Session::new();

    if args.len() <= 1 {
        // Default: Start web server
        let port = 8080;
        let site_dir = if std::path::Path::new("site").is_dir() {
            "site"
        } else if std::path::Path::new("../site").is_dir() {
            "../site"
        } else {
            "."
        };
        if let Err(e) = start_server(port, site_dir) {
            eprintln!("Failed to start server on port {}: {}", port, e);
            std::process::exit(1);
        }
        return;
    }

    match args[1].as_str() {
        "--help" | "-h" => {
            print_help();
        }
        "--version" | "-v" => {
            println!("centl-web 0.15.0 (Oasis Al-Nur)");
        }
        "--serve" | "serve" => {
            let port = if args.len() >= 3 {
                args[2].parse::<u16>().unwrap_or(8080)
            } else {
                8080
            };
            let site_dir = if std::path::Path::new("site").is_dir() {
                "site"
            } else if std::path::Path::new("../site").is_dir() {
                "../site"
            } else {
                "."
            };
            if let Err(e) = start_server(port, site_dir) {
                eprintln!("Failed to start server on port {}: {}", port, e);
                std::process::exit(1);
            }
        }
        "--syntax" => {
            let res = evaluate(":syntax", &mut session).unwrap();
            println!("{}", res.text);
        }
        "eval" => {
            if args.len() >= 3 {
                let expr = args[2..].join(" ");
                match evaluate(&expr, &mut session) {
                    Ok(res) => println!("{}", res.text),
                    Err(e) => {
                        eprintln!("Error: {}", e);
                        std::process::exit(1);
                    }
                }
            } else {
                eprintln!("Usage: centl-web eval \"EXPRESSION\"");
            }
        }
        "es" | "erdos" => {
            if args.len() >= 4 && args[2] == "solve" {
                if let Ok(p) = args[3].parse::<u64>() {
                    let res = solve_es(p);
                    if let Some(w) = res.witness {
                        println!("{}\nGrade: {} · Layer: {} · Kind: {}", w.equation(), res.grade.to_uppercase(), w.layer, w.kind);
                    } else {
                        println!("Prime {} unsolved in window. Grade: {}", p, res.grade);
                    }
                } else {
                    eprintln!("Invalid prime number: {}", args[3]);
                }
            } else if args.len() >= 3 && args[2] == "hunt" {
                let from = if args.len() >= 4 {
                    args[3].parse::<u64>().unwrap_or(20000)
                } else {
                    20000
                };
                let summary = run_hunt_window(from, 50000, 50);
                println!("Public Hunt Window [{}, {}]: Checked {} primes.", summary.start_bound, summary.end_bound, summary.primes_checked);
                println!("GREAT: {} | GOOD: {} | LETTER: {} | UNSOLVED: {}", summary.great_count, summary.good_count, summary.letter_count, summary.unsolved_count);
            } else {
                eprintln!("Usage: centl-web es solve <p> | centl-web es hunt [from]");
            }
        }
        "physics" => {
            if args.len() >= 5 && args[2] == "convert" {
                if let Ok(v) = args[3].parse::<f64>() {
                    match convert_units(v, &args[4], &args[5]) {
                        Ok(res) => println!("{}", res.summary),
                        Err(e) => eprintln!("Physics Error: {}", e),
                    }
                }
            } else {
                eprintln!("Usage: centl-web physics convert <val> <from> <to>");
            }
        }
        _ => {
            // Direct expression evaluation
            let full_expr = args[1..].join(" ");
            match evaluate(&full_expr, &mut session) {
                Ok(res) => println!("{}", res.text),
                Err(e) => {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
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
        let res = evaluate("diff(x^3, x)", &mut session).unwrap();
        assert_eq!(res.text, "3 * x^2");
    }

    #[test]
    fn test_symbolic_integration() {
        let mut session = Session::new();
        let res = evaluate("integrate(3*x^2 + 2*x, x, 0, 5)", &mut session).unwrap();
        assert_eq!(res.text, "150");
    }

    #[test]
    fn test_solve_linear_equation() {
        let mut session = Session::new();
        let res = evaluate("solve(3*x - 12 = 0, x)", &mut session).unwrap();
        assert_eq!(res.text, "x = 4");
    }

    #[test]
    fn test_solve_quadratic_equation() {
        let mut session = Session::new();
        let res = evaluate("solve(x^2 - 5*x + 6 = 0, x)", &mut session).unwrap();
        assert!(res.text.contains("x = 3") && res.text.contains("x = 2"));
    }

    #[test]
    fn test_erdos_straus_solver() {
        let res = solve_es(1009);
        assert!(res.solved);
        let w = res.witness.unwrap();
        assert!(w.verify());
    }

    #[test]
    fn test_physics_conversion() {
        let res = convert_units(100.0, "cm", "m").unwrap();
        assert_eq!(res.summary, "100 cm = 1.00000000 m");
    }
}
