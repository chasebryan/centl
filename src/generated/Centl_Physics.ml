open Prims
type dimension =
  {
  length_exp: Prims.int ;
  mass_exp: Prims.int ;
  time_exp: Prims.int ;
  current_exp: Prims.int ;
  temperature_exp: Prims.int ;
  amount_exp: Prims.int ;
  luminosity_exp: Prims.int }
let __proj__Mkdimension__item__length_exp (projectee : dimension) :
  Prims.int=
  match projectee with
  | { length_exp; mass_exp; time_exp; current_exp; temperature_exp;
      amount_exp; luminosity_exp;_} -> length_exp
let __proj__Mkdimension__item__mass_exp (projectee : dimension) : Prims.int=
  match projectee with
  | { length_exp; mass_exp; time_exp; current_exp; temperature_exp;
      amount_exp; luminosity_exp;_} -> mass_exp
let __proj__Mkdimension__item__time_exp (projectee : dimension) : Prims.int=
  match projectee with
  | { length_exp; mass_exp; time_exp; current_exp; temperature_exp;
      amount_exp; luminosity_exp;_} -> time_exp
let __proj__Mkdimension__item__current_exp (projectee : dimension) :
  Prims.int=
  match projectee with
  | { length_exp; mass_exp; time_exp; current_exp; temperature_exp;
      amount_exp; luminosity_exp;_} -> current_exp
let __proj__Mkdimension__item__temperature_exp (projectee : dimension) :
  Prims.int=
  match projectee with
  | { length_exp; mass_exp; time_exp; current_exp; temperature_exp;
      amount_exp; luminosity_exp;_} -> temperature_exp
let __proj__Mkdimension__item__amount_exp (projectee : dimension) :
  Prims.int=
  match projectee with
  | { length_exp; mass_exp; time_exp; current_exp; temperature_exp;
      amount_exp; luminosity_exp;_} -> amount_exp
let __proj__Mkdimension__item__luminosity_exp (projectee : dimension) :
  Prims.int=
  match projectee with
  | { length_exp; mass_exp; time_exp; current_exp; temperature_exp;
      amount_exp; luminosity_exp;_} -> luminosity_exp
let dimensionless : dimension=
  {
    length_exp = Prims.int_zero;
    mass_exp = Prims.int_zero;
    time_exp = Prims.int_zero;
    current_exp = Prims.int_zero;
    temperature_exp = Prims.int_zero;
    amount_exp = Prims.int_zero;
    luminosity_exp = Prims.int_zero
  }
let length_dimension : dimension=
  {
    length_exp = Prims.int_one;
    mass_exp = (dimensionless.mass_exp);
    time_exp = (dimensionless.time_exp);
    current_exp = (dimensionless.current_exp);
    temperature_exp = (dimensionless.temperature_exp);
    amount_exp = (dimensionless.amount_exp);
    luminosity_exp = (dimensionless.luminosity_exp)
  }
let mass_dimension : dimension=
  {
    length_exp = (dimensionless.length_exp);
    mass_exp = Prims.int_one;
    time_exp = (dimensionless.time_exp);
    current_exp = (dimensionless.current_exp);
    temperature_exp = (dimensionless.temperature_exp);
    amount_exp = (dimensionless.amount_exp);
    luminosity_exp = (dimensionless.luminosity_exp)
  }
let time_dimension : dimension=
  {
    length_exp = (dimensionless.length_exp);
    mass_exp = (dimensionless.mass_exp);
    time_exp = Prims.int_one;
    current_exp = (dimensionless.current_exp);
    temperature_exp = (dimensionless.temperature_exp);
    amount_exp = (dimensionless.amount_exp);
    luminosity_exp = (dimensionless.luminosity_exp)
  }
let current_dimension : dimension=
  {
    length_exp = (dimensionless.length_exp);
    mass_exp = (dimensionless.mass_exp);
    time_exp = (dimensionless.time_exp);
    current_exp = Prims.int_one;
    temperature_exp = (dimensionless.temperature_exp);
    amount_exp = (dimensionless.amount_exp);
    luminosity_exp = (dimensionless.luminosity_exp)
  }
let temperature_dimension : dimension=
  {
    length_exp = (dimensionless.length_exp);
    mass_exp = (dimensionless.mass_exp);
    time_exp = (dimensionless.time_exp);
    current_exp = (dimensionless.current_exp);
    temperature_exp = Prims.int_one;
    amount_exp = (dimensionless.amount_exp);
    luminosity_exp = (dimensionless.luminosity_exp)
  }
let amount_dimension : dimension=
  {
    length_exp = (dimensionless.length_exp);
    mass_exp = (dimensionless.mass_exp);
    time_exp = (dimensionless.time_exp);
    current_exp = (dimensionless.current_exp);
    temperature_exp = (dimensionless.temperature_exp);
    amount_exp = Prims.int_one;
    luminosity_exp = (dimensionless.luminosity_exp)
  }
let luminosity_dimension : dimension=
  {
    length_exp = (dimensionless.length_exp);
    mass_exp = (dimensionless.mass_exp);
    time_exp = (dimensionless.time_exp);
    current_exp = (dimensionless.current_exp);
    temperature_exp = (dimensionless.temperature_exp);
    amount_exp = (dimensionless.amount_exp);
    luminosity_exp = Prims.int_one
  }
let dimension_equal (left : dimension) (right : dimension) : Prims.bool=
  ((((((left.length_exp = right.length_exp) &&
         (left.mass_exp = right.mass_exp))
        && (left.time_exp = right.time_exp))
       && (left.current_exp = right.current_exp))
      && (left.temperature_exp = right.temperature_exp))
     && (left.amount_exp = right.amount_exp))
    && (left.luminosity_exp = right.luminosity_exp)
let dimension_multiply (left : dimension) (right : dimension) : dimension=
  {
    length_exp = (left.length_exp + right.length_exp);
    mass_exp = (left.mass_exp + right.mass_exp);
    time_exp = (left.time_exp + right.time_exp);
    current_exp = (left.current_exp + right.current_exp);
    temperature_exp = (left.temperature_exp + right.temperature_exp);
    amount_exp = (left.amount_exp + right.amount_exp);
    luminosity_exp = (left.luminosity_exp + right.luminosity_exp)
  }
let dimension_divide (left : dimension) (right : dimension) : dimension=
  {
    length_exp = (left.length_exp - right.length_exp);
    mass_exp = (left.mass_exp - right.mass_exp);
    time_exp = (left.time_exp - right.time_exp);
    current_exp = (left.current_exp - right.current_exp);
    temperature_exp = (left.temperature_exp - right.temperature_exp);
    amount_exp = (left.amount_exp - right.amount_exp);
    luminosity_exp = (left.luminosity_exp - right.luminosity_exp)
  }
let dimension_power (value : dimension) (exponent : Prims.int) : dimension=
  {
    length_exp = (value.length_exp * exponent);
    mass_exp = (value.mass_exp * exponent);
    time_exp = (value.time_exp * exponent);
    current_exp = (value.current_exp * exponent);
    temperature_exp = (value.temperature_exp * exponent);
    amount_exp = (value.amount_exp * exponent);
    luminosity_exp = (value.luminosity_exp * exponent)
  }
let dimension_even (value : dimension) : Prims.bool=
  ((((((((mod) value.length_exp (Prims.of_int 2)) = Prims.int_zero) &&
         (((mod) value.mass_exp (Prims.of_int 2)) = Prims.int_zero))
        && (((mod) value.time_exp (Prims.of_int 2)) = Prims.int_zero))
       && (((mod) value.current_exp (Prims.of_int 2)) = Prims.int_zero))
      && (((mod) value.temperature_exp (Prims.of_int 2)) = Prims.int_zero))
     && (((mod) value.amount_exp (Prims.of_int 2)) = Prims.int_zero))
    && (((mod) value.luminosity_exp (Prims.of_int 2)) = Prims.int_zero)
let dimension_square_root (value : dimension) :
  dimension FStar_Pervasives_Native.option=
  if dimension_even value
  then
    FStar_Pervasives_Native.Some
      {
        length_exp = (value.length_exp / (Prims.of_int 2));
        mass_exp = (value.mass_exp / (Prims.of_int 2));
        time_exp = (value.time_exp / (Prims.of_int 2));
        current_exp = (value.current_exp / (Prims.of_int 2));
        temperature_exp = (value.temperature_exp / (Prims.of_int 2));
        amount_exp = (value.amount_exp / (Prims.of_int 2));
        luminosity_exp = (value.luminosity_exp / (Prims.of_int 2))
      }
  else FStar_Pervasives_Native.None
type exact_scalar = Centl_Core.rational
type unit =
  {
  unit_symbol: Prims.string ;
  unit_dimension: dimension ;
  unit_scale: exact_scalar }
let __proj__Mkunit__item__unit_symbol (projectee : unit) : Prims.string=
  match projectee with
  | { unit_symbol; unit_dimension; unit_scale;_} -> unit_symbol
let __proj__Mkunit__item__unit_dimension (projectee : unit) : dimension=
  match projectee with
  | { unit_symbol; unit_dimension; unit_scale;_} -> unit_dimension
let __proj__Mkunit__item__unit_scale (projectee : unit) : exact_scalar=
  match projectee with
  | { unit_symbol; unit_dimension; unit_scale;_} -> unit_scale
let unit_valid (value : unit) : Prims.bool=
  (value.unit_scale).Centl_Core.numerator > Prims.int_zero
type quantity =
  {
  magnitude: exact_scalar ;
  quantity_dimension: dimension ;
  preferred_unit: Prims.string }
let __proj__Mkquantity__item__magnitude (projectee : quantity) :
  exact_scalar=
  match projectee with
  | { magnitude; quantity_dimension; preferred_unit;_} -> magnitude
let __proj__Mkquantity__item__quantity_dimension (projectee : quantity) :
  dimension=
  match projectee with
  | { magnitude; quantity_dimension; preferred_unit;_} -> quantity_dimension
let __proj__Mkquantity__item__preferred_unit (projectee : quantity) :
  Prims.string=
  match projectee with
  | { magnitude; quantity_dimension; preferred_unit;_} -> preferred_unit
type quantity_result =
  | QuantityOk of quantity 
  | DimensionMismatch 
  | DivisionByZero 
  | InvalidUnit 
  | UndefinedPower 
  | InvalidSquareRoot 
  | NonDimensionlessArgument 
let uu___is_QuantityOk (projectee : quantity_result) : Prims.bool=
  match projectee with | QuantityOk _0 -> true | uu___ -> false
let __proj__QuantityOk__item___0 (projectee : quantity_result) : quantity=
  match projectee with | QuantityOk _0 -> _0
let uu___is_DimensionMismatch (projectee : quantity_result) : Prims.bool=
  match projectee with | DimensionMismatch -> true | uu___ -> false
let uu___is_DivisionByZero (projectee : quantity_result) : Prims.bool=
  match projectee with | DivisionByZero -> true | uu___ -> false
let uu___is_InvalidUnit (projectee : quantity_result) : Prims.bool=
  match projectee with | InvalidUnit -> true | uu___ -> false
let uu___is_UndefinedPower (projectee : quantity_result) : Prims.bool=
  match projectee with | UndefinedPower -> true | uu___ -> false
let uu___is_InvalidSquareRoot (projectee : quantity_result) : Prims.bool=
  match projectee with | InvalidSquareRoot -> true | uu___ -> false
let uu___is_NonDimensionlessArgument (projectee : quantity_result) :
  Prims.bool=
  match projectee with | NonDimensionlessArgument -> true | uu___ -> false
let quantity_of_unit (value : exact_scalar) (source : unit) : quantity=
  {
    magnitude = (Centl_Core.multiply value source.unit_scale);
    quantity_dimension = (source.unit_dimension);
    preferred_unit = (source.unit_symbol)
  }
let quantity_of_unit_checked (value : exact_scalar) (source : unit) :
  quantity_result=
  if unit_valid source
  then QuantityOk (quantity_of_unit value source)
  else InvalidUnit
let quantity_in_unit (value : quantity) (target : unit) :
  exact_scalar FStar_Pervasives_Native.option=
  if Prims.op_Negation (unit_valid target)
  then FStar_Pervasives_Native.None
  else
    if
      Prims.op_Negation
        (dimension_equal value.quantity_dimension target.unit_dimension)
    then FStar_Pervasives_Native.None
    else
      (match Centl_Core.divide value.magnitude target.unit_scale with
       | Centl_Core.Success converted ->
           FStar_Pervasives_Native.Some converted
       | Centl_Core.Failure uu___ -> FStar_Pervasives_Native.None)
let prefer_unit (value : quantity) (target : unit) : quantity_result=
  if Prims.op_Negation (unit_valid target)
  then InvalidUnit
  else
    if dimension_equal value.quantity_dimension target.unit_dimension
    then
      QuantityOk
        {
          magnitude = (value.magnitude);
          quantity_dimension = (value.quantity_dimension);
          preferred_unit = (target.unit_symbol)
        }
    else DimensionMismatch
let quantity_add (left : quantity) (right : quantity) : quantity_result=
  if dimension_equal left.quantity_dimension right.quantity_dimension
  then
    QuantityOk
      {
        magnitude = (Centl_Core.add left.magnitude right.magnitude);
        quantity_dimension = (left.quantity_dimension);
        preferred_unit = (left.preferred_unit)
      }
  else DimensionMismatch
let quantity_subtract (left : quantity) (right : quantity) : quantity_result=
  if dimension_equal left.quantity_dimension right.quantity_dimension
  then
    QuantityOk
      {
        magnitude = (Centl_Core.subtract left.magnitude right.magnitude);
        quantity_dimension = (left.quantity_dimension);
        preferred_unit = (left.preferred_unit)
      }
  else DimensionMismatch
let quantity_multiply (left : quantity) (right : quantity) : quantity=
  {
    magnitude = (Centl_Core.multiply left.magnitude right.magnitude);
    quantity_dimension =
      (dimension_multiply left.quantity_dimension right.quantity_dimension);
    preferred_unit = ""
  }
let quantity_divide (left : quantity) (right : quantity) : quantity_result=
  if (right.magnitude).Centl_Core.numerator = Prims.int_zero
  then DivisionByZero
  else
    (match Centl_Core.divide left.magnitude right.magnitude with
     | Centl_Core.Success magnitude ->
         QuantityOk
           {
             magnitude;
             quantity_dimension =
               (dimension_divide left.quantity_dimension
                  right.quantity_dimension);
             preferred_unit = ""
           }
     | Centl_Core.Failure uu___ -> DivisionByZero)
let quantity_power (value : quantity) (exponent : Prims.int) :
  quantity_result=
  match Centl_Core.power value.magnitude exponent with
  | Centl_Core.Success magnitude ->
      QuantityOk
        {
          magnitude;
          quantity_dimension =
            (dimension_power value.quantity_dimension exponent);
          preferred_unit = ""
        }
  | Centl_Core.Failure (Centl_Core.DivisionByZero) -> DivisionByZero
  | Centl_Core.Failure (Centl_Core.UndefinedPower) -> UndefinedPower
  | Centl_Core.Failure (Centl_Core.ZeroDenominator) -> UndefinedPower
let quantity_validate_square_root (value : quantity)
  (root_numerator : Prims.int) (root_denominator : Prims.int) :
  quantity_result=
  match dimension_square_root value.quantity_dimension with
  | FStar_Pervasives_Native.None -> InvalidSquareRoot
  | FStar_Pervasives_Native.Some result_dimension ->
      (match Centl_Core.validate_square_root
               (value.magnitude).Centl_Core.numerator
               (value.magnitude).Centl_Core.denominator root_numerator
               root_denominator
       with
       | Centl_Core.ValidSquareRoot magnitude ->
           QuantityOk
             {
               magnitude;
               quantity_dimension = result_dimension;
               preferred_unit = ""
             }
       | Centl_Core.InvalidSquareRoot -> InvalidSquareRoot)
let require_dimensionless (value : quantity) : quantity_result=
  if dimension_equal value.quantity_dimension dimensionless
  then QuantityOk value
  else NonDimensionlessArgument
let scalar (numerator : Prims.int) (denominator : Prims.int) : exact_scalar=
  Centl_Core.make numerator denominator
let meter : unit=
  {
    unit_symbol = "m";
    unit_dimension = length_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let centimeter : unit=
  {
    unit_symbol = "cm";
    unit_dimension = length_dimension;
    unit_scale = (scalar Prims.int_one (Prims.of_int 100))
  }
let kilometer : unit=
  {
    unit_symbol = "km";
    unit_dimension = length_dimension;
    unit_scale = (scalar (Prims.of_int 1000) Prims.int_one)
  }
let second : unit=
  {
    unit_symbol = "s";
    unit_dimension = time_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let millisecond : unit=
  {
    unit_symbol = "ms";
    unit_dimension = time_dimension;
    unit_scale = (scalar Prims.int_one (Prims.of_int 1000))
  }
let minute : unit=
  {
    unit_symbol = "min";
    unit_dimension = time_dimension;
    unit_scale = (scalar (Prims.of_int 60) Prims.int_one)
  }
let hour : unit=
  {
    unit_symbol = "h";
    unit_dimension = time_dimension;
    unit_scale = (scalar (Prims.of_int 3600) Prims.int_one)
  }
let kilogram : unit=
  {
    unit_symbol = "kg";
    unit_dimension = mass_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let gram : unit=
  {
    unit_symbol = "g";
    unit_dimension = mass_dimension;
    unit_scale = (scalar Prims.int_one (Prims.of_int 1000))
  }
let ampere : unit=
  {
    unit_symbol = "A";
    unit_dimension = current_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let kelvin : unit=
  {
    unit_symbol = "K";
    unit_dimension = temperature_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let mole : unit=
  {
    unit_symbol = "mol";
    unit_dimension = amount_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let candela : unit=
  {
    unit_symbol = "cd";
    unit_dimension = luminosity_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let velocity_dimension : dimension=
  dimension_divide length_dimension time_dimension
let acceleration_dimension : dimension=
  dimension_divide length_dimension
    (dimension_power time_dimension (Prims.of_int 2))
let force_dimension : dimension=
  dimension_multiply mass_dimension acceleration_dimension
let energy_dimension : dimension=
  dimension_multiply force_dimension length_dimension
let momentum_dimension : dimension=
  dimension_multiply mass_dimension velocity_dimension
let spring_constant_dimension : dimension=
  dimension_divide force_dimension length_dimension
let newton : unit=
  {
    unit_symbol = "N";
    unit_dimension = force_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let joule : unit=
  {
    unit_symbol = "J";
    unit_dimension = energy_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let meter_per_second : unit=
  {
    unit_symbol = "m/s";
    unit_dimension = velocity_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let meter_per_second_squared : unit=
  {
    unit_symbol = "m/s^2";
    unit_dimension = acceleration_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let kilogram_meter_per_second : unit=
  {
    unit_symbol = "kg*m/s";
    unit_dimension = momentum_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let newton_per_meter : unit=
  {
    unit_symbol = "N/m";
    unit_dimension = spring_constant_dimension;
    unit_scale = (scalar Prims.int_one Prims.int_one)
  }
let quantity_has_dimension (value : quantity) (expected : dimension) :
  Prims.bool= dimension_equal value.quantity_dimension expected
let quantity_negate (value : quantity) : quantity=
  {
    magnitude = (Centl_Core.negate value.magnitude);
    quantity_dimension = (value.quantity_dimension);
    preferred_unit = (value.preferred_unit)
  }
let quantity_scale (factor : exact_scalar) (value : quantity) : quantity=
  {
    magnitude = (Centl_Core.multiply factor value.magnitude);
    quantity_dimension = (value.quantity_dimension);
    preferred_unit = (value.preferred_unit)
  }
let mechanics_momentum (mass : quantity) (velocity : quantity) :
  quantity_result=
  if
    (quantity_has_dimension mass mass_dimension) &&
      (quantity_has_dimension velocity velocity_dimension)
  then QuantityOk (quantity_multiply mass velocity)
  else DimensionMismatch
let mechanics_force (mass : quantity) (acceleration : quantity) :
  quantity_result=
  if
    (quantity_has_dimension mass mass_dimension) &&
      (quantity_has_dimension acceleration acceleration_dimension)
  then QuantityOk (quantity_multiply mass acceleration)
  else DimensionMismatch
let mechanics_kinetic_energy (mass : quantity) (velocity : quantity) :
  quantity_result=
  if
    (quantity_has_dimension mass mass_dimension) &&
      (quantity_has_dimension velocity velocity_dimension)
  then
    let velocity_squared = quantity_multiply velocity velocity in
    let twice_energy = quantity_multiply mass velocity_squared in
    QuantityOk
      (quantity_scale (scalar Prims.int_one (Prims.of_int 2)) twice_energy)
  else DimensionMismatch
let mechanics_uniform_gravitational_potential (mass : quantity)
  (gravity : quantity) (height : quantity) : quantity_result=
  if
    ((quantity_has_dimension mass mass_dimension) &&
       (quantity_has_dimension gravity acceleration_dimension))
      && (quantity_has_dimension height length_dimension)
  then QuantityOk (quantity_multiply (quantity_multiply mass gravity) height)
  else DimensionMismatch
let mechanics_constant_acceleration_velocity (initial_velocity : quantity)
  (acceleration : quantity) (elapsed_time : quantity) : quantity_result=
  if
    ((quantity_has_dimension initial_velocity velocity_dimension) &&
       (quantity_has_dimension acceleration acceleration_dimension))
      && (quantity_has_dimension elapsed_time time_dimension)
  then
    quantity_add initial_velocity
      (quantity_multiply acceleration elapsed_time)
  else DimensionMismatch
let mechanics_constant_acceleration_displacement
  (initial_velocity : quantity) (acceleration : quantity)
  (elapsed_time : quantity) : quantity_result=
  if
    ((quantity_has_dimension initial_velocity velocity_dimension) &&
       (quantity_has_dimension acceleration acceleration_dimension))
      && (quantity_has_dimension elapsed_time time_dimension)
  then
    let velocity_term = quantity_multiply initial_velocity elapsed_time in
    let time_squared = quantity_multiply elapsed_time elapsed_time in
    let acceleration_term = quantity_multiply acceleration time_squared in
    quantity_add velocity_term
      (quantity_scale (scalar Prims.int_one (Prims.of_int 2))
         acceleration_term)
  else DimensionMismatch
let mechanics_hooke_force (spring_constant : quantity)
  (displacement : quantity) : quantity_result=
  if
    (quantity_has_dimension spring_constant spring_constant_dimension) &&
      (quantity_has_dimension displacement length_dimension)
  then
    QuantityOk
      (quantity_negate (quantity_multiply spring_constant displacement))
  else DimensionMismatch
