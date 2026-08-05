#define CAML_NAME_SPACE

#if defined(_WIN32) && !defined(CAMLDLLIMPORT)
#define CAMLDLLIMPORT __declspec(dllimport)
#endif

#include <limits.h>

#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <gmp.h>
#include <flint/arb.h>
#include <flint/fmpq.h>
#include <flint/fmpz.h>
#include <flint/flint.h>

/* FlexDLL scans Windows static archives once. Seed GMP symbols that are only
   discovered after it extracts the FLINT conversion objects. */
#if defined(_WIN32) && defined(__GNUC__)
typedef int (*centl_mpz_set_str_fn)(mpz_ptr, const char *, int);
typedef double (*centl_mpz_get_d_fn)(mpz_srcptr);
typedef void (*centl_mpz_set_d_fn)(mpz_ptr, double);

static centl_mpz_set_str_fn const centl_mpz_set_str_root __attribute__((used)) = mpz_set_str;
static centl_mpz_get_d_fn const centl_mpz_get_d_root __attribute__((used)) = mpz_get_d;
static centl_mpz_set_d_fn const centl_mpz_set_d_root __attribute__((used)) = mpz_set_d;
#endif

#if defined(_WIN32)
#define CENTL_PRIM CAMLprim __declspec(dllexport)
#else
#define CENTL_PRIM CAMLprim
#endif

#define Arb_val(value) ((arb_struct *)Data_custom_val(value))

/* Mirror the engine's upper work/exponent ceilings and require a positive Arb
   precision. Keeping the checks at the C boundary makes direct use of the
   low-level OCaml module fail safely instead of handing nonsensical sizes to
   FLINT. */
#define CENTL_MIN_PRECISION 2L
#define CENTL_MAX_PRECISION 16384L
#define CENTL_MAX_EXPONENT 100000L

static long centl_precision(value precision_value)
{
    long precision = Long_val(precision_value);
    if (precision < CENTL_MIN_PRECISION || precision > CENTL_MAX_PRECISION) {
        caml_invalid_argument("CENTL Arb precision");
    }
    return precision;
}

static int centl_is_decimal_integer(value text_value)
{
    const char *text = String_val(text_value);
    mlsize_t length = caml_string_length(text_value);
    mlsize_t index = 0;

    if (length == 0) return 0;
    if (text[0] == '-') {
        if (length == 1) return 0;
        index = 1;
    }
    for (; index < length; ++index) {
        if (text[index] < '0' || text[index] > '9') return 0;
    }
    return 1;
}

static void centl_arb_finalize(value wrapped)
{
    arb_clear(Arb_val(wrapped));
}

static struct custom_operations centl_arb_operations = {
    "net.nosuchmachine.centl.arb",
    centl_arb_finalize,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

static value centl_alloc_arb(void)
{
    value result = caml_alloc_custom(&centl_arb_operations, sizeof(arb_struct), 0, 1);
    arb_init(Arb_val(result));
    return result;
}

CENTL_PRIM value centl_arb_of_fraction(value numerator_value, value denominator_value,
                                       value precision_value)
{
    CAMLparam3(numerator_value, denominator_value, precision_value);
    CAMLlocal1(result);
    fmpz_t numerator;
    fmpz_t denominator;
    fmpq_t fraction;
    long precision = centl_precision(precision_value);

    fmpz_init(numerator);
    fmpz_init(denominator);
    fmpq_init(fraction);
    if (!centl_is_decimal_integer(numerator_value) ||
        !centl_is_decimal_integer(denominator_value) ||
        fmpz_set_str(numerator, String_val(numerator_value), 10) != 0 ||
        fmpz_set_str(denominator, String_val(denominator_value), 10) != 0 ||
        fmpz_is_zero(denominator)) {
        fmpq_clear(fraction);
        fmpz_clear(denominator);
        fmpz_clear(numerator);
        caml_invalid_argument("CENTL Arb fraction");
    }
    fmpq_set_fmpz_frac(fraction, numerator, denominator);
    result = centl_alloc_arb();
    arb_set_fmpq(Arb_val(result), fraction, precision);
    fmpq_clear(fraction);
    fmpz_clear(denominator);
    fmpz_clear(numerator);
    CAMLreturn(result);
}

CENTL_PRIM value centl_arb_pi(value precision_value)
{
    CAMLparam1(precision_value);
    CAMLlocal1(result);
    long precision = centl_precision(precision_value);
    result = centl_alloc_arb();
    arb_const_pi(Arb_val(result), precision);
    CAMLreturn(result);
}

CENTL_PRIM value centl_arb_neg(value input_value)
{
    CAMLparam1(input_value);
    CAMLlocal1(result);
    result = centl_alloc_arb();
    arb_neg(Arb_val(result), Arb_val(input_value));
    CAMLreturn(result);
}

CENTL_PRIM value centl_arb_abs(value input_value)
{
    CAMLparam1(input_value);
    CAMLlocal1(result);
    result = centl_alloc_arb();
    arb_abs(Arb_val(result), Arb_val(input_value));
    CAMLreturn(result);
}

#define CENTL_ARB_BINARY(name, operation)                                      \
    CENTL_PRIM value name(value left_value, value right_value, value precision_value) \
    {                                                                          \
        CAMLparam3(left_value, right_value, precision_value);                   \
        CAMLlocal1(result);                                                     \
        long precision = centl_precision(precision_value);                      \
        result = centl_alloc_arb();                                             \
        operation(Arb_val(result), Arb_val(left_value), Arb_val(right_value),   \
                  precision);                                                   \
        CAMLreturn(result);                                                     \
    }

CENTL_ARB_BINARY(centl_arb_add, arb_add)
CENTL_ARB_BINARY(centl_arb_sub, arb_sub)
CENTL_ARB_BINARY(centl_arb_mul, arb_mul)
CENTL_ARB_BINARY(centl_arb_div, arb_div)
CENTL_ARB_BINARY(centl_arb_atan2, arb_atan2)

CENTL_PRIM value centl_arb_pow(value base_value, value exponent_value,
                               value precision_value)
{
    CAMLparam3(base_value, exponent_value, precision_value);
    CAMLlocal1(result);
    long exponent = Long_val(exponent_value);
    long precision = centl_precision(precision_value);
    if (exponent < -CENTL_MAX_EXPONENT || exponent > CENTL_MAX_EXPONENT) {
        caml_invalid_argument("CENTL Arb exponent");
    }
    result = centl_alloc_arb();
    if (exponent >= 0) {
        arb_pow_ui(Arb_val(result), Arb_val(base_value), (ulong)exponent,
                   precision);
    } else {
        arb_t temporary;
        arb_init(temporary);
        arb_pow_ui(temporary, Arb_val(base_value), (ulong)(-exponent),
                   precision);
        arb_one(Arb_val(result));
        arb_div(Arb_val(result), Arb_val(result), temporary, precision);
        arb_clear(temporary);
    }
    CAMLreturn(result);
}

#define CENTL_ARB_UNARY(name, operation)                                      \
    CENTL_PRIM value name(value input_value, value precision_value)            \
    {                                                                          \
        CAMLparam2(input_value, precision_value);                              \
        CAMLlocal1(result);                                                     \
        long precision = centl_precision(precision_value);                      \
        result = centl_alloc_arb();                                             \
        operation(Arb_val(result), Arb_val(input_value), precision);            \
        CAMLreturn(result);                                                     \
    }

CENTL_ARB_UNARY(centl_arb_sqrt, arb_sqrt)
CENTL_ARB_UNARY(centl_arb_exp, arb_exp)
CENTL_ARB_UNARY(centl_arb_log, arb_log)
CENTL_ARB_UNARY(centl_arb_sin, arb_sin)
CENTL_ARB_UNARY(centl_arb_cos, arb_cos)
CENTL_ARB_UNARY(centl_arb_tan, arb_tan)
CENTL_ARB_UNARY(centl_arb_asin, arb_asin)
CENTL_ARB_UNARY(centl_arb_acos, arb_acos)
CENTL_ARB_UNARY(centl_arb_atan, arb_atan)
CENTL_ARB_UNARY(centl_arb_sinh, arb_sinh)
CENTL_ARB_UNARY(centl_arb_cosh, arb_cosh)
CENTL_ARB_UNARY(centl_arb_tanh, arb_tanh)

CENTL_PRIM value centl_arb_endpoints(value input_value)
{
    CAMLparam1(input_value);
    CAMLlocal4(result, lower_value, upper_value, exponent_value);
    fmpz_t lower;
    fmpz_t upper;
    fmpz_t exponent;
    char *lower_text;
    char *upper_text;
    char *exponent_text;

    fmpz_init(lower);
    fmpz_init(upper);
    fmpz_init(exponent);
    arb_get_interval_fmpz_2exp(lower, upper, exponent, Arb_val(input_value));
    lower_text = fmpz_get_str(NULL, 10, lower);
    upper_text = fmpz_get_str(NULL, 10, upper);
    exponent_text = fmpz_get_str(NULL, 10, exponent);
    lower_value = caml_copy_string(lower_text);
    upper_value = caml_copy_string(upper_text);
    exponent_value = caml_copy_string(exponent_text);
    flint_free(lower_text);
    flint_free(upper_text);
    flint_free(exponent_text);
    fmpz_clear(lower);
    fmpz_clear(upper);
    fmpz_clear(exponent);
    result = caml_alloc_tuple(3);
    Store_field(result, 0, lower_value);
    Store_field(result, 1, upper_value);
    Store_field(result, 2, exponent_value);
    CAMLreturn(result);
}

CENTL_PRIM value centl_arb_classification(value input_value)
{
    CAMLparam1(input_value);
    int result = 0;
    const arb_struct *input = Arb_val(input_value);
    if (arb_is_finite(input)) result |= 1;
    if (arb_is_zero(input)) result |= 2;
    if (arb_is_nonzero(input)) result |= 4;
    if (arb_is_positive(input)) result |= 8;
    if (arb_is_nonnegative(input)) result |= 16;
    if (arb_is_negative(input)) result |= 32;
    if (arb_is_nonpositive(input)) result |= 64;
    CAMLreturn(Val_int(result));
}
