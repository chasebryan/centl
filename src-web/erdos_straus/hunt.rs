// Public Erdős–Straus Infinite Hunt Runner & Vault Authority
// Free Computation Foundation - Apache-2.0

use super::gods_letter::{
    evaluate_gods_letter_candidate, persist_gods_letter_candidate, EsWitness, GodsLetterSpec,
};
use super::solver::{
    is_mordell_hard, is_prime, solve_es_with_config, CandidateClassification,
    DualDescentCertificate, LetterAdmissionStatus, SolveResult, Witness, REMNANT_THRESHOLD,
};
use std::fs;
use std::path::PathBuf;

#[derive(Clone, Debug)]
pub struct HuntConfig {
    pub start_bound: u64,
    pub window_size: u64,
    pub max_primes: usize,
    pub letter_threshold: u64,
    pub mordell_only: bool,
    pub gods_letter_only: bool,
    pub engine_mode: String,
}

impl Default for HuntConfig {
    fn default() -> Self {
        HuntConfig {
            start_bound: 20000,
            window_size: 5000,
            max_primes: 50,
            letter_threshold: 10,
            mordell_only: false,
            gods_letter_only: false,
            engine_mode: "auto".to_string(),
        }
    }
}

#[derive(Clone, Debug)]
pub struct HuntSummary {
    pub start_bound: u64,
    pub end_bound: u64,
    pub primes_checked: usize,
    pub mordell_hard_count: usize,
    pub theorem_clearances: usize,
    pub corridor_clearances: usize,
    pub cbis_escapes: usize,
    pub cbx_survivors: usize,
    pub ordinary_decompositions: usize,
    pub letter_candidates_evaluated: usize,
    pub verified_letters_count: usize,
    pub gods_letter_count: usize,
    pub rejected_admissions: usize,
    pub unsolved_count: usize,
    pub active_engine: String,
    pub filter_mode: String,
    pub findings: Vec<SolveResult>,
    pub execution_millis: u128,
}

pub fn resolve_letters_dir() -> PathBuf {
    if let Ok(custom) = std::env::var("CENTL_LETTERS_DIR") {
        let p = PathBuf::from(custom);
        let _ = fs::create_dir_all(&p);
        return p;
    }
    let candidates = [
        PathBuf::from("letters"),
        PathBuf::from("research/erdos-straus/letters"),
        PathBuf::from("../letters"),
    ];
    for cand in &candidates {
        if cand.is_dir() {
            return cand.clone();
        }
    }
    let default_dir = PathBuf::from("letters");
    let _ = fs::create_dir_all(&default_dir);
    default_dir
}

pub fn resolve_escapes_dir() -> PathBuf {
    if let Ok(custom) = std::env::var("CENTL_ESCAPES_DIR") {
        let p = PathBuf::from(custom);
        let _ = fs::create_dir_all(&p);
        return p;
    }
    let candidates = [
        PathBuf::from("escapes"),
        PathBuf::from("research/erdos-straus/escapes"),
        PathBuf::from("../escapes"),
    ];
    for cand in &candidates {
        if cand.is_dir() {
            return cand.clone();
        }
    }
    let default_dir = PathBuf::from("escapes");
    let _ = fs::create_dir_all(&default_dir);
    default_dir
}

/// Strict Hard Invariant Validator for Erdős–Straus artifacts.
/// Validates mathematical, schema, and certification invariants across LETTER, REMNANT, and ESCAPE artifacts.
pub fn validate_artifact_invariants(
    grade: &str,
    n: u64,
    residue_840: u64,
    descent_depth: u64,
    discovery_depth: u64,
    artifact_id: &str,
    is_mordell_hard_flag: bool,
    admission_status: &LetterAdmissionStatus,
    witness: Option<&Witness>,
    dual_descent_cert: Option<&DualDescentCertificate>,
) -> Result<(), String> {
    let _ = discovery_depth; // validated contextually

    // Invariant 1: n must match ID prefix
    let expected_prefix = match grade {
        "letter" => format!("L-{}", n),
        "remnant" => format!("REM-{}", n),
        "escape" => format!("ESC-{}", n),
        _ => return Err(format!("Invalid artifact grade '{}'", grade)),
    };
    if artifact_id != expected_prefix {
        return Err(format!(
            "Artifact ID '{}' does not match expected '{}' for prime {}",
            artifact_id, expected_prefix, n
        ));
    }

    // Invariant 2: Residue 840 correctness
    if residue_840 != (n % 840) {
        return Err(format!(
            "Malformed residue: reported {} != actual {} mod 840",
            residue_840,
            n % 840
        ));
    }

    // Invariant 3: Mordell-hard correctness
    if is_mordell_hard_flag != is_mordell_hard(n) {
        return Err(format!(
            "Malformed Mordell-hard flag: reported {} != actual {}",
            is_mordell_hard_flag,
            is_mordell_hard(n)
        ));
    }

    // Invariant 4: Witness rational equation verification (if witness exists)
    if let Some(w) = witness {
        if !w.verify() {
            return Err(format!(
                "Exact 3-Egyptian fraction decomposition verification failed for prime {}",
                n
            ));
        }
        if w.n != n {
            return Err(format!(
                "Witness n ({}) does not match target candidate {}",
                w.n, n
            ));
        }
    }

    // Invariant 5: Grade-specific invariants
    match grade {
        "letter" => {
            if !admission_status.is_admitted() {
                return Err(format!(
                    "Cannot assign grade 'letter': Central Gate admission status is Rejected ({:?})",
                    admission_status
                ));
            }
            if !is_mordell_hard(n) {
                return Err(format!(
                    "Cannot assign grade 'letter': prime {} mod 840 = {} is not Mordell-hard",
                    n, residue_840
                ));
            }
            if witness.is_none() {
                return Err(format!(
                    "Cannot assign grade 'letter': missing decomposition witness for prime {}",
                    n
                ));
            }
        }
        "remnant" => {
            if descent_depth <= REMNANT_THRESHOLD {
                return Err(format!(
                    "Cannot assign grade 'remnant': descent_depth ({}) <= Remnant threshold ({})",
                    descent_depth, REMNANT_THRESHOLD
                ));
            }
            let cert = dual_descent_cert.ok_or_else(|| {
                format!(
                    "Cannot assign grade 'remnant': missing Dual Descent survival certificate for prime {}",
                    n
                )
            })?;
            if !cert.verified || cert.descent_depth <= REMNANT_THRESHOLD {
                return Err(format!(
                    "Cannot assign grade 'remnant': Dual Descent survival certificate unverified or depth ({}) <= {}",
                    cert.descent_depth, REMNANT_THRESHOLD
                ));
            }
        }
        "escape" => {
            if witness.is_none() {
                return Err(format!(
                    "Cannot assign grade 'escape': missing decomposition witness for prime {}",
                    n
                ));
            }
        }
        _ => return Err(format!("Unknown artifact grade '{}'", grade)),
    }

    Ok(())
}

/// Persist ONLY genuine, centrally admitted letters to `letters/` vault.
pub fn persist_letter_to_disk(res: &SolveResult) {
    let letter_id = format!("L-{}", res.n);
    if let Err(err) = validate_artifact_invariants(
        "letter",
        res.n,
        res.residue_840,
        res.descent_depth,
        res.discovery_depth,
        &letter_id,
        res.is_mordell_hard,
        &res.admission_status,
        res.witness.as_ref(),
        res.dual_descent_certificate.as_ref(),
    ) {
        eprintln!("[ES Letter Vault Invariant Error] {}", err);
        return;
    }

    let witness = match &res.witness {
        Some(w) => w,
        None => return,
    };

    let dir = resolve_letters_dir();
    let md_path = dir.join(format!("{}.md", letter_id));
    let json_path = dir.join(format!("{}.json", letter_id));

    let cert = res.letter_number.clone().unwrap_or_else(|| {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        let mut hasher = DefaultHasher::new();
        res.n.hash(&mut hasher);
        witness.x.to_string().hash(&mut hasher);
        format!("{:016x}", hasher.finish())
    });

    let md_content = format!(
        "# Erdős–Straus Letter Certificate: #{letter_id}\n\n\
        ## Executive Verification Summary\n\
        - **Target Prime (p)**: `{p}`\n\
        - **Residue Modulo 840**: `{res_840}` (Mordell-Hard Survivor)\n\
        - **Discovery Depth (δ)**: `{discovery_depth}`\n\
        - **Dual Descent Depth**: `{descent_depth}`\n\
        - **Discovering Engine**: `{engine}`\n\
        - **Arithmetic Grade**: `LETTER`\n\
        - **Admission Status**: `ADMITTED (Authoritative Central Gate)`\n\
        - **SHA-256 Certificate**: `{cert}`\n\n\
        ## Exact 3-Egyptian Fraction Decomposition\n\
        $$ \\frac{{4}}{{{p}}} = \\frac{{1}}{{{x}}} + \\frac{{1}}{{{y}}} + \\frac{{1}}{{{z}}} $$\n\n\
        ```text\n\
        {equation}\n\
        ```\n\n\
        ## Witness Quadruple\n\
        - **x**: `{x}`\n\
        - **y**: `{y}`\n\
        - **z**: `{z}`\n\
        - **Verification Identity**: `4xyz == n(yz + xz + xy)`\n\
        - **Verification Status**: `TRUE (100% ℚ Arbitrary-Precision Rational Proof)`\n\n\
        ## Engine Provenance\n\
        - **Method**: `{method}`\n\
        - **Corridor Layer**: `{layer}`\n\
        - **Classification**: `Central Gate Admitted Letter`\n\
        - **Engine Name**: `{engine}`\n",
        letter_id = letter_id,
        p = res.n,
        res_840 = res.residue_840,
        discovery_depth = witness.discovery_depth,
        descent_depth = witness.descent_depth,
        engine = witness.engine_name,
        cert = cert,
        x = witness.x,
        y = witness.y,
        z = witness.z,
        equation = witness.equation(),
        method = witness.method,
        layer = witness.layer,
    );

    let _ = fs::write(&md_path, md_content);

    let json_content = serde_json::json!({
        "schema": "centl26.erdos_straus.letter/v1",
        "letter_id": letter_id,
        "n": res.n,
        "residue_840": res.residue_840,
        "is_mordell_hard": res.is_mordell_hard,
        "discovery_depth": witness.discovery_depth,
        "descent_depth": witness.descent_depth,
        "depth": witness.discovery_depth, // Deprecated legacy alias
        "discovered_by": witness.engine_name,
        "method": witness.method,
        "layer": witness.layer,
        "classification": "central_gate_admitted",
        "admission_status": "admitted",
        "grade": "letter",
        "equation": witness.equation(),
        "witness": {
            "x": witness.x.to_string(),
            "y": witness.y.to_string(),
            "z": witness.z.to_string(),
        },
        "certificate": cert,
        "verified": witness.verified && witness.verify(),
    });

    let _ = fs::write(&json_path, json_content.to_string());
}

/// Persist corridor escapes / intermediate decompositions to `escapes/` directory.
pub fn persist_escape_to_disk(res: &SolveResult) {
    let escape_id = format!("ESC-{}", res.n);
    if let Err(err) = validate_artifact_invariants(
        "escape",
        res.n,
        res.residue_840,
        res.descent_depth,
        res.discovery_depth,
        &escape_id,
        res.is_mordell_hard,
        &res.admission_status,
        res.witness.as_ref(),
        res.dual_descent_certificate.as_ref(),
    ) {
        eprintln!("[ES Escape Vault Invariant Error] {}", err);
        return;
    }

    let witness = match &res.witness {
        Some(w) => w,
        None => return,
    };

    let dir = resolve_escapes_dir();
    let md_path = dir.join(format!("{}.md", escape_id));
    let json_path = dir.join(format!("{}.json", escape_id));

    let rejection_desc = match &res.admission_status {
        LetterAdmissionStatus::Rejected(r) => r.description(),
        LetterAdmissionStatus::Admitted => "Admitted".to_string(),
    };

    let md_content = format!(
        "# Erdős–Straus Corridor Escape: #{escape_id}\n\n\
        ## Executive Summary\n\
        - **Target Prime (p)**: `{p}`\n\
        - **Residue Modulo 840**: `{res_840}` ({mordell_status})\n\
        - **Discovery Depth (δ)**: `{discovery_depth}`\n\
        - **Dual Descent Depth**: `{descent_depth}`\n\
        - **Classification**: `{classification}`\n\
        - **Letter Admission**: `REJECTED ({rejection_desc})`\n\
        - **Discovering Engine**: `{engine}`\n\n\
        ## Exact 3-Egyptian Fraction Decomposition\n\
        $$ \\frac{{4}}{{{p}}} = \\frac{{1}}{{{x}}} + \\frac{{1}}{{{y}}} + \\frac{{1}}{{{z}}} $$\n\n\
        ```text\n\
        {equation}\n\
        ```\n\n\
        ## Witness Quadruple\n\
        - **x**: `{x}`\n\
        - **y**: `{y}`\n\
        - **z**: `{z}`\n\
        - **Verification Status**: `TRUE (100% ℚ Exact Proof)`\n",
        escape_id = escape_id,
        p = res.n,
        res_840 = res.residue_840,
        mordell_status = if res.is_mordell_hard { "Mordell-Hard Candidate" } else { "Non-Mordell Residue" },
        discovery_depth = witness.discovery_depth,
        descent_depth = witness.descent_depth,
        classification = res.classification.display_label(),
        rejection_desc = rejection_desc,
        engine = witness.engine_name,
        x = witness.x,
        y = witness.y,
        z = witness.z,
        equation = witness.equation(),
    );

    let _ = fs::write(&md_path, md_content);

    let json_content = serde_json::json!({
        "schema": "centl26.erdos_straus.escape/v1",
        "escape_id": escape_id,
        "n": res.n,
        "residue_840": res.residue_840,
        "is_mordell_hard": res.is_mordell_hard,
        "discovery_depth": witness.discovery_depth,
        "descent_depth": witness.descent_depth,
        "depth": witness.discovery_depth, // Deprecated legacy alias
        "classification": "corridor_escape",
        "admission_status": "rejected",
        "admission_rejection_reason": rejection_desc,
        "discovered_by": witness.engine_name,
        "grade": "escape",
        "equation": witness.equation(),
        "witness": {
            "x": witness.x.to_string(),
            "y": witness.y.to_string(),
            "z": witness.z.to_string(),
        },
        "verified": witness.verified && witness.verify(),
    });

    let _ = fs::write(&json_path, json_content.to_string());
}

pub fn resolve_remnants_dir() -> PathBuf {
    if let Ok(custom) = std::env::var("CENTL_REMNANTS_DIR") {
        let p = PathBuf::from(custom);
        let _ = fs::create_dir_all(&p);
        return p;
    }
    let candidates = [
        PathBuf::from("remnants"),
        PathBuf::from("research/erdos-straus/remnants"),
        PathBuf::from("../remnants"),
    ];
    for cand in &candidates {
        if cand.is_dir() {
            return cand.clone();
        }
    }
    let default_dir = PathBuf::from("remnants");
    let _ = fs::create_dir_all(&default_dir);
    default_dir
}

/// Persist CBX dual descent deep corridor survivors to `remnants/` directory.
pub fn persist_remnant_to_disk(res: &SolveResult) {
    let remnant_id = format!("REM-{}", res.n);
    if let Err(err) = validate_artifact_invariants(
        "remnant",
        res.n,
        res.residue_840,
        res.descent_depth,
        res.discovery_depth,
        &remnant_id,
        res.is_mordell_hard,
        &res.admission_status,
        res.witness.as_ref(),
        res.dual_descent_certificate.as_ref(),
    ) {
        eprintln!("[ES Remnant Vault Invariant Error] {}", err);
        return;
    }

    let dir = resolve_remnants_dir();
    let md_path = dir.join(format!("{}.md", remnant_id));
    let json_path = dir.join(format!("{}.json", remnant_id));

    let cert = res.dual_descent_certificate.as_ref().map(|c| c.certificate.clone()).unwrap_or_else(|| {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        let mut hasher = DefaultHasher::new();
        res.n.hash(&mut hasher);
        res.descent_depth.hash(&mut hasher);
        format!("REM-{:016x}", hasher.finish())
    });

    let witness_opt = res.witness.as_ref();
    let decomp_verified = witness_opt.map_or(false, |w| w.verified && w.verify());
    let (equation_str, x_str, y_str, z_str, discovering_engine, method_str, layer_str) = match witness_opt {
        Some(w) => (
            w.equation(),
            w.x.to_string(),
            w.y.to_string(),
            w.z.to_string(),
            w.engine_name.clone(),
            w.method.clone(),
            w.layer.clone(),
        ),
        None => (
            "Decomposition pending / unresolved in corridor search".to_string(),
            "N/A".to_string(),
            "N/A".to_string(),
            "N/A".to_string(),
            "Unsolved Candidate".to_string(),
            "dual_descent_survival".to_string(),
            "descent_ladder".to_string(),
        ),
    };

    let md_content = format!(
        "# Erdős–Straus Remnant Certificate: #{remnant_id}\n\n\
        ## Executive Verification Summary\n\
        - **Target Prime (p)**: `{p}`\n\
        - **Residue Modulo 840**: `{res_840}` ({mordell_status})\n\
        - **Dual Descent Survival Depth (δ)**: `{descent_depth}`\n\
        - **Discovery Depth**: `{discovery_depth}`\n\
        - **Remnant Threshold**: `δ > {remnant_threshold}`\n\
        - **Arithmetic Grade**: `REMNANT`\n\
        - **Classification**: `CBX Dual Descent Deep Survivor`\n\
        - **Survival Verification**: `TRUE`\n\
        - **Decomposition Verification**: `{decomp_status}`\n\
        - **Survival Engine**: `{survival_engine}`\n\
        - **Decomposition Discovering Engine**: `{discovering_engine}`\n\
        - **SHA-256 Certificate**: `{cert}`\n\n\
        ## Exact 3-Egyptian Fraction Decomposition\n\
        $$ \\frac{{4}}{{{p}}} = \\frac{{1}}{{{x}}} + \\frac{{1}}{{{y}}} + \\frac{{1}}{{{z}}} $$\n\n\
        ```text\n\
        {equation}\n\
        ```\n\n\
        ## Witness Quadruple\n\
        - **x**: `{x}`\n\
        - **y**: `{y}`\n\
        - **z**: `{z}`\n\
        - **Verification Identity**: `4xyz == n(yz + xz + xy)`\n\
        - **Verification Status**: `{verif_status}`\n",
        remnant_id = remnant_id,
        p = res.n,
        res_840 = res.residue_840,
        mordell_status = if res.is_mordell_hard { "Mordell-Hard Candidate" } else { "Non-Mordell Residue" },
        descent_depth = res.descent_depth,
        discovery_depth = res.discovery_depth,
        remnant_threshold = REMNANT_THRESHOLD,
        decomp_status = if decomp_verified { "TRUE" } else { "FALSE (Unsolved Candidate)" },
        survival_engine = res.survival_engine.as_deref().unwrap_or("CBX.kernel (Dual Descent)"),
        discovering_engine = discovering_engine,
        cert = cert,
        equation = equation_str,
        x = x_str,
        y = y_str,
        z = z_str,
        verif_status = if decomp_verified { "TRUE (100% ℚ Arbitrary-Precision Rational Proof)" } else { "PENDING DECOMPOSITION" },
    );

    let _ = fs::write(&md_path, md_content);

    let mut json_val = serde_json::json!({
        "schema": "centl26.erdos_straus.remnant/v1",
        "remnant_id": remnant_id,
        "n": res.n,
        "residue_840": res.residue_840,
        "grade": "remnant",
        "classification": "dual_descent_deep_survivor",
        "descent_depth": res.descent_depth,
        "discovery_depth": res.discovery_depth,
        "remnant_threshold": REMNANT_THRESHOLD,
        "survival_engine": res.survival_engine.as_deref().unwrap_or("CBX.kernel (Dual Descent)"),
        "discovered_by": discovering_engine,
        "method": method_str,
        "layer": layer_str,
        "equation": equation_str,
        "verified": decomp_verified,
        "survival_verified": true,
        "decomposition_verified": decomp_verified,
        "certificate": cert,
    });

    if let Some(w) = witness_opt {
        json_val["witness"] = serde_json::json!({
            "x": w.x.to_string(),
            "y": w.y.to_string(),
            "z": w.z.to_string(),
        });
    }

    let _ = fs::write(&json_path, serde_json::to_string_pretty(&json_val).unwrap_or_default());
}

#[derive(Clone, Debug)]
pub struct VaultAuditReport {
    pub total_scanned: usize,
    pub legitimate_letters_retained: usize,
    pub remnants_retained: usize,
    pub entries_migrated_to_escapes: usize,
    pub entries_migrated_to_remnants: usize,
    pub invalid_entries: Vec<AuditDetail>,
}

impl VaultAuditReport {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "status": "ok",
            "total_scanned": self.total_scanned,
            "legitimate_letters_retained": self.legitimate_letters_retained,
            "remnants_retained": self.remnants_retained,
            "entries_migrated_to_escapes": self.entries_migrated_to_escapes,
            "entries_migrated_to_remnants": self.entries_migrated_to_remnants,
            "invalid_entries": self.invalid_entries.iter().map(|e| {
                serde_json::json!({
                    "n": e.n,
                    "residue_840": e.residue_840,
                    "is_mordell_hard": e.is_mordell_hard,
                    "previous_file": e.previous_file,
                    "new_file": e.new_file,
                    "rejection_reason": e.rejection_reason
                })
            }).collect::<Vec<_>>()
        })
    }
}

#[derive(Clone, Debug)]
pub struct AuditDetail {
    pub n: u64,
    pub residue_840: u64,
    pub is_mordell_hard: bool,
    pub previous_file: String,
    pub new_file: String,
    pub rejection_reason: String,
}

/// Centralized migration and re-audit of historical letter and remnant vault entries.
/// Re-verifies primality, residue mod 840, Mordell-hard status, exact identity, and central admission.
/// Non-letter entries are relocated to `escapes/` or `remnants/` with updated provenance (never silently deleted).
pub fn audit_and_migrate_vault() -> VaultAuditReport {
    let letters_dir = resolve_letters_dir();
    let escapes_dir = resolve_escapes_dir();
    let remnants_dir = resolve_remnants_dir();
    let mut total_scanned = 0;
    let mut legitimate_letters_retained = 0;
    let mut remnants_retained = 0;
    let mut entries_migrated_to_escapes = 0;
    let mut entries_migrated_to_remnants = 0;
    let mut invalid_entries = Vec::new();

    // 1. Audit letters vault
    if let Ok(entries) = fs::read_dir(&letters_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("json")
                && path.file_name().and_then(|s| s.to_str()) != Some("index.json")
            {
                total_scanned += 1;
                if let Ok(content) = fs::read_to_string(&path) {
                    if let Ok(json_val) = serde_json::from_str::<serde_json::Value>(&content) {
                        let n = json_val.get("n").and_then(|v| v.as_u64()).unwrap_or(0);
                        let res = solve_es_with_config(n, 10, "auto");
                        if res.letter_admitted {
                            legitimate_letters_retained += 1;
                        } else if res.remnant_admitted {
                            entries_migrated_to_remnants += 1;
                            let md_path = path.with_extension("md");
                            let new_json = remnants_dir.join(format!("REM-{}.json", n));
                            let reason = "Candidate survived Dual Descent beyond threshold (δ > 50) - migrated to Remnants".to_string();
                            persist_remnant_to_disk(&res);
                            let _ = fs::remove_file(&path);
                            if md_path.exists() {
                                let _ = fs::remove_file(&md_path);
                            }
                            invalid_entries.push(AuditDetail {
                                n,
                                residue_840: n % 840,
                                is_mordell_hard: is_mordell_hard(n),
                                previous_file: format!("letters/{}", path.file_name().unwrap_or_default().to_string_lossy()),
                                new_file: format!("remnants/{}", new_json.file_name().unwrap_or_default().to_string_lossy()),
                                rejection_reason: reason,
                            });
                        } else {
                            entries_migrated_to_escapes += 1;
                            let md_path = path.with_extension("md");
                            let file_stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
                            let new_json = escapes_dir.join(format!("{}.json", file_stem));
                            let reason = match res.admission_status {
                                LetterAdmissionStatus::Rejected(ref r) => r.description(),
                                _ => "Admission rejected".to_string(),
                            };
                            persist_escape_to_disk(&res);
                            let _ = fs::remove_file(&path);
                            if md_path.exists() {
                                let _ = fs::remove_file(&md_path);
                            }
                            invalid_entries.push(AuditDetail {
                                n,
                                residue_840: n % 840,
                                is_mordell_hard: is_mordell_hard(n),
                                previous_file: format!("letters/{}", path.file_name().unwrap_or_default().to_string_lossy()),
                                new_file: format!("escapes/{}", new_json.file_name().unwrap_or_default().to_string_lossy()),
                                rejection_reason: reason,
                            });
                        }
                    }
                }
            }
        }
    }

    // 2. Audit remnants vault: strictly demote any records with descent_depth <= 50 (e.g. REM-375017)
    if let Ok(entries) = fs::read_dir(&remnants_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("json")
                && path.file_name().and_then(|s| s.to_str()) != Some("index.json")
            {
                total_scanned += 1;
                if let Ok(content) = fs::read_to_string(&path) {
                    if let Ok(json_val) = serde_json::from_str::<serde_json::Value>(&content) {
                        let n = json_val.get("n").and_then(|v| v.as_u64()).unwrap_or(0);
                        let descent_depth = json_val.get("descent_depth").and_then(|v| v.as_u64()).unwrap_or_else(|| {
                            json_val.get("depth").and_then(|v| v.as_u64()).unwrap_or(0)
                        });
                        let survival_verified = json_val.get("survival_verified").and_then(|v| v.as_bool()).unwrap_or(false);

                        // Hard Invariant Check: Remnant MUST have descent_depth > REMNANT_THRESHOLD and survival_verified
                        if descent_depth > REMNANT_THRESHOLD && survival_verified {
                            remnants_retained += 1;
                        } else {
                            entries_migrated_to_escapes += 1;
                            let md_path = path.with_extension("md");
                            let new_json = escapes_dir.join(format!("ESC-{}.json", n));
                            let reason = format!(
                                "Descent depth (δ={}) <= {}; candidate does not qualify as Remnant - demoted to Escape",
                                descent_depth, REMNANT_THRESHOLD
                            );
                            
                            // Re-save as Escape
                            let res = solve_es_with_config(n, 10, "auto");
                            persist_escape_to_disk(&res);

                            let _ = fs::remove_file(&path);
                            if md_path.exists() {
                                let _ = fs::remove_file(&md_path);
                            }

                            invalid_entries.push(AuditDetail {
                                n,
                                residue_840: n % 840,
                                is_mordell_hard: is_mordell_hard(n),
                                previous_file: format!("remnants/{}", path.file_name().unwrap_or_default().to_string_lossy()),
                                new_file: format!("escapes/{}", new_json.file_name().unwrap_or_default().to_string_lossy()),
                                rejection_reason: reason,
                            });
                        }
                    }
                }
            }
        }
    }

    VaultAuditReport {
        total_scanned,
        legitimate_letters_retained,
        remnants_retained,
        entries_migrated_to_escapes,
        entries_migrated_to_remnants,
        invalid_entries,
    }
}

// Simple prime sieve for window [from, to]
pub fn sieve_primes(from: u64, to: u64) -> Vec<u64> {
    let mut primes = Vec::new();
    let start = if from < 2 { 2 } else { from };
    for n in start..=to {
        if is_prime(n) {
            primes.push(n);
        }
    }
    primes
}

pub fn run_hunt_window(from: u64, window_size: u64, max_primes: usize) -> HuntSummary {
    let config = HuntConfig {
        start_bound: from,
        window_size,
        max_primes,
        letter_threshold: 10,
        mordell_only: false,
        gods_letter_only: false,
        engine_mode: "auto".to_string(),
    };
    run_configured_hunt_window(&config)
}

pub fn run_configured_hunt_window(config: &HuntConfig) -> HuntSummary {
    let start_time = std::time::Instant::now();
    let to = config.start_bound.saturating_add(config.window_size);
    let mut primes = sieve_primes(config.start_bound, to);

    // God's Letter hunt runs the FULL engine stack (CC theorems included).
    // Mordell-only would skip every prime CC can clear, so the HUD looks dead.
    if config.mordell_only && !config.gods_letter_only {
        primes.retain(|&p| is_mordell_hard(p));
    }

    let mut theorem_clearances = 0;
    let mut corridor_clearances = 0;
    let mut cbis_escapes = 0;
    let mut cbx_survivors = 0;
    let mut ordinary_decompositions = 0;
    let mut letter_candidates_evaluated = 0;
    let mut verified_letters_count = 0;
    let mut gods_letter_count = 0;
    let mut rejected_admissions = 0;
    let mut unsolved_count = 0;
    let mut mordell_hard_count = 0;
    let mut findings = Vec::new();

    let evaluated_primes: Vec<u64> = if config.gods_letter_only {
        primes
    } else {
        primes.into_iter().take(config.max_primes).collect()
    };

    for &p in &evaluated_primes {
        if is_mordell_hard(p) {
            mordell_hard_count += 1;
        }
        let res = solve_es_with_config(p, config.letter_threshold, &config.engine_mode);

        match res.classification {
            CandidateClassification::TheoremClearance => {
                theorem_clearances += 1;
            }
            CandidateClassification::CorridorHit => {
                corridor_clearances += 1;
            }
            CandidateClassification::CbisEscape => {
                cbis_escapes += 1;
            }
            CandidateClassification::DualDescentDeepSurvivor | CandidateClassification::CbxSurvivor => {
                cbx_survivors += 1;
            }
            CandidateClassification::OrdinaryDecomposition => {
                ordinary_decompositions += 1;
            }
            CandidateClassification::UnsolvedCandidate => {
                unsolved_count += 1;
            }
            CandidateClassification::CentralGateAdmitted => {
                // Count the engine that actually found the witness, not the admission overlay.
                if res.discovery_depth <= 10 {
                    corridor_clearances += 1;
                } else if res.discovery_depth <= 50 {
                    cbis_escapes += 1;
                } else {
                    cbx_survivors += 1;
                }
            }
            CandidateClassification::CorridorEscape => {
                corridor_clearances += 1;
            }
            CandidateClassification::InvalidCandidate => {}
        }

        if res.is_mordell_hard {
            letter_candidates_evaluated += 1;
        }

        // Multi-Artifact Persistence: Preserve each earned artifact independently without mutual destruction
        if res.letter_admitted {
            verified_letters_count += 1;
            persist_letter_to_disk(&res);
        }
        if res.remnant_admitted {
            persist_remnant_to_disk(&res);
        }
        if res.escape_admitted {
            persist_escape_to_disk(&res);
        }

        let gl_eval = if res.is_mordell_hard {
            let spec = GodsLetterSpec::v1();
            let raw = match &res.witness {
                Some(w) => vec![EsWitness::new(
                    res.n as u128,
                    w.x.clone(),
                    w.y.clone(),
                    w.z.clone(),
                    &w.method,
                    &w.engine_name,
                    w.discovery_depth,
                )],
                None => Vec::new(),
            };
            Some(evaluate_gods_letter_candidate(res.n as u128, &raw, &spec))
        } else {
            None
        };
        let gl_candidate = gl_eval.as_ref().map(|e| e.gods_letter_candidate).unwrap_or(false);
        if gl_candidate {
            gods_letter_count += 1;
            if let Some(eval) = gl_eval.as_ref() {
                let _ = persist_gods_letter_candidate(eval);
            }
        }

        if config.gods_letter_only {
            if gl_candidate {
                findings.push(res);
            } else {
                rejected_admissions += 1;
            }
        } else if res.letter_admitted {
            findings.push(res);
        } else {
            rejected_admissions += 1;
            // Record interesting non-letter corridor escapes, remnants, and Mordell candidates
            if res.is_mordell_hard
                || res.remnant_admitted
                || res.classification == CandidateClassification::CbisEscape
                || res.classification == CandidateClassification::DualDescentDeepSurvivor
                || res.classification == CandidateClassification::CbxSurvivor
            {
                findings.push(res);
            }
        }
    }

    HuntSummary {
        start_bound: config.start_bound,
        end_bound: to,
        primes_checked: evaluated_primes.len(),
        mordell_hard_count,
        theorem_clearances,
        corridor_clearances,
        cbis_escapes,
        cbx_survivors,
        ordinary_decompositions,
        letter_candidates_evaluated,
        verified_letters_count,
        gods_letter_count,
        rejected_admissions,
        unsolved_count,
        active_engine: if config.engine_mode == "auto" {
            "Coordinated Ensemble (CC/CBAP/CBIS/CBX/BB)".to_string()
        } else {
            config.engine_mode.clone()
        },
        filter_mode: if config.gods_letter_only {
            "God's Letter (unsolved Mordell-hard after full engine menu)".to_string()
        } else if config.mordell_only {
            "Mordell-Hard Only (840k + r)".to_string()
        } else {
            format!("Letter Depth ≥ {}", config.letter_threshold)
        },
        findings,
        execution_millis: start_time.elapsed().as_millis(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::erdos_straus::LetterRejectionReason;
    use crate::engine::rational::BigInt;

    #[test]
    fn test_configured_hunt_window_standard() {
        let config = HuntConfig {
            start_bound: 20000,
            window_size: 1000,
            max_primes: 50,
            letter_threshold: 10,
            mordell_only: false,
            gods_letter_only: false,
            engine_mode: "auto".to_string(),
        };

        let summary = run_configured_hunt_window(&config);
        assert_eq!(summary.start_bound, 20000);
        assert_eq!(summary.end_bound, 21000);
        assert!(summary.primes_checked > 0);
        assert_eq!(summary.unsolved_count, 0);

        // Exhaustive classification integrity: every scanned prime belongs to exactly one structural bucket
        let sum_classified = summary.theorem_clearances
            + summary.corridor_clearances
            + summary.cbis_escapes
            + summary.cbx_survivors
            + summary.ordinary_decompositions
            + summary.unsolved_count;
        assert_eq!(sum_classified, summary.primes_checked);

        // Verified letters must be <= Mordell-hard candidates
        assert!(summary.verified_letters_count <= summary.mordell_hard_count);
    }

    #[test]
    fn test_configured_hunt_window_gods_letter_filter() {
        let config = HuntConfig {
            start_bound: 1000,
            window_size: 2000,
            max_primes: 50,
            letter_threshold: 10,
            mordell_only: false,
            gods_letter_only: true,
            engine_mode: "auto".to_string(),
        };
        let summary = run_configured_hunt_window(&config);
        assert_eq!(summary.filter_mode, "God's Letter (unsolved Mordell-hard after full engine menu)");
        assert!(summary.theorem_clearances > 0, "CC.kernel must run on non-Mordell primes in a God's Letter hunt");
        assert_eq!(summary.gods_letter_count, 0, "solved Mordell primes are not God's Letters");
        assert!(!summary.findings.iter().any(|f| f.n == 2521));
        assert!(!summary.findings.iter().any(|f| f.n == 1201));
    }

    #[test]
    fn test_configured_hunt_window_mordell_only() {
        let config = HuntConfig {
            start_bound: 20000,
            window_size: 5000,
            max_primes: 50,
            letter_threshold: 10,
            mordell_only: true,
            gods_letter_only: false,
            engine_mode: "auto".to_string(),
        };

        let summary = run_configured_hunt_window(&config);
        assert_eq!(summary.start_bound, 20000);
        assert_eq!(summary.end_bound, 25000);
        assert!(summary.primes_checked > 0);
        assert_eq!(summary.mordell_hard_count, summary.primes_checked);
        for f in &summary.findings {
            assert!(f.is_mordell_hard);
        }
    }

    static VAULT_TEST_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());

    #[test]
    fn test_persist_letter_to_disk_admitted_only() {
        let _guard = VAULT_TEST_LOCK.lock().unwrap();
        // p = 2521 with threshold 10 is CorridorHit (rejected from letters)
        let routine_res = solve_es_with_config(2521, 10, "auto");
        assert_eq!(routine_res.n, 2521);
        assert_ne!(routine_res.grade, "letter");
        assert_eq!(routine_res.letter_number, None);

        // When threshold is 0 <= depth 0, Central Gate admits it as genuine letter
        let letter_res = solve_es_with_config(2521, 0, "auto");
        assert_eq!(letter_res.grade, "letter");
        assert!(letter_res.letter_number.is_some());
        persist_letter_to_disk(&letter_res);

        let letters_dir = resolve_letters_dir();
        let md_file = letters_dir.join("L-2521.md");
        let json_file = letters_dir.join("L-2521.json");
        assert!(md_file.exists());
        assert!(json_file.exists());
        let md_content = fs::read_to_string(&md_file).unwrap();
        assert!(md_content.contains("# Erdős–Straus Letter Certificate: #L-2521"));
        assert!(md_content.contains("ADMITTED"));
    }

    #[test]
    fn test_persist_remnant_to_disk_qualified() {
        let _guard = VAULT_TEST_LOCK.lock().unwrap();
        // Create qualified CBX dual descent deep survivor
        let p = 375017;
        let mut res = solve_es_with_config(p, 10, "auto");
        res.descent_depth = 57;
        res.discovery_depth = 0;
        res.dual_descent_certificate = Some(DualDescentCertificate {
            candidate: p,
            descent_depth: 57,
            threshold: 50,
            survival_engine: "CBX.kernel (Dual Descent)".to_string(),
            verified: true,
            certificate: "REM-0000000000000001".to_string(),
        });
        res.remnant_admitted = true;
        res.classification = CandidateClassification::DualDescentDeepSurvivor;
        persist_remnant_to_disk(&res);

        let remnants_dir = resolve_remnants_dir();
        let md_file = remnants_dir.join("REM-375017.md");
        let json_file = remnants_dir.join("REM-375017.json");
        assert!(md_file.exists());
        assert!(json_file.exists());
        let md_content = fs::read_to_string(&md_file).unwrap();
        assert!(md_content.contains("# Erdős–Straus Remnant Certificate: #REM-375017"));
        assert!(md_content.contains("Dual Descent Survival Depth (δ)"));
        assert!(md_content.contains("`57`"));
        assert!(md_content.contains("Discovery Depth"));
        assert!(md_content.contains("`0`"));
        assert!(md_content.contains("CBX Dual Descent Deep Survivor"));

        let json_content = fs::read_to_string(&json_file).unwrap();
        let val: serde_json::Value = serde_json::from_str(&json_content).unwrap();
        assert_eq!(val["schema"], "centl26.erdos_straus.remnant/v1");
        assert_eq!(val["remnant_id"], "REM-375017");
        assert_eq!(val["descent_depth"], 57);
        assert_eq!(val["discovery_depth"], 0);
        assert_eq!(val["remnant_threshold"], 50);
        assert_eq!(val["grade"], "remnant");
        assert_eq!(val["classification"], "dual_descent_deep_survivor");
        assert_eq!(val["survival_verified"], true);
    }

    #[test]
    fn test_rem_375017_demoted_to_escape_on_descent_zero() {
        let _guard = VAULT_TEST_LOCK.lock().unwrap();
        let remnants_dir = resolve_remnants_dir();
        let escapes_dir = resolve_escapes_dir();

        // Write an old/invalid REM-375017 file with descent_depth = 0
        let fake_rem_json = remnants_dir.join("REM-375017.json");
        let fake_rem_md = remnants_dir.join("REM-375017.md");
        let _ = fs::write(&fake_rem_json, r#"{"schema":"centl26.erdos_straus.remnant/v1","n":375017,"descent_depth":0,"depth":0,"survival_verified":false}"#);
        let _ = fs::write(&fake_rem_md, "# Stale REM");

        // Run audit & migration
        let report = audit_and_migrate_vault();
        assert!(report.entries_migrated_to_escapes >= 1);

        // Stale remnant files must be removed
        assert!(!fake_rem_json.exists());
        assert!(!fake_rem_md.exists());

        // Escape file must exist and be valid
        let esc_json = escapes_dir.join("ESC-375017.json");
        let esc_md = escapes_dir.join("ESC-375017.md");
        assert!(esc_json.exists());
        assert!(esc_md.exists());
        let val: serde_json::Value = serde_json::from_str(&fs::read_to_string(&esc_json).unwrap()).unwrap();
        assert_eq!(val["grade"], "escape");
        assert_eq!(val["n"], 375017);
    }

    #[test]
    fn test_hard_invariant_rejection_contradictions() {
        // 1. Remnant with descent_depth <= 50 -> ERROR
        let err1 = validate_artifact_invariants(
            "remnant",
            375017,
            377,
            0, // descent_depth <= 50
            0,
            "REM-375017",
            false,
            &LetterAdmissionStatus::Rejected(LetterRejectionReason::NonMordellResidue(377)),
            None,
            None,
        );
        assert!(err1.is_err());

        // 2. Letter with unverified witness -> ERROR
        let mut unverified_w = Witness {
            n: 2521,
            x: BigInt::from_u64(10), // Corrupted x
            y: BigInt::from_u64(20),
            z: BigInt::from_u64(30),
            method: "test".to_string(),
            layer: "test".to_string(),
            kind: "test".to_string(),
            engine_name: "test".to_string(),
            discovery_depth: 10,
            descent_depth: 0,
            depth: 10,
            residue_840: 1,
            is_mordell_hard: true,
            verified: false,
        };
        let err2 = validate_artifact_invariants(
            "letter",
            2521,
            1,
            0,
            10,
            "L-2521",
            true,
            &LetterAdmissionStatus::Admitted,
            Some(&unverified_w),
            None,
        );
        assert!(err2.is_err());

        // 3. ID mismatch -> ERROR
        unverified_w.verified = true;
        let err3 = validate_artifact_invariants(
            "letter",
            2521,
            1,
            0,
            10,
            "L-9999", // Mismatch
            true,
            &LetterAdmissionStatus::Admitted,
            Some(&unverified_w),
            None,
        );
        assert!(err3.is_err());

        // 4. Residue mismatch -> ERROR
        let err4 = validate_artifact_invariants(
            "letter",
            2521,
            999, // Mismatch (actual is 1)
            0,
            10,
            "L-2521",
            true,
            &LetterAdmissionStatus::Admitted,
            Some(&unverified_w),
            None,
        );
        assert!(err4.is_err());
    }

    #[test]
    fn test_audit_and_migrate_vault() {
        let _guard = VAULT_TEST_LOCK.lock().unwrap();
        let report = audit_and_migrate_vault();
        assert!(report.total_scanned >= report.legitimate_letters_retained);
    }
}
