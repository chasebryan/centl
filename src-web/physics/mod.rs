// Physics Engine & Scientific Computations for CENTL
// Free Computation Foundation - Apache-2.0

use std::collections::HashMap;

#[derive(Clone, Debug, PartialEq)]
pub struct PhysicsResult {
    pub title: String,
    pub details: Vec<(String, String)>,
    pub summary: String,
    pub verified: bool,
}

pub fn convert_units(value: f64, from: &str, to: &str) -> Result<PhysicsResult, String> {
    let from_clean = from.trim().to_lowercase();
    let to_clean = to.trim().to_lowercase();

    // Length conversion
    let length_factors: HashMap<&str, f64> = [
        ("m", 1.0), ("meter", 1.0), ("meters", 1.0),
        ("cm", 0.01), ("centimeter", 0.01), ("centimeters", 0.01),
        ("mm", 0.001), ("millimeter", 0.001),
        ("km", 1000.0), ("kilometer", 1000.0),
        ("in", 0.0254), ("inch", 0.0254), ("inches", 0.0254),
        ("ft", 0.3048), ("foot", 0.3048), ("feet", 0.3048),
        ("yd", 0.9144), ("yard", 0.9144),
        ("mi", 1609.344), ("mile", 1609.344), ("miles", 1609.344),
    ].into_iter().collect();

    // Mass conversion
    let mass_factors: HashMap<&str, f64> = [
        ("kg", 1.0), ("kilogram", 1.0),
        ("g", 0.001), ("gram", 0.001),
        ("mg", 0.000001), ("milligram", 0.000001),
        ("lb", 0.45359237), ("lbs", 0.45359237), ("pound", 0.45359237),
        ("oz", 0.028349523125), ("ounce", 0.028349523125),
    ].into_iter().collect();

    // Time conversion
    let time_factors: HashMap<&str, f64> = [
        ("s", 1.0), ("sec", 1.0), ("second", 1.0), ("seconds", 1.0),
        ("ms", 0.001), ("millisecond", 0.001),
        ("min", 60.0), ("minute", 60.0), ("minutes", 60.0),
        ("hr", 3600.0), ("hour", 3600.0), ("hours", 3600.0),
        ("day", 86400.0), ("days", 86400.0),
    ].into_iter().collect();

    // Energy conversion
    let energy_factors: HashMap<&str, f64> = [
        ("j", 1.0), ("joule", 1.0), ("joules", 1.0),
        ("kj", 1000.0), ("kilojoule", 1000.0),
        ("cal", 4.184), ("calorie", 4.184),
        ("kcal", 4184.0), ("kilocalorie", 4184.0),
        ("ev", 1.602176634e-19), ("electronvolt", 1.602176634e-19),
        ("kwh", 3600000.0),
    ].into_iter().collect();

    // Pressure conversion
    let pressure_factors: HashMap<&str, f64> = [
        ("pa", 1.0), ("pascal", 1.0),
        ("kpa", 1000.0),
        ("bar", 100000.0),
        ("atm", 101325.0),
        ("psi", 6894.757),
        ("mmhg", 133.322),
    ].into_iter().collect();

    let check_map = |map: &HashMap<&str, f64>| -> Option<f64> {
        let f1 = map.get(from_clean.as_str())?;
        let f2 = map.get(to_clean.as_str())?;
        let base_si = value * f1;
        Some(base_si / f2)
    };

    if let Some(res) = check_map(&length_factors) {
        return Ok(PhysicsResult {
            title: "Length Unit Conversion".to_string(),
            details: vec![
                ("Input".to_string(), format!("{} {}", value, from)),
                ("Output".to_string(), format!("{:.8} {}", res, to)),
                ("Conversion Factor".to_string(), format!("1 {} = {} {}", from, length_factors[from_clean.as_str()] / length_factors[to_clean.as_str()], to)),
            ],
            summary: format!("{} {} = {:.8} {}", value, from, res, to),
            verified: true,
        });
    }

    if let Some(res) = check_map(&mass_factors) {
        return Ok(PhysicsResult {
            title: "Mass Unit Conversion".to_string(),
            details: vec![
                ("Input".to_string(), format!("{} {}", value, from)),
                ("Output".to_string(), format!("{:.8} {}", res, to)),
            ],
            summary: format!("{} {} = {:.8} {}", value, from, res, to),
            verified: true,
        });
    }

    if let Some(res) = check_map(&time_factors) {
        return Ok(PhysicsResult {
            title: "Time Unit Conversion".to_string(),
            details: vec![
                ("Input".to_string(), format!("{} {}", value, from)),
                ("Output".to_string(), format!("{:.8} {}", res, to)),
            ],
            summary: format!("{} {} = {:.8} {}", value, from, res, to),
            verified: true,
        });
    }

    if let Some(res) = check_map(&energy_factors) {
        return Ok(PhysicsResult {
            title: "Energy Unit Conversion".to_string(),
            details: vec![
                ("Input".to_string(), format!("{} {}", value, from)),
                ("Output".to_string(), format!("{:.8} {}", res, to)),
            ],
            summary: format!("{} {} = {:.8} {}", value, from, res, to),
            verified: true,
        });
    }

    if let Some(res) = check_map(&pressure_factors) {
        return Ok(PhysicsResult {
            title: "Pressure Unit Conversion".to_string(),
            details: vec![
                ("Input".to_string(), format!("{} {}", value, from)),
                ("Output".to_string(), format!("{:.8} {}", res, to)),
            ],
            summary: format!("{} {} = {:.8} {}", value, from, res, to),
            verified: true,
        });
    }

    Err(format!("incompatible or unknown units: {} -> {}", from, to))
}

pub fn simulate_collision_1d(m1: f64, v1: f64, m2: f64, v2: f64, restitution: f64) -> Result<PhysicsResult, String> {
    if m1 <= 0.0 || m2 <= 0.0 {
        return Err("masses must be strictly positive".to_string());
    }
    let e = restitution.clamp(0.0, 1.0);

    let p_initial = m1 * v1 + m2 * v2;
    let ke1_initial = 0.5 * m1 * v1 * v1;
    let ke2_initial = 0.5 * m2 * v2 * v2;
    let ke_total_initial = ke1_initial + ke2_initial;

    let total_mass = m1 + m2;
    let v1_prime = (m1 * v1 + m2 * v2 - m2 * e * (v1 - v2)) / total_mass;
    let v2_prime = (m1 * v1 + m2 * v2 + m1 * e * (v1 - v2)) / total_mass;

    let p_final = m1 * v1_prime + m2 * v2_prime;
    let ke1_final = 0.5 * m1 * v1_prime * v1_prime;
    let ke2_final = 0.5 * m2 * v2_prime * v2_prime;
    let ke_total_final = ke1_final + ke2_final;
    let energy_loss = ke_total_initial - ke_total_final;

    let momentum_conserved = (p_initial - p_final).abs() < 1e-9;

    Ok(PhysicsResult {
        title: format!("1D Collision Simulation (Restitution e = {:.2})", e),
        details: vec![
            ("Body 1 Initial".to_string(), format!("m1 = {} kg, v1 = {:.4} m/s", m1, v1)),
            ("Body 2 Initial".to_string(), format!("m2 = {} kg, v2 = {:.4} m/s", m2, v2)),
            ("Body 1 Final".to_string(), format!("v1' = {:.4} m/s", v1_prime)),
            ("Body 2 Final".to_string(), format!("v2' = {:.4} m/s", v2_prime)),
            ("Total Momentum".to_string(), format!("P_init = {:.6} kg·m/s, P_final = {:.6} kg·m/s", p_initial, p_final)),
            ("Initial Kinetic Energy".to_string(), format!("{:.6} J", ke_total_initial)),
            ("Final Kinetic Energy".to_string(), format!("{:.6} J (loss: {:.6} J)", ke_total_final, energy_loss)),
            ("Momentum Conservation".to_string(), if momentum_conserved { "VERIFIED EXACT".to_string() } else { "ERROR".to_string() }),
        ],
        summary: format!("v1' = {:.4} m/s, v2' = {:.4} m/s (P = {:.4} kg·m/s)", v1_prime, v2_prime, p_final),
        verified: momentum_conserved,
    })
}

pub fn calculate_kinematics(v0: f64, a: f64, t: f64) -> PhysicsResult {
    let v = v0 + a * t;
    let d = v0 * t + 0.5 * a * t * t;
    PhysicsResult {
        title: "Kinematics Calculation".to_string(),
        details: vec![
            ("Initial Velocity (v0)".to_string(), format!("{:.4} m/s", v0)),
            ("Acceleration (a)".to_string(), format!("{:.4} m/s²", a)),
            ("Time elapsed (t)".to_string(), format!("{:.4} s", t)),
            ("Final Velocity (v)".to_string(), format!("{:.4} m/s", v)),
            ("Displacement (d)".to_string(), format!("{:.4} m", d)),
        ],
        summary: format!("v = {:.4} m/s, displacement d = {:.4} m", v, d),
        verified: true,
    }
}
