type element = string

type composition = (element * int) list

let normalize atoms =
  atoms
  |> List.sort (fun (a, _) (b, _) -> String.compare a b)

let add_element element count atoms =
  let rec insert = function
    | [] -> [ (element, count) ]
    | (existing, n) :: rest when existing = element ->
        (existing, n + count) :: rest
    | head :: rest -> head :: insert rest
  in
  normalize (insert atoms)

let parse_simple formula =
  let len = String.length formula in
  let rec loop i acc =
    if i >= len then Some (normalize acc)
    else
      let c = formula.[i] in
      if c < 'A' || c > 'Z' then None
      else
        let j =
          if i + 1 < len && formula.[i + 1] >= 'a' && formula.[i + 1] <= 'z'
          then i + 2 else i + 1
        in
        let symbol = String.sub formula i (j - i) in
        let k = ref j in
        while !k < len && formula.[!k] >= '0' && formula.[!k] <= '9' do
          incr k
        done;
        let count =
          if !k = j then 1 else int_of_string (String.sub formula j (!k - j))
        in
        loop !k (add_element symbol count acc)
  in
  loop 0 []
