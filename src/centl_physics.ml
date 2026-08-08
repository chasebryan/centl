exception Physics_error of string

type dimension = {
  length : int;
  mass : int;
  time : int;
  current : int;
  temperature : int;
  amount : int;
  luminous_intensity : int;
}

let dimension ?(length = 0) ?(mass = 0) ?(time = 0) ?(current = 0)
    ?(temperature = 0) ?(amount = 0) ?(luminous_intensity = 0) () =
  { length; mass; time; current; temperature; amount; luminous_intensity }

let dim_dimensionless = dimension ()
let dim_length = dimension ~length:1 ()
let dim_mass = dimension ~mass:1 ()
let dim_time = dimension ~time:1 ()
let dim_current = dimension ~current:1 ()
let dim_temperature = dimension ~temperature:1 ()
let dim_amount = dimension ~amount:1 ()
let dim_luminous_intensity = dimension ~luminous_intensity:1 ()

let dim_mul a b =
  {
    length = a.length + b.length;
    mass = a.mass + b.mass;
    time = a.time + b.time;
    current = a.current + b.current;
    temperature = a.temperature + b.temperature;
    amount = a.amount + b.amount;
    luminous_intensity = a.luminous_intensity + b.luminous_intensity;
  }

let dim_pow d exponent =
  {
    length = d.length * exponent;
    mass = d.mass * exponent;
    time = d.time * exponent;
    current = d.current * exponent;
    temperature = d.temperature * exponent;
    amount = d.amount * exponent;
    luminous_intensity = d.luminous_intensity * exponent;
  }

let dim_div a b = dim_mul a (dim_pow b (-1))
let dim_equal a b = a = b
let dim_velocity = dim_div dim_length dim_time
let dim_acceleration = dim_div dim_velocity dim_time
let dim_force = dim_mul dim_mass dim_acceleration
let dim_energy = dim_mul dim_force dim_length
let dim_pressure = dim_div dim_force (dim_pow dim_length 2)
let dim_frequency = dim_pow dim_time (-1)
let dim_charge = dim_mul dim_current dim_time
let dim_power = dim_div dim_energy dim_time
let dim_voltage = dim_div dim_power dim_current
let dim_spring_constant = dim_div dim_force dim_length
let dim_linear_drag = dim_div dim_mass dim_time
let dim_momentum = dim_mul dim_mass dim_velocity

let dimension_to_string d =
  let term symbol exponent =
    if exponent = 0 then None
    else if exponent = 1 then Some symbol
    else Some (Printf.sprintf "%s^%d" symbol exponent)
  in
  let parts =
    [
      term "m" d.length;
      term "kg" d.mass;
      term "s" d.time;
      term "A" d.current;
      term "K" d.temperature;
      term "mol" d.amount;
      term "cd" d.luminous_intensity;
    ]
    |> List.filter_map (fun x -> x)
  in
  match parts with [] -> "1" | _ -> String.concat "*" parts

type unit_def = {
  name : string;
  symbol : string;
  unit_dimension : dimension;
  scale_to_si : Q.t;
}

let unit_def name symbol unit_dimension scale_to_si =
  { name; symbol; unit_dimension; scale_to_si = Q.of_string scale_to_si }

let unit_catalog =
  [
    unit_def "dimensionless" "1" dim_dimensionless "1";
    unit_def "metre" "m" dim_length "1";
    unit_def "centimetre" "cm" dim_length "1/100";
    unit_def "millimetre" "mm" dim_length "1/1000";
    unit_def "kilometre" "km" dim_length "1000";
    unit_def "second" "s" dim_time "1";
    unit_def "millisecond" "ms" dim_time "1/1000";
    unit_def "minute" "min" dim_time "60";
    unit_def "hour" "h" dim_time "3600";
    unit_def "kilogram" "kg" dim_mass "1";
    unit_def "gram" "g" dim_mass "1/1000";
    unit_def "ampere" "A" dim_current "1";
    unit_def "kelvin" "K" dim_temperature "1";
    unit_def "mole" "mol" dim_amount "1";
    unit_def "candela" "cd" dim_luminous_intensity "1";
    unit_def "metres per second" "m/s" dim_velocity "1";
    unit_def "metres per second squared" "m/s^2" dim_acceleration "1";
    unit_def "newton" "N" dim_force "1";
    unit_def "joule" "J" dim_energy "1";
    unit_def "pascal" "Pa" dim_pressure "1";
    unit_def "hertz" "Hz" dim_frequency "1";
    unit_def "coulomb" "C" dim_charge "1";
    unit_def "watt" "W" dim_power "1";
    unit_def "volt" "V" dim_voltage "1";
    unit_def "newtons per metre" "N/m" dim_spring_constant "1";
    unit_def "kilograms per second" "kg/s" dim_linear_drag "1";
    unit_def "joule second" "J*s" (dim_mul dim_energy dim_time) "1";
    unit_def "joules per kelvin" "J/K" (dim_div dim_energy dim_temperature) "1";
    unit_def "per mole" "1/mol" (dim_pow dim_amount (-1)) "1";
  ]

let unit_of_symbol symbol =
  List.find_opt (fun unit_def -> String.equal unit_def.symbol symbol) unit_catalog

let unit_exn symbol =
  match unit_of_symbol symbol with
  | Some unit_def -> unit_def
  | None -> raise (Physics_error ("unknown unit: " ^ symbol))

let require_dimension ~context ~expected actual =
  if not (dim_equal expected actual) then
    raise
      (Physics_error
         (Printf.sprintf "%s: expected dimension %s but got %s" context
            (dimension_to_string expected) (dimension_to_string actual)))

type quantity = { si_value : Q.t; quantity_dimension : dimension }

let quantity_of_si si_value quantity_dimension = { si_value; quantity_dimension }

let quantity value unit_symbol =
  let unit_def = unit_exn unit_symbol in
  quantity_of_si (Q.mul value unit_def.scale_to_si) unit_def.unit_dimension

let convert quantity unit_symbol =
  let unit_def = unit_exn unit_symbol in
  require_dimension ~context:("convert to " ^ unit_symbol)
    ~expected:unit_def.unit_dimension quantity.quantity_dimension;
  Q.div quantity.si_value unit_def.scale_to_si

let quantity_add a b =
  require_dimension ~context:"quantity addition" ~expected:a.quantity_dimension
    b.quantity_dimension;
  quantity_of_si (Q.add a.si_value b.si_value) a.quantity_dimension

let quantity_sub a b =
  require_dimension ~context:"quantity subtraction" ~expected:a.quantity_dimension
    b.quantity_dimension;
  quantity_of_si (Q.sub a.si_value b.si_value) a.quantity_dimension

let quantity_mul a b =
  quantity_of_si (Q.mul a.si_value b.si_value)
    (dim_mul a.quantity_dimension b.quantity_dimension)

let quantity_div a b =
  if Q.equal b.si_value Q.zero then raise (Physics_error "division by zero quantity");
  quantity_of_si (Q.div a.si_value b.si_value)
    (dim_div a.quantity_dimension b.quantity_dimension)

let quantity_scale factor q = quantity_of_si (Q.mul factor q.si_value) q.quantity_dimension
let quantity_neg q = quantity_scale Q.minus_one q

let quantity_to_string_as q unit_symbol =
  Printf.sprintf "%s %s" (Q.to_string (convert q unit_symbol)) unit_symbol

type vector3 = {
  x : Q.t;
  y : Q.t;
  z : Q.t;
  vector_dimension : dimension;
}

let vector_of_si ~dimension x y z = { x; y; z; vector_dimension = dimension }

let vector3 ~unit_symbol x y z =
  let unit_def = unit_exn unit_symbol in
  vector_of_si ~dimension:unit_def.unit_dimension
    (Q.mul x unit_def.scale_to_si)
    (Q.mul y unit_def.scale_to_si)
    (Q.mul z unit_def.scale_to_si)

let zero_vector dimension = vector_of_si ~dimension Q.zero Q.zero Q.zero

let vector_add a b =
  require_dimension ~context:"vector addition" ~expected:a.vector_dimension b.vector_dimension;
  vector_of_si ~dimension:a.vector_dimension (Q.add a.x b.x) (Q.add a.y b.y)
    (Q.add a.z b.z)

let vector_sub a b =
  require_dimension ~context:"vector subtraction" ~expected:a.vector_dimension b.vector_dimension;
  vector_of_si ~dimension:a.vector_dimension (Q.sub a.x b.x) (Q.sub a.y b.y)
    (Q.sub a.z b.z)

let vector_scale factor v =
  vector_of_si ~dimension:v.vector_dimension (Q.mul factor v.x) (Q.mul factor v.y)
    (Q.mul factor v.z)

let vector_neg v = vector_scale Q.minus_one v

let vector_times_quantity v q =
  vector_of_si ~dimension:(dim_mul v.vector_dimension q.quantity_dimension)
    (Q.mul v.x q.si_value) (Q.mul v.y q.si_value) (Q.mul v.z q.si_value)

let vector_div_quantity v q =
  if Q.equal q.si_value Q.zero then raise (Physics_error "vector division by zero quantity");
  vector_of_si ~dimension:(dim_div v.vector_dimension q.quantity_dimension)
    (Q.div v.x q.si_value) (Q.div v.y q.si_value) (Q.div v.z q.si_value)

let vector_dot a b =
  quantity_of_si
    (Q.add (Q.add (Q.mul a.x b.x) (Q.mul a.y b.y)) (Q.mul a.z b.z))
    (dim_mul a.vector_dimension b.vector_dimension)

let vector_cross a b =
  vector_of_si ~dimension:(dim_mul a.vector_dimension b.vector_dimension)
    (Q.sub (Q.mul a.y b.z) (Q.mul a.z b.y))
    (Q.sub (Q.mul a.z b.x) (Q.mul a.x b.z))
    (Q.sub (Q.mul a.x b.y) (Q.mul a.y b.x))

let vector_norm_squared v = vector_dot v v

let vector_to_string_as v unit_symbol =
  let unit_def = unit_exn unit_symbol in
  require_dimension ~context:("render vector in " ^ unit_symbol)
    ~expected:unit_def.unit_dimension v.vector_dimension;
  let scale component = Q.to_string (Q.div component unit_def.scale_to_si) in
  Printf.sprintf "%s,%s,%s" (scale v.x) (scale v.y) (scale v.z)

type physical_constant = {
  constant_name : string;
  constant_symbol : string;
  constant_value : quantity;
  display_unit : string;
  provenance : string;
  exact_value : bool;
}

let exact_constant name symbol value unit_symbol provenance =
  {
    constant_name = name;
    constant_symbol = symbol;
    constant_value = quantity (Q.of_string value) unit_symbol;
    display_unit = unit_symbol;
    provenance;
    exact_value = true;
  }

let physical_constants =
  [
    exact_constant "speed of light in vacuum" "c" "299792458" "m/s"
      "SI defining constant";
    exact_constant "Planck constant" "h" "6.62607015e-34" "J*s"
      "SI defining constant";
    exact_constant "elementary charge" "e" "1.602176634e-19" "C"
      "SI defining constant";
    exact_constant "Boltzmann constant" "k_B" "1.380649e-23" "J/K"
      "SI defining constant";
    exact_constant "Avogadro constant" "N_A" "6.02214076e23" "1/mol"
      "SI defining constant";
    exact_constant "standard acceleration of gravity" "g0" "9.80665" "m/s^2"
      "conventional standard value";
  ]

let constant symbol =
  match
    List.find_opt
      (fun constant -> String.equal constant.constant_symbol symbol)
      physical_constants
  with
  | Some constant -> constant
  | None -> raise (Physics_error ("unknown physical constant: " ^ symbol))

type particle = {
  id : string;
  mass : quantity;
  position : vector3;
  velocity : vector3;
}

let particle ~id ~mass ~position ~velocity =
  require_dimension ~context:"particle mass" ~expected:dim_mass mass.quantity_dimension;
  if Q.compare mass.si_value Q.zero <= 0 then
    raise (Physics_error "particle mass must be positive");
  require_dimension ~context:"particle position" ~expected:dim_length position.vector_dimension;
  require_dimension ~context:"particle velocity" ~expected:dim_velocity velocity.vector_dimension;
  { id; mass; position; velocity }

type force_model = particle -> vector3

let require_force context force =
  require_dimension ~context ~expected:dim_force force.vector_dimension;
  force

let constant_force force =
  let force = require_force "constant force" force in
  fun _particle -> force

let uniform_gravity acceleration =
  require_dimension ~context:"uniform gravity" ~expected:dim_acceleration
    acceleration.vector_dimension;
  fun particle ->
    vector_times_quantity acceleration particle.mass |> require_force "gravity force"

let hooke_force ~anchor ~stiffness =
  require_dimension ~context:"spring anchor" ~expected:dim_length anchor.vector_dimension;
  require_dimension ~context:"spring stiffness" ~expected:dim_spring_constant
    stiffness.quantity_dimension;
  fun particle ->
    let displacement = vector_sub particle.position anchor in
    vector_times_quantity displacement stiffness |> vector_neg
    |> require_force "spring force"

let linear_drag coefficient =
  require_dimension ~context:"linear drag coefficient" ~expected:dim_linear_drag
    coefficient.quantity_dimension;
  if Q.compare coefficient.si_value Q.zero < 0 then
    raise (Physics_error "linear drag coefficient must be non-negative");
  fun particle ->
    vector_times_quantity particle.velocity coefficient |> vector_neg
    |> require_force "linear drag force"

let net_force force_models particle =
  List.fold_left
    (fun total force_model -> vector_add total (force_model particle))
    (zero_vector dim_force) force_models

let acceleration force_models particle =
  vector_div_quantity (net_force force_models particle) particle.mass

let step_symplectic_euler ~dt ~forces particle =
  require_dimension ~context:"time step" ~expected:dim_time dt.quantity_dimension;
  if Q.compare dt.si_value Q.zero <= 0 then
    raise (Physics_error "time step must be positive");
  let a = acceleration forces particle in
  require_dimension ~context:"computed acceleration" ~expected:dim_acceleration
    a.vector_dimension;
  let velocity_delta = vector_times_quantity a dt in
  let velocity = vector_add particle.velocity velocity_delta in
  let position_delta = vector_times_quantity velocity dt in
  let position = vector_add particle.position position_delta in
  { particle with position; velocity }

let simulate ~steps ~dt ~forces initial =
  if steps < 0 then raise (Physics_error "simulation steps must be non-negative");
  if steps > 1_000_000 then
    raise (Physics_error "simulation steps exceed the 1000000-step safety limit");
  let rec loop remaining state acc =
    if remaining = 0 then List.rev (state :: acc)
    else
      let next = step_symplectic_euler ~dt ~forces state in
      loop (remaining - 1) next (state :: acc)
  in
  loop steps initial []

let final_state trajectory =
  match List.rev trajectory with
  | state :: _ -> state
  | [] -> raise (Physics_error "empty trajectory")

let momentum particle = vector_times_quantity particle.velocity particle.mass

let kinetic_energy particle =
  let speed_squared = vector_norm_squared particle.velocity in
  quantity_mul particle.mass speed_squared |> quantity_scale (Q.of_string "1/2")

let uniform_gravity_potential ~acceleration ~reference particle =
  require_dimension ~context:"uniform gravity potential acceleration"
    ~expected:dim_acceleration acceleration.vector_dimension;
  require_dimension ~context:"uniform gravity potential reference" ~expected:dim_length
    reference.vector_dimension;
  let displacement = vector_sub particle.position reference in
  quantity_mul particle.mass (vector_dot acceleration displacement) |> quantity_neg

let spring_potential ~anchor ~stiffness particle =
  require_dimension ~context:"spring potential anchor" ~expected:dim_length
    anchor.vector_dimension;
  require_dimension ~context:"spring potential stiffness" ~expected:dim_spring_constant
    stiffness.quantity_dimension;
  let displacement = vector_sub particle.position anchor in
  quantity_mul stiffness (vector_norm_squared displacement)
  |> quantity_scale (Q.of_string "1/2")

type invariant_report = {
  conserved : bool;
  initial : quantity;
  final : quantity;
  delta : quantity;
}

let compare_invariant ~initial ~final =
  require_dimension ~context:"invariant comparison" ~expected:initial.quantity_dimension
    final.quantity_dimension;
  let delta = quantity_sub final initial in
  { conserved = Q.equal delta.si_value Q.zero; initial; final; delta }

let elastic_collision_1d ~mass1 ~velocity1 ~mass2 ~velocity2 =
  require_dimension ~context:"collision mass1" ~expected:dim_mass mass1.quantity_dimension;
  require_dimension ~context:"collision mass2" ~expected:dim_mass mass2.quantity_dimension;
  require_dimension ~context:"collision velocity1" ~expected:dim_velocity
    velocity1.quantity_dimension;
  require_dimension ~context:"collision velocity2" ~expected:dim_velocity
    velocity2.quantity_dimension;
  if Q.compare mass1.si_value Q.zero <= 0 || Q.compare mass2.si_value Q.zero <= 0 then
    raise (Physics_error "collision masses must be positive");
  let m1 = mass1.si_value in
  let m2 = mass2.si_value in
  let v1 = velocity1.si_value in
  let v2 = velocity2.si_value in
  let total_mass = Q.add m1 m2 in
  let v1_final =
    Q.add
      (Q.mul (Q.div (Q.sub m1 m2) total_mass) v1)
      (Q.mul (Q.div (Q.mul (Q.of_int 2) m2) total_mass) v2)
  in
  let v2_final =
    Q.add
      (Q.mul (Q.div (Q.mul (Q.of_int 2) m1) total_mass) v1)
      (Q.mul (Q.div (Q.sub m2 m1) total_mass) v2)
  in
  (quantity_of_si v1_final dim_velocity, quantity_of_si v2_final dim_velocity)
