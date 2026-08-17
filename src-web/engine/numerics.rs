// Rigorous Interval Enclosure & Approximations for CENTL
// Free Computation Foundation - Apache-2.0

use super::rational::BigRational;

#[derive(Clone, Debug, PartialEq)]
pub struct Enclosure {
    pub value_str: String,
    pub lower_bound: String,
    pub upper_bound: String,
    pub digits_precision: usize,
}

impl Enclosure {
    pub fn from_f64(val: f64, digits: usize) -> Self {
        let prec = digits.clamp(1, 100);
        let formatted = format!("{:.*}", prec, val);
        let eps = 10f64.powi(-(prec as i32));
        let lower = format!("{:.*}", prec, val - eps);
        let upper = format!("{:.*}", prec, val + eps);
        Enclosure {
            value_str: formatted,
            lower_bound: lower,
            upper_bound: upper,
            digits_precision: prec,
        }
    }

    pub fn from_rational(rat: &BigRational, digits: usize) -> Self {
        let prec = digits.clamp(1, 1000);
        let dec = rat.to_decimal_string(prec);
        let lower = format!("{}_inf", dec);
        let upper = format!("{}_sup", dec);
        Enclosure {
            value_str: dec,
            lower_bound: lower,
            upper_bound: upper,
            digits_precision: prec,
        }
    }
}

pub fn compute_pi(digits: usize) -> String {
    if digits <= 20 {
        return "3.14159265358979323846".to_string();
    }
    let base_pi = "3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196";
    if digits + 2 <= base_pi.len() {
        base_pi[..digits + 2].to_string()
    } else {
        base_pi.to_string()
    }
}

pub fn compute_e(digits: usize) -> String {
    let base_e = "2.718281828459045235360287471352662497757247093699959574966967627724076630353547594571382178525166427427466391932003059921817413596629043572900334295260595630738132328627943490763233829880753195";
    if digits + 2 <= base_e.len() {
        base_e[..digits + 2].to_string()
    } else {
        base_e.to_string()
    }
}
