type error =
  | Empty_matrix
  | Empty_row
  | Ragged_rows
  | Index_out_of_bounds
  | Shape_mismatch of string
  | Not_square of string
  | Singular_matrix
  | Right_hand_side_length_mismatch

exception Matrix_error of error

type t = { rows : int; columns : int; entries : Q.t array array }

type rref_result = { matrix : t; pivot_columns : int list }

type linear_solution =
  | No_solution
  | Unique of Q.t array
  | Infinite of {
      particular : Q.t array;
      nullspace_basis : Q.t array list;
    }

let error_message = function
  | Empty_matrix -> "matrix must contain at least one row"
  | Empty_row -> "matrix rows must contain at least one entry"
  | Ragged_rows -> "matrix rows must all have the same length"
  | Index_out_of_bounds -> "matrix index is out of bounds"
  | Shape_mismatch context -> context ^ ": matrix dimensions are incompatible"
  | Not_square context -> context ^ ": matrix must be square"
  | Singular_matrix -> "matrix is singular"
  | Right_hand_side_length_mismatch ->
      "right-hand-side length must equal the matrix row count"

let copy_entries entries = Array.map Array.copy entries

let of_arrays rows =
  let row_count = Array.length rows in
  if row_count = 0 then Error Empty_matrix
  else
    let column_count = Array.length rows.(0) in
    if column_count = 0 then Error Empty_row
    else if
      Array.exists (fun row -> Array.length row <> column_count) rows
    then Error Ragged_rows
    else
      Ok
        {
          rows = row_count;
          columns = column_count;
          entries = copy_entries rows;
        }

let of_rows rows = of_arrays (Array.of_list (List.map Array.of_list rows))

let make_exn rows =
  match of_rows rows with
  | Ok matrix -> matrix
  | Error error -> raise (Matrix_error error)

let dimensions matrix = (matrix.rows, matrix.columns)

let get matrix row column =
  if row < 0 || row >= matrix.rows || column < 0 || column >= matrix.columns then
    Error Index_out_of_bounds
  else Ok matrix.entries.(row).(column)

let get_exn matrix row column =
  match get matrix row column with
  | Ok value -> value
  | Error error -> raise (Matrix_error error)

let to_rows matrix =
  Array.to_list matrix.entries |> List.map (fun row -> Array.to_list row)

let equal a b =
  a.rows = b.rows
  && a.columns = b.columns
  &&
  let same = ref true in
  let row = ref 0 in
  while !same && !row < a.rows do
    let column = ref 0 in
    while !same && !column < a.columns do
      if not (Q.equal a.entries.(!row).(!column) b.entries.(!row).(!column)) then
        same := false;
      incr column
    done;
    incr row
  done;
  !same

let map f matrix =
  {
    matrix with
    entries = Array.map (fun row -> Array.map f row) matrix.entries;
  }

let map2 context f a b =
  if a.rows <> b.rows || a.columns <> b.columns then Error (Shape_mismatch context)
  else
    Ok
      {
        rows = a.rows;
        columns = a.columns;
        entries =
          Array.init a.rows (fun row ->
              Array.init a.columns (fun column ->
                  f a.entries.(row).(column) b.entries.(row).(column)));
      }

let add a b = map2 "matrix addition" Q.add a b
let sub a b = map2 "matrix subtraction" Q.sub a b
let scale scalar matrix = map (Q.mul scalar) matrix
let neg matrix = scale Q.minus_one matrix

let multiply a b =
  if a.columns <> b.rows then Error (Shape_mismatch "matrix multiplication")
  else
    Ok
      {
        rows = a.rows;
        columns = b.columns;
        entries =
          Array.init a.rows (fun row ->
              Array.init b.columns (fun column ->
                  let total = ref Q.zero in
                  for k = 0 to a.columns - 1 do
                    total :=
                      Q.add !total
                        (Q.mul a.entries.(row).(k) b.entries.(k).(column))
                  done;
                  !total));
      }

let transpose matrix =
  {
    rows = matrix.columns;
    columns = matrix.rows;
    entries =
      Array.init matrix.columns (fun row ->
          Array.init matrix.rows (fun column -> matrix.entries.(column).(row)));
  }

let identity size =
  if size < 1 then Error Empty_matrix
  else
    Ok
      {
        rows = size;
        columns = size;
        entries =
          Array.init size (fun row ->
              Array.init size (fun column ->
                  if row = column then Q.one else Q.zero));
      }

let require_square context matrix =
  if matrix.rows = matrix.columns then Ok () else Error (Not_square context)

let trace matrix =
  match require_square "trace" matrix with
  | Error _ as error -> error
  | Ok () ->
      let total = ref Q.zero in
      for i = 0 to matrix.rows - 1 do
        total := Q.add !total matrix.entries.(i).(i)
      done;
      Ok !total

let find_nonzero_in_column entries start_row row_count column =
  let rec find row =
    if row >= row_count then None
    else if Q.equal entries.(row).(column) Q.zero then find (row + 1)
    else Some row
  in
  find start_row

let swap_rows entries a b =
  if a <> b then begin
    let temporary = entries.(a) in
    entries.(a) <- entries.(b);
    entries.(b) <- temporary
  end

let determinant matrix =
  match require_square "determinant" matrix with
  | Error _ as error -> error
  | Ok () ->
      let entries = copy_entries matrix.entries in
      let determinant = ref Q.one in
      let singular = ref false in
      let column = ref 0 in
      while not !singular && !column < matrix.columns do
        match
          find_nonzero_in_column entries !column matrix.rows !column
        with
        | None -> singular := true
        | Some pivot_row ->
            if pivot_row <> !column then begin
              swap_rows entries pivot_row !column;
              determinant := Q.neg !determinant
            end;
            let pivot = entries.(!column).(!column) in
            determinant := Q.mul !determinant pivot;
            for row = !column + 1 to matrix.rows - 1 do
              if not (Q.equal entries.(row).(!column) Q.zero) then begin
                let factor = Q.div entries.(row).(!column) pivot in
                entries.(row).(!column) <- Q.zero;
                for k = !column + 1 to matrix.columns - 1 do
                  entries.(row).(k) <-
                    Q.sub entries.(row).(k)
                      (Q.mul factor entries.(!column).(k))
                done
              end
            done;
            incr column
      done;
      Ok (if !singular then Q.zero else !determinant)

let rref_array input =
  let entries = copy_entries input in
  let row_count = Array.length entries in
  let column_count = if row_count = 0 then 0 else Array.length entries.(0) in
  let pivot_row = ref 0 in
  let pivots_reversed = ref [] in
  let column = ref 0 in
  while !pivot_row < row_count && !column < column_count do
    match find_nonzero_in_column entries !pivot_row row_count !column with
    | None -> incr column
    | Some selected ->
        swap_rows entries selected !pivot_row;
        let pivot = entries.(!pivot_row).(!column) in
        for k = !column to column_count - 1 do
          entries.(!pivot_row).(k) <- Q.div entries.(!pivot_row).(k) pivot
        done;
        for row = 0 to row_count - 1 do
          if row <> !pivot_row then begin
            let factor = entries.(row).(!column) in
            if not (Q.equal factor Q.zero) then begin
              entries.(row).(!column) <- Q.zero;
              for k = !column + 1 to column_count - 1 do
                entries.(row).(k) <-
                  Q.sub entries.(row).(k)
                    (Q.mul factor entries.(!pivot_row).(k))
              done
            end
          end
        done;
        pivots_reversed := (!pivot_row, !column) :: !pivots_reversed;
        incr pivot_row;
        incr column
  done;
  (entries, List.rev !pivots_reversed)

let rref matrix =
  let entries, pivots = rref_array matrix.entries in
  {
    matrix = { matrix with entries };
    pivot_columns = List.map snd pivots;
  }

let rank matrix = List.length (rref matrix).pivot_columns

let inverse matrix =
  match require_square "inverse" matrix with
  | Error _ as error -> error
  | Ok () ->
      let size = matrix.rows in
      let augmented =
        Array.init size (fun row ->
            Array.init (2 * size) (fun column ->
                if column < size then matrix.entries.(row).(column)
                else if column - size = row then Q.one
                else Q.zero))
      in
      let reduced, pivots = rref_array augmented in
      let left_pivots = List.filter (fun (_, column) -> column < size) pivots in
      if List.length left_pivots <> size then Error Singular_matrix
      else
        Ok
          {
            rows = size;
            columns = size;
            entries =
              Array.init size (fun row ->
                  Array.init size (fun column -> reduced.(row).(column + size)));
          }

let all_zero_coefficients row variable_count =
  let zero = ref true in
  let column = ref 0 in
  while !zero && !column < variable_count do
    if not (Q.equal row.(!column) Q.zero) then zero := false;
    incr column
  done;
  !zero

let solve matrix rhs =
  if Array.length rhs <> matrix.rows then Error Right_hand_side_length_mismatch
  else
    let variable_count = matrix.columns in
    let augmented =
      Array.init matrix.rows (fun row ->
          Array.init (variable_count + 1) (fun column ->
              if column < variable_count then matrix.entries.(row).(column)
              else rhs.(row)))
    in
    let reduced, pivots = rref_array augmented in
    let inconsistent = ref false in
    for row = 0 to matrix.rows - 1 do
      if
        all_zero_coefficients reduced.(row) variable_count
        && not (Q.equal reduced.(row).(variable_count) Q.zero)
      then inconsistent := true
    done;
    if !inconsistent then Ok No_solution
    else
      let coefficient_pivots =
        List.filter (fun (_, column) -> column < variable_count) pivots
      in
      let pivot_columns = List.map snd coefficient_pivots in
      let particular = Array.make variable_count Q.zero in
      List.iter
        (fun (row, column) -> particular.(column) <- reduced.(row).(variable_count))
        coefficient_pivots;
      if List.length pivot_columns = variable_count then Ok (Unique particular)
      else
        let free_columns =
          let free = ref [] in
          for column = variable_count - 1 downto 0 do
            if not (List.mem column pivot_columns) then free := column :: !free
          done;
          !free
        in
        let basis =
          List.map
            (fun free_column ->
              let vector = Array.make variable_count Q.zero in
              vector.(free_column) <- Q.one;
              List.iter
                (fun (row, pivot_column) ->
                  vector.(pivot_column) <- Q.neg reduced.(row).(free_column))
                coefficient_pivots;
              vector)
            free_columns
        in
        Ok (Infinite { particular; nullspace_basis = basis })

let nullspace matrix =
  let reduced, pivots = rref_array matrix.entries in
  let pivot_columns = List.map snd pivots in
  let free_columns =
    let free = ref [] in
    for column = matrix.columns - 1 downto 0 do
      if not (List.mem column pivot_columns) then free := column :: !free
    done;
    !free
  in
  List.map
    (fun free_column ->
      let vector = Array.make matrix.columns Q.zero in
      vector.(free_column) <- Q.one;
      List.iter
        (fun (row, pivot_column) ->
          vector.(pivot_column) <- Q.neg reduced.(row).(free_column))
        pivots;
      vector)
    free_columns

let multiply_vector matrix vector =
  if Array.length vector <> matrix.columns then
    Error (Shape_mismatch "matrix-vector multiplication")
  else
    Ok
      (Array.init matrix.rows (fun row ->
           let total = ref Q.zero in
           for column = 0 to matrix.columns - 1 do
             total :=
               Q.add !total (Q.mul matrix.entries.(row).(column) vector.(column))
           done;
           !total))

let vector_equal a b =
  Array.length a = Array.length b
  &&
  let same = ref true in
  let i = ref 0 in
  while !same && !i < Array.length a do
    if not (Q.equal a.(!i) b.(!i)) then same := false;
    incr i
  done;
  !same

let exact_bits matrix =
  let bits = ref 0 in
  Array.iter
    (fun row ->
      Array.iter
        (fun value ->
          bits :=
            !bits + Z.numbits (Z.abs (Q.num value)) + Z.numbits (Q.den value))
        row)
    matrix.entries;
  !bits
