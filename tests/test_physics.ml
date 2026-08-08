let exact numerator denominator =
  Centl_Core.make (Z.of_int numerator) (Z.of_int denominator)

let check_rational message expected_n expected_d value =
  Alcotest.(check string)
    (message ^ " numerator") (string_of_int expected_n)
    (Z.to_string value.Centl_Core.numerator);
  Alcotest.(check string)
    (message ^ " denominator") (string_of_int expected_d)
    (Z.to_string value.Centl_Core.denominator)

let test_meter_centimeter_canonical () =
  let meter_value =
    Centl_Physics.quantity_of_unit (exact 1 1) Centl_Physics.meter
  in
  let centimeter_value =
    Centl_Physics.quantity_of_unit (exact 100 1) Centl_Physics.centimeter
  in
  Alcotest.(check bool)
    "same dimensions" true
    (Centl_Physics.dimension_equal meter_value.quantity_dimension
       centimeter_value.quantity_dimension);
  check_rational "one metre canonical" 1 1 meter_value.magnitude;
  check_rational "hundred centimetres canonical" 1 1 centimeter_value.magnitude

let test_exact_conversion () =
  let one_meter =
    Centl_Physics.quantity_of_unit (exact 1 1) Centl_Physics.meter
  in
  match Centl_Physics.quantity_in_unit one_meter Centl_Physics.centimeter with
  | None -> Alcotest.fail "metre to centimetre conversion was rejected"
  | Some converted -> check_rational "1 m in cm" 100 1 converted

let test_invalid_unit () =
  let invalid : Centl_Physics.unit =
    {
      unit_symbol = "bad";
      unit_dimension = Centl_Physics.length_dimension;
      unit_scale = exact 0 1;
    }
  in
  match Centl_Physics.quantity_of_unit_checked (exact 3 1) invalid with
  | Centl_Physics.InvalidUnit -> ()
  | _ -> Alcotest.fail "zero-scale unit must be rejected"

let test_dimension_mismatch () =
  let one_meter =
    Centl_Physics.quantity_of_unit (exact 1 1) Centl_Physics.meter
  in
  let one_kilogram =
    Centl_Physics.quantity_of_unit (exact 1 1) Centl_Physics.kilogram
  in
  match Centl_Physics.quantity_add one_meter one_kilogram with
  | Centl_Physics.DimensionMismatch -> ()
  | _ -> Alcotest.fail "mass + length must be rejected"

let test_quantity_power () =
  let two_meters =
    Centl_Physics.quantity_of_unit (exact 2 1) Centl_Physics.meter
  in
  match Centl_Physics.quantity_power two_meters (Z.of_int 2) with
  | Centl_Physics.QuantityOk squared ->
      check_rational "(2 m)^2" 4 1 squared.magnitude;
      let expected =
        Centl_Physics.dimension_power Centl_Physics.length_dimension
          (Z.of_int 2)
      in
      Alcotest.(check bool)
        "power multiplies dimensions" true
        (Centl_Physics.dimension_equal squared.quantity_dimension expected)
  | _ -> Alcotest.fail "exact integer quantity power failed"

let test_negative_quantity_power () =
  let two_seconds =
    Centl_Physics.quantity_of_unit (exact 2 1) Centl_Physics.second
  in
  match Centl_Physics.quantity_power two_seconds (Z.of_int (-1)) with
  | Centl_Physics.QuantityOk reciprocal ->
      check_rational "(2 s)^-1" 1 2 reciprocal.magnitude;
      Alcotest.(check int)
        "reciprocal time exponent" (-1)
        (Z.to_int reciprocal.quantity_dimension.time_exp)
  | _ -> Alcotest.fail "negative integer quantity power failed"

let test_undefined_zero_power () =
  let zero = Centl_Physics.quantity_of_unit (exact 0 1) Centl_Physics.meter in
  match Centl_Physics.quantity_power zero Z.zero with
  | Centl_Physics.UndefinedPower -> ()
  | _ -> Alcotest.fail "0^0 must remain undefined"

let test_exact_quantity_square_root () =
  let area_dimension =
    Centl_Physics.dimension_power Centl_Physics.length_dimension (Z.of_int 2)
  in
  let area : Centl_Physics.quantity =
    {
      magnitude = exact 9 1;
      quantity_dimension = area_dimension;
      preferred_unit = "m^2";
    }
  in
  match Centl_Physics.quantity_validate_square_root area (Z.of_int 3) Z.one with
  | Centl_Physics.QuantityOk root ->
      check_rational "sqrt(9 m^2)" 3 1 root.magnitude;
      Alcotest.(check bool)
        "sqrt area dimension" true
        (Centl_Physics.dimension_equal root.quantity_dimension
           Centl_Physics.length_dimension)
  | _ -> Alcotest.fail "exact square-root witness was rejected"

let test_fractional_dimension_square_root_rejected () =
  let length = Centl_Physics.quantity_of_unit (exact 9 1) Centl_Physics.meter in
  match
    Centl_Physics.quantity_validate_square_root length (Z.of_int 3) Z.one
  with
  | Centl_Physics.InvalidSquareRoot -> ()
  | _ -> Alcotest.fail "sqrt(length) must not introduce fractional dimensions"

let test_dimensionless_gate () =
  let length = Centl_Physics.quantity_of_unit (exact 1 1) Centl_Physics.meter in
  let scalar : Centl_Physics.quantity =
    {
      magnitude = exact 1 2;
      quantity_dimension = Centl_Physics.dimensionless;
      preferred_unit = "";
    }
  in
  begin match Centl_Physics.require_dimensionless length with
  | Centl_Physics.NonDimensionlessArgument -> ()
  | _ -> Alcotest.fail "dimensionful transcendental argument must be rejected"
  end;
  match Centl_Physics.require_dimensionless scalar with
  | Centl_Physics.QuantityOk _ -> ()
  | _ -> Alcotest.fail "dimensionless transcendental argument must be admitted"

let check_dimension message expected value =
  Alcotest.(check bool)
    message true
    (Centl_Physics.dimension_equal value.Centl_Physics.quantity_dimension
       expected)

let test_mechanics_momentum () =
  let mass =
    Centl_Physics.quantity_of_unit (exact 2 1) Centl_Physics.kilogram
  in
  let velocity =
    Centl_Physics.quantity_of_unit (exact 3 1) Centl_Physics.meter_per_second
  in
  match Centl_Physics.mechanics_momentum mass velocity with
  | Centl_Physics.QuantityOk momentum ->
      check_rational "momentum" 6 1 momentum.magnitude;
      check_dimension "momentum dimension" Centl_Physics.momentum_dimension
        momentum
  | _ -> Alcotest.fail "valid momentum formula was rejected"

let test_mechanics_force () =
  let mass =
    Centl_Physics.quantity_of_unit (exact 2 1) Centl_Physics.kilogram
  in
  let acceleration =
    Centl_Physics.quantity_of_unit (exact (-4) 1)
      Centl_Physics.meter_per_second_squared
  in
  match Centl_Physics.mechanics_force mass acceleration with
  | Centl_Physics.QuantityOk force ->
      check_rational "force" (-8) 1 force.magnitude;
      check_dimension "force dimension" Centl_Physics.force_dimension force
  | _ -> Alcotest.fail "valid force formula was rejected"

let test_mechanics_kinetic_energy () =
  let mass =
    Centl_Physics.quantity_of_unit (exact 2 1) Centl_Physics.kilogram
  in
  let velocity =
    Centl_Physics.quantity_of_unit (exact 3 1) Centl_Physics.meter_per_second
  in
  match Centl_Physics.mechanics_kinetic_energy mass velocity with
  | Centl_Physics.QuantityOk energy ->
      check_rational "kinetic energy" 9 1 energy.magnitude;
      check_dimension "kinetic energy dimension" Centl_Physics.energy_dimension
        energy
  | _ -> Alcotest.fail "valid kinetic-energy formula was rejected"

let test_mechanics_uniform_potential () =
  let mass =
    Centl_Physics.quantity_of_unit (exact 2 1) Centl_Physics.kilogram
  in
  let gravity =
    Centl_Physics.quantity_of_unit (exact 10 1)
      Centl_Physics.meter_per_second_squared
  in
  let height = Centl_Physics.quantity_of_unit (exact 5 1) Centl_Physics.meter in
  match
    Centl_Physics.mechanics_uniform_gravitational_potential mass gravity height
  with
  | Centl_Physics.QuantityOk energy ->
      check_rational "uniform gravitational potential" 100 1 energy.magnitude;
      check_dimension "potential energy dimension"
        Centl_Physics.energy_dimension energy
  | _ -> Alcotest.fail "valid gravitational-potential formula was rejected"

let test_mechanics_constant_acceleration_velocity () =
  let velocity =
    Centl_Physics.quantity_of_unit (exact 3 1) Centl_Physics.meter_per_second
  in
  let acceleration =
    Centl_Physics.quantity_of_unit (exact (-2) 1)
      Centl_Physics.meter_per_second_squared
  in
  let elapsed =
    Centl_Physics.quantity_of_unit (exact 4 1) Centl_Physics.second
  in
  match
    Centl_Physics.mechanics_constant_acceleration_velocity velocity acceleration
      elapsed
  with
  | Centl_Physics.QuantityOk result ->
      check_rational "constant-acceleration velocity" (-5) 1 result.magnitude;
      check_dimension "velocity dimension" Centl_Physics.velocity_dimension
        result
  | _ -> Alcotest.fail "valid constant-acceleration velocity was rejected"

let test_mechanics_constant_acceleration_displacement () =
  let velocity =
    Centl_Physics.quantity_of_unit (exact 3 1) Centl_Physics.meter_per_second
  in
  let acceleration =
    Centl_Physics.quantity_of_unit (exact (-2) 1)
      Centl_Physics.meter_per_second_squared
  in
  let elapsed =
    Centl_Physics.quantity_of_unit (exact 4 1) Centl_Physics.second
  in
  match
    Centl_Physics.mechanics_constant_acceleration_displacement velocity
      acceleration elapsed
  with
  | Centl_Physics.QuantityOk result ->
      check_rational "constant-acceleration displacement" (-4) 1
        result.magnitude;
      check_dimension "displacement dimension" Centl_Physics.length_dimension
        result
  | _ -> Alcotest.fail "valid constant-acceleration displacement was rejected"

let test_mechanics_hooke_force () =
  let spring =
    Centl_Physics.quantity_of_unit (exact 4 1) Centl_Physics.newton_per_meter
  in
  let displacement =
    Centl_Physics.quantity_of_unit (exact 3 1) Centl_Physics.meter
  in
  match Centl_Physics.mechanics_hooke_force spring displacement with
  | Centl_Physics.QuantityOk force ->
      check_rational "Hooke force" (-12) 1 force.magnitude;
      check_dimension "Hooke force dimension" Centl_Physics.force_dimension
        force
  | _ -> Alcotest.fail "valid Hooke-law formula was rejected"

let test_mechanics_dimension_mismatch () =
  let length = Centl_Physics.quantity_of_unit (exact 2 1) Centl_Physics.meter in
  let velocity =
    Centl_Physics.quantity_of_unit (exact 3 1) Centl_Physics.meter_per_second
  in
  match Centl_Physics.mechanics_momentum length velocity with
  | Centl_Physics.DimensionMismatch -> ()
  | _ -> Alcotest.fail "mechanics formula accepted invalid dimensions"

let test_derived_force_dimension () =
  let expected =
    Centl_Physics.dimension_multiply Centl_Physics.mass_dimension
      Centl_Physics.acceleration_dimension
  in
  Alcotest.(check bool)
    "newton dimension" true
    (Centl_Physics.dimension_equal Centl_Physics.newton.unit_dimension expected)

let test_dimension_square_root () =
  let area =
    Centl_Physics.dimension_power Centl_Physics.length_dimension (Z.of_int 2)
  in
  match Centl_Physics.dimension_square_root area with
  | None -> Alcotest.fail "sqrt(length^2) should be dimensionally valid"
  | Some root ->
      Alcotest.(check bool)
        "sqrt(length^2) = length" true
        (Centl_Physics.dimension_equal root Centl_Physics.length_dimension)

let () =
  Alcotest.run "CENTL Physics"
    [
      ( "units",
        [
          Alcotest.test_case "metre-centimetre canonical equality" `Quick
            test_meter_centimeter_canonical;
          Alcotest.test_case "exact unit conversion" `Quick
            test_exact_conversion;
          Alcotest.test_case "invalid unit" `Quick test_invalid_unit;
          Alcotest.test_case "dimension mismatch" `Quick test_dimension_mismatch;
        ] );
      ( "quantities",
        [
          Alcotest.test_case "integer power" `Quick test_quantity_power;
          Alcotest.test_case "negative integer power" `Quick
            test_negative_quantity_power;
          Alcotest.test_case "undefined zero power" `Quick
            test_undefined_zero_power;
          Alcotest.test_case "exact square root" `Quick
            test_exact_quantity_square_root;
          Alcotest.test_case "fractional dimension sqrt rejected" `Quick
            test_fractional_dimension_square_root_rejected;
          Alcotest.test_case "dimensionless gate" `Quick test_dimensionless_gate;
        ] );
      ( "mechanics",
        [
          Alcotest.test_case "momentum" `Quick test_mechanics_momentum;
          Alcotest.test_case "force" `Quick test_mechanics_force;
          Alcotest.test_case "kinetic energy" `Quick
            test_mechanics_kinetic_energy;
          Alcotest.test_case "uniform gravitational potential" `Quick
            test_mechanics_uniform_potential;
          Alcotest.test_case "constant-acceleration velocity" `Quick
            test_mechanics_constant_acceleration_velocity;
          Alcotest.test_case "constant-acceleration displacement" `Quick
            test_mechanics_constant_acceleration_displacement;
          Alcotest.test_case "Hooke force" `Quick test_mechanics_hooke_force;
          Alcotest.test_case "dimension mismatch" `Quick
            test_mechanics_dimension_mismatch;
        ] );
      ( "dimensions",
        [
          Alcotest.test_case "derived force dimension" `Quick
            test_derived_force_dimension;
          Alcotest.test_case "dimension square root" `Quick
            test_dimension_square_root;
        ] );
    ]
