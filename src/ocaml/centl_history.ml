type limits = { max_entries : int; max_bytes : int; max_entry_bytes : int }

let default_limits =
  { max_entries = 1_000; max_bytes = 1_048_576; max_entry_bytes = 32_768 }

type storage = { path : string; limits : limits }

type t = {
  limits : limits;
  storage : storage option;
  mutable newest_first : string list;
}

let json_prefix = "{\"version\":1,\"entries\":["
let json_suffix = "]}\n"
let serialized_overhead = String.length json_prefix + String.length json_suffix

let nonempty_environment getenv name =
  match getenv name with
  | Some value when String.trim value <> "" -> Some value
  | Some _ | None -> None

let state_path ~win32 getenv =
  let history_path root =
    Filename.concat (Filename.concat root "centl") "history.json"
  in
  if win32 then
    match nonempty_environment getenv "LOCALAPPDATA" with
    | Some root -> Some (history_path root)
    | None ->
        begin match nonempty_environment getenv "APPDATA" with
        | Some root -> Some (history_path root)
        | None ->
            Option.map
              (fun root ->
                history_path
                  (Filename.concat (Filename.concat root "AppData") "Local"))
              (nonempty_environment getenv "USERPROFILE")
        end
  else
    match nonempty_environment getenv "XDG_STATE_HOME" with
    | Some root when not (Filename.is_relative root) -> Some (history_path root)
    | Some _ | None ->
        Option.map
          (fun root ->
            history_path
              (Filename.concat (Filename.concat root ".local") "state"))
          (nonempty_environment getenv "HOME")

let default_path () = state_path ~win32:Sys.win32 Sys.getenv_opt

let environment_disables_persistence ?(getenv = Sys.getenv_opt) () =
  match getenv "CENTL_NO_HISTORY" with
  | Some _ -> true
  | None ->
      begin match getenv "CENTL_HISTORY" with
      | Some value ->
          List.mem
            (String.lowercase_ascii (String.trim value))
            [ "0"; "false"; "no"; "off" ]
      | None -> false
      end

let valid_entry limits entry =
  let length = String.length entry in
  length > 0
  && length <= limits.max_entry_bytes
  && String.trim entry <> ""
  && String.for_all
       (fun character ->
         let code = Char.code character in
         character = '\t' || (code >= 32 && code <> 127))
       entry

let encoded_entry entry = Yojson.Safe.to_string (`String entry)

let bounded_entries limits entries =
  let max_entries = max 0 limits.max_entries in
  let max_bytes = max serialized_overhead limits.max_bytes in
  let individually_fits entry =
    valid_entry limits entry
    && serialized_overhead + String.length (encoded_entry entry) <= max_bytes
  in
  let newest = List.rev entries |> List.filter individually_fits in
  let rec collect count bytes chronological = function
    | [] -> chronological
    | _ when count >= max_entries -> chronological
    | entry :: rest ->
        let separator = if count = 0 then 0 else 1 in
        let cost = separator + String.length (encoded_entry entry) in
        if serialized_overhead + bytes + cost > max_bytes then chronological
        else collect (count + 1) (bytes + cost) (entry :: chronological) rest
  in
  collect 0 0 [] newest

let serialize entries =
  json_prefix ^ String.concat "," (List.map encoded_entry entries) ^ json_suffix

let entries_of_json limits json =
  match json with
  | `Assoc fields ->
      begin match
        (List.assoc_opt "version" fields, List.assoc_opt "entries" fields)
      with
      | Some (`Int 1), Some (`List values) ->
          values
          |> List.filter_map (function
            | `String entry -> Some entry
            | _ -> None)
          |> bounded_entries limits
      | _ -> []
      end
  | _ -> []

let close_noerr descriptor =
  try Unix.close descriptor with Unix.Unix_error _ -> ()

let set_private_file_mode ?(fchmod = Unix.fchmod) ~win32 descriptor =
  if not win32 then fchmod descriptor 0o600

let lstat path =
  try Some (Unix.lstat path)
  with Unix.Unix_error (Unix.ENOENT, _, _) -> None

let same_file left right =
  left.Unix.st_dev = right.Unix.st_dev && left.Unix.st_ino = right.Unix.st_ino

let require_owned_regular path metadata =
  if metadata.Unix.st_kind <> Unix.S_REG then
    raise (Sys_error (path ^ " is not a regular file"));
  if not Sys.win32 && metadata.Unix.st_uid <> Unix.geteuid () then
    raise (Sys_error (path ^ " is not owned by the current user"))

let read_file storage =
  let expected =
    match lstat storage.path with
    | None -> raise (Sys_error (storage.path ^ " does not exist"))
    | Some metadata ->
        require_owned_regular storage.path metadata;
        metadata
  in
  let descriptor =
    Unix.openfile storage.path [ Unix.O_RDONLY; Unix.O_SHARE_DELETE ] 0
  in
  Fun.protect
    ~finally:(fun () -> close_noerr descriptor)
    (fun () ->
      let metadata = Unix.fstat descriptor in
      require_owned_regular storage.path metadata;
      if not (same_file expected metadata) then
        raise (Sys_error "history file changed while it was being opened");
      set_private_file_mode ~win32:Sys.win32 descriptor;
      if
        metadata.st_size < 0
        || metadata.st_size > max serialized_overhead storage.limits.max_bytes
      then []
      else
        let buffer = Bytes.create metadata.st_size in
        let rec read offset =
          if offset >= Bytes.length buffer then offset
          else
            match
              Unix.read descriptor buffer offset (Bytes.length buffer - offset)
            with
            | 0 -> offset
            | count -> read (offset + count)
        in
        let length = read 0 in
        let contents = Bytes.sub_string buffer 0 length in
        entries_of_json storage.limits (Yojson.Safe.from_string contents))

let load storage =
  try read_file storage
  with
  | Sys_error _ | Unix.Unix_error _ | Yojson.Json_error _ | Invalid_argument _
  ->
    []

let rec ensure_directory directory =
  if directory = "" || directory = Filename.dirname directory then ()
  else if Sys.file_exists directory then
    begin if not (Sys.is_directory directory) then
      raise (Sys_error (directory ^ " is not a directory"))
    end
  else begin
    ensure_directory (Filename.dirname directory);
    try Unix.mkdir directory 0o700
    with
    | Unix.Unix_error (Unix.EEXIST, _, _) when Sys.is_directory directory ->
      ()
  end

let prepare_directory path =
  let directory = Filename.dirname path in
  ensure_directory directory;
  let metadata = Unix.lstat directory in
  if metadata.Unix.st_kind = Unix.S_LNK then
    raise (Sys_error ("refusing symbolic-link history directory: " ^ directory));
  if metadata.Unix.st_kind <> Unix.S_DIR then
    raise (Sys_error (directory ^ " is not a directory"));
  if not Sys.win32 then begin
    if metadata.Unix.st_uid <> Unix.geteuid () then
      raise (Sys_error ("history directory is not owned by the current user: " ^ directory));
    if String.lowercase_ascii (Filename.basename directory) = "centl" then
      Unix.chmod directory 0o700;
    let verified = Unix.lstat directory in
    if
      verified.Unix.st_kind <> Unix.S_DIR
      || not (same_file metadata verified)
      || verified.Unix.st_uid <> Unix.geteuid ()
      || verified.Unix.st_perm land 0o022 <> 0
    then
      raise (Sys_error ("unsafe history directory: " ^ directory))
  end;
  directory

let write_all descriptor contents =
  let rec write offset =
    if offset < String.length contents then
      let count =
        Unix.write_substring descriptor contents offset
          (String.length contents - offset)
      in
      if count = 0 then raise (Sys_error "could not write history file")
      else write (offset + count)
  in
  write 0

let temporary_file path =
  let directory = Filename.dirname path in
  let basename = Filename.basename path in
  let rec open_unique attempt =
    if attempt >= 32 then raise (Sys_error "could not create history file")
    else
      let candidate =
        Filename.concat directory
          (Printf.sprintf ".%s.%d.%08x.tmp" basename (Unix.getpid ())
             (Random.bits ()))
      in
      try
        let descriptor =
          Unix.openfile candidate
            [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_EXCL; Unix.O_TRUNC ]
            0o600
        in
        (candidate, descriptor)
      with Unix.Unix_error (Unix.EEXIST, _, _) -> open_unique (attempt + 1)
  in
  open_unique 0

let sync_directory directory =
  if not Sys.win32 then
    try
      let descriptor = Unix.openfile directory [ Unix.O_RDONLY ] 0 in
      Fun.protect
        ~finally:(fun () -> close_noerr descriptor)
        (fun () -> Unix.fsync descriptor)
    with Unix.Unix_error _ -> ()

let atomic_write path contents =
  let directory = prepare_directory path in
  let temporary, descriptor = temporary_file path in
  let descriptor_open = ref true in
  let committed = ref false in
  let close_descriptor () =
    if !descriptor_open then begin
      descriptor_open := false;
      close_noerr descriptor
    end
  in
  Fun.protect
    ~finally:(fun () ->
      close_descriptor ();
      if not !committed then
        try Unix.unlink temporary with Unix.Unix_error _ -> ())
    (fun () ->
      set_private_file_mode ~win32:Sys.win32 descriptor;
      write_all descriptor contents;
      Unix.fsync descriptor;
      close_descriptor ();
      Unix.rename temporary path;
      committed := true;
      sync_directory directory)

let validate_lock_path lock_path descriptor expected =
  let opened = Unix.fstat descriptor in
  require_owned_regular lock_path opened;
  begin match expected with
  | Some metadata when not (same_file metadata opened) ->
      raise (Sys_error "history lock changed while it was being opened")
  | Some _ -> ()
  | None ->
      begin match lstat lock_path with
      | Some metadata ->
          require_owned_regular lock_path metadata;
          if not (same_file metadata opened) then
            raise (Sys_error "history lock changed while it was being created")
      | None -> raise (Sys_error "history lock disappeared while it was being created")
      end
  end

let with_storage_lock storage action =
  let directory = prepare_directory storage.path in
  let lock_path = Filename.concat directory "history.lock" in
  let expected =
    match lstat lock_path with
    | None -> None
    | Some metadata ->
        require_owned_regular lock_path metadata;
        Some metadata
  in
  let descriptor =
    Unix.openfile lock_path [ Unix.O_RDWR; Unix.O_CREAT ] 0o600
  in
  Fun.protect
    ~finally:(fun () -> close_noerr descriptor)
    (fun () ->
      validate_lock_path lock_path descriptor expected;
      set_private_file_mode ~win32:Sys.win32 descriptor;
      Unix.lockf descriptor Unix.F_LOCK 0;
      action ())

let tolerate_storage_errors action =
  try action ()
  with
  | Sys_error _ | Unix.Unix_error _ | Yojson.Json_error _ | Invalid_argument _
  ->
    ()

let append_to_storage storage entry =
  tolerate_storage_errors (fun () ->
      with_storage_lock storage (fun () ->
          let entries = load storage in
          let entries =
            match List.rev entries with
            | previous :: _ when previous = entry -> entries
            | _ -> bounded_entries storage.limits (entries @ [ entry ])
          in
          atomic_write storage.path (serialize entries)))

let clear_storage storage =
  tolerate_storage_errors (fun () ->
      with_storage_lock storage (fun () ->
          atomic_write storage.path (serialize [])))

let create ?(persistent = true) ?path ?(limits = default_limits) () =
  let limits =
    {
      max_entries = max 0 limits.max_entries;
      max_bytes = max serialized_overhead limits.max_bytes;
      max_entry_bytes = max 0 limits.max_entry_bytes;
    }
  in
  let path =
    match path with Some path -> Some path | None -> default_path ()
  in
  let storage =
    if persistent then Option.map (fun path -> { path; limits }) path else None
  in
  let entries = Option.fold ~none:[] ~some:load storage in
  { limits; storage; newest_first = List.rev entries }

let entries history = List.rev history.newest_first

let add history entry =
  if valid_entry history.limits entry then
    match history.newest_first with
    | previous :: _ when previous = entry -> ()
    | _ ->
        let updated =
          bounded_entries history.limits (entries history @ [ entry ])
        in
        history.newest_first <- List.rev updated;
        begin match history.newest_first with
        | newest :: _ when newest = entry ->
            Option.iter
              (fun storage -> append_to_storage storage entry)
              history.storage
        | _ -> ()
        end

let clear history =
  history.newest_first <- [];
  Option.iter clear_storage history.storage
