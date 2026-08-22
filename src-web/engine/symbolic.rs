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

    pub fn free_variables(&self) -> Vec<String> {
        let mut vars = std::collections::BTreeSet::new();
        self.collect_variables(&mut vars);
        vars.into_iter().collect()
    }

    fn collect_variables(&self, acc: &mut std::collections::BTreeSet<String>) {
        match self {
            Expr::Variable(v) => {
                if v != "pi" && v != "e" && v != "tau" {
                    acc.insert(v.clone());
                }
            }
            Expr::Neg(inner) => inner.collect_variables(acc),
            Expr::Add(a, b) | Expr::Sub(a, b) | Expr::Mul(a, b) | Expr::Div(a, b) | Expr::Equation(a, b) => {
                a.collect_variables(acc);
                b.collect_variables(acc);
            }
            Expr::Pow(base, _) => base.collect_variables(acc),
            Expr::Function(_, args) => {
                for a in args {
                    a.collect_variables(acc);
                }
            }
            Expr::Number(_) | Expr::Constant(_) => {}
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
                        if name == "exp" && n.is_zero() {
                            return Expr::num(1);
                        }
                        if name == "sin" && n.is_zero() {
                            return Expr::num(0);
                        }
                        if name == "cos" && n.is_zero() {
                            return Expr::num(1);
                        }
                        if name == "tan" && n.is_zero() {
                            return Expr::num(0);
                        }
                        if (name == "log" || name == "ln") && n.is_one() {
                            return Expr::num(0);
                        }
                        if name == "sqrt" {
                            if n.is_zero() {
                                return Expr::num(0);
                            }
                            if let Some(sq) = n.exact_sqrt() {
                                return Expr::Number(sq);
                            }
                        }
                        if name == "cbrt" && n.denom.is_one() {
                            if let Some(i) = n.numer.to_i64() {
                                let cb = (i as f64).cbrt().round() as i64;
                                if cb * cb * cb == i {
                                    return Expr::num(cb);
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
        let poly = Polynomial::from_expr(&diff, var)?;
        poly.solve()
    }

    // Symbolic expansion: expand((x - 1)*(x + 1)) -> x^2 - 1
    pub fn expand(&self) -> Expr {
        let vars = self.free_variables();
        if vars.len() == 1 {
            if let Ok(poly) = Polynomial::from_expr(self, &vars[0]) {
                return poly.to_expr();
            }
        }
        self.expand_raw().simplify()
    }

    fn expand_raw(&self) -> Expr {
        match self {
            Expr::Mul(a, b) => {
                let ea = a.expand_raw();
                let eb = b.expand_raw();
                match (&ea, &eb) {
                    (Expr::Add(a1, a2), _) => {
                        Expr::Add(
                            Box::new(Expr::Mul(a1.clone(), Box::new(eb.clone())).expand_raw()),
                            Box::new(Expr::Mul(a2.clone(), Box::new(eb.clone())).expand_raw()),
                        ).simplify()
                    }
                    (Expr::Sub(a1, a2), _) => {
                        Expr::Sub(
                            Box::new(Expr::Mul(a1.clone(), Box::new(eb.clone())).expand_raw()),
                            Box::new(Expr::Mul(a2.clone(), Box::new(eb.clone())).expand_raw()),
                        ).simplify()
                    }
                    (_, Expr::Add(b1, b2)) => {
                        Expr::Add(
                            Box::new(Expr::Mul(Box::new(ea.clone()), b1.clone()).expand_raw()),
                            Box::new(Expr::Mul(Box::new(ea.clone()), b2.clone()).expand_raw()),
                        ).simplify()
                    }
                    (_, Expr::Sub(b1, b2)) => {
                        Expr::Sub(
                            Box::new(Expr::Mul(Box::new(ea.clone()), b1.clone()).expand_raw()),
                            Box::new(Expr::Mul(Box::new(ea.clone()), b2.clone()).expand_raw()),
                        ).simplify()
                    }
                    _ => Expr::Mul(Box::new(ea), Box::new(eb)).simplify(),
                }
            }
            Expr::Pow(base, exp) if *exp > 1 && *exp <= 8 => {
                let mut res = base.expand_raw();
                for _ in 1..*exp {
                    res = Expr::Mul(Box::new(res), Box::new(base.expand_raw())).expand_raw();
                }
                res.simplify()
            }
            Expr::Add(a, b) => Expr::Add(Box::new(a.expand_raw()), Box::new(b.expand_raw())).simplify(),
            Expr::Sub(a, b) => Expr::Sub(Box::new(a.expand_raw()), Box::new(b.expand_raw())).simplify(),
            Expr::Neg(a) => Expr::Neg(Box::new(a.expand_raw())).simplify(),
            Expr::Div(a, b) => Expr::Div(Box::new(a.expand_raw()), Box::new(b.expand_raw())).simplify(),
            _ => self.clone(),
        }
    }

    // Symbolic factorization for polynomial forms
    pub fn factor(&self, var: &str) -> Result<Expr, String> {
        let poly = match Polynomial::from_expr(self, var) {
            Ok(p) => p,
            Err(_) => return Ok(self.clone()),
        };
        let deg = poly.degree();
        if deg <= 1 {
            return Ok(self.clone());
        }
        let roots = match poly.solve() {
            Ok(r) => r,
            Err(_) => return Ok(self.clone()),
        };
        let mut rational_roots = Vec::new();
        for r in roots {
            if let Expr::Number(n) = r {
                rational_roots.push(n);
            }
        }
        if rational_roots.is_empty() {
            return Ok(self.clone());
        }
        let mut factors = Vec::new();
        let leading = poly.coeffs[deg].clone();
        if !leading.is_one() {
            factors.push(Expr::Number(leading));
        }
        for r in rational_roots {
            let term = if r.is_zero() {
                Expr::var(var)
            } else if r.is_negative() {
                Expr::Add(Box::new(Expr::var(var)), Box::new(Expr::Number(-r)))
            } else {
                Expr::Sub(Box::new(Expr::var(var)), Box::new(Expr::Number(r)))
            };
            factors.push(term);
        }
        if factors.len() == 1 {
            Ok(factors[0].clone())
        } else {
            let mut acc = factors[0].clone();
            for f in factors.into_iter().skip(1) {
                acc = Expr::Mul(Box::new(acc), Box::new(f));
            }
            Ok(acc)
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Polynomial {
    pub var: String,
    pub coeffs: Vec<BigRational>, // coeffs[i] is coefficient of var^i
}

impl Polynomial {
    pub fn zero(var: &str) -> Self {
        Polynomial {
            var: var.to_string(),
            coeffs: vec![BigRational::zero()],
        }
    }

    pub fn constant(var: &str, c: BigRational) -> Self {
        Polynomial {
            var: var.to_string(),
            coeffs: vec![c],
        }
    }

    pub fn variable(var: &str) -> Self {
        Polynomial {
            var: var.to_string(),
            coeffs: vec![BigRational::zero(), BigRational::one()],
        }
    }

    pub fn normalize(&mut self) {
        while self.coeffs.len() > 1 && self.coeffs.last().map(|c| c.is_zero()).unwrap_or(false) {
            self.coeffs.pop();
        }
    }

    pub fn degree(&self) -> usize {
        let mut p = self.clone();
        p.normalize();
        if p.coeffs.is_empty() {
            0
        } else {
            p.coeffs.len() - 1
        }
    }

    pub fn is_zero(&self) -> bool {
        let mut p = self.clone();
        p.normalize();
        p.coeffs.len() == 1 && p.coeffs[0].is_zero()
    }

    pub fn add(&self, other: &Self) -> Result<Self, String> {
        let n = self.coeffs.len().max(other.coeffs.len());
        let mut coeffs = Vec::with_capacity(n);
        for i in 0..n {
            let a = self.coeffs.get(i).cloned().unwrap_or_else(BigRational::zero);
            let b = other.coeffs.get(i).cloned().unwrap_or_else(BigRational::zero);
            coeffs.push(&a + &b);
        }
        let mut res = Polynomial {
            var: self.var.clone(),
            coeffs,
        };
        res.normalize();
        Ok(res)
    }

    pub fn sub(&self, other: &Self) -> Result<Self, String> {
        let n = self.coeffs.len().max(other.coeffs.len());
        let mut coeffs = Vec::with_capacity(n);
        for i in 0..n {
            let a = self.coeffs.get(i).cloned().unwrap_or_else(BigRational::zero);
            let b = other.coeffs.get(i).cloned().unwrap_or_else(BigRational::zero);
            coeffs.push(&a - &b);
        }
        let mut res = Polynomial {
            var: self.var.clone(),
            coeffs,
        };
        res.normalize();
        Ok(res)
    }

    pub fn mul(&self, other: &Self) -> Result<Self, String> {
        if self.is_zero() || other.is_zero() {
            return Ok(Polynomial::zero(&self.var));
        }
        let mut coeffs = vec![BigRational::zero(); self.coeffs.len() + other.coeffs.len() - 1];
        for (i, a) in self.coeffs.iter().enumerate() {
            for (j, b) in other.coeffs.iter().enumerate() {
                let term = a * b;
                coeffs[i + j] = &coeffs[i + j] + &term;
            }
        }
        let mut res = Polynomial {
            var: self.var.clone(),
            coeffs,
        };
        res.normalize();
        Ok(res)
    }

    pub fn div_constant(&self, c: &BigRational) -> Result<Self, String> {
        if c.is_zero() {
            return Err("division by zero in polynomial calculation".to_string());
        }
        let mut coeffs = Vec::with_capacity(self.coeffs.len());
        for a in &self.coeffs {
            coeffs.push(a / c);
        }
        let mut res = Polynomial {
            var: self.var.clone(),
            coeffs,
        };
        res.normalize();
        Ok(res)
    }

    pub fn pow(&self, exp: u32) -> Result<Self, String> {
        if exp == 0 {
            return Ok(Polynomial::constant(&self.var, BigRational::one()));
        }
        let mut acc = self.clone();
        for _ in 1..exp {
            acc = acc.mul(self)?;
        }
        Ok(acc)
    }

    pub fn from_expr(expr: &Expr, var: &str) -> Result<Self, String> {
        let expanded = expr.expand_raw();
        Self::from_expanded_expr(&expanded, var)
    }

    fn from_expanded_expr(expr: &Expr, var: &str) -> Result<Self, String> {
        match expr {
            Expr::Number(n) => Ok(Polynomial::constant(var, n.clone())),
            Expr::Variable(v) if v == var => Ok(Polynomial::variable(var)),
            Expr::Variable(_) => Err(format!("multivariate expression in single-variable solver: {}", expr)),
            Expr::Constant(c) => Err(format!("symbolic constant in polynomial solver: {}", c)),
            Expr::Neg(inner) => {
                let p = Self::from_expanded_expr(inner, var)?;
                Polynomial::zero(var).sub(&p)
            }
            Expr::Add(a, b) => {
                let pa = Self::from_expanded_expr(a, var)?;
                let pb = Self::from_expanded_expr(b, var)?;
                pa.add(&pb)
            }
            Expr::Sub(a, b) => {
                let pa = Self::from_expanded_expr(a, var)?;
                let pb = Self::from_expanded_expr(b, var)?;
                pa.sub(&pb)
            }
            Expr::Mul(a, b) => {
                let pa = Self::from_expanded_expr(a, var)?;
                let pb = Self::from_expanded_expr(b, var)?;
                pa.mul(&pb)
            }
            Expr::Div(a, b) => {
                let pb = Self::from_expanded_expr(b, var)?;
                if pb.degree() == 0 && !pb.is_zero() {
                    let pa = Self::from_expanded_expr(a, var)?;
                    pa.div_constant(&pb.coeffs[0])
                } else {
                    Err(format!("division by non-constant polynomial: {}", expr))
                }
            }
            Expr::Pow(base, exp) => {
                if *exp < 0 {
                    return Err(format!("negative power in polynomial: {}", expr));
                }
                let pb = Self::from_expanded_expr(base, var)?;
                pb.pow(*exp as u32)
            }
            Expr::Equation(l, r) => {
                let pl = Self::from_expanded_expr(l, var)?;
                let pr = Self::from_expanded_expr(r, var)?;
                pl.sub(&pr)
            }
            Expr::Function(name, args) => {
                Err(format!("unsupported function in polynomial solver: {}({:?})", name, args))
            }
        }
    }

    pub fn to_expr(&self) -> Expr {
        let mut p = self.clone();
        p.normalize();
        if p.is_zero() {
            return Expr::num(0);
        }

        let mut result: Option<Expr> = None;
        for i in (0..p.coeffs.len()).rev() {
            let c = &p.coeffs[i];
            if c.is_zero() {
                continue;
            }
            let is_neg = c.is_negative();
            let abs_c = c.abs();
            let term = if i == 0 {
                Expr::Number(abs_c)
            } else if i == 1 {
                if abs_c.is_one() {
                    Expr::var(&p.var)
                } else {
                    Expr::Mul(Box::new(Expr::Number(abs_c)), Box::new(Expr::var(&p.var)))
                }
            } else {
                let power = Expr::Pow(Box::new(Expr::var(&p.var)), i as i32);
                if abs_c.is_one() {
                    power
                } else {
                    Expr::Mul(Box::new(Expr::Number(abs_c)), Box::new(power))
                }
            };
            result = match result {
                None => {
                    if is_neg {
                        Some(Expr::Neg(Box::new(term)))
                    } else {
                        Some(term)
                    }
                }
                Some(prev) => {
                    if is_neg {
                        Some(Expr::Sub(Box::new(prev), Box::new(term)))
                    } else {
                        Some(Expr::Add(Box::new(prev), Box::new(term)))
                    }
                }
            };
        }

        result.unwrap_or_else(|| Expr::num(0))
    }

    pub fn evaluate_rational(&self, x: &BigRational) -> BigRational {
        let mut res = BigRational::zero();
        let mut xp = BigRational::one();
        for c in &self.coeffs {
            res = &res + &(c * &xp);
            xp = &xp * x;
        }
        res
    }

    pub fn synthetic_divide_root(&self, r: &BigRational) -> (Polynomial, BigRational) {
        let deg = self.degree();
        if deg == 0 {
            return (Polynomial::zero(&self.var), self.coeffs[0].clone());
        }
        let mut q_coeffs = vec![BigRational::zero(); deg];
        let mut cur = BigRational::zero();
        for i in (0..=deg).rev() {
            let coeff = &self.coeffs[i];
            let val = &cur + coeff;
            if i > 0 {
                q_coeffs[i - 1] = val.clone();
                cur = &val * r;
            } else {
                cur = val;
            }
        }
        let mut q = Polynomial {
            var: self.var.clone(),
            coeffs: q_coeffs,
        };
        q.normalize();
        (q, cur)
    }

    pub fn solve(&self) -> Result<Vec<Expr>, String> {
        let mut p = self.clone();
        p.normalize();
        let deg = p.degree();

        if deg == 0 {
            if p.coeffs[0].is_zero() {
                return Err("identity equation: infinite solutions".to_string());
            } else {
                return Err("inconsistent equation: no solutions".to_string());
            }
        }

        if deg == 1 {
            let a1 = &p.coeffs[1];
            let a0 = &p.coeffs[0];
            let sol = &(-a0) / a1;
            return Ok(vec![Expr::Number(sol)]);
        }

        if deg == 2 {
            let a2 = &p.coeffs[2];
            let a1 = &p.coeffs[1];
            let a0 = &p.coeffs[0];
            let four = BigRational::from_i64(4);
            let two = BigRational::from_i64(2);
            let four_ac = &(&four * a2) * a0;
            let a1_sq = a1 * a1;
            let delta = &a1_sq - &four_ac;

            if delta.is_zero() {
                let sol = (-a1) / (&two * a2);
                return Ok(vec![Expr::Number(sol)]);
            } else if delta.is_negative() {
                let real = (-a1) / (&two * a2);
                let im_val = (-delta.to_f64()).sqrt() / (2.0 * a2.to_f64());
                let sol1 = format!("{} + {}*i", real, im_val);
                let sol2 = format!("{} - {}*i", real, im_val);
                return Ok(vec![Expr::Variable(sol1), Expr::Variable(sol2)]);
            } else if let Some(sqrt_delta) = delta.exact_sqrt() {
                let sol1 = (&(-a1) + &sqrt_delta) / (&two * a2);
                let sol2 = (&(-a1) - &sqrt_delta) / (&two * a2);
                let mut sorted = vec![sol1, sol2];
                sorted.sort();
                return Ok(vec![Expr::Number(sorted[0].clone()), Expr::Number(sorted[1].clone())]);
            } else {
                let d_f = delta.to_f64().sqrt();
                let mut sol1_f = (-a1.to_f64() + d_f) / (2.0 * a2.to_f64());
                let mut sol2_f = (-a1.to_f64() - d_f) / (2.0 * a2.to_f64());
                if sol1_f > sol2_f {
                    std::mem::swap(&mut sol1_f, &mut sol2_f);
                }
                return Ok(vec![
                    Expr::Number(BigRational::from_f64(sol1_f).unwrap_or_else(BigRational::zero)),
                    Expr::Number(BigRational::from_f64(sol2_f).unwrap_or_else(BigRational::zero)),
                ]);
            }
        }

        // Higher degree (>= 3): Rational Root Theorem
        let mut roots = Vec::new();
        let mut current_p = p.clone();

        while current_p.coeffs.len() > 1 && current_p.coeffs[0].is_zero() {
            roots.push(Expr::Number(BigRational::zero()));
            current_p.coeffs.remove(0);
            current_p.normalize();
        }

        if current_p.degree() <= 2 {
            if current_p.degree() > 0 {
                let sub_roots = current_p.solve()?;
                roots.extend(sub_roots);
            }
            roots.sort_by(|a, b| {
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    na.cmp(nb)
                } else {
                    std::cmp::Ordering::Equal
                }
            });
            return Ok(roots);
        }

        let a0 = current_p.coeffs[0].clone();
        let an = current_p.coeffs[current_p.degree()].clone();

        let p_divs = get_integer_divisors(a0.numer.abs().to_string().parse::<u64>().unwrap_or(1));
        let q_divs = get_integer_divisors(an.numer.abs().to_string().parse::<u64>().unwrap_or(1));

        let mut found_rational_root = false;
        for &pv in &p_divs {
            for &qv in &q_divs {
                for sign in &[1i64, -1i64] {
                    let test_r = BigRational::from_fraction(*sign * pv as i64, qv as i64);
                    if current_p.evaluate_rational(&test_r).is_zero() {
                        roots.push(Expr::Number(test_r.clone()));
                        let (q, _) = current_p.synthetic_divide_root(&test_r);
                        current_p = q;
                        found_rational_root = true;
                        break;
                    }
                }
                if found_rational_root {
                    break;
                }
            }
            if found_rational_root {
                break;
            }
        }

        if found_rational_root {
            if current_p.degree() > 0 {
                let sub_roots = current_p.solve()?;
                roots.extend(sub_roots);
            }
            roots.sort_by(|a, b| {
                if let (Expr::Number(na), Expr::Number(nb)) = (a, b) {
                    na.cmp(nb)
                } else {
                    std::cmp::Ordering::Equal
                }
            });
            return Ok(roots);
        }

        Err(format!("exact polynomial root solver could not find closed rational roots for degree {}", current_p.degree()))
    }
}

fn get_integer_divisors(n: u64) -> Vec<u64> {
    if n == 0 {
        return vec![1];
    }
    let mut divs = Vec::new();
    let limit = (n as f64).sqrt() as u64;
    for d in 1..=limit {
        if n % d == 0 {
            divs.push(d);
            if d * d != n {
                divs.push(n / d);
            }
        }
    }
    divs.sort_unstable();
    divs
}

pub fn extract_quadratic_coeffs(expr: &Expr, var: &str) -> Result<(BigRational, BigRational, BigRational), String> {
    let poly = Polynomial::from_expr(expr, var)?;
    let c0 = poly.coeffs.get(0).cloned().unwrap_or_else(BigRational::zero);
    let c1 = poly.coeffs.get(1).cloned().unwrap_or_else(BigRational::zero);
    let c2 = poly.coeffs.get(2).cloned().unwrap_or_else(BigRational::zero);
    if poly.degree() > 2 {
        return Err(format!("polynomial degree > 2 not supported in quadratic extraction: degree {}", poly.degree()));
    }
    Ok((c2, c1, c0))
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
        let trimmed = input.trim();
        if trimmed.is_empty() {
            return Err("empty expression".to_string());
        }
        if let Some(rest) = trimmed.strip_prefix("solve ") {
            let rest_trimmed = rest.trim();
            if !rest_trimmed.starts_with('(') {
                if let Some(for_idx) = rest_trimmed.to_ascii_lowercase().find(" for ") {
                    let eq_part = rest_trimmed[..for_idx].trim();
                    let var_part = rest_trimmed[for_idx + 5..].trim();
                    return Self::parse(&format!("solve({}, {})", eq_part, var_part));
                } else {
                    return Self::parse(&format!("solve({})", rest_trimmed));
                }
            }
        }
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
                Some(c) if self.is_implicit_mul_allowed(&left, c) => {
                    let right = self.parse_power()?;
                    left = Expr::Mul(Box::new(left), Box::new(right));
                }
                _ => break,
            }
        }
        Ok(left)
    }

    fn is_implicit_mul_allowed(&self, left: &Expr, next_char: char) -> bool {
        match left {
            Expr::Number(_) => next_char == '(' || next_char.is_alphabetic() || next_char == '_',
            _ => next_char == '(',
        }
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
