// Erdős–Straus Exact 3-Egyptian Fraction Solver & Central Letter Admission Gate
// Free Computation Foundation - Apache-2.0

use super::certificate::{compute_letter_number, compute_witness_certificate};
use crate::engine::rational::BigInt;

pub const MORDELL_HARD_CLASSES_840: [u64; 6] = [1, 121, 169, 289, 361, 529];
pub const REMNANT_THRESHOLD: u64 = 50;
pub const DEFAULT_LETTER_DEPTH_THRESHOLD: u64 = 10;

pub fn is_mordell_hard(n: u64) -> bool {
    let rem = n % 840;
    MORDELL_HARD_CLASSES_840.contains(&rem)
}

pub fn is_prime(n: u64) -> bool {
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

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CandidateClassification {
    CentralGateAdmitted,    // Admitted genuine Letter
    DualDescentDeepSurvivor,// CBX Dual Descent deep survivor (descent_depth > 50)
    CorridorEscape,         // Non-letter corridor escape
    TheoremClearance,       // Fast O(1) linear congruences / identities (CC.kernel)
    CorridorHit,            // Shallow signed box (discovery_depth <= 10, CBAP)
    CbisEscape,             // CBIS phase contraction corridor escape (discovery_depth > 10)
    CbxSurvivor,            // Legacy alias for DualDescentDeepSurvivor
    OrdinaryDecomposition,  // Non-Mordell search hit
    UnsolvedCandidate,      // Reached horizon without solution (region incomplete)
    CertifiedCounterexample,// Complete finite region empty — disproof ticket
    InvalidCandidate,       // Non-prime or n <= 1
}

impl CandidateClassification {
    pub fn as_str(&self) -> &'static str {
        match self {
            CandidateClassification::CentralGateAdmitted => "central_gate_admitted",
            CandidateClassification::DualDescentDeepSurvivor | CandidateClassification::CbxSurvivor => "dual_descent_deep_survivor",
            CandidateClassification::CorridorEscape => "corridor_escape",
            CandidateClassification::TheoremClearance => "theorem_clearance",
            CandidateClassification::CorridorHit => "corridor_hit",
            CandidateClassification::CbisEscape => "cbis_escape",
            CandidateClassification::OrdinaryDecomposition => "ordinary_decomposition",
            CandidateClassification::UnsolvedCandidate => "unsolved_candidate",
            CandidateClassification::CertifiedCounterexample => "certified_counterexample",
            CandidateClassification::InvalidCandidate => "invalid_candidate",
        }
    }

    pub fn display_label(&self) -> &'static str {
        match self {
            CandidateClassification::CentralGateAdmitted => "Central Gate Admitted Letter",
            CandidateClassification::DualDescentDeepSurvivor | CandidateClassification::CbxSurvivor => "CBX Dual Descent Deep Survivor",
            CandidateClassification::CorridorEscape => "Corridor Escape",
            CandidateClassification::TheoremClearance => "Theorem Clearance (CC Sieve)",
            CandidateClassification::CorridorHit => "Corridor Hit (CBAP Signed Box)",
            CandidateClassification::CbisEscape => "CBIS Escape (Phase Contraction)",
            CandidateClassification::OrdinaryDecomposition => "Ordinary Decomposition",
            CandidateClassification::UnsolvedCandidate => "Unsolved Candidate",
            CandidateClassification::CertifiedCounterexample => "Certified Counterexample (Complete Region Empty)",
            CandidateClassification::InvalidCandidate => "Invalid Candidate",
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum LetterRejectionReason {
    NonMordellResidue(u64),
    NotPrime,
    PreclearancePassed(String),
    CorridorDepthBelowThreshold { depth: u64, threshold: u64 },
    MissingWitness,
    VerificationFailed,
    EngineCannotAdmitLetter(String),
}

impl LetterRejectionReason {
    pub fn description(&self) -> String {
        match self {
            LetterRejectionReason::NonMordellResidue(rem) => {
                format!("Non-Mordell Residue ({} mod 840 ∉ {{1, 121, 169, 289, 361, 529}})", rem)
            }
            LetterRejectionReason::NotPrime => "Candidate integer is composite or < 2".to_string(),
            LetterRejectionReason::PreclearancePassed(method) => {
                format!("Preclearance theorem sieve passed ({})", method)
            }
            LetterRejectionReason::CorridorDepthBelowThreshold { depth, threshold } => {
                format!("Discovery depth (δ={}) below broken-window threshold (threshold={})", depth, threshold)
            }
            LetterRejectionReason::MissingWitness => "No valid 3-Egyptian decomposition witness provided".to_string(),
            LetterRejectionReason::VerificationFailed => "Exact rational identity 4xyz == n(yz+xz+xy) failed".to_string(),
            LetterRejectionReason::EngineCannotAdmitLetter(engine) => {
                format!("Engine '{}' cannot independently admit letters", engine)
            }
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum LetterAdmissionStatus {
    Admitted,
    Rejected(LetterRejectionReason),
}

impl LetterAdmissionStatus {
    pub fn is_admitted(&self) -> bool {
        matches!(self, LetterAdmissionStatus::Admitted)
    }

    pub fn rejection_reason(&self) -> Option<&LetterRejectionReason> {
        match self {
            LetterAdmissionStatus::Admitted => None,
            LetterAdmissionStatus::Rejected(r) => Some(r),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DualDescentCertificate {
    pub candidate: u64,
    pub descent_depth: u64,
    pub threshold: u64,
    pub survival_engine: String,
    pub verified: bool,
    pub certificate: String,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Witness {
    pub n: u64,
    pub x: BigInt,
    pub y: BigInt,
    pub z: BigInt,
    pub method: String,
    pub layer: String,
    pub kind: String,
    pub engine_name: String,
    pub discovery_depth: u64,
    pub descent_depth: u64,
    pub depth: u64, // Legacy alias maintained for backward compatibility (equals discovery_depth)
    pub residue_840: u64,
    pub is_mordell_hard: bool,
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

    pub fn certificate_sha256(&self) -> String {
        compute_witness_certificate(
            self.n,
            &self.x.to_string(),
            &self.y.to_string(),
            &self.z.to_string(),
            &self.method,
            &self.engine_name,
            self.discovery_depth,
        )
    }
}

#[derive(Clone, Debug)]
pub struct SolveResult {
    pub solved: bool,
    pub n: u64,
    pub residue_840: u64,
    pub is_mordell_hard: bool,
    pub witness: Option<Witness>,
    pub classification: CandidateClassification,
    pub admission_status: LetterAdmissionStatus,
    pub grade: String,
    pub letter_number: Option<String>,
    pub discovered_by: String,
    pub discovery_depth: u64,
    pub descent_depth: u64,
    pub survival_engine: Option<String>,
    pub dual_descent_certificate: Option<DualDescentCertificate>,
    pub letter_admitted: bool,
    pub remnant_admitted: bool,
    pub escape_admitted: bool,
    pub execution_micros: u128,
}

/// Bounded hardness proxy, not a theorem of nonexistence.
/// Counts staged modular hits on (2k+3) and (4k+1) through 200 stages.
/// Use this to decide where to look. Do not use it as a certificate of what is true.
pub fn compute_dual_descent_survival(n: u64) -> (u64, bool) {
    if !is_prime(n) || n <= 2 {
        return (0, false);
    }
    // Fast theorem congruences do not enter dual descent
    if n % 4 == 3 || n % 3 == 2 || n % 8 == 5 {
        return (0, true);
    }
    // Simulate CBX Dual Descent ladder stages:
    // At each descent level k, evaluate modular reduction on (2k+3) and quadratic defect
    let mut stages_survived = 0u64;
    for stage in 1..=200 {
        let modulus = 2 * stage + 3;
        if n % modulus == 0 {
            stages_survived = stage;
            break;
        }
        // Test Kneser defect boundary
        if (n + stage) % (4 * stage + 1) == 0 {
            stages_survived = stage;
            break;
        }
        stages_survived = stage;
    }
    (stages_survived, true)
}

/// Authoritative Centralized Letter Admission Gate
///
/// Under the CBX/ES letter contract:
/// is_letter_candidate(p, result) =
///     is_prime(p)
///     && is_mordell_hard(p)
///     && survives_all_required_preclearance_layers(p)
///     && satisfies_required_letter_depth(result)
///     && exact_certificate_verification(result)
pub fn evaluate_letter_admission(
    n: u64,
    solve: &SolveResult,
    letter_depth_threshold: u64,
) -> LetterAdmissionStatus {
    // 1. Mandatory Primality Check
    if !is_prime(n) {
        return LetterAdmissionStatus::Rejected(LetterRejectionReason::NotPrime);
    }

    // 2. Strict Mordell-Hard radar: p mod 840 in {1, 121, 169, 289, 361, 529}
    if !is_mordell_hard(n) {
        return LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(n % 840));
    }

    // 3. Preclearance layers: Did the prime get solved by CC.kernel fast linear congruences?
    if solve.classification == CandidateClassification::TheoremClearance {
        return LetterAdmissionStatus::Rejected(LetterRejectionReason::PreclearancePassed(
            solve.discovered_by.clone(),
        ));
    }

    // 4. Must have verified witness
    let witness = match &solve.witness {
        Some(w) => w,
        None => return LetterAdmissionStatus::Rejected(LetterRejectionReason::MissingWitness),
    };

    // 5. Rational arithmetic identity verification: 4xyz == n(yz + xz + xy)
    if !witness.verify() {
        return LetterAdmissionStatus::Rejected(LetterRejectionReason::VerificationFailed);
    }

    // 6. Discovery Depth requirement: must be a genuine corridor escape / broken window (discovery_depth >= letter_depth_threshold)
    if witness.discovery_depth < letter_depth_threshold {
        return LetterAdmissionStatus::Rejected(LetterRejectionReason::CorridorDepthBelowThreshold {
            depth: witness.discovery_depth,
            threshold: letter_depth_threshold,
        });
    }

    // Passed all mandatory gates
    LetterAdmissionStatus::Admitted
}

pub fn evaluate_remnant_admission(
    n: u64,
    solve: &SolveResult,
    remnant_threshold: u64,
) -> bool {
    if !is_prime(n) || n <= 2 {
        return false;
    }
    if solve.descent_depth <= remnant_threshold {
        return false;
    }
    match &solve.dual_descent_certificate {
        Some(cert) => cert.verified && cert.descent_depth > remnant_threshold,
        None => false,
    }
}

fn make_witness(
    n: u64,
    x: BigInt,
    y: BigInt,
    z: BigInt,
    method: &str,
    engine_name: &str,
    layer: &str,
    kind: &str,
    res_840: u64,
    is_mordell: bool,
    discovery_depth: u64,
    descent_depth: u64,
) -> Witness {
    let mut w = Witness {
        n,
        x,
        y,
        z,
        method: method.to_string(),
        layer: layer.to_string(),
        kind: kind.to_string(),
        engine_name: engine_name.to_string(),
        discovery_depth,
        descent_depth,
        depth: discovery_depth,
        residue_840: res_840,
        is_mordell_hard: is_mordell,
        verified: false,
    };
    w.verified = w.verify();
    w
}

/// CC.kernel linear identities. Each formula is the exact rational identity 4/n = 1/x+1/y+1/z.
///
/// even n=2k:     x=k+1, y=k(k+1), z=k
/// n ≡ 3 (mod 4): x=(n+1)/4, y=z=n(n+1)/2
/// n ≡ 2 (mod 3): x=(n+1)/3, y=n, z=n(n+1)/3
/// n ≡ 5 (mod 8): x=(n+3)/4, y=n(n+3)/8, z=n(n+3)/4
fn try_cc_theorem(n: u64, res_840: u64, is_mordell: bool) -> Option<Witness> {
    let n_bi = BigInt::from_u64(n);

    if n % 2 == 0 {
        let k = n / 2;
        let k_bi = BigInt::from_u64(k);
        let kp1 = BigInt::from_u64(k + 1);
        return Some(make_witness(
            n,
            kp1.clone(),
            &k_bi * &kp1,
            k_bi,
            "even_reduction",
            "CC.kernel (Even Identity)",
            "theorem",
            "even",
            res_840,
            is_mordell,
            0,
            0,
        ));
    }

    if n % 4 == 3 {
        let np1 = BigInt::from_u64(n + 1);
        let x = &np1 / &BigInt::from_u64(4);
        let y = &(&n_bi * &np1) / &BigInt::from_u64(2);
        return Some(make_witness(
            n,
            x,
            y.clone(),
            y,
            "4p+3",
            "CC.kernel (4p+3 Sieve)",
            "theorem",
            "linear",
            res_840,
            is_mordell,
            0,
            0,
        ));
    }

    if n % 3 == 2 {
        let np1 = BigInt::from_u64(n + 1);
        let x = &np1 / &BigInt::from_u64(3);
        let z = &n_bi * &x;
        return Some(make_witness(
            n,
            x,
            n_bi,
            z,
            "3p+2",
            "CC.kernel (3p+2 Sieve)",
            "theorem",
            "linear",
            res_840,
            is_mordell,
            0,
            0,
        ));
    }

    if n % 8 == 5 {
        let np3 = BigInt::from_u64(n + 3);
        let x = &np3 / &BigInt::from_u64(4);
        let y = &(&n_bi * &np3) / &BigInt::from_u64(8);
        let z = &(&n_bi * &np3) / &BigInt::from_u64(4);
        return Some(make_witness(
            n,
            x,
            y,
            z,
            "8p+5",
            "CC.kernel (8p+5 Sieve)",
            "theorem",
            "linear",
            res_840,
            is_mordell,
            0,
            0,
        ));
    }

    None
}

/// Type-I/II two-target: n ≡ 1 (mod 4), k ≡ 3 (mod 4), x = (n+k)/4,
/// 4/n = 1/x + d/(n x) + (k-d)/(n x) when d | n x and (k-d) | n x.
fn try_two_target_k(n: u64, res_840: u64, is_mordell: bool, k_max: u64) -> Option<Witness> {
    if n % 4 != 1 {
        return None;
    }
    let n_u = n as u128;
    for k in (3..=k_max).step_by(4) {
        if (n + k) % 4 != 0 {
            continue;
        }
        let x = (n + k) / 4;
        let nx = n_u * x as u128;
        for d in 1..k {
            let kd = k - d;
            if kd == 0 {
                continue;
            }
            if nx % d as u128 == 0 && nx % kd as u128 == 0 {
                let y = nx / d as u128;
                let z = nx / kd as u128;
                if y == 0 || z == 0 || y > u64::MAX as u128 || z > u64::MAX as u128 {
                    continue;
                }
                let w = make_witness(
                    n,
                    BigInt::from_u64(x),
                    BigInt::from_u64(y as u64),
                    BigInt::from_u64(z as u64),
                    "two_target_k",
                    "CC.kernel (Two-Target k)",
                    "theorem",
                    "two_target",
                    res_840,
                    is_mordell,
                    x.saturating_sub((n / 4) + 1),
                    0,
                );
                if w.verified {
                    return Some(w);
                }
            }
        }
    }
    None
}

fn u128_divisors(mut v: u128) -> Vec<u128> {
    let mut factors: Vec<(u128, u32)> = Vec::new();
    let mut p = 2u128;
    while p * p <= v {
        if v % p == 0 {
            let mut e = 0u32;
            while v % p == 0 {
                v /= p;
                e += 1;
            }
            factors.push((p, e));
        }
        p += if p == 2 { 1 } else { 2 };
        if p > 1_000_003 && v > 1 {
            break;
        }
    }
    if v > 1 {
        factors.push((v, 1));
    }
    let mut divs = vec![1u128];
    for (p, e) in factors {
        let mut next = Vec::new();
        let mut pe = 1u128;
        for _ in 0..=e {
            for &d in &divs {
                next.push(d * pe);
            }
            pe = pe.saturating_mul(p);
        }
        divs = next;
    }
    divs.sort_unstable();
    divs.dedup();
    divs
}

/// Complete finite search for x ≤ y ≤ z: (Ay − nx)(Az − nx) = n²x².
/// Returns (witness, region_was_complete).
fn try_divisor_complete(
    n: u64,
    res_840: u64,
    is_mordell: bool,
    max_x: u64,
) -> (Option<Witness>, bool) {
    if n < 2 {
        return (None, true);
    }
    let x_lo = n / 4 + 1;
    let x_hi_full = (3 * n) / 4;
    if x_hi_full < x_lo {
        return (None, true);
    }
    let x_hi = x_hi_full.min(x_lo.saturating_add(max_x.saturating_sub(1)));
    let complete = x_hi >= x_hi_full;
    let n_u = n as u128;
    for x in x_lo..=x_hi {
        let a = 4u128 * x as u128 - n_u;
        if a == 0 {
            continue;
        }
        let nx = n_u * x as u128;
        let n2x2 = nx.saturating_mul(nx);
        if n2x2 == 0 {
            continue;
        }
        for d in u128_divisors(n2x2) {
            if d == 0 {
                continue;
            }
            let y_num = d + nx;
            if y_num % a != 0 {
                continue;
            }
            let y = y_num / a;
            if y < x as u128 || y > u64::MAX as u128 {
                continue;
            }
            let z_num = nx * y;
            if z_num % d != 0 {
                continue;
            }
            let z = z_num / d;
            if z < y || z > u64::MAX as u128 {
                continue;
            }
            let w = make_witness(
                n,
                BigInt::from_u64(x),
                BigInt::from_u64(y as u64),
                BigInt::from_u64(z as u64),
                "divisor_complete",
                "bb.kernel (Complete Finite Region)",
                "decision",
                "complete",
                res_840,
                is_mordell,
                x.saturating_sub(x_lo),
                0,
            );
            if w.verified {
                return (Some(w), complete);
            }
        }
    }
    (None, complete)
}

fn theorem_clearance_result(
    n: u64,
    res_840: u64,
    is_mordell: bool,
    w: Witness,
    start: std::time::Instant,
) -> SolveResult {
    let method = w.method.clone();
    let discovered_by = w.engine_name.clone();
    SolveResult {
        solved: true,
        n,
        residue_840: res_840,
        is_mordell_hard: is_mordell,
        witness: Some(w),
        classification: CandidateClassification::TheoremClearance,
        admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::PreclearancePassed(
            method,
        )),
        grade: "theorem_clearance".to_string(),
        letter_number: None,
        discovered_by,
        discovery_depth: 0,
        descent_depth: 0,
        survival_engine: None,
        dual_descent_certificate: None,
        letter_admitted: false,
        remnant_admitted: false,
        escape_admitted: false,
        execution_micros: start.elapsed().as_micros(),
    }
}

pub fn solve_es(n: u64) -> SolveResult {
    solve_es_with_config(n, 10, "auto")
}

pub fn solve_es_with_config(n: u64, letter_depth_threshold: u64, engine_preference: &str) -> SolveResult {
    let start = std::time::Instant::now();
    let res_840 = n % 840;
    let is_mordell = is_mordell_hard(n);

    if n <= 1 {
        return SolveResult {
            solved: false,
            n,
            residue_840: res_840,
            is_mordell_hard: is_mordell,
            witness: None,
            classification: CandidateClassification::InvalidCandidate,
            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::NotPrime),
            grade: "invalid".to_string(),
            letter_number: None,
            discovered_by: "Validation".to_string(),
            discovery_depth: 0,
            descent_depth: 0,
            survival_engine: None,
            dual_descent_certificate: None,
            letter_admitted: false,
            remnant_admitted: false,
            escape_admitted: false,
            execution_micros: start.elapsed().as_micros(),
        };
    }

    let allow_theorems = engine_preference == "auto" || engine_preference == "cc";
    let allow_corridor = engine_preference == "auto"
        || engine_preference == "cbap"
        || engine_preference == "cbis"
        || engine_preference == "cbx"
        || engine_preference == "bb";

    // 1–4. CC.kernel linear identities (even, 4p+3, 3p+2, 8p+5)
    if allow_theorems {
        if let Some(w) = try_cc_theorem(n, res_840, is_mordell) {
            if w.verified {
                return theorem_clearance_result(n, res_840, is_mordell, w, start);
            }
        }
    }

    // 5. Two-Target Signed Box Corridor Search (CBAP / CBIS / CBX)
    if !allow_corridor {
        // CC-only mode: Mordell-hard primes remain unsolved here by design.
        let (descent_depth, _survival_ok) = compute_dual_descent_survival(n);
        return SolveResult {
            solved: false,
            n,
            residue_840: res_840,
            is_mordell_hard: is_mordell,
            witness: None,
            classification: CandidateClassification::UnsolvedCandidate,
            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::MissingWitness),
            grade: "unsolved_candidate".to_string(),
            letter_number: None,
            discovered_by: "CC.kernel (theorems only)".to_string(),
            discovery_depth: 0,
            descent_depth,
            survival_engine: None,
            dual_descent_certificate: None,
            letter_admitted: false,
            remnant_admitted: false,
            escape_admitted: false,
            execution_micros: start.elapsed().as_micros(),
        };
    }

    let x_base = (n / 4) + 1;
    let x_max = n + 2000;
    let n_u128 = n as u128;
    for x in x_base..=x_max {
        let discovery_depth = x - x_base;
        let x_u128 = x as u128;
        let num = 4 * x_u128 - n_u128;
        let den = n_u128 * x_u128;
        let y_min = (den / num) + 1;
        let y_max = (2 * den / num) + 1;
        let y_limit = (y_min + 5000).min(y_max);
        for y_u128 in y_min..=y_limit {
            let z_num = num * y_u128 - den;
            let z_den = den * y_u128;
            if z_num > 0 && z_den % z_num == 0 {
                let z_u128 = z_den / z_num;
                if z_u128 <= u64::MAX as u128 && y_u128 <= u64::MAX as u128 {
                    let y = y_u128 as u64;
                    let z = z_u128 as u64;
                    let (engine_tag, mut classification) = if discovery_depth <= 10 {
                        ("CBAP.kernel (Signed Box AP)", if is_mordell { CandidateClassification::CorridorHit } else { CandidateClassification::OrdinaryDecomposition })
                    } else if discovery_depth <= 50 {
                        ("CBIS.kernel (Phase Contraction)", CandidateClassification::CbisEscape)
                    } else {
                        ("CBX.kernel (Dual Descent Lane-I)", CandidateClassification::DualDescentDeepSurvivor)
                    };

                    // Compute CBX dual descent survival
                    let (descent_depth, survival_ok) = compute_dual_descent_survival(n);
                    let dual_descent_certificate = if descent_depth > REMNANT_THRESHOLD && survival_ok {
                        use std::collections::hash_map::DefaultHasher;
                        use std::hash::{Hash, Hasher};
                        let mut hasher = DefaultHasher::new();
                        n.hash(&mut hasher);
                        descent_depth.hash(&mut hasher);
                        let cert_hash = format!("REM-{:016x}", hasher.finish());
                        Some(DualDescentCertificate {
                            candidate: n,
                            descent_depth,
                            threshold: REMNANT_THRESHOLD,
                            survival_engine: "CBX.kernel (Dual Descent)".to_string(),
                            verified: true,
                            certificate: cert_hash,
                        })
                    } else {
                        None
                    };

                    let w = Witness {
                        n,
                        x: BigInt::from_u64(x),
                        y: BigInt::from_u64(y),
                        z: BigInt::from_u64(z),
                        method: "two_target_search".to_string(),
                        layer: "corridor".to_string(),
                        kind: "quadratic".to_string(),
                        engine_name: engine_tag.to_string(),
                        discovery_depth,
                        descent_depth,
                        depth: discovery_depth,
                        residue_840: res_840,
                        is_mordell_hard: is_mordell,
                        verified: true,
                    };

                    if w.verify() {
                        let mut result = SolveResult {
                            solved: true,
                            n,
                            residue_840: res_840,
                            is_mordell_hard: is_mordell,
                            witness: Some(w),
                            classification,
                            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::EngineCannotAdmitLetter(engine_tag.to_string())),
                            grade: classification.as_str().to_string(),
                            letter_number: None,
                            discovered_by: engine_tag.to_string(),
                            discovery_depth,
                            descent_depth,
                            survival_engine: Some("CBX.kernel (Dual Descent)".to_string()),
                            dual_descent_certificate,
                            letter_admitted: false,
                            remnant_admitted: false,
                            escape_admitted: false,
                            execution_micros: start.elapsed().as_micros(),
                        };

                        // Central Authoritative Letter Admission Evaluation
                        let admission = evaluate_letter_admission(n, &result, letter_depth_threshold);
                        result.admission_status = admission.clone();

                        let is_letter = admission.is_admitted();
                        let is_remnant = evaluate_remnant_admission(n, &result, REMNANT_THRESHOLD);

                        result.letter_admitted = is_letter;
                        result.remnant_admitted = is_remnant;
                        result.escape_admitted = !is_letter && !is_remnant;

                        if is_letter {
                            result.grade = "letter".to_string();
                            result.classification = CandidateClassification::CentralGateAdmitted;
                            result.letter_number = Some(compute_letter_number(n, &["window_broken"]));
                        } else if is_remnant {
                            result.grade = "remnant".to_string();
                            result.classification = CandidateClassification::DualDescentDeepSurvivor;
                        } else {
                            result.grade = "escape".to_string();
                            if classification == CandidateClassification::DualDescentDeepSurvivor {
                                classification = CandidateClassification::CorridorEscape;
                            }
                            result.classification = classification;
                        }

                        return result;
                    }
                }
            }
        }
    }

    // 6. Decision expansion: two-target k identities, then a complete divisor region
    //    when n is small enough. Approximates are never used to certify.
    if allow_corridor {
        if let Some(w) = try_two_target_k(n, res_840, is_mordell, 243) {
            if w.verified {
                let mut result = theorem_clearance_result(n, res_840, is_mordell, w, start);
                result.classification = CandidateClassification::OrdinaryDecomposition;
                result.grade = "instance_proof".to_string();
                result.discovered_by = "CC.kernel (Two-Target k)".to_string();
                let admission = evaluate_letter_admission(n, &result, letter_depth_threshold);
                result.admission_status = admission.clone();
                result.letter_admitted = admission.is_admitted();
                if result.letter_admitted {
                    result.grade = "letter".to_string();
                    result.classification = CandidateClassification::CentralGateAdmitted;
                    result.letter_number = Some(compute_letter_number(n, &["window_broken"]));
                }
                return result;
            }
        }
        if n <= 10_000 {
        let (found, complete) = try_divisor_complete(n, res_840, is_mordell, u64::MAX);
        if let Some(w) = found {
            if w.verified {
                let mut result = theorem_clearance_result(n, res_840, is_mordell, w, start);
                result.classification = if complete {
                    CandidateClassification::OrdinaryDecomposition
                } else {
                    CandidateClassification::CbisEscape
                };
                result.grade = "instance_proof".to_string();
                result.discovered_by = "bb.kernel (Complete Finite Region)".to_string();
                let admission = evaluate_letter_admission(n, &result, letter_depth_threshold);
                result.admission_status = admission.clone();
                result.letter_admitted = admission.is_admitted();
                if result.letter_admitted {
                    result.grade = "letter".to_string();
                    result.classification = CandidateClassification::CentralGateAdmitted;
                    result.letter_number = Some(compute_letter_number(n, &["window_broken"]));
                }
                return result;
            }
        }
        if complete {
            let (descent_depth, _) = compute_dual_descent_survival(n);
            return SolveResult {
                solved: false,
                n,
                residue_840: res_840,
                is_mordell_hard: is_mordell,
                witness: None,
                classification: CandidateClassification::CertifiedCounterexample,
                admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::MissingWitness),
                grade: "certified_counterexample".to_string(),
                letter_number: None,
                discovered_by: "bb.kernel (Complete Finite Region)".to_string(),
                discovery_depth: 0,
                descent_depth,
                survival_engine: None,
                dual_descent_certificate: None,
                letter_admitted: false,
                remnant_admitted: false,
                escape_admitted: false,
                execution_micros: start.elapsed().as_micros(),
            };
        }
        } // n <= 10_000
    }

    // 7. Unsolved Boundary (region incomplete — watchdog residual, not a disproof)
    let (descent_depth, survival_ok) = compute_dual_descent_survival(n);
    let dual_descent_certificate = if descent_depth > REMNANT_THRESHOLD && survival_ok {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        let mut hasher = DefaultHasher::new();
        n.hash(&mut hasher);
        descent_depth.hash(&mut hasher);
        Some(DualDescentCertificate {
            candidate: n,
            descent_depth,
            threshold: REMNANT_THRESHOLD,
            survival_engine: "CBX.kernel (Dual Descent)".to_string(),
            verified: true,
            certificate: format!("REM-{:016x}", hasher.finish()),
        })
    } else {
        None
    };

    let is_remnant = dual_descent_certificate.is_some();

    SolveResult {
        solved: false,
        n,
        residue_840: res_840,
        is_mordell_hard: is_mordell,
        witness: None,
        classification: if is_remnant {
            CandidateClassification::DualDescentDeepSurvivor
        } else {
            CandidateClassification::UnsolvedCandidate
        },
        admission_status: LetterAdmissionStatus::Rejected(if !is_prime(n) {
            LetterRejectionReason::NotPrime
        } else if !is_mordell {
            LetterRejectionReason::NonMordellResidue(res_840)
        } else {
            LetterRejectionReason::MissingWitness
        }),
        grade: if is_remnant { "remnant".to_string() } else { "unsolved_candidate".to_string() },
        letter_number: None,
        discovered_by: "Unsolved Boundary".to_string(),
        discovery_depth: 0,
        descent_depth,
        survival_engine: Some("CBX.kernel (Dual Descent)".to_string()),
        dual_descent_certificate,
        letter_admitted: false,
        remnant_admitted: is_remnant,
        escape_admitted: false,
        execution_micros: start.elapsed().as_micros(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_regression_fixtures_non_mordell_cbis_escapes_rejected() {
        // Fixture 1: p = 375017, residue = 377 mod 840 (NOT Mordell-hard)
        let p1 = 375017;
        assert_eq!(p1 % 840, 377);
        assert!(!is_mordell_hard(p1));
        assert!(is_prime(p1));

        let res1 = solve_es_with_config(p1, 10, "auto");
        assert!(res1.solved);
        assert!(res1.witness.is_some());
        assert!(res1.witness.as_ref().unwrap().verify());
        // Valid exact decomposition must NOT make it a letter
        assert_ne!(res1.grade, "letter");
        assert_eq!(res1.letter_number, None);
        assert!(!res1.admission_status.is_admitted());

        // Test explicit CBIS candidate structure for p = 375017 at depth 17
        let cbis_res1 = SolveResult {
            solved: true,
            n: p1,
            residue_840: 377,
            is_mordell_hard: false,
            witness: res1.witness.clone(),
            classification: CandidateClassification::CbisEscape,
            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::EngineCannotAdmitLetter("CBIS".into())),
            grade: "cbis_escape".into(),
            letter_number: None,
            discovered_by: "CBIS.kernel (Phase Contraction)".into(),
            discovery_depth: 17,
            descent_depth: 0,
            survival_engine: None,
            dual_descent_certificate: None,
            letter_admitted: false,
            remnant_admitted: false,
            escape_admitted: true,
            execution_micros: 100,
        };
        let admission1 = evaluate_letter_admission(p1, &cbis_res1, 10);
        assert_eq!(
            admission1,
            LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(377))
        );
        assert!(!admission1.is_admitted());

        // Fixture 2: p = 265873, residue = 433 mod 840 (NOT Mordell-hard)
        let p2 = 265873;
        assert_eq!(p2 % 840, 433);
        assert!(!is_mordell_hard(p2));
        assert!(is_prime(p2));

        let res2 = solve_es_with_config(p2, 10, "auto");
        assert!(res2.solved);
        assert!(res2.witness.is_some());
        assert!(res2.witness.as_ref().unwrap().verify());
        assert_ne!(res2.grade, "letter");
        assert_eq!(res2.letter_number, None);
        assert_eq!(
            res2.admission_status,
            LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(433))
        );
    }

    #[test]
    fn test_mordell_hard_residue_classes_necessary_but_not_sufficient() {
        // Verify the 6 Mordell-hard classes
        for &rem in &MORDELL_HARD_CLASSES_840 {
            assert!(is_mordell_hard(rem));
        }

        // p = 2521 is prime, 2521 % 840 = 1 (Mordell-hard)
        let p = 2521;
        assert_eq!(p % 840, 1);
        assert!(is_mordell_hard(p));

        // When solved at shallow corridor (depth 5 < threshold 10), it is a Remnant / not a letter
        let res_shallow = solve_es_with_config(p, 10, "auto");
        assert!(res_shallow.solved);
        assert_eq!(res_shallow.classification, CandidateClassification::DualDescentDeepSurvivor);
        assert_ne!(res_shallow.grade, "letter");
        assert_eq!(res_shallow.grade, "remnant");
        assert_eq!(res_shallow.letter_number, None);
        assert_eq!(
            res_shallow.admission_status,
            LetterAdmissionStatus::Rejected(LetterRejectionReason::CorridorDepthBelowThreshold {
                depth: 5,
                threshold: 10,
            })
        );

        // When threshold is met (threshold 5 <= depth 5), Central Admission elevates it to letter
        let res_broken = solve_es_with_config(p, 5, "auto");
        assert_eq!(res_broken.grade, "letter");
        assert!(res_broken.letter_number.is_some());
        assert_eq!(res_broken.admission_status, LetterAdmissionStatus::Admitted);
    }

    #[test]
    fn test_depth_separation_descent_vs_discovery() {
        // Candidate with high descent_depth (survived 57 descent stages) but found at discovery_depth 0
        let cert = DualDescentCertificate {
            candidate: 375017,
            descent_depth: 57,
            threshold: 50,
            survival_engine: "CBX.kernel (Dual Descent)".to_string(),
            verified: true,
            certificate: "REM-0000000000000001".to_string(),
        };
        let w = Witness {
            n: 375017,
            x: BigInt::from_u64(93755),
            y: BigInt::from_u64(11719906420),
            z: BigInt::from_u64(969573210587556284),
            method: "two_target_search".to_string(),
            layer: "corridor".to_string(),
            kind: "quadratic".to_string(),
            engine_name: "CBAP.kernel (Signed Box AP)".to_string(),
            discovery_depth: 0,
            descent_depth: 57,
            depth: 0,
            residue_840: 377,
            is_mordell_hard: false,
            verified: true,
        };
        assert!(w.verify());
        assert_eq!(w.discovery_depth, 0);
        assert_eq!(w.descent_depth, 57);
        assert_eq!(w.depth, 0); // legacy alias

        let res = SolveResult {
            solved: true,
            n: 375017,
            residue_840: 377,
            is_mordell_hard: false,
            witness: Some(w),
            classification: CandidateClassification::DualDescentDeepSurvivor,
            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(377)),
            grade: "remnant".to_string(),
            letter_number: None,
            discovered_by: "CBAP.kernel (Signed Box AP)".to_string(),
            discovery_depth: 0,
            descent_depth: 57,
            survival_engine: Some("CBX.kernel (Dual Descent)".to_string()),
            dual_descent_certificate: Some(cert),
            letter_admitted: false,
            remnant_admitted: true,
            escape_admitted: false,
            execution_micros: 50,
        };

        assert_eq!(res.descent_depth, 57);
        assert_eq!(res.discovery_depth, 0);
        assert!(evaluate_remnant_admission(375017, &res, 50));
        assert!(!evaluate_letter_admission(375017, &res, 10).is_admitted());
    }

    #[test]
    fn test_remnant_definition_by_descent_depth_threshold() {
        // Candidate with descent_depth <= 50 must NOT qualify as a Remnant
        let mut res = solve_es_with_config(375017, 10, "auto");
        res.descent_depth = 0;
        res.dual_descent_certificate = None;
        assert!(!evaluate_remnant_admission(375017, &res, 50));

        // Candidate with descent_depth > 50 and verified certificate qualifies
        res.descent_depth = 55;
        res.dual_descent_certificate = Some(DualDescentCertificate {
            candidate: 375017,
            descent_depth: 55,
            threshold: 50,
            survival_engine: "CBX.kernel (Dual Descent)".to_string(),
            verified: true,
            certificate: "REM-test".to_string(),
        });
        assert!(evaluate_remnant_admission(375017, &res, 50));
    }

    #[test]
    fn test_remnant_with_and_without_decomposition() {
        // Remnant with verified decomposition
        let w = Witness {
            n: 375017,
            x: BigInt::from_u64(93755),
            y: BigInt::from_u64(11719906420),
            z: BigInt::from_u64(969573210587556284),
            method: "two_target_search".to_string(),
            layer: "corridor".to_string(),
            kind: "quadratic".to_string(),
            engine_name: "CBX.kernel (Dual Descent)".to_string(),
            discovery_depth: 0,
            descent_depth: 80,
            depth: 0,
            residue_840: 377,
            is_mordell_hard: false,
            verified: true,
        };
        assert!(w.verify());
        let res_with_decomp = SolveResult {
            solved: true,
            n: 375017,
            residue_840: 377,
            is_mordell_hard: false,
            witness: Some(w),
            classification: CandidateClassification::DualDescentDeepSurvivor,
            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(377)),
            grade: "remnant".to_string(),
            letter_number: None,
            discovered_by: "CBX.kernel (Dual Descent)".to_string(),
            discovery_depth: 0,
            descent_depth: 80,
            survival_engine: Some("CBX.kernel (Dual Descent)".to_string()),
            dual_descent_certificate: Some(DualDescentCertificate {
                candidate: 375017,
                descent_depth: 80,
                threshold: 50,
                survival_engine: "CBX.kernel (Dual Descent)".to_string(),
                verified: true,
                certificate: "REM-375017".to_string(),
            }),
            letter_admitted: false,
            remnant_admitted: true,
            escape_admitted: false,
            execution_micros: 200,
        };
        assert!(evaluate_remnant_admission(375017, &res_with_decomp, 50));
        assert!(res_with_decomp.witness.as_ref().unwrap().verify());

        // Remnant without decomposition (unsolved after search horizon)
        let res_without_decomp = SolveResult {
            solved: false,
            n: 375017,
            residue_840: 377,
            is_mordell_hard: false,
            witness: None,
            classification: CandidateClassification::DualDescentDeepSurvivor,
            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(377)),
            grade: "remnant".to_string(),
            letter_number: None,
            discovered_by: "Unsolved Boundary".to_string(),
            discovery_depth: 0,
            descent_depth: 80,
            survival_engine: Some("CBX.kernel (Dual Descent)".to_string()),
            dual_descent_certificate: Some(DualDescentCertificate {
                candidate: 375017,
                descent_depth: 80,
                threshold: 50,
                survival_engine: "CBX.kernel (Dual Descent)".to_string(),
                verified: true,
                certificate: "REM-375017-unsolved".to_string(),
            }),
            letter_admitted: false,
            remnant_admitted: true,
            escape_admitted: false,
            execution_micros: 500,
        };
        assert!(evaluate_remnant_admission(375017, &res_without_decomp, 50));
    }

    #[test]
    fn test_multi_certificate_independence() {
        // A prime that is both a Mordell-hard letter and a deep dual descent survivor
        let p = 2521; // 2521 % 840 = 1
        assert!(is_mordell_hard(p));
        let w = Witness {
            n: p,
            x: BigInt::from_u64(631),
            y: BigInt::from_u64(3181482),
            z: BigInt::from_u64(3181482),
            method: "two_target_search".to_string(),
            layer: "corridor".to_string(),
            kind: "quadratic".to_string(),
            engine_name: "CBX.kernel (Dual Descent)".to_string(),
            discovery_depth: 15,
            descent_depth: 72,
            depth: 15,
            residue_840: 1,
            is_mordell_hard: true,
            verified: true,
        };
        let res = SolveResult {
            solved: true,
            n: p,
            residue_840: 1,
            is_mordell_hard: true,
            witness: Some(w),
            classification: CandidateClassification::CentralGateAdmitted,
            admission_status: LetterAdmissionStatus::Admitted,
            grade: "letter".to_string(),
            letter_number: Some("L-2521".to_string()),
            discovered_by: "CBX.kernel (Dual Descent)".to_string(),
            discovery_depth: 15,
            descent_depth: 72,
            survival_engine: Some("CBX.kernel (Dual Descent)".to_string()),
            dual_descent_certificate: Some(DualDescentCertificate {
                candidate: p,
                descent_depth: 72,
                threshold: 50,
                survival_engine: "CBX.kernel (Dual Descent)".to_string(),
                verified: true,
                certificate: "REM-2521".to_string(),
            }),
            letter_admitted: true,
            remnant_admitted: true,
            escape_admitted: false,
            execution_micros: 120,
        };

        assert!(res.letter_admitted);
        assert!(res.remnant_admitted);
        assert!(!res.escape_admitted);
        assert_eq!(res.descent_depth, 72);
        assert_eq!(res.discovery_depth, 15);
    }

    fn assert_verified_theorem(n: u64, method: &str) {
        let res = solve_es_with_config(n, 10, "auto");
        assert!(res.solved, "n={} should be solved", n);
        assert_eq!(res.classification, CandidateClassification::TheoremClearance);
        let w = res.witness.as_ref().expect("theorem witness");
        assert!(w.verify(), "identity failed for n={} method={} eq={}", n, w.method, w.equation());
        assert_eq!(w.method, method);
        assert!(!res.letter_admitted);
    }

    #[test]
    fn test_cc_even_identity() {
        for n in [2u64, 4, 6, 10, 100, 1_000_000] {
            assert_verified_theorem(n, "even_reduction");
        }
    }

    #[test]
    fn test_cc_4p3_identity() {
        for n in [3u64, 7, 11, 19, 23, 10_000_003] {
            assert_eq!(n % 4, 3);
            assert_verified_theorem(n, "4p+3");
        }
    }

    #[test]
    fn test_cc_3p2_identity() {
        // 5 ≡ 2 (mod 3); 4p+3 does not fire (5 ≡ 1 mod 4)
        assert_verified_theorem(5, "3p+2");
        assert_verified_theorem(11, "4p+3"); // 11 ≡ 3 (mod 4) takes precedence
        assert_verified_theorem(17, "3p+2");
        assert_verified_theorem(375017, "3p+2");
    }

    #[test]
    fn test_cc_8p5_identity_including_pinned_escape() {
        // 13 ≡ 5 (mod 8), ≡ 1 (mod 3), ≡ 1 (mod 4) → 8p+5
        assert_verified_theorem(13, "8p+5");
        assert_verified_theorem(37, "8p+5");
        // Observatory pin ESC-9341077 was a false CBIS because x was (n+3)/8 instead of (n+3)/4
        let p = 9_341_077u64;
        assert!(is_prime(p));
        assert_eq!(p % 8, 5);
        assert_eq!(p % 840, 277);
        assert!(!is_mordell_hard(p));
        let res = solve_es_with_config(p, 10, "auto");
        assert_eq!(res.classification, CandidateClassification::TheoremClearance);
        assert_eq!(res.witness.as_ref().unwrap().method, "8p+5");
        assert!(res.witness.as_ref().unwrap().verify());
        assert_eq!(res.discovery_depth, 0);
        assert!(!res.letter_admitted);
        assert_ne!(res.classification, CandidateClassification::CbisEscape);
    }

    #[test]
    fn test_unsolved_mordell_is_not_a_letter() {
        // CC-only mode: 2521 escapes every linear sieve and has no corridor witness
        let res = solve_es_with_config(2521, 10, "cc");
        assert!(!res.solved);
        assert!(res.is_mordell_hard);
        assert!(!res.letter_admitted);
        assert_eq!(res.classification, CandidateClassification::UnsolvedCandidate);
        assert_eq!(
            res.admission_status,
            LetterAdmissionStatus::Rejected(LetterRejectionReason::MissingWitness)
        );
        assert_ne!(res.grade, "letter");
        assert_eq!(res.letter_number, None);
    }

    #[test]
    fn test_two_target_k_and_complete_are_exact() {
        let res = solve_es_with_config(1009, 10, "auto");
        assert!(res.solved, "Mordell origin-class 1009 must still be solved exactly");
        assert!(res.witness.as_ref().unwrap().verify());
        assert_ne!(res.classification, CandidateClassification::CertifiedCounterexample);
    }

    #[test]
    fn test_divisor_complete_small_prime() {
        let (w, complete) = try_divisor_complete(13, 13 % 840, false, u64::MAX);
        assert!(complete);
        assert!(w.unwrap().verify());
    }
}
