// Dual proof/disproof ledger for Erdős–Straus.
// Certificates are exact ℚ only. Approximates never certify.

use super::solver::{CandidateClassification, SolveResult};

/// Dirichlet density of primes hit by even ∪ 4p+3 ∪ 3p+2 ∪ 8p+5.
pub const CLASS_COVER_DENSITY: f64 = 0.875;
/// 6 Mordell-hard classes / φ(840) = 6/192 among primes > 7.
pub const MORDELL_RESIDUAL_DENSITY: f64 = 6.0 / 192.0;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TicketKind {
    ClassProof,
    InstanceProof,
    CertifiedCounterexample,
    IncompleteResidual,
    Invalid,
}

impl TicketKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            TicketKind::ClassProof => "class_proof",
            TicketKind::InstanceProof => "instance_proof",
            TicketKind::CertifiedCounterexample => "certified_counterexample",
            TicketKind::IncompleteResidual => "incomplete_residual",
            TicketKind::Invalid => "invalid",
        }
    }

    pub fn ledger_side(&self) -> &'static str {
        match self {
            TicketKind::ClassProof | TicketKind::InstanceProof => "proof",
            TicketKind::CertifiedCounterexample => "disproof",
            TicketKind::IncompleteResidual | TicketKind::Invalid => "residual",
        }
    }

    pub fn is_major_ticket(&self) -> bool {
        matches!(self, TicketKind::ClassProof | TicketKind::CertifiedCounterexample)
    }
}

pub fn ticket_kind_of(res: &SolveResult) -> TicketKind {
    match res.classification {
        CandidateClassification::InvalidCandidate => TicketKind::Invalid,
        CandidateClassification::TheoremClearance => TicketKind::ClassProof,
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

#[derive(Clone, Debug)]
pub struct DualLedger {
    pub class_proofs: usize,
    pub instance_proofs: usize,
    pub counterexamples: usize,
    pub incomplete_residuals: usize,
    pub covered_density: f64,
    pub residual_density: f64,
    pub game_status: String,
}

impl DualLedger {
    pub fn from_counts(
        class_proofs: usize,
        instance_proofs: usize,
        counterexamples: usize,
        incomplete_residuals: usize,
    ) -> Self {
        let game_status = if counterexamples > 0 {
            "DISPROVED".to_string()
        } else {
            "OPEN".to_string()
        };
        DualLedger {
            class_proofs,
            instance_proofs,
            counterexamples,
            incomplete_residuals,
            covered_density: CLASS_COVER_DENSITY,
            residual_density: MORDELL_RESIDUAL_DENSITY,
            game_status,
        }
    }

    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "class_proofs": self.class_proofs,
            "instance_proofs": self.instance_proofs,
            "counterexamples": self.counterexamples,
            "incomplete_residuals": self.incomplete_residuals,
            "covered_density": self.covered_density,
            "residual_density": self.residual_density,
            "game_status": self.game_status,
            "approximates_certify": false,
            "weighing": if self.counterexamples > 0 {
                "One certified counterexample outweighs every instance proof."
            } else {
                "Class cover 7/8 (Dirichlet). Residual is the six Mordell classes (1/32). Instance piles do not prove ES. Zero counterexamples. Game OPEN."
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
    fn class_proof_for_linear_sieve() {
        let res = solve_es_with_config(7, 10, "auto");
        assert!(res.solved);
        assert_eq!(ticket_kind_of(&res), TicketKind::ClassProof);
        assert_eq!(ticket_kind_of(&res).ledger_side(), "proof");
        assert!(ticket_kind_of(&res).is_major_ticket());
    }

    #[test]
    fn instance_or_class_for_mordell_origin() {
        let res = solve_es_with_config(2521, 10, "auto");
        assert!(res.solved);
        let kind = ticket_kind_of(&res);
        assert_ne!(kind, TicketKind::CertifiedCounterexample);
        assert_ne!(kind, TicketKind::IncompleteResidual);
    }

    #[test]
    fn weighing_zero_counterexamples_is_open() {
        let ledger = DualLedger::from_counts(100, 20, 0, 1);
        assert_eq!(ledger.game_status, "OPEN");
        assert_eq!(ledger.covered_density, CLASS_COVER_DENSITY);
        let ledger2 = DualLedger::from_counts(100, 20, 1, 0);
        assert_eq!(ledger2.game_status, "DISPROVED");
    }
}
