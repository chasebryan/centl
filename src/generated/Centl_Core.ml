open Prims
type binary_operator =
  | Add 
  | Subtract 
  | Multiply 
  | Divide 
let uu___is_Add (projectee : binary_operator) : Prims.bool=
  match projectee with | Add -> true | uu___ -> false
let uu___is_Subtract (projectee : binary_operator) : Prims.bool=
  match projectee with | Subtract -> true | uu___ -> false
let uu___is_Multiply (projectee : binary_operator) : Prims.bool=
  match projectee with | Multiply -> true | uu___ -> false
let uu___is_Divide (projectee : binary_operator) : Prims.bool=
  match projectee with | Divide -> true | uu___ -> false
type relation =
  | Equal 
  | NotEqual 
  | LessThan 
  | LessOrEqual 
  | GreaterThan 
  | GreaterOrEqual 
let uu___is_Equal (projectee : relation) : Prims.bool=
  match projectee with | Equal -> true | uu___ -> false
let uu___is_NotEqual (projectee : relation) : Prims.bool=
  match projectee with | NotEqual -> true | uu___ -> false
let uu___is_LessThan (projectee : relation) : Prims.bool=
  match projectee with | LessThan -> true | uu___ -> false
let uu___is_LessOrEqual (projectee : relation) : Prims.bool=
  match projectee with | LessOrEqual -> true | uu___ -> false
let uu___is_GreaterThan (projectee : relation) : Prims.bool=
  match projectee with | GreaterThan -> true | uu___ -> false
let uu___is_GreaterOrEqual (projectee : relation) : Prims.bool=
  match projectee with | GreaterOrEqual -> true | uu___ -> false
type expression =
  | Literal of Prims.int * Prims.int 
  | Symbol of Prims.string 
  | Negate of expression 
  | Binary of binary_operator * expression * expression 
  | Power of expression * Prims.int 
  | Function of Prims.string * expression Prims.list 
  | Differentiate of expression * Prims.string 
  | Substitute of expression * Prims.string * expression 
  | Derivative of expression * Prims.string 
  | Simplify of expression 
  | Expand of expression 
  | Factor of expression 
  | Assuming of expression * expression * relation * expression 
let uu___is_Literal (projectee : expression) : Prims.bool=
  match projectee with
  | Literal (numerator, denominator) -> true
  | uu___ -> false
let __proj__Literal__item__numerator (projectee : expression) : Prims.int=
  match projectee with | Literal (numerator, denominator) -> numerator
let __proj__Literal__item__denominator (projectee : expression) : Prims.int=
  match projectee with | Literal (numerator, denominator) -> denominator
let uu___is_Symbol (projectee : expression) : Prims.bool=
  match projectee with | Symbol name -> true | uu___ -> false
let __proj__Symbol__item__name (projectee : expression) : Prims.string=
  match projectee with | Symbol name -> name
let uu___is_Negate (projectee : expression) : Prims.bool=
  match projectee with | Negate _0 -> true | uu___ -> false
let __proj__Negate__item___0 (projectee : expression) : expression=
  match projectee with | Negate _0 -> _0
let uu___is_Binary (projectee : expression) : Prims.bool=
  match projectee with | Binary (_0, _1, _2) -> true | uu___ -> false
let __proj__Binary__item___0 (projectee : expression) : binary_operator=
  match projectee with | Binary (_0, _1, _2) -> _0
let __proj__Binary__item___1 (projectee : expression) : expression=
  match projectee with | Binary (_0, _1, _2) -> _1
let __proj__Binary__item___2 (projectee : expression) : expression=
  match projectee with | Binary (_0, _1, _2) -> _2
let uu___is_Power (projectee : expression) : Prims.bool=
  match projectee with | Power (_0, exponent) -> true | uu___ -> false
let __proj__Power__item___0 (projectee : expression) : expression=
  match projectee with | Power (_0, exponent) -> _0
let __proj__Power__item__exponent (projectee : expression) : Prims.int=
  match projectee with | Power (_0, exponent) -> exponent
let uu___is_Function (projectee : expression) : Prims.bool=
  match projectee with | Function (name, arguments) -> true | uu___ -> false
let __proj__Function__item__name (projectee : expression) : Prims.string=
  match projectee with | Function (name, arguments) -> name
let __proj__Function__item__arguments (projectee : expression) :
  expression Prims.list=
  match projectee with | Function (name, arguments) -> arguments
let uu___is_Differentiate (projectee : expression) : Prims.bool=
  match projectee with
  | Differentiate (_0, variable) -> true
  | uu___ -> false
let __proj__Differentiate__item___0 (projectee : expression) : expression=
  match projectee with | Differentiate (_0, variable) -> _0
let __proj__Differentiate__item__variable (projectee : expression) :
  Prims.string=
  match projectee with | Differentiate (_0, variable) -> variable
let uu___is_Substitute (projectee : expression) : Prims.bool=
  match projectee with
  | Substitute (_0, variable, replacement) -> true
  | uu___ -> false
let __proj__Substitute__item___0 (projectee : expression) : expression=
  match projectee with | Substitute (_0, variable, replacement) -> _0
let __proj__Substitute__item__variable (projectee : expression) :
  Prims.string=
  match projectee with | Substitute (_0, variable, replacement) -> variable
let __proj__Substitute__item__replacement (projectee : expression) :
  expression=
  match projectee with
  | Substitute (_0, variable, replacement) -> replacement
let uu___is_Derivative (projectee : expression) : Prims.bool=
  match projectee with | Derivative (_0, variable) -> true | uu___ -> false
let __proj__Derivative__item___0 (projectee : expression) : expression=
  match projectee with | Derivative (_0, variable) -> _0
let __proj__Derivative__item__variable (projectee : expression) :
  Prims.string= match projectee with | Derivative (_0, variable) -> variable
let uu___is_Simplify (projectee : expression) : Prims.bool=
  match projectee with | Simplify _0 -> true | uu___ -> false
let __proj__Simplify__item___0 (projectee : expression) : expression=
  match projectee with | Simplify _0 -> _0
let uu___is_Expand (projectee : expression) : Prims.bool=
  match projectee with | Expand _0 -> true | uu___ -> false
let __proj__Expand__item___0 (projectee : expression) : expression=
  match projectee with | Expand _0 -> _0
let uu___is_Factor (projectee : expression) : Prims.bool=
  match projectee with | Factor _0 -> true | uu___ -> false
let __proj__Factor__item___0 (projectee : expression) : expression=
  match projectee with | Factor _0 -> _0
let uu___is_Assuming (projectee : expression) : Prims.bool=
  match projectee with
  | Assuming (_0, left, _2, right) -> true
  | uu___ -> false
let __proj__Assuming__item___0 (projectee : expression) : expression=
  match projectee with | Assuming (_0, left, _2, right) -> _0
let __proj__Assuming__item__left (projectee : expression) : expression=
  match projectee with | Assuming (_0, left, _2, right) -> left
let __proj__Assuming__item___2 (projectee : expression) : relation=
  match projectee with | Assuming (_0, left, _2, right) -> _2
let __proj__Assuming__item__right (projectee : expression) : expression=
  match projectee with | Assuming (_0, left, _2, right) -> right
type rational = {
  numerator: Prims.int ;
  denominator: Prims.int }
let __proj__Mkrational__item__numerator (projectee : rational) : Prims.int=
  match projectee with | { numerator; denominator;_} -> numerator
let __proj__Mkrational__item__denominator (projectee : rational) : Prims.int=
  match projectee with | { numerator; denominator;_} -> denominator
type dyadic_enclosure =
  {
  lower_mantissa: Prims.int ;
  upper_mantissa: Prims.int ;
  binary_exponent: Prims.int }
let __proj__Mkdyadic_enclosure__item__lower_mantissa
  (projectee : dyadic_enclosure) : Prims.int=
  match projectee with
  | { lower_mantissa; upper_mantissa; binary_exponent;_} -> lower_mantissa
let __proj__Mkdyadic_enclosure__item__upper_mantissa
  (projectee : dyadic_enclosure) : Prims.int=
  match projectee with
  | { lower_mantissa; upper_mantissa; binary_exponent;_} -> upper_mantissa
let __proj__Mkdyadic_enclosure__item__binary_exponent
  (projectee : dyadic_enclosure) : Prims.int=
  match projectee with
  | { lower_mantissa; upper_mantissa; binary_exponent;_} -> binary_exponent
type enclosure_validation =
  | ValidEnclosure of dyadic_enclosure 
  | InvalidEnclosure 
let uu___is_ValidEnclosure (projectee : enclosure_validation) : Prims.bool=
  match projectee with | ValidEnclosure _0 -> true | uu___ -> false
let __proj__ValidEnclosure__item___0 (projectee : enclosure_validation) :
  dyadic_enclosure= match projectee with | ValidEnclosure _0 -> _0
let uu___is_InvalidEnclosure (projectee : enclosure_validation) : Prims.bool=
  match projectee with | InvalidEnclosure -> true | uu___ -> false
let validate_enclosure (lower_mantissa : Prims.int)
  (upper_mantissa : Prims.int) (binary_exponent : Prims.int)
  (maximum_exponent : Prims.nat) : enclosure_validation=
  if
    ((lower_mantissa <= upper_mantissa) &&
       (binary_exponent >= (- maximum_exponent)))
      && (binary_exponent <= maximum_exponent)
  then ValidEnclosure { lower_mantissa; upper_mantissa; binary_exponent }
  else InvalidEnclosure
type decimal_enclosure =
  {
  lower_scaled: Prims.int ;
  upper_scaled: Prims.int ;
  decimal_places: Prims.int }
let __proj__Mkdecimal_enclosure__item__lower_scaled
  (projectee : decimal_enclosure) : Prims.int=
  match projectee with
  | { lower_scaled; upper_scaled; decimal_places;_} -> lower_scaled
let __proj__Mkdecimal_enclosure__item__upper_scaled
  (projectee : decimal_enclosure) : Prims.int=
  match projectee with
  | { lower_scaled; upper_scaled; decimal_places;_} -> upper_scaled
let __proj__Mkdecimal_enclosure__item__decimal_places
  (projectee : decimal_enclosure) : Prims.int=
  match projectee with
  | { lower_scaled; upper_scaled; decimal_places;_} -> decimal_places
let rec positive_power (base : Prims.pos) (exponent : Prims.nat) : Prims.pos=
  if exponent = Prims.int_zero
  then Prims.int_one
  else
    if ((mod) exponent (Prims.of_int 2)) = Prims.int_zero
    then
      (let half = positive_power base (exponent / (Prims.of_int 2)) in
       half * half)
    else base * (positive_power base (exponent - Prims.int_one))
type positive_fraction =
  {
  fraction_numerator: Prims.int ;
  fraction_denominator: Prims.pos }
let __proj__Mkpositive_fraction__item__fraction_numerator
  (projectee : positive_fraction) : Prims.int=
  match projectee with
  | { fraction_numerator; fraction_denominator;_} -> fraction_numerator
let __proj__Mkpositive_fraction__item__fraction_denominator
  (projectee : positive_fraction) : Prims.pos=
  match projectee with
  | { fraction_numerator; fraction_denominator;_} -> fraction_denominator
let scaled_dyadic_fraction (mantissa : Prims.int)
  (binary_exponent : Prims.int) (decimal_places : Prims.int) :
  positive_fraction=
  let binary_numerator =
    if binary_exponent >= Prims.int_zero
    then positive_power (Prims.of_int 2) binary_exponent
    else Prims.int_one in
  let binary_denominator =
    if binary_exponent >= Prims.int_zero
    then Prims.int_one
    else positive_power (Prims.of_int 2) (- binary_exponent) in
  let decimal_numerator =
    if decimal_places >= Prims.int_zero
    then positive_power (Prims.of_int 10) decimal_places
    else Prims.int_one in
  let decimal_denominator =
    if decimal_places >= Prims.int_zero
    then Prims.int_one
    else positive_power (Prims.of_int 10) (- decimal_places) in
  {
    fraction_numerator = ((mantissa * binary_numerator) * decimal_numerator);
    fraction_denominator = (binary_denominator * decimal_denominator)
  }
let floor_fraction (value : positive_fraction) : Prims.int=
  value.fraction_numerator / value.fraction_denominator
let ceiling_fraction (value : positive_fraction) : Prims.int=
  - ((- (value.fraction_numerator)) / value.fraction_denominator)
let outward_round_dyadic (source : dyadic_enclosure)
  (decimal_places : Prims.int) : decimal_enclosure=
  let lower =
    scaled_dyadic_fraction source.lower_mantissa source.binary_exponent
      decimal_places in
  let upper =
    scaled_dyadic_fraction source.upper_mantissa source.binary_exponent
      decimal_places in
  let lower_scaled = floor_fraction lower in
  let upper_scaled = ceiling_fraction upper in
  { lower_scaled; upper_scaled; decimal_places }
type decimal_rounding_validation =
  | RoundedDecimalEnclosure of decimal_enclosure 
  | InvalidDecimalRounding 
let uu___is_RoundedDecimalEnclosure (projectee : decimal_rounding_validation)
  : Prims.bool=
  match projectee with | RoundedDecimalEnclosure _0 -> true | uu___ -> false
let __proj__RoundedDecimalEnclosure__item___0
  (projectee : decimal_rounding_validation) : decimal_enclosure=
  match projectee with | RoundedDecimalEnclosure _0 -> _0
let uu___is_InvalidDecimalRounding (projectee : decimal_rounding_validation)
  : Prims.bool=
  match projectee with | InvalidDecimalRounding -> true | uu___ -> false
let round_enclosure_outward (lower_mantissa : Prims.int)
  (upper_mantissa : Prims.int) (binary_exponent : Prims.int)
  (maximum_exponent : Prims.nat) (decimal_places : Prims.int)
  (maximum_decimal_places : Prims.nat) : decimal_rounding_validation=
  if
    ((((lower_mantissa <= upper_mantissa) &&
         (binary_exponent >= (- maximum_exponent)))
        && (binary_exponent <= maximum_exponent))
       && (decimal_places >= (- maximum_decimal_places)))
      && (decimal_places <= maximum_decimal_places)
  then
    let source = { lower_mantissa; upper_mantissa; binary_exponent } in
    RoundedDecimalEnclosure (outward_round_dyadic source decimal_places)
  else InvalidDecimalRounding
let normalize_natural (numerator : Prims.nat) (denominator : Prims.pos) :
  rational=
  let divisor = Centl_Gcd.gcd numerator denominator in
  if divisor > Prims.int_zero
  then
    let reduced_numerator = numerator / divisor in
    let reduced_denominator = denominator / divisor in
    { numerator = reduced_numerator; denominator = reduced_denominator }
  else { numerator; denominator }
let normalize_positive (numerator : Prims.int) (denominator : Prims.pos) :
  rational=
  if numerator >= Prims.int_zero
  then normalize_natural numerator denominator
  else
    (let magnitude = - numerator in
     let magnitude_value = normalize_natural magnitude denominator in
     let result =
       {
         numerator = (- (magnitude_value.numerator));
         denominator = (magnitude_value.denominator)
       } in
     result)
let make (numerator : Prims.int) (denominator : Prims.int) : rational=
  if denominator > Prims.int_zero
  then normalize_positive numerator denominator
  else
    (let result = normalize_positive (- numerator) (- denominator) in result)
type square_root_validation =
  | ValidSquareRoot of rational 
  | InvalidSquareRoot 
let uu___is_ValidSquareRoot (projectee : square_root_validation) :
  Prims.bool=
  match projectee with | ValidSquareRoot _0 -> true | uu___ -> false
let __proj__ValidSquareRoot__item___0 (projectee : square_root_validation) :
  rational= match projectee with | ValidSquareRoot _0 -> _0
let uu___is_InvalidSquareRoot (projectee : square_root_validation) :
  Prims.bool=
  match projectee with | InvalidSquareRoot -> true | uu___ -> false
let validate_square_root (radicand_numerator : Prims.int)
  (radicand_denominator : Prims.int) (root_numerator : Prims.int)
  (root_denominator : Prims.int) : square_root_validation=
  if
    ((((radicand_numerator >= Prims.int_zero) &&
         (radicand_denominator > Prims.int_zero))
        && (root_numerator >= Prims.int_zero))
       && (root_denominator > Prims.int_zero))
      &&
      (((root_numerator * root_numerator) * radicand_denominator) =
         ((radicand_numerator * root_denominator) * root_denominator))
  then ValidSquareRoot (make root_numerator root_denominator)
  else InvalidSquareRoot
let negate (value : rational) : rational=
  make (- (value.numerator)) value.denominator
let add (left : rational) (right : rational) : rational=
  make
    ((left.numerator * right.denominator) +
       (right.numerator * left.denominator))
    (left.denominator * right.denominator)
let subtract (left : rational) (right : rational) : rational=
  make
    ((left.numerator * right.denominator) -
       (right.numerator * left.denominator))
    (left.denominator * right.denominator)
let multiply (left : rational) (right : rational) : rational=
  make (left.numerator * right.numerator)
    (left.denominator * right.denominator)
let rec power_natural (value : rational) (exponent : Prims.nat) : rational=
  if exponent = Prims.int_zero
  then make Prims.int_one Prims.int_one
  else
    if ((mod) exponent (Prims.of_int 2)) = Prims.int_zero
    then
      (let half = power_natural value (exponent / (Prims.of_int 2)) in
       multiply half half)
    else multiply value (power_natural value (exponent - Prims.int_one))
type error =
  | ZeroDenominator 
  | DivisionByZero 
  | UndefinedPower 
let uu___is_ZeroDenominator (projectee : error) : Prims.bool=
  match projectee with | ZeroDenominator -> true | uu___ -> false
let uu___is_DivisionByZero (projectee : error) : Prims.bool=
  match projectee with | DivisionByZero -> true | uu___ -> false
let uu___is_UndefinedPower (projectee : error) : Prims.bool=
  match projectee with | UndefinedPower -> true | uu___ -> false
type outcome =
  | Success of rational 
  | Failure of error 
let uu___is_Success (projectee : outcome) : Prims.bool=
  match projectee with | Success _0 -> true | uu___ -> false
let __proj__Success__item___0 (projectee : outcome) : rational=
  match projectee with | Success _0 -> _0
let uu___is_Failure (projectee : outcome) : Prims.bool=
  match projectee with | Failure _0 -> true | uu___ -> false
let __proj__Failure__item___0 (projectee : outcome) : error=
  match projectee with | Failure _0 -> _0
let divide (left : rational) (right : rational) : outcome=
  if right.numerator = Prims.int_zero
  then Failure DivisionByZero
  else
    Success
      (make (left.numerator * right.denominator)
         (left.denominator * right.numerator))
let power (value : rational) (exponent : Prims.int) : outcome=
  if (exponent = Prims.int_zero) && (value.numerator = Prims.int_zero)
  then Failure UndefinedPower
  else
    if exponent >= Prims.int_zero
    then Success (power_natural value exponent)
    else
      if value.numerator = Prims.int_zero
      then Failure DivisionByZero
      else
        (let reciprocal = make value.denominator value.numerator in
         Success (power_natural reciprocal (- exponent)))
let apply (operator : binary_operator) (left : rational) (right : rational) :
  outcome=
  match operator with
  | Add -> Success (add left right)
  | Subtract -> Success (subtract left right)
  | Multiply -> Success (multiply left right)
  | Divide -> divide left right
type value =
  | ExactRational of rational 
  | ExactSymbolic of expression 
let uu___is_ExactRational (projectee : value) : Prims.bool=
  match projectee with | ExactRational _0 -> true | uu___ -> false
let __proj__ExactRational__item___0 (projectee : value) : rational=
  match projectee with | ExactRational _0 -> _0
let uu___is_ExactSymbolic (projectee : value) : Prims.bool=
  match projectee with | ExactSymbolic _0 -> true | uu___ -> false
let __proj__ExactSymbolic__item___0 (projectee : value) : expression=
  match projectee with | ExactSymbolic _0 -> _0
type evaluation =
  | Evaluated of value 
  | EvaluationFailure of error 
let uu___is_Evaluated (projectee : evaluation) : Prims.bool=
  match projectee with | Evaluated _0 -> true | uu___ -> false
let __proj__Evaluated__item___0 (projectee : evaluation) : value=
  match projectee with | Evaluated _0 -> _0
let uu___is_EvaluationFailure (projectee : evaluation) : Prims.bool=
  match projectee with | EvaluationFailure _0 -> true | uu___ -> false
let __proj__EvaluationFailure__item___0 (projectee : evaluation) : error=
  match projectee with | EvaluationFailure _0 -> _0
let expression_of_value (result : value) : expression=
  match result with
  | ExactRational rational1 ->
      Literal ((rational1.numerator), (rational1.denominator))
  | ExactSymbolic expression1 -> expression1
let is_zero_value (result : value) : Prims.bool=
  match result with
  | ExactRational rational1 -> rational1.numerator = Prims.int_zero
  | ExactSymbolic uu___ -> false
let is_one_value (result : value) : Prims.bool=
  match result with
  | ExactRational rational1 ->
      (rational1.numerator = Prims.int_one) &&
        (rational1.denominator = Prims.int_one)
  | ExactSymbolic uu___ -> false
let rec expression_is_total (term : expression) : Prims.bool=
  match term with
  | Literal (uu___, denominator) -> denominator <> Prims.int_zero
  | Symbol uu___ -> true
  | Negate inner -> expression_is_total inner
  | Binary (Divide, uu___, uu___1) -> false
  | Binary (uu___, left, right) ->
      (expression_is_total left) && (expression_is_total right)
  | Power (base, exponent) ->
      (exponent > Prims.int_zero) && (expression_is_total base)
  | Function (name, argument::[]) ->
      ((((((name = "sin") || (name = "cos")) || (name = "exp")) ||
           (name = "sinh"))
          || (name = "cosh"))
         || (name = "atan"))
        && (expression_is_total argument)
  | Function (uu___, uu___1) -> false
  | Differentiate (uu___, uu___1) -> false
  | Substitute (uu___, uu___1, uu___2) -> false
  | Derivative (uu___, uu___1) -> false
  | Simplify inner -> expression_is_total inner
  | Expand inner -> expression_is_total inner
  | Factor inner -> expression_is_total inner
  | Assuming (uu___, uu___1, uu___2, uu___3) -> false
let value_is_total (result : value) : Prims.bool=
  match result with
  | ExactRational uu___ -> true
  | ExactSymbolic expression1 -> expression_is_total expression1
let scale_symbolic (coefficient : rational) (expression1 : expression) :
  evaluation=
  match expression1 with
  | Binary (Multiply, Literal (numerator, denominator), remainder) ->
      if denominator = Prims.int_zero
      then EvaluationFailure ZeroDenominator
      else
        (let combined = multiply coefficient (make numerator denominator) in
         if
           (combined.numerator = Prims.int_zero) &&
             (expression_is_total remainder)
         then Evaluated (ExactRational combined)
         else
           if
             (combined.numerator = Prims.int_one) &&
               (combined.denominator = Prims.int_one)
           then Evaluated (ExactSymbolic remainder)
           else
             Evaluated
               (ExactSymbolic
                  (Binary
                     (Multiply,
                       (Literal
                          ((combined.numerator), (combined.denominator))),
                       remainder))))
  | uu___ ->
      if
        (coefficient.numerator = Prims.int_zero) &&
          (expression_is_total expression1)
      then Evaluated (ExactRational coefficient)
      else
        if
          (coefficient.numerator = Prims.int_one) &&
            (coefficient.denominator = Prims.int_one)
        then Evaluated (ExactSymbolic expression1)
        else
          Evaluated
            (ExactSymbolic
               (Binary
                  (Multiply,
                    (Literal
                       ((coefficient.numerator), (coefficient.denominator))),
                    expression1)))
let evaluate_rational_outcome (result : outcome) : evaluation=
  match result with
  | Success rational1 -> Evaluated (ExactRational rational1)
  | Failure error1 -> EvaluationFailure error1
let negate_value (result : value) : value=
  match result with
  | ExactRational rational1 -> ExactRational (negate rational1)
  | ExactSymbolic (Negate inner) -> ExactSymbolic inner
  | ExactSymbolic expression1 -> ExactSymbolic (Negate expression1)
let apply_values (operator : binary_operator) (left : value) (right : value)
  : evaluation=
  match (left, right) with
  | (ExactRational left_rational, ExactRational right_rational) ->
      evaluate_rational_outcome (apply operator left_rational right_rational)
  | (uu___, uu___1) ->
      (match operator with
       | Add ->
           if is_zero_value left
           then Evaluated right
           else
             if is_zero_value right
             then Evaluated left
             else
               Evaluated
                 (ExactSymbolic
                    (Binary
                       (Add, (expression_of_value left),
                         (expression_of_value right))))
       | Subtract ->
           if is_zero_value right
           then Evaluated left
           else
             Evaluated
               (ExactSymbolic
                  (Binary
                     (Subtract, (expression_of_value left),
                       (expression_of_value right))))
       | Multiply ->
           (match (left, right) with
            | (ExactRational coefficient, ExactSymbolic expression1) ->
                scale_symbolic coefficient expression1
            | (ExactSymbolic expression1, ExactRational coefficient) ->
                scale_symbolic coefficient expression1
            | (uu___2, uu___3) ->
                if
                  ((is_zero_value left) && (value_is_total right)) ||
                    ((is_zero_value right) && (value_is_total left))
                then
                  Evaluated
                    (ExactRational (make Prims.int_zero Prims.int_one))
                else
                  if is_one_value left
                  then Evaluated right
                  else
                    if is_one_value right
                    then Evaluated left
                    else
                      Evaluated
                        (ExactSymbolic
                           (Binary
                              (Multiply, (expression_of_value left),
                                (expression_of_value right)))))
       | Divide ->
           if is_zero_value right
           then EvaluationFailure DivisionByZero
           else
             if is_one_value right
             then Evaluated left
             else
               Evaluated
                 (ExactSymbolic
                    (Binary
                       (Divide, (expression_of_value left),
                         (expression_of_value right)))))
let power_value (base : value) (exponent : Prims.int) : evaluation=
  match base with
  | ExactRational rational1 ->
      evaluate_rational_outcome (power rational1 exponent)
  | ExactSymbolic expression1 ->
      if exponent = Prims.int_one
      then Evaluated base
      else Evaluated (ExactSymbolic (Power (expression1, exponent)))
type substitution_binding =
  {
  substitution_name: Prims.string ;
  substitution_value: expression }
let __proj__Mksubstitution_binding__item__substitution_name
  (projectee : substitution_binding) : Prims.string=
  match projectee with
  | { substitution_name; substitution_value;_} -> substitution_name
let __proj__Mksubstitution_binding__item__substitution_value
  (projectee : substitution_binding) : expression=
  match projectee with
  | { substitution_name; substitution_value;_} -> substitution_value
let rec substitution_expression_size (term : expression) : Prims.nat=
  match term with
  | Literal (uu___, uu___1) -> Prims.int_one
  | Symbol uu___ -> Prims.int_one
  | Negate inner -> Prims.int_one + (substitution_expression_size inner)
  | Power (inner, uu___) ->
      Prims.int_one + (substitution_expression_size inner)
  | Differentiate (inner, uu___) ->
      Prims.int_one + (substitution_expression_size inner)
  | Derivative (inner, uu___) ->
      Prims.int_one + (substitution_expression_size inner)
  | Simplify inner -> Prims.int_one + (substitution_expression_size inner)
  | Expand inner -> Prims.int_one + (substitution_expression_size inner)
  | Factor inner -> Prims.int_one + (substitution_expression_size inner)
  | Binary (uu___, left, right) ->
      (Prims.int_one + (substitution_expression_size left)) +
        (substitution_expression_size right)
  | Function (uu___, arguments) ->
      Prims.int_one + (substitution_arguments_size arguments)
  | Substitute (inner, uu___, replacement) ->
      (Prims.int_one + (substitution_expression_size inner)) +
        (substitution_expression_size replacement)
  | Assuming (inner, left, uu___, right) ->
      ((Prims.int_one + (substitution_expression_size inner)) +
         (substitution_expression_size left))
        + (substitution_expression_size right)
and substitution_arguments_size (arguments : expression Prims.list) :
  Prims.nat=
  match arguments with
  | [] -> Prims.int_zero
  | argument::rest ->
      (Prims.int_one + (substitution_expression_size argument)) +
        (substitution_arguments_size rest)
let rec expression_mentions_symbol (term : expression) (name : Prims.string)
  : Prims.bool=
  match term with
  | Literal (uu___, uu___1) -> false
  | Symbol symbol -> symbol = name
  | Negate inner -> expression_mentions_symbol inner name
  | Power (inner, uu___) -> expression_mentions_symbol inner name
  | Simplify inner -> expression_mentions_symbol inner name
  | Expand inner -> expression_mentions_symbol inner name
  | Factor inner -> expression_mentions_symbol inner name
  | Binary (uu___, left, right) ->
      (expression_mentions_symbol left name) ||
        (expression_mentions_symbol right name)
  | Function (uu___, arguments) -> expressions_mention_symbol arguments name
  | Differentiate (inner, variable) ->
      (variable = name) || (expression_mentions_symbol inner name)
  | Derivative (inner, variable) ->
      (variable = name) || (expression_mentions_symbol inner name)
  | Substitute (inner, variable, replacement) ->
      ((variable = name) || (expression_mentions_symbol inner name)) ||
        (expression_mentions_symbol replacement name)
  | Assuming (inner, left, uu___, right) ->
      ((expression_mentions_symbol inner name) ||
         (expression_mentions_symbol left name))
        || (expression_mentions_symbol right name)
and expressions_mention_symbol (expressions : expression Prims.list)
  (name : Prims.string) : Prims.bool=
  match expressions with
  | [] -> false
  | expression1::rest ->
      (expression_mentions_symbol expression1 name) ||
        (expressions_mention_symbol rest name)
let rec lookup_substitution (name : Prims.string)
  (substitutions : substitution_binding Prims.list) :
  expression FStar_Pervasives_Native.option=
  match substitutions with
  | [] -> FStar_Pervasives_Native.None
  | substitution::rest ->
      if substitution.substitution_name = name
      then FStar_Pervasives_Native.Some (substitution.substitution_value)
      else lookup_substitution name rest
let rec remove_substitution (name : Prims.string)
  (substitutions : substitution_binding Prims.list) :
  substitution_binding Prims.list=
  match substitutions with
  | [] -> []
  | substitution::rest ->
      if substitution.substitution_name = name
      then remove_substitution name rest
      else substitution :: (remove_substitution name rest)
let rec substitutions_mention (name : Prims.string)
  (substitutions : substitution_binding Prims.list) : Prims.bool=
  match substitutions with
  | [] -> false
  | substitution::rest ->
      (expression_mentions_symbol substitution.substitution_value name) ||
        (substitutions_mention name rest)
let rec substitution_bindings_size
  (substitutions : substitution_binding Prims.list) : Prims.nat=
  match substitutions with
  | [] -> Prims.int_zero
  | substitution::rest ->
      (Prims.int_one +
         (substitution_expression_size substitution.substitution_value))
        + (substitution_bindings_size rest)
let rec substitutions_use_name (name : Prims.string)
  (substitutions : substitution_binding Prims.list) : Prims.bool=
  match substitutions with
  | [] -> false
  | substitution::rest ->
      ((substitution.substitution_name = name) ||
         (expression_mentions_symbol substitution.substitution_value name))
        || (substitutions_use_name name rest)
let rec find_fresh_bound_name (term : expression)
  (substitutions : substitution_binding Prims.list)
  (candidate : Prims.string) (fuel : Prims.nat) : Prims.string=
  if
    (Prims.op_Negation (expression_mentions_symbol term candidate)) &&
      (Prims.op_Negation (substitutions_use_name candidate substitutions))
  then candidate
  else
    if fuel = Prims.int_zero
    then Prims.strcat candidate "_"
    else
      find_fresh_bound_name term substitutions (Prims.strcat candidate "_")
        (fuel - Prims.int_one)
let fresh_bound_name (term : expression)
  (substitutions : substitution_binding Prims.list) (binder : Prims.string) :
  Prims.string=
  find_fresh_bound_name term substitutions
    (Prims.strcat "_centl_bound_" binder)
    ((substitution_expression_size term) +
       (substitution_bindings_size substitutions))
let rec substitute_many (term : expression)
  (substitutions : substitution_binding Prims.list) : expression=
  match term with
  | Literal (uu___, uu___1) -> term
  | Symbol name ->
      (match lookup_substitution name substitutions with
       | FStar_Pervasives_Native.Some replacement -> replacement
       | FStar_Pervasives_Native.None -> term)
  | Negate inner -> Negate (substitute_many inner substitutions)
  | Binary (operator, left, right) ->
      Binary
        (operator, (substitute_many left substitutions),
          (substitute_many right substitutions))
  | Power (base, exponent) ->
      Power ((substitute_many base substitutions), exponent)
  | Function (name, arguments) ->
      if
        (((name = "sum") || (name = "product")) || (name = "integrate")) ||
          (name = "sequence")
      then
        Function
          (name, (substitute_iteration_arguments arguments substitutions))
      else
        if name = "recurrence"
        then
          Function
            (name, (substitute_recurrence_arguments arguments substitutions))
        else
          if name = "solve"
          then
            Function
              (name, (substitute_solve_arguments arguments substitutions))
          else
            Function
              (name, (substitute_many_arguments arguments substitutions))
  | Differentiate (inner, bound_variable) ->
      let inner_substitutions =
        remove_substitution bound_variable substitutions in
      if substitutions_mention bound_variable inner_substitutions
      then
        let fresh = fresh_bound_name inner inner_substitutions bound_variable in
        Differentiate
          ((substitute_many inner
              ({
                 substitution_name = bound_variable;
                 substitution_value = (Symbol fresh)
               } :: inner_substitutions)), fresh)
      else
        Differentiate
          ((substitute_many inner inner_substitutions), bound_variable)
  | Substitute (inner, bound_variable, inner_replacement) ->
      let inner_substitutions =
        remove_substitution bound_variable substitutions in
      if substitutions_mention bound_variable inner_substitutions
      then
        let fresh = fresh_bound_name inner inner_substitutions bound_variable in
        Substitute
          ((substitute_many inner
              ({
                 substitution_name = bound_variable;
                 substitution_value = (Symbol fresh)
               } :: inner_substitutions)), fresh,
            (substitute_many inner_replacement substitutions))
      else
        Substitute
          ((substitute_many inner inner_substitutions), bound_variable,
            (substitute_many inner_replacement substitutions))
  | Derivative (inner, bound_variable) ->
      let inner_substitutions =
        remove_substitution bound_variable substitutions in
      if substitutions_mention bound_variable inner_substitutions
      then
        let fresh = fresh_bound_name inner inner_substitutions bound_variable in
        Derivative
          ((substitute_many inner
              ({
                 substitution_name = bound_variable;
                 substitution_value = (Symbol fresh)
               } :: inner_substitutions)), fresh)
      else
        Derivative
          ((substitute_many inner inner_substitutions), bound_variable)
  | Simplify inner -> Simplify (substitute_many inner substitutions)
  | Expand inner -> Expand (substitute_many inner substitutions)
  | Factor inner -> Factor (substitute_many inner substitutions)
  | Assuming (inner, left, relation1, right) ->
      Assuming
        ((substitute_many inner substitutions),
          (substitute_many left substitutions), relation1,
          (substitute_many right substitutions))
and substitute_many_arguments (arguments : expression Prims.list)
  (substitutions : substitution_binding Prims.list) : expression Prims.list=
  match arguments with
  | [] -> []
  | argument::rest -> (substitute_many argument substitutions) ::
      (substitute_many_arguments rest substitutions)
and substitute_iteration_arguments (arguments : expression Prims.list)
  (substitutions : substitution_binding Prims.list) : expression Prims.list=
  match arguments with
  | body::(Symbol binder)::[] ->
      let body_substitutions = remove_substitution binder substitutions in
      (match body_substitutions with
       | [] -> [body; Symbol binder]
       | uu___ ->
           if substitutions_mention binder body_substitutions
           then
             let fresh = fresh_bound_name body body_substitutions binder in
             [substitute_many body
                ({
                   substitution_name = binder;
                   substitution_value = (Symbol fresh)
                 } :: body_substitutions);
             Symbol fresh]
           else [substitute_many body body_substitutions; Symbol binder])
  | body::(Symbol binder)::lower::upper::[] ->
      let body_substitutions = remove_substitution binder substitutions in
      (match body_substitutions with
       | [] ->
           [body;
           Symbol binder;
           substitute_many lower substitutions;
           substitute_many upper substitutions]
       | uu___ ->
           if substitutions_mention binder body_substitutions
           then
             let fresh = fresh_bound_name body body_substitutions binder in
             [substitute_many body
                ({
                   substitution_name = binder;
                   substitution_value = (Symbol fresh)
                 } :: body_substitutions);
             Symbol fresh;
             substitute_many lower substitutions;
             substitute_many upper substitutions]
           else
             [substitute_many body body_substitutions;
             Symbol binder;
             substitute_many lower substitutions;
             substitute_many upper substitutions])
  | [] -> []
  | argument::rest -> (substitute_many argument substitutions) ::
      (substitute_many_arguments rest substitutions)
and substitute_recurrence_arguments (arguments : expression Prims.list)
  (substitutions : substitution_binding Prims.list) : expression Prims.list=
  match arguments with
  | initial::step::(Symbol original_previous)::(Symbol
      original_variable)::lower::upper::[] ->
      let step_substitutions =
        remove_substitution original_variable
          (remove_substitution original_previous substitutions) in
      let previous =
        if substitutions_mention original_previous step_substitutions
        then
          let scope =
            Function ("recurrence", [step; Symbol original_variable]) in
          fresh_bound_name scope step_substitutions original_previous
        else original_previous in
      let variable =
        if substitutions_mention original_variable step_substitutions
        then
          let scope = Function ("recurrence", [step; Symbol previous]) in
          fresh_bound_name scope step_substitutions original_variable
        else original_variable in
      let renamed_variable_substitutions =
        if variable = original_variable
        then step_substitutions
        else
          {
            substitution_name = original_variable;
            substitution_value = (Symbol variable)
          } :: step_substitutions in
      let scoped_substitutions =
        if previous = original_previous
        then renamed_variable_substitutions
        else
          {
            substitution_name = original_previous;
            substitution_value = (Symbol previous)
          } :: renamed_variable_substitutions in
      [substitute_many initial substitutions;
      substitute_many step scoped_substitutions;
      Symbol previous;
      Symbol variable;
      substitute_many lower substitutions;
      substitute_many upper substitutions]
  | [] -> []
  | argument::rest -> (substitute_many argument substitutions) ::
      (substitute_many_arguments rest substitutions)
and substitute_solve_arguments (arguments : expression Prims.list)
  (substitutions : substitution_binding Prims.list) : expression Prims.list=
  match arguments with
  | left::right::(Symbol binder)::[] ->
      let equation_substitutions = remove_substitution binder substitutions in
      if substitutions_mention binder equation_substitutions
      then
        let equation = Function ("solve", [left; right]) in
        let fresh = fresh_bound_name equation equation_substitutions binder in
        [substitute_many left
           ({ substitution_name = binder; substitution_value = (Symbol fresh)
            } :: equation_substitutions);
        substitute_many right
          ({ substitution_name = binder; substitution_value = (Symbol fresh)
           } :: equation_substitutions);
        Symbol fresh]
      else
        [substitute_many left equation_substitutions;
        substitute_many right equation_substitutions;
        Symbol binder]
  | [] -> []
  | argument::rest -> (substitute_many argument substitutions) ::
      (substitute_many_arguments rest substitutions)
let substitute (term : expression) (variable : Prims.string)
  (replacement : expression) : expression=
  substitute_many term
    [{ substitution_name = variable; substitution_value = replacement }]
let rec differentiate (term : expression) (variable : Prims.string) :
  expression=
  match term with
  | Literal (uu___, uu___1) -> Literal (Prims.int_zero, Prims.int_one)
  | Symbol name ->
      if name = variable
      then Literal (Prims.int_one, Prims.int_one)
      else Literal (Prims.int_zero, Prims.int_one)
  | Negate inner -> Negate (differentiate inner variable)
  | Binary (Add, left, right) ->
      Binary
        (Add, (differentiate left variable), (differentiate right variable))
  | Binary (Subtract, left, right) ->
      Binary
        (Subtract, (differentiate left variable),
          (differentiate right variable))
  | Binary (Multiply, left, right) ->
      Binary
        (Add, (Binary (Multiply, (differentiate left variable), right)),
          (Binary (Multiply, left, (differentiate right variable))))
  | Binary (Divide, left, right) ->
      Binary
        (Divide,
          (Binary
             (Subtract,
               (Binary (Multiply, (differentiate left variable), right)),
               (Binary (Multiply, left, (differentiate right variable))))),
          (Power (right, (Prims.of_int 2))))
  | Power (base, exponent) ->
      if exponent = Prims.int_zero
      then Literal (Prims.int_zero, Prims.int_one)
      else
        if exponent = Prims.int_one
        then differentiate base variable
        else
          Binary
            (Multiply,
              (Binary
                 (Multiply, (Literal (exponent, Prims.int_one)),
                   (Power (base, (exponent - Prims.int_one))))),
              (differentiate base variable))
  | Function (name, argument::[]) ->
      let argument_derivative = differentiate argument variable in
      if name = "sin"
      then
        Binary
          (Multiply, (Function ("cos", [argument])), argument_derivative)
      else
        if name = "cos"
        then
          Binary
            (Multiply, (Negate (Function ("sin", [argument]))),
              argument_derivative)
        else
          if name = "exp"
          then
            Binary
              (Multiply, (Function ("exp", [argument])), argument_derivative)
          else
            if name = "log"
            then Binary (Divide, argument_derivative, argument)
            else
              if name = "sqrt"
              then
                Binary
                  (Divide, argument_derivative,
                    (Binary
                       (Multiply,
                         (Literal ((Prims.of_int 2), Prims.int_one)),
                         (Function ("sqrt", [argument])))))
              else
                if name = "tan"
                then
                  Binary
                    (Divide, argument_derivative,
                      (Power
                         ((Function ("cos", [argument])), (Prims.of_int 2))))
                else
                  if name = "sinh"
                  then
                    Binary
                      (Multiply, (Function ("cosh", [argument])),
                        argument_derivative)
                  else
                    if name = "cosh"
                    then
                      Binary
                        (Multiply, (Function ("sinh", [argument])),
                          argument_derivative)
                    else
                      if name = "tanh"
                      then
                        Binary
                          (Divide, argument_derivative,
                            (Power
                               ((Function ("cosh", [argument])),
                                 (Prims.of_int 2))))
                      else
                        if name = "asin"
                        then
                          Binary
                            (Divide, argument_derivative,
                              (Function
                                 ("sqrt",
                                   [Binary
                                      (Subtract,
                                        (Literal
                                           (Prims.int_one, Prims.int_one)),
                                        (Power (argument, (Prims.of_int 2))))])))
                        else
                          if name = "acos"
                          then
                            Negate
                              (Binary
                                 (Divide, argument_derivative,
                                   (Function
                                      ("sqrt",
                                        [Binary
                                           (Subtract,
                                             (Literal
                                                (Prims.int_one,
                                                  Prims.int_one)),
                                             (Power
                                                (argument, (Prims.of_int 2))))]))))
                          else
                            if name = "atan"
                            then
                              Binary
                                (Divide, argument_derivative,
                                  (Binary
                                     (Add,
                                       (Literal
                                          (Prims.int_one, Prims.int_one)),
                                       (Power (argument, (Prims.of_int 2))))))
                            else Derivative (term, variable)
  | Function (uu___, uu___1) -> Derivative (term, variable)
  | Derivative (uu___, uu___1) -> Derivative (term, variable)
  | Differentiate (uu___, uu___1) -> Derivative (term, variable)
  | Substitute (uu___, uu___1, uu___2) -> Derivative (term, variable)
  | Simplify inner -> differentiate inner variable
  | Expand inner -> differentiate inner variable
  | Factor inner -> differentiate inner variable
  | Assuming (inner, left, relation1, right) ->
      Assuming ((differentiate inner variable), left, relation1, right)
type polynomial_model =
  | PolynomialConstant of Prims.int 
  | PolynomialVariable 
  | PolynomialNegate of polynomial_model 
  | PolynomialAdd of polynomial_model * polynomial_model 
  | PolynomialSubtract of polynomial_model * polynomial_model 
  | PolynomialMultiply of polynomial_model * polynomial_model 
  | PolynomialPower of polynomial_model * Prims.nat 
let uu___is_PolynomialConstant (projectee : polynomial_model) : Prims.bool=
  match projectee with | PolynomialConstant _0 -> true | uu___ -> false
let __proj__PolynomialConstant__item___0 (projectee : polynomial_model) :
  Prims.int= match projectee with | PolynomialConstant _0 -> _0
let uu___is_PolynomialVariable (projectee : polynomial_model) : Prims.bool=
  match projectee with | PolynomialVariable -> true | uu___ -> false
let uu___is_PolynomialNegate (projectee : polynomial_model) : Prims.bool=
  match projectee with | PolynomialNegate _0 -> true | uu___ -> false
let __proj__PolynomialNegate__item___0 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialNegate _0 -> _0
let uu___is_PolynomialAdd (projectee : polynomial_model) : Prims.bool=
  match projectee with | PolynomialAdd (_0, _1) -> true | uu___ -> false
let __proj__PolynomialAdd__item___0 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialAdd (_0, _1) -> _0
let __proj__PolynomialAdd__item___1 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialAdd (_0, _1) -> _1
let uu___is_PolynomialSubtract (projectee : polynomial_model) : Prims.bool=
  match projectee with | PolynomialSubtract (_0, _1) -> true | uu___ -> false
let __proj__PolynomialSubtract__item___0 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialSubtract (_0, _1) -> _0
let __proj__PolynomialSubtract__item___1 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialSubtract (_0, _1) -> _1
let uu___is_PolynomialMultiply (projectee : polynomial_model) : Prims.bool=
  match projectee with | PolynomialMultiply (_0, _1) -> true | uu___ -> false
let __proj__PolynomialMultiply__item___0 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialMultiply (_0, _1) -> _0
let __proj__PolynomialMultiply__item___1 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialMultiply (_0, _1) -> _1
let uu___is_PolynomialPower (projectee : polynomial_model) : Prims.bool=
  match projectee with | PolynomialPower (_0, _1) -> true | uu___ -> false
let __proj__PolynomialPower__item___0 (projectee : polynomial_model) :
  polynomial_model= match projectee with | PolynomialPower (_0, _1) -> _0
let __proj__PolynomialPower__item___1 (projectee : polynomial_model) :
  Prims.nat= match projectee with | PolynomialPower (_0, _1) -> _1
let rec integer_power (base : Prims.int) (exponent : Prims.nat) : Prims.int=
  if exponent = Prims.int_zero
  then Prims.int_one
  else base * (integer_power base (exponent - Prims.int_one))
let rec polynomial_model_value (term : polynomial_model) (point : Prims.int)
  : Prims.int=
  match term with
  | PolynomialConstant value1 -> value1
  | PolynomialVariable -> point
  | PolynomialNegate inner -> - (polynomial_model_value inner point)
  | PolynomialAdd (left, right) ->
      (polynomial_model_value left point) +
        (polynomial_model_value right point)
  | PolynomialSubtract (left, right) ->
      (polynomial_model_value left point) -
        (polynomial_model_value right point)
  | PolynomialMultiply (left, right) ->
      (polynomial_model_value left point) *
        (polynomial_model_value right point)
  | PolynomialPower (base, exponent) ->
      integer_power (polynomial_model_value base point) exponent
let rec polynomial_model_tangent (term : polynomial_model)
  (point : Prims.int) : Prims.int=
  match term with
  | PolynomialConstant uu___ -> Prims.int_zero
  | PolynomialVariable -> Prims.int_one
  | PolynomialNegate inner -> - (polynomial_model_tangent inner point)
  | PolynomialAdd (left, right) ->
      (polynomial_model_tangent left point) +
        (polynomial_model_tangent right point)
  | PolynomialSubtract (left, right) ->
      (polynomial_model_tangent left point) -
        (polynomial_model_tangent right point)
  | PolynomialMultiply (left, right) ->
      ((polynomial_model_tangent left point) *
         (polynomial_model_value right point))
        +
        ((polynomial_model_value left point) *
           (polynomial_model_tangent right point))
  | PolynomialPower (base, exponent) ->
      if exponent = Prims.int_zero
      then Prims.int_zero
      else
        (exponent *
           (integer_power (polynomial_model_value base point)
              (exponent - Prims.int_one)))
          * (polynomial_model_tangent base point)
let rec polynomial_model_derivative (term : polynomial_model) :
  polynomial_model=
  match term with
  | PolynomialConstant uu___ -> PolynomialConstant Prims.int_zero
  | PolynomialVariable -> PolynomialConstant Prims.int_one
  | PolynomialNegate inner ->
      PolynomialNegate (polynomial_model_derivative inner)
  | PolynomialAdd (left, right) ->
      PolynomialAdd
        ((polynomial_model_derivative left),
          (polynomial_model_derivative right))
  | PolynomialSubtract (left, right) ->
      PolynomialSubtract
        ((polynomial_model_derivative left),
          (polynomial_model_derivative right))
  | PolynomialMultiply (left, right) ->
      PolynomialAdd
        ((PolynomialMultiply ((polynomial_model_derivative left), right)),
          (PolynomialMultiply (left, (polynomial_model_derivative right))))
  | PolynomialPower (base, exponent) ->
      if exponent = Prims.int_zero
      then PolynomialConstant Prims.int_zero
      else
        if exponent = Prims.int_one
        then polynomial_model_derivative base
        else
          PolynomialMultiply
            ((PolynomialMultiply
                ((PolynomialConstant exponent),
                  (PolynomialPower (base, (exponent - Prims.int_one))))),
              (polynomial_model_derivative base))
let rec embed_polynomial_model (term : polynomial_model)
  (variable : Prims.string) : expression=
  match term with
  | PolynomialConstant value1 -> Literal (value1, Prims.int_one)
  | PolynomialVariable -> Symbol variable
  | PolynomialNegate inner -> Negate (embed_polynomial_model inner variable)
  | PolynomialAdd (left, right) ->
      Binary
        (Add, (embed_polynomial_model left variable),
          (embed_polynomial_model right variable))
  | PolynomialSubtract (left, right) ->
      Binary
        (Subtract, (embed_polynomial_model left variable),
          (embed_polynomial_model right variable))
  | PolynomialMultiply (left, right) ->
      Binary
        (Multiply, (embed_polynomial_model left variable),
          (embed_polynomial_model right variable))
  | PolynomialPower (base, exponent) ->
      Power ((embed_polynomial_model base variable), exponent)
let rec evaluate_integer_polynomial (term : expression)
  (variable : Prims.string) (point : Prims.int) :
  Prims.int FStar_Pervasives_Native.option=
  match term with
  | Literal (numerator, denominator) ->
      if denominator = Prims.int_one
      then FStar_Pervasives_Native.Some numerator
      else FStar_Pervasives_Native.None
  | Symbol name ->
      if name = variable
      then FStar_Pervasives_Native.Some point
      else FStar_Pervasives_Native.None
  | Negate inner ->
      (match evaluate_integer_polynomial inner variable point with
       | FStar_Pervasives_Native.Some value1 ->
           FStar_Pervasives_Native.Some (- value1)
       | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None)
  | Binary (operator, left, right) ->
      (match ((evaluate_integer_polynomial left variable point),
               (evaluate_integer_polynomial right variable point))
       with
       | (FStar_Pervasives_Native.Some left_value,
          FStar_Pervasives_Native.Some right_value) ->
           (match operator with
            | Add -> FStar_Pervasives_Native.Some (left_value + right_value)
            | Subtract ->
                FStar_Pervasives_Native.Some (left_value - right_value)
            | Multiply ->
                FStar_Pervasives_Native.Some (left_value * right_value)
            | Divide -> FStar_Pervasives_Native.None)
       | (uu___, uu___1) -> FStar_Pervasives_Native.None)
  | Power (base, exponent) ->
      if exponent < Prims.int_zero
      then FStar_Pervasives_Native.None
      else
        (match evaluate_integer_polynomial base variable point with
         | FStar_Pervasives_Native.Some value1 ->
             FStar_Pervasives_Native.Some (integer_power value1 exponent)
         | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None)
  | Function (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Differentiate (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Substitute (uu___, uu___1, uu___2) -> FStar_Pervasives_Native.None
  | Derivative (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Simplify uu___ -> FStar_Pervasives_Native.None
  | Expand uu___ -> FStar_Pervasives_Native.None
  | Factor uu___ -> FStar_Pervasives_Native.None
  | Assuming (uu___, uu___1, uu___2, uu___3) -> FStar_Pervasives_Native.None
type coefficient = rational
type polynomial = coefficient Prims.list
type variable_scan =
  | NoVariable 
  | OneVariable of Prims.string 
  | NotUnivariate 
let uu___is_NoVariable (projectee : variable_scan) : Prims.bool=
  match projectee with | NoVariable -> true | uu___ -> false
let uu___is_OneVariable (projectee : variable_scan) : Prims.bool=
  match projectee with | OneVariable _0 -> true | uu___ -> false
let __proj__OneVariable__item___0 (projectee : variable_scan) : Prims.string=
  match projectee with | OneVariable _0 -> _0
let uu___is_NotUnivariate (projectee : variable_scan) : Prims.bool=
  match projectee with | NotUnivariate -> true | uu___ -> false
let maximum_expansion_exponent : Prims.nat= Prims.of_int 64
let merge_variable_scan (left : variable_scan) (right : variable_scan) :
  variable_scan=
  match (left, right) with
  | (NotUnivariate, uu___) -> NotUnivariate
  | (uu___, NotUnivariate) -> NotUnivariate
  | (NoVariable, result) -> result
  | (result, NoVariable) -> result
  | (OneVariable left_name, OneVariable right_name) ->
      if left_name = right_name then left else NotUnivariate
let rec scan_polynomial_variable (term : expression) : variable_scan=
  match term with
  | Literal (uu___, uu___1) -> NoVariable
  | Symbol name -> OneVariable name
  | Negate inner -> scan_polynomial_variable inner
  | Binary (Add, left, right) ->
      merge_variable_scan (scan_polynomial_variable left)
        (scan_polynomial_variable right)
  | Binary (Subtract, left, right) ->
      merge_variable_scan (scan_polynomial_variable left)
        (scan_polynomial_variable right)
  | Binary (Multiply, left, right) ->
      merge_variable_scan (scan_polynomial_variable left)
        (scan_polynomial_variable right)
  | Binary (Divide, left, right) ->
      (match scan_polynomial_variable right with
       | NoVariable -> scan_polynomial_variable left
       | uu___ -> NotUnivariate)
  | Power (base, exponent) ->
      if
        (exponent > Prims.int_zero) &&
          (exponent <= maximum_expansion_exponent)
      then scan_polynomial_variable base
      else NotUnivariate
  | Function (uu___, uu___1) -> NotUnivariate
  | Differentiate (uu___, uu___1) -> NotUnivariate
  | Substitute (uu___, uu___1, uu___2) -> NotUnivariate
  | Derivative (uu___, uu___1) -> NotUnivariate
  | Simplify inner -> scan_polynomial_variable inner
  | Expand inner -> scan_polynomial_variable inner
  | Factor inner -> scan_polynomial_variable inner
  | Assuming (uu___, uu___1, uu___2, uu___3) -> NotUnivariate
let rec polynomial_add (left : polynomial) (right : polynomial) : polynomial=
  match (left, right) with
  | ([], result) -> result
  | (result, []) -> result
  | (left_head::left_tail, right_head::right_tail) ->
      (add left_head right_head) :: (polynomial_add left_tail right_tail)
let rec polynomial_negate (value1 : polynomial) : polynomial=
  match value1 with
  | [] -> []
  | head::tail -> (negate head) :: (polynomial_negate tail)
let polynomial_subtract (left : polynomial) (right : polynomial) :
  polynomial= polynomial_add left (polynomial_negate right)
let rec polynomial_scale (factor : coefficient) (value1 : polynomial) :
  polynomial=
  match value1 with
  | [] -> []
  | head::tail -> (multiply factor head) :: (polynomial_scale factor tail)
let rec polynomial_multiply (left : polynomial) (right : polynomial) :
  polynomial=
  match left with
  | [] -> []
  | head::tail ->
      polynomial_add (polynomial_scale head right)
        ((make Prims.int_zero Prims.int_one) ::
        (polynomial_multiply tail right))
let rec polynomial_power (base : polynomial) (exponent : Prims.nat) :
  polynomial=
  if exponent = Prims.int_zero
  then [make Prims.int_one Prims.int_one]
  else
    polynomial_multiply base
      (polynomial_power base (exponent - Prims.int_one))
let rec polynomial_tail_is_zero (value1 : polynomial) : Prims.bool=
  match value1 with
  | [] -> true
  | head::tail ->
      (head.numerator = Prims.int_zero) && (polynomial_tail_is_zero tail)
let polynomial_constant (value1 : polynomial) :
  coefficient FStar_Pervasives_Native.option=
  match value1 with
  | [] -> FStar_Pervasives_Native.Some (make Prims.int_zero Prims.int_one)
  | head::tail ->
      if polynomial_tail_is_zero tail
      then FStar_Pervasives_Native.Some head
      else FStar_Pervasives_Native.None
let polynomial_divide_constant (numerator : polynomial)
  (denominator : polynomial) : polynomial FStar_Pervasives_Native.option=
  match polynomial_constant denominator with
  | FStar_Pervasives_Native.Some value1 ->
      if value1.numerator = Prims.int_zero
      then FStar_Pervasives_Native.None
      else
        FStar_Pervasives_Native.Some
          (polynomial_scale (make value1.denominator value1.numerator)
             numerator)
  | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
let rec polynomial_of (term : expression) (variable : Prims.string) :
  polynomial FStar_Pervasives_Native.option=
  match term with
  | Literal (numerator, denominator) ->
      if denominator = Prims.int_zero
      then FStar_Pervasives_Native.None
      else FStar_Pervasives_Native.Some [make numerator denominator]
  | Symbol name ->
      if name = variable
      then
        FStar_Pervasives_Native.Some
          [make Prims.int_zero Prims.int_one;
          make Prims.int_one Prims.int_one]
      else FStar_Pervasives_Native.None
  | Negate inner ->
      (match polynomial_of inner variable with
       | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
       | FStar_Pervasives_Native.Some value1 ->
           FStar_Pervasives_Native.Some (polynomial_negate value1))
  | Binary (operator, left, right) ->
      (match ((polynomial_of left variable), (polynomial_of right variable))
       with
       | (FStar_Pervasives_Native.Some left_value,
          FStar_Pervasives_Native.Some right_value) ->
           (match operator with
            | Add ->
                FStar_Pervasives_Native.Some
                  (polynomial_add left_value right_value)
            | Subtract ->
                FStar_Pervasives_Native.Some
                  (polynomial_subtract left_value right_value)
            | Multiply ->
                FStar_Pervasives_Native.Some
                  (polynomial_multiply left_value right_value)
            | Divide -> polynomial_divide_constant left_value right_value)
       | (uu___, uu___1) -> FStar_Pervasives_Native.None)
  | Power (base, exponent) ->
      if
        (exponent > Prims.int_zero) &&
          (exponent <= maximum_expansion_exponent)
      then
        (match polynomial_of base variable with
         | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
         | FStar_Pervasives_Native.Some value1 ->
             FStar_Pervasives_Native.Some (polynomial_power value1 exponent))
      else FStar_Pervasives_Native.None
  | Function (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Differentiate (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Substitute (uu___, uu___1, uu___2) -> FStar_Pervasives_Native.None
  | Derivative (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Simplify inner -> polynomial_of inner variable
  | Expand inner -> polynomial_of inner variable
  | Factor inner -> polynomial_of inner variable
  | Assuming (uu___, uu___1, uu___2, uu___3) -> FStar_Pervasives_Native.None
type equation_classification =
  | NoEquationSolutions 
  | AllEquationValues 
  | OneEquationSolution of rational 
  | TwoEquationSolutions of rational * rational 
  | RationalQuadratic of rational * rational * rational 
  | UnresolvedEquation 
let uu___is_NoEquationSolutions (projectee : equation_classification) :
  Prims.bool=
  match projectee with | NoEquationSolutions -> true | uu___ -> false
let uu___is_AllEquationValues (projectee : equation_classification) :
  Prims.bool=
  match projectee with | AllEquationValues -> true | uu___ -> false
let uu___is_OneEquationSolution (projectee : equation_classification) :
  Prims.bool=
  match projectee with | OneEquationSolution _0 -> true | uu___ -> false
let __proj__OneEquationSolution__item___0
  (projectee : equation_classification) : rational=
  match projectee with | OneEquationSolution _0 -> _0
let uu___is_TwoEquationSolutions (projectee : equation_classification) :
  Prims.bool=
  match projectee with
  | TwoEquationSolutions (_0, _1) -> true
  | uu___ -> false
let __proj__TwoEquationSolutions__item___0
  (projectee : equation_classification) : rational=
  match projectee with | TwoEquationSolutions (_0, _1) -> _0
let __proj__TwoEquationSolutions__item___1
  (projectee : equation_classification) : rational=
  match projectee with | TwoEquationSolutions (_0, _1) -> _1
let uu___is_RationalQuadratic (projectee : equation_classification) :
  Prims.bool=
  match projectee with
  | RationalQuadratic (leading, linear, discriminant) -> true
  | uu___ -> false
let __proj__RationalQuadratic__item__leading
  (projectee : equation_classification) : rational=
  match projectee with
  | RationalQuadratic (leading, linear, discriminant) -> leading
let __proj__RationalQuadratic__item__linear
  (projectee : equation_classification) : rational=
  match projectee with
  | RationalQuadratic (leading, linear, discriminant) -> linear
let __proj__RationalQuadratic__item__discriminant
  (projectee : equation_classification) : rational=
  match projectee with
  | RationalQuadratic (leading, linear, discriminant) -> discriminant
let uu___is_UnresolvedEquation (projectee : equation_classification) :
  Prims.bool=
  match projectee with | UnresolvedEquation -> true | uu___ -> false
let classify_constant_equation (constant : coefficient) :
  equation_classification=
  if constant.numerator = Prims.int_zero
  then AllEquationValues
  else NoEquationSolutions
let solve_linear_equation (constant : coefficient) (linear : coefficient) :
  equation_classification=
  if linear.numerator = Prims.int_zero
  then classify_constant_equation constant
  else
    (match divide (negate constant) linear with
     | Success root -> OneEquationSolution root
     | Failure uu___ -> UnresolvedEquation)
let classify_quadratic_equation (constant : coefficient)
  (linear : coefficient) (leading : coefficient) : equation_classification=
  if leading.numerator = Prims.int_zero
  then solve_linear_equation constant linear
  else
    (let four = make (Prims.of_int 4) Prims.int_one in
     let discriminant =
       subtract (multiply linear linear)
         (multiply four (multiply leading constant)) in
     if discriminant.numerator < Prims.int_zero
     then NoEquationSolutions
     else
       if discriminant.numerator = Prims.int_zero
       then
         (let denominator =
            multiply (make (Prims.of_int 2) Prims.int_one) leading in
          match divide (negate linear) denominator with
          | Success root -> OneEquationSolution root
          | Failure uu___ -> UnresolvedEquation)
       else RationalQuadratic (leading, linear, discriminant))
let classify_polynomial_equation (coefficients : polynomial) :
  equation_classification=
  match coefficients with
  | [] -> AllEquationValues
  | constant::tail ->
      if polynomial_tail_is_zero tail
      then classify_constant_equation constant
      else
        (match tail with
         | [] -> classify_constant_equation constant
         | linear::quadratic_tail ->
             if polynomial_tail_is_zero quadratic_tail
             then solve_linear_equation constant linear
             else
               (match quadratic_tail with
                | [] -> solve_linear_equation constant linear
                | leading::higher ->
                    if polynomial_tail_is_zero higher
                    then classify_quadratic_equation constant linear leading
                    else UnresolvedEquation))
let solve_equation (left : expression) (right : expression)
  (variable : Prims.string) : equation_classification=
  match polynomial_of (Binary (Subtract, left, right)) variable with
  | FStar_Pervasives_Native.None -> UnresolvedEquation
  | FStar_Pervasives_Native.Some coefficients ->
      classify_polynomial_equation coefficients
let complete_rational_quadratic (leading : rational) (linear : rational)
  (discriminant : rational) (root : rational) : equation_classification=
  if
    (((((((leading.denominator <= Prims.int_zero) ||
            (linear.denominator <= Prims.int_zero))
           || (discriminant.denominator <= Prims.int_zero))
          || (root.denominator <= Prims.int_zero))
         || (leading.numerator = Prims.int_zero))
        || (discriminant.numerator <= Prims.int_zero))
       || (root.numerator < Prims.int_zero))
      ||
      (((root.numerator * root.numerator) * discriminant.denominator) <>
         ((discriminant.numerator * root.denominator) * root.denominator))
  then UnresolvedEquation
  else
    (let denominator = multiply (make (Prims.of_int 2) Prims.int_one) leading in
     let negative_linear = negate linear in
     match ((divide (subtract negative_linear root) denominator),
             (divide (add negative_linear root) denominator))
     with
     | (Success first, Success second) ->
         TwoEquationSolutions (first, second)
     | (uu___, uu___1) -> UnresolvedEquation)
type signed_term =
  | PositiveTerm of expression 
  | NegativeTerm of expression 
let uu___is_PositiveTerm (projectee : signed_term) : Prims.bool=
  match projectee with | PositiveTerm _0 -> true | uu___ -> false
let __proj__PositiveTerm__item___0 (projectee : signed_term) : expression=
  match projectee with | PositiveTerm _0 -> _0
let uu___is_NegativeTerm (projectee : signed_term) : Prims.bool=
  match projectee with | NegativeTerm _0 -> true | uu___ -> false
let __proj__NegativeTerm__item___0 (projectee : signed_term) : expression=
  match projectee with | NegativeTerm _0 -> _0
let coefficient_is_one (value1 : coefficient) : Prims.bool=
  (value1.numerator = Prims.int_one) && (value1.denominator = Prims.int_one)
let coefficient_is_integer (value1 : coefficient) (integer : Prims.int) :
  Prims.bool=
  (value1.numerator = integer) && (value1.denominator = Prims.int_one)
let polynomial_term (value1 : coefficient) (variable : Prims.string)
  (degree : Prims.nat) : signed_term FStar_Pervasives_Native.option=
  if value1.numerator = Prims.int_zero
  then FStar_Pervasives_Native.None
  else
    (let negative = value1.numerator < Prims.int_zero in
     let magnitude = if negative then negate value1 else value1 in
     let term =
       if degree = Prims.int_zero
       then Literal ((magnitude.numerator), (magnitude.denominator))
       else
         (let variable_term =
            if degree = Prims.int_one
            then Symbol variable
            else Power ((Symbol variable), degree) in
          if coefficient_is_one magnitude
          then variable_term
          else
            Binary
              (Multiply,
                (Literal ((magnitude.numerator), (magnitude.denominator))),
                variable_term)) in
     if negative
     then FStar_Pervasives_Native.Some (NegativeTerm term)
     else FStar_Pervasives_Native.Some (PositiveTerm term))
let add_polynomial_term (higher : expression FStar_Pervasives_Native.option)
  (current : signed_term FStar_Pervasives_Native.option) :
  expression FStar_Pervasives_Native.option=
  match (higher, current) with
  | (FStar_Pervasives_Native.None, FStar_Pervasives_Native.None) ->
      FStar_Pervasives_Native.None
  | (FStar_Pervasives_Native.Some expression1, FStar_Pervasives_Native.None)
      -> FStar_Pervasives_Native.Some expression1
  | (FStar_Pervasives_Native.None, FStar_Pervasives_Native.Some (PositiveTerm
     expression1)) -> FStar_Pervasives_Native.Some expression1
  | (FStar_Pervasives_Native.None, FStar_Pervasives_Native.Some (NegativeTerm
     expression1)) -> FStar_Pervasives_Native.Some (Negate expression1)
  | (FStar_Pervasives_Native.Some expression1, FStar_Pervasives_Native.Some
     (PositiveTerm current1)) ->
      FStar_Pervasives_Native.Some (Binary (Add, expression1, current1))
  | (FStar_Pervasives_Native.Some expression1, FStar_Pervasives_Native.Some
     (NegativeTerm current1)) ->
      FStar_Pervasives_Native.Some (Binary (Subtract, expression1, current1))
let rec polynomial_expression_from (coefficients : polynomial)
  (variable : Prims.string) (degree : Prims.nat) :
  expression FStar_Pervasives_Native.option=
  match coefficients with
  | [] -> FStar_Pervasives_Native.None
  | head::tail ->
      let higher =
        polynomial_expression_from tail variable (degree + Prims.int_one) in
      add_polynomial_term higher (polynomial_term head variable degree)
let polynomial_expression (coefficients : polynomial)
  (variable : Prims.string) : expression=
  match polynomial_expression_from coefficients variable Prims.int_zero with
  | FStar_Pervasives_Native.None -> Literal (Prims.int_zero, Prims.int_one)
  | FStar_Pervasives_Native.Some expression1 -> expression1
let antiderivative_coefficient (value1 : coefficient) (degree : Prims.pos) :
  coefficient= make value1.numerator (value1.denominator * degree)
let rec polynomial_antiderivative_tail (coefficients : polynomial)
  (degree : Prims.pos) : polynomial=
  match coefficients with
  | [] -> []
  | coefficient1::rest -> (antiderivative_coefficient coefficient1 degree) ::
      (polynomial_antiderivative_tail rest (degree + Prims.int_one))
let polynomial_antiderivative_coefficients (coefficients : polynomial) :
  polynomial= (make Prims.int_zero Prims.int_one) ::
  (polynomial_antiderivative_tail coefficients Prims.int_one)
let derivative_coefficient (value1 : coefficient) (degree : Prims.pos) :
  coefficient=
  {
    numerator = (value1.numerator * degree);
    denominator = (value1.denominator)
  }
let rec polynomial_derivative_tail (coefficients : polynomial)
  (degree : Prims.pos) : polynomial=
  match coefficients with
  | [] -> []
  | coefficient1::rest -> (derivative_coefficient coefficient1 degree) ::
      (polynomial_derivative_tail rest (degree + Prims.int_one))
let polynomial_derivative_coefficients (coefficients : polynomial) :
  polynomial=
  match coefficients with
  | [] -> []
  | _constant::higher -> polynomial_derivative_tail higher Prims.int_one
let rec polynomial_evaluate_horner (coefficients : polynomial)
  (point : coefficient) : coefficient=
  match coefficients with
  | [] -> make Prims.int_zero Prims.int_one
  | constant::higher ->
      add constant (multiply point (polynomial_evaluate_horner higher point))
let polynomial_definite_integral_coefficients (coefficients : polynomial)
  (lower : coefficient) (upper : coefficient) : coefficient=
  let antiderivative = polynomial_antiderivative_coefficients coefficients in
  subtract (polynomial_evaluate_horner antiderivative upper)
    (polynomial_evaluate_horner antiderivative lower)
let integrate_polynomial (term : expression) (variable : Prims.string) :
  expression FStar_Pervasives_Native.option=
  match polynomial_of term variable with
  | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
  | FStar_Pervasives_Native.Some coefficients ->
      FStar_Pervasives_Native.Some
        (polynomial_expression
           (polynomial_antiderivative_coefficients coefficients) variable)
let definite_integral_polynomial (term : expression)
  (variable : Prims.string) (lower : rational) (upper : rational) :
  rational FStar_Pervasives_Native.option=
  if
    (lower.denominator <= Prims.int_zero) ||
      (upper.denominator <= Prims.int_zero)
  then FStar_Pervasives_Native.None
  else
    (match polynomial_of term variable with
     | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
     | FStar_Pervasives_Native.Some coefficients ->
         let normalized_lower = make lower.numerator lower.denominator in
         let normalized_upper = make upper.numerator upper.denominator in
         FStar_Pervasives_Native.Some
           (polynomial_definite_integral_coefficients coefficients
              normalized_lower normalized_upper))
let canonicalize_polynomial (term : expression) : expression=
  match scan_polynomial_variable term with
  | NoVariable -> term
  | NotUnivariate -> term
  | OneVariable variable ->
      (match polynomial_of term variable with
       | FStar_Pervasives_Native.None -> term
       | FStar_Pervasives_Native.Some coefficients ->
           polynomial_expression coefficients variable)
let square_base (term : expression) :
  expression FStar_Pervasives_Native.option=
  match term with
  | Power (base, exponent) ->
      if
        (exponent > Prims.int_zero) &&
          (((mod) exponent (Prims.of_int 2)) = Prims.int_zero)
      then
        (if exponent = (Prims.of_int 2)
         then FStar_Pervasives_Native.Some base
         else
           FStar_Pervasives_Native.Some
             (Power (base, (exponent / (Prims.of_int 2)))))
      else FStar_Pervasives_Native.None
  | Literal (numerator, denominator) ->
      if (numerator = Prims.int_one) && (denominator = Prims.int_one)
      then FStar_Pervasives_Native.Some term
      else FStar_Pervasives_Native.None
  | uu___ -> FStar_Pervasives_Native.None
let difference_of_squares (term : expression) :
  expression FStar_Pervasives_Native.option=
  match term with
  | Binary (Subtract, left, right) ->
      (match ((square_base left), (square_base right)) with
       | (FStar_Pervasives_Native.Some left_base,
          FStar_Pervasives_Native.Some right_base) ->
           FStar_Pervasives_Native.Some
             (Binary
                (Multiply, (Binary (Subtract, left_base, right_base)),
                  (Binary (Add, left_base, right_base))))
       | (uu___, uu___1) -> FStar_Pervasives_Native.None)
  | uu___ -> FStar_Pervasives_Native.None
let rec drop_zero_coefficients (coefficients : polynomial) :
  (Prims.nat * polynomial)=
  match coefficients with
  | [] -> (Prims.int_zero, [])
  | head::tail ->
      if head.numerator = Prims.int_zero
      then
        let uu___ = drop_zero_coefficients tail in
        (match uu___ with
         | (degree, remainder) -> ((degree + Prims.int_one), remainder))
      else (Prims.int_zero, coefficients)
let factor_polynomial (canonical : expression) (variable : Prims.string)
  (coefficients : polynomial) : expression=
  match coefficients with
  | constant::linear::quadratic::[] ->
      if
        ((coefficient_is_integer constant (Prims.of_int (-1))) &&
           (coefficient_is_integer linear Prims.int_zero))
          && (coefficient_is_integer quadratic Prims.int_one)
      then
        Binary
          (Multiply,
            (Binary
               (Subtract, (Symbol variable),
                 (Literal (Prims.int_one, Prims.int_one)))),
            (Binary
               (Add, (Symbol variable),
                 (Literal (Prims.int_one, Prims.int_one)))))
      else
        if
          ((coefficient_is_integer constant Prims.int_one) &&
             (coefficient_is_integer linear (Prims.of_int 2)))
            && (coefficient_is_integer quadratic Prims.int_one)
        then
          Power
            ((Binary
                (Add, (Symbol variable),
                  (Literal (Prims.int_one, Prims.int_one)))),
              (Prims.of_int 2))
        else
          if
            ((coefficient_is_integer constant Prims.int_one) &&
               (coefficient_is_integer linear (Prims.of_int (-2))))
              && (coefficient_is_integer quadratic Prims.int_one)
          then
            Power
              ((Binary
                  (Subtract, (Symbol variable),
                    (Literal (Prims.int_one, Prims.int_one)))),
                (Prims.of_int 2))
          else
            (let uu___ = drop_zero_coefficients coefficients in
             match uu___ with
             | (degree, remainder) ->
                 if
                   (degree = Prims.int_zero) ||
                     ((degree > Prims.int_zero) && (remainder = []))
                 then canonical
                 else
                   Binary
                     (Multiply,
                       (if degree = Prims.int_one
                        then Symbol variable
                        else Power ((Symbol variable), degree)),
                       (polynomial_expression remainder variable)))
  | uu___ ->
      let uu___1 = drop_zero_coefficients coefficients in
      (match uu___1 with
       | (degree, remainder) ->
           if
             (degree = Prims.int_zero) ||
               ((degree > Prims.int_zero) && (remainder = []))
           then canonical
           else
             Binary
               (Multiply,
                 (if degree = Prims.int_one
                  then Symbol variable
                  else Power ((Symbol variable), degree)),
                 (polynomial_expression remainder variable)))
let factor_expression (term : expression) : expression=
  let canonical = canonicalize_polynomial term in
  match difference_of_squares canonical with
  | FStar_Pervasives_Native.Some factored -> factored
  | FStar_Pervasives_Native.None ->
      (match scan_polynomial_variable canonical with
       | OneVariable variable ->
           (match polynomial_of canonical variable with
            | FStar_Pervasives_Native.Some coefficients ->
                factor_polynomial canonical variable coefficients
            | FStar_Pervasives_Native.None -> canonical)
       | uu___ -> canonical)
let is_zero_literal (term : expression) : Prims.bool=
  match term with
  | Literal (numerator, denominator) ->
      (numerator = Prims.int_zero) && (denominator <> Prims.int_zero)
  | uu___ -> false
let condition_proves_nonzero (term : expression) (left : expression)
  (relation1 : relation) (right : expression) : Prims.bool=
  let strict =
    ((relation1 = NotEqual) || (relation1 = LessThan)) ||
      (relation1 = GreaterThan) in
  strict &&
    (((term = left) && (is_zero_literal right)) ||
       ((term = right) && (is_zero_literal left)))
let rec simplify_assuming (term : expression) (left : expression)
  (relation1 : relation) (right : expression) : expression=
  match term with
  | Literal (uu___, uu___1) -> term
  | Symbol uu___ -> term
  | Negate inner -> Negate (simplify_assuming inner left relation1 right)
  | Binary (operator, inner_left, inner_right) ->
      let simplified_left = simplify_assuming inner_left left relation1 right in
      let simplified_right =
        simplify_assuming inner_right left relation1 right in
      (match operator with
       | Divide ->
           if
             (simplified_left = simplified_right) &&
               (condition_proves_nonzero simplified_right left relation1
                  right)
           then Literal (Prims.int_one, Prims.int_one)
           else Binary (Divide, simplified_left, simplified_right)
       | uu___ -> Binary (operator, simplified_left, simplified_right))
  | Power (base, exponent) ->
      let simplified = simplify_assuming base left relation1 right in
      if
        (exponent = Prims.int_zero) &&
          (condition_proves_nonzero simplified left relation1 right)
      then Literal (Prims.int_one, Prims.int_one)
      else Power (simplified, exponent)
  | Function (name, arguments) ->
      Function
        (name, (simplify_assuming_arguments arguments left relation1 right))
  | Differentiate (inner, variable) ->
      Differentiate
        ((simplify_assuming inner left relation1 right), variable)
  | Substitute (inner, variable, replacement) ->
      Substitute
        ((simplify_assuming inner left relation1 right), variable,
          (simplify_assuming replacement left relation1 right))
  | Derivative (inner, variable) ->
      Derivative ((simplify_assuming inner left relation1 right), variable)
  | Simplify inner -> Simplify (simplify_assuming inner left relation1 right)
  | Expand inner -> Expand (simplify_assuming inner left relation1 right)
  | Factor inner -> Factor (simplify_assuming inner left relation1 right)
  | Assuming (inner, nested_left, nested_relation, nested_right) ->
      Assuming
        ((simplify_assuming inner left relation1 right), nested_left,
          nested_relation, nested_right)
and simplify_assuming_arguments (arguments : expression Prims.list)
  (left : expression) (relation1 : relation) (right : expression) :
  expression Prims.list=
  match arguments with
  | [] -> []
  | argument::rest -> (simplify_assuming argument left relation1 right) ::
      (simplify_assuming_arguments rest left relation1 right)
let magnitude (value1 : Prims.int) : Prims.nat=
  if value1 < Prims.int_zero then - value1 else value1
let rec factorial_loop (remaining : Prims.nat) (accumulator : Prims.nat) :
  Prims.nat=
  if remaining = Prims.int_zero
  then accumulator
  else factorial_loop (remaining - Prims.int_one) (accumulator * remaining)
let factorial_natural (value1 : Prims.nat) : Prims.nat=
  factorial_loop value1 Prims.int_one
let rec choose_product (next : Prims.nat) (remaining : Prims.nat)
  (divisor : Prims.pos) (accumulator : Prims.nat) : Prims.nat=
  if remaining = Prims.int_zero
  then accumulator
  else
    choose_product (next + Prims.int_one) (remaining - Prims.int_one)
      (divisor + Prims.int_one) ((accumulator * next) / divisor)
let choose_natural (n : Prims.nat) (k : Prims.nat) : Prims.nat=
  if k > n
  then Prims.int_zero
  else
    (let selected = if k > (n - k) then n - k else k in
     choose_product ((n - selected) + Prims.int_one) selected Prims.int_one
       Prims.int_one)
let rec fibonacci_loop (remaining : Prims.nat) (current : Prims.nat)
  (next : Prims.nat) : Prims.nat=
  if remaining = Prims.int_zero
  then current
  else fibonacci_loop (remaining - Prims.int_one) next (current + next)
let fibonacci_natural (value1 : Prims.nat) : Prims.nat=
  fibonacci_loop value1 Prims.int_zero Prims.int_one
let rec falling_product (next : Prims.nat) (remaining : Prims.nat)
  (accumulator : Prims.nat) : Prims.nat=
  if remaining = Prims.int_zero
  then accumulator
  else
    falling_product (next - Prims.int_one) (remaining - Prims.int_one)
      (accumulator * next)
let integer_literal (term : expression) :
  Prims.int FStar_Pervasives_Native.option=
  match term with
  | Literal (value1, uu___) when uu___ = Prims.int_one ->
      FStar_Pervasives_Native.Some value1
  | Negate (Literal (value1, uu___)) when uu___ = Prims.int_one ->
      FStar_Pervasives_Native.Some (- value1)
  | uu___ -> FStar_Pervasives_Native.None
let rewrite_function (name : Prims.string)
  (arguments : expression Prims.list) : expression=
  match (name, arguments) with
  | ("sin", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_zero, Prims.int_one)
  | ("tan", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_zero, Prims.int_one)
  | ("sinh", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_zero, Prims.int_one)
  | ("tanh", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_zero, Prims.int_one)
  | ("atan", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_zero, Prims.int_one)
  | ("log", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_one) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_zero, Prims.int_one)
  | ("cos", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_one, Prims.int_one)
  | ("cosh", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_one, Prims.int_one)
  | ("exp", (Literal (uu___, uu___1))::[]) when
      (uu___ = Prims.int_zero) && (uu___1 = Prims.int_one) ->
      Literal (Prims.int_one, Prims.int_one)
  | ("square_area", side::[]) -> Power (side, (Prims.of_int 2))
  | ("rectangle_area", width::height::[]) -> Binary (Multiply, width, height)
  | ("rectangle_perimeter", width::height::[]) ->
      Binary
        (Multiply, (Literal ((Prims.of_int 2), Prims.int_one)),
          (Binary (Add, width, height)))
  | ("triangle_area", base::height::[]) ->
      Binary
        (Divide, (Binary (Multiply, base, height)),
          (Literal ((Prims.of_int 2), Prims.int_one)))
  | ("trapezoid_area", left_base::right_base::height::[]) ->
      Binary
        (Divide,
          (Binary (Multiply, (Binary (Add, left_base, right_base)), height)),
          (Literal ((Prims.of_int 2), Prims.int_one)))
  | ("hypot", left::right::[]) ->
      Function
        ("sqrt",
          [Binary
             (Add, (Power (left, (Prims.of_int 2))),
               (Power (right, (Prims.of_int 2))))])
  | ("distance", x1::y1::x2::y2::[]) ->
      Function
        ("sqrt",
          [Binary
             (Add, (Power ((Binary (Subtract, x2, x1)), (Prims.of_int 2))),
               (Power ((Binary (Subtract, y2, y1)), (Prims.of_int 2))))])
  | ("circle_area", radius::[]) ->
      Binary (Multiply, (Symbol "pi"), (Power (radius, (Prims.of_int 2))))
  | ("circumference", radius::[]) ->
      Binary
        (Multiply, (Literal ((Prims.of_int 2), Prims.int_one)),
          (Binary (Multiply, (Symbol "pi"), radius)))
  | ("sphere_area", radius::[]) ->
      Binary
        (Multiply, (Literal ((Prims.of_int 4), Prims.int_one)),
          (Binary
             (Multiply, (Symbol "pi"), (Power (radius, (Prims.of_int 2))))))
  | ("sphere_volume", radius::[]) ->
      Binary
        (Multiply, (Literal ((Prims.of_int 4), (Prims.of_int 3))),
          (Binary
             (Multiply, (Symbol "pi"), (Power (radius, (Prims.of_int 3))))))
  | ("cylinder_volume", radius::height::[]) ->
      Binary
        (Multiply,
          (Binary
             (Multiply, (Symbol "pi"), (Power (radius, (Prims.of_int 2))))),
          height)
  | ("slope", x1::y1::x2::y2::[]) ->
      Binary
        (Divide, (Binary (Subtract, y2, y1)), (Binary (Subtract, x2, x1)))
  | ("radians", degrees::[]) ->
      Binary
        (Multiply,
          (Binary
             (Divide, degrees, (Literal ((Prims.of_int 180), Prims.int_one)))),
          (Symbol "pi"))
  | ("degrees", (Symbol "pi")::[]) ->
      Literal ((Prims.of_int 180), Prims.int_one)
  | ("degrees", radians::[]) ->
      Binary
        (Divide,
          (Binary
             (Multiply, radians,
               (Literal ((Prims.of_int 180), Prims.int_one)))),
          (Symbol "pi"))
  | ("integrate", body::(Symbol variable)::[]) ->
      (match integrate_polynomial body variable with
       | FStar_Pervasives_Native.Some antiderivative -> antiderivative
       | FStar_Pervasives_Native.None -> Function (name, arguments))
  | ("integrate", body::(Symbol variable)::(Literal
     (lower_numerator, lower_denominator))::(Literal
     (upper_numerator, upper_denominator))::[]) ->
      (match definite_integral_polynomial body variable
               { numerator = lower_numerator; denominator = lower_denominator
               }
               { numerator = upper_numerator; denominator = upper_denominator
               }
       with
       | FStar_Pervasives_Native.Some value1 ->
           Literal ((value1.numerator), (value1.denominator))
       | FStar_Pervasives_Native.None -> Function (name, arguments))
  | ("gcd", left::right::[]) ->
      (match ((integer_literal left), (integer_literal right)) with
       | (FStar_Pervasives_Native.Some left_value,
          FStar_Pervasives_Native.Some right_value) ->
           Literal
             ((Centl_Gcd.gcd (magnitude left_value) (magnitude right_value)),
               Prims.int_one)
       | (uu___, uu___1) -> Function (name, arguments))
  | ("lcm", left::right::[]) ->
      (match ((integer_literal left), (integer_literal right)) with
       | (FStar_Pervasives_Native.Some left_value,
          FStar_Pervasives_Native.Some right_value) ->
           let left_magnitude = magnitude left_value in
           let right_magnitude = magnitude right_value in
           if
             (left_magnitude = Prims.int_zero) ||
               (right_magnitude = Prims.int_zero)
           then Literal (Prims.int_zero, Prims.int_one)
           else
             (let divisor = Centl_Gcd.gcd left_magnitude right_magnitude in
              if divisor = Prims.int_zero
              then Function (name, arguments)
              else
                Literal
                  (((left_magnitude / divisor) * right_magnitude),
                    Prims.int_one))
       | (uu___, uu___1) -> Function (name, arguments))
  | ("factorial", argument::[]) ->
      (match integer_literal argument with
       | FStar_Pervasives_Native.Some value1 ->
           if value1 >= Prims.int_zero
           then Literal ((factorial_natural value1), Prims.int_one)
           else Function (name, arguments)
       | FStar_Pervasives_Native.None -> Function (name, arguments))
  | ("choose", n_argument::k_argument::[]) ->
      (match ((integer_literal n_argument), (integer_literal k_argument))
       with
       | (FStar_Pervasives_Native.Some n, FStar_Pervasives_Native.Some k) ->
           if (n >= Prims.int_zero) && (k >= Prims.int_zero)
           then Literal ((choose_natural n k), Prims.int_one)
           else Function (name, arguments)
       | (uu___, uu___1) -> Function (name, arguments))
  | ("permutations", n_argument::k_argument::[]) ->
      (match ((integer_literal n_argument), (integer_literal k_argument))
       with
       | (FStar_Pervasives_Native.Some n, FStar_Pervasives_Native.Some k) ->
           if ((n >= Prims.int_zero) && (k >= Prims.int_zero)) && (k <= n)
           then Literal ((falling_product n k Prims.int_one), Prims.int_one)
           else Function (name, arguments)
       | (uu___, uu___1) -> Function (name, arguments))
  | ("fibonacci", argument::[]) ->
      (match integer_literal argument with
       | FStar_Pervasives_Native.Some value1 ->
           if value1 >= Prims.int_zero
           then Literal ((fibonacci_natural value1), Prims.int_one)
           else Function (name, arguments)
       | FStar_Pervasives_Native.None -> Function (name, arguments))
  | (uu___, uu___1) -> Function (name, arguments)
let rec resolve_arguments (arguments : expression Prims.list) :
  expression Prims.list=
  match arguments with
  | [] -> []
  | argument::rest -> (resolve argument) :: (resolve_arguments rest)
and resolve (term : expression) : expression=
  match term with
  | Literal (uu___, uu___1) -> term
  | Symbol uu___ -> term
  | Negate inner -> Negate (resolve inner)
  | Binary (operator, left, right) ->
      Binary (operator, (resolve left), (resolve right))
  | Power (base, exponent) -> Power ((resolve base), exponent)
  | Function (name, arguments) ->
      rewrite_function name (resolve_arguments arguments)
  | Derivative (inner, variable) -> Derivative ((resolve inner), variable)
  | Differentiate (inner, variable) -> differentiate (resolve inner) variable
  | Substitute (inner, variable, replacement) ->
      substitute (resolve inner) variable (resolve replacement)
  | Simplify inner -> canonicalize_polynomial (resolve inner)
  | Expand inner -> canonicalize_polynomial (resolve inner)
  | Factor inner -> factor_expression (resolve inner)
  | Assuming (inner, left, relation1, right) ->
      let resolved_left = resolve left in
      let resolved_right = resolve right in
      Assuming
        ((simplify_assuming (resolve inner) resolved_left relation1
            resolved_right), resolved_left, relation1, resolved_right)
type argument_evaluation =
  | EvaluatedArguments of expression Prims.list 
  | ArgumentEvaluationFailure of error 
let uu___is_EvaluatedArguments (projectee : argument_evaluation) :
  Prims.bool=
  match projectee with | EvaluatedArguments _0 -> true | uu___ -> false
let __proj__EvaluatedArguments__item___0 (projectee : argument_evaluation) :
  expression Prims.list= match projectee with | EvaluatedArguments _0 -> _0
let uu___is_ArgumentEvaluationFailure (projectee : argument_evaluation) :
  Prims.bool=
  match projectee with
  | ArgumentEvaluationFailure _0 -> true
  | uu___ -> false
let __proj__ArgumentEvaluationFailure__item___0
  (projectee : argument_evaluation) : error=
  match projectee with | ArgumentEvaluationFailure _0 -> _0
let rec evaluate_arguments (arguments : expression Prims.list) :
  argument_evaluation=
  match arguments with
  | [] -> EvaluatedArguments []
  | argument::rest ->
      (match evaluate argument with
       | EvaluationFailure error1 -> ArgumentEvaluationFailure error1
       | Evaluated value1 ->
           (match evaluate_arguments rest with
            | ArgumentEvaluationFailure error1 ->
                ArgumentEvaluationFailure error1
            | EvaluatedArguments values ->
                EvaluatedArguments ((expression_of_value value1) :: values)))
and evaluate (term : expression) : evaluation=
  match term with
  | Literal (numerator, denominator) ->
      if denominator = Prims.int_zero
      then EvaluationFailure ZeroDenominator
      else Evaluated (ExactRational (make numerator denominator))
  | Symbol name -> Evaluated (ExactSymbolic (Symbol name))
  | Negate inner ->
      (match evaluate inner with
       | EvaluationFailure error1 -> EvaluationFailure error1
       | Evaluated value1 -> Evaluated (negate_value value1))
  | Binary (operator, left, right) ->
      (match evaluate left with
       | EvaluationFailure error1 -> EvaluationFailure error1
       | Evaluated left_value ->
           (match evaluate right with
            | EvaluationFailure error1 -> EvaluationFailure error1
            | Evaluated right_value ->
                apply_values operator left_value right_value))
  | Power (base, exponent) ->
      (match evaluate base with
       | EvaluationFailure error1 -> EvaluationFailure error1
       | Evaluated value1 -> power_value value1 exponent)
  | Function (name, arguments) ->
      (match evaluate_arguments arguments with
       | ArgumentEvaluationFailure error1 -> EvaluationFailure error1
       | EvaluatedArguments values ->
           Evaluated (ExactSymbolic (Function (name, values))))
  | Derivative (inner, variable) ->
      (match evaluate inner with
       | EvaluationFailure error1 -> EvaluationFailure error1
       | Evaluated value1 ->
           Evaluated
             (ExactSymbolic
                (Derivative ((expression_of_value value1), variable))))
  | Differentiate (inner, variable) ->
      (match evaluate inner with
       | EvaluationFailure error1 -> EvaluationFailure error1
       | Evaluated value1 ->
           Evaluated
             (ExactSymbolic
                (Differentiate ((expression_of_value value1), variable))))
  | Substitute (inner, variable, replacement) ->
      (match evaluate inner with
       | EvaluationFailure error1 -> EvaluationFailure error1
       | Evaluated inner_value ->
           (match evaluate replacement with
            | EvaluationFailure error1 -> EvaluationFailure error1
            | Evaluated replacement_value ->
                Evaluated
                  (ExactSymbolic
                     (Substitute
                        ((expression_of_value inner_value), variable,
                          (expression_of_value replacement_value))))))
  | Simplify inner -> evaluate inner
  | Expand inner -> evaluate inner
  | Factor inner -> evaluate inner
  | Assuming (inner, left, relation1, right) ->
      (match evaluate inner with
       | EvaluationFailure error1 -> EvaluationFailure error1
       | Evaluated inner_value ->
           (match evaluate left with
            | EvaluationFailure error1 -> EvaluationFailure error1
            | Evaluated left_value ->
                (match evaluate right with
                 | EvaluationFailure error1 -> EvaluationFailure error1
                 | Evaluated right_value ->
                     Evaluated
                       (ExactSymbolic
                          (Assuming
                             ((expression_of_value inner_value),
                               (expression_of_value left_value), relation1,
                               (expression_of_value right_value)))))))
