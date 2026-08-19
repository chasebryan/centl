// Public Erdős–Straus Infinite Hunt Runner
// Free Computation Foundation - Apache-2.0

use super::solver::{solve_es, SolveResult};

#[derive(Clone, Debug)]
pub struct HuntSummary {
    pub start_bound: u64,
    pub end_bound: u64,
    pub primes_checked: usize,
    pub great_count: usize,
    pub good_count: usize,
    pub letter_count: usize,
    pub unsolved_count: usize,
    pub findings: Vec<SolveResult>,
    pub execution_millis: u128,
}

// Simple prime sieve for window [from, to]
pub fn sieve_primes(from: u64, to: u64) -> Vec<u64> {
    let mut primes = Vec::new();
    let low = from.max(2);
    if low > to {
        return primes;
    }
    for n in low..=to {
        if is_prime(n) {
            primes.push(n);
        }
    }
    primes
}

fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 || n == 3 {
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

pub fn run_hunt_window(from: u64, window_size: u64, max_primes: usize) -> HuntSummary {
    let start_time = std::time::Instant::now();
    let to = from + window_size;
    let primes = sieve_primes(from, to);

    let mut great_count = 0;
    let mut good_count = 0;
    let mut letter_count = 0;
    let mut unsolved_count = 0;
    let mut findings = Vec::new();

    for &p in primes.iter().take(max_primes) {
        let res = solve_es(p);
        match res.grade.as_str() {
            "great" => great_count += 1,
            "good" => {
                good_count += 1;
                findings.push(res);
            }
            "letter" => {
                letter_count += 1;
                findings.push(res);
            }
            _ => {
                unsolved_count += 1;
                findings.push(res);
            }
        }
    }

    HuntSummary {
        start_bound: from,
        end_bound: to,
        primes_checked: primes.len().min(max_primes),
        great_count,
        good_count,
        letter_count,
        unsolved_count,
        findings,
        execution_millis: start_time.elapsed().as_millis(),
    }
}
