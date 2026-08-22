// CENTL Core Library & Web Application Engine
// Free Computation Foundation - Apache-2.0

pub mod engine;
pub mod erdos_straus;
pub mod physics;
pub mod server;

pub use engine::{evaluate, Session};
pub use server::{start_lab_server, start_server};
use std::env;
use std::path::Path;

pub fn print_help() {
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

pub fn resolve_site_dir() -> Result<String, String> {
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

pub fn serve(port: u16) {
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

pub fn serve_lab(port: u16) {
    if let Err(error) = start_lab_server(port) {
        eprintln!("Failed to start CentL26 on port {}: {}", port, error);
        std::process::exit(1);
    }
}

pub fn run_cli() {
    let args: Vec<String> = env::args().collect();
    let mut session = Session::new();

    if args.iter().any(|arg| arg == "--help" || arg == "-h") {
        print_help();
        return;
    }

    if args.iter().any(|arg| arg == "--version" || arg == "-v") {
        println!("CentL26 {} · backend compatibility 0.15 Al-Nur", env!("CARGO_PKG_VERSION"));
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
    use super::engine::symbolic::Expr;
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

        let higher = evaluate("diff(x^5, x, 2)", &mut session).unwrap();
        assert_eq!(higher.text, "20 * x^3");
    }

    #[test]
    fn test_symbolic_expansion_and_taylor() {
        let mut session = Session::new();
        let exp = evaluate("expand(x * (x + 2))", &mut session).unwrap();
        assert_eq!(exp.text, "x^2 + 2 * x");

        let ser = evaluate("taylor(x^3 + 2*x, x, 3)", &mut session).unwrap();
        assert!(ser.text.contains("x^3") && ser.text.contains("2 * x"));
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

    #[test]
    fn test_exact_square_root_rational() {
        let zero = BigInt::zero();
        assert_eq!(zero.exact_sqrt(), Some(BigInt::zero()));

        let one = BigInt::one();
        assert_eq!(one.exact_sqrt(), Some(BigInt::one()));

        let four = BigInt::from_i64(4);
        assert_eq!(four.exact_sqrt(), Some(BigInt::from_i64(2)));

        let hundred = BigInt::from_i64(100);
        assert_eq!(hundred.exact_sqrt(), Some(BigInt::from_i64(10)));

        let non_square = BigInt::from_i64(50);
        assert_eq!(non_square.exact_sqrt(), None);

        let large_square = BigInt::from_i64(144_000_000);
        assert_eq!(large_square.exact_sqrt(), Some(BigInt::from_i64(12_000)));

        let rat_sq = BigRational::from_fraction(49, 144);
        assert_eq!(rat_sq.exact_sqrt(), Some(BigRational::from_fraction(7, 12)));

        let rat_non_sq = BigRational::from_fraction(2, 3);
        assert_eq!(rat_non_sq.exact_sqrt(), None);
    }

    #[test]
    fn test_implicit_multiplication_parsing() {
        use crate::engine::symbolic::Parser;
        let e1 = Parser::parse("2x").unwrap();
        assert_eq!(e1, Expr::Mul(Box::new(Expr::num(2)), Box::new(Expr::var("x"))));

        let e2 = Parser::parse("5x^2").unwrap();
        assert_eq!(e2, Expr::Mul(Box::new(Expr::num(5)), Box::new(Expr::Pow(Box::new(Expr::var("x")), 2))));

        let e3 = Parser::parse("3(x + 1)").unwrap();
        assert_eq!(
            e3,
            Expr::Mul(
                Box::new(Expr::num(3)),
                Box::new(Expr::Add(Box::new(Expr::var("x")), Box::new(Expr::num(1))))
            )
        );

        let e4 = Parser::parse("(x - 1)(x + 1)").unwrap();
        assert_eq!(
            e4,
            Expr::Mul(
                Box::new(Expr::Sub(Box::new(Expr::var("x")), Box::new(Expr::num(1)))),
                Box::new(Expr::Add(Box::new(Expr::var("x")), Box::new(Expr::num(1))))
            )
        );

        let e5 = Parser::parse("4pi").unwrap();
        assert_eq!(e5, Expr::Mul(Box::new(Expr::num(4)), Box::new(Expr::Constant("pi".to_string()))));

        let e6 = Parser::parse("2sin(x)").unwrap();
        assert_eq!(
            e6,
            Expr::Mul(
                Box::new(Expr::num(2)),
                Box::new(Expr::Function("sin".to_string(), vec![Expr::var("x")]))
            )
        );
    }

    #[test]
    fn test_linear_equations_and_implicit_multiplication() {
        let mut session = Session::new();

        // 2x + 3 = 7 -> x = 2
        let r1 = evaluate("2x + 3 = 7", &mut session).unwrap();
        assert_eq!(r1.text, "x = 2");
        assert_eq!(r1.exact_rational, Some(BigRational::from_i64(2)));

        // 5 - 2x = 11 -> x = -3
        let r2 = evaluate("5 - 2x = 11", &mut session).unwrap();
        assert_eq!(r2.text, "x = -3");
        assert_eq!(r2.exact_rational, Some(BigRational::from_i64(-3)));

        // 3(x - 4) = 2(x + 1) -> 3x - 12 = 2x + 2 -> x = 14
        let r3 = evaluate("3(x - 4) = 2(x + 1)", &mut session).unwrap();
        assert_eq!(r3.text, "x = 14");
        assert_eq!(r3.exact_rational, Some(BigRational::from_i64(14)));

        // x/2 + 1/3 = 5 -> x/2 = 14/3 -> x = 28/3
        let r4 = evaluate("x/2 + 1/3 = 5", &mut session).unwrap();
        assert_eq!(r4.text, "x = 28/3");
        assert_eq!(r4.exact_rational, Some(BigRational::from_fraction(28, 3)));

        // Explicit solve command syntax
        let r5 = evaluate("solve 4x + 8 = 0", &mut session).unwrap();
        assert_eq!(r5.text, "x = -2");

        let r6 = evaluate("solve 3y - 9 = 0 for y", &mut session).unwrap();
        assert_eq!(r6.text, "y = 3");
    }

    #[test]
    fn test_constant_equality_verification() {
        let mut session = Session::new();

        let r1 = evaluate("2 + 3 = 5", &mut session).unwrap();
        assert_eq!(r1.text, "true");

        let r2 = evaluate("2 + 3 = 6", &mut session).unwrap();
        assert_eq!(r2.text, "false");

        let r3 = evaluate("1/2 + 1/3 = 5/6", &mut session).unwrap();
        assert_eq!(r3.text, "true");

        let r4 = evaluate("2^10 = 1024", &mut session).unwrap();
        assert_eq!(r4.text, "true");
    }

    #[test]
    fn test_quadratic_equations_exact_and_radicals() {
        let mut session = Session::new();

        // Standard factored quadratic: x^2 - 5x + 6 = 0 -> x = 2, x = 3
        let r1 = evaluate("x^2 - 5x + 6 = 0", &mut session).unwrap();
        assert!(r1.text.contains("x = 2") && r1.text.contains("x = 3"));

        // Product form: (x - 2)(x + 3) = 0 -> x = -3, x = 2
        let r2 = evaluate("(x - 2)(x + 3) = 0", &mut session).unwrap();
        assert!(r2.text.contains("x = -3") && r2.text.contains("x = 2"));

        // Shifted square: (x + 1)^2 = 9 -> x^2 + 2x - 8 = 0 -> x = -4, x = 2
        let r3 = evaluate("(x + 1)^2 = 9", &mut session).unwrap();
        assert!(r3.text.contains("x = -4") && r3.text.contains("x = 2"));

        // Fractional coefficients: 2x^2 + 7x + 3 = 0 -> x = -3, x = -1/2
        let r4 = evaluate("2x^2 + 7x + 3 = 0", &mut session).unwrap();
        assert!(r4.text.contains("x = -3") && r4.text.contains("x = -1/2"));

        // Difference of squares: 4x^2 - 1 = 0 -> x = -1/2, x = 1/2
        let r5 = evaluate("4x^2 - 1 = 0", &mut session).unwrap();
        assert!(r5.text.contains("x = -1/2") && r5.text.contains("x = 1/2"));

        // Repeated root: x^2 - 6x + 9 = 0 -> x = 3
        let r6 = evaluate("x^2 - 6x + 9 = 0", &mut session).unwrap();
        assert_eq!(r6.text, "x = 3");

        // Complex roots: x^2 + 4 = 0 -> x = 0 + 2*i, x = 0 - 2*i
        let r7 = evaluate("x^2 + 4 = 0", &mut session).unwrap();
        assert!(r7.text.contains("2*i") && r7.text.contains("- 2*i"));
    }

    #[test]
    fn test_higher_degree_polynomial_solving() {
        let mut session = Session::new();

        // Cubic: x^3 - 6x^2 + 11x - 6 = 0 -> roots are 1, 2, 3
        let r1 = evaluate("x^3 - 6x^2 + 11x - 6 = 0", &mut session).unwrap();
        assert!(r1.text.contains("x = 1") && r1.text.contains("x = 2") && r1.text.contains("x = 3"));

        // Cubic with zero root: x^3 - x = 0 -> roots are 0, -1, 1
        let r2 = evaluate("x^3 - x = 0", &mut session).unwrap();
        assert!(r2.text.contains("x = 0") && r2.text.contains("x = -1") && r2.text.contains("x = 1"));

        // Quartic: x^4 - 5x^2 + 4 = 0 -> roots are -2, -1, 1, 2
        let r3 = evaluate("x^4 - 5x^2 + 4 = 0", &mut session).unwrap();
        assert!(r3.text.contains("x = -2") && r3.text.contains("x = -1") && r3.text.contains("x = 1") && r3.text.contains("x = 2"));
    }

    #[test]
    fn test_polynomial_expansion_and_factoring() {
        let mut session = Session::new();

        // Expansion
        let r1 = evaluate("expand((x - 1)*(x + 1))", &mut session).unwrap();
        assert_eq!(r1.text, "x^2 - 1");

        let r2 = evaluate("expand((x + 2)^2)", &mut session).unwrap();
        assert_eq!(r2.text, "x^2 + 4 * x + 4");

        // Factoring
        let r3 = evaluate("factor(x^2 - 9)", &mut session).unwrap();
        assert_eq!(r3.text, "(x + 3) * (x - 3)");

        let r4 = evaluate("factor(x^2 - 5x + 6)", &mut session).unwrap();
        assert_eq!(r4.text, "(x - 2) * (x - 3)");

        let r5 = evaluate("factor(x^3 - 6x^2 + 11x - 6)", &mut session).unwrap();
        assert_eq!(r5.text, "(x - 1) * (x - 2) * (x - 3)");
    }

    #[test]
    fn test_calculus_differentiation_integration_limits_series() {
        let mut session = Session::new();

        // Differentiation
        let r1 = evaluate("diff(3x^4 - 5x^2 + 2, x)", &mut session).unwrap();
        assert_eq!(r1.text, "12 * x^3 - 10 * x");

        // Higher order differentiation
        let r2 = evaluate("diff(x^4, x, 2)", &mut session).unwrap();
        assert_eq!(r2.text, "12 * x^2");

        let r3 = evaluate("diff(x^4, x, 3)", &mut session).unwrap();
        assert_eq!(r3.text, "24 * x");

        // Definite Integration
        let r4 = evaluate("integrate(x^3, x, 0, 2)", &mut session).unwrap();
        assert_eq!(r4.text, "4");

        let r5 = evaluate("integrate(3x^2 + 2x, x, 0, 3)", &mut session).unwrap();
        assert_eq!(r5.text, "36");

        // Limits & L'Hopital's rule
        let r6 = evaluate("limit((x^2 - 1)/(x - 1), x, 1)", &mut session).unwrap();
        assert_eq!(r6.text, "2");

        let r7 = evaluate("limit((x^2 - 4)/(x - 2), x, 2)", &mut session).unwrap();
        assert_eq!(r7.text, "4");

        let r8 = evaluate("limit(3x + 5, x, 2)", &mut session).unwrap();
        assert_eq!(r8.text, "11");

        // Summations
        let r9 = evaluate("sum(k^2, k, 1, 5)", &mut session).unwrap();
        assert_eq!(r9.text, "55");

        let r10 = evaluate("sum(k, k, 1, 10)", &mut session).unwrap();
        assert_eq!(r10.text, "55");

        // Products
        let r11 = evaluate("product(k, k, 1, 5)", &mut session).unwrap();
        assert_eq!(r11.text, "120");

        let r12 = evaluate("product(2, k, 1, 4)", &mut session).unwrap();
        assert_eq!(r12.text, "16");

        // Taylor series
        let r13 = evaluate("taylor(exp(x), x, 0, 3)", &mut session).unwrap();
        assert!(r13.text.contains("1") && r13.text.contains("x") && r13.text.contains("1/2 * x^2") && r13.text.contains("1/6 * x^3"));
    }

    #[test]
    fn test_polynomial_canonical_operations() {
        use crate::engine::symbolic::Polynomial;
        let p1 = Polynomial {
            var: "x".to_string(),
            coeffs: vec![BigRational::from_i64(6), BigRational::from_i64(-5), BigRational::from_i64(1)], // x^2 - 5x + 6
        };

        let (q, rem) = p1.synthetic_divide_root(&BigRational::from_i64(2));
        assert!(rem.is_zero());
        assert_eq!(q.coeffs, vec![BigRational::from_i64(-3), BigRational::from_i64(1)]); // x - 3

        let roots = p1.solve().unwrap();
        assert_eq!(roots.len(), 2);
        assert_eq!(roots[0], Expr::Number(BigRational::from_i64(2)));
        assert_eq!(roots[1], Expr::Number(BigRational::from_i64(3)));
    }

    #[test]
    fn test_chemistry_formulas_and_elements() {
        use crate::engine::sci::calculate_molar_mass_breakdown;

        // Water: H2O -> ~18.015 g/mol
        let (mass_h2o, steps_h2o) = calculate_molar_mass_breakdown("H2O").unwrap();
        assert!((mass_h2o - 18.015).abs() < 0.05);
        assert!(!steps_h2o.is_empty());

        // Sulfuric Acid: H2SO4 -> ~98.079 g/mol
        let (mass_h2so4, _) = calculate_molar_mass_breakdown("H2SO4").unwrap();
        assert!((mass_h2so4 - 98.079).abs() < 0.05);

        // Calcium Hydroxide: Ca(OH)2 -> ~74.093 g/mol
        let (mass_caoh2, _) = calculate_molar_mass_breakdown("Ca(OH)2").unwrap();
        assert!((mass_caoh2 - 74.093).abs() < 0.05);

        // Glucose: C6H12O6 -> ~180.156 g/mol
        let (mass_glu, _) = calculate_molar_mass_breakdown("C6H12O6").unwrap();
        assert!((mass_glu - 180.156).abs() < 0.05);
    }

    #[test]
    fn test_physics_quantum_and_thermodynamics() {
        use crate::physics::{calculate_photon, calculate_debroglie, calculate_carnot, calculate_photoelectric};

        // Photon energy for 500 nm green light
        let photon = calculate_photon(500.0 * 1e-9, true).unwrap();
        assert!(photon.summary.contains("eV") || photon.summary.contains("Joules"));

        // De Broglie wavelength for electron at 10^6 m/s (m_e ~ 9.109e-31 kg)
        let debroglie = calculate_debroglie(9.1093837e-31, 1.0e6).unwrap();
        assert!(debroglie.summary.contains("Wavelength") || debroglie.summary.contains("m"));

        // Carnot efficiency: Th = 500 K, Tc = 300 K -> eta = 40%
        let carnot = calculate_carnot(500.0, 300.0).unwrap();
        assert!(carnot.summary.contains("40.00%"));

        // Photoelectric stopping potential: work function 2.0 eV, 400 nm
        let pe = calculate_photoelectric(2.0, 400.0).unwrap();
        assert!(pe.summary.contains("V_stop") || pe.summary.contains("K_max"));
    }
}
