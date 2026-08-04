#!/usr/bin/env julia

using Nemo
using Random
using JSON3

const repository_root = normpath(joinpath(@__DIR__, "..", ".."))
const centl = get(ENV, "CENTL_BIN", joinpath(repository_root, "centl"))
const rational_polynomial_ring, rational_polynomial_variable =
    polynomial_ring(QQ, "x")

function exact_json_value(value, expression::String)
    Bool(value.exact) || error(
        "CENTL returned an inexact sequence item for $(expression)",
    )
    kind = String(value.kind)
    if kind == "integer"
        return QQ(parse(BigInt, String(value.value)))
    elseif kind == "rational"
        return QQ(
            parse(BigInt, String(value.numerator)),
            parse(BigInt, String(value.denominator)),
        )
    end
    error("CENTL returned non-rational kind $(kind) for $(expression)")
end

function centl_response(expression::String)
    command = Cmd([centl, "--json", expression])
    response = JSON3.read(read(command, String))
    response.ok || error(
        "CENTL rejected differential expression $(expression): " *
        String(response.error.code) * ": " * String(response.error.message),
    )
    return response
end

function centl_exact(expression::String)
    response = centl_response(expression)
    return exact_json_value(response.value, expression)
end

function centl_exact_sequence(expression::String)
    response = centl_response(expression)
    value = response.value
    kind = String(value.kind)
    kind == "sequence" || error(
        "CENTL returned non-sequence kind $(kind) for $(expression)",
    )
    Bool(value.exact) || error(
        "CENTL returned an inexact sequence for $(expression)",
    )
    items = [exact_json_value(item, expression) for item in value.items]
    Int(value.length) == length(items) || error(
        "CENTL returned inconsistent sequence length for $(expression)",
    )
    return items
end

function exact_text(value)
    numerator_text = string(numerator(value))
    denominator_value = denominator(value)
    return isone(denominator_value) ? numerator_text :
           numerator_text * "/" * string(denominator_value)
end

function check_exact(expression::String, expected)
    expected = QQ(expected)
    actual = centl_exact(expression)
    actual == expected || error(
        "CENTL differential mismatch\n" *
        "  expression: " * expression * "\n" *
        "  expected:   " * exact_text(expected) * "\n" *
        "  actual:     " * exact_text(actual),
    )
end

function check_exact_sequence(expression::String, expected)
    expected = [QQ(value) for value in expected]
    actual = centl_exact_sequence(expression)
    actual == expected || error(
        "CENTL sequence differential mismatch\n" *
        "  expression: " * expression * "\n" *
        "  expected:   [" * join(exact_text.(expected), ", ") * "]\n" *
        "  actual:     [" * join(exact_text.(actual), ", ") * "]",
    )
end

function polynomial_sum(lower::Int, upper::Int, power::Int)
    total = ZZ(0)
    for value in lower:upper
        total += ZZ(value)^power
    end
    return total
end

function linear_product(lower::Int, upper::Int, offset::Int)
    total = ZZ(1)
    for value in lower:upper
        total *= ZZ(value + offset)
    end
    return total
end

function rational_source(value)
    "(" * exact_text(QQ(value)) * ")"
end

function polynomial_source(coefficients)
    terms = String[]
    for (offset, coefficient) in enumerate(coefficients)
        iszero(coefficient) && continue
        degree = offset - 1
        coefficient_text = rational_source(coefficient)
        term = if degree == 0
            coefficient_text
        elseif degree == 1
            coefficient_text * "*x"
        else
            coefficient_text * "*x^" * string(degree)
        end
        push!(terms, term)
    end
    isempty(terms) ? "0" : join(terms, " + ")
end

function polynomial_integral_between(coefficients, lower, upper)
    polynomial = zero(rational_polynomial_ring)
    for (offset, coefficient) in enumerate(coefficients)
        polynomial += coefficient * rational_polynomial_variable^(offset - 1)
    end
    antiderivative = integral(polynomial)
    evaluate(antiderivative, upper) - evaluate(antiderivative, lower)
end

function check_polynomial_integral(coefficients, lower, upper)
    expression =
        "integrate(" * polynomial_source(coefficients) * ", x = " *
        rational_source(lower) * ", " * rational_source(upper) * ")"
    expected = polynomial_integral_between(coefficients, lower, upper)
    check_exact(expression, expected)
end

function run_differential_suite()
    check_exact("0.1 + 0.2", QQ(3, 10))
    check_exact("choose(52, 5)", QQ(binomial(ZZ(52), ZZ(5))))

    for (lower, upper, power) in
        [(-8, 12, 1), (1, 100, 2), (-5, 5, 4), (7, 6, 3)]
        expected = lower > upper ? ZZ(0) : polynomial_sum(lower, upper, power)
        check_exact(
            "sum(k^$(power), k = $(lower), $(upper))",
            QQ(expected),
        )
    end

    for (lower, upper, offset) in
        [(1, 20, 0), (-3, 4, 5), (5, 4, 2), (1, 12, 1)]
        expected = lower > upper ? ZZ(1) :
                   linear_product(lower, upper, offset)
        check_exact(
            "product(k + $(offset), k = $(lower), $(upper))",
            QQ(expected),
        )
    end

    harmonic = QQ(0)
    for value in 1:20
        harmonic += QQ(1, value)
    end
    check_exact("sum(1/k, k = 1, 20)", harmonic)

    telescoping = QQ(1)
    for value in 1:30
        telescoping *= QQ(value + 1, value)
    end
    check_exact("product((k + 1)/k, k = 1, 30)", telescoping)

    check_exact_sequence(
        "sequence(k^3 - 2*k, k = -3, 4)",
        [QQ(value)^3 - 2 * QQ(value) for value in -3:4],
    )
    check_exact_sequence(
        "sequence((2*k + 1)/(k + 2), k = 0, 8)",
        [QQ(2 * value + 1, value + 2) for value in 0:8],
    )
    check_exact_sequence("sequence(1/0, k = 1, 0)", [])

    factorials = [QQ(1)]
    current = QQ(1)
    for index in 1:12
        current *= QQ(index)
        push!(factorials, current)
    end
    check_exact_sequence(
        "recurrence(1, a = a*k, k = 0, 12)",
        factorials,
    )

    affine_recurrence = [QQ(1, 3)]
    current = QQ(1, 3)
    for index in -1:7
        current = (3 * current + QQ(index)) / 2
        push!(affine_recurrence, current)
    end
    check_exact_sequence(
        "recurrence(1/3, a = (3*a + k)/2, k = -2, 7)",
        affine_recurrence,
    )
    check_exact_sequence(
        "recurrence(1/0, a = a, k = 1, 0)",
        [],
    )

    deterministic_integrals = [
        ([QQ(1), QQ(2), QQ(3)], QQ(0), QQ(3)),
        ([QQ(1, 2), QQ(-3, 4), QQ(2, 5)], QQ(-2, 3), QQ(5, 4)),
        ([QQ(-7, 3), QQ(0), QQ(5, 2), QQ(-1, 6)], QQ(4, 3), QQ(-3, 2)),
    ]
    for (coefficients, lower, upper) in deterministic_integrals
        check_polynomial_integral(coefficients, lower, upper)
    end

    integration_random = MersenneTwister(0x1A7E6A1)
    for _ in 1:60
        degree = rand(integration_random, 0:6)
        coefficients = [
            QQ(
                rand(integration_random, -12:12),
                rand(integration_random, 1:9),
            ) for _ in 0:degree
        ]
        lower = QQ(
            rand(integration_random, -10:10),
            rand(integration_random, 1:6),
        )
        upper = QQ(
            rand(integration_random, -10:10),
            rand(integration_random, 1:6),
        )
        check_polynomial_integral(coefficients, lower, upper)
    end

    random = MersenneTwister(0xCE71)
    for _ in 1:40
        lower = rand(random, -20:20)
        upper = rand(random, lower:30)
        coefficient = rand(random, -12:12)
        constant = rand(random, -12:12)
        expected = sum(
            ZZ(coefficient) * ZZ(value) + ZZ(constant) for
            value in lower:upper
        )
        check_exact(
            "sum($(coefficient)*k + $(constant), k = $(lower), $(upper))",
            QQ(expected),
        )
    end

    println("CENTL Julia/Nemo differential suite passed")
end

run_differential_suite()
