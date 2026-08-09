open Prims
let raw_add (left : Centl_Core.rational) (right : Centl_Core.rational) :
  Centl_Core.rational=
  {
    Centl_Core.numerator =
      ((left.Centl_Core.numerator * right.Centl_Core.denominator) +
         (right.Centl_Core.numerator * left.Centl_Core.denominator));
    Centl_Core.denominator =
      (left.Centl_Core.denominator * right.Centl_Core.denominator)
  }
let raw_multiply (left : Centl_Core.rational) (right : Centl_Core.rational) :
  Centl_Core.rational=
  {
    Centl_Core.numerator =
      (left.Centl_Core.numerator * right.Centl_Core.numerator);
    Centl_Core.denominator =
      (left.Centl_Core.denominator * right.Centl_Core.denominator)
  }
let rec rational_polynomial_model_of_expression
  (term : Centl_Core.expression) (variable : Prims.string) :
  Centl_Core.rational_polynomial_model FStar_Pervasives_Native.option=
  match term with
  | Centl_Core.Literal (numerator, denominator) ->
      if denominator = Prims.int_zero
      then FStar_Pervasives_Native.None
      else
        FStar_Pervasives_Native.Some
          (Centl_Core.RZConstant (Centl_Core.make numerator denominator))
  | Centl_Core.Symbol name ->
      if name = variable
      then FStar_Pervasives_Native.Some Centl_Core.RZVariable
      else FStar_Pervasives_Native.None
  | Centl_Core.Negate inner ->
      (match rational_polynomial_model_of_expression inner variable with
       | FStar_Pervasives_Native.Some model ->
           FStar_Pervasives_Native.Some (Centl_Core.RZNegate model)
       | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None)
  | Centl_Core.Binary (operator, left, right) ->
      (match ((rational_polynomial_model_of_expression left variable),
               (rational_polynomial_model_of_expression right variable))
       with
       | (FStar_Pervasives_Native.Some left_model,
          FStar_Pervasives_Native.Some right_model) ->
           (match operator with
            | Centl_Core.Add ->
                FStar_Pervasives_Native.Some
                  (Centl_Core.RZAdd (left_model, right_model))
            | Centl_Core.Subtract ->
                FStar_Pervasives_Native.Some
                  (Centl_Core.RZSubtract (left_model, right_model))
            | Centl_Core.Multiply ->
                FStar_Pervasives_Native.Some
                  (Centl_Core.RZMultiply (left_model, right_model))
            | Centl_Core.Divide -> FStar_Pervasives_Native.None)
       | (uu___, uu___1) -> FStar_Pervasives_Native.None)
  | Centl_Core.Power (base, exponent) ->
      if
        (exponent > Prims.int_zero) &&
          (exponent <= Centl_Core.maximum_expansion_exponent)
      then
        (match rational_polynomial_model_of_expression base variable with
         | FStar_Pervasives_Native.Some model ->
             FStar_Pervasives_Native.Some
               (Centl_Core.RZPower (model, exponent))
         | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None)
      else FStar_Pervasives_Native.None
  | Centl_Core.Simplify inner ->
      rational_polynomial_model_of_expression inner variable
  | Centl_Core.Expand inner ->
      rational_polynomial_model_of_expression inner variable
  | Centl_Core.Factor inner ->
      rational_polynomial_model_of_expression inner variable
  | Centl_Core.Function (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Centl_Core.Differentiate (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Centl_Core.Substitute (uu___, uu___1, uu___2) ->
      FStar_Pervasives_Native.None
  | Centl_Core.Derivative (uu___, uu___1) -> FStar_Pervasives_Native.None
  | Centl_Core.Assuming (uu___, uu___1, uu___2, uu___3) ->
      FStar_Pervasives_Native.None
type polynomial_identity_classification =
  | VerifiedPolynomialIdentity 
  | NonzeroPolynomialIdentity 
  | UnsupportedPolynomialIdentity 
let uu___is_VerifiedPolynomialIdentity
  (projectee : polynomial_identity_classification) : Prims.bool=
  match projectee with | VerifiedPolynomialIdentity -> true | uu___ -> false
let uu___is_NonzeroPolynomialIdentity
  (projectee : polynomial_identity_classification) : Prims.bool=
  match projectee with | NonzeroPolynomialIdentity -> true | uu___ -> false
let uu___is_UnsupportedPolynomialIdentity
  (projectee : polynomial_identity_classification) : Prims.bool=
  match projectee with
  | UnsupportedPolynomialIdentity -> true
  | uu___ -> false
let classify_polynomial_identity (left : Centl_Core.expression)
  (right : Centl_Core.expression) (variable : Prims.string) :
  polynomial_identity_classification=
  match ((rational_polynomial_model_of_expression left variable),
          (rational_polynomial_model_of_expression right variable))
  with
  | (FStar_Pervasives_Native.Some left_model, FStar_Pervasives_Native.Some
     right_model) ->
      if
        Centl_Core.polynomial_is_zero
          (Centl_Core.collect_rational_polynomial_model
             (Centl_Core.RZSubtract (left_model, right_model)))
      then VerifiedPolynomialIdentity
      else NonzeroPolynomialIdentity
  | (uu___, uu___1) -> UnsupportedPolynomialIdentity
