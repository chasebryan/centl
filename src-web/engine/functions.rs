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

/// Extended Euclidean Algorithm: returns (gcd, x, y) such that a*x + b*y = gcd
pub fn xgcd(a: i64, b: i64) -> (i64, i64, i64) {
    if b == 0 {
        if a < 0 {
            (-a, -1, 0)
        } else {
            (a, 1, 0)
        }
    } else {
        let (g, x1, y1) = xgcd(b, a % b);
        let x = y1;
        let y = x1 - (a / b) * y1;
        (g, x, y)
    }
}

/// Modular multiplicative inverse: a^-1 mod m
pub fn modinv(a: i64, m: i64) -> Result<i64, String> {
    if m <= 1 {
        return Err("modulus m must be > 1".to_string());
    }
    let a_mod = ((a % m) + m) % m;
    let (g, x, _) = xgcd(a_mod, m);
    if g != 1 {
        return Err(format!("{} has no modular inverse modulo {}", a, m));
    }
    Ok(((x % m) + m) % m)
}

/// Modular exponentiation: (base^exp) % m
pub fn modpow(base: u64, mut exp: u64, m: u64) -> u64 {
    if m == 1 {
        return 0;
    }
    let mut res: u128 = 1;
    let mut b = (base % m) as u128;
    let modulus = m as u128;
    while exp > 0 {
        if exp % 2 == 1 {
            res = (res * b) % modulus;
        }
        b = (b * b) % modulus;
        exp /= 2;
    }
    res as u64
}

/// Euler's totient function: count of 1 <= k <= n coprime to n
pub fn totient(n: u64) -> u64 {
    if n == 0 {
        return 0;
    }
    let mut result = n;
    let mut p = 2;
    let mut temp = n;
    while p * p <= temp {
        if temp % p == 0 {
            while temp % p == 0 {
                temp /= p;
            }
            result -= result / p;
        }
        p += 1;
    }
    if temp > 1 {
        result -= result / temp;
    }
    result
}

/// Least common multiple
pub fn lcm_u64(a: u64, b: u64) -> u64 {
    if a == 0 || b == 0 {
        return 0;
    }
    let gcd = {
        let mut x = a;
        let mut y = b;
        while y != 0 {
            let t = y;
            y = x % y;
            x = t;
        }
        x
    };
    (a / gcd) * b
}

/// 2x2 Matrix Determinant: det([[a, b], [c, d]]) = a*d - b*c
pub fn det2(a: f64, b: f64, c: f64, d: f64) -> f64 {
    a * d - b * c
}

/// 3x3 Matrix Determinant
pub fn det3(m: &[[f64; 3]; 3]) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
        - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}

/// 2x2 Matrix Inverse: returns [d/det, -b/det, -c/det, a/det]
pub fn inv2(a: f64, b: f64, c: f64, d: f64) -> Result<[f64; 4], String> {
    let det = det2(a, b, c, d);
    if det.abs() < 1e-15 {
        return Err("singular matrix: determinant is zero, no inverse exists".to_string());
    }
    Ok([d / det, -b / det, -c / det, a / det])
}

/// 3D Vector Dot Product
pub fn dot3(v1: (f64, f64, f64), v2: (f64, f64, f64)) -> f64 {
    v1.0 * v2.0 + v1.1 * v2.1 + v1.2 * v2.2
}

/// 3D Vector Cross Product
pub fn cross3(v1: (f64, f64, f64), v2: (f64, f64, f64)) -> (f64, f64, f64) {
    (
        v1.1 * v2.2 - v1.2 * v2.1,
        v1.2 * v2.0 - v1.0 * v2.2,
        v1.0 * v2.1 - v1.1 * v2.0,
    )
}

/// 3D Vector Norm / Magnitude
pub fn norm3(v: (f64, f64, f64)) -> f64 {
    (v.0 * v.0 + v.1 * v.1 + v.2 * v.2).sqrt()
}

/// Statistical Mean
pub fn mean(values: &[f64]) -> Result<f64, String> {
    if values.is_empty() {
        return Err("mean requires at least one value".to_string());
    }
    let sum: f64 = values.iter().sum();
    Ok(sum / (values.len() as f64))
}

/// Statistical Sample Variance
pub fn variance(values: &[f64]) -> Result<f64, String> {
    if values.len() < 2 {
        return Err("sample variance requires at least two values".to_string());
    }
    let m = mean(values)?;
    let sq_diff_sum: f64 = values.iter().map(|x| (x - m).powi(2)).sum();
    Ok(sq_diff_sum / ((values.len() - 1) as f64))
}

/// Statistical Sample Standard Deviation
pub fn stddev(values: &[f64]) -> Result<f64, String> {
    Ok(variance(values)?.sqrt())
}

/// Normal Distribution Probability Density Function
pub fn normal_pdf(x: f64, mu: f64, sigma: f64) -> Result<f64, String> {
    if sigma <= 0.0 {
        return Err("standard deviation sigma must be > 0".to_string());
    }
    let z = (x - mu) / sigma;
    let inv_sqrt_2pi = 0.3989422804014327;
    Ok((inv_sqrt_2pi / sigma) * (-0.5 * z * z).exp())
}

/// Standard Normal Cumulative Distribution Function (Abramowitz & Stegun approx, max error 7.5e-8)
pub fn normal_cdf(x: f64, mu: f64, sigma: f64) -> Result<f64, String> {
    if sigma <= 0.0 {
        return Err("standard deviation sigma must be > 0".to_string());
    }
    let z = (x - mu) / sigma;
    let t = 1.0 / (1.0 + 0.2316419 * z.abs());
    let d = 0.3989422804014327 * (-0.5 * z * z).exp();
    let poly = t * (0.319381530 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429))));
    let p = 1.0 - d * poly;
    if z < 0.0 {
        Ok(1.0 - p)
    } else {
        Ok(p)
    }
}

/// Binomial Probability Mass Function: P(X = k) = C(n, k) * p^k * (1-p)^(n-k)
pub fn binomial_pmf(k: u64, n: u64, p: f64) -> Result<f64, String> {
    if k > n {
        return Ok(0.0);
    }
    if p < 0.0 || p > 1.0 {
        return Err("probability p must be between 0.0 and 1.0".to_string());
    }
    let c = choose(n, k)?.to_f64();
    Ok(c * p.powi(k as i32) * (1.0 - p).powi((n - k) as i32))
}

/// Poisson Probability Mass Function: P(X = k) = (lambda^k * e^-lambda) / k!
pub fn poisson_pmf(k: u64, lambda: f64) -> Result<f64, String> {
    if lambda <= 0.0 {
        return Err("poisson rate parameter lambda must be > 0".to_string());
    }
    let mut log_p = (k as f64) * lambda.ln() - lambda;
    for i in 1..=k {
        log_p -= (i as f64).ln();
    }
    Ok(log_p.exp())
}
