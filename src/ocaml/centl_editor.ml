type result =
  | Submitted of string
  | Input_limit_exceeded
  | End_of_input
  | Interrupted

type ghost = {
  display : string;
  accept : string option;
}

let write text =
  output_string stdout text;
  flush stdout

let save_cursor = "\027[s"
let restore_cursor = "\027[u"

let redraw ~ghost ~prompt ~text ~cursor =
  let suffix =
    match ghost with
    | Some value when cursor = String.length text && value.display <> "" ->
        "\027[2m" ^ value.display ^ "\027[0m"
    | _ -> ""
  in
  write (restore_cursor ^ "\027[J" ^ prompt ^ text ^ suffix);
  write (restore_cursor ^ prompt ^ String.sub text 0 cursor)

let identifier_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | _ -> false

let completion_span text cursor =
  let rec left i =
    if i > 0 && identifier_char text.[i - 1] then left (i - 1) else i
  in
  let rec right i =
    if i < String.length text && identifier_char text.[i] then right (i + 1)
    else i
  in
  let word_start = left cursor in
  let start =
    if word_start > 0 && text.[word_start - 1] = ':' then word_start - 1
    else word_start
  in
  (start, right cursor)

let common_prefix left right =
  let limit = min (String.length left) (String.length right) in
  let rec loop i =
    if i < limit && left.[i] = right.[i] then loop (i + 1) else i
  in
  String.sub left 0 (loop 0)

let replace_span text start finish replacement =
  String.sub text 0 start ^ replacement
  ^ String.sub text finish (String.length text - finish)

let complete ~prompt ~candidates ~max_bytes ~redraw_current text cursor =
  let start, finish = completion_span !text !cursor in
  let prefix = String.sub !text start (!cursor - start) in
  let matches =
    candidates
    |> List.filter (String.starts_with ~prefix)
    |> List.sort_uniq String.compare
  in
  let apply replacement =
    let next = replace_span !text start finish replacement in
    if String.length next > max_bytes then begin
      write "\007";
      false
    end
    else begin
      text := next;
      cursor := start + String.length replacement;
      redraw_current ();
      true
    end
  in
  match matches with
  | [] ->
      write "\007";
      false
  | [ candidate ] -> apply candidate
  | first :: rest ->
      let shared = List.fold_left common_prefix first rest in
      if String.length shared > String.length prefix then apply shared
      else begin
        redraw_current ();
        write ("\r\n" ^ String.concat "  " matches ^ "\r\n" ^ save_cursor);
        redraw_current ();
        false
      end

let read_canonical ~prompt ~max_bytes =
  write prompt;
  match Centl_protocol.read_line stdin max_bytes with
  | Centl_protocol.Line line -> Submitted line
  | Centl_protocol.Oversized -> Input_limit_exceeded
  | Centl_protocol.End -> End_of_input

let read_raw ~prompt ~history ~candidates ~suggest ~max_bytes
    (original : Unix.terminal_io) =
  let raw =
    {
      original with
      c_icanon = false;
      c_echo = false;
      c_echoe = false;
      c_echok = false;
      c_echonl = false;
      c_isig = false;
      c_ixon = false;
      c_icrnl = false;
      c_vmin = 1;
      c_vtime = 0;
    }
  in
  Unix.tcsetattr Unix.stdin Unix.TCSANOW raw;
  Fun.protect
    ~finally:(fun () ->
      try Unix.tcsetattr Unix.stdin Unix.TCSANOW original with _ -> ())
    (fun () ->
      let text = ref "" in
      let cursor = ref 0 in
      let overflowed = ref false in
      let entries = Array.of_list (Centl_history.entries history) in
      let history_index = ref (Array.length entries) in
      let draft = ref "" in
      let byte = Bytes.create 1 in
      let current_ghost () = suggest !text !cursor in
      let redraw_current () =
        redraw ~ghost:(current_ghost ()) ~prompt ~text:!text ~cursor:!cursor
      in
      let rec read_byte () =
        try
          if Unix.read Unix.stdin byte 0 1 = 0 then None
          else Some (Bytes.get byte 0)
        with
        | Unix.Unix_error (Unix.EINTR, _, _) -> read_byte ()
        | Unix.Unix_error (Unix.EIO, _, _) -> None
      in
      let input () =
        match read_byte () with Some c -> c | None -> raise End_of_file
      in
      let set value =
        if String.length value > max_bytes then write "\007"
        else begin
          text := value;
          cursor := String.length value;
          overflowed := false;
          redraw_current ()
        end
      in
      let older () =
        if !history_index = 0 then write "\007"
        else begin
          if !history_index = Array.length entries then draft := !text;
          decr history_index;
          set entries.(!history_index)
        end
      in
      let newer () =
        if !history_index >= Array.length entries then write "\007"
        else begin
          incr history_index;
          if !history_index = Array.length entries then set !draft
          else set entries.(!history_index)
        end
      in
      let insert c =
        if String.length !text >= max_bytes then begin
          overflowed := true;
          write "\007"
        end
        else begin
          text :=
            String.sub !text 0 !cursor ^ String.make 1 c
            ^ String.sub !text !cursor (String.length !text - !cursor);
          incr cursor;
          redraw_current ()
        end
      in
      let insert_text value =
        let next =
          String.sub !text 0 !cursor ^ value
          ^ String.sub !text !cursor (String.length !text - !cursor)
        in
        if String.length next > max_bytes then write "\007"
        else begin
          text := next;
          cursor := !cursor + String.length value;
          overflowed := false;
          redraw_current ()
        end
      in
      let backspace () =
        if !cursor > 0 then begin
          text :=
            String.sub !text 0 (!cursor - 1)
            ^ String.sub !text !cursor (String.length !text - !cursor);
          decr cursor;
          overflowed := false;
          redraw_current ()
        end
      in
      let delete () =
        if !cursor < String.length !text then begin
          text :=
            String.sub !text 0 !cursor
            ^ String.sub !text (!cursor + 1)
                (String.length !text - !cursor - 1);
          overflowed := false;
          redraw_current ()
        end
      in
      let submit () =
        redraw ~ghost:None ~prompt ~text:!text ~cursor:!cursor;
        write "\r\n";
        if !overflowed then Input_limit_exceeded else Submitted !text
      in
      let end_of_input () =
        redraw ~ghost:None ~prompt ~text:!text ~cursor:!cursor;
        write "\r\n";
        if !overflowed then Input_limit_exceeded
        else if !text = "" then End_of_input
        else Submitted !text
      in
      let escape_read () =
        try
          let ready, _, _ = Unix.select [ Unix.stdin ] [] [] 0.05 in
          if ready = [] then None else read_byte ()
        with Unix.Unix_error (Unix.EINTR, _, _) -> None
      in
      let escape () =
        match escape_read () with
        | Some '[' ->
            begin match escape_read () with
            | Some 'A' -> older ()
            | Some 'B' -> newer ()
            | Some 'C' when !cursor < String.length !text ->
                incr cursor;
                redraw_current ()
            | Some 'D' when !cursor > 0 ->
                decr cursor;
                redraw_current ()
            | Some 'H' ->
                cursor := 0;
                redraw_current ()
            | Some 'F' ->
                cursor := String.length !text;
                redraw_current ()
            | Some '3' -> if escape_read () = Some '~' then delete ()
            | _ -> ()
            end
        | Some 'O' ->
            begin match escape_read () with
            | Some 'H' ->
                cursor := 0;
                redraw_current ()
            | Some 'F' ->
                cursor := String.length !text;
                redraw_current ()
            | _ -> ()
            end
        | _ -> ()
      in
      let tab () =
        match current_ghost () with
        | Some { accept = Some value; _ } when !cursor = String.length !text ->
            insert_text value
        | _ ->
            ignore
              (complete ~prompt ~candidates ~max_bytes ~redraw_current text cursor)
      in
      let rec loop () =
        match input () with
        | '\r' | '\n' -> submit ()
        | '\003' ->
            redraw ~ghost:None ~prompt ~text:!text ~cursor:!cursor;
            write "^C\r\n";
            Interrupted
        | '\004' when !text = "" ->
            write "\r\n";
            End_of_input
        | '\004' ->
            delete ();
            loop ()
        | '\001' ->
            cursor := 0;
            redraw_current ();
            loop ()
        | '\005' ->
            cursor := String.length !text;
            redraw_current ();
            loop ()
        | '\t' ->
            tab ();
            loop ()
        | '\016' ->
            older ();
            loop ()
        | '\014' ->
            newer ();
            loop ()
        | '\008' | '\127' ->
            backspace ();
            loop ()
        | '\021' ->
            text := String.sub !text !cursor (String.length !text - !cursor);
            cursor := 0;
            overflowed := false;
            redraw_current ();
            loop ()
        | '\027' ->
            escape ();
            loop ()
        | c when Char.code c < 32 -> loop ()
        | c ->
            insert c;
            loop ()
        | exception End_of_file -> end_of_input ()
      in
      write (save_cursor ^ prompt);
      redraw_current ();
      loop ())

let read_line ~suggest ~prompt ~history ~candidates ~max_bytes =
  if
    Sys.win32
    || not (Unix.isatty Unix.stdout)
    || Sys.getenv_opt "TERM" = Some "dumb"
  then read_canonical ~prompt ~max_bytes
  else
    try
      read_raw ~prompt ~history ~candidates ~suggest ~max_bytes
        (Unix.tcgetattr Unix.stdin)
    with Unix.Unix_error _ | Invalid_argument _ ->
      read_canonical ~prompt ~max_bytes
