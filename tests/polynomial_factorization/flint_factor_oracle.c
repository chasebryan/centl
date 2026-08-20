#include <flint/flint.h>
#include <flint/fmpz.h>
#include <flint/fmpz_poly.h>
#include <flint/fmpz_poly_factor.h>

#include <errno.h>
#include <stdlib.h>
#include <string.h>

static void fail(const char *message)
{
    flint_fprintf(stderr, "%s\n", message);
    exit(2);
}

static void parse_dense(fmpz_poly_t polynomial, const char *encoded)
{
    size_t length = strlen(encoded);
    char *copy = (char *) flint_malloc(length + 1);
    memcpy(copy, encoded, length + 1);

    slong exponent = 0;
    char *token = strtok(copy, ",");
    while (token != NULL)
    {
        char *end = NULL;
        errno = 0;
        long coefficient = strtol(token, &end, 10);
        if (errno != 0 || end == token || *end != '\0')
        {
            flint_free(copy);
            fail("invalid dense integer coefficient");
        }
        fmpz_poly_set_coeff_si(polynomial, exponent, coefficient);
        exponent++;
        token = strtok(NULL, ",");
    }

    flint_free(copy);
}

static void print_factor(const fmpz_poly_struct *polynomial, slong multiplicity)
{
    slong degree = fmpz_poly_degree(polynomial);
    fmpz_t coefficient;
    fmpz_init(coefficient);

    flint_printf("{\"multiplicity\":%wd,\"coefficients\":[", multiplicity);
    for (slong exponent = 0; exponent <= degree; exponent++)
    {
        if (exponent != 0)
            flint_printf(",");
        fmpz_poly_get_coeff_fmpz(coefficient, polynomial, exponent);
        flint_printf("\"");
        fmpz_print(coefficient);
        flint_printf("\"");
    }
    flint_printf("]}");

    fmpz_clear(coefficient);
}

int main(int argc, char **argv)
{
    if (argc != 2)
        fail("usage: flint_factor_oracle COEFF0,COEFF1,...");

    fmpz_poly_t polynomial;
    fmpz_poly_factor_t factors;
    fmpz_poly_init(polynomial);
    fmpz_poly_factor_init(factors);

    parse_dense(polynomial, argv[1]);
    if (fmpz_poly_is_zero(polynomial))
        fail("FLINT differential oracle requires a nonzero polynomial");

    fmpz_poly_factor(factors, polynomial);

    flint_printf("{\"factors\":[");
    for (slong index = 0; index < factors->num; index++)
    {
        if (index != 0)
            flint_printf(",");
        print_factor(factors->p + index, factors->exp[index]);
    }
    flint_printf("]}\n");

    fmpz_poly_factor_clear(factors);
    fmpz_poly_clear(polynomial);
    flint_cleanup();
    return 0;
}
