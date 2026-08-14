#include <stdio.h>

#include <gmp.h>
#include <flint/arb.h>
#include <flint/flint.h>

int main(void)
{
    arb_t sample;
    arb_init(sample);
    arb_set_si(sample, 2);
    printf("centl marsa native probe: flint %s gmp %s\n", FLINT_VERSION,
           gmp_version);
    arb_clear(sample);
    flint_cleanup();
    return 0;
}
