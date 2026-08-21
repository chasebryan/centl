// CENTL26 Example Catalog & STEM Reference Dataset
// Free Computation Foundation - Apache-2.0

pub struct StemExample {
    pub domain: &'static str,
    pub category: &'static str,
    pub command: &'static str,
    pub input_example: &'static str,
    pub description: &'static str,
    pub expected_result: &'static str,
    pub exactness_guarantee: &'static str,
}

pub static STEM_EXAMPLES: &[StemExample] = &[
    // --- Exact Mathematics & Arithmetic ---
    StemExample {
        domain: "Mathematics",
        category: "Exact Arithmetic",
        command: "0.1 + 0.2",
        input_example: "0.1 + 0.2",
        description: "Exact rational addition without IEEE-754 floating-point degradation.",
        expected_result: "3/10",
        exactness_guarantee: "Exact Rational",
    },
    StemExample {
        domain: "Mathematics",
        category: "Exact Arithmetic",
        command: "(1/3 + 5/7) * (14/11)",
        input_example: "(1/3 + 5/7) * (14/11)",
        description: "Exact fraction arithmetic with arbitrary precision.",
        expected_result: "44/33 -> 4/3 simplified rational",
        exactness_guarantee: "Exact Rational",
    },
    StemExample {
        domain: "Mathematics",
        category: "Large Integer Arithmetic",
        command: "2^64",
        input_example: "2^64",
        description: "Arbitrary-precision integer exponentiation beyond 64-bit integer limits.",
        expected_result: "18446744073709551616",
        exactness_guarantee: "Exact BigInt",
    },
    StemExample {
        domain: "Mathematics",
        category: "Rigorous Enclosure",
        command: "approx(pi, 50)",
        input_example: "approx(pi, 50)",
        description: "Arb-backed rigorous interval enclosure approximation for Pi with 50 justified digits.",
        expected_result: "3.14159265358979323846264338327950288419716939937510",
        exactness_guarantee: "Rigorous Interval Enclosure",
    },
    StemExample {
        domain: "Mathematics",
        category: "Rigorous Enclosure",
        command: "approx(sqrt(2), 60)",
        input_example: "approx(sqrt(2), 60)",
        description: "Rigorous interval enclosure for the square root of 2.",
        expected_result: "1.414213562373095048801688724209698078569671875376948073176679...",
        exactness_guarantee: "Rigorous Interval Enclosure",
    },

    // --- Symbolic Calculus ---
    StemExample {
        domain: "Calculus",
        category: "Symbolic Differentiation",
        command: "diff(x^3 * sin(x), x)",
        input_example: "diff(x^3 * sin(x), x)",
        description: "Exact symbolic differentiation applying product and trigonometric chain rules.",
        expected_result: "3 * x^2 * sin(x) + x^3 * cos(x)",
        exactness_guarantee: "Exact Symbolic",
    },
    StemExample {
        domain: "Calculus",
        category: "Definite Integration",
        command: "integrate(3*x^2 + 2*x, x, 0, 5)",
        input_example: "integrate(3*x^2 + 2*x, x, 0, 5)",
        description: "Definite integral evaluated strictly over exact rational bounds via Fundamental Theorem of Calculus.",
        expected_result: "150",
        exactness_guarantee: "Exact Rational",
    },
    StemExample {
        domain: "Calculus",
        category: "Indefinite Integration",
        command: "integrate(cos(x), x)",
        input_example: "integrate(cos(x), x)",
        description: "Symbolic antiderivative of trigonometric function.",
        expected_result: "sin(x) + C",
        exactness_guarantee: "Exact Symbolic",
    },

    // --- Symbolic Algebra ---
    StemExample {
        domain: "Algebra",
        category: "Equation Solving",
        command: "solve(3*x - 12 = 0, x)",
        input_example: "solve(3*x - 12 = 0, x)",
        description: "Symbolic linear equation solving.",
        expected_result: "x = 4",
        exactness_guarantee: "Exact Algebraic",
    },
    StemExample {
        domain: "Algebra",
        category: "Polynomial Expansion",
        command: "expand((x + 2) * (x - 3))",
        input_example: "expand((x + 2) * (x - 3))",
        description: "Algebraic expansion and polynomial simplification.",
        expected_result: "x^2 - x - 6",
        exactness_guarantee: "Exact Symbolic",
    },
    StemExample {
        domain: "Algebra",
        category: "Polynomial Factorization",
        command: "factor(x^2 - 9, x)",
        input_example: "factor(x^2 - 9, x)",
        description: "Polynomial factorization into irreducible factors.",
        expected_result: "(x - 3) * (x + 3)",
        exactness_guarantee: "Exact Symbolic",
    },
    StemExample {
        domain: "Algebra",
        category: "Identity Assertion",
        command: "assert(sin(x)^2 + cos(x)^2 = 1)",
        input_example: "assert(sin(x)^2 + cos(x)^2 = 1)",
        description: "Formal mathematical identity verification.",
        expected_result: "assert(...): verified",
        exactness_guarantee: "Formal Prover",
    },

    // --- Combinatorics & Number Theory ---
    StemExample {
        domain: "Number Theory",
        category: "Combinatorics",
        command: "choose(52, 5)",
        input_example: "choose(52, 5)",
        description: "Binomial coefficient nCr (e.g. 5-card poker hands from a 52-card deck).",
        expected_result: "2598960",
        exactness_guarantee: "Exact BigInt",
    },
    StemExample {
        domain: "Number Theory",
        category: "Factorial",
        command: "factorial(20)",
        input_example: "factorial(20)",
        description: "Arbitrary-precision integer factorial calculation.",
        expected_result: "2432902008176640000",
        exactness_guarantee: "Exact BigInt",
    },
    StemExample {
        domain: "Number Theory",
        category: "Fibonacci Numbers",
        command: "fibonacci(50)",
        input_example: "fibonacci(50)",
        description: "Arbitrary-precision Fibonacci sequence evaluation.",
        expected_result: "12586269025",
        exactness_guarantee: "Exact BigInt",
    },
    StemExample {
        domain: "Number Theory",
        category: "Greatest Common Divisor",
        command: "gcd(123456789, 987654321)",
        input_example: "gcd(123456789, 987654321)",
        description: "Euclidean algorithm for exact greatest common divisor.",
        expected_result: "9",
        exactness_guarantee: "Exact Integer",
    },
    StemExample {
        domain: "Number Theory",
        category: "Prime Factorization",
        command: "prime_factors(123456789)",
        input_example: "prime_factors(123456789)",
        description: "Canonical prime factorization of positive integers.",
        expected_result: "3^2 * 3607 * 3803",
        exactness_guarantee: "Deterministic Factorization",
    },
    StemExample {
        domain: "Number Theory",
        category: "Primality Testing",
        command: "is_prime(104729)",
        input_example: "is_prime(104729)",
        description: "Deterministic primality test for integers.",
        expected_result: "true",
        exactness_guarantee: "Deterministic Primality",
    },

    // --- Exact Chemistry ---
    StemExample {
        domain: "Chemistry",
        category: "Atom Counting",
        command: "atoms Ca(OH)2",
        input_example: "atoms Ca(OH)2",
        description: "Exact atom counting with nested parenthesized radicals (auto-detected).",
        expected_result: "Ca=1, H=2, O=2",
        exactness_guarantee: "Exact Integer",
    },
    StemExample {
        domain: "Chemistry",
        category: "Atom Counting",
        command: "atoms Al2(SO4)3",
        input_example: "atoms Al2(SO4)3",
        description: "Multi-element sulfate radical expansion.",
        expected_result: "Al=2, O=12, S=3",
        exactness_guarantee: "Exact Integer",
    },
    StemExample {
        domain: "Chemistry",
        category: "Reaction Balancing",
        command: "balance Fe + O2 -> Fe2O3",
        input_example: "balance Fe + O2 -> Fe2O3",
        description: "Exact rational nullspace matrix reaction balancing (auto-detected).",
        expected_result: "4 Fe + 3 O2 -> 2 Fe2O3",
        exactness_guarantee: "Exact Rational Nullspace",
    },
    StemExample {
        domain: "Chemistry",
        category: "Direct Reaction Balancing",
        command: "C6H12O6 + O2 -> CO2 + H2O",
        input_example: "C6H12O6 + O2 -> CO2 + H2O",
        description: "Direct chemical equation balancing without typing 'chem' or 'balance'.",
        expected_result: "C6H12O6 + 6 O2 -> 6 CO2 + 6 H2O",
        exactness_guarantee: "Exact Rational Nullspace",
    },
    StemExample {
        domain: "Chemistry",
        category: "Redox Reaction Balancing",
        command: "balance KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2",
        input_example: "balance KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2",
        description: "Complex multi-species redox reaction balancing.",
        expected_result: "2 KMnO4 + 16 HCl -> 2 KCl + 2 MnCl2 + 8 H2O + 5 Cl2",
        exactness_guarantee: "Exact Rational Nullspace",
    },
    StemExample {
        domain: "Chemistry",
        category: "Avogadro Conversion",
        command: "particles exact 1",
        input_example: "particles exact 1",
        description: "Exact entity count for 1 mole using the 2019 SI defining Avogadro constant.",
        expected_result: "602214076000000000000000 specified entities",
        exactness_guarantee: "Exact SI 2019 Definition",
    },
    StemExample {
        domain: "Chemistry",
        category: "Mole Calculation",
        command: "moles 602214076000000000000000",
        input_example: "moles 602214076000000000000000",
        description: "Convert exact particle count back to moles.",
        expected_result: "1 mol",
        exactness_guarantee: "Exact Rational",
    },
    StemExample {
        domain: "Chemistry",
        category: "Stoichiometry",
        command: "stoich measured 'C2H6 + O2 -> CO2 + H2O' C2H6 3 CO2",
        input_example: "stoich measured 'C2H6 + O2 -> CO2 + H2O' C2H6 3 CO2",
        description: "Stoichiometric yield calculation (amount of CO2 produced from 3 mol C2H6).",
        expected_result: "6 mol CO2",
        exactness_guarantee: "Exact Stoichiometric Vector",
    },
    StemExample {
        domain: "Chemistry",
        category: "Limiting Reactant",
        command: "limiting '2 H2 + O2 -> 2 H2O' H2 5 O2 2",
        input_example: "limiting '2 H2 + O2 -> 2 H2O' H2 5 O2 2",
        description: "Determine limiting and excess reactants.",
        expected_result: "Limiting reactant: O2 (produces 4 mol H2O, 1 mol H2 remaining)",
        exactness_guarantee: "Exact Rational Comparison",
    },
    StemExample {
        domain: "Chemistry",
        category: "Sample Spread Statistics",
        command: "spread g 10.02 10.05 10.01 10.08",
        input_example: "spread g 10.02 10.05 10.01 10.08",
        description: "Descriptive sample spread statistics preserving rational variance and exact symbolic bounds.",
        expected_result: "Mean = 10.04 g, exact sample variance",
        exactness_guarantee: "Exact Over Reported Values",
    },

    // --- Physics & Physical Quantities ---
    StemExample {
        domain: "Physics",
        category: "Unit Conversion",
        command: "convert 100 cm m",
        input_example: "convert 100 cm m",
        description: "Exact physical unit conversion (auto-detected).",
        expected_result: "1 m",
        exactness_guarantee: "Exact Rational Dimensional Analysis",
    },
    StemExample {
        domain: "Physics",
        category: "Pressure Conversion",
        command: "convert 1 atm Pa",
        input_example: "convert 1 atm Pa",
        description: "Standard atmosphere to SI Pascals.",
        expected_result: "101325 Pa",
        exactness_guarantee: "Exact SI Definition",
    },
    StemExample {
        domain: "Physics",
        category: "Physical Constants",
        command: "constant c",
        input_example: "constant c",
        description: "Look up speed of light in vacuum with SI provenance.",
        expected_result: "c = 299792458 m/s (Exact definition)",
        exactness_guarantee: "Authoritative SI Catalog",
    },
    StemExample {
        domain: "Physics",
        category: "Physical Constants",
        command: "constant h",
        input_example: "constant h",
        description: "Planck's constant defining value.",
        expected_result: "h = 6.62607015e-34 J s (Exact SI 2019)",
        exactness_guarantee: "Authoritative SI Catalog",
    },
    StemExample {
        domain: "Physics",
        category: "Physical Constants",
        command: "constant G",
        input_example: "constant G",
        description: "Newtonian constant of gravitation with measured uncertainty.",
        expected_result: "G = 6.67430e-11 m^3/(kg s^2) (CODATA)",
        exactness_guarantee: "CODATA Measured with Uncertainty",
    },
    StemExample {
        domain: "Physics",
        category: "Relativistic Kinematics",
        command: "cherenkov 1.33 2.5e8",
        input_example: "cherenkov 1.33 2.5e8",
        description: "Cherenkov radiation emission angle in water (n=1.33) at particle velocity 2.5e8 m/s.",
        expected_result: "Cherenkov emission angle theta ~ 25.4 deg",
        exactness_guarantee: "Relativistic Phase-Velocity Formula",
    },
    StemExample {
        domain: "Physics",
        category: "1D Collision Simulation",
        command: "collision m1=2.5 v1=10 m2=1.5 v2=-5 e=0.8",
        input_example: "collision m1=2.5 v1=10 m2=1.5 v2=-5 e=0.8",
        description: "1D momentum & kinetic energy collision simulation with restitution coefficient e=0.8.",
        expected_result: "Final velocities v1_prime, v2_prime and kinetic energy loss",
        exactness_guarantee: "Exact Momentum & Restitution System",
    },
    StemExample {
        domain: "Physics",
        category: "Gravitational Trajectory",
        command: "gravity m=10 p=0,0,100 v=15,0,0 dt=0.01 steps=500",
        input_example: "gravity m=10 p=0,0,100 v=15,0,0 dt=0.01 steps=500",
        description: "Numerical kinematic integration under gravitational acceleration.",
        expected_result: "Time of flight, impact coordinates, and trajectory profile",
        exactness_guarantee: "Symplectic Numerical Integration",
    },

    // --- Erdős–Straus Research ---
    StemExample {
        domain: "Number Theory",
        category: "Erdős–Straus Diophantine",
        command: "es solve 2521",
        input_example: "es solve 2521",
        description: "Decompose 4/p = 1/x + 1/y + 1/z for prime p = 2521.",
        expected_result: "4/2521 = 1/x + 1/y + 1/z witness decomposition with search grade & layer",
        exactness_guarantee: "Exact Diophantine Witness",
    },
    StemExample {
        domain: "Number Theory",
        category: "Erdős–Straus Hunt",
        command: "es hunt 20000",
        input_example: "es hunt 20000",
        description: "Run public Erdős–Straus prime search window and inspect density.",
        expected_result: "Hunt window summary with classified witness statistics",
        exactness_guarantee: "Deterministic Search Window",
    },

    // --- Chemical Process Systems (CPS) ---
    StemExample {
        domain: "CPS",
        category: "Process Preflight",
        command: "preflight exact CH4=2 O2=4",
        input_example: "preflight exact CH4=2 O2=4",
        description: "Chemical Process Systems preflight validation for multi-species feed.",
        expected_result: "CPS Preflight: composition validated (2 species, 6 total mol).",
        exactness_guarantee: "Exact Conservation Contract",
    },

    // --- Plain-English SCi Problem Sets ---
    StemExample {
        domain: "SCi Natural Language",
        category: "Plain English Chemistry",
        command: "What is the molar mass of Ca(OH)2?",
        input_example: "What is the molar mass of Ca(OH)2?",
        description: "Plain English natural language question solved by native offline SCi interpreter.",
        expected_result: "Step-by-step breakdown: Ca(OH)2 -> 74.093 g/mol",
        exactness_guarantee: "Exact Atomic Weights IUPAC",
    },
    StemExample {
        domain: "SCi Natural Language",
        category: "Plain English Calculus",
        command: "Find the derivative of x^4 * cos(x) with respect to x",
        input_example: "Find the derivative of x^4 * cos(x) with respect to x",
        description: "Natural language calculus query evaluated symbolically.",
        expected_result: "4 * x^3 * cos(x) - x^4 * sin(x)",
        exactness_guarantee: "Exact Symbolic",
    },
    StemExample {
        domain: "SCi Natural Language",
        category: "Plain English Physics",
        command: "Convert 100 kilometers per hour to meters per second",
        input_example: "Convert 100 kilometers per hour to meters per second",
        description: "Natural language unit conversion question.",
        expected_result: "100 km/h = 250/9 m/s (~27.778 m/s)",
        exactness_guarantee: "Exact Rational Conversion",
    },

    // --- Quantum Physics ---
    StemExample {
        domain: "Physics",
        category: "Quantum Physics",
        command: "physics debroglie 9.10938e-31 2.187e6",
        input_example: "physics debroglie 9.10938e-31 2.187e6",
        description: "De Broglie matter wavelength for an electron in Bohr orbit.",
        expected_result: "λ = 3.3249e-10 m (0.3325 nm)",
        exactness_guarantee: "Deterministic SI Formulation",
    },
    StemExample {
        domain: "Physics",
        category: "Quantum Physics",
        command: "physics photon 500",
        input_example: "physics photon 500",
        description: "Photon energy and momentum for 500 nm green light.",
        expected_result: "E = 2.4796 eV (3.972e-19 J), f = 5.996e14 Hz",
        exactness_guarantee: "Exact SI Constants",
    },
    StemExample {
        domain: "Physics",
        category: "Quantum Spectroscopy",
        command: "physics rydberg 2 3 1",
        input_example: "physics rydberg 2 3 1",
        description: "Hydrogen Balmer-alpha red spectral line transition wavelength (n=3 -> n=2).",
        expected_result: "λ = 656.47 nm (1.889 eV, Balmer Series)",
        exactness_guarantee: "Rydberg Formula Exact",
    },
    StemExample {
        domain: "Physics",
        category: "Quantum Physics",
        command: "physics photoelectric 2.3 400",
        input_example: "physics photoelectric 2.3 400",
        description: "Photoelectric effect stopping potential and kinetic energy for potassium metal.",
        expected_result: "K_max = 0.7996 eV, V_stop = 0.7996 V",
        exactness_guarantee: "Exact Conservation",
    },

    // --- Thermodynamics & Astrophysics ---
    StemExample {
        domain: "Physics",
        category: "Thermodynamics",
        command: "physics carnot 600 300",
        input_example: "physics carnot 600 300",
        description: "Carnot maximum theoretical thermodynamic efficiency between 600 K and 300 K.",
        expected_result: "η_carnot = 50.00% (COP_refrig = 1.0000)",
        exactness_guarantee: "Exact Thermodynamic Limit",
    },
    StemExample {
        domain: "Physics",
        category: "Radiation Physics",
        command: "physics blackbody 5778 1.0 1.0",
        input_example: "physics blackbody 5778 1.0 1.0",
        description: "Stefan-Boltzmann total radiated power flux and Wien peak wavelength for solar surface.",
        expected_result: "P = 6.32e7 W/m², λ_max = 501.5 nm (Visible Spectrum)",
        exactness_guarantee: "CODATA Stefan-Boltzmann Law",
    },
    StemExample {
        domain: "Physics",
        category: "Astrophysics",
        command: "physics escape 5.9722e24 6.371e6",
        input_example: "physics escape 5.9722e24 6.371e6",
        description: "Earth gravitational escape velocity and circular low-orbit speed.",
        expected_result: "v_esc = 11.19 km/s, v_orb = 7.91 km/s, g = 9.82 m/s²",
        exactness_guarantee: "Newtonian Gravitation",
    },
    StemExample {
        domain: "Physics",
        category: "Special Relativity",
        command: "physics lorentz 2.4e8",
        input_example: "physics lorentz 2.4e8",
        description: "Relativistic Lorentz factor (gamma) and time dilation factor at 80% speed of light.",
        expected_result: "γ = 1.6653 (β = 0.8005, v = 2.40e8 m/s)",
        exactness_guarantee: "Exact Relativistic Kinematics",
    },

    // --- Linear Algebra & Vector Calculus ---
    StemExample {
        domain: "Mathematics",
        category: "Linear Algebra",
        command: "det2(4, 7, 2, 6)",
        input_example: "det2(4, 7, 2, 6)",
        description: "Exact 2x2 matrix determinant calculation (4*6 - 7*2).",
        expected_result: "10",
        exactness_guarantee: "Exact Integer",
    },
    StemExample {
        domain: "Mathematics",
        category: "Linear Algebra",
        command: "inv2(4, 7, 2, 6)",
        input_example: "inv2(4, 7, 2, 6)",
        description: "Exact 2x2 matrix inverse.",
        expected_result: "[[0.600000, -0.700000], [-0.200000, 0.400000]]",
        exactness_guarantee: "Exact Determinant Division",
    },
    StemExample {
        domain: "Mathematics",
        category: "Vector Calculus",
        command: "cross(1, 0, 0, 0, 1, 0)",
        input_example: "cross(1, 0, 0, 0, 1, 0)",
        description: "3D vector cross product i × j = k.",
        expected_result: "(0.000000, 0.000000, 1.000000)",
        exactness_guarantee: "Exact 3D Vector Geometry",
    },
    StemExample {
        domain: "Mathematics",
        category: "Vector Calculus",
        command: "dot(1, 2, 3, 4, 5, 6)",
        input_example: "dot(1, 2, 3, 4, 5, 6)",
        description: "3D vector dot product (1*4 + 2*5 + 3*6).",
        expected_result: "32",
        exactness_guarantee: "Exact Rational",
    },

    // --- Extended Number Theory ---
    StemExample {
        domain: "Mathematics",
        category: "Number Theory",
        command: "xgcd(240, 46)",
        input_example: "xgcd(240, 46)",
        description: "Extended Euclidean Algorithm for Bezout coefficients a*x + b*y = gcd(a,b).",
        expected_result: "gcd = 2, x = -9, y = 47 (240*-9 + 46*47 = 2)",
        exactness_guarantee: "Exact Euclidean Algorithm",
    },
    StemExample {
        domain: "Mathematics",
        category: "Number Theory",
        command: "modinv(3, 11)",
        input_example: "modinv(3, 11)",
        description: "Modular multiplicative inverse (3 * 4 = 12 ≡ 1 mod 11).",
        expected_result: "4",
        exactness_guarantee: "Exact Modular Arithmetic",
    },
    StemExample {
        domain: "Mathematics",
        category: "Number Theory",
        command: "totient(36)",
        input_example: "totient(36)",
        description: "Euler's totient function phi(36) = 36 * (1-1/2) * (1-1/3).",
        expected_result: "12",
        exactness_guarantee: "Exact Euler Totient",
    },

    // --- Statistics & Probability ---
    StemExample {
        domain: "Mathematics",
        category: "Statistics",
        command: "mean(10, 20, 30, 40, 50)",
        input_example: "mean(10, 20, 30, 40, 50)",
        description: "Sample arithmetic mean.",
        expected_result: "30.00000000",
        exactness_guarantee: "Exact Rational Mean",
    },
    StemExample {
        domain: "Mathematics",
        category: "Statistics",
        command: "stddev(2, 4, 4, 4, 5, 5, 7, 9)",
        input_example: "stddev(2, 4, 4, 4, 5, 5, 7, 9)",
        description: "Sample standard deviation.",
        expected_result: "2.13808993",
        exactness_guarantee: "Rigorous Unbiased Variance",
    },

    // --- 2D Function Plotting ---
    StemExample {
        domain: "Visualization",
        category: "Function Plotting",
        command: "plot sin(x) from -3.14 to 3.14",
        input_example: "plot sin(x) from -3.14 to 3.14",
        description: "Generates a clean 2D ASCII Unicode function plot in the notebook feed.",
        expected_result: "2D ASCII Function Plot with domain/range axes and discrete markers",
        exactness_guarantee: "Deterministic Sampling Grid",
    },
    StemExample {
        domain: "Visualization",
        category: "Function Plotting",
        command: "plot x^2 - 4 from -4 to 4",
        input_example: "plot x^2 - 4 from -4 to 4",
        description: "2D quadratic parabola curve plot.",
        expected_result: "2D Parabola Plot with vertex and root markers",
        exactness_guarantee: "Deterministic Sampling Grid",
    },

    // --- Hybrid Gemini STEM Workflows ---
    StemExample {
        domain: "Gemini Hybrid",
        category: "Multi-Step STEM Problem",
        command: ":gemini Solve the combustion of propane C3H8 + O2 and determine moles of CO2 from 5 moles of C3H8",
        input_example: ":gemini Solve the combustion of propane C3H8 + O2 and determine moles of CO2 from 5 moles of C3H8",
        description: "Multi-step STEM word problem translated by Gemini and strictly verified by CentL exact kernel.",
        expected_result: "Balanced: C3H8 + 5 O2 -> 3 CO2 + 4 H2O; Yield: 15 mol CO2 (exact)",
        exactness_guarantee: "Verified (Gemini + CentL Exact Kernel)",
    },
];

pub fn generate_examples_csv() -> String {
    let mut csv = String::from("Domain,Category,Command,Input Example,Description,Expected Result/Behavior,Exactness Guarantee\r\n");
    for ex in STEM_EXAMPLES {
        csv.push_str(&format!(
            "\"{}\",\"{}\",\"{}\",\"{}\",\"{}\",\"{}\",\"{}\"\r\n",
            escape_csv(ex.domain),
            escape_csv(ex.category),
            escape_csv(ex.command),
            escape_csv(ex.input_example),
            escape_csv(ex.description),
            escape_csv(ex.expected_result),
            escape_csv(ex.exactness_guarantee)
        ));
    }
    csv
}

pub fn generate_examples_tsv() -> String {
    let mut tsv = String::from("Domain\tCategory\tCommand\tInput Example\tDescription\tExpected Result/Behavior\tExactness Guarantee\n");
    for ex in STEM_EXAMPLES {
        tsv.push_str(&format!(
            "{}\t{}\t{}\t{}\t{}\t{}\t{}\n",
            escape_tsv(ex.domain),
            escape_tsv(ex.category),
            escape_tsv(ex.command),
            escape_tsv(ex.input_example),
            escape_tsv(ex.description),
            escape_tsv(ex.expected_result),
            escape_tsv(ex.exactness_guarantee)
        ));
    }
    tsv
}

fn escape_csv(s: &str) -> String {
    s.replace('"', "\"\"")
}

fn escape_tsv(s: &str) -> String {
    s.replace('\t', " ").replace('\n', " ").replace('\r', "")
}
