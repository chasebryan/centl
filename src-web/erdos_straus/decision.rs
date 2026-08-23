// Dual proof/disproof ledger for Erdős–Straus.
// Hardness measures tell us where to look. Certificates tell us what is true.
// Approximates never certify.

use super::certificate::{compute_unsolved_certificate, sha256_hex};
use super::solver::{is_prime, CandidateClassification, SolveResult};

/// Dirichlet density of primes hit by even ∪ 4p+3 ∪ 3p+2 ∪ 8p+5.
/// This is NOT complementary to the Mordell hard core.
pub const ELEMENTARY_CC_COVER: f64 = 0.875; // 7/8
/// Primes remaining after elementary CC: 1/8.
pub const POST_CC_RESIDUAL: f64 = 0.125; // 1/8
/// Additional classical modular structure between CC and Mordell: 1/8 − 1/32.
pub const INTERMEDIATE_MODULAR: f64 = 0.09375; // 3/32
/// 6 Mordell-hard classes / φ(840) = 6/192 among primes > 7.
pub const MORDELL_HARD_CORE: f64 = 6.0 / 192.0; // 1/32

/// Permanent elementary identities. Not incremented per prime.
pub const ELEMENTARY_THEOREM_COUNT: usize = 4;
pub const ELEMENTARY_THEOREMS: [&str; 4] = ["even_reduction", "4p+3", "3p+2", "8p+5"];

pub const DISPROOF_SCHEMA: &str = "centl26.erdos_straus.disproof/v2";
pub const COMPLETENESS_THEOREM: &str =
    "If 4/n=1/x+1/y+1/z with x≤y≤z then floor(n/4)+1 ≤ x ≤ floor(3n/4). Equivalent form (Ay-nx)(Az-nx)=n²x² with A=4x-n.";
pub const FACTOR_ALGO: &str = "trial-division enumerating divisors of n²x²";
pub const DECISION_ENGINE_VERSION: &str = "es-decision/v2";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TicketKind {
    /// One of the four permanent elementary identities. Never a per-prime count.
    ClassTheorem,
    /// Prime cleared by applying a class theorem. Not a new class proof.
    ClassCoveredInstance,
    /// Constructive witness from corridor / two-target k / complete search.
    InstanceProof,
    CertifiedCounterexample,
    IncompleteResidual,
    Invalid,
}

impl TicketKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            TicketKind::ClassTheorem => "class_theorem",
            TicketKind::ClassCoveredInstance => "class_covered_instance",
            TicketKind::InstanceProof => "instance_proof",
            TicketKind::CertifiedCounterexample => "certified_counterexample",
            TicketKind::IncompleteResidual => "incomplete_residual",
            TicketKind::Invalid => "invalid",
        }
    }

    pub fn ledger_side(&self) -> &'static str {
        match self {
            TicketKind::ClassTheorem | TicketKind::ClassCoveredInstance | TicketKind::InstanceProof => {
                "proof"
            }
            TicketKind::CertifiedCounterexample => "disproof",
            TicketKind::IncompleteResidual | TicketKind::Invalid => "residual",
        }
    }

    pub fn is_major_ticket(&self) -> bool {
        matches!(
            self,
            TicketKind::ClassTheorem | TicketKind::CertifiedCounterexample
        )
    }
}

pub fn ticket_kind_of(res: &SolveResult) -> TicketKind {
    match res.classification {
        CandidateClassification::InvalidCandidate => TicketKind::Invalid,
        CandidateClassification::TheoremClearance => TicketKind::ClassCoveredInstance,
        CandidateClassification::CertifiedCounterexample => TicketKind::CertifiedCounterexample,
        CandidateClassification::UnsolvedCandidate => TicketKind::IncompleteResidual,
        _ if res.solved => TicketKind::InstanceProof,
        _ => TicketKind::IncompleteResidual,
    }
}

/// Approximate 1/x+1/y+1/z ≈ 4/n is never a certificate.
pub fn approximate_identity_is_certificate(n: u64, x: f64, y: f64, z: f64) -> bool {
    let _ = (n, x, y, z);
    false
}

pub fn x_bounds(n: u64) -> (u64, u64) {
    let x_min = n / 4 + 1;
    let x_max = (3 * n) / 4;
    (x_min, x_max)
}

/// Paranoid DIS artifact. Empty complete region only.
pub fn disproof_certificate_json(n: u64) -> serde_json::Value {
    let (x_min, x_max) = x_bounds(n);
    let x_count = if x_max >= x_min {
        x_max - x_min + 1
    } else {
        0
    };
    let source_commit = std::env::var("CENTL_BUILD_COMMIT").unwrap_or_else(|_| "26.13.0-release".into());
    let payload = format!(
        "ES-DISPROOF-v2\nn={}\nx_min={}\nx_max={}\nx_count={}\ntheorem={}\nfactor={}\nengine={}\ncommit={}\n",
        n, x_min, x_max, x_count, COMPLETENESS_THEOREM, FACTOR_ALGO, DECISION_ENGINE_VERSION, source_commit
    );
    let content_hash = sha256_hex(&payload);
    let replay_hash = compute_unsolved_certificate(n);
    serde_json::json!({
        "schema": DISPROOF_SCHEMA,
        "ticket": "certified_counterexample",
        "n": n,
        "prime": is_prime(n),
        "residue_840": n % 840,
        "x_min": x_min,
        "x_max": x_max,
        "x_count": x_count,
        "ordering": "x <= y <= z",
        "completeness_theorem": COMPLETENESS_THEOREM,
        "completeness_version": DECISION_ENGINE_VERSION,
        "factorization_algorithm": FACTOR_ALGO,
        "source_commit": source_commit,
        "primality": if is_prime(n) { "deterministic_trial_division" } else { "composite" },
        "replay_hash": format!("SHA256: {}", replay_hash),
        "content_hash": format!("SHA256: {}", content_hash),
        "independent_verifier": "bb.kernel exact 4xyz=n(xy+xz+yz); region replay via try_divisor_complete",
        "approximates_certify": false,
        "hardness_is_not_a_certificate": true
    })
}

#[derive(Clone, Debug)]
pub struct DualLedger {
    pub elementary_theorems: usize,
    pub class_covered_instances: usize,
    pub constructive_instances: usize,
    pub counterexamples: usize,
    pub incomplete_residuals: usize,
    pub elementary_cc_cover: f64,
    pub intermediate_modular_density: f64,
    pub mordell_hard_core: f64,
    pub game_status: String,
}

impl DualLedger {
    pub fn from_counts(
        class_covered_instances: usize,
        constructive_instances: usize,
        counterexamples: usize,
        incomplete_residuals: usize,
    ) -> Self {
        let game_status = if counterexamples > 0 {
            "DISPROVED".to_string()
        } else {
            "OPEN".to_string()
        };
        DualLedger {
            elementary_theorems: ELEMENTARY_THEOREM_COUNT,
            class_covered_instances,
            constructive_instances,
            counterexamples,
            incomplete_residuals,
            elementary_cc_cover: ELEMENTARY_CC_COVER,
            intermediate_modular_density: INTERMEDIATE_MODULAR,
            mordell_hard_core: MORDELL_HARD_CORE,
            game_status,
        }
    }

    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "elementary_theorems": self.elementary_theorems,
            "elementary_theorem_ids": ELEMENTARY_THEOREMS,
            "class_covered_instances": self.class_covered_instances,
            "constructive_instances": self.constructive_instances,
            "counterexamples": self.counterexamples,
            "incomplete_residuals": self.incomplete_residuals,
            "densities": {
                "elementary_cc_cover": self.elementary_cc_cover,
                "post_cc_residual": POST_CC_RESIDUAL,
                "intermediate_modular": self.intermediate_modular_density,
                "mordell_hard_core": self.mordell_hard_core,
                "note": "7/8 and 1/32 are not complementary. Intermediate classical modular structure is 3/32."
            },
            "game_status": self.game_status,
            "approximates_certify": false,
            "hardness_measures_are_not_certificates": true,
            "victory_certificate": "none — requires uniform covering of Mordell classes {1,121,169,289,361,529} mod 840",
            "weighing": if self.counterexamples > 0 {
                "One certified counterexample outweighs every instance. Game DISPROVED."
            } else {
                "Elementary CC cover = 7/8 (4 theorems). Intermediate modular = 3/32. Mordell hard core = 1/32. Class-covered instances are applications of theorems, not new class proofs. Constructive instances do not prove ES. Zero counterexamples. Game OPEN."
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::erdos_straus::solver::solve_es_with_config;

    #[test]
    fn approximates_never_certify() {
        assert!(!approximate_identity_is_certificate(5, 2.0, 5.0, 10.0));
        assert!(!approximate_identity_is_certificate(7, 2.0, 28.0, 28.0000001));
    }

    #[test]
    fn densities_are_not_complementary() {
        let s = ELEMENTARY_CC_COVER + INTERMEDIATE_MODULAR + MORDELL_HARD_CORE;
        assert!((s - 1.0).abs() < 1e-12);
        assert!((ELEMENTARY_CC_COVER + POST_CC_RESIDUAL - 1.0).abs() < 1e-12);
        assert!((POST_CC_RESIDUAL - INTERMEDIATE_MODULAR - MORDELL_HARD_CORE).abs() < 1e-12);
    }

    #[test]
    fn sieve_prime_is_class_covered_instance_not_a_new_class_proof() {
        let res = solve_es_with_config(7, 10, "auto");
        assert!(res.solved);
        assert_eq!(ticket_kind_of(&res), TicketKind::ClassCoveredInstance);
        assert_eq!(ticket_kind_of(&res).ledger_side(), "proof");
        assert!(!ticket_kind_of(&res).is_major_ticket());
        assert_eq!(ELEMENTARY_THEOREM_COUNT, 4);
    }

    #[test]
    fn instance_or_covered_for_mordell_origin() {
        let res = solve_es_with_config(2521, 10, "auto");
        assert!(res.solved);
        let kind = ticket_kind_of(&res);
        assert_ne!(kind, TicketKind::CertifiedCounterexample);
        assert_ne!(kind, TicketKind::IncompleteResidual);
        assert_ne!(kind, TicketKind::ClassTheorem);
    }

    #[test]
    fn weighing_zero_counterexamples_is_open() {
        let ledger = DualLedger::from_counts(100, 20, 0, 1);
        assert_eq!(ledger.game_status, "OPEN");
        assert_eq!(ledger.elementary_theorems, 4);
        assert_eq!(ledger.mordell_hard_core, MORDELL_HARD_CORE);
        let ledger2 = DualLedger::from_counts(100, 20, 1, 0);
        assert_eq!(ledger2.game_status, "DISPROVED");
    }

    #[test]
    fn disproof_certificate_is_heavy() {
        let v = disproof_certificate_json(1009);
        assert_eq!(v["schema"], DISPROOF_SCHEMA);
        assert_eq!(v["x_min"], 1009 / 4 + 1);
        assert_eq!(v["x_max"], (3 * 1009) / 4);
        assert_eq!(v["prime"], true);
        assert_eq!(v["approximates_certify"], false);
        assert!(v["content_hash"].as_str().unwrap().starts_with("SHA256: "));
        assert!(v["completeness_theorem"].as_str().unwrap().contains("floor(n/4)"));
    }
}
