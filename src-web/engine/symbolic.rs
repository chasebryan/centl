// Symbolic Mathematics, Differentiation, Integration, and Equation Solver for CENTL
// Free Computation Foundation - Apache-2.0

use super::rational::BigRational;
use std::fmt;

#[derive(Clone, PartialEq, Eq, Debug)]
pub enum Expr {
    Number(BigRational),
    Variable(String),
    Constant(String), // pi, e, tau
    Add(Box<Expr>, Box<Expr>),
    Sub(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
    Div(Box<Expr>, Box<Expr>),
    Pow(Box<Expr>, i32),
    Neg(Box<Expr>),
    Function(String, Vec<Expr>),
    Equation(Box<Expr>, Box<Expr>),
}

impl Expr {
    pub fn num(n: i64) -> Self {
        Expr::Number(BigRational::from_i64(n))
    }

    pub fn frac(num: i64, den: i64) -> Self {
        Expr::Number(BigRational::from_fraction(num, den))
    }

    pub fn var(name: &str) -> Self {
        Expr::Variable(name.to_string())
    }

    pub fn is_zero(&self) -> bool {
        match self {
            Expr::Number(r) => r.is_zero(),
            _ => false,
        }
    }

    pub fn is_one(&self) -> bool {
        match self {
            Expr::Number(r) => r.is_integer() && r.numer.is_one(),
            _ => false,
        }
    }

    pub fn to_f64(&self) -> Result<f64, String> {
        match self {
            Expr::Number(n) => Ok(n.to_f64()),
            Expr::Constant(c) => match c.as_str() {
                "pi" => Ok(std::f64::consts::PI),
                "e" => Ok(std::f64::consts::E),
                "tau" => Ok(std::f64::consts::TAU),
                _ => Err(format!("unknown constant: {}", c)),
            },
            Expr::Neg(inner) => Ok(-inner.to_f64()?),
            Expr::Add(a, b) => Ok(a.to_f64()? + b.to_f64()?),
            Expr::Sub(a, b) => Ok(a.to_f64()? - b.to_f64()?),
            Expr::Mul(a, b) => Ok(a.to_f64()? * b.to_f64()?),
            Expr::Div(a, b) => {
                let den = b.to_f64()?;
                if den == 0.0 {
                    return Err("division by zero in numerical evaluation".to_string());
                }
                Ok(a.to_f64()? / den)
            }
            Expr::Pow(base, exp) => Ok(base.to_f64()?.powi(*exp as i32)),
            Expr::Function(name, args) => {
                if args.len() == 1 {
                    let val = args[0].to_f64()?;
                    match name.as_str() {
                        "sin" => Ok(val.sin()),
                        "cos" => Ok(val.cos()),
                        "tan" => Ok(val.tan()),
                        "asin" => Ok(val.asin()),
                        "acos" => Ok(val.acos()),
                        "atan" => Ok(val.atan()),
                        "sinh" => Ok(val.sinh()),
                        "cosh" => Ok(val.cosh()),
                        "tanh" => Ok(val.tanh()),
                        "exp" => Ok(val.exp()),
                        "ln" | "log" => Ok(val.ln()),
                        "sqrt" => Ok(val.sqrt()),
                        "abs" => Ok(val.abs()),
                        _ => Err(format!("unknown function in to_f64: {}", name)),
                    }
                } else {
                    Err(format!("cannot convert multi-arg function '{}' to float", name))
                }
            }
            _ => Err(format!("cannot convert symbolic expression '{}' to float", self)),
        }
    }

    // Symbolic Differentiation d(expr)/d(var)
    pub fn diff(&self, var: &str) -> Expr {
        match self {
            Expr::Number(_) | Expr::Constant(_) => Expr::num(0),
            Expr::Variable(v) => {
                if v == var {
                    Expr::num(1)
                } else {
                    Expr::num(0)
                }
            }
            Expr::Neg(inner) => Expr::Neg(Box::new(inner.diff(var))),
            Expr::Add(a, b) => Expr::Add(Box::new(a.diff(var)), Box::new(b.diff(var))).simplify(),
            Expr::Sub(a, b) => Expr::Sub(Box::new(a.diff(var)), Box::new(b.diff(var))).simplify(),
            Expr::Mul(a, b) => {
                // Product rule: a'b + ab'
                let term1 = Expr::Mul(Box::new(a.diff(var)), b.clone());
                let term2 = Expr::Mul(a.clone(), Box::new(b.diff(var)));
                Expr::Add(Box::new(term1), Box::new(term2)).simplify()
            }
            Expr::Div(a, b) => {
                // Quotient rule: (a'b - ab') / b^2
                let num1 = Expr::Mul(Box::new(a.diff(var)), b.clone());
                let num2 = Expr::Mul(a.clone(), Box::new(b.diff(var)));
                let num = Expr::Sub(Box::new(num1), Box::new(num2));
                let den = Expr::Pow(b.clone(), 2);
                Expr::Div(Box::new(num), Box::new(den)).simplify()
            }
            Expr::Pow(base, exp) => {
                // Power rule: n * base^(n-1) * base'
                let n = *exp;
                if n == 0 {
                    Expr::num(0)
                } else if n == 1 {
                    base.diff(var)
                } else {
                    let factor = Expr::num(n as i64);
                    let power = Expr::Pow(base.clone(), n - 1);
                    let chain = base.diff(var);
                    Expr::Mul(Box::new(Expr::Mul(Box::new(factor), Box::new(power))), Box::new(chain)).simplify()
                }
            }
            Expr::Function(name, args) => match name.as_str() {
                "sin" if args.len() == 1 => {
                    let u = &args[0];
                    Expr::Mul(Box::new(Expr::Function("cos".to_string(), vec![u.clone()])), Box::new(u.diff(var))).simplify()
                }
                "cos" if args.len() == 1 => {
                    let u = &args[0];
                    Expr::Mul(Box::new(Expr::Neg(Box::new(Expr::Function("sin".to_string(), vec![u.clone()])))), Box::new(u.diff(var))).simplify()
                }
                "tan" if args.len() == 1 => {
                    let u = &args[0];
                    let sec2 = Expr::Pow(Box::new(Expr::Function("cos".to_string(), vec![u.clone()])), -2);
                    Expr::Mul(Box::new(sec2), Box::new(u.diff(var))).simplify()
                }
                "exp" if args.len() == 1 => {
                    let u = &args[0];
                    Expr::Mul(Box::new(Expr::Function("exp".to_string(), vec![u.clone()])), Box::new(u.diff(var))).simplify()
                }
                "log" if args.len() == 1 => {
                    let u = &args[0];
                    Expr::Div(Box::new(u.diff(var)), Box::new(u.clone())).simplify()
                }
                "sqrt" if args.len() == 1 => {
                    let u = &args[0];
                    let den = Expr::Mul(Box::new(Expr::num(2)), Box::new(Expr::Function("sqrt".to_string(), vec![u.clone()])));
                    Expr::Div(Box::new(u.diff(var)), Box::new(den)).simplify()
                }
                _ => Expr::Function(format!("diff_{}", name), args.clone()),
            },
            Expr::Equation(l, r) => Expr::Equation(Box::new(l.diff(var)), Box::new(r.diff(var))),
        }
    }

    // Symbolic Substitution
    pub fn substitute(&self, var: &str, val: &Expr) -> Expr {
        match self {
            Expr::Variable(v) if v == var => val.clone(),
            Expr::Variable(_) | Expr::Number(_) | Expr::Constant(_) => self.clone(),
            Expr::Neg(inner) => Expr::Neg(Box::new(inner.substitute(var, val))).simplify(),
            Expr::Add(a, b) => Expr::Add(Box::new(a.substitute(var, val)), Box::new(b.substitute(var, val))).simplify(),
            Expr::Sub(a, b) => Expr::Sub(Box::new(a.substitute(var, val)), Box::new(b.substitute(var, val))).simplify(),
            Expr::Mul(a, b) => Expr::Mul(Box::new(a.substitute(var, val)), Box::new(b.substitute(var, val))).simplify(),
            Expr::Div(a, b) => Expr::Div(Box::new(a.substitute(var, val)), Box::new(b.substitute(var, val))).simplify(),
            Expr::Pow(base, exp) => Expr::Pow(Box::new(base.substitute(var, val)), *exp).simplify(),
            Expr::Function(name, args) => {
                let new_args: Vec<Expr> = args.iter().map(|a| a.substitute(var, val)).collect();
                Expr::Function(name.clone(), new_args).simplify()
            }
            Expr::Equation(l, r) => Expr::Equation(Box::new(l.substitute(var, val)), Box::new(r.substitute(var, val))),
        }
    }

    // Symbolic Integration for Polynomial and Elementary terms
    pub fn integrate(&self, var: &str) -> Result<Expr, String> {
        let simplified = self.simplify();
        match &simplified {
            Expr::Number(n) => {
                Ok(Expr::Mul(Box::new(Expr::Number(n.clone())), Box::new(Expr::Variable(var.to_string()))).simplify())
            }
            Expr::Variable(v) if v == var => {
                let half = Expr::frac(1, 2);
                let x2 = Expr::Pow(Box::new(Expr::var(var)), 2);
                Ok(Expr::Mul(Box::new(half), Box::new(x2)).simplify())
            }
            Expr::Variable(v) => {
                Ok(Expr::Mul(Box::new(Expr::var(v)), Box::new(Expr::var(var))).simplify())
            }
            Expr::Add(a, b) => {
                let ia = a.integrate(var)?;
                let ib = b.integrate(var)?;
                Ok(Expr::Add(Box::new(ia), Box::new(ib)).simplify())
            }
            Expr::Sub(a, b) => {
                let ia = a.integrate(var)?;
                let ib = b.integrate(var)?;
                Ok(Expr::Sub(Box::new(ia), Box::new(ib)).simplify())
            }
            Expr::Mul(a, b) => {
                if let Expr::Number(n) = a.as_ref() {
                    let ib = b.integrate(var)?;
                    Ok(Expr::Mul(Box::new(Expr::Number(n.clone())), Box::new(ib)).simplify())
                } else if let Expr::Number(n) = b.as_ref() {
                    let ia = a.integrate(var)?;
                    Ok(Expr::Mul(Box::new(Expr::Number(n.clone())), Box::new(ia)).simplify())
                } else {
                    Err(format!("unsupported non-linear product integration: {}", self))
                }
            }
            Expr::Pow(base, exp) if base.as_ref() == &Expr::Variable(var.to_string()) => {
                let n = *exp;
                if n == -1 {
                    Ok(Expr::Function("log".to_string(), vec![Expr::var(var)]))
                } else {
                    let new_exp = n + 1;
                    let factor = Expr::frac(1, new_exp as i64);
                    let power = Expr::Pow(base.clone(), new_exp);
                    Ok(Expr::Mul(Box::new(factor), Box::new(power)).simplify())
                }
            }
            Expr::Function(name, args) if args.len() == 1 && args[0] == Expr::Variable(var.to_string()) => {
                match name.as_str() {
                    "cos" => Ok(Expr::Function("sin".to_string(), vec![Expr::var(var)])),
                    "sin" => Ok(Expr::Neg(Box::new(Expr::Function("cos".to_string(), vec![Expr::var(var)])))),
                    "exp" => Ok(Expr::Function("exp".to_string(), vec![Expr::var(var)])),
                    _ => Err(format!("antiderivative for {} not supported", name)),
                }
            }
            _ => Err(format!("cannot integrate expression symbolically: {}", self)),
        }
    }

    // Definite integral: integrate(expr, var, lower, upper)
    pub fn integrate_definite(&self, var: &str, lower: &Expr, upper: &Expr) -> Result<Expr, String> {
        let anti = self.integrate(var)?;
        let val_upper = anti.substitute(var, upper).simplify();
        let val_lower = anti.substitute(var, lower).simplify();
        Ok(Expr::Sub(Box::new(val_upper), Box::new(val_lower)).simplify())
    }

    // Symbolic simplification
    pub fn simplify(&self) -> Expr {
        match self {
            Expr::Number(_) | Expr::Variable(_) | Expr::Constant(_) => self.clone(),
            Expr::Neg(inner) => {
                let s = inner.simplify();
                match s {
                    Expr::Number(n) => Expr::Number(-n),
                    Expr::Neg(x) => *x,
                    _ => Expr::Neg(Box::new(s)),
                }
            }
            Expr::Add(a, b) => {
                let sa = a.simplify();
                let sb = b.simplify();
                if sa.is_zero() {
                    return sb;
                }
                if sb.is_zero() {
                    return sa;
                }
                match (&sa, &sb) {
                    (Expr::Number(na), Expr::Number(nb)) => Expr::Number(na + nb),
                    (Expr::Variable(va), Expr::Variable(vb)) if va == vb => {
                        Expr::Mul(Box::new(Expr::num(2)), Box::new(Expr::var(va)))
                    }
                    _ => Expr::Add(Box::new(sa), Box::new(sb)),
                }
            }
            Expr::Sub(a, b) => {
                let sa = a.simplify();
                let sb = b.simplify();
                if sb.is_zero() {
                    return sa;
                }
                if sa == sb {
                    return Expr::num(0);
                }
                match (&sa, &sb) {
                    (Expr::Number(na), Expr::Number(nb)) => Expr::Number(na - nb),
                    _ => Expr::Sub(Box::new(sa), Box::new(sb)),
                }
            }
            Expr::Mul(a, b) => {
                let sa = a.simplify();
                let sb = b.simplify();
                if sa.is_zero() || sb.is_zero() {
                    return Expr::num(0);
                }
                if sa.is_one() {
                    return sb;
                }
                if sb.is_one() {
                    return sa;
                }
                match (&sa, &sb) {
                    (Expr::Number(na), Expr::Number(nb)) => Expr::Number(na * nb),
                    (Expr::Number(na), Expr::Mul(b1, b2)) => {
                        if let Expr::Number(nb) = b1.as_ref() {
                            Expr::Mul(Box::new(Expr::Number(na * nb)), b2.clone()).simplify()
                        } else {
                            Expr::Mul(Box::new(sa), Box::new(sb))
                        }
                    }
                    (Expr::Variable(va), Expr::Variable(vb)) if va == vb => {
                        Expr::Pow(Box::new(Expr::var(va)), 2)
                    }
                    _ => Expr::Mul(Box::new(sa), Box::new(sb)),
                }
            }
            Expr::Div(a, b) => {
                let sa = a.simplify();
                let sb = b.simplify();
                if sb.is_zero() {
                    return Expr::Div(Box::new(sa), Box::new(sb));
                }
                if sa.is_zero() {
                    return Expr::num(0);
                }
                if sb.is_one() {
                    return sa;
                }
                if sa == sb {
                    return Expr::num(1);
                }
                match (&sa, &sb) {
                    (Expr::Number(na), Expr::Number(nb)) => Expr::Number(na / nb),
                    _ => Expr::Div(Box::new(sa), Box::new(sb)),
                }
            }
            Expr::Pow(base, exp) => {
                let sbase = base.simplify();
                if *exp == 0 {
                    return Expr::num(1);
                }
                if *exp == 1 {
                    return sbase;
                }
                if let Expr::Number(ref n) = sbase {
                    if let Ok(p) = n.pow(*exp) {
                        return Expr::Number(p);
                    }
                }
                Expr::Pow(Box::new(sbase), *exp)
            }
            Expr::Function(name, args) => {
                let sargs: Vec<Expr> = args.iter().map(|a| a.simplify()).collect();
                if sargs.len() == 1 {
                    if let Expr::Number(n) = &sargs[0] {
                        if name == "abs" {
                            return Expr::Number(n.abs());
                        }
                        if name == "sqrt" && n.denom.is_one() && !n.is_negative() {
                            if let Some(i) = n.numer.to_i64() {
                                let sq = (i as f64).sqrt() as i64;
                                if sq * sq == i {
                                    return Expr::num(sq);
                                }
                            }
                        }
                    }
                }
                Expr::Function(name.clone(), sargs)
            }
            Expr::Equation(l, r) => Expr::Equation(Box::new(l.simplify()), Box::new(r.simplify())),
        }
    }

    // Exact equation solver: solve(left = right, var)
    pub fn solve(&self, var: &str) -> Result<Vec<Expr>, String> {
        let (lhs, rhs) = match self {
            Expr::Equation(l, r) => (l.as_ref(), r.as_ref()),
            _ => (self, &Expr::num(0)),
        };
        let diff = Expr::Sub(Box::new(lhs.clone()), Box::new(rhs.clone())).simplify();

        let (c2, c1, c0) = extract_quadratic_coeffs(&diff, var)?;

        if c2.is_zero() {
            if c1.is_zero() {
                if c0.is_zero() {
                    return Err("identity equation: infinite solutions".to_string());
                } else {
                    return Err("inconsistent equation: no solutions".to_string());
                }
            }
            let sol = -(&c0 / &c1);
            Ok(vec![Expr::Number(sol)])
        } else {
            let four = BigRational::from_i64(4);
            let two = BigRational::from_i64(2);
            let four_c2_c0 = &(&four * &c2) * &c0;
            let delta = &(&c1 * &c1) - &four_c2_c0;

            if delta.is_zero() {
                let sol = -(&c1 / &(&two * &c2));
                Ok(vec![Expr::Number(sol)])
            } else if delta.is_negative() {
                let real = -(&c1 / &(&two * &c2));
                let im_val = (-delta.to_f64()).sqrt() / (2.0 * c2.to_f64());
                let sol1 = format!("{} + {}*i", real, im_val);
                let sol2 = format!("{} - {}*i", real, im_val);
                Ok(vec![Expr::Variable(sol1), Expr::Variable(sol2)])
            } else {
                let delta_num = delta.numer.to_f64();
                let delta_den = delta.denom.to_f64();
                let sq_num = delta_num.sqrt().round();
                let sq_den = delta_den.sqrt().round();
                if (sq_num * sq_num - delta_num).abs() < 1e-6 && (sq_den * sq_den - delta_den).abs() < 1e-6 {
                    let sqrt_delta = BigRational::from_fraction(sq_num as i64, sq_den as i64);
                    let sol1 = (&(-&c1) + &sqrt_delta) / (&two * &c2);
                    let sol2 = (&(-&c1) - &sqrt_delta) / (&two * &c2);
                    Ok(vec![Expr::Number(sol1), Expr::Number(sol2)])
                } else {
                    let d_f = delta.to_f64().sqrt();
                    let sol1_f = (-c1.to_f64() + d_f) / (2.0 * c2.to_f64());
                    let sol2_f = (-c1.to_f64() - d_f) / (2.0 * c2.to_f64());
                    Ok(vec![
                        Expr::Number(BigRational::from_str(&format!("{:.12}", sol1_f)).unwrap_or_else(|_| BigRational::zero())),
                        Expr::Number(BigRational::from_str(&format!("{:.12}", sol2_f)).unwrap_or_else(|_| BigRational::zero())),
                    ])
                }
            }
        }
    }

    // Symbolic expansion: expand((x - 1)*(x + 1)) -> x^2 - 1
    pub fn expand(&self) -> Expr {
        match self {
            Expr::Mul(a, b) => {
                let ea = a.expand();
                let eb = b.expand();
                match (&ea, &eb) {
                    (Expr::Add(a1, a2), _) => {
                        Expr::Add(
                            Box::new(Expr::Mul(a1.clone(), Box::new(eb.clone())).expand()),
                            Box::new(Expr::Mul(a2.clone(), Box::new(eb.clone())).expand()),
                        ).simplify()
                    }
                    (Expr::Sub(a1, a2), _) => {
                        Expr::Sub(
                            Box::new(Expr::Mul(a1.clone(), Box::new(eb.clone())).expand()),
                            Box::new(Expr::Mul(a2.clone(), Box::new(eb.clone())).expand()),
                        ).simplify()
                    }
                    (_, Expr::Add(b1, b2)) => {
                        Expr::Add(
                            Box::new(Expr::Mul(Box::new(ea.clone()), b1.clone()).expand()),
                            Box::new(Expr::Mul(Box::new(ea.clone()), b2.clone()).expand()),
                        ).simplify()
                    }
                    (_, Expr::Sub(b1, b2)) => {
                        Expr::Sub(
                            Box::new(Expr::Mul(Box::new(ea.clone()), b1.clone()).expand()),
                            Box::new(Expr::Mul(Box::new(ea.clone()), b2.clone()).expand()),
                        ).simplify()
                    }
                    _ => Expr::Mul(Box::new(ea), Box::new(eb)).simplify(),
                }
            }
            Expr::Pow(base, exp) if *exp > 1 && *exp <= 8 => {
                let mut res = base.expand();
                for _ in 1..*exp {
                    res = Expr::Mul(Box::new(res), Box::new(base.expand())).expand();
                }
                res.simplify()
            }
            Expr::Add(a, b) => Expr::Add(Box::new(a.expand()), Box::new(b.expand())).simplify(),
            Expr::Sub(a, b) => Expr::Sub(Box::new(a.expand()), Box::new(b.expand())).simplify(),
            Expr::Neg(a) => Expr::Neg(Box::new(a.expand())).simplify(),
            Expr::Div(a, b) => Expr::Div(Box::new(a.expand()), Box::new(b.expand())).simplify(),
            _ => self.clone(),
        }
    }

    // Symbolic factorization for quadratic / polynomial forms
    pub fn factor(&self, var: &str) -> Result<Expr, String> {
        let diff = self.expand().simplify();
        let (c2, c1, c0) = extract_quadratic_coeffs(&diff, var)?;
        if c2.is_zero() {
            return Ok(diff);
        }
        let four = BigRational::from_i64(4);
        let two = BigRational::from_i64(2);
        let four_c2_c0 = &(&four * &c2) * &c0;
        let delta = &(&c1 * &c1) - &four_c2_c0;

        if delta.is_negative() {
            return Ok(self.clone());
        }

        let delta_num = delta.numer.to_f64();
        let delta_den = delta.denom.to_f64();
        let sq_num = delta_num.sqrt().round();
        let sq_den = delta_den.sqrt().round();

        if (sq_num * sq_num - delta_num).abs() < 1e-6 && (sq_den * sq_den - delta_den).abs() < 1e-6 {
            let sqrt_delta = BigRational::from_fraction(sq_num as i64, sq_den as i64);
            let r1 = (&(-&c1) + &sqrt_delta) / (&two * &c2);
            let r2 = (&(-&c1) - &sqrt_delta) / (&two * &c2);

            let term1 = if r1.is_zero() {
                Expr::var(var)
            } else if r1.is_negative() {
                Expr::Add(Box::new(Expr::var(var)), Box::new(Expr::Number(-r1)))
            } else {
                Expr::Sub(Box::new(Expr::var(var)), Box::new(Expr::Number(r1)))
            };

            let term2 = if r2.is_zero() {
                Expr::var(var)
            } else if r2.is_negative() {
                Expr::Add(Box::new(Expr::var(var)), Box::new(Expr::Number(-r2)))
            } else {
                Expr::Sub(Box::new(Expr::var(var)), Box::new(Expr::Number(r2)))
            };

            if c2.numer.is_one() && c2.denom.is_one() {
                Ok(Expr::Mul(Box::new(term1), Box::new(term2)))
            } else {
                let leading = Expr::Number(c2);
                Ok(Expr::Mul(Box::new(leading), Box::new(Expr::Mul(Box::new(term1), Box::new(term2)))))
            }
        } else {
            Ok(self.clone())
        }
    }
}

fn extract_quadratic_coeffs(expr: &Expr, var: &str) -> Result<(BigRational, BigRational, BigRational), String> {
    match expr {
        Expr::Number(n) => Ok((BigRational::zero(), BigRational::zero(), n.clone())),
        Expr::Variable(v) if v == var => Ok((BigRational::zero(), BigRational::one(), BigRational::zero())),
        Expr::Variable(_) => Ok((BigRational::zero(), BigRational::zero(), BigRational::zero())),
        Expr::Add(a, b) => {
            let (a2, a1, a0) = extract_quadratic_coeffs(a, var)?;
            let (b2, b1, b0) = extract_quadratic_coeffs(b, var)?;
            Ok((a2 + b2, a1 + b1, a0 + b0))
        }
        Expr::Sub(a, b) => {
            let (a2, a1, a0) = extract_quadratic_coeffs(a, var)?;
            let (b2, b1, b0) = extract_quadratic_coeffs(b, var)?;
            Ok((a2 - b2, a1 - b1, a0 - b0))
        }
        Expr::Mul(a, b) => {
            if let Expr::Number(n) = a.as_ref() {
                let (b2, b1, b0) = extract_quadratic_coeffs(b, var)?;
                Ok((n * &b2, n * &b1, n * &b0))
            } else if let Expr::Number(n) = b.as_ref() {
                let (a2, a1, a0) = extract_quadratic_coeffs(a, var)?;
                Ok((n * &a2, n * &a1, n * &a0))
            } else {
                Err(format!("non-linear expression in solve: {}", expr))
            }
        }
        Expr::Pow(base, exp) if base.as_ref() == &Expr::Variable(var.to_string()) => {
            if *exp == 1 {
                Ok((BigRational::zero(), BigRational::one(), BigRational::zero()))
            } else if *exp == 2 {
                Ok((BigRational::one(), BigRational::zero(), BigRational::zero()))
            } else {
                Err(format!("polynomial degree > 2 not yet supported: degree {}", exp))
            }
        }
        Expr::Neg(inner) => {
            let (c2, c1, c0) = extract_quadratic_coeffs(inner, var)?;
            Ok((-c2, -c1, -c0))
        }
        _ => Err(format!("cannot solve non-polynomial expression: {}", expr)),
    }
}

impl fmt::Display for Expr {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Expr::Number(r) => write!(f, "{}", r),
            Expr::Variable(v) => write!(f, "{}", v),
            Expr::Constant(c) => write!(f, "{}", c),
            Expr::Neg(inner) => write!(f, "-{}", inner),
            Expr::Add(a, b) => write!(f, "{} + {}", a, b),
            Expr::Sub(a, b) => write!(f, "{} - {}", a, b),
            Expr::Mul(a, b) => {
                let fa = match a.as_ref() {
                    Expr::Add(_, _) | Expr::Sub(_, _) => format!("({})", a),
                    _ => format!("{}", a),
                };
                let fb = match b.as_ref() {
                    Expr::Add(_, _) | Expr::Sub(_, _) => format!("({})", b),
                    _ => format!("{}", b),
                };
                write!(f, "{} * {}", fa, fb)
            }
            Expr::Div(a, b) => {
                let fa = match a.as_ref() {
                    Expr::Add(_, _) | Expr::Sub(_, _) => format!("({})", a),
                    _ => format!("{}", a),
                };
                let fb = match b.as_ref() {
                    Expr::Add(_, _) | Expr::Sub(_, _) | Expr::Mul(_, _) => format!("({})", b),
                    _ => format!("{}", b),
                };
                write!(f, "{} / {}", fa, fb)
            }
            Expr::Pow(base, exp) => match base.as_ref() {
                Expr::Variable(_) | Expr::Constant(_) => write!(f, "{}^{}", base, exp),
                _ => write!(f, "({})^{}", base, exp),
            },
            Expr::Function(name, args) => {
                let arg_strs: Vec<String> = args.iter().map(|a| format!("{}", a)).collect();
                write!(f, "{}({})", name, arg_strs.join(", "))
            }
            Expr::Equation(l, r) => write!(f, "{} = {}", l, r),
        }
    }
}

// -------------------------------------------------------------
// Expression Parser
// -------------------------------------------------------------

pub struct Parser<'a> {
    chars: Vec<char>,
    pos: usize,
    _marker: std::marker::PhantomData<&'a ()>,
}

impl<'a> Parser<'a> {
    pub fn parse(input: &str) -> Result<Expr, String> {
        let mut p = Parser {
            chars: input.chars().collect(),
            pos: 0,
            _marker: std::marker::PhantomData,
        };
        p.skip_whitespace();
        if p.is_eof() {
            return Err("empty expression".to_string());
        }
        let expr = p.parse_equation()?;
        p.skip_whitespace();
        if !p.is_eof() {
            return Err(format!("unexpected trailing character at index {}", p.pos));
        }
        Ok(expr)
    }

    fn skip_whitespace(&mut self) {
        while self.pos < self.chars.len() && self.chars[self.pos].is_whitespace() {
            self.pos += 1;
        }
    }

    fn peek(&self) -> Option<char> {
        self.chars.get(self.pos).copied()
    }

    fn is_eof(&self) -> bool {
        self.pos >= self.chars.len()
    }

    fn parse_equation(&mut self) -> Result<Expr, String> {
        let left = self.parse_add_sub()?;
        self.skip_whitespace();
        if self.peek() == Some('=') {
            self.pos += 1;
            let right = self.parse_add_sub()?;
            Ok(Expr::Equation(Box::new(left), Box::new(right)))
        } else {
            Ok(left)
        }
    }

    fn parse_add_sub(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_mul_div()?;
        loop {
            self.skip_whitespace();
            match self.peek() {
                Some('+') => {
                    self.pos += 1;
                    let right = self.parse_mul_div()?;
                    left = Expr::Add(Box::new(left), Box::new(right));
                }
                Some('-') => {
                    self.pos += 1;
                    let right = self.parse_mul_div()?;
                    left = Expr::Sub(Box::new(left), Box::new(right));
                }
                _ => break,
            }
        }
        Ok(left)
    }

    fn parse_mul_div(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_power()?;
        loop {
            self.skip_whitespace();
            match self.peek() {
                Some('*') => {
                    self.pos += 1;
                    let right = self.parse_power()?;
                    left = Expr::Mul(Box::new(left), Box::new(right));
                }
                Some('/') => {
                    self.pos += 1;
                    let right = self.parse_power()?;
                    left = Expr::Div(Box::new(left), Box::new(right));
                }
                _ => break,
            }
        }
        Ok(left)
    }

    fn parse_power(&mut self) -> Result<Expr, String> {
        let base = self.parse_unary()?;
        self.skip_whitespace();
        if self.peek() == Some('^') {
            self.pos += 1;
            let exp_expr = self.parse_unary()?;
            match exp_expr {
                Expr::Number(r) if r.is_integer() => {
                    if let Some(n) = r.numer.to_i64() {
                        return Ok(Expr::Pow(Box::new(base), n as i32));
                    }
                }
                _ => {}
            }
            return Err("power exponent must be an integer".to_string());
        }
        Ok(base)
    }

    fn parse_unary(&mut self) -> Result<Expr, String> {
        self.skip_whitespace();
        if self.peek() == Some('-') {
            self.pos += 1;
            let inner = self.parse_unary()?;
            Ok(Expr::Neg(Box::new(inner)))
        } else if self.peek() == Some('+') {
            self.pos += 1;
            self.parse_unary()
        } else {
            self.parse_primary()
        }
    }

    fn parse_primary(&mut self) -> Result<Expr, String> {
        self.skip_whitespace();
        if self.is_eof() {
            return Err("unexpected end of input".to_string());
        }
        let c = self.peek().unwrap();
        if c == '(' {
            self.pos += 1;
            let expr = self.parse_equation()?;
            self.skip_whitespace();
            if self.peek() != Some(')') {
                return Err("missing closing parenthesis ')'".to_string());
            }
            self.pos += 1;
            return Ok(expr);
        }
        if c.is_ascii_digit() || c == '.' {
            return self.parse_number();
        }
        if c.is_alphabetic() || c == '_' {
            return self.parse_identifier_or_call();
        }
        Err(format!("unexpected character '{}' at index {}", c, self.pos))
    }

    fn parse_number(&mut self) -> Result<Expr, String> {
        let start = self.pos;
        let mut seen_dot = false;
        while self.pos < self.chars.len() {
            let c = self.chars[self.pos];
            if c.is_ascii_digit() {
                self.pos += 1;
            } else if c == '.' && !seen_dot {
                seen_dot = true;
                self.pos += 1;
            } else {
                break;
            }
        }
        let num_str: String = self.chars[start..self.pos].iter().collect();
        let rat = BigRational::from_str(&num_str)?;
        Ok(Expr::Number(rat))
    }

    fn parse_identifier_or_call(&mut self) -> Result<Expr, String> {
        let start = self.pos;
        while self.pos < self.chars.len() {
            let c = self.chars[self.pos];
            if c.is_alphanumeric() || c == '_' {
                self.pos += 1;
            } else {
                break;
            }
        }
        let name: String = self.chars[start..self.pos].iter().collect();
        self.skip_whitespace();
        if self.peek() == Some('(') {
            self.pos += 1;
            let mut args = Vec::new();
            self.skip_whitespace();
            if self.peek() == Some(')') {
                self.pos += 1;
                return Ok(Expr::Function(name, args));
            }
            loop {
                let arg = self.parse_equation()?;
                args.push(arg);
                self.skip_whitespace();
                if self.peek() == Some(',') {
                    self.pos += 1;
                } else if self.peek() == Some(')') {
                    self.pos += 1;
                    break;
                } else {
                    return Err("expected ',' or ')' in argument list".to_string());
                }
            }
            Ok(Expr::Function(name, args))
        } else {
            if name == "pi" || name == "e" || name == "tau" {
                Ok(Expr::Constant(name))
            } else {
                Ok(Expr::Variable(name))
            }
        }
    }
}
