module Centl.Physics

module Core = Centl.Core

(** CENTL Physics stage 1: exact dimensions, multiplicative units, and
    canonical rational quantities.  This module deliberately excludes affine
    units, vectors, simulation state, and ODE semantics. *)

type dimension = {
  length_exp: int;
  mass_exp: int;
  time_exp: int;
  current_exp: int;
  temperature_exp: int;
  amount_exp: int;
  luminosity_exp: int
}

let dimensionless : dimension = {
  length_exp = 0;
  mass_exp = 0;
  time_exp = 0;
  current_exp = 0;
  temperature_exp = 0;
  amount_exp = 0;
  luminosity_exp = 0
}

let length_dimension : dimension =
  { dimensionless with length_exp = 1 }

let mass_dimension : dimension =
  { dimensionless with mass_exp = 1 }

let time_dimension : dimension =
  { dimensionless with time_exp = 1 }

let current_dimension : dimension =
  { dimensionless with current_exp = 1 }

let temperature_dimension : dimension =
  { dimensionless with temperature_exp = 1 }

let amount_dimension : dimension =
  { dimensionless with amount_exp = 1 }

let luminosity_dimension : dimension =
  { dimensionless with luminosity_exp = 1 }

let dimension_equal (left right:dimension) : Tot bool =
  left.length_exp = right.length_exp &&
  left.mass_exp = right.mass_exp &&
  left.time_exp = right.time_exp &&
  left.current_exp = right.current_exp &&
  left.temperature_exp = right.temperature_exp &&
  left.amount_exp = right.amount_exp &&
  left.luminosity_exp = right.luminosity_exp

let dimension_multiply (left right:dimension) : Tot dimension = {
  length_exp = left.length_exp + right.length_exp;
  mass_exp = left.mass_exp + right.mass_exp;
  time_exp = left.time_exp + right.time_exp;
  current_exp = left.current_exp + right.current_exp;
  temperature_exp = left.temperature_exp + right.temperature_exp;
  amount_exp = left.amount_exp + right.amount_exp;
  luminosity_exp = left.luminosity_exp + right.luminosity_exp
}

let dimension_divide (left right:dimension) : Tot dimension = {
  length_exp = left.length_exp - right.length_exp;
  mass_exp = left.mass_exp - right.mass_exp;
  time_exp = left.time_exp - right.time_exp;
  current_exp = left.current_exp - right.current_exp;
  temperature_exp = left.temperature_exp - right.temperature_exp;
  amount_exp = left.amount_exp - right.amount_exp;
  luminosity_exp = left.luminosity_exp - right.luminosity_exp
}

let dimension_power (value:dimension) (exponent:int) : Tot dimension = {
  length_exp = value.length_exp * exponent;
  mass_exp = value.mass_exp * exponent;
  time_exp = value.time_exp * exponent;
  current_exp = value.current_exp * exponent;
  temperature_exp = value.temperature_exp * exponent;
  amount_exp = value.amount_exp * exponent;
  luminosity_exp = value.luminosity_exp * exponent
}

let dimension_even (value:dimension) : Tot bool =
  value.length_exp % 2 = 0 &&
  value.mass_exp % 2 = 0 &&
  value.time_exp % 2 = 0 &&
  value.current_exp % 2 = 0 &&
  value.temperature_exp % 2 = 0 &&
  value.amount_exp % 2 = 0 &&
  value.luminosity_exp % 2 = 0

(** [dimension_square_root] refuses a root whose dimensions would require
    fractional exponents. *)
let dimension_square_root (value:dimension) : Tot (option dimension) =
  if dimension_even value then
    Some {
      length_exp = value.length_exp / 2;
      mass_exp = value.mass_exp / 2;
      time_exp = value.time_exp / 2;
      current_exp = value.current_exp / 2;
      temperature_exp = value.temperature_exp / 2;
      amount_exp = value.amount_exp / 2;
      luminosity_exp = value.luminosity_exp / 2
    }
  else None

type exact_scalar = value:Core.rational{Core.invariant value}

type unit = {
  unit_symbol: string;
  unit_dimension: dimension;
  unit_scale: exact_scalar
}

let unit_valid (value:unit) : Tot bool =
  value.unit_scale.numerator > 0

(** Quantity magnitudes are always canonical SI magnitudes.  [preferred_unit]
    affects presentation only and never changes [magnitude]. *)
type quantity = {
  magnitude: exact_scalar;
  quantity_dimension: dimension;
  preferred_unit: string
}

type quantity_result =
  | QuantityOk: quantity -> quantity_result
  | DimensionMismatch
  | DivisionByZero
  | InvalidUnit
  | UndefinedPower
  | InvalidSquareRoot
  | NonDimensionlessArgument

(** Built-in and verified units have strictly positive exact scales.  Host
    parsers that accept user-defined units must call [quantity_of_unit_checked]
    rather than constructing canonical quantities directly. *)
let quantity_of_unit (value:exact_scalar) (source:unit) : Tot quantity = {
  magnitude = Core.multiply value source.unit_scale;
  quantity_dimension = source.unit_dimension;
  preferred_unit = source.unit_symbol
}

let quantity_of_unit_checked (value:exact_scalar) (source:unit)
  : Tot quantity_result
=
  if unit_valid source then QuantityOk (quantity_of_unit value source)
  else InvalidUnit

(** Conversion returns the exact scalar expressed in [target].  The source
    quantity itself remains canonical and unchanged. *)
let quantity_in_unit (value:quantity) (target:unit)
  : Tot (option exact_scalar)
=
  if not (unit_valid target) then None
  else if not (dimension_equal value.quantity_dimension target.unit_dimension)
  then None
  else
    match Core.divide value.magnitude target.unit_scale with
    | Core.Success converted -> Some converted
    | Core.Failure _ -> None

let prefer_unit (value:quantity) (target:unit) : Tot quantity_result =
  if not (unit_valid target) then InvalidUnit
  else if dimension_equal value.quantity_dimension target.unit_dimension then
    QuantityOk { value with preferred_unit = target.unit_symbol }
  else DimensionMismatch

let quantity_add (left right:quantity) : Tot quantity_result =
  if dimension_equal left.quantity_dimension right.quantity_dimension then
    QuantityOk {
      magnitude = Core.add left.magnitude right.magnitude;
      quantity_dimension = left.quantity_dimension;
      preferred_unit = left.preferred_unit
    }
  else DimensionMismatch

let quantity_subtract (left right:quantity) : Tot quantity_result =
  if dimension_equal left.quantity_dimension right.quantity_dimension then
    QuantityOk {
      magnitude = Core.subtract left.magnitude right.magnitude;
      quantity_dimension = left.quantity_dimension;
      preferred_unit = left.preferred_unit
    }
  else DimensionMismatch

let quantity_multiply (left right:quantity) : Tot quantity = {
  magnitude = Core.multiply left.magnitude right.magnitude;
  quantity_dimension =
    dimension_multiply left.quantity_dimension right.quantity_dimension;
  preferred_unit = ""
}

let quantity_divide (left right:quantity) : Tot quantity_result =
  if right.magnitude.numerator = 0 then DivisionByZero
  else
    match Core.divide left.magnitude right.magnitude with
    | Core.Success magnitude ->
        QuantityOk {
          magnitude = magnitude;
          quantity_dimension =
            dimension_divide left.quantity_dimension right.quantity_dimension;
          preferred_unit = ""
        }
    | Core.Failure _ -> DivisionByZero

(** Integer powers are exact when the verified rational core accepts the
    scalar operation.  Dimensions are multiplied by the same exponent. *)
let quantity_power (value:quantity) (exponent:int) : Tot quantity_result =
  match Core.power value.magnitude exponent with
  | Core.Success magnitude ->
      QuantityOk {
        magnitude = magnitude;
        quantity_dimension = dimension_power value.quantity_dimension exponent;
        preferred_unit = ""
      }
  | Core.Failure Core.DivisionByZero -> DivisionByZero
  | Core.Failure Core.UndefinedPower -> UndefinedPower
  | Core.Failure Core.ZeroDenominator -> UndefinedPower

(** Exact square-root validation deliberately requires an exact rational root
    witness.  Irrational roots are not manufactured as exact quantities. *)
let quantity_validate_square_root
    (value:quantity)
    (root_numerator root_denominator:int)
  : Tot quantity_result
=
  match dimension_square_root value.quantity_dimension with
  | None -> InvalidSquareRoot
  | Some result_dimension ->
      begin match
        Core.validate_square_root
          value.magnitude.numerator value.magnitude.denominator
          root_numerator root_denominator
      with
      | Core.ValidSquareRoot magnitude ->
          QuantityOk {
            magnitude = magnitude;
            quantity_dimension = result_dimension;
            preferred_unit = ""
          }
      | Core.InvalidSquareRoot -> InvalidSquareRoot
      end

(** This is the common admission gate for sin, exp, log, and any later
    dimensionless-only mathematical operation.  It does not claim an exact
    transcendental result; it only proves the physical argument is admissible. *)
let require_dimensionless (value:quantity) : Tot quantity_result =
  if dimension_equal value.quantity_dimension dimensionless then
    QuantityOk value
  else NonDimensionlessArgument

let scalar (numerator:int) (denominator:int{denominator <> 0}) : exact_scalar =
  Core.make numerator denominator

let meter : unit = {
  unit_symbol = "m";
  unit_dimension = length_dimension;
  unit_scale = scalar 1 1
}

let centimeter : unit = {
  unit_symbol = "cm";
  unit_dimension = length_dimension;
  unit_scale = scalar 1 100
}

let kilometer : unit = {
  unit_symbol = "km";
  unit_dimension = length_dimension;
  unit_scale = scalar 1000 1
}

let second : unit = {
  unit_symbol = "s";
  unit_dimension = time_dimension;
  unit_scale = scalar 1 1
}

let millisecond : unit = {
  unit_symbol = "ms";
  unit_dimension = time_dimension;
  unit_scale = scalar 1 1000
}

let minute : unit = {
  unit_symbol = "min";
  unit_dimension = time_dimension;
  unit_scale = scalar 60 1
}

let hour : unit = {
  unit_symbol = "h";
  unit_dimension = time_dimension;
  unit_scale = scalar 3600 1
}

let kilogram : unit = {
  unit_symbol = "kg";
  unit_dimension = mass_dimension;
  unit_scale = scalar 1 1
}

let gram : unit = {
  unit_symbol = "g";
  unit_dimension = mass_dimension;
  unit_scale = scalar 1 1000
}

let ampere : unit = {
  unit_symbol = "A";
  unit_dimension = current_dimension;
  unit_scale = scalar 1 1
}

let kelvin : unit = {
  unit_symbol = "K";
  unit_dimension = temperature_dimension;
  unit_scale = scalar 1 1
}

let mole : unit = {
  unit_symbol = "mol";
  unit_dimension = amount_dimension;
  unit_scale = scalar 1 1
}

let candela : unit = {
  unit_symbol = "cd";
  unit_dimension = luminosity_dimension;
  unit_scale = scalar 1 1
}

let velocity_dimension : dimension =
  dimension_divide length_dimension time_dimension

let acceleration_dimension : dimension =
  dimension_divide length_dimension (dimension_power time_dimension 2)

let force_dimension : dimension =
  dimension_multiply mass_dimension acceleration_dimension

let energy_dimension : dimension =
  dimension_multiply force_dimension length_dimension

let momentum_dimension : dimension =
  dimension_multiply mass_dimension velocity_dimension

let spring_constant_dimension : dimension =
  dimension_divide force_dimension length_dimension

let newton : unit = {
  unit_symbol = "N";
  unit_dimension = force_dimension;
  unit_scale = scalar 1 1
}

let joule : unit = {
  unit_symbol = "J";
  unit_dimension = energy_dimension;
  unit_scale = scalar 1 1
}

let meter_per_second : unit = {
  unit_symbol = "m/s";
  unit_dimension = velocity_dimension;
  unit_scale = scalar 1 1
}

let meter_per_second_squared : unit = {
  unit_symbol = "m/s^2";
  unit_dimension = acceleration_dimension;
  unit_scale = scalar 1 1
}

let kilogram_meter_per_second : unit = {
  unit_symbol = "kg*m/s";
  unit_dimension = momentum_dimension;
  unit_scale = scalar 1 1
}

let newton_per_meter : unit = {
  unit_symbol = "N/m";
  unit_dimension = spring_constant_dimension;
  unit_scale = scalar 1 1
}

let quantity_has_dimension (value:quantity) (expected:dimension)
  : Tot bool
=
  dimension_equal value.quantity_dimension expected

let quantity_negate (value:quantity) : Tot quantity =
  { value with magnitude = Core.negate value.magnitude }

let quantity_scale (factor:exact_scalar) (value:quantity) : Tot quantity =
  { value with magnitude = Core.multiply factor value.magnitude }

(** Pure mechanics formulas.  These functions have no world state and
    reject dimensionally invalid arguments before evaluating a formula. *)
let mechanics_momentum (mass velocity:quantity) : Tot quantity_result =
  if quantity_has_dimension mass mass_dimension &&
     quantity_has_dimension velocity velocity_dimension
  then QuantityOk (quantity_multiply mass velocity)
  else DimensionMismatch

let mechanics_force (mass acceleration:quantity) : Tot quantity_result =
  if quantity_has_dimension mass mass_dimension &&
     quantity_has_dimension acceleration acceleration_dimension
  then QuantityOk (quantity_multiply mass acceleration)
  else DimensionMismatch

let mechanics_kinetic_energy (mass velocity:quantity)
  : Tot quantity_result
=
  if quantity_has_dimension mass mass_dimension &&
     quantity_has_dimension velocity velocity_dimension
  then
    let velocity_squared = quantity_multiply velocity velocity in
    let twice_energy = quantity_multiply mass velocity_squared in
    QuantityOk (quantity_scale (scalar 1 2) twice_energy)
  else DimensionMismatch

let mechanics_uniform_gravitational_potential
    (mass gravity height:quantity)
  : Tot quantity_result
=
  if quantity_has_dimension mass mass_dimension &&
     quantity_has_dimension gravity acceleration_dimension &&
     quantity_has_dimension height length_dimension
  then
    QuantityOk
      (quantity_multiply (quantity_multiply mass gravity) height)
  else DimensionMismatch

let mechanics_constant_acceleration_velocity
    (initial_velocity acceleration elapsed_time:quantity)
  : Tot quantity_result
=
  if quantity_has_dimension initial_velocity velocity_dimension &&
     quantity_has_dimension acceleration acceleration_dimension &&
     quantity_has_dimension elapsed_time time_dimension
  then
    quantity_add initial_velocity
      (quantity_multiply acceleration elapsed_time)
  else DimensionMismatch

let mechanics_constant_acceleration_displacement
    (initial_velocity acceleration elapsed_time:quantity)
  : Tot quantity_result
=
  if quantity_has_dimension initial_velocity velocity_dimension &&
     quantity_has_dimension acceleration acceleration_dimension &&
     quantity_has_dimension elapsed_time time_dimension
  then
    let velocity_term = quantity_multiply initial_velocity elapsed_time in
    let time_squared = quantity_multiply elapsed_time elapsed_time in
    let acceleration_term = quantity_multiply acceleration time_squared in
    quantity_add velocity_term
      (quantity_scale (scalar 1 2) acceleration_term)
  else DimensionMismatch

let mechanics_hooke_force (spring_constant displacement:quantity)
  : Tot quantity_result
=
  if quantity_has_dimension spring_constant spring_constant_dimension &&
     quantity_has_dimension displacement length_dimension
  then
    QuantityOk
      (quantity_negate (quantity_multiply spring_constant displacement))
  else DimensionMismatch

(** Representation-level dimension laws are definitional for the fixed
    seven-exponent vector. *)
let dimension_identity (value:dimension)
  : Lemma
      (ensures
        dimension_equal (dimension_multiply value dimensionless) value)
= ()

let dimension_divide_self (value:dimension)
  : Lemma
      (ensures
        dimension_equal (dimension_divide value value) dimensionless)
= ()

let force_has_newton_dimensions ()
  : Lemma
      (ensures
        dimension_equal newton.unit_dimension
          (dimension_multiply mass_dimension acceleration_dimension))
= ()

(** Concrete exact conversion witness: 100 cm and 1 m produce the same
    canonical magnitude. *)
let meter_centimeter_canonical_example ()
  : Lemma
      (ensures
        Core.equivalent
          (quantity_of_unit (scalar 1 1) meter).magnitude
          (quantity_of_unit (scalar 100 1) centimeter).magnitude)
= ()

let incompatible_addition_example ()
  : Lemma
      (ensures
        quantity_add
          (quantity_of_unit (scalar 1 1) meter)
          (quantity_of_unit (scalar 1 1) kilogram) =
        DimensionMismatch)
= ()

let square_root_area_dimension_example ()
  : Lemma
      (ensures
        dimension_square_root (dimension_power length_dimension 2) =
        Some length_dimension)
= ()

let dimensionless_gate_rejects_length_example ()
  : Lemma
      (ensures
        require_dimensionless (quantity_of_unit (scalar 1 1) meter) =
        NonDimensionlessArgument)
= ()
