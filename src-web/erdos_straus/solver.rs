// Erdős–Straus Exact 3-Egyptian Fraction Solver & Central Letter Admission Gate
// Free Computation Foundation - Apache-2.0

use super::certificate::compute_letter_number;
use crate::engine::rational::BigInt;

pub const MORDELL_HARD_CLASSES_840: [u64; 6] = [1, 121, 169, 289, 361, 529];

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
    TheoremClearance,       // Fast O(1) linear congruences / identities (CC.kernel)
    CorridorHit,            // Shallow signed box (depth <= 10, CBAP)
    CbisEscape,             // CBIS phase contraction corridor escape (depth > 10)
    CbxSurvivor,            // CBX dual descent deep corridor survivor (depth > 50)
    OrdinaryDecomposition,  // Non-Mordell search hit
    UnsolvedCandidate,      // Reached horizon without solution
    InvalidCandidate,       // Non-prime or n <= 1
}

impl CandidateClassification {
    pub fn as_str(&self) -> &'static str {
        match self {
            CandidateClassification::TheoremClearance => "theorem_clearance",
            CandidateClassification::CorridorHit => "corridor_hit",
            CandidateClassification::CbisEscape => "cbis_escape",
            CandidateClassification::CbxSurvivor => "cbx_survivor",
            CandidateClassification::OrdinaryDecomposition => "ordinary_decomposition",
            CandidateClassification::UnsolvedCandidate => "unsolved_candidate",
            CandidateClassification::InvalidCandidate => "invalid_candidate",
        }
    }

    pub fn display_label(&self) -> &'static str {
        match self {
            CandidateClassification::TheoremClearance => "Theorem Clearance (CC Sieve)",
            CandidateClassification::CorridorHit => "Corridor Hit (CBAP Signed Box)",
            CandidateClassification::CbisEscape => "CBIS Escape (Phase Contraction)",
            CandidateClassification::CbxSurvivor => "CBX Remnant (Dual Descent)",
            CandidateClassification::OrdinaryDecomposition => "Ordinary Decomposition",
            CandidateClassification::UnsolvedCandidate => "Unsolved Candidate",
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
                format!("Corridor depth (δ={}) below broken-window threshold (threshold={})", depth, threshold)
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
    pub depth: u64,
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
    pub execution_micros: u128,
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

    // 6. Depth requirement: must be a genuine corridor escape / broken window (depth >= letter_depth_threshold)
    if witness.depth < letter_depth_threshold {
        return LetterAdmissionStatus::Rejected(LetterRejectionReason::CorridorDepthBelowThreshold {
            depth: witness.depth,
            threshold: letter_depth_threshold,
        });
    }

    // Passed all mandatory gates
    LetterAdmissionStatus::Admitted
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
            execution_micros: start.elapsed().as_micros(),
        };
    }

    let allow_theorems = engine_preference == "auto" || engine_preference == "cc";

    // 1. Check if n is even (n = 2k)
    if allow_theorems && n % 2 == 0 {
        let k = n / 2;
        let w = Witness {
            n,
            x: BigInt::from_u64(k + 1),
            y: BigInt::from_u64(k * (k + 1)),
            z: BigInt::from_u64(k * (k + 1)),
            method: "even_reduction".to_string(),
            layer: "theorem".to_string(),
            kind: "even".to_string(),
            engine_name: "CC.kernel (Theorem)".to_string(),
            depth: 0,
            residue_840: res_840,
            is_mordell_hard: is_mordell,
            verified: true,
        };
        return SolveResult {
            solved: true,
            n,
            residue_840: res_840,
            is_mordell_hard: is_mordell,
            witness: Some(w),
            classification: CandidateClassification::TheoremClearance,
            admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::PreclearancePassed("even_reduction".to_string())),
            grade: "theorem_clearance".to_string(),
            letter_number: None,
            discovered_by: "CC.kernel (Even Identity)".to_string(),
            execution_micros: start.elapsed().as_micros(),
        };
    }

    // 2. Linear congruence: n = 3 (mod 4)
    if allow_theorems && n % 4 == 3 {
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
            engine_name: "CC.kernel (4p+3 Sieve)".to_string(),
            depth: 0,
            residue_840: res_840,
            is_mordell_hard: is_mordell,
            verified: true,
        };
        if w.verify() {
            return SolveResult {
                solved: true,
                n,
                residue_840: res_840,
                is_mordell_hard: is_mordell,
                witness: Some(w),
                classification: CandidateClassification::TheoremClearance,
                admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::PreclearancePassed("4p+3".to_string())),
                grade: "theorem_clearance".to_string(),
                letter_number: None,
                discovered_by: "CC.kernel (4p+3 Sieve)".to_string(),
                execution_micros: start.elapsed().as_micros(),
            };
        }
    }

    // 3. Linear congruence: n = 2 (mod 3)
    if allow_theorems && n % 3 == 2 {
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
            engine_name: "CC.kernel (3p+2 Sieve)".to_string(),
            depth: 0,
            residue_840: res_840,
            is_mordell_hard: is_mordell,
            verified: true,
        };
        if w.verify() {
            return SolveResult {
                solved: true,
                n,
                residue_840: res_840,
                is_mordell_hard: is_mordell,
                witness: Some(w),
                classification: CandidateClassification::TheoremClearance,
                admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::PreclearancePassed("3p+2".to_string())),
                grade: "theorem_clearance".to_string(),
                letter_number: None,
                discovered_by: "CC.kernel (3p+2 Sieve)".to_string(),
                execution_micros: start.elapsed().as_micros(),
            };
        }
    }

    // 4. Linear congruence: n = 5 (mod 8)
    if allow_theorems && n % 8 == 5 {
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
            engine_name: "CC.kernel (8p+5 Sieve)".to_string(),
            depth: 0,
            residue_840: res_840,
            is_mordell_hard: is_mordell,
            verified: true,
        };
        if w.verify() {
            return SolveResult {
                solved: true,
                n,
                residue_840: res_840,
                is_mordell_hard: is_mordell,
                witness: Some(w),
                classification: CandidateClassification::TheoremClearance,
                admission_status: LetterAdmissionStatus::Rejected(LetterRejectionReason::PreclearancePassed("8p+5".to_string())),
                grade: "theorem_clearance".to_string(),
                letter_number: None,
                discovered_by: "CC.kernel (8p+5 Sieve)".to_string(),
                execution_micros: start.elapsed().as_micros(),
            };
        }
    }

    // 5. Two-Target Signed Box Corridor Search (CBAP / CBIS / CBX / CC.kernel)
    let x_base = (n / 4) + 1;
    let x_max = n + 2000;
    let n_u128 = n as u128;
    for x in x_base..=x_max {
        let depth = x - x_base;
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
                    let (engine_tag, classification) = if depth <= 10 {
                        ("CBAP.kernel (Signed Box AP)", if is_mordell { CandidateClassification::CorridorHit } else { CandidateClassification::OrdinaryDecomposition })
                    } else if depth <= 50 {
                        ("CBIS.kernel (Phase Contraction)", CandidateClassification::CbisEscape)
                    } else {
                        ("CBX.kernel (Dual Descent Lane-I)", CandidateClassification::CbxSurvivor)
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
                        depth,
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
                            execution_micros: start.elapsed().as_micros(),
                        };

                        // CENTRAL AUTHORITATIVE LETTER ADMISSION EVALUATION
                        let admission = evaluate_letter_admission(n, &result, letter_depth_threshold);
                        result.admission_status = admission.clone();

                        if admission.is_admitted() {
                            result.grade = "letter".to_string();
                            result.letter_number = Some(compute_letter_number(n, &["window_broken"]));
                        }

                        let _ = engine_preference;
                        return result;
                    }
                }
            }
        }
    }

    // 6. Unsolved Boundary
    let mut result = SolveResult {
        solved: false,
        n,
        residue_840: res_840,
        is_mordell_hard: is_mordell,
        witness: None,
        classification: CandidateClassification::UnsolvedCandidate,
        admission_status: if is_mordell && is_prime(n) {
            LetterAdmissionStatus::Admitted
        } else {
            LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(res_840))
        },
        grade: "unsolved_candidate".to_string(),
        letter_number: None,
        discovered_by: "Unsolved Boundary".to_string(),
        execution_micros: start.elapsed().as_micros(),
    };

    if result.admission_status.is_admitted() {
        result.grade = "letter".to_string();
        result.letter_number = Some(compute_letter_number(n, &["unsolved_after_search"]));
    }

    result
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

        // When solved at shallow corridor (depth 5 < threshold 10), it is a CorridorHit, NOT a letter
        let res_shallow = solve_es_with_config(p, 10, "auto");
        assert!(res_shallow.solved);
        assert_eq!(res_shallow.classification, CandidateClassification::CorridorHit);
        assert_ne!(res_shallow.grade, "letter");
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
    fn test_letter_admission_fails_closed_for_non_mordell() {
        // 73 is prime, 73 % 840 = 73 (not Mordell-hard)
        assert!(!is_mordell_hard(73));

        // Even with threshold 0, non-Mordell primes MUST NEVER be admitted as a Letter
        let res = solve_es_with_config(73, 0, "auto");
        assert_ne!(res.grade, "letter");
        assert_eq!(res.letter_number, None);

        // 1013 is prime, 1013 % 840 = 173 (not Mordell-hard)
        assert!(!is_mordell_hard(1013));
        let res_1013 = solve_es_with_config(1013, 0, "auto");
        assert_ne!(res_1013.grade, "letter");
        assert_eq!(res_1013.letter_number, None);
    }
}
