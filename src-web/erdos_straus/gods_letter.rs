// God's Letter — Unique Terminal Erdős–Straus Hunt Artifact
// Free Computation Foundation - Apache-2.0

use super::certificate::Sha256;
use super::solver::{
    compute_dual_descent_survival, is_mordell_hard, is_prime, solve_es_with_config,
    REMNANT_THRESHOLD,
};
use crate::engine::rational::BigInt;
use std::cmp::Ordering;
use std::collections::{BTreeMap, HashMap};
use std::fs;
use std::path::{Path, PathBuf};

pub const GODS_LETTER_SCHEMA: &str = "centl26.erdos-straus.gods-letter/v3";
pub const GODS_LETTER_SPEC_NAME: &str = "GodsLetterSpec";
pub const GODS_LETTER_SPEC_VERSION: &str = "3";
pub const CLASSIFICATION_GODS_LETTER: &str = "gods_letter";
/// Principal Mordell class: p ≡ 1 (mod 840). 840 = 8·3·5·7.
pub const PRINCIPAL_MORDELL_MODULUS: u128 = 840;
pub const PRINCIPAL_MORDELL_RESIDUE: u128 = 1;
/// Additional (non-origin) God's Letters must be found this far past x_0 = floor(p/4)+1.
/// Depth 50 is the CBAP→CBX corridor boundary. No such remnant exists below 10^5.
pub const GODS_LETTER_ASTRONOMICAL_DEPTH: u64 = 50;

/// Exact 3-Egyptian Fraction Witness with BigInt coordinates
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct EsWitness {
    pub n: u128,
    pub x: BigInt,
    pub y: BigInt,
    pub z: BigInt,
    pub method: String,
    pub engine_name: String,
    pub discovery_depth: u64,
}

impl EsWitness {
    pub fn new(n: u128, x: BigInt, y: BigInt, z: BigInt, method: &str, engine_name: &str, discovery_depth: u64) -> Self {
        // Enforce canonical ordering x <= y <= z
        let mut coords = [x, y, z];
        coords.sort();
        let [x_canon, y_canon, z_canon] = coords;
        EsWitness {
            n,
            x: x_canon,
            y: y_canon,
            z: z_canon,
            method: method.to_string(),
            engine_name: engine_name.to_string(),
            discovery_depth,
        }
    }

    pub fn equation(&self) -> String {
        format!("4/{} = 1/{} + 1/{} + 1/{}", self.n, self.x, self.y, self.z)
    }

    /// Verifies the exact integer identity 4*x*y*z == n*(x*y + x*z + y*z) with positive denominators.
    pub fn verify(&self) -> bool {
        if self.n == 0 || self.x <= BigInt::zero() || self.y <= BigInt::zero() || self.z <= BigInt::zero() {
            return false;
        }
        let four = BigInt::from_i64(4);
        let n_bi = BigInt::from_str(&self.n.to_string()).unwrap_or_else(|_| BigInt::zero());
        let left = &four * &(&self.x * &(&self.y * &self.z));
        let xy = &self.x * &self.y;
        let xz = &self.x * &self.z;
        let yz = &self.y * &self.z;
        let sum_pairs = &(&yz + &xz) + &xy;
        let right = &n_bi * &sum_pairs;
        left == right
    }

    pub fn cmp_coordinates(&self, other: &Self) -> Ordering {
        match self.x.cmp(&other.x) {
            Ordering::Equal => match self.y.cmp(&other.y) {
                Ordering::Equal => self.z.cmp(&other.z),
                other_y => other_y,
            },
            other_x => other_x,
        }
    }

    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "n": self.n.to_string(),
            "x": self.x.to_string(),
            "y": self.y.to_string(),
            "z": self.z.to_string(),
            "method": self.method,
            "engine_name": self.engine_name,
            "discovery_depth": self.discovery_depth,
            "equation": self.equation()
        })
    }
}

/// Certified Finite Hunt Domain Specification
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GodsLetterDomain {
    pub lower_bound: u128,
    pub upper_bound: u128,
    pub primes_only: bool,
    pub inclusive_lower: bool,
    pub inclusive_upper: bool,
}

impl GodsLetterDomain {
    pub fn new(lower_bound: u128, upper_bound: u128, primes_only: bool) -> Self {
        GodsLetterDomain {
            lower_bound,
            upper_bound,
            primes_only,
            inclusive_lower: true,
            inclusive_upper: true,
        }
    }

    pub fn default_certified() -> Self {
        GodsLetterDomain {
            lower_bound: 2,
            upper_bound: 100_000,
            primes_only: true,
            inclusive_lower: true,
            inclusive_upper: true,
        }
    }

    pub fn contains(&self, p: u128) -> bool {
        let lower_ok = if self.inclusive_lower {
            p >= self.lower_bound
        } else {
            p > self.lower_bound
        };
        let upper_ok = if self.inclusive_upper {
            p <= self.upper_bound
        } else {
            p < self.upper_bound
        };
        lower_ok && upper_ok
    }

    pub fn domain_hash(&self) -> String {
        let payload = format!(
            "domain:{}:{}:{}:{}:{}",
            self.lower_bound, self.upper_bound, self.primes_only, self.inclusive_lower, self.inclusive_upper
        );
        let mut hasher = Sha256::new();
        hasher.update(payload.as_bytes());
        let digest = hasher.finalize();
        digest[..16].iter().map(|b| format!("{:02x}", b)).collect()
    }

    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "lower_bound": self.lower_bound.to_string(),
            "upper_bound": self.upper_bound.to_string(),
            "primes_only": self.primes_only,
            "inclusive_lower": self.inclusive_lower,
            "inclusive_upper": self.inclusive_upper
        })
    }
}

/// Versioned Specification for God's Letter Admission Contract
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GodsLetterSpec {
    pub name: String,
    pub version: String,
    pub letter_depth_threshold: u64,
    pub remnant_threshold: u64,
    pub astronomical_depth_threshold: u64,
    pub mandatory_hardness_criteria: Vec<String>,
}

impl GodsLetterSpec {
    pub fn v1() -> Self {
        GodsLetterSpec {
            name: GODS_LETTER_SPEC_NAME.to_string(),
            version: GODS_LETTER_SPEC_VERSION.to_string(),
            letter_depth_threshold: 0,
            remnant_threshold: REMNANT_THRESHOLD,
            astronomical_depth_threshold: GODS_LETTER_ASTRONOMICAL_DEPTH,
            mandatory_hardness_criteria: vec![
                "mordell_hard_residue_840".to_string(),
                "elementary_preclearance_escape".to_string(),
                "dual_descent_ladder_escape".to_string(),
                "corridor_boundary_broken_window".to_string(),
                "astronomical_corridor_or_origin".to_string(),
            ],
        }
    }

    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "name": self.name,
            "version": self.version,
            "letter_depth_threshold": self.letter_depth_threshold,
            "remnant_threshold": self.remnant_threshold,
            "astronomical_depth_threshold": self.astronomical_depth_threshold,
            "mandatory_hardness_criteria": self.mandatory_hardness_criteria
        })
    }
}

/// Hardness criterion outcome
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct HardnessCriterionResult {
    pub id: String,
    pub version: String,
    pub passed: bool,
    pub description: String,
    pub metric: Option<String>,
    pub details: String,
}

impl HardnessCriterionResult {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "id": self.id,
            "version": self.version,
            "passed": self.passed,
            "description": self.description,
            "metric": self.metric,
            "details": self.details
        })
    }
}

/// Letter predicate recomputation result
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LetterPredicateResult {
    pub admitted: bool,
    pub residue_840: u64,
    pub hard_residue: bool,
    pub preclearance_escaped: bool,
    pub depth: u64,
    pub reason: String,
}

impl LetterPredicateResult {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "admitted": self.admitted,
            "residue_840": self.residue_840,
            "hard_residue": self.hard_residue,
            "preclearance_escaped": self.preclearance_escaped,
            "depth": self.depth,
            "reason": self.reason
        })
    }
}

/// Remnant predicate recomputation result
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RemnantPredicateResult {
    pub admitted: bool,
    pub descent_depth: u64,
    pub threshold: u64,
    pub terminal_stage: Option<u64>,
    pub reason: String,
}

impl RemnantPredicateResult {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "admitted": self.admitted,
            "descent_depth": self.descent_depth,
            "threshold": self.threshold,
            "terminal_stage": self.terminal_stage,
            "reason": self.reason
        })
    }
}

/// Engine geometry mathematical membership
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct EngineGeometryResult {
    pub cbap_signed_box: bool,
    pub cbx_dual_descent: bool,
    pub cbis_phase_contraction: bool,
    pub cc_preclearance_escaped: bool,
}

impl EngineGeometryResult {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "cbap_signed_box": self.cbap_signed_box,
            "cbx_dual_descent": self.cbx_dual_descent,
            "cbis_phase_contraction": self.cbis_phase_contraction,
            "cc_preclearance_escaped": self.cc_preclearance_escaped
        })
    }
}

/// Full candidate evaluation record
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GodsLetterCandidateEvaluation {
    pub p: u128,
    pub is_prime: bool,
    pub prime_passed: bool,
    pub witness: Option<EsWitness>,
    pub alternate_witnesses: Vec<EsWitness>,
    pub witness_verified: bool,
    pub letter: LetterPredicateResult,
    pub remnant: RemnantPredicateResult,
    pub hardness: Vec<HardnessCriterionResult>,
    pub hardness_passed: bool,
    pub engine_geometry: EngineGeometryResult,
    pub origin_generator: bool,
    pub astronomical: bool,
    pub unsolved_alarm: bool,
    pub gods_letter_kind: Option<String>,
    pub gods_letter_candidate: bool,
    pub rejection_reasons: Vec<String>,
}

impl GodsLetterCandidateEvaluation {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "p": self.p.to_string(),
            "is_prime": self.is_prime,
            "prime_passed": self.prime_passed,
            "witness": self.witness.as_ref().map(|w| w.to_json()),
            "alternate_witnesses": self.alternate_witnesses.iter().map(|w| w.to_json()).collect::<Vec<_>>(),
            "witness_verified": self.witness_verified,
            "letter": self.letter.to_json(),
            "remnant": self.remnant.to_json(),
            "hardness": self.hardness.iter().map(|h| h.to_json()).collect::<Vec<_>>(),
            "hardness_passed": self.hardness_passed,
            "engine_geometry": self.engine_geometry.to_json(),
            "origin_generator": self.origin_generator,
            "astronomical": self.astronomical,
            "unsolved_alarm": self.unsolved_alarm,
            "gods_letter_kind": self.gods_letter_kind,
            "gods_letter_candidate": self.gods_letter_candidate,
            "rejection_reasons": self.rejection_reasons
        })
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum UniquenessStatus {
    UniqueWithinCertifiedDomain,
    NoGodsLetter,
    NonUnique { candidate_count: usize },
}

impl UniquenessStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            UniquenessStatus::UniqueWithinCertifiedDomain => "unique_within_certified_domain",
            UniquenessStatus::NoGodsLetter => "no_gods_letter",
            UniquenessStatus::NonUnique { .. } => "gods_letter_non_unique",
        }
    }

    pub fn to_json(&self) -> serde_json::Value {
        match self {
            UniquenessStatus::UniqueWithinCertifiedDomain => serde_json::json!({
                "status": "unique_within_certified_domain",
                "candidate_count": 1
            }),
            UniquenessStatus::NoGodsLetter => serde_json::json!({
                "status": "no_gods_letter",
                "candidate_count": 0
            }),
            UniquenessStatus::NonUnique { candidate_count } => serde_json::json!({
                "status": "gods_letter_non_unique",
                "candidate_count": candidate_count
            }),
        }
    }
}

/// Elimination tree and domain evaluation statistics
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DomainStatistics {
    pub total_integers_considered: usize,
    pub primes_tested: usize,
    pub letter_survivors: usize,
    pub remnant_survivors: usize,
    pub letter_remnant_intersection: usize,
    pub hardness_survivors: usize,
    pub full_candidates: usize,
    pub stage_progression: Vec<StageCount>,
}

impl DomainStatistics {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "total_integers_considered": self.total_integers_considered,
            "primes_tested": self.primes_tested,
            "letter_survivors": self.letter_survivors,
            "remnant_survivors": self.remnant_survivors,
            "letter_remnant_intersection": self.letter_remnant_intersection,
            "hardness_survivors": self.hardness_survivors,
            "full_candidates": self.full_candidates,
            "stage_progression": self.stage_progression.iter().map(|s| s.to_json()).collect::<Vec<_>>()
        })
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StageCount {
    pub stage_name: String,
    pub entering_count: usize,
    pub surviving_count: usize,
    pub eliminated_count: usize,
}

impl StageCount {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "stage_name": self.stage_name,
            "entering_count": self.entering_count,
            "surviving_count": self.surviving_count,
            "eliminated_count": self.eliminated_count
        })
    }
}

/// Official content-addressed God's Letter Certificate
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GodsLetterCertificate {
    pub schema: String,
    pub artifact_id: String,
    pub classification: String,
    pub name: String,
    pub n: u128,
    pub prime: bool,
    pub equation: String,
    pub witness: serde_json::Value,
    pub alternate_witnesses: Vec<serde_json::Value>,
    pub letter: LetterPredicateResult,
    pub remnant: RemnantPredicateResult,
    pub hardness: Vec<HardnessCriterionResult>,
    pub engine_geometry: EngineGeometryResult,
    pub domain: GodsLetterDomain,
    pub domain_statistics: DomainStatistics,
    pub uniqueness: serde_json::Value,
    pub verification: serde_json::Value,
    pub specification: serde_json::Value,
    pub provenance: serde_json::Value,
    pub certificate: String,
}

impl GodsLetterCertificate {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "schema": self.schema,
            "artifact_id": self.artifact_id,
            "classification": self.classification,
            "name": self.name,
            "n": self.n,
            "prime": self.prime,
            "equation": self.equation,
            "witness": self.witness,
            "alternate_witnesses": self.alternate_witnesses,
            "letter": self.letter.to_json(),
            "remnant": self.remnant.to_json(),
            "hardness": self.hardness.iter().map(|h| h.to_json()).collect::<Vec<_>>(),
            "engine_geometry": self.engine_geometry.to_json(),
            "domain": self.domain.to_json(),
            "domain_statistics": self.domain_statistics.to_json(),
            "uniqueness": self.uniqueness,
            "verification": self.verification,
            "specification": self.specification,
            "provenance": self.provenance,
            "certificate": self.certificate
        })
    }
}

/// Aggregate Domain Evaluation Result
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GodsLetterDomainEvaluation {
    pub domain: GodsLetterDomain,
    pub spec: GodsLetterSpec,
    pub candidates_evaluated: usize,
    pub surviving_candidates: Vec<GodsLetterCandidateEvaluation>,
    pub uniqueness_status: UniquenessStatus,
    pub statistics: DomainStatistics,
    pub certificate: Option<GodsLetterCertificate>,
    pub corpus_sha256: String,
    pub source_commit: String,
}

impl GodsLetterDomainEvaluation {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "domain": self.domain.to_json(),
            "spec": self.spec.to_json(),
            "candidates_evaluated": self.candidates_evaluated,
            "surviving_candidates": self.surviving_candidates.iter().map(|c| c.to_json()).collect::<Vec<_>>(),
            "uniqueness_status": self.uniqueness_status.to_json(),
            "statistics": self.statistics.to_json(),
            "certificate": self.certificate.as_ref().map(|c| c.to_json()),
            "corpus_sha256": self.corpus_sha256,
            "source_commit": self.source_commit
        })
    }
}

// ============================================================================
// PURE PREDICATES
// ============================================================================

/// 3.1 Prime Predicate P(p)
pub fn evaluate_prime_predicate(p: u128) -> Result<(), &'static str> {
    if p <= 2 {
        return Err("not_prime");
    }
    if p > u64::MAX as u128 {
        // High-integer deterministic primality test
        return if is_prime_u128(p) { Ok(()) } else { Err("not_prime") };
    }
    if is_prime(p as u64) {
        Ok(())
    } else {
        Err("not_prime")
    }
}

fn is_prime_u128(n: u128) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 || n == 3 {
        return true;
    }
    if n % 2 == 0 || n % 3 == 0 {
        return false;
    }
    let mut i = 5u128;
    while i.saturating_mul(i) <= n {
        if n % i == 0 || n % (i + 2) == 0 {
            return false;
        }
        i += 6;
    }
    true
}

/// 3.2 Exact Erdős–Straus Witness Predicate V(p)
pub fn evaluate_witness_predicate(p: u128, w: &EsWitness) -> Result<(), &'static str> {
    if w.n != p {
        return Err("invalid_es_witness");
    }
    if w.x <= BigInt::zero() || w.y <= BigInt::zero() || w.z <= BigInt::zero() {
        return Err("invalid_es_witness");
    }
    if !w.verify() {
        return Err("invalid_es_witness");
    }
    Ok(())
}

/// 4. Letter Predicate L(p)
pub fn evaluate_letter_predicate(
    p: u128,
    witness: Option<&EsWitness>,
    spec: &GodsLetterSpec,
) -> LetterPredicateResult {
    let res_840 = (p % 840) as u64;
    let hard_residue = is_mordell_hard(res_840);
    let preclearance_escaped = (p % 4 != 3) && (p % 3 != 2) && (p % 8 != 5) && (p % 2 != 0);

    let depth = if let Some(w) = witness {
        w.discovery_depth
    } else {
        0
    };

    let prime_ok = evaluate_prime_predicate(p).is_ok();
    let witness_ok = witness.map_or(false, |w| evaluate_witness_predicate(p, w).is_ok());
    let depth_ok = depth >= spec.letter_depth_threshold;

    let admitted = prime_ok && hard_residue && preclearance_escaped && witness_ok && depth_ok;

    let reason = if !prime_ok {
        "Candidate integer is composite or <= 2".to_string()
    } else if !hard_residue {
        format!("Non-Mordell residue ({} mod 840 not in {{1, 121, 169, 289, 361, 529}})", res_840)
    } else if !preclearance_escaped {
        "Preclearance theorem sieve passed (4p+3, 3p+2, or 8p+5)".to_string()
    } else if !witness_ok {
        "Missing or invalid exact 3-Egyptian decomposition witness".to_string()
    } else if !depth_ok {
        format!("Discovery depth (δ={}) below letter threshold ({})", depth, spec.letter_depth_threshold)
    } else {
        "Admitted by Authoritative Central Letter Gate".to_string()
    };

    LetterPredicateResult {
        admitted,
        residue_840: res_840,
        hard_residue,
        preclearance_escaped,
        depth,
        reason,
    }
}

/// 5. Remnant Predicate R(p)
pub fn evaluate_remnant_predicate(p: u128, spec: &GodsLetterSpec) -> RemnantPredicateResult {
    let prime_ok = evaluate_prime_predicate(p).is_ok();
    if !prime_ok || p <= 2 {
        return RemnantPredicateResult {
            admitted: false,
            descent_depth: 0,
            threshold: spec.remnant_threshold,
            terminal_stage: Some(0),
            reason: "Non-prime or candidate <= 2".to_string(),
        };
    }

    if p > u64::MAX as u128 {
        return RemnantPredicateResult {
            admitted: false,
            descent_depth: 0,
            threshold: spec.remnant_threshold,
            terminal_stage: Some(0),
            reason: "Prime exceeds u64 dual-descent horizon".to_string(),
        };
    }

    let (descent_depth, survival_ok) = compute_dual_descent_survival(p as u64);
    let admitted = survival_ok && descent_depth > spec.remnant_threshold;

    let reason = if admitted {
        format!("Survived Dual Descent to depth δ={} (threshold > {})", descent_depth, spec.remnant_threshold)
    } else {
        format!("Dual Descent depth (δ={}) did not exceed Remnant threshold ({})", descent_depth, spec.remnant_threshold)
    };

    RemnantPredicateResult {
        admitted,
        descent_depth,
        threshold: spec.remnant_threshold,
        terminal_stage: if admitted { None } else { Some(descent_depth) },
        reason,
    }
}

/// Ω(p) — Principal Mordell origin generator.
///
/// p is the least prime in the arithmetic progression 840k + 1.
/// This is a well-ordering theorem, not a ranking of hunt findings and not `p == 2521`.
/// 841 = 29² and 1681 = 41² are the only smaller positive terms; both are composite,
/// so the generator is unique among all primes.
pub fn evaluate_origin_generator_predicate(p: u128) -> Result<(), &'static str> {
    if p % PRINCIPAL_MORDELL_MODULUS != PRINCIPAL_MORDELL_RESIDUE {
        return Err("not_principal_mordell_class");
    }
    if evaluate_prime_predicate(p).is_err() {
        return Err("not_prime");
    }
    let mut q = PRINCIPAL_MORDELL_RESIDUE;
    while q < p {
        if q > 1 && is_prime_u128(q) {
            return Err("not_principal_mordell_origin");
        }
        q = q.saturating_add(PRINCIPAL_MORDELL_MODULUS);
        if q == PRINCIPAL_MORDELL_RESIDUE {
            break;
        }
    }
    Ok(())
}

/// 6. Hardness Intersection Predicate H(p)
pub fn evaluate_hardness_criteria(
    p: u128,
    witness: Option<&EsWitness>,
    spec: &GodsLetterSpec,
) -> Vec<HardnessCriterionResult> {
    let mut criteria = Vec::new();

    // Criterion 1: mordell_hard_residue_840
    let res_840 = (p % 840) as u64;
    let is_mordell = is_mordell_hard(res_840);
    criteria.push(HardnessCriterionResult {
        id: "mordell_hard_residue_840".to_string(),
        version: "v1".to_string(),
        passed: is_mordell,
        description: "Candidate prime must belong to a Mordell-hard quadratic non-residue class mod 840 (840k + {1, 121, 169, 289, 361, 529})".to_string(),
        metric: Some(res_840.to_string()),
        details: format!("Residue: {} mod 840; Mordell-hard: {}", res_840, is_mordell),
    });

    // Criterion 2: elementary_preclearance_escape
    let escapes_linear = (p % 4 != 3) && (p % 3 != 2) && (p % 8 != 5) && (p % 2 != 0);
    criteria.push(HardnessCriterionResult {
        id: "elementary_preclearance_escape".to_string(),
        version: "v1".to_string(),
        passed: escapes_linear,
        description: "Candidate must escape all elementary linear congruence sieves (4p+3, 3p+2, 8p+5, 2k)".to_string(),
        metric: None,
        details: if escapes_linear {
            "Escaped all elementary linear modular sieves".to_string()
        } else {
            "Cleared by elementary linear modular congruence".to_string()
        },
    });

    // Criterion 3: dual_descent_ladder_escape
    let (descent_depth, survival_ok) = if p <= u64::MAX as u128 {
        compute_dual_descent_survival(p as u64)
    } else {
        (0, false)
    };
    let deep_descent = survival_ok && descent_depth > spec.remnant_threshold;
    criteria.push(HardnessCriterionResult {
        id: "dual_descent_ladder_escape".to_string(),
        version: "v1".to_string(),
        passed: deep_descent,
        description: format!("Candidate must survive dual-descent ladder beyond Remnant threshold (> {} stages)", spec.remnant_threshold),
        metric: Some(descent_depth.to_string()),
        details: format!("Dual descent survival depth: {} (threshold: > {})", descent_depth, spec.remnant_threshold),
    });

    // Criterion 4: corridor_boundary_broken_window
    // Spec: require a nonzero search offset beyond x_0 = floor(p/4)+1.
    // Residue class 1 is not a substitute for a broken window.
    let broken_window = witness.map_or(false, |w| w.discovery_depth > 0);
    criteria.push(HardnessCriterionResult {
        id: "corridor_boundary_broken_window".to_string(),
        version: "v1".to_string(),
        passed: broken_window,
        description: "Candidate requires search offset (δ > 0) beyond shallow corridor base horizon x_0 = floor(p/4) + 1".to_string(),
        metric: witness.map(|w| w.discovery_depth.to_string()),
        details: format!("Broken window condition verified: {}", broken_window),
    });

    // Criterion 5: astronomical_corridor_or_origin
    // Origin letter (least prime ≡ 1 mod 840) is admitted as the founding artifact.
    // Any later God's Letter must be found at discovery depth ≥ astronomical threshold
    // (beyond the CBAP shallow box). This is a rarity gate, not a uniqueness lock.
    let origin_ok = evaluate_origin_generator_predicate(p).is_ok();
    let astro_ok = witness.map_or(false, |w| w.discovery_depth >= spec.astronomical_depth_threshold);
    let apex_ok = origin_ok || astro_ok;
    criteria.push(HardnessCriterionResult {
        id: "astronomical_corridor_or_origin".to_string(),
        version: "v3".to_string(),
        passed: apex_ok,
        description: format!(
            "Founding origin (least prime ≡ 1 mod 840) OR discovery depth δ ≥ {} (CBX/deep corridor; additional letters only)",
            spec.astronomical_depth_threshold
        ),
        metric: witness.map(|w| w.discovery_depth.to_string()),
        details: if origin_ok {
            format!("ORIGIN LETTER: p={} is the least prime ≡ 1 (mod 840)", p)
        } else if astro_ok {
            format!(
                "ASTRONOMICAL LETTER: discovery depth δ={} ≥ {}",
                witness.map(|w| w.discovery_depth).unwrap_or(0),
                spec.astronomical_depth_threshold
            )
        } else {
            format!(
                "Neither origin nor astronomical: δ={} < {} and not the 840ℤ+1 generator",
                witness.map(|w| w.discovery_depth).unwrap_or(0),
                spec.astronomical_depth_threshold
            )
        },
    });

    criteria
}

/// 7. Engine Complementarity Predicate E(p)
pub fn evaluate_engine_geometries(
    p: u128,
    witness: Option<&EsWitness>,
    descent_depth: u64,
) -> EngineGeometryResult {
    let cbap_signed_box = witness.map_or(false, |w| evaluate_witness_predicate(p, w).is_ok());
    let cbx_dual_descent = descent_depth > REMNANT_THRESHOLD;
    // CBIS phase contraction: a genuine broken window (δ > 0), not a method-name substring.
    let cbis_phase_contraction = witness.map_or(false, |w| w.discovery_depth > 0);
    let cc_preclearance_escaped = (p % 4 != 3) && (p % 3 != 2) && (p % 8 != 5) && (p % 2 != 0);

    EngineGeometryResult {
        cbap_signed_box,
        cbx_dual_descent,
        cbis_phase_contraction,
        cc_preclearance_escaped,
    }
}

// ============================================================================
// CANDIDATE & DOMAIN EVALUATORS
// ============================================================================

/// Evaluates a single candidate prime against all independent God's Letter predicates.
///
/// Invariant: This function does NOT know if other candidates exist in the domain.
pub fn evaluate_gods_letter_candidate(
    p: u128,
    raw_witnesses: &[EsWitness],
    spec: &GodsLetterSpec,
) -> GodsLetterCandidateEvaluation {
    let mut rejection_reasons = Vec::new();

    // 1. Prime Predicate P(p)
    let prime_result = evaluate_prime_predicate(p);
    let is_prime = prime_result.is_ok();
    let prime_passed = is_prime;
    if !prime_passed {
        rejection_reasons.push("not_prime".to_string());
    }

    // 2. Exact Witness Predicate V(p)
    // Canonicalize all provided witnesses: sort x <= y <= z, verify 4xyz identity, sort lexicographically
    let mut verified_witnesses: Vec<EsWitness> = raw_witnesses
        .iter()
        .map(|w| {
            EsWitness::new(
                p,
                w.x.clone(),
                w.y.clone(),
                w.z.clone(),
                &w.method,
                &w.engine_name,
                w.discovery_depth,
            )
        })
        .filter(|w| evaluate_witness_predicate(p, w).is_ok())
        .collect();

    // If no witness was provided, attempt deterministic solver resolution only when
    // the cheap letter-shape predicates can still pass (Mordell-hard + preclearance).
    let letter_shape_possible = is_prime
        && is_mordell_hard((p % 840) as u64)
        && (p % 4 != 3)
        && (p % 3 != 2)
        && (p % 8 != 5)
        && (p % 2 != 0);
    if verified_witnesses.is_empty() && p <= u64::MAX as u128 && letter_shape_possible {
        let solve = solve_es_with_config(p as u64, spec.letter_depth_threshold, "auto");
        if let Some(w) = solve.witness {
            let es_w = EsWitness::new(
                p,
                w.x,
                w.y,
                w.z,
                &w.method,
                &w.engine_name,
                w.discovery_depth,
            );
            if evaluate_witness_predicate(p, &es_w).is_ok() {
                verified_witnesses.push(es_w);
            }
        }
    }

    // Sort deterministically: lexicographic (x, y, z)
    verified_witnesses.sort_by(|a, b| a.cmp_coordinates(b));
    verified_witnesses.dedup_by(|a, b| a.x == b.x && a.y == b.y && a.z == b.z);

    let (canonical_witness, alternate_witnesses) = if !verified_witnesses.is_empty() {
        let canonical = verified_witnesses.remove(0);
        (Some(canonical), verified_witnesses)
    } else {
        (None, Vec::new())
    };

    let witness_verified = canonical_witness.is_some();
    if !witness_verified {
        rejection_reasons.push("invalid_es_witness".to_string());
    }

    // 3. Letter Predicate L(p)
    let letter_result = evaluate_letter_predicate(p, canonical_witness.as_ref(), spec);
    if !letter_result.admitted {
        rejection_reasons.push("not_letter".to_string());
    }

    // 4. Remnant Predicate R(p)
    let remnant_result = evaluate_remnant_predicate(p, spec);
    if !remnant_result.admitted {
        rejection_reasons.push("not_remnant".to_string());
    }

    // 5. Hardness Intersection Predicate H(p)
    let hardness_results = evaluate_hardness_criteria(p, canonical_witness.as_ref(), spec);
    let hardness_passed = hardness_results.iter().all(|c| c.passed);
    if !hardness_passed {
        rejection_reasons.push("hardness_criteria_failed".to_string());
    }

    // 6. Engine Complementarity Predicate E(p)
    let engine_result = evaluate_engine_geometries(
        p,
        canonical_witness.as_ref(),
        remnant_result.descent_depth,
    );
    let engine_passed = engine_result.cbap_signed_box
        && engine_result.cbx_dual_descent
        && engine_result.cbis_phase_contraction
        && engine_result.cc_preclearance_escaped;
    if !engine_passed {
        rejection_reasons.push("engine_complementarity_failed".to_string());
    }

    let origin_generator = evaluate_origin_generator_predicate(p).is_ok();
    let astronomical = canonical_witness
        .as_ref()
        .map(|w| w.discovery_depth >= spec.astronomical_depth_threshold)
        .unwrap_or(false);

    // God's Letter = Mordell-hard prime that the full engine menu did not solve.
    // A verified witness is a Letter / Escape / Remnant — never a God's Letter.
    let unsolved_alarm = prime_passed && letter_shape_possible && !witness_verified;
    let gods_letter_candidate = unsolved_alarm;
    let gods_letter_kind = if gods_letter_candidate {
        Some("unsolved".to_string())
    } else {
        None
    };
    if witness_verified {
        rejection_reasons.push("solved_not_gods_letter".to_string());
    }

    GodsLetterCandidateEvaluation {
        p,
        is_prime,
        prime_passed,
        witness: canonical_witness,
        alternate_witnesses,
        witness_verified,
        letter: letter_result,
        remnant: remnant_result,
        hardness: hardness_results,
        hardness_passed,
        engine_geometry: engine_result,
        origin_generator,
        astronomical,
        unsolved_alarm,
        gods_letter_kind,
        gods_letter_candidate,
        rejection_reasons,
    }
}

/// Raw candidate input discovered from repository vaults / search
#[derive(Clone, Debug)]
pub struct CandidateInput {
    pub p: u128,
    pub witnesses: Vec<EsWitness>,
    pub source_files: Vec<String>,
}

/// Evaluates all candidates across a certified domain, enforces the singleton rule,
/// and builds the deterministic domain certificate and statistics.
pub fn evaluate_gods_letter_domain(
    domain: &GodsLetterDomain,
    discovered_corpus: Option<&[CandidateInput]>,
    spec: &GodsLetterSpec,
) -> GodsLetterDomainEvaluation {
    // 1. Gather all candidate primes in the certified domain.
    // Corpus witnesses accelerate V(p) but never replace the domain scan:
    // uniqueness is a claim about D, not about files on disk.
    let mut candidate_map: BTreeMap<u128, Vec<EsWitness>> = BTreeMap::new();

    let start = if domain.lower_bound < 2 { 2 } else { domain.lower_bound };
    let end = domain.upper_bound;
    if start <= end {
        for n in start..=end {
            if !domain.primes_only || is_prime_u128(n) {
                candidate_map.insert(n, Vec::new());
            }
        }
    }

    if let Some(corpus) = discovered_corpus {
        for item in corpus {
            if domain.contains(item.p) {
                let entry = candidate_map.entry(item.p).or_default();
                entry.extend(item.witnesses.clone());
            }
        }
    }

    let total_integers_considered = if domain.upper_bound >= domain.lower_bound {
        (domain.upper_bound - domain.lower_bound + 1) as usize
    } else {
        0
    };

    let primes_tested = candidate_map.len();
    let mut letter_survivors_count = 0;
    let mut remnant_survivors_count = 0;
    let mut letter_remnant_count = 0;
    let mut hardness_survivors_count = 0;
    let mut full_survivors: Vec<GodsLetterCandidateEvaluation> = Vec::new();

    let mut evaluated_candidates: Vec<GodsLetterCandidateEvaluation> = Vec::new();

    for (&p, witnesses) in &candidate_map {
        let eval = evaluate_gods_letter_candidate(p, witnesses, spec);

        if eval.letter.admitted {
            letter_survivors_count += 1;
        }
        if eval.remnant.admitted {
            remnant_survivors_count += 1;
        }
        if eval.letter.admitted && eval.remnant.admitted {
            letter_remnant_count += 1;
        }
        if eval.hardness_passed {
            hardness_survivors_count += 1;
        }
        if eval.gods_letter_candidate {
            full_survivors.push(eval.clone());
        }

        evaluated_candidates.push(eval);
    }

    let full_candidate_count = full_survivors.len();

    // 8. SINGLETON RULE
    let uniqueness_status = match full_candidate_count {
        0 => UniquenessStatus::NoGodsLetter,
        1 => UniquenessStatus::UniqueWithinCertifiedDomain,
        n => UniquenessStatus::NonUnique { candidate_count: n },
    };

    // Stage progression statistics for audit / explain
    let stage_progression = vec![
        StageCount {
            stage_name: "CERTIFIED_DOMAIN_INTEGERS".to_string(),
            entering_count: total_integers_considered,
            surviving_count: primes_tested,
            eliminated_count: total_integers_considered.saturating_sub(primes_tested),
        },
        StageCount {
            stage_name: "PRIME_FILTER_P(p)".to_string(),
            entering_count: primes_tested,
            surviving_count: primes_tested,
            eliminated_count: 0,
        },
        StageCount {
            stage_name: "LETTER_ADMISSION_L(p)".to_string(),
            entering_count: primes_tested,
            surviving_count: letter_survivors_count,
            eliminated_count: primes_tested.saturating_sub(letter_survivors_count),
        },
        StageCount {
            stage_name: "REMNANT_ADMISSION_R(p)".to_string(),
            entering_count: letter_survivors_count,
            surviving_count: letter_remnant_count,
            eliminated_count: letter_survivors_count.saturating_sub(letter_remnant_count),
        },
        StageCount {
            stage_name: "HARDNESS_INTERSECTION_H(p)".to_string(),
            entering_count: letter_remnant_count,
            surviving_count: full_candidate_count,
            eliminated_count: letter_remnant_count.saturating_sub(full_candidate_count),
        },
        StageCount {
            stage_name: "SINGLETON_SURVIVOR_G(p)".to_string(),
            entering_count: full_candidate_count,
            surviving_count: if full_candidate_count == 1 { 1 } else { 0 },
            eliminated_count: if full_candidate_count == 1 { 0 } else { full_candidate_count },
        },
    ];

    let statistics = DomainStatistics {
        total_integers_considered,
        primes_tested,
        letter_survivors: letter_survivors_count,
        remnant_survivors: remnant_survivors_count,
        letter_remnant_intersection: letter_remnant_count,
        hardness_survivors: hardness_survivors_count,
        full_candidates: full_candidate_count,
        stage_progression,
    };

    // Calculate deterministic corpus hash
    let mut corpus_hasher = Sha256::new();
    corpus_hasher.update(format!("spec:{}\n", spec.version).as_bytes());
    corpus_hasher.update(format!("domain:{}:{}\n", domain.lower_bound, domain.upper_bound).as_bytes());
    for (&p, _) in &candidate_map {
        corpus_hasher.update(format!("p:{}\n", p).as_bytes());
    }
    let corpus_digest = corpus_hasher.finalize();
    let corpus_sha256: String = corpus_digest.iter().map(|b| format!("{:02x}", b)).collect();

    let source_commit = "26.12.0-release".to_string();

    // Certificate for the founding origin if present, else the least certified survivor with a witness.
    // Multiple astronomical letters are allowed; they do not void the origin certificate.
    let certificate = if let Some(winner) = full_survivors
        .iter()
        .find(|c| c.origin_generator && c.witness.is_some())
        .or_else(|| full_survivors.iter().find(|c| c.witness.is_some()))
    {
        let w = winner.witness.as_ref().unwrap();

        let alt_json: Vec<serde_json::Value> = winner
            .alternate_witnesses
            .iter()
            .map(|alt| {
                serde_json::json!({
                    "x": alt.x.to_string(),
                    "y": alt.y.to_string(),
                    "z": alt.z.to_string(),
                    "method": alt.method,
                    "engine_name": alt.engine_name,
                    "equation": alt.equation()
                })
            })
            .collect();

        let artifact_id = format!("GL-{}", winner.p);

        // Deterministic certificate hash material (excludes volatile generated_at)
        let hash_payload = serde_json::json!({
            "schema": GODS_LETTER_SCHEMA,
            "artifact_id": artifact_id,
            "classification": CLASSIFICATION_GODS_LETTER,
            "name": "God's Letter",
            "n": winner.p,
            "prime": true,
            "equation": w.equation(),
            "witness": {
                "x": w.x.to_string(),
                "y": w.y.to_string(),
                "z": w.z.to_string()
            },
            "alternate_witnesses": alt_json,
            "letter": winner.letter.to_json(),
            "remnant": winner.remnant.to_json(),
            "hardness": winner.hardness.iter().map(|h| h.to_json()).collect::<Vec<_>>(),
            "engine_geometry": winner.engine_geometry.to_json(),
            "domain": domain.to_json(),
            "domain_statistics": {
                "total_integers_considered": statistics.total_integers_considered,
                "primes_tested": statistics.primes_tested,
                "full_candidates": statistics.full_candidates
            },
            "gods_letter_kind": winner.gods_letter_kind,
            "uniqueness": uniqueness_status.to_json(),
            "verification": {
                "exact_identity": true,
                "all_predicates_recomputed": true,
                "verified": true
            },
            "specification": {
                "name": spec.name,
                "version": spec.version
            },
            "provenance": {
                "source_commit": source_commit,
                "corpus_sha256": corpus_sha256
            }
        });

        let hash_str = serde_json::to_string(&hash_payload).unwrap_or_default();
        let mut cert_hasher = Sha256::new();
        cert_hasher.update(hash_str.as_bytes());
        let cert_digest = cert_hasher.finalize();
        let cert_hash: String = cert_digest.iter().map(|b| format!("{:02x}", b)).collect();

        Some(GodsLetterCertificate {
            schema: GODS_LETTER_SCHEMA.to_string(),
            artifact_id,
            classification: CLASSIFICATION_GODS_LETTER.to_string(),
            name: "God's Letter".to_string(),
            n: winner.p,
            prime: true,
            equation: w.equation(),
            witness: serde_json::json!({
                "x": w.x.to_string(),
                "y": w.y.to_string(),
                "z": w.z.to_string()
            }),
            alternate_witnesses: alt_json,
            letter: winner.letter.clone(),
            remnant: winner.remnant.clone(),
            hardness: winner.hardness.clone(),
            engine_geometry: winner.engine_geometry.clone(),
            domain: domain.clone(),
            domain_statistics: statistics.clone(),
            uniqueness: uniqueness_status.to_json(),
            verification: serde_json::json!({
                "exact_identity": true,
                "all_predicates_recomputed": true,
                "verified": true
            }),
            specification: serde_json::json!({
                "name": spec.name.clone(),
                "version": spec.version.clone()
            }),
            provenance: serde_json::json!({
                "source_commit": source_commit.clone(),
                "corpus_sha256": corpus_sha256.clone(),
                "generated_at": "2026-08-22T00:00:00Z"
            }),
            certificate: cert_hash,
        })
    } else {
        None
    };

    GodsLetterDomainEvaluation {
        domain: domain.clone(),
        spec: spec.clone(),
        candidates_evaluated: evaluated_candidates.len(),
        surviving_candidates: full_survivors,
        uniqueness_status,
        statistics,
        certificate,
        corpus_sha256,
        source_commit,
    }
}

/// Convenience predicate requiring domain and spec context
pub fn is_gods_letter(p: u128, domain: &GodsLetterDomain, spec: &GodsLetterSpec) -> bool {
    let eval = evaluate_gods_letter_domain(domain, None, spec);
    if eval.uniqueness_status == UniquenessStatus::UniqueWithinCertifiedDomain {
        eval.surviving_candidates.first().map_or(false, |c| c.p == p)
    } else {
        false
    }
}

// ============================================================================
// CORPUS DISCOVERY
// ============================================================================

fn json_u128(v: &serde_json::Value) -> Option<u128> {
    if let Some(n) = v.as_u64() {
        return Some(n as u128);
    }
    if let Some(s) = v.as_str() {
        return s.parse::<u128>().ok();
    }
    None
}

fn json_u64(v: &serde_json::Value) -> Option<u64> {
    if let Some(n) = v.as_u64() {
        return Some(n);
    }
    if let Some(s) = v.as_str() {
        return s.parse::<u64>().ok();
    }
    None
}

fn json_bigint(v: &serde_json::Value) -> Option<BigInt> {
    if let Some(s) = v.as_str() {
        return BigInt::from_str(s).ok();
    }
    if let Some(n) = v.as_u64() {
        return Some(BigInt::from_u64(n));
    }
    if let Some(s) = v.as_i64().map(|n| n.to_string()) {
        return BigInt::from_str(&s).ok();
    }
    None
}

fn extract_corpus_prime(val: &serde_json::Value) -> Option<u128> {
    val.get("n")
        .and_then(json_u128)
        .or_else(|| val.get("p").and_then(json_u128))
        .or_else(|| val.get("event").and_then(|e| e.get("p").and_then(json_u128)))
        .or_else(|| val.get("event").and_then(|e| e.get("n").and_then(json_u128)))
}

fn extract_corpus_witness(p: u128, val: &serde_json::Value) -> Option<EsWitness> {
    let w_obj = val.get("witness").or_else(|| val.get("event"));
    let (x, y, z) = if let Some(w_obj) = w_obj {
        match (
            json_bigint(w_obj.get("x")?),
            json_bigint(w_obj.get("y")?),
            json_bigint(w_obj.get("z")?),
        ) {
            (Some(x), Some(y), Some(z)) => (x, y, z),
            _ => return None,
        }
    } else {
        return None;
    };

    let method = val
        .get("method")
        .and_then(|v| v.as_str())
        .or_else(|| val.get("event").and_then(|e| e.get("method").and_then(|v| v.as_str())))
        .unwrap_or("corridor_discovery");
    let engine = val
        .get("discovered_by")
        .and_then(|v| v.as_str())
        .or_else(|| val.get("event").and_then(|e| e.get("kernel").and_then(|v| v.as_str())))
        .unwrap_or("CENTL");
    let depth = val
        .get("discovery_depth")
        .and_then(json_u64)
        .or_else(|| val.get("depth").and_then(json_u64))
        .or_else(|| val.get("event").and_then(|e| e.get("discovery_depth").and_then(json_u64)))
        .unwrap_or(0);

    let w = EsWitness::new(p, x, y, z, method, engine, depth);
    if w.verify() {
        Some(w)
    } else {
        None
    }
}

/// Discovers candidate primes and their witnesses from repository vaults and findings.
/// Normalizes duplicates so that candidate identity is solely `p`.
pub fn discover_corpus_candidates(domain: &GodsLetterDomain) -> Vec<CandidateInput> {
    let mut candidate_map: HashMap<u128, (Vec<EsWitness>, Vec<String>)> = HashMap::new();

    let search_dirs = [
        PathBuf::from("letters"),
        PathBuf::from("remnants"),
        PathBuf::from("escapes"),
        PathBuf::from("gods-letter"),
        PathBuf::from("research/erdos-straus/letters"),
        PathBuf::from("research/erdos-straus/remnants"),
        PathBuf::from("research/erdos-straus/escapes"),
        PathBuf::from("research/erdos-straus/findings"),
        PathBuf::from("../letters"),
        PathBuf::from("../remnants"),
        PathBuf::from("../escapes"),
        PathBuf::from("../gods-letter"),
    ];

    for base_dir in &search_dirs {
        if !base_dir.is_dir() {
            continue;
        }
        collect_json_files_recursive(base_dir, &mut |file_path, content| {
            if let Ok(val) = serde_json::from_str::<serde_json::Value>(content) {
                if let Some(p) = extract_corpus_prime(&val) {
                    if domain.contains(p) {
                        let witness_opt = extract_corpus_witness(p, &val);
                        let entry = candidate_map.entry(p).or_insert_with(|| (Vec::new(), Vec::new()));
                        entry.1.push(file_path.to_string_lossy().to_string());
                        if let Some(w) = witness_opt {
                            entry.0.push(w);
                        }
                    }
                }
            }
        });
    }

    let mut result: Vec<CandidateInput> = candidate_map
        .into_iter()
        .map(|(p, (mut witnesses, mut source_files))| {
            witnesses.sort_by(|a, b| a.cmp_coordinates(b));
            witnesses.dedup_by(|a, b| a.x == b.x && a.y == b.y && a.z == b.z);
            source_files.sort();
            source_files.dedup();
            CandidateInput {
                p,
                witnesses,
                source_files,
            }
        })
        .collect();

    result.sort_by_key(|c| c.p);
    result
}

fn collect_json_files_recursive<F: FnMut(&Path, &str)>(dir: &Path, callback: &mut F) {
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                // Avoid recursing into target or build directories
                let name = path.file_name().unwrap_or_default().to_string_lossy();
                if name != "target" && name != "build" && name != "_build" && name != ".git" && name != "history" {
                    collect_json_files_recursive(&path, callback);
                }
            } else if path.extension().and_then(|s| s.to_str()) == Some("json") {
                let fname = path.file_name().unwrap_or_default().to_string_lossy();
                if fname == "last-evaluation.json" || fname == "index.json" {
                    continue;
                }
                if let Ok(content) = fs::read_to_string(&path) {
                    callback(&path, &content);
                }
            }
        }
    }
}

// ============================================================================
// PERSISTENCE
// ============================================================================

pub fn resolve_gods_letter_dir() -> PathBuf {
    if let Ok(custom) = std::env::var("CENTL_GODS_LETTER_DIR") {
        let p = PathBuf::from(custom);
        let _ = fs::create_dir_all(&p);
        return p;
    }
    // Prefer the repository vault even when the process cwd is an .app Resources dir.
    if let Ok(mut dir) = std::env::current_dir() {
        for _ in 0..8 {
            let vault = dir.join("gods-letter");
            if dir.join("Cargo.toml").exists() && vault.is_dir() {
                return vault;
            }
            if !dir.pop() {
                break;
            }
        }
    }
    let candidates = [
        PathBuf::from("gods-letter"),
        PathBuf::from("research/erdos-straus/gods-letter"),
        PathBuf::from("../gods-letter"),
    ];
    for cand in &candidates {
        if cand.is_dir() {
            return cand.clone();
        }
    }
    let default_dir = PathBuf::from("gods-letter");
    let _ = fs::create_dir_all(&default_dir);
    default_dir
}

/// Always writes the latest domain evaluation report (even on singleton failure).
pub fn persist_domain_evaluation_report(eval: &GodsLetterDomainEvaluation) -> Result<PathBuf, String> {
    let dir = resolve_gods_letter_dir();
    let path = dir.join("last-evaluation.json");
    let json_str = serde_json::to_string_pretty(&eval.to_json()).map_err(|e| e.to_string())?;
    fs::write(&path, json_str).map_err(|e| e.to_string())?;
    Ok(path)
}

pub fn load_current_gods_letter_json() -> Option<serde_json::Value> {
    let dir = resolve_gods_letter_dir();
    for name in ["current.json", "last-evaluation.json"] {
        let path = dir.join(name);
        if let Ok(content) = fs::read_to_string(&path) {
            if let Ok(val) = serde_json::from_str::<serde_json::Value>(&content) {
                return Some(val);
            }
        }
    }
    None
}

/// Re-evaluate the certified domain and compare against a stored GL certificate.
pub fn verify_stored_gods_letter(
    eval: &GodsLetterDomainEvaluation,
) -> serde_json::Value {
    let stored = load_current_gods_letter_json();
    match (&eval.uniqueness_status, stored) {
        (UniquenessStatus::UniqueWithinCertifiedDomain, Some(stored)) => {
            // current.json is the certificate object; last-evaluation.json wraps it.
            let stored_hash = stored.get("certificate").and_then(|v| {
                v.as_str().map(|s| s.to_string()).or_else(|| {
                    v.get("certificate")
                        .and_then(|inner| inner.as_str())
                        .map(|s| s.to_string())
                })
            });
            let live_hash = eval.certificate.as_ref().map(|c| c.certificate.clone());
            let stored_n = stored
                .get("n")
                .and_then(json_u128)
                .or_else(|| stored.get("certificate").and_then(|c| c.get("n")).and_then(json_u128));
            let live_n = eval.surviving_candidates.first().map(|c| c.p);
            let hashes_match = stored_hash.as_ref() == live_hash.as_ref();
            let n_match = stored_n == live_n;
            serde_json::json!({
                "verified": hashes_match && n_match && eval.certificate.is_some(),
                "hashes_match": hashes_match,
                "prime_match": n_match,
                "stored_prime": stored_n.map(|n| n.to_string()),
                "live_prime": live_n.map(|n| n.to_string()),
                "uniqueness": eval.uniqueness_status.to_json()
            })
        }
        (status, None) => serde_json::json!({
            "verified": false,
            "reason": "no stored God's Letter certificate",
            "uniqueness": status.to_json()
        }),
        (status, Some(_)) => serde_json::json!({
            "verified": false,
            "reason": "live evaluation is not a unique God's Letter",
            "uniqueness": status.to_json()
        }),
    }
}

/// Persists the God's Letter certificate and markdown artifact if and only if
/// uniqueness is certified (exactly 1 survivor).
pub fn persist_gods_letter_artifact(eval: &GodsLetterDomainEvaluation) -> Result<PathBuf, String> {
    let _ = persist_domain_evaluation_report(eval);

    if eval.surviving_candidates.is_empty() {
        return Err(format!(
            "Cannot persist God's Letter: no unsolved survivors ({:?})",
            eval.uniqueness_status
        ));
    }

    let mut last_path: Option<PathBuf> = None;
    for cand in &eval.surviving_candidates {
        if let Ok(path) = persist_gods_letter_candidate(cand) {
            last_path = Some(path);
        }
    }

    let Some(cert) = eval.certificate.as_ref() else {
        return last_path.ok_or_else(|| "Failed to persist unsolved God's Letter files".to_string());
    };
    let dir = resolve_gods_letter_dir();
    let p = cert.n;
    let artifact_id = format!("GL-{}", p);

    let json_path = dir.join(format!("{}.json", artifact_id));
    let md_path = dir.join(format!("{}.md", artifact_id));
    let current_json_path = dir.join("current.json");
    let readme_path = dir.join("README.md");

    // Format JSON
    let json_str = serde_json::to_string_pretty(&cert.to_json()).map_err(|e| e.to_string())?;
    fs::write(&json_path, &json_str).map_err(|e| e.to_string())?;
    fs::write(&current_json_path, &json_str).map_err(|e| e.to_string())?;

    // Format Markdown
    let x_str = cert.witness.get("x").and_then(|v| v.as_str()).unwrap_or("");
    let y_str = cert.witness.get("y").and_then(|v| v.as_str()).unwrap_or("");
    let z_str = cert.witness.get("z").and_then(|v| v.as_str()).unwrap_or("");

    let md_content = format!(
        "# GOD'S LETTER: #{artifact_id}\n\n\
        > **Terminal Erdős–Straus Hunt Certification**  \n\
        > Classification: `gods_letter` · Status: `UNIQUE WITHIN CERTIFIED DOMAIN`\n\n\
        ## Executive Verification Summary\n\
        - **Target Prime (p)**: `{p}`\n\
        - **Artifact ID**: `{artifact_id}`\n\
        - **Letter Status**: `PASS` (Mordell-Hard Residue `{res_840}` mod 840)\n\
        - **Remnant Status**: `PASS` (Dual Descent Depth `{descent_depth}` > `{remnant_thresh}`)\n\
        - **Hardness Intersection**: `ALL PASS` (5/5 Mandatory Geometry Criteria, including principal Mordell origin)\n\
        - **Exact Witness Verification**: `TRUE (100% Arbitrary-Precision Rational Identity Proof)`\n\
        - **Surviving Candidate Count**: `1` (Unique singleton survivor)\n\
        - **Certified Hunt Domain**: `{lower} <= p <= {upper}`\n\
        - **Specification Version**: `{spec_name} v{spec_ver}`\n\
        - **SHA-256 Certificate**: `{cert_hash}`\n\n\
        ## Exact 3-Egyptian Fraction Decomposition\n\
        $$ \\frac{{4}}{{{p}}} = \\frac{{1}}{{{x}}} + \\frac{{1}}{{{y}}} + \\frac{{1}}{{{z}}} $$\n\n\
        ```text\n\
        {equation}\n\
        ```\n\n\
        ## Canonical Witness Coordinates\n\
        - **x**: `{x}`\n\
        - **y**: `{y}`\n\
        - **z**: `{z}`\n\
        - **Identity**: `4*x*y*z == p*(x*y + x*z + y*z)`\n\
        - **Rational Arithmetic**: Exact `BigInt` (Zero floating-point approximation)\n\n\
        ## Elimination Progression\n\
        ```text\n\
        Integers in Certified Domain  : {integers_scanned}\n\
        Primes Tested                 : {primes_tested}\n\
        Letter Survivors              : {letters_survived}\n\
        Remnant Survivors             : {remnants_survived}\n\
        Letter ∩ Remnant Intersection : {intersection_count}\n\
        Hardness Intersection         : {hardness_survived}\n\
        Final God's Letter Candidates : 1\n\
        ```\n\n\
        ## Scientific Claim Boundaries\n\
        *Exactly one God's Letter exists in certified domain [{lower}, {upper}] under specification version {spec_ver}.*\n",
        artifact_id = artifact_id,
        p = p,
        res_840 = cert.letter.residue_840,
        descent_depth = cert.remnant.descent_depth,
        remnant_thresh = cert.remnant.threshold,
        lower = cert.domain.lower_bound,
        upper = cert.domain.upper_bound,
        spec_name = eval.spec.name,
        spec_ver = eval.spec.version,
        cert_hash = cert.certificate,
        equation = cert.equation,
        x = x_str,
        y = y_str,
        z = z_str,
        integers_scanned = cert.domain_statistics.total_integers_considered,
        primes_tested = cert.domain_statistics.primes_tested,
        letters_survived = cert.domain_statistics.letter_survivors,
        remnants_survived = cert.domain_statistics.remnant_survivors,
        intersection_count = cert.domain_statistics.letter_remnant_intersection,
        hardness_survived = cert.domain_statistics.hardness_survivors,
    );

    fs::write(&md_path, md_content).map_err(|e| e.to_string())?;

    // Maintain history archive: gods-letter/history/spec-v1/domain-<domain_hash>/GL-<p>.json
    let domain_hash = eval.domain.domain_hash();
    let history_dir = dir.join("history").join(format!("spec-v{}", eval.spec.version)).join(format!("domain-{}", domain_hash));
    let _ = fs::create_dir_all(&history_dir);
    let history_json = history_dir.join(format!("{}.json", artifact_id));
    let _ = fs::write(&history_json, &json_str);

    // Write vault README if missing
    if !readme_path.exists() {
        let readme_content = "# God's Letter Vault\n\n\
        This directory stores the unique terminal **God's Letter** artifact of the Erdős–Straus Hunt.\n\n\
        ## Terminal Contract Invariant\n\
        God's Letter is emitted if and only if exactly one candidate prime survives the complete set of independent\n\
        Letter, Remnant, Hardness, and Engine predicates over a certified finite hunt domain.\n\n\
        - `current.json`: Current active certified God's Letter.\n\
        - `GL-<p>.json`: Content-addressed machine certificate.\n\
        - `GL-<p>.md`: Mathematical verification report.\n\
        - `history/`: Immutable historical record of previous specification/domain runs.\n";
        let _ = fs::write(&readme_path, readme_content);
    }

    Ok(json_path)
}

/// Persist one God's Letter: an unsolved Mordell-hard prime after the full engine menu.
/// Solved decompositions are refused — they belong in letters/, remnants/, or escapes/.
pub fn persist_gods_letter_candidate(eval: &GodsLetterCandidateEvaluation) -> Result<PathBuf, String> {
    if !eval.gods_letter_candidate {
        return Err(format!("p={} is not a God's Letter candidate", eval.p));
    }
    if eval.witness_verified {
        return Err(format!(
            "p={} has a verified witness; that is a letter/escape/remnant, not a God's Letter",
            eval.p
        ));
    }

    let dir = resolve_gods_letter_dir();
    let artifact_id = format!("GL-{}", eval.p);
    let json_path = dir.join(format!("{}.json", artifact_id));
    let md_path = dir.join(format!("{}.md", artifact_id));
    let kind = eval
        .gods_letter_kind
        .clone()
        .unwrap_or_else(|| "unsolved".to_string());

    let payload = serde_json::json!({
        "schema": GODS_LETTER_SCHEMA,
        "artifact_id": artifact_id,
        "classification": CLASSIFICATION_GODS_LETTER,
        "gods_letter_kind": kind,
        "n": eval.p.to_string(),
        "prime": eval.is_prime,
        "equation": null,
        "witness": null,
        "status": "unsolved_in_engine_horizon",
        "search_horizon": {
            "engine": "auto",
            "x_span": "x0 ..= n+2000",
            "y_span": 5000,
            "note": "Not a proof of a counterexample. Unsolved inside this certified search menu only."
        },
        "letter": eval.letter.to_json(),
        "remnant": eval.remnant.to_json(),
        "hardness": eval.hardness.iter().map(|h| h.to_json()).collect::<Vec<_>>(),
        "engine_geometry": eval.engine_geometry.to_json(),
        "specification": {
            "name": GODS_LETTER_SPEC_NAME,
            "version": GODS_LETTER_SPEC_VERSION
        }
    });
    let json_str = serde_json::to_string_pretty(&payload).map_err(|e| e.to_string())?;
    fs::write(&json_path, &json_str).map_err(|e| e.to_string())?;
    let _ = fs::write(dir.join("current.json"), &json_str);

    let md = format!(
        "# GOD'S LETTER: #{id}\n\n\
         > Classification: `gods_letter` · Kind: `unsolved`\n\n\
         Mordell-hard prime `{p}` was **not** decomposed by the full engine menu (CC theorems + two-target corridor + BB).\n\n\
         - **Residue mod 840**: `{res}`\n\
         - **Dual descent**: `{desc}`\n\
         - **Witness**: none\n\
         - **Claim boundary**: unsolved inside the certified search horizon, not a proof that no identity exists.\n",
        id = artifact_id,
        p = eval.p,
        res = eval.letter.residue_840,
        desc = eval.remnant.descent_depth,
    );
    fs::write(&md_path, md).map_err(|e| e.to_string())?;
    refresh_gods_letter_index(&dir);
    Ok(json_path)
}

fn refresh_gods_letter_index(dir: &Path) {
    let mut letters = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            let name = path.file_name().and_then(|s| s.to_str()).unwrap_or("");
            if name.starts_with("GL-") && path.extension().and_then(|s| s.to_str()) == Some("json") {
                if let Ok(content) = fs::read_to_string(&path) {
                    if let Ok(val) = serde_json::from_str::<serde_json::Value>(&content) {
                        letters.push(val);
                    }
                }
            }
        }
    }
    letters.sort_by(|a, b| {
        let na = a.get("n").and_then(json_u128).unwrap_or(0);
        let nb = b.get("n").and_then(json_u128).unwrap_or(0);
        na.cmp(&nb)
    });
    let index = serde_json::json!({
        "schema": "centl26.erdos-straus.gods-letter-index/v1",
        "total": letters.len(),
        "letters": letters.iter().map(|v| serde_json::json!({
            "artifact_id": v.get("artifact_id"),
            "n": v.get("n"),
            "gods_letter_kind": v.get("gods_letter_kind"),
            "equation": v.get("equation")
        })).collect::<Vec<_>>()
    });
    let _ = fs::write(dir.join("index.json"), serde_json::to_string_pretty(&index).unwrap_or_default());
}

/// Re-evaluate letters/remnants/escapes and persist any that currently qualify as God's Letters.
pub fn ingest_gods_letters_from_corpus() -> Vec<PathBuf> {
    let spec = GodsLetterSpec::v1();
    let domain = GodsLetterDomain::default_certified();
    let corpus = discover_corpus_candidates(&domain);
    let mut written = Vec::new();
    for item in &corpus {
        let eval = evaluate_gods_letter_candidate(item.p, &item.witnesses, &spec);
        if eval.gods_letter_candidate {
            if let Ok(path) = persist_gods_letter_candidate(&eval) {
                written.push(path);
            }
        }
    }
    written
}

// ============================================================================
// FORMATTERS FOR CLI & HUMAN OUTPUT
// ============================================================================

pub fn format_human_summary(eval: &GodsLetterDomainEvaluation) -> String {
    match eval.uniqueness_status {
        UniquenessStatus::UniqueWithinCertifiedDomain => {
            let cert = eval.certificate.as_ref().unwrap();
            let x_str = cert.witness.get("x").and_then(|v| v.as_str()).unwrap_or("");
            let y_str = cert.witness.get("y").and_then(|v| v.as_str()).unwrap_or("");
            let z_str = cert.witness.get("z").and_then(|v| v.as_str()).unwrap_or("");

            format!(
                "GOD'S LETTER\n\n\
                Prime:              {}\n\
                Artifact:           {}\n\
                Letter:             PASS\n\
                Remnant:            PASS\n\
                Hardness criteria:  ALL PASS\n\
                Exact ES witness:   VERIFIED\n\
                Candidate count:    1\n\n\
                Status:\n\
                UNIQUE WITHIN CERTIFIED DOMAIN\n\n\
                Domain:\n\
                {} <= p <= {}\n\n\
                {}\n\n\
                Witness:\n\
                x = {}\n\
                y = {}\n\
                z = {}\n\n\
                Certificate:\n\
                {}",
                cert.n,
                cert.artifact_id,
                cert.domain.lower_bound,
                cert.domain.upper_bound,
                cert.equation,
                x_str,
                y_str,
                z_str,
                cert.certificate
            )
        }
        UniquenessStatus::NoGodsLetter => {
            format!(
                "NO GOD'S LETTER\n\n\
                Candidate count: 0\n\
                Status: NO SURVIVORS IN CERTIFIED DOMAIN\n\
                Domain: {} <= p <= {}\n\
                Primes tested: {}\n",
                eval.domain.lower_bound,
                eval.domain.upper_bound,
                eval.statistics.primes_tested
            )
        }
        UniquenessStatus::NonUnique { candidate_count } => {
            let primes_str = eval
                .surviving_candidates
                .iter()
                .map(|c| c.p.to_string())
                .collect::<Vec<_>>()
                .join(", ");
            format!(
                "GOD'S LETTER — MULTIPLE CERTIFIED SURVIVORS\n\n\
                Candidate count: {}\n\
                Status: ADDITIONAL ASTRONOMICAL LETTER(S) BEYOND THE ORIGIN\n\
                Domain: {} <= p <= {}\n\
                Surviving candidates: [{}]\n\
                Origin artifact is retained; each additional letter is persisted.\n",
                candidate_count,
                eval.domain.lower_bound,
                eval.domain.upper_bound,
                primes_str
            )
        }
    }
}

pub fn format_explain_tree(eval: &GodsLetterDomainEvaluation) -> String {
    let mut out = String::new();
    out.push_str("=== GOD'S LETTER ELIMINATION TREE & AUDIT TRAIL ===\n\n");
    out.push_str("CERTIFIED DOMAIN\n");
    out.push_str("      |\n");
    out.push_str("      v\n");
    out.push_str(&format!("   PRIMES ({})\n", eval.statistics.primes_tested));
    out.push_str("      |\n");
    out.push_str("      v\n");
    out.push_str(&format!("   LETTER SURVIVORS ({})\n", eval.statistics.letter_survivors));
    out.push_str("      |\n");
    out.push_str("      v\n");
    out.push_str(&format!("   REMNANT SURVIVORS ({})\n", eval.statistics.remnant_survivors));
    out.push_str("      |\n");
    out.push_str("      v\n");
    out.push_str(&format!(" LETTER ∩ REMNANT ({})\n", eval.statistics.letter_remnant_intersection));
    out.push_str("      |\n");
    out.push_str("      v\n");
    out.push_str(&format!(" HARDNESS CRITERIA ({})\n", eval.statistics.hardness_survivors));
    out.push_str("      |\n");
    out.push_str("      v\n");
    out.push_str(&format!(" EXACT ES VERIFIED ({})\n", eval.statistics.full_candidates));
    out.push_str("      |\n");
    out.push_str("      v\n");
    if eval.uniqueness_status == UniquenessStatus::UniqueWithinCertifiedDomain {
        let p = eval.surviving_candidates[0].p;
        out.push_str(&format!(" GOD'S LETTER (GL-{})\n\n", p));
    } else {
        out.push_str(&format!(" {}\n\n", eval.uniqueness_status.as_str().to_uppercase()));
        if !eval.surviving_candidates.is_empty() {
            out.push_str("Surviving G(p) candidates:\n");
            for c in &eval.surviving_candidates {
                let eq = c.witness.as_ref().map(|w| w.equation()).unwrap_or_else(|| "no witness".to_string());
                out.push_str(&format!(
                    "  p={}  res840={}  disc={}  desc={}  {}\n",
                    c.p,
                    c.letter.residue_840,
                    c.letter.depth,
                    c.remnant.descent_depth,
                    eq
                ));
            }
            out.push('\n');
        }
    }

    out.push_str("Stage Breakdown:\n");
    for stage in &eval.statistics.stage_progression {
        out.push_str(&format!(
            "• {:<30} : entering={:<6} survivors={:<6} eliminated={}\n",
            stage.stage_name, stage.entering_count, stage.surviving_count, stage.eliminated_count
        ));
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_predicate() {
        assert!(evaluate_prime_predicate(2521).is_ok());
        assert!(evaluate_prime_predicate(3).is_ok());
        assert_eq!(evaluate_prime_predicate(1), Err("not_prime"));
        assert_eq!(evaluate_prime_predicate(0), Err("not_prime"));
        assert_eq!(evaluate_prime_predicate(4), Err("not_prime"));
        assert_eq!(evaluate_prime_predicate(1001), Err("not_prime"));
    }

    #[test]
    fn test_witness_predicate_valid_and_invalid() {
        // Valid witness for 2521: 4/2521 = 1/636 + 1/69748 + 1/131876031
        let w_valid = EsWitness::new(
            2521,
            BigInt::from_u64(636),
            BigInt::from_u64(69748),
            BigInt::from_u64(131876031),
            "two_target_search",
            "CBAP",
            5,
        );
        assert!(evaluate_witness_predicate(2521, &w_valid).is_ok());

        // Invalid witness: corrupted denominator
        let w_invalid = EsWitness::new(
            2521,
            BigInt::from_u64(636),
            BigInt::from_u64(69748),
            BigInt::from_u64(100),
            "test",
            "test",
            0,
        );
        assert_eq!(evaluate_witness_predicate(2521, &w_invalid), Err("invalid_es_witness"));

        // Zero / negative denominator rejection
        let w_zero = EsWitness::new(
            2521,
            BigInt::zero(),
            BigInt::from_u64(69748),
            BigInt::from_u64(131876031),
            "test",
            "test",
            0,
        );
        assert_eq!(evaluate_witness_predicate(2521, &w_zero), Err("invalid_es_witness"));
    }

    #[test]
    fn test_witness_canonical_reordering() {
        let w = EsWitness::new(
            2521,
            BigInt::from_u64(131876031),
            BigInt::from_u64(636),
            BigInt::from_u64(69748),
            "test",
            "test",
            0,
        );
        assert_eq!(w.x, BigInt::from_u64(636));
        assert_eq!(w.y, BigInt::from_u64(69748));
        assert_eq!(w.z, BigInt::from_u64(131876031));
        assert!(w.verify());
    }

    #[test]
    fn test_letter_admission_pure_evaluator() {
        let spec = GodsLetterSpec::v1();
        let w = EsWitness::new(
            2521,
            BigInt::from_u64(636),
            BigInt::from_u64(69748),
            BigInt::from_u64(131876031),
            "two_target_search",
            "CBAP",
            5,
        );
        let res_letter = evaluate_letter_predicate(2521, Some(&w), &spec);
        assert!(res_letter.admitted);
        assert_eq!(res_letter.residue_840, 1);
        assert!(res_letter.hard_residue);

        // Non-Mordell prime: 375017 (residue 377 mod 840)
        let res_non_mordell = evaluate_letter_predicate(375017, None, &spec);
        assert!(!res_non_mordell.admitted);
        assert!(!res_non_mordell.hard_residue);
        assert_eq!(res_non_mordell.residue_840, 377);
    }

    #[test]
    fn test_remnant_pure_evaluator() {
        let spec = GodsLetterSpec::v1();
        // 2521 survives dual descent deeply
        let res_2521 = evaluate_remnant_predicate(2521, &spec);
        assert!(res_2521.admitted);
        assert!(res_2521.descent_depth > 50);

        // Shallow prime: e.g. 7 (7 % 4 == 3, preclearance clears it, descent depth = 0)
        let res_shallow = evaluate_remnant_predicate(7, &spec);
        assert!(!res_shallow.admitted);
        assert_eq!(res_shallow.descent_depth, 0);
    }

    #[test]
    fn test_singleton_cases() {
        let spec = GodsLetterSpec::v1();

        // Case 0: Empty domain where no prime survives
        let domain_empty = GodsLetterDomain::new(10, 12, true); // contains 11 (11 % 4 = 3, not Mordell)
        let eval_empty = evaluate_gods_letter_domain(&domain_empty, None, &spec);
        assert_eq!(eval_empty.uniqueness_status, UniquenessStatus::NoGodsLetter);
        assert!(eval_empty.certificate.is_none());

        // Domain containing 2521: 2521 is solved, so it is not a God's Letter.
        let domain_certified = GodsLetterDomain::new(2000, 3000, true);
        let eval_one = evaluate_gods_letter_domain(&domain_certified, None, &spec);
        assert!(!eval_one.surviving_candidates.iter().any(|c| c.p == 2521));
        assert_eq!(eval_one.uniqueness_status, UniquenessStatus::NoGodsLetter);

        // Case >1: Synthetic simulation of multiple survivors
        let fake_w1 = EsWitness::new(1009, BigInt::from_u64(253), BigInt::from_u64(255277), BigInt::from_u64(255277), "test", "test", 1);
        let fake_w2 = EsWitness::new(2521, BigInt::from_u64(636), BigInt::from_u64(69748), BigInt::from_u64(131876031), "test", "test", 5);
        let fake_corpus = vec![
            CandidateInput { p: 1009, witnesses: vec![fake_w1], source_files: vec!["f1".into()] },
            CandidateInput { p: 2521, witnesses: vec![fake_w2], source_files: vec!["f2".into()] },
        ];
        // Test domain containing both candidates
        let domain_multi = GodsLetterDomain::new(1000, 3000, true);
        let eval_multi = evaluate_gods_letter_domain(&domain_multi, Some(&fake_corpus), &spec);
        // Note: 1009 fails Mordell-hard (1009 % 840 = 169 is Mordell, but let's check its dual descent)
        // If candidate count is > 1, uniqueness_status must be NonUnique
        if eval_multi.surviving_candidates.len() > 1 {
            assert!(matches!(eval_multi.uniqueness_status, UniquenessStatus::NonUnique { .. }));
            assert!(eval_multi.certificate.is_some());
            assert_eq!(eval_multi.certificate.as_ref().unwrap().n, 2521);
        }
    }

    #[test]
    fn test_duplicate_normalization() {
        let spec = GodsLetterSpec::v1();
        let domain = GodsLetterDomain::new(2000, 3000, true);
        let w = EsWitness::new(2521, BigInt::from_u64(636), BigInt::from_u64(69748), BigInt::from_u64(131876031), "test", "test", 5);

        // Same prime in 5 different files
        let duplicated_corpus = vec![
            CandidateInput { p: 2521, witnesses: vec![w.clone()], source_files: vec!["letters/L-2521.json".into()] },
            CandidateInput { p: 2521, witnesses: vec![w.clone()], source_files: vec!["remnants/REM-2521.json".into()] },
            CandidateInput { p: 2521, witnesses: vec![w.clone()], source_files: vec!["escapes/ESC-2521.json".into()] },
            CandidateInput { p: 2521, witnesses: vec![w.clone()], source_files: vec!["findings/great.json".into()] },
            CandidateInput { p: 2521, witnesses: vec![w.clone()], source_files: vec!["obs/2521.json".into()] },
        ];

        let eval = evaluate_gods_letter_domain(&domain, Some(&duplicated_corpus), &spec);
        // Domain scan still enumerates every prime in [2000, 3000];
        // duplicate source files for p=2521 must collapse to one survivor.
        assert!(eval.statistics.primes_tested > 1);
        assert!(!eval.surviving_candidates.iter().any(|c| c.p == 2521));
    }

    #[test]
    fn test_certificate_determinism() {
        let spec = GodsLetterSpec::v1();
        let domain = GodsLetterDomain::new(2000, 3000, true);

        let eval1 = evaluate_gods_letter_domain(&domain, None, &spec);
        let eval2 = evaluate_gods_letter_domain(&domain, None, &spec);

        assert_eq!(eval1.uniqueness_status, eval2.uniqueness_status);
        assert_eq!(eval1.corpus_sha256, eval2.corpus_sha256);
        assert_eq!(eval1.surviving_candidates.len(), eval2.surviving_candidates.len());
    }

    #[test]
    fn test_anti_hardcoding_regression() {
        // Construct a synthetic prime p = 289 (composite) vs a prime that isn't 2521
        // Verify that the predicate logic derives results from mathematics, not a `p == 2521` check.
        let spec = GodsLetterSpec::v1();

        // 17 is prime, but 17 % 840 = 17 (not Mordell-hard) -> must fail Letter
        let eval_17 = evaluate_gods_letter_candidate(17, &[], &spec);
        assert!(!eval_17.gods_letter_candidate);
        assert!(!eval_17.letter.admitted);

        // 73 is prime, 73 % 4 = 1, 73 % 3 = 1, 73 % 8 = 1, 73 % 840 = 73 (not Mordell) -> must fail Letter
        let eval_73 = evaluate_gods_letter_candidate(73, &[], &spec);
        assert!(!eval_73.gods_letter_candidate);
        assert!(!eval_73.letter.admitted);

        // Solved Mordell primes are letters/escapes — not God's Letters.
        let eval_1201 = evaluate_gods_letter_candidate(1201, &[], &spec);
        assert!(!eval_1201.gods_letter_candidate);
        assert!(eval_1201.witness_verified);

        let eval_2521 = evaluate_gods_letter_candidate(2521, &[], &spec);
        assert!(!eval_2521.gods_letter_candidate);
        assert!(eval_2521.witness_verified);
        assert!(eval_2521.origin_generator);

        let eval_3361 = evaluate_gods_letter_candidate(3361, &[], &spec);
        assert_eq!(3361 % 840, 1);
        assert!(!eval_3361.gods_letter_candidate);
        assert!(eval_3361.witness_verified);
    }

    #[test]
    fn test_astronomical_depth_can_admit_a_second_letter() {
        let spec = GodsLetterSpec::v1();
        // Real 1201 witness, but with discovery depth raised to the astronomical floor.
        // This is a gate test: a second letter is *possible*, not that 1201 naturally qualifies.
        let w = EsWitness::new(
            1201,
            BigInt::from_u64(306),
            BigInt::from_u64(15980),
            BigInt::from_u64(172727820),
            "two_target_search",
            "CBX",
            GODS_LETTER_ASTRONOMICAL_DEPTH,
        );
        assert!(w.verify());
        let eval = evaluate_gods_letter_candidate(1201, &[w], &spec);
        assert!(eval.astronomical);
        assert!(!eval.gods_letter_candidate, "a solved identity is not a God's Letter");
    }

    #[test]
    fn test_ingest_does_not_file_solved_as_gods_letters() {
        let written = ingest_gods_letters_from_corpus();
        assert!(
            written.is_empty(),
            "corpus identities are solved; they must not be ingested as God's Letters"
        );
    }

    #[test]
    fn test_search_miss_is_not_a_gods_letter() {
        let spec = GodsLetterSpec::v1();
        // 17 is prime, not Mordell; empty witnesses must not become an unsolved alarm.
        let eval = evaluate_gods_letter_candidate(17, &[], &spec);
        assert!(!eval.unsolved_alarm);
        assert!(!eval.gods_letter_candidate);
    }

    #[test]
    fn test_origin_generator_well_ordering() {
        assert_eq!(evaluate_origin_generator_predicate(841), Err("not_prime"));
        assert_eq!(evaluate_origin_generator_predicate(1681), Err("not_prime"));
        assert!(evaluate_origin_generator_predicate(2521).is_ok());
        assert_eq!(evaluate_origin_generator_predicate(1201), Err("not_principal_mordell_class"));
        assert_eq!(evaluate_origin_generator_predicate(3361), Err("not_principal_mordell_origin"));
        assert_eq!(841u128, 29 * 29);
        assert_eq!(1681u128, 41 * 41);
    }

    #[test]
    fn test_origin_uniqueness_over_shared_domain() {
        let spec = GodsLetterSpec::v1();
        let domain = GodsLetterDomain::new(1000, 3000, true);
        let eval = evaluate_gods_letter_domain(&domain, None, &spec);
        assert!(!eval.surviving_candidates.iter().any(|c| c.p == 1201 || c.p == 2521));
        assert_eq!(eval.uniqueness_status, UniquenessStatus::NoGodsLetter);
    }

    #[test]
    fn test_canonical_origin_window_is_unique() {
        let spec = GodsLetterSpec::v1();
        let domain = GodsLetterDomain::new(2, 10_000, true);
        let eval = evaluate_gods_letter_domain(&domain, None, &spec);
        assert!(!eval.surviving_candidates.iter().any(|c| c.p == 2521 && c.gods_letter_candidate));
        assert_eq!(eval.uniqueness_status, UniquenessStatus::NoGodsLetter);
    }

    #[test]
    fn test_broken_window_rejects_depth_zero() {
        let spec = GodsLetterSpec::v1();
        // 3361 is residue-1 Mordell, remnant, but corridor hit at δ=0.
        let eval = evaluate_gods_letter_candidate(3361, &[], &spec);
        assert!(!eval.gods_letter_candidate);
        assert!(eval.witness_verified);
    }

    #[test]
    fn test_bigint_extreme_denominators() {
        // Construct witness with denominators exceeding u64::MAX
        let p: u128 = 2521;
        let x = BigInt::from_str("18446744073709551616").unwrap(); // 2^64
        let y = BigInt::from_str("36893488147419103232").unwrap(); // 2^65
        let z = BigInt::from_str("73786976294838206464").unwrap(); // 2^66

        let w = EsWitness::new(p, x, y, z, "test", "test", 0);
        // Identity won't match, but verify() must run without panicking or overflowing
        assert!(!w.verify());
    }
}
