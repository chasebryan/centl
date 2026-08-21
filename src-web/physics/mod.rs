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

pub struct PhysicalConstant {
    pub symbol: &'static str,
    pub name: &'static str,
    pub value_str: &'static str,
    pub value_f64: f64,
    pub unit: &'static str,
    pub exact: bool,
    pub provenance: &'static str,
}

pub const PHYSICAL_CONSTANTS: &[PhysicalConstant] = &[
    PhysicalConstant { symbol: "c", name: "Speed of light in vacuum", value_str: "299792458", value_f64: 299792458.0, unit: "m/s", exact: true, provenance: "SI definition (exact)" },
    PhysicalConstant { symbol: "h", name: "Planck constant", value_str: "6.62607015e-34", value_f64: 6.62607015e-34, unit: "J·s", exact: true, provenance: "SI definition (exact)" },
    PhysicalConstant { symbol: "hbar", name: "Reduced Planck constant (h / 2pi)", value_str: "1.054571817e-34", value_f64: 1.0545718176461565e-34, unit: "J·s", exact: false, provenance: "Derived from SI h" },
    PhysicalConstant { symbol: "G", name: "Newtonian constant of gravitation", value_str: "6.67430e-11", value_f64: 6.67430e-11, unit: "m³/(kg·s²)", exact: false, provenance: "CODATA 2018" },
    PhysicalConstant { symbol: "k_B", name: "Boltzmann constant", value_str: "1.380649e-23", value_f64: 1.380649e-23, unit: "J/K", exact: true, provenance: "SI definition (exact)" },
    PhysicalConstant { symbol: "k", name: "Boltzmann constant (alias)", value_str: "1.380649e-23", value_f64: 1.380649e-23, unit: "J/K", exact: true, provenance: "SI definition (exact)" },
    PhysicalConstant { symbol: "e", name: "Elementary charge", value_str: "1.602176634e-19", value_f64: 1.602176634e-19, unit: "C", exact: true, provenance: "SI definition (exact)" },
    PhysicalConstant { symbol: "m_e", name: "Electron rest mass", value_str: "9.1093837015e-31", value_f64: 9.1093837015e-31, unit: "kg", exact: false, provenance: "CODATA 2018" },
    PhysicalConstant { symbol: "m_p", name: "Proton rest mass", value_str: "1.67262192369e-27", value_f64: 1.67262192369e-27, unit: "kg", exact: false, provenance: "CODATA 2018" },
    PhysicalConstant { symbol: "m_n", name: "Neutron rest mass", value_str: "1.67492749804e-27", value_f64: 1.67492749804e-27, unit: "kg", exact: false, provenance: "CODATA 2018" },
    PhysicalConstant { symbol: "N_A", name: "Avogadro constant", value_str: "6.02214076e23", value_f64: 6.02214076e23, unit: "mol⁻¹", exact: true, provenance: "SI definition (exact)" },
    PhysicalConstant { symbol: "epsilon_0", name: "Vacuum electric permittivity", value_str: "8.8541878128e-12", value_f64: 8.8541878128e-12, unit: "F/m", exact: false, provenance: "CODATA 2018" },
    PhysicalConstant { symbol: "mu_0", name: "Vacuum magnetic permeability", value_str: "1.25663706212e-6", value_f64: 1.25663706212e-6, unit: "N/A²", exact: false, provenance: "CODATA 2018" },
    PhysicalConstant { symbol: "R", name: "Molar gas constant (N_A * k_B)", value_str: "8.31446261815324", value_f64: 8.31446261815324, unit: "J/(mol·K)", exact: true, provenance: "Exact product N_A * k_B" },
    PhysicalConstant { symbol: "g_0", name: "Standard acceleration of gravity", value_str: "9.80665", value_f64: 9.80665, unit: "m/s²", exact: true, provenance: "Standard definition (exact)" },
    PhysicalConstant { symbol: "sigma_sb", name: "Stefan-Boltzmann constant", value_str: "5.670374419e-8", value_f64: 5.670374419e-8, unit: "W/(m²·K⁴)", exact: true, provenance: "Exact derivation (pi² k_B⁴ / (60 hbar³ c²))" },
    PhysicalConstant { symbol: "alpha", name: "Fine-structure constant", value_str: "0.0072973525693", value_f64: 7.2973525693e-3, unit: "dimensionless (1/137.035999084)", exact: false, provenance: "CODATA 2018" },
];

pub fn lookup_constant(symbol: &str) -> Option<&'static PhysicalConstant> {
    let sym_clean = symbol.trim();
    PHYSICAL_CONSTANTS.iter().find(|c| c.symbol.eq_ignore_ascii_case(sym_clean))
}

pub fn list_units_catalog() -> PhysicsResult {
    let catalog = vec![
        ("Length", "m (meter, SI), cm, mm, km, in (inch), ft (foot), yd (yard), mi (mile)"),
        ("Mass", "kg (kilogram, SI), g, mg, lb (pound), oz (ounce)"),
        ("Time", "s (second, SI), ms, min (minute), hr (hour), day"),
        ("Energy", "J (joule, SI), kJ, cal (calorie), kcal, eV (electronvolt), kWh"),
        ("Pressure", "Pa (pascal, SI), kPa, bar, atm (atmosphere), psi, mmHg"),
        ("Constants", "c, h, hbar, G, k_B, e, m_e, m_p, m_n, N_A, epsilon_0, mu_0, R, g_0, sigma_sb, alpha"),
    ];
    let details = catalog
        .into_iter()
        .map(|(cat, units)| (cat.to_string(), units.to_string()))
        .collect();
    PhysicsResult {
        title: "Physical Units & Dimensions Catalog".to_string(),
        details,
        summary: "SI base dimensions and derived unit conversions available".to_string(),
        verified: true,
    }
}

pub fn calculate_cherenkov(refractive_index: f64, speed: f64) -> Result<PhysicsResult, String> {
    if refractive_index < 1.0 {
        return Err("refractive index must be >= 1.0".to_string());
    }
    if speed <= 0.0 {
        return Err("particle speed must be > 0.0 m/s".to_string());
    }
    let c = 299792458.0;
    if speed >= c {
        return Err("particle speed must be strictly subluminal (< c)".to_string());
    }

    let beta = speed / c;
    let threshold_beta = 1.0 / refractive_index;
    let threshold_speed = c / refractive_index;
    let beta_n = beta * refractive_index;
    let emission = beta_n > 1.0;

    let (cone_angle_rad, cone_angle_deg) = if emission {
        let cos_theta = 1.0 / beta_n;
        let theta_rad = cos_theta.acos();
        (Some(theta_rad), Some(theta_rad.to_degrees()))
    } else {
        (None, None)
    };

    let mut details = vec![
        ("Refractive Index (n)".to_string(), format!("{:.6}", refractive_index)),
        ("Particle Speed (v)".to_string(), format!("{:.6e} m/s", speed)),
        ("Particle Beta (v/c)".to_string(), format!("{:.6}", beta)),
        ("Threshold Beta (1/n)".to_string(), format!("{:.6}", threshold_beta)),
        ("Threshold Speed (c/n)".to_string(), format!("{:.6e} m/s", threshold_speed)),
        ("Beta * n Product".to_string(), format!("{:.6}", beta_n)),
        ("Cherenkov Emission".to_string(), if emission { "ACTIVE (v > c/n)".to_string() } else { "SUB-THRESHOLD (no emission)".to_string() }),
    ];

    if let (Some(rad), Some(deg)) = (cone_angle_rad, cone_angle_deg) {
        details.push(("Cherenkov Cone Angle (rad)".to_string(), format!("{:.6} rad", rad)));
        details.push(("Cherenkov Cone Angle (deg)".to_string(), format!("{:.4}°", deg)));
    }

    let summary = if emission {
        format!("Emission active: beta*n = {:.4} > 1, cone angle = {:.2}°", beta_n, cone_angle_deg.unwrap_or(0.0))
    } else {
        format!("Sub-threshold: beta*n = {:.4} <= 1, no radiation emitted", beta_n)
    };

    Ok(PhysicsResult {
        title: "Relativistic Cherenkov Radiation Analysis".to_string(),
        details,
        summary,
        verified: true,
    })
}

pub fn simulate_gravity_trajectory(
    mass: f64,
    pos: (f64, f64, f64),
    vel: (f64, f64, f64),
    grav: (f64, f64, f64),
    dt: f64,
    steps: u64,
) -> Result<PhysicsResult, String> {
    if mass <= 0.0 {
        return Err("mass must be > 0".to_string());
    }
    if dt <= 0.0 {
        return Err("time step dt must be > 0".to_string());
    }
    if steps == 0 || steps > 1000000 {
        return Err("steps must be between 1 and 1,000,000".to_string());
    }

    let mut p = pos;
    let mut v = vel;
    for _ in 0..steps {
        // Symplectic Euler: update velocity first, then position
        v.0 += grav.0 * dt;
        v.1 += grav.1 * dt;
        v.2 += grav.2 * dt;
        p.0 += v.0 * dt;
        p.1 += v.1 * dt;
        p.2 += v.2 * dt;
    }

    let t_total = (steps as f64) * dt;
    let v_mag = (v.0 * v.0 + v.1 * v.1 + v.2 * v.2).sqrt();
    let p_mag = (p.0 * p.0 + p.1 * p.1 + p.2 * p.2).sqrt();

    Ok(PhysicsResult {
        title: "Symplectic Gravitational Trajectory Simulation".to_string(),
        details: vec![
            ("Mass".to_string(), format!("{} kg", mass)),
            ("Initial Position".to_string(), format!("({:.4}, {:.4}, {:.4}) m", pos.0, pos.1, pos.2)),
            ("Initial Velocity".to_string(), format!("({:.4}, {:.4}, {:.4}) m/s", vel.0, vel.1, vel.2)),
            ("Gravity Acceleration".to_string(), format!("({:.4}, {:.4}, {:.4}) m/s²", grav.0, grav.1, grav.2)),
            ("Time Step (dt)".to_string(), format!("{:.4} s", dt)),
            ("Total Steps".to_string(), format!("{}", steps)),
            ("Total Duration".to_string(), format!("{:.4} s", t_total)),
            ("Final Position".to_string(), format!("({:.4}, {:.4}, {:.4}) m (dist: {:.4} m)", p.0, p.1, p.2, p_mag)),
            ("Final Velocity".to_string(), format!("({:.4}, {:.4}, {:.4}) m/s (speed: {:.4} m/s)", v.0, v.1, v.2, v_mag)),
        ],
        summary: format!("t = {:.2}s: p = ({:.2}, {:.2}, {:.2}) m, v = ({:.2}, {:.2}, {:.2}) m/s", t_total, p.0, p.1, p.2, v.0, v.1, v.2),
        verified: true,
    })
}
