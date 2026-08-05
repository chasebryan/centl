let milliseconds seconds = seconds *. 1_000.

let budget name default =
  match Sys.getenv_opt name with
  | None -> default
  | Some value ->
      begin match float_of_string_opt value with
      | Some parsed when parsed > 0. -> parsed
      | _ -> failwith (name ^ " must be a positive number")
      end

let scale = budget "CENTL_PERF_BUDGET_SCALE" 1.

let timed operation =
  Gc.compact ();
  let started = Unix.gettimeofday () in
  let result = operation () in
  let elapsed = Unix.gettimeofday () -. started in
  (elapsed, result)

let require_evaluation expression =
  match Centl_engine.evaluate expression with
  | Ok value -> String.length (Centl_engine.text_of_value value)
  | Error error ->
      failwith
        (Printf.sprintf "%s failed with %s: %s" expression error.code
           error.message)

let require_protocol response =
  match response with
  | `Assoc fields when List.assoc_opt "ok" fields = Some (`Bool true) ->
      String.length (Yojson.Safe.to_string response)
  | _ -> failwith ("protocol workload failed: " ^ Yojson.Safe.to_string response)

let run_binary binary expression =
  let channel =
    Unix.open_process_args_in binary [| binary; "--json"; expression |]
  in
  let output =
    try input_line channel
    with error ->
      ignore (Unix.close_process_in channel);
      raise error
  in
  begin match Unix.close_process_in channel with
  | Unix.WEXITED 0 -> ()
  | Unix.WEXITED code -> failwith (Printf.sprintf "centl exited %d" code)
  | Unix.WSIGNALED signal ->
      failwith (Printf.sprintf "centl was signalled (%d)" signal)
  | Unix.WSTOPPED signal ->
      failwith (Printf.sprintf "centl stopped (%d)" signal)
  end;
  match Yojson.Safe.from_string output with
  | `Assoc fields when List.assoc_opt "ok" fields = Some (`Bool true) -> ()
  | _ -> failwith ("centl returned an invalid startup response: " ^ output)

let median values =
  let sorted = List.sort Float.compare values in
  List.nth sorted (List.length sorted / 2)

let failures = ref []

let report name ~operations ~budget_ms elapsed =
  let elapsed_ms = milliseconds elapsed in
  let rate = float_of_int operations /. max elapsed 0.000_001 in
  Printf.printf "%s: %.2f ms, %.0f operations/s (budget %.0f ms)\n%!" name
    elapsed_ms rate budget_ms;
  if elapsed_ms > budget_ms then
    failures :=
      Printf.sprintf "%s took %.2f ms (budget %.0f ms)" name elapsed_ms
        budget_ms
      :: !failures

let () =
  let binary =
    match Sys.getenv_opt "CENTL_BIN" with
    | Some path when Sys.file_exists path -> path
    | Some path -> failwith ("CENTL_BIN does not exist: " ^ path)
    | None -> failwith "CENTL_BIN must name the built centl executable"
  in
  run_binary binary "1 + 1";
  let startup_samples =
    List.init 5 (fun _ -> fst (timed (fun () -> run_binary binary "1 + 1")))
  in
  let startup = median startup_samples in
  report "process startup median" ~operations:1
    ~budget_ms:(scale *. budget "CENTL_PERF_STARTUP_MS" 750.)
    startup;

  let exact_inputs =
    [|
      "(2^256 + 1) / (2^128 + 1)";
      "sum(k^2, k = 1, 1000)";
      "product((k + 1) / k, k = 1, 100)";
      "integrate((x + 1)^8, x = 0, 1)";
      "diff((x + 1)^10, x)";
      "expand((x + 1)^8)";
      "solve(x^2 - 5*x + 6 = 0, x)";
    |]
  in
  let exact_rounds = 40 in
  let exact_checksum = ref 0 in
  let exact_elapsed, () =
    timed (fun () ->
        for _ = 1 to exact_rounds do
          Array.iter
            (fun expression ->
              exact_checksum := !exact_checksum + require_evaluation expression)
            exact_inputs
        done)
  in
  if !exact_checksum = 0 then failwith "exact workload was optimized away";
  report "representative exact evaluation"
    ~operations:(exact_rounds * Array.length exact_inputs)
    ~budget_ms:(scale *. budget "CENTL_PERF_EXACT_MS" 5_000.)
    exact_elapsed;

  let native_inputs =
    [|
      "approx(sqrt(2), 30)";
      "approx(pi, 30)";
      "approx(sin(1/3), 30)";
      "approx(log(2), 30)";
      "approx(exp(1/7), 30)";
      "approx(atan2(1, 2), 30)";
    |]
  in
  let native_rounds = 10 in
  let native_checksum = ref 0 in
  let native_elapsed, () =
    timed (fun () ->
        for _ = 1 to native_rounds do
          Array.iter
            (fun expression ->
              native_checksum :=
                !native_checksum + require_evaluation expression)
            native_inputs
        done)
  in
  if !native_checksum = 0 then failwith "native workload was optimized away";
  report "rigorous Arb evaluation"
    ~operations:(native_rounds * Array.length native_inputs)
    ~budget_ms:(scale *. budget "CENTL_PERF_ARB_MS" 5_000.)
    native_elapsed;

  let protocol = Centl_protocol.create () in
  let protocol_checksum = ref 0 in
  let protocol_operations = 500 in
  let protocol_elapsed, () =
    timed (fun () ->
        for request = 1 to protocol_operations do
          let line =
            Printf.sprintf
              {|{"version":1,"id":%d,"expression":"(1/3 + 1/6)^5"}|} request
          in
          protocol_checksum :=
            !protocol_checksum
            + require_protocol (Centl_protocol.handle_line protocol line)
        done)
  in
  if !protocol_checksum = 0 then failwith "protocol workload was optimized away";
  report "persistent JSONL evaluation" ~operations:protocol_operations
    ~budget_ms:(scale *. budget "CENTL_PERF_PROTOCOL_MS" 5_000.)
    protocol_elapsed;

  match List.rev !failures with
  | [] ->
      Printf.printf "performance smoke budgets passed (scale %.2f)\n%!" scale
  | failures ->
      List.iter
        (fun message -> prerr_endline ("performance: " ^ message))
        failures;
      exit 1
