#!/usr/bin/env julia

using Nemo
using Random
using JSON3

const repository_root = normpath(joinpath(@__DIR__, "..", ".."))
const centl = get(ENV, "CENTL_BIN", joinpath(repository_root, "centl"))

function centl_exact(expression::String)
    command = Cmd([centl, "--json", expression])
    response = JSON3.read(read(command, String))
    response.ok || error(
        "CENTL rejected differential expression $(expression): " *
        String(response.error.code) * ": " * String(response.error.message),
    )
    value = response.value
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
