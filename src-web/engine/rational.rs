// Exact BigInt and BigRational Engine for CENTL
// Free Computation Foundation - Apache-2.0

use std::cmp::Ordering;
use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Rem, Sub};

#[derive(Clone, PartialEq, Eq)]
pub struct BigInt {
    pub sign: bool, // true = positive or zero, false = negative
    pub digits: Vec<u32>, // base 10^9 digits, least significant first
}

const BASE: u64 = 1_000_000_000;

impl BigInt {
    pub fn zero() -> Self {
        BigInt {
            sign: true,
            digits: vec![0],
        }
    }

    pub fn one() -> Self {
        BigInt {
            sign: true,
            digits: vec![1],
        }
    }

    pub fn from_i64(n: i64) -> Self {
        if n == 0 {
            return Self::zero();
        }
        let sign = n >= 0;
        let mut u = if n < 0 {
            if n == i64::MIN {
                (i64::MAX as u64) + 1
            } else {
                (-n) as u64
            }
        } else {
            n as u64
        };
        let mut digits = Vec::new();
        while u > 0 {
            digits.push((u % BASE) as u32);
            u /= BASE;
        }
        BigInt { sign, digits }
    }

    pub fn from_u64(mut u: u64) -> Self {
        if u == 0 {
            return Self::zero();
        }
        let mut digits = Vec::new();
        while u > 0 {
            digits.push((u % BASE) as u32);
            u /= BASE;
        }
        BigInt { sign: true, digits }
    }

    pub fn from_str(s: &str) -> Result<Self, String> {
        let s = s.trim();
        if s.is_empty() {
            return Err("empty string".to_string());
        }
        let (sign, digits_str) = if s.starts_with('-') {
            (false, &s[1..])
        } else if s.starts_with('+') {
            (true, &s[1..])
        } else {
            (true, s)
        };
        if digits_str.is_empty() || !digits_str.chars().all(|c| c.is_ascii_digit()) {
            return Err(format!("invalid integer literal: {}", s));
        }
        let trimmed = digits_str.trim_start_matches('0');
        if trimmed.is_empty() {
            return Ok(Self::zero());
        }
        let mut result = Self::zero();
        let ten = Self::from_i64(10);
        for c in trimmed.chars() {
            let d = c.to_digit(10).unwrap() as i64;
            result = &(&result * &ten) + &Self::from_i64(d);
        }
        result.sign = sign;
        Ok(result)
    }

    pub fn is_zero(&self) -> bool {
        self.digits.is_empty() || (self.digits.len() == 1 && self.digits[0] == 0)
    }

    pub fn is_one(&self) -> bool {
        self.sign && self.digits.len() == 1 && self.digits[0] == 1
    }

    pub fn is_negative(&self) -> bool {
        !self.sign && !self.is_zero()
    }

    pub fn is_even(&self) -> bool {
        if self.is_zero() {
            true
        } else {
            self.digits[0] % 2 == 0
        }
    }

    pub fn abs(&self) -> Self {
        BigInt {
            sign: true,
            digits: self.digits.clone(),
        }
    }

    fn trim(&mut self) {
        while self.digits.len() > 1 && *self.digits.last().unwrap() == 0 {
            self.digits.pop();
        }
        if self.digits.is_empty() {
            self.digits.push(0);
            self.sign = true;
        } else if self.digits.len() == 1 && self.digits[0] == 0 {
            self.sign = true;
        }
    }

    fn cmp_abs(&self, other: &Self) -> Ordering {
        if self.digits.len() != other.digits.len() {
            return self.digits.len().cmp(&other.digits.len());
        }
        for (a, b) in self.digits.iter().rev().zip(other.digits.iter().rev()) {
            if a != b {
                return a.cmp(b);
            }
        }
        Ordering::Equal
    }

    pub fn to_i64(&self) -> Option<i64> {
        if self.digits.len() > 3 {
            return None;
        }
        let mut val: u64 = 0;
        let mut mul: u64 = 1;
        for &d in &self.digits {
            val = val.checked_add((d as u64).checked_mul(mul)?)?;
            mul = mul.checked_mul(BASE)?;
        }
        if self.sign {
            if val <= i64::MAX as u64 {
                Some(val as i64)
            } else {
                None
            }
        } else {
            if val <= (i64::MAX as u64) + 1 {
                Some(-(val as i64))
            } else {
                None
            }
        }
    }

    pub fn to_f64(&self) -> f64 {
        let mut res = 0.0;
        let mut factor = 1.0;
        for &d in &self.digits {
            res += (d as f64) * factor;
            factor *= BASE as f64;
        }
        if self.sign {
            res
        } else {
            -res
        }
    }

    pub fn pow(&self, exp: u32) -> Self {
        if exp == 0 {
            return Self::one();
        }
        if exp == 1 {
            return self.clone();
        }
        let mut base = self.clone();
        let mut result = Self::one();
        let mut e = exp;
        while e > 0 {
            if e % 2 == 1 {
                result = &result * &base;
            }
            if e > 1 {
                base = &base * &base;
            }
            e /= 2;
        }
        result
    }

    pub fn gcd(a: &Self, b: &Self) -> Self {
        let mut x = a.abs();
        let mut y = b.abs();
        while !y.is_zero() {
            let r = &x % &y;
            x = y;
            y = r;
        }
        x
    }

    pub fn lcm(a: &Self, b: &Self) -> Self {
        if a.is_zero() || b.is_zero() {
            return Self::zero();
        }
        let g = Self::gcd(a, b);
        let div = &a.abs() / &g;
        &div * &b.abs()
    }
}

impl PartialOrd for BigInt {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for BigInt {
    fn cmp(&self, other: &Self) -> Ordering {
        if self.sign != other.sign {
            if self.is_zero() && other.is_zero() {
                return Ordering::Equal;
            }
            return if self.sign {
                Ordering::Greater
            } else {
                Ordering::Less
            };
        }
        let ord = self.cmp_abs(other);
        if self.sign {
            ord
        } else {
            ord.reverse()
        }
    }
}

impl<'a, 'b> Add<&'b BigInt> for &'a BigInt {
    type Output = BigInt;
    fn add(self, other: &'b BigInt) -> BigInt {
        if self.sign == other.sign {
            let mut digits = Vec::new();
            let mut carry: u64 = 0;
            let n = self.digits.len().max(other.digits.len());
            for i in 0..n {
                let d1 = self.digits.get(i).copied().unwrap_or(0) as u64;
                let d2 = other.digits.get(i).copied().unwrap_or(0) as u64;
                let sum = d1 + d2 + carry;
                digits.push((sum % BASE) as u32);
                carry = sum / BASE;
            }
            if carry > 0 {
                digits.push(carry as u32);
            }
            let mut res = BigInt {
                sign: self.sign,
                digits,
            };
            res.trim();
            res
        } else {
            if self.cmp_abs(other) >= Ordering::Equal {
                let mut digits = Vec::new();
                let mut borrow: i64 = 0;
                for i in 0..self.digits.len() {
                    let d1 = self.digits[i] as i64;
                    let d2 = other.digits.get(i).copied().unwrap_or(0) as i64;
                    let diff = d1 - d2 - borrow;
                    if diff < 0 {
                        digits.push((diff + BASE as i64) as u32);
                        borrow = 1;
                    } else {
                        digits.push(diff as u32);
                        borrow = 0;
                    }
                }
                let mut res = BigInt {
                    sign: self.sign,
                    digits,
                };
                res.trim();
                res
            } else {
                other + self
            }
        }
    }
}

impl Add for BigInt {
    type Output = BigInt;
    fn add(self, other: BigInt) -> BigInt {
        &self + &other
    }
}

impl<'a, 'b> Sub<&'b BigInt> for &'a BigInt {
    type Output = BigInt;
    fn sub(self, other: &'b BigInt) -> BigInt {
        let mut neg_other = other.clone();
        if !neg_other.is_zero() {
            neg_other.sign = !neg_other.sign;
        }
        self + &neg_other
    }
}

impl Sub for BigInt {
    type Output = BigInt;
    fn sub(self, other: BigInt) -> BigInt {
        &self - &other
    }
}

impl<'a, 'b> Mul<&'b BigInt> for &'a BigInt {
    type Output = BigInt;
    fn mul(self, other: &'b BigInt) -> BigInt {
        if self.is_zero() || other.is_zero() {
            return BigInt::zero();
        }
        let mut digits = vec![0u64; self.digits.len() + other.digits.len()];
        for (i, &d1) in self.digits.iter().enumerate() {
            let mut carry = 0u64;
            for (j, &d2) in other.digits.iter().enumerate() {
                let cur = digits[i + j] + (d1 as u64) * (d2 as u64) + carry;
                digits[i + j] = cur % BASE;
                carry = cur / BASE;
            }
            if carry > 0 {
                digits[i + other.digits.len()] += carry;
            }
        }
        let d32: Vec<u32> = digits.into_iter().map(|x| x as u32).collect();
        let mut res = BigInt {
            sign: self.sign == other.sign,
            digits: d32,
        };
        res.trim();
        res
    }
}

impl Mul for BigInt {
    type Output = BigInt;
    fn mul(self, other: BigInt) -> BigInt {
        &self * &other
    }
}

impl<'a, 'b> Div<&'b BigInt> for &'a BigInt {
    type Output = BigInt;
    fn div(self, other: &'b BigInt) -> BigInt {
        if other.is_zero() {
            panic!("division by zero in BigInt");
        }
        let (q, _) = div_rem_abs(self, other);
        let mut res = q;
        res.sign = self.sign == other.sign || res.is_zero();
        res
    }
}

impl Div for BigInt {
    type Output = BigInt;
    fn div(self, other: BigInt) -> BigInt {
        &self / &other
    }
}

impl<'a, 'b> Rem<&'b BigInt> for &'a BigInt {
    type Output = BigInt;
    fn rem(self, other: &'b BigInt) -> BigInt {
        if other.is_zero() {
            panic!("remainder by zero in BigInt");
        }
        let (_, r) = div_rem_abs(self, other);
        let mut res = r;
        res.sign = self.sign || res.is_zero();
        res
    }
}

impl Rem for BigInt {
    type Output = BigInt;
    fn rem(self, other: BigInt) -> BigInt {
        &self % &other
    }
}

impl Neg for BigInt {
    type Output = BigInt;
    fn neg(mut self) -> BigInt {
        if !self.is_zero() {
            self.sign = !self.sign;
        }
        self
    }
}

impl<'a> Neg for &'a BigInt {
    type Output = BigInt;
    fn neg(self) -> BigInt {
        let mut res = self.clone();
        if !res.is_zero() {
            res.sign = !res.sign;
        }
        res
    }
}

fn div_rem_abs(a: &BigInt, b: &BigInt) -> (BigInt, BigInt) {
    if a.cmp_abs(b) == Ordering::Less {
        return (BigInt::zero(), a.abs());
    }
    if b.digits.len() == 1 {
        let divisor = b.digits[0] as u64;
        let mut q_digits = vec![0u32; a.digits.len()];
        let mut rem = 0u64;
        for i in (0..a.digits.len()).rev() {
            let cur = rem * BASE + (a.digits[i] as u64);
            q_digits[i] = (cur / divisor) as u32;
            rem = cur % divisor;
        }
        let mut q = BigInt {
            sign: true,
            digits: q_digits,
        };
        q.trim();
        let mut r = BigInt::from_u64(rem);
        r.trim();
        return (q, r);
    }
    // Binary long division for arbitrary sizes
    let mut quotient = BigInt::zero();
    let mut remainder = BigInt::zero();

    let a_str = a.abs().to_string();
    for c in a_str.chars() {
        let d = c.to_digit(10).unwrap() as i64;
        remainder = &(&remainder * &BigInt::from_i64(10)) + &BigInt::from_i64(d);
        let mut digit = 0;
        let b_abs = b.abs();
        while remainder >= b_abs {
            remainder = &remainder - &b_abs;
            digit += 1;
        }
        quotient = &(&quotient * &BigInt::from_i64(10)) + &BigInt::from_i64(digit);
    }
    quotient.trim();
    remainder.trim();
    (quotient, remainder)
}

impl fmt::Display for BigInt {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.is_zero() {
            return write!(f, "0");
        }
        if !self.sign {
            write!(f, "-")?;
        }
        let len = self.digits.len();
        write!(f, "{}", self.digits[len - 1])?;
        for i in (0..len - 1).rev() {
            write!(f, "{:09}", self.digits[i])?;
        }
        Ok(())
    }
}

impl fmt::Debug for BigInt {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self)
    }
}

// -------------------------------------------------------------
// BigRational (Exact a/b fraction)
// -------------------------------------------------------------

#[derive(Clone, PartialEq, Eq)]
pub struct BigRational {
    pub numer: BigInt,
    pub denom: BigInt,
}

impl BigRational {
    pub fn new(mut numer: BigInt, mut denom: BigInt) -> Self {
        if denom.is_zero() {
            panic!("denominator cannot be zero in BigRational");
        }
        if denom.is_negative() {
            numer = -numer;
            denom = -denom;
        }
        if numer.is_zero() {
            return BigRational {
                numer: BigInt::zero(),
                denom: BigInt::one(),
            };
        }
        let g = BigInt::gcd(&numer, &denom);
        if !g.is_one() && !g.is_zero() {
            numer = &numer / &g;
            denom = &denom / &g;
        }
        BigRational { numer, denom }
    }

    pub fn zero() -> Self {
        BigRational {
            numer: BigInt::zero(),
            denom: BigInt::one(),
        }
    }

    pub fn one() -> Self {
        BigRational {
            numer: BigInt::one(),
            denom: BigInt::one(),
        }
    }

    pub fn from_i64(n: i64) -> Self {
        BigRational::new(BigInt::from_i64(n), BigInt::one())
    }

    pub fn from_bigint(n: BigInt) -> Self {
        BigRational::new(n, BigInt::one())
    }

    pub fn from_fraction(numer: i64, denom: i64) -> Self {
        BigRational::new(BigInt::from_i64(numer), BigInt::from_i64(denom))
    }

    pub fn from_u64(n: u64) -> Self {
        BigRational::new(BigInt::from_u64(n), BigInt::one())
    }

    pub fn from_f64(val: f64) -> Option<Self> {
        if val.is_nan() || val.is_infinite() {
            return None;
        }
        let s = format!("{:.8}", val);
        BigRational::from_str(&s).ok()
    }

    pub fn from_str(s: &str) -> Result<Self, String> {
        let s = s.trim();
        if let Some((n_str, d_str)) = s.split_once('/') {
            let n = BigInt::from_str(n_str)?;
            let d = BigInt::from_str(d_str)?;
            if d.is_zero() {
                return Err("division by zero in fraction".to_string());
            }
            Ok(BigRational::new(n, d))
        } else if let Some((int_part, frac_part)) = s.split_once('.') {
            // Decimal parsing e.g. "0.125" -> 125 / 1000 = 1/8
            let sign = !int_part.starts_with('-');
            let int_abs = int_part.trim_start_matches('-').trim_start_matches('+');
            let frac_len = frac_part.len() as u32;
            let full_str = format!("{}{}", int_abs, frac_part);
            let n = BigInt::from_str(&full_str)?;
            let ten = BigInt::from_i64(10);
            let d = ten.pow(frac_len);
            let res = BigRational::new(n, d);
            if sign {
                Ok(res)
            } else {
                Ok(-res)
            }
        } else {
            let n = BigInt::from_str(s)?;
            Ok(BigRational::from_bigint(n))
        }
    }

    pub fn is_integer(&self) -> bool {
        self.denom.is_one()
    }

    pub fn is_zero(&self) -> bool {
        self.numer.is_zero()
    }

    pub fn is_negative(&self) -> bool {
        self.numer.is_negative()
    }

    pub fn abs(&self) -> Self {
        BigRational {
            numer: self.numer.abs(),
            denom: self.denom.clone(),
        }
    }

    pub fn recip(&self) -> Result<Self, String> {
        if self.is_zero() {
            Err("division by zero".to_string())
        } else {
            Ok(BigRational::new(self.denom.clone(), self.numer.clone()))
        }
    }

    pub fn pow(&self, exp: i32) -> Result<Self, String> {
        if exp == 0 {
            return Ok(Self::one());
        }
        if exp > 0 {
            let n = self.numer.pow(exp as u32);
            let d = self.denom.pow(exp as u32);
            Ok(BigRational::new(n, d))
        } else {
            if self.is_zero() {
                return Err("cannot raise zero to negative power".to_string());
            }
            let pos_exp = (-exp) as u32;
            let n = self.denom.pow(pos_exp);
            let d = self.numer.pow(pos_exp);
            Ok(BigRational::new(n, d))
        }
    }

    pub fn to_f64(&self) -> f64 {
        self.numer.to_f64() / self.denom.to_f64()
    }

    pub fn to_decimal_string(&self, digits: usize) -> String {
        if self.is_zero() {
            return "0".to_string();
        }
        let sign_prefix = if self.is_negative() { "-" } else { "" };
        let num = self.numer.abs();
        let den = self.denom.abs();
        let int_part = &num / &den;
        let rem = &num % &den;
        if rem.is_zero() {
            return format!("{}{}", sign_prefix, int_part);
        }
        let mut frac_digits = String::new();
        let mut current_rem = rem;
        let ten = BigInt::from_i64(10);
        for _ in 0..digits {
            current_rem = &current_rem * &ten;
            let d = &current_rem / &den;
            frac_digits.push_str(&d.to_string());
            current_rem = &current_rem % &den;
            if current_rem.is_zero() {
                break;
            }
        }
        format!("{}{}.{}", sign_prefix, int_part, frac_digits)
    }
}

impl PartialOrd for BigRational {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for BigRational {
    fn cmp(&self, other: &Self) -> Ordering {
        let left = &self.numer * &other.denom;
        let right = &other.numer * &self.denom;
        left.cmp(&right)
    }
}

impl<'a, 'b> Add<&'b BigRational> for &'a BigRational {
    type Output = BigRational;
    fn add(self, other: &'b BigRational) -> BigRational {
        let n = &(&self.numer * &other.denom) + &(&other.numer * &self.denom);
        let d = &self.denom * &other.denom;
        BigRational::new(n, d)
    }
}

impl Add for BigRational {
    type Output = BigRational;
    fn add(self, other: BigRational) -> BigRational {
        &self + &other
    }
}

impl<'a, 'b> Sub<&'b BigRational> for &'a BigRational {
    type Output = BigRational;
    fn sub(self, other: &'b BigRational) -> BigRational {
        let n = &(&self.numer * &other.denom) - &(&other.numer * &self.denom);
        let d = &self.denom * &other.denom;
        BigRational::new(n, d)
    }
}

impl Sub for BigRational {
    type Output = BigRational;
    fn sub(self, other: BigRational) -> BigRational {
        &self - &other
    }
}

impl<'a, 'b> Mul<&'b BigRational> for &'a BigRational {
    type Output = BigRational;
    fn mul(self, other: &'b BigRational) -> BigRational {
        BigRational::new(&self.numer * &other.numer, &self.denom * &other.denom)
    }
}

impl Mul for BigRational {
    type Output = BigRational;
    fn mul(self, other: BigRational) -> BigRational {
        &self * &other
    }
}

impl<'a, 'b> Div<&'b BigRational> for &'a BigRational {
    type Output = BigRational;
    fn div(self, other: &'b BigRational) -> BigRational {
        if other.is_zero() {
            panic!("division by zero in BigRational");
        }
        BigRational::new(&self.numer * &other.denom, &self.denom * &other.numer)
    }
}

impl Div for BigRational {
    type Output = BigRational;
    fn div(self, other: BigRational) -> BigRational {
        &self / &other
    }
}

impl Neg for BigRational {
    type Output = BigRational;
    fn neg(self) -> BigRational {
        BigRational {
            numer: -self.numer,
            denom: self.denom,
        }
    }
}

impl<'a> Neg for &'a BigRational {
    type Output = BigRational;
    fn neg(self) -> BigRational {
        BigRational {
            numer: -&self.numer,
            denom: self.denom.clone(),
        }
    }
}

impl fmt::Display for BigRational {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.denom.is_one() {
            write!(f, "{}", self.numer)
        } else {
            write!(f, "{}/{}", self.numer, self.denom)
        }
    }
}

impl fmt::Debug for BigRational {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self)
    }
}
