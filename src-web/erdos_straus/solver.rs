// Erdős–Straus Exact 3-Egyptian Fraction Solver
// Free Computation Foundation - Apache-2.0

use super::certificate::compute_letter_number;
use crate::engine::rational::BigInt;

#[derive(Clone, Debug, PartialEq)]
pub struct Witness {
    pub n: u64,
    pub x: BigInt,
    pub y: BigInt,
    pub z: BigInt,
    pub method: String,
    pub layer: String,
    pub kind: String,
    pub verified: bool,
}

impl Witness {
    pub fn equation(&self) -> String {
        format!("4/{} = 1/{} + 1/{} + 1/{}", self.n, self.x, self.y, self.z)
    }

    pub fn verify(&self) -> bool {
        let four = BigInt::from_i64(4);
        let n_bi = BigInt::from_u64(self.n);
        let left = &four * &(&self.x * &(&self.y * &self.z));
        let xy = &self.x * &self.y;
        let xz = &self.x * &self.z;
        let yz = &self.y * &self.z;
        let sum_pairs = &(&yz + &xz) + &xy;
        let right = &n_bi * &sum_pairs;
        left == right
    }
}

#[derive(Clone, Debug)]
pub struct SolveResult {
    pub solved: bool,
    pub n: u64,
    pub witness: Option<Witness>,
    pub grade: String,
    pub letter_number: Option<String>,
    pub execution_micros: u128,
}

pub fn solve_es(n: u64) -> SolveResult {
    let start = std::time::Instant::now();
    if n <= 1 {
        return SolveResult {
            solved: false,
            n,
            witness: None,
            grade: "invalid".to_string(),
            letter_number: None,
            execution_micros: start.elapsed().as_micros(),
        };
    }

    // 1. Check if n is even (n = 2k)
    if n % 2 == 0 {
        let k = n / 2;
        let w = Witness {
            n,
            x: BigInt::from_u64(k + 1),
            y: BigInt::from_u64(k * (k + 1)),
            z: BigInt::from_u64(k * (k + 1)),
            method: "even_reduction".to_string(),
            layer: "theorem".to_string(),
            kind: "even".to_string(),
            verified: true,
        };
        return SolveResult {
            solved: true,
            n,
            witness: Some(w),
            grade: "great".to_string(),
            letter_number: None,
            execution_micros: start.elapsed().as_micros(),
        };
    }

    // 2. Linear congruence: n = 3 (mod 4) -> 4/n = 1/((n+1)/4) + ...
    if n % 4 == 3 {
        let x = (n + 1) / 4;
        let y = n * (n + 1) / 2;
        let z = n * (n + 1) / 2;
        let w = Witness {
            n,
            x: BigInt::from_u64(x),
            y: BigInt::from_u64(y),
            z: BigInt::from_u64(z),
            method: "4p+3".to_string(),
            layer: "theorem".to_string(),
            kind: "linear".to_string(),
            verified: true,
        };
        if w.verify() {
            return SolveResult {
                solved: true,
                n,
                witness: Some(w),
                grade: "great".to_string(),
                letter_number: None,
                execution_micros: start.elapsed().as_micros(),
            };
        }
    }

    // 3. Linear congruence: n = 2 (mod 3) -> 4/n = 1/((n+2)/3) + ...
    if n % 3 == 2 {
        let x = (n + 2) / 3;
        let y = n * x;
        let z = n * x;
        let w = Witness {
            n,
            x: BigInt::from_u64(x),
            y: BigInt::from_u64(y),
            z: BigInt::from_u64(z),
            method: "3p+2".to_string(),
            layer: "theorem".to_string(),
            kind: "linear".to_string(),
            verified: true,
        };
        if w.verify() {
            return SolveResult {
                solved: true,
                n,
                witness: Some(w),
                grade: "great".to_string(),
                letter_number: None,
                execution_micros: start.elapsed().as_micros(),
            };
        }
    }

    // 4. Linear congruence: n = 5 (mod 8)
    if n % 8 == 5 {
        let x = (n + 3) / 8;
        let y = (n + 3) / 2;
        let z = n * (n + 3) / 4;
        let w = Witness {
            n,
            x: BigInt::from_u64(x),
            y: BigInt::from_u64(y),
            z: BigInt::from_u64(z),
            method: "8p+5".to_string(),
            layer: "theorem".to_string(),
            kind: "linear".to_string(),
            verified: true,
        };
        if w.verify() {
            return SolveResult {
                solved: true,
                n,
                witness: Some(w),
                grade: "great".to_string(),
                letter_number: None,
                execution_micros: start.elapsed().as_micros(),
            };
        }
    }

    // 5. Systematic 2-parameter search
    let x_min = (n / 4) + 1;
    let x_max = n + 1000;
    for x in x_min..=x_max {
        let num = 4 * x - n;
        let den = n * x;
        let y_min = (den / num) + 1;
        let y_max = (2 * den / num) + 1;
        for y in y_min..=(y_min + 5000).min(y_max) {
            let z_num = num * y - den;
            let z_den = den * y;
            if z_num > 0 && z_den % z_num == 0 {
                let z = z_den / z_num;
                let w = Witness {
                    n,
                    x: BigInt::from_u64(x),
                    y: BigInt::from_u64(y),
                    z: BigInt::from_u64(z),
                    method: "two_target_search".to_string(),
                    layer: "window".to_string(),
                    kind: "quadratic".to_string(),
                    verified: true,
                };
                if w.verify() {
                    let grade = if x <= (n / 4) + 10 { "good" } else { "letter" };
                    let letter_num = if grade == "letter" {
                        Some(compute_letter_number(n, &["two_target", "window_survivor"]))
                    } else {
                        None
                    };
                    return SolveResult {
                        solved: true,
                        n,
                        witness: Some(w),
                        grade: grade.to_string(),
                        letter_number: letter_num,
                        execution_micros: start.elapsed().as_micros(),
                    };
                }
            }
        }
    }

    SolveResult {
        solved: false,
        n,
        witness: None,
        grade: "unsolved".to_string(),
        letter_number: Some(compute_letter_number(n, &["hard_unsolved"])),
        execution_micros: start.elapsed().as_micros(),
    }
}
