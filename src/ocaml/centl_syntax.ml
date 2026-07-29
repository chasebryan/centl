type entry = { form : string; meaning : string }
type section = { name : string; entries : entry array }
type example = { kind : string; calculation : string; result : string }

let entry form meaning = { form; meaning }

let sections =
  [|
    {
      name = "Values";
      entries =
        [|
          entry "123" "integer (exact)";
          entry "0.125" "decimal (exact)";
          entry "1/3" "fraction (exact)";
          entry "x" "symbolic variable";
          entry "(expression)" "group an expression";
          entry "pi" "circle constant";
          entry "e" "Euler's number";
          entry "tau" "two times pi";
        |];
    };
    {
      name = "Arithmetic";
      entries =
        [|
          entry "+x" "positive value";
          entry "-x" "negation";
          entry "a + b" "addition";
          entry "a - b" "subtraction";
          entry "a * b" "multiplication";
          entry "a / b" "division";
          entry "x^n" "integer power";
        |];
    };
    {
      name = "Symbolic math";
      entries =
        [|
          entry "f(x, ...)" "symbolic function call";
          entry "name = expression" "immutable value definition";
          entry "f(x, ...) = expression" "immutable function definition";
          entry "solve(left = right, variable)" "solve an equation exactly";
          entry "diff(expression, variable)" "differentiate";
          entry "substitute(expression, variable = value)" "substitute a value";
          entry "simplify(expression)" "collect and simplify";
          entry "expand(expression)" "expand a polynomial";
          entry "factor(expression)" "factor a polynomial";
          entry "assuming(expression, condition)" "attach a domain assumption";
          entry "=  !=  <  <=  >  >=" "relations used in assumptions";
        |];
    };
    {
      name = "Approximation";
      entries =
        [|
          entry "approx(expression)" "rigorous enclosure at 20 digits";
          entry "approx(expression, digits)"
            "rigorous enclosure at 1-1000 digits";
        |];
    };
    {
      name = "Functions";
      entries =
        [|
          entry "sqrt(x)" "square root";
          entry "abs(x)" "absolute value";
          entry "exp(x)" "e raised to x";
          entry "log(x)" "natural logarithm";
          entry "sin(x)" "sine";
          entry "cos(x)" "cosine";
          entry "tan(x)" "tangent";
          entry "asin(x)" "inverse sine";
          entry "acos(x)" "inverse cosine";
          entry "atan(x)" "inverse tangent";
          entry "atan2(y, x)" "quadrant-aware inverse tangent";
          entry "sinh(x)" "hyperbolic sine";
          entry "cosh(x)" "hyperbolic cosine";
          entry "tanh(x)" "hyperbolic tangent";
          entry "radians(degrees)" "degrees to radians";
          entry "degrees(radians)" "radians to degrees";
        |];
    };
    {
      name = "Geometry";
      entries =
        [|
          entry "square_area(side)" "area of a square";
          entry "rectangle_area(width, height)" "area of a rectangle";
          entry "rectangle_perimeter(width, height)" "perimeter of a rectangle";
          entry "triangle_area(base, height)" "area of a triangle";
          entry "trapezoid_area(base1, base2, height)" "area of a trapezoid";
          entry "circle_area(radius)" "area of a circle";
          entry "circumference(radius)" "circumference of a circle";
          entry "sphere_area(radius)" "surface area of a sphere";
          entry "sphere_volume(radius)" "volume of a sphere";
          entry "cylinder_volume(radius, height)" "volume of a cylinder";
          entry "hypot(a, b)" "hypotenuse length";
          entry "distance(x1, y1, x2, y2)" "distance between two points";
          entry "slope(x1, y1, x2, y2)" "slope between two points";
        |];
    };
    {
      name = "Concrete math";
      entries =
        [|
          entry "gcd(a, b)" "greatest common divisor";
          entry "lcm(a, b)" "least common multiple";
          entry "factorial(n)" "n factorial";
          entry "choose(n, k)" "binomial coefficient";
          entry "permutations(n, k)" "ordered selections";
          entry "fibonacci(n)" "nth Fibonacci number";
        |];
    };
    {
      name = "Scripts";
      entries = [| entry "# comment" "ignored line in a script" |];
    };
  |]

let examples =
  [|
    { kind = "exact"; calculation = "0.1 + 0.2"; result = "3/10" };
    {
      kind = "calculus";
      calculation = "diff(x^3 + 2*x + 1, x)";
      result = "3 * x^2 + 2";
    };
    {
      kind = "definition";
      calculation = "f(x) = x^2 + 1";
      result = "f(x) = x^2 + 1";
    };
    { kind = "geometry"; calculation = "circle_area(3)"; result = "9 * pi" };
    {
      kind = "rigorous";
      calculation = "approx(sqrt(2), 12)";
      result = "≈ [1.41421356237, 1.41421356238]";
    };
  |]

let identifier_of_form = function
  | "123" -> "integer"
  | "0.125" -> "decimal"
  | "1/3" -> "fraction"
  | "x" -> "variable"
  | "(expression)" -> "()"
  | "+x" | "a + b" -> "+"
  | "-x" | "a - b" -> "-"
  | "a * b" -> "*"
  | "a / b" -> "/"
  | "x^n" -> "^"
  | "f(x, ...)" -> "f(...)"
  | "name = expression" -> "name="
  | "f(x, ...) = expression" -> "f(...)="
  | "=  !=  <  <=  >  >=" -> "= != < <= > >="
  | "# comment" -> "#"
  | form ->
      begin match String.index_opt form '(' with
      | Some index -> String.sub form 0 index
      | None -> form
      end

let unique_identifiers entries =
  Array.fold_left
    (fun identifiers item ->
      let identifier = identifier_of_form item.form in
      if List.mem identifier identifiers then identifiers
      else identifiers @ [ identifier ])
    [] entries

let section_line section =
  String.lowercase_ascii section.name
  ^ ": "
  ^ String.concat " " (unique_identifiers section.entries)

let example_line example = example.calculation ^ " -> " ^ example.result

let plain_text () =
  let groups = Array.to_list sections |> List.map section_line in
  let calculations = Array.to_list examples |> List.map example_line in
  String.concat "\n"
    ([ "CENTL syntax" ] @ groups @ [ ""; "examples:" ] @ calculations)

let print channel =
  output_string channel (plain_text ());
  output_char channel '\n'
