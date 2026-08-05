type ball

external of_fraction : string -> string -> int -> ball = "centl_arb_of_fraction"
external pi : int -> ball = "centl_arb_pi"
external neg : ball -> ball = "centl_arb_neg"
external abs : ball -> ball = "centl_arb_abs"
external add : ball -> ball -> int -> ball = "centl_arb_add"
external sub : ball -> ball -> int -> ball = "centl_arb_sub"
external mul : ball -> ball -> int -> ball = "centl_arb_mul"
external div : ball -> ball -> int -> ball = "centl_arb_div"
external pow : ball -> int -> int -> ball = "centl_arb_pow"
external sqrt : ball -> int -> ball = "centl_arb_sqrt"
external exp : ball -> int -> ball = "centl_arb_exp"
external log : ball -> int -> ball = "centl_arb_log"
external sin : ball -> int -> ball = "centl_arb_sin"
external cos : ball -> int -> ball = "centl_arb_cos"
external tan : ball -> int -> ball = "centl_arb_tan"
external asin : ball -> int -> ball = "centl_arb_asin"
external acos : ball -> int -> ball = "centl_arb_acos"
external atan : ball -> int -> ball = "centl_arb_atan"
external atan2 : ball -> ball -> int -> ball = "centl_arb_atan2"
external sinh : ball -> int -> ball = "centl_arb_sinh"
external cosh : ball -> int -> ball = "centl_arb_cosh"
external tanh : ball -> int -> ball = "centl_arb_tanh"
external endpoints : ball -> string * string * string = "centl_arb_endpoints"
external classification : ball -> int = "centl_arb_classification"

let finite value = classification value land 1 <> 0

let check_ball label value =
  if not (finite value) then failwith (label ^ " returned a nonfinite ball");
  let lower, upper, exponent = endpoints value in
  ignore (int_of_string exponent);
  if Z.compare (Z.of_string lower) (Z.of_string upper) > 0 then
    failwith (label ^ " returned reversed endpoints")

let invalid label operation =
  match operation () with
  | exception Invalid_argument _ -> ()
  | exception error -> failwith (label ^ " raised " ^ Printexc.to_string error)
  | _ -> failwith (label ^ " accepted invalid boundary input")

let () =
  invalid "embedded NUL numerator" (fun () -> of_fraction "1\0009" "2" 64);
  invalid "embedded NUL denominator" (fun () -> of_fraction "1" "2\0009" 64);
  invalid "zero denominator" (fun () -> of_fraction "1" "0" 64);
  invalid "low precision" (fun () -> pi 1);
  invalid "high precision" (fun () -> pi 16_385);
  let half = of_fraction "1" "2" 192 in
  invalid "low binary precision" (fun () -> add half half 0);
  invalid "large positive exponent" (fun () -> pow half 100_001 192);
  invalid "large negative exponent" (fun () -> pow half (-100_001) 192);
  for iteration = 1 to 2_000 do
    let numerator = string_of_int ((iteration mod 199) - 99) in
    let denominator = string_of_int ((iteration mod 97) + 1) in
    let value = of_fraction numerator denominator 192 in
    let positive = add (abs value) half 192 in
    check_ball "fraction" value;
    check_ball "pi" (pi 192);
    check_ball "neg" (neg value);
    check_ball "abs" (abs value);
    check_ball "add" (add value half 192);
    check_ball "sub" (sub value half 192);
    check_ball "mul" (mul value half 192);
    check_ball "div" (div value half 192);
    check_ball "pow" (pow positive ((iteration mod 9) - 4) 192);
    check_ball "sqrt" (sqrt positive 192);
    check_ball "exp" (exp half 192);
    check_ball "log" (log positive 192);
    check_ball "sin" (sin half 192);
    check_ball "cos" (cos half 192);
    check_ball "tan" (tan half 192);
    check_ball "asin" (asin half 192);
    check_ball "acos" (acos half 192);
    check_ball "atan" (atan value 192);
    check_ball "atan2" (atan2 value positive 192);
    check_ball "sinh" (sinh half 192);
    check_ball "cosh" (cosh half 192);
    check_ball "tanh" (tanh half 192);
    if iteration mod 50 = 0 then Gc.full_major ()
  done;
  Gc.compact ();
  Printf.printf "ASan/UBSan native Arb boundary passed (2000 iterations)\n%!"
