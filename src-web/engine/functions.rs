// Mathematical and Geometric Functions for CENTL
// Free Computation Foundation - Apache-2.0

use super::rational::{BigInt, BigRational};

pub fn factorial(n: u64) -> Result<BigInt, String> {
    if n > 5000 {
        return Err("factorial argument too large (limit 5000)".to_string());
    }
    let mut res = BigInt::one();
    for i in 2..=n {
        res = &res * &BigInt::from_u64(i);
    }
    Ok(res)
}

pub fn choose(n: u64, k: u64) -> Result<BigInt, String> {
    if k > n {
        return Ok(BigInt::zero());
    }
    if k == 0 || k == n {
        return Ok(BigInt::one());
    }
    let k = k.min(n - k);
    let mut num = BigInt::one();
    let mut den = BigInt::one();
    for i in 1..=k {
        num = &num * &BigInt::from_u64(n - k + i);
        den = &den * &BigInt::from_u64(i);
    }
    Ok(&num / &den)
}

pub fn permutations(n: u64, k: u64) -> Result<BigInt, String> {
    if k > n {
        return Ok(BigInt::zero());
    }
    let mut res = BigInt::one();
    for i in (n - k + 1)..=n {
        res = &res * &BigInt::from_u64(i);
    }
    Ok(res)
}

pub fn fibonacci(n: u64) -> Result<BigInt, String> {
    if n == 0 {
        return Ok(BigInt::zero());
    }
    if n == 1 || n == 2 {
        return Ok(BigInt::one());
    }
    if n > 50000 {
        return Err("fibonacci index too large (limit 50000)".to_string());
    }
    let mut a = BigInt::zero();
    let mut b = BigInt::one();
    for _ in 2..=n {
        let next = &a + &b;
        a = b;
        b = next;
    }
    Ok(b)
}

// Geometry exact formulas
pub fn square_area(side: &BigRational) -> BigRational {
    side * side
}

pub fn rectangle_area(width: &BigRational, height: &BigRational) -> BigRational {
    width * height
}

pub fn rectangle_perimeter(width: &BigRational, height: &BigRational) -> BigRational {
    let two = BigRational::from_i64(2);
    &two * &(width + height)
}

pub fn triangle_area(base: &BigRational, height: &BigRational) -> BigRational {
    let half = BigRational::from_fraction(1, 2);
    &(&half * base) * height
}

pub fn trapezoid_area(b1: &BigRational, b2: &BigRational, height: &BigRational) -> BigRational {
    let half = BigRational::from_fraction(1, 2);
    let sum = b1 + b2;
    &(&half * &sum) * height
}

pub fn hypot(a: f64, b: f64) -> f64 {
    a.hypot(b)
}

pub fn distance(x1: f64, y1: f64, x2: f64, y2: f64) -> f64 {
    (x2 - x1).hypot(y2 - y1)
}

pub fn slope(x1: &BigRational, y1: &BigRational, x2: &BigRational, y2: &BigRational) -> Result<BigRational, String> {
    let dx = x2 - x1;
    if dx.is_zero() {
        return Err("vertical line: undefined slope (division by zero)".to_string());
    }
    let dy = y2 - y1;
    Ok(&dy / &dx)
}

pub fn is_prime(n: u64) -> bool {
    if n <= 1 {
        return false;
    }
    if n <= 3 {
        return true;
    }
    if n % 2 == 0 || n % 3 == 0 {
        return false;
    }
    let mut i = 5;
    while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 {
            return false;
        }
        i += 6;
    }
    true
}

pub fn prime_factors(mut n: u64) -> Vec<(u64, usize)> {
    let mut factors = Vec::new();
    if n == 0 {
        return factors;
    }
    let mut count = 0;
    while n % 2 == 0 {
        count += 1;
        n /= 2;
    }
    if count > 0 {
        factors.push((2, count));
    }
    let mut d = 3;
    while d * d <= n {
        let mut count = 0;
        while n % d == 0 {
            count += 1;
            n /= d;
        }
        if count > 0 {
            factors.push((d, count));
        }
        d += 2;
    }
    if n > 1 {
        factors.push((n, 1));
    }
    factors
}

pub fn factors(n: u64) -> Vec<u64> {
    if n == 0 {
        return Vec::new();
    }
    let mut small = Vec::new();
    let mut large = Vec::new();
    let mut i = 1;
    while i * i <= n {
        if n % i == 0 {
            small.push(i);
            if i * i != n {
                large.push(n / i);
            }
        }
        i += 1;
    }
    large.reverse();
    small.extend(large);
    small
}
