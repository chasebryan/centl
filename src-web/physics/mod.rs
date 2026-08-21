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

    // Velocity / Speed conversion (SI: m/s)
    let speed_factors: HashMap<&str, f64> = [
        ("m/s", 1.0), ("mps", 1.0), ("meter/sec", 1.0), ("meters/sec", 1.0),
        ("km/h", 1.0 / 3.6), ("kph", 1.0 / 3.6), ("km/hr", 1.0 / 3.6),
        ("mph", 0.44704), ("mile/hr", 0.44704), ("miles/hr", 0.44704),
        ("ft/s", 0.3048), ("fps", 0.3048), ("knot", 0.514444), ("knots", 0.514444),
        ("c", 299792458.0),
    ].into_iter().collect();

    // Power conversion (SI: W)
    let power_factors: HashMap<&str, f64> = [
        ("w", 1.0), ("watt", 1.0), ("watts", 1.0),
        ("kw", 1000.0), ("kilowatt", 1000.0), ("kilowatts", 1000.0),
        ("mw", 1000000.0), ("megawatt", 1000000.0),
        ("hp", 745.699872), ("horsepower", 745.699872),
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

    if let Some(res) = check_map(&speed_factors) {
        return Ok(PhysicsResult {
            title: "Speed / Velocity Unit Conversion".to_string(),
            details: vec![
                ("Input".to_string(), format!("{} {}", value, from)),
                ("Output".to_string(), format!("{:.8} {}", res, to)),
            ],
            summary: format!("{} {} = {:.8} {}", value, from, res, to),
            verified: true,
        });
    }

    if let Some(res) = check_map(&power_factors) {
        return Ok(PhysicsResult {
            title: "Power Unit Conversion".to_string(),
            details: vec![
                ("Input".to_string(), format!("{} {}", value, from)),
                ("Output".to_string(), format!("{:.8} {}", res, to)),
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

/// De Broglie Wavelength: λ = h / (m * v)
pub fn calculate_debroglie(mass: f64, velocity: f64) -> Result<PhysicsResult, String> {
    if mass <= 0.0 || velocity <= 0.0 {
        return Err("mass and velocity must be strictly positive".to_string());
    }
    let h = 6.62607015e-34;
    let p = mass * velocity;
    let wavelength = h / p;
    let wavelength_nm = wavelength * 1e9;
    let wavelength_pm = wavelength * 1e12;

    Ok(PhysicsResult {
        title: "De Broglie Matter Wave Calculation".to_string(),
        details: vec![
            ("Mass (m)".to_string(), format!("{:.6e} kg", mass)),
            ("Velocity (v)".to_string(), format!("{:.6e} m/s", velocity)),
            ("Momentum (p)".to_string(), format!("{:.6e} kg·m/s", p)),
            ("Planck Constant (h)".to_string(), "6.62607015e-34 J·s (exact SI)".to_string()),
            ("Wavelength (SI)".to_string(), format!("{:.6e} m", wavelength)),
            ("Wavelength (nm)".to_string(), format!("{:.6e} nm", wavelength_nm)),
            ("Wavelength (pm)".to_string(), format!("{:.6e} pm", wavelength_pm)),
        ],
        summary: format!("λ = {:.6e} m ({:.4} nm)", wavelength, wavelength_nm),
        verified: true,
    })
}

/// Photon Energy & Momentum: E = h*f = h*c / λ
pub fn calculate_photon(value: f64, is_wavelength: bool) -> Result<PhysicsResult, String> {
    if value <= 0.0 {
        return Err("wavelength or frequency must be strictly positive".to_string());
    }
    let h = 6.62607015e-34;
    let c = 299792458.0;
    let q_e = 1.602176634e-19;

    let (wavelength_m, freq_hz) = if is_wavelength {
        (value, c / value)
    } else {
        (c / value, value)
    };

    let energy_j = h * freq_hz;
    let energy_ev = energy_j / q_e;
    let momentum_si = h / wavelength_m;

    Ok(PhysicsResult {
        title: "Photon Energy, Frequency & Momentum".to_string(),
        details: vec![
            ("Wavelength (λ)".to_string(), format!("{:.6e} m ({:.2} nm)", wavelength_m, wavelength_m * 1e9)),
            ("Frequency (f)".to_string(), format!("{:.6e} Hz ({:.2} THz)", freq_hz, freq_hz * 1e-12)),
            ("Energy (Joules)".to_string(), format!("{:.6e} J", energy_j)),
            ("Energy (eV)".to_string(), format!("{:.6} eV", energy_ev)),
            ("Momentum (p)".to_string(), format!("{:.6e} kg·m/s", momentum_si)),
        ],
        summary: format!("E = {:.4} eV ({:.6e} J), f = {:.4e} Hz", energy_ev, energy_j, freq_hz),
        verified: true,
    })
}

/// Rydberg Atomic Transition Formula: 1/λ = R_H * Z² * (1/n1² - 1/n2²)
pub fn calculate_rydberg(n1: u64, n2: u64, z: u64) -> Result<PhysicsResult, String> {
    if n1 == 0 || n2 == 0 {
        return Err("principal quantum numbers n1 and n2 must be >= 1".to_string());
    }
    if n1 >= n2 {
        return Err("n1 must be strictly less than n2 (emission transition)".to_string());
    }
    if z == 0 {
        return Err("atomic number Z must be >= 1".to_string());
    }
    let r_inf = 10973731.568160; // m^-1 (CODATA Rydberg constant)
    let c = 299792458.0;
    let h = 6.62607015e-34;
    let q_e = 1.602176634e-19;

    let inv_lambda = r_inf * (z as f64).powi(2) * (1.0 / (n1 as f64).powi(2) - 1.0 / (n2 as f64).powi(2));
    let wavelength_m = 1.0 / inv_lambda;
    let wavelength_nm = wavelength_m * 1e9;
    let freq_hz = c / wavelength_m;
    let energy_j = h * freq_hz;
    let energy_ev = energy_j / q_e;

    let series_name = match n1 {
        1 => "Lyman Series (UV)",
        2 => "Balmer Series (Visible)",
        3 => "Paschen Series (Infrared)",
        4 => "Brackett Series (Far-IR)",
        5 => "Pfund Series (Far-IR)",
        _ => "Higher Series",
    };

    Ok(PhysicsResult {
        title: format!("Rydberg Spectral Line Transition (n = {} → {})", n2, n1),
        details: vec![
            ("Lower State (n1)".to_string(), n1.to_string()),
            ("Upper State (n2)".to_string(), n2.to_string()),
            ("Atomic Number (Z)".to_string(), z.to_string()),
            ("Spectral Series".to_string(), series_name.to_string()),
            ("Wavenumber (1/λ)".to_string(), format!("{:.6e} m⁻¹", inv_lambda)),
            ("Transition Wavelength".to_string(), format!("{:.6e} m ({:.4} nm)", wavelength_m, wavelength_nm)),
            ("Photon Frequency".to_string(), format!("{:.6e} Hz", freq_hz)),
            ("Photon Energy".to_string(), format!("{:.6} eV ({:.6e} J)", energy_ev, energy_j)),
        ],
        summary: format!("λ = {:.2} nm ({} eV, {})", wavelength_nm, energy_ev, series_name),
        verified: true,
    })
}

/// Photoelectric Effect: K_max = h*f - Φ
pub fn calculate_photoelectric(work_function_ev: f64, wavelength_nm: f64) -> Result<PhysicsResult, String> {
    if work_function_ev <= 0.0 || wavelength_nm <= 0.0 {
        return Err("work function and wavelength must be strictly positive".to_string());
    }
    let h = 6.62607015e-34;
    let c = 299792458.0;
    let q_e = 1.602176634e-19;

    let lambda_m = wavelength_nm * 1e-9;
    let photon_energy_j = (h * c) / lambda_m;
    let photon_energy_ev = photon_energy_j / q_e;
    let work_function_j = work_function_ev * q_e;

    let cutoff_lambda_nm = (h * c / work_function_j) * 1e9;
    let electron_emission = photon_energy_ev > work_function_ev;

    let (k_max_ev, v_max_m_s, v_stopping) = if electron_emission {
        let k_ev = photon_energy_ev - work_function_ev;
        let k_j = k_ev * q_e;
        let m_e = 9.1093837015e-31;
        let v = (2.0 * k_j / m_e).sqrt();
        (k_ev, v, k_ev)
    } else {
        (0.0, 0.0, 0.0)
    };

    Ok(PhysicsResult {
        title: "Photoelectric Effect Analysis".to_string(),
        details: vec![
            ("Incident Wavelength".to_string(), format!("{:.2} nm", wavelength_nm)),
            ("Photon Energy (E_photon)".to_string(), format!("{:.4} eV", photon_energy_ev)),
            ("Work Function (Φ)".to_string(), format!("{:.4} eV", work_function_ev)),
            ("Cutoff Wavelength (λ_0)".to_string(), format!("{:.2} nm", cutoff_lambda_nm)),
            ("Photoelectric Emission".to_string(), if electron_emission { "ACTIVE (E_photon > Φ)".to_string() } else { "NO EMISSION (E_photon <= Φ)".to_string() }),
            ("Max Kinetic Energy (K_max)".to_string(), format!("{:.4} eV", k_max_ev)),
            ("Max Electron Velocity (v_max)".to_string(), format!("{:.4e} m/s", v_max_m_s)),
            ("Stopping Potential (V_0)".to_string(), format!("{:.4} V", v_stopping)),
        ],
        summary: if electron_emission {
            format!("Emission active: K_max = {:.4} eV, V_stop = {:.4} V, v_max = {:.2e} m/s", k_max_ev, v_stopping, v_max_m_s)
        } else {
            format!("Sub-threshold: E_photon ({:.2} eV) < Φ ({:.2} eV), no emission", photon_energy_ev, work_function_ev)
        },
        verified: true,
    })
}

/// Carnot Thermodynamic Heat Engine Efficiency: η = 1 - Tc / Th
pub fn calculate_carnot(th_k: f64, tc_k: f64) -> Result<PhysicsResult, String> {
    if th_k <= 0.0 || tc_k <= 0.0 {
        return Err("temperatures must be strictly positive absolute temperatures in Kelvin".to_string());
    }
    if tc_k >= th_k {
        return Err("hot reservoir Th must be strictly greater than cold reservoir Tc".to_string());
    }
    let efficiency = 1.0 - (tc_k / th_k);
    let efficiency_pct = efficiency * 100.0;
    let cop_refrigerator = tc_k / (th_k - tc_k);
    let cop_heat_pump = th_k / (th_k - tc_k);

    Ok(PhysicsResult {
        title: "Carnot Cycle Maximum Thermodynamic Efficiency".to_string(),
        details: vec![
            ("Hot Reservoir (Th)".to_string(), format!("{:.2} K ({:.2} °C)", th_k, th_k - 273.15)),
            ("Cold Reservoir (Tc)".to_string(), format!("{:.2} K ({:.2} °C)", tc_k, tc_k - 273.15)),
            ("Maximum Efficiency (η_carnot)".to_string(), format!("{:.6} ({:.2}%)", efficiency, efficiency_pct)),
            ("COP (Carnot Refrigerator)".to_string(), format!("{:.4}", cop_refrigerator)),
            ("COP (Carnot Heat Pump)".to_string(), format!("{:.4}", cop_heat_pump)),
        ],
        summary: format!("η_carnot = {:.2}% (Th = {:.1} K, Tc = {:.1} K)", efficiency_pct, th_k, tc_k),
        verified: true,
    })
}

/// Stefan-Boltzmann Blackbody Radiation & Wien's Displacement Law
pub fn calculate_blackbody(t_k: f64, area_m2: Option<f64>, emissivity: Option<f64>) -> Result<PhysicsResult, String> {
    if t_k <= 0.0 {
        return Err("temperature T must be strictly positive in Kelvin".to_string());
    }
    let sigma = 5.670374419e-8; // W/(m²·K⁴)
    let b_wien = 2.897771955e-3; // m·K (Wien displacement constant)
    let area = area_m2.unwrap_or(1.0);
    let eps = emissivity.unwrap_or(1.0).clamp(0.0, 1.0);

    let flux = eps * sigma * t_k.powi(4);
    let total_power = flux * area;
    let lambda_max_m = b_wien / t_k;
    let lambda_max_nm = lambda_max_m * 1e9;

    let spectral_region = if lambda_max_nm < 380.0 {
        "Ultraviolet"
    } else if lambda_max_nm <= 750.0 {
        "Visible Spectrum"
    } else if lambda_max_nm <= 10000.0 {
        "Near/Mid-Infrared"
    } else {
        "Far-Infrared / Microwave"
    };

    Ok(PhysicsResult {
        title: "Stefan-Boltzmann Radiation & Wien Displacement".to_string(),
        details: vec![
            ("Absolute Temperature (T)".to_string(), format!("{:.2} K ({:.2} °C)", t_k, t_k - 273.15)),
            ("Radiant Emittance / Flux (j*)".to_string(), format!("{:.6e} W/m²", flux)),
            ("Surface Area (A)".to_string(), format!("{:.4} m²", area)),
            ("Emissivity (ε)".to_string(), format!("{:.4}", eps)),
            ("Total Radiated Power (P)".to_string(), format!("{:.6e} W ({:.4} kW)", total_power, total_power * 1e-3)),
            ("Peak Wavelength (λ_max)".to_string(), format!("{:.6e} m ({:.2} nm)", lambda_max_m, lambda_max_nm)),
            ("Peak Spectral Region".to_string(), spectral_region.to_string()),
        ],
        summary: format!("P = {:.4e} W, λ_max = {:.1} nm ({})", total_power, lambda_max_nm, spectral_region),
        verified: true,
    })
}

/// Escape Velocity: v_esc = sqrt(2 * G * M / R)
pub fn calculate_escape_velocity(mass_kg: f64, radius_m: f64) -> Result<PhysicsResult, String> {
    if mass_kg <= 0.0 || radius_m <= 0.0 {
        return Err("mass and radius must be strictly positive".to_string());
    }
    let g = 6.67430e-11;
    let v_esc = (2.0 * g * mass_kg / radius_m).sqrt();
    let v_esc_km_s = v_esc / 1000.0;
    let v_orb = (g * mass_kg / radius_m).sqrt();
    let v_orb_km_s = v_orb / 1000.0;
    let surface_g = g * mass_kg / (radius_m * radius_m);

    Ok(PhysicsResult {
        title: "Gravitational Escape & Orbital Velocity".to_string(),
        details: vec![
            ("Body Mass (M)".to_string(), format!("{:.6e} kg", mass_kg)),
            ("Body Radius (R)".to_string(), format!("{:.6e} m ({:.2} km)", radius_m, radius_m / 1000.0)),
            ("Surface Gravity (g)".to_string(), format!("{:.4} m/s²", surface_g)),
            ("Circular Orbital Speed (v_orb)".to_string(), format!("{:.4e} m/s ({:.4} km/s)", v_orb, v_orb_km_s)),
            ("Escape Velocity (v_esc)".to_string(), format!("{:.4e} m/s ({:.4} km/s)", v_esc, v_esc_km_s)),
        ],
        summary: format!("v_esc = {:.2} km/s, v_orb = {:.2} km/s, g = {:.2} m/s²", v_esc_km_s, v_orb_km_s, surface_g),
        verified: true,
    })
}

/// Relativistic Lorentz Factor & Kinematics: γ = 1 / sqrt(1 - (v/c)²)
pub fn calculate_lorentz(v_m_s: f64) -> Result<PhysicsResult, String> {
    if v_m_s < 0.0 {
        return Err("velocity must be non-negative".to_string());
    }
    let c = 299792458.0;
    if v_m_s >= c {
        return Err("velocity must be strictly subluminal (< c)".to_string());
    }
    let beta = v_m_s / c;
    let gamma = 1.0 / (1.0 - beta * beta).sqrt();

    Ok(PhysicsResult {
        title: "Special Relativistic Lorentz Transformation".to_string(),
        details: vec![
            ("Velocity (v)".to_string(), format!("{:.6e} m/s", v_m_s)),
            ("Normalized Velocity (β = v/c)".to_string(), format!("{:.8}", beta)),
            ("Lorentz Factor (γ)".to_string(), format!("{:.8}", gamma)),
            ("Time Dilation Factor (Δt / Δt₀)".to_string(), format!("{:.8}", gamma)),
            ("Length Contraction Factor (L / L₀)".to_string(), format!("{:.8}", 1.0 / gamma)),
        ],
        summary: format!("γ = {:.6} (β = {:.6}, v = {:.4e} m/s)", gamma, beta, v_m_s),
        verified: true,
    })
}
