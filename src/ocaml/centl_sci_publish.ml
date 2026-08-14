type role = Contributor | Owner
type grant = { role : role; allow_commit : bool; allow_pr : bool }

let contains needle text =
  Option.is_some
    (Centl_sci_interaction.find_substring ~needle (String.lowercase_ascii text))

let wants text =
  let text = String.lowercase_ascii (String.trim text) in
  contains "prepare contribution" text
  || contains "prepare upstream" text
  || contains "pack contribution" text
  || contains "publish status" text
  || contains "grant contributor publish" text
  || contains "grant owner publish" text
  || contains "revoke publish" text
  || contains "stage contribution" text
  || contains "commit contribution" text
  || contains "open draft pull request" text
  || contains "open a pull request" text
  || contains "submit to github" text
  || contains "push this to github" text
  || contains "publish this to github" text
  || contains "upgrade centl on github" text
  || contains "achieve oasis" text
  || contains "declare oasis" text
  || contains "promote to oasis" text
  || contains "merge to oasis" text
  || contains "merge this pull request" text
  || contains "approve this pull request" text
  || contains "create the new release" text
  || contains "create a release" text
  || contains "tag a release" text

let lstat path =
  try Some (Unix.lstat path) with Unix.Unix_error (Unix.ENOENT, _, _) -> None

let home_dir () = Centl_platform.home_directory ()

let grant_path () =
  match home_dir () with
  | None -> None
  | Some home -> (
      match lstat home with
      | Some stat when stat.Unix.st_kind = Unix.S_LNK -> None
      | Some stat when stat.Unix.st_kind <> Unix.S_DIR -> None
      | None -> None
      | Some _ ->
          Some
            (Filename.concat (Filename.concat home ".centl") "publish.grant"))

let validate_secret_file path =
  match lstat path with
  | None -> Error "no publish grant is installed"
  | Some stat when stat.Unix.st_kind = Unix.S_LNK ->
      Error "refusing symbolic-link publish grant"
  | Some stat when stat.Unix.st_kind <> Unix.S_REG ->
      Error "publish grant is not a regular file"
  | Some stat
    when Centl_platform.posix_identity_enforced
         && stat.Unix.st_uid <> Unix.geteuid () ->
      Error "publish grant is not owned by the current user"
  | Some stat
    when Centl_platform.posix_identity_enforced
         && stat.Unix.st_perm land 0o077 <> 0 ->
      Error "publish grant must not be group/other readable"
  | Some _ -> Ok ()

let parse_grant json =
  match json with
  | `Assoc fields ->
      let string_field name =
        match List.assoc_opt name fields with
        | Some (`String value) -> Some value
        | _ -> None
      in
      let bool_field name =
        match List.assoc_opt name fields with
        | Some (`Bool value) -> Some value
        | _ -> None
      in
      begin match
        ( string_field "repository",
          string_field "role",
          bool_field "allow_commit",
          bool_field "allow_pr" )
      with
      | Some "chasebryan/centl", Some role, Some allow_commit, Some allow_pr ->
          begin match role with
          | "contributor" ->
              Ok
                {
                  role = Contributor;
                  allow_commit = false;
                  allow_pr = false;
                }
          | "owner" -> Ok { role = Owner; allow_commit; allow_pr }
          | _ -> Error "publish grant has an unknown role"
          end
      | Some repository, _, _, _ ->
          Error ("publish grant is not for chasebryan/centl: " ^ repository)
      | _ -> Error "publish grant is missing required fields"
      end
  | _ -> Error "publish grant is not a JSON object"

let read_grant () =
  match grant_path () with
  | None -> Error "HOME is unavailable; cannot read a publish grant"
  | Some path -> (
      match validate_secret_file path with
      | Error _ as error -> error
      | Ok () -> (
          try parse_grant (Yojson.Safe.from_file path)
          with Sys_error message | Yojson.Json_error message -> Error message))

let write_grant grant =
  match grant_path () with
  | None -> Error "HOME is unavailable; cannot write a publish grant"
  | Some path -> (
      try
        Centl_sci_workspace.ensure_directory (Filename.dirname path);
        begin match lstat path with
        | Some stat when stat.Unix.st_kind = Unix.S_LNK ->
            raise (Sys_error "refusing to overwrite a symbolic-link grant")
        | _ -> ()
        end;
        let json =
          `Assoc
            [
              ("schema_version", `Int 1);
              ("repository", `String "chasebryan/centl");
              ( "role",
                `String
                  (match grant.role with
                  | Contributor -> "contributor"
                  | Owner -> "owner") );
              ("allow_prepare", `Bool true);
              ("allow_pack", `Bool true);
              ("allow_commit", `Bool grant.allow_commit);
              ("allow_pr", `Bool grant.allow_pr);
              ("stores_credentials", `Bool false);
              ( "note",
                `String
                  "This grant never stores tokens. GitHub remains the approval \
                   authority. Pull requests are draft and target mirage." );
            ]
        in
        Centl_sci_workspace.atomic_write_json path json;
        Unix.chmod path 0o600;
        Ok path
      with Sys_error message | Unix.Unix_error (_, _, message) ->
        Error message)

let revoke_grant () =
  match grant_path () with
  | None -> Error "HOME is unavailable"
  | Some path -> (
      match lstat path with
      | None -> Ok "No publish grant was installed."
      | Some stat when stat.Unix.st_kind = Unix.S_LNK ->
          Error "refusing to remove a symbolic-link grant"
      | Some _ -> (
          try
            Sys.remove path;
            Ok "Publish grant revoked."
          with Sys_error message -> Error message))

let owner_acceptance = "i accept local git and gh without storing tokens"
let source_markers = [ "centl.opam"; "src/ocaml"; ".git" ]

let is_source_root dir =
  List.for_all
    (fun name -> Sys.file_exists (Filename.concat dir name))
    source_markers

let rec walk_source dir =
  match lstat dir with
  | Some stat when stat.Unix.st_kind = Unix.S_LNK -> None
  | Some stat when stat.Unix.st_kind <> Unix.S_DIR -> None
  | None -> None
  | Some _ ->
      if is_source_root dir then Some dir
      else
        let parent = Filename.dirname dir in
        if parent = dir then None else walk_source parent

let source_root () =
  match Sys.getenv_opt "CENTL_SOURCE" with
  | Some value when String.trim value <> "" ->
      let value = String.trim value in
      begin match lstat value with
      | Some stat
        when stat.Unix.st_kind = Unix.S_DIR && is_source_root value ->
          Some value
      | _ -> None
      end
  | _ -> walk_source (Sys.getcwd ())

let safe_branch id =
  let digest = String.sub (Centl_sha256.hex_string id) 0 8 in
  "centl-sci/contrib-" ^ digest

let valid_pack_id name =
  let length = String.length name in
  length >= 12 && length <= 24
  && String.starts_with ~prefix:"r" name
  && String.for_all
       (function 'a' .. 'z' | '0' .. '9' | '-' -> true | _ -> false)
       name
  && (not (String.contains name '/'))
  && (not (String.contains name '\\'))

let safe_basename name =
  name <> "" && name <> "." && name <> ".."
  && (not (String.contains name '/'))
  && (not (String.contains name '\\'))
  && name.[0] <> '.'
  && String.for_all
       (function
         | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' | '.' -> true
         | _ -> false)
       name

let looks_secret text =
  let lower = String.lowercase_ascii text in
  contains "ghp_" text
  || contains "gho_" text
  || contains "github_pat_" lower
  || contains "begin openssh private key" lower
  || contains "aws_secret_access_key" lower

let valid_branch name =
  let ok = function
    | 'a' .. 'z' | '0' .. '9' | '-' | '/' -> true
    | _ -> false
  in
  String.starts_with ~prefix:"centl-sci/contrib-" name
  && String.length name <= 48
  && String.for_all ok name

let max_copy_bytes = 256 * 1024

let read_regular path =
  match lstat path with
  | Some stat
    when stat.Unix.st_kind = Unix.S_REG && stat.Unix.st_size <= max_copy_bytes
    -> (
      try
        let channel = open_in_bin path in
        Fun.protect
          ~finally:(fun () -> close_in_noerr channel)
          (fun () ->
            Ok (really_input_string channel (in_channel_length channel)))
      with Sys_error message -> Error message)
  | Some stat when stat.Unix.st_kind = Unix.S_LNK ->
      Error ("refusing symbolic link: " ^ path)
  | _ -> Error ("refusing oversized or non-regular file: " ^ path)

let copy_file source dest =
  match read_regular source with
  | Error _ as error -> error
  | Ok text when looks_secret text ->
      Error ("refusing to pack possible secret material: " ^ source)
  | Ok text -> (
      try
        Centl_sci_workspace.ensure_directory (Filename.dirname dest);
        Centl_sci_workspace.with_atomic_output dest (fun channel ->
            output_string channel text);
        Ok ()
      with Sys_error message | Unix.Unix_error (_, _, message) ->
        Error message)

let run_allowlisted ~cwd executable args =
  if executable <> "git" && executable <> "gh" then
    Error "refusing non-allowlisted executable"
  else
    match lstat cwd with
    | Some stat when stat.Unix.st_kind <> Unix.S_DIR ->
        Error "refusing to run from a non-directory"
    | Some stat when stat.Unix.st_kind = Unix.S_LNK ->
        Error "refusing to run from a symbolic-link directory"
    | None -> Error "working directory is unavailable"
    | Some _ ->
        let args =
          match executable with
          | "git" -> "-C" :: cwd :: args
          | _ -> args
        in
        let argv = Array.of_list (executable :: args) in
        try
          let previous = Sys.getcwd () in
          Fun.protect
            ~finally:(fun () -> try Sys.chdir previous with Sys_error _ -> ())
            (fun () ->
              if executable = "gh" then Sys.chdir cwd;
              let channel = Unix.open_process_args_in executable argv in
              let buffer = Buffer.create 256 in
              let rec loop count =
                if count > 65_536 then Error "command output exceeded the bound"
                else
                  match input_char channel with
                  | character ->
                      Buffer.add_char buffer character;
                      loop (count + 1)
                  | exception End_of_file ->
                      begin match Unix.close_process_in channel with
                      | Unix.WEXITED 0 -> Ok (Buffer.contents buffer)
                      | Unix.WEXITED code ->
                          Error
                            (Printf.sprintf "%s exited %d: %s" executable code
                               (String.trim (Buffer.contents buffer)))
                      | _ -> Error (executable ^ " terminated abnormally")
                      end
              in
              loop 0)
        with Sys_error message | Unix.Unix_error (_, _, message) ->
          Error message

let origin_is_official root =
  match run_allowlisted ~cwd:root "git" [ "remote"; "get-url"; "origin" ] with
  | Error _ -> false
  | Ok url ->
      let url = String.lowercase_ascii (String.trim url) in
      let url =
        if String.ends_with ~suffix:".git\n" url then
          String.sub url 0 (String.length url - 5)
        else if String.ends_with ~suffix:".git" url then
          String.sub url 0 (String.length url - 4)
        else String.trim url
      in
      url = "https://github.com/chasebryan/centl"
      || url = "git@github.com:chasebryan/centl"
      || url = "ssh://git@github.com/chasebryan/centl"

let pack_id workspace =
  let revision = Centl_sci_workspace.read_revision workspace in
  Printf.sprintf "r%d-%s" revision
    (String.sub
       (Centl_sha256.hex_string (workspace.root ^ string_of_int revision))
       0 8)

let pack_root workspace id =
  Filename.concat
    (Filename.concat workspace.Centl_sci_workspace.generated "contributions")
    id

let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  Centl_sci_workspace.with_atomic_output path (fun channel ->
      output_string channel text;
      if text = "" || text.[String.length text - 1] <> '\n' then
        output_char channel '\n')

let review_document ~id ~role =
  String.concat "\n"
    [
      "# CENTL contribution pack " ^ id;
      "";
      "Upstream: `chasebryan/centl`";
      ("Role: "
      ^ match role with Contributor -> "contributor" | Owner -> "owner");
      "";
      "This pack is downstream material. It is not verified CENTL core.";
      "GitHub pull-request review remains the approval authority.";
      "CENTL does not store tokens and does not force-push.";
      "Draft pull requests target `mirage`, never `oasis`.";
      "";
      "## Required human review";
      "";
      "- DCO sign-off on any commit (`git commit -s`)";
      "- no secrets, tokens, home paths, or private journal text";
      "- tests for any behavior change";
      "- assurance claims remain honest";
      "- owner and contributor changes use the same review gate";
      "";
    ]

let security_document () =
  String.concat "\n"
    [
      "# Security checklist";
      "";
      "- [ ] No credentials or tokens are included";
      "- [ ] No generated program is presented as verified core";
      "- [ ] No host binary was rewritten by this pack";
      "- [ ] Network was not used except an explicit draft `gh pr create`";
      "- [ ] The operator ran `make test` / relevant quality gates";
      "";
      "No software is 100% secure. This path removes whole classes of hole:";
      "no shell interpolation of English, no stored tokens, no force push,";
      "no oasis target, draft PR only, allowlisted argv only.";
      "";
    ]

let copy_tree_limited ~src_dir ~dest_dir ~suffixes =
  if not (Sys.file_exists src_dir) then 0
  else
    let names = Sys.readdir src_dir |> Array.to_list in
    List.fold_left
      (fun count name ->
        if count >= 32 then count
        else if not (safe_basename name) then count
        else
          let source = Filename.concat src_dir name in
          match lstat source with
          | Some stat when stat.Unix.st_kind = Unix.S_REG ->
              if
                List.exists
                  (fun suffix -> Filename.check_suffix name suffix)
                  suffixes
              then
                match copy_file source (Filename.concat dest_dir name) with
                | Ok () -> count + 1
                | Error _ -> count
              else count
          | _ -> count)
      0 names

let pack workspace =
  let id = pack_id workspace in
  let root = pack_root workspace id in
  let role =
    match read_grant () with Ok grant -> grant.role | Error _ -> Contributor
  in
  try
    Centl_sci_workspace.ensure workspace;
    Centl_sci_workspace.ensure_directory root;
    write_text (Filename.concat root "REVIEW.md") (review_document ~id ~role);
    write_text
      (Filename.concat root "SECURITY-CHECKLIST.md")
      (security_document ());
    write_text
      (Filename.concat root "DCO.md")
      "Every Git commit must use `git commit -s`.\nSee the repository DCO.md.\n";
    ignore (Centl_sci_journal.write_dialect workspace);
    let dialect = Centl_sci_journal.dialect_path workspace in
    if Sys.file_exists dialect then
      ignore (copy_file dialect (Filename.concat root "dialect.centl"));
    let copied_modules =
      copy_tree_limited ~src_dir:workspace.modules_dir
        ~dest_dir:(Filename.concat root "modules")
        ~suffixes:[ ".centl" ]
    in
    let copied_spoken =
      copy_tree_limited
        ~src_dir:(Filename.concat workspace.root "spoken")
        ~dest_dir:(Filename.concat root "spoken")
        ~suffixes:[ ".json" ]
    in
    Ok
      ( root,
        Printf.sprintf
          "Packed contribution `%s`.\n\
           Path: %s\n\
           Copied %d module file(s) and %d spoken alias file(s).\n\
           No network was used. Review REVIEW.md before any GitHub step.\n\
           Other users still need a draft pull request and human approval."
          id root copied_modules copied_spoken )
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let latest_pack workspace =
  let directory =
    Filename.concat workspace.Centl_sci_workspace.generated "contributions"
  in
  if not (Sys.file_exists directory) then None
  else
    Sys.readdir directory |> Array.to_list
    |> List.filter (fun name ->
        valid_pack_id name
        && Sys.file_exists
             (Filename.concat (Filename.concat directory name) "REVIEW.md"))
    |> List.sort String.compare |> List.rev
    |> function
    | name :: _ -> Some name
    | [] -> None

let stage workspace =
  match source_root () with
  | None ->
      Error
        "No CENTL source checkout was found. Set CENTL_SOURCE or run from the \
         repository if you want files staged for a pull request. The local \
         pack is still available."
  | Some source -> (
      match latest_pack workspace with
      | None ->
          Error "No contribution pack exists. Run `pack contribution` first."
      | Some id when not (valid_pack_id id) ->
          Error "refusing unsafe contribution pack identity"
      | Some id -> (
          let src = pack_root workspace id in
          let dest =
            Filename.concat
              (Filename.concat
                 (Filename.concat source "lab")
                 "sci-contributions")
              (Filename.concat "proposed" id)
          in
          let allowed_prefix =
            Filename.concat source "lab/sci-contributions/proposed/"
          in
          if
            not
              (String.starts_with ~prefix:allowed_prefix dest
              || String.starts_with ~prefix:allowed_prefix (dest ^ "/"))
          then Error "refusing to stage outside lab/sci-contributions/proposed"
          else
          try
            Centl_sci_workspace.ensure_directory dest;
            let files =
              [
                "REVIEW.md"; "SECURITY-CHECKLIST.md"; "DCO.md"; "dialect.centl";
              ]
            in
            List.iter
              (fun name ->
                let from_path = Filename.concat src name in
                if Sys.file_exists from_path then
                  ignore (copy_file from_path (Filename.concat dest name)))
              files;
            ignore
              (copy_tree_limited
                 ~src_dir:(Filename.concat src "modules")
                 ~dest_dir:(Filename.concat dest "modules")
                 ~suffixes:[ ".centl" ]);
            ignore
              (copy_tree_limited
                 ~src_dir:(Filename.concat src "spoken")
                 ~dest_dir:(Filename.concat dest "spoken")
                 ~suffixes:[ ".json" ]);
            Ok
              (Printf.sprintf
                 "Staged pack `%s` at %s\n\
                  Only this proposed pack will be committable through CENTL.\n\
                  Verified core and oasis were not touched."
                 id dest)
          with Sys_error message -> Error message))

let commit workspace =
  match read_grant () with
  | Error message -> Error message
  | Ok grant when not grant.allow_commit ->
      Error
        "This publish grant does not allow commits. Use `grant owner publish I \
         accept local git and gh without storing tokens` or commit by hand \
         with `git commit -s`."
  | Ok _ -> (
      match source_root () with
      | None -> Error "No CENTL source checkout is available."
      | Some source -> (
          match latest_pack workspace with
          | None -> Error "No contribution pack exists."
          | Some id ->
              let branch = safe_branch id in
              if not (valid_branch branch) then Error "refusing invalid branch"
              else
                let rel =
                  Filename.concat
                    (Filename.concat "lab/sci-contributions/proposed" id)
                    ""
                in
                let rel = String.sub rel 0 (String.length rel - 1) in
                let ( let* ) = Result.bind in
                let* _ =
                  run_allowlisted ~cwd:source "git"
                    [ "rev-parse"; "--is-inside-work-tree" ]
                in
                let* _ =
                  run_allowlisted ~cwd:source "git" [ "checkout"; "-b"; branch ]
                in
                let* _ =
                  run_allowlisted ~cwd:source "git" [ "add"; "--"; rel ]
                in
                let message = "centl-sci: draft contribution pack " ^ id in
                let* _ =
                  run_allowlisted ~cwd:source "git"
                    [ "commit"; "-s"; "-m"; message ]
                in
                Ok
                  (Printf.sprintf
                     "Created signed commit on `%s` adding only `%s`.\n\
                      This did not push. Open a draft pull request next, or \
                      push yourself."
                     branch rel)))

let open_pr workspace =
  match read_grant () with
  | Error message -> Error message
  | Ok grant when not grant.allow_pr ->
      Error
        "This publish grant does not allow GitHub pull requests. Grant owner \
         publish, or open the PR yourself with `gh pr create --draft --base \
         mirage`."
  | Ok _ -> (
      match source_root () with
      | None -> Error "No CENTL source checkout is available."
      | Some source -> (
          if not (origin_is_official source) then
            Error
              "origin is not github.com/chasebryan/centl. CENTL will not aim a \
               pull request at another repository. Push your fork yourself and \
               open a draft PR targeting mirage."
          else
            match latest_pack workspace with
            | None -> Error "No contribution pack exists."
            | Some id -> (
                let branch = safe_branch id in
                if not (valid_branch branch) then
                  Error "refusing invalid branch"
                else
                  let body =
                    Filename.concat (pack_root workspace id) "REVIEW.md"
                  in
                  if not (Sys.file_exists body) then
                    Error "contribution REVIEW.md is missing"
                  else
                    let args =
                      [
                        "pr";
                        "create";
                        "--draft";
                        "--repo";
                        "chasebryan/centl";
                        "--base";
                        "mirage";
                        "--head";
                        branch;
                        "--title";
                        "centl-sci contribution pack " ^ id;
                        "--body-file";
                        body;
                      ]
                    in
                    match run_allowlisted ~cwd:source "gh" args with
                    | Error message -> Error message
                    | Ok output ->
                        Ok
                          (String.trim output
                         ^ "\n\
                            Draft pull request opened against `mirage`.\n\
                            Human review is still required. oasis was not \
                            targeted."))))

let promotion_logic () =
  String.concat "\n"
    [
      "Official Oasis logic (this replaces informal “just ship it” \
       instructions):";
      "";
      "1. Experimental and laboratory work targets `mirage`.";
      "   Mirage is never a full release. Users may build or install from";
      "   `mirage` if they want experimental surfaces.";
      "2. `main` is the complete developer/research distribution. It is not";
      "   an Oasis declaration.";
      "3. Oasis is a promotion state on the `oasis` branch only, after";
      "   `python3 scripts/oasis.py` and a final identity pass succeed on a";
      "   clean, reviewed commit. See docs/OASIS.md.";
      "4. CENTL v0.14.0 remains the published Oasis release until a later";
      "   identity earns its own declaration. Oasis does not inherit.";
      "5. No agent, owner grant, or green CI result may self-approve, merge";
      "   to oasis, or create a SemVer tag.";
      "6. Draft pull requests created by CENTL-SCi target `mirage` only.";
      "7. Oasis does not regress: a candidate must contain the current oasis";
      "   tip. Merge oasis into the candidate before promotion. Do not drop";
      "   installer channels, gates, or Oasis-only fixes to land laboratory work.";
      "";
      "This command will not declare Oasis, merge to oasis, or publish a tag.";
    ]

let oasis_inspect () =
  let root = Option.value (source_root ()) ~default:(Sys.getcwd ()) in
  let branch =
    match
      run_allowlisted ~cwd:root "git" [ "rev-parse"; "--abbrev-ref"; "HEAD" ]
    with
    | Ok value -> String.trim value
    | Error _ -> "unknown"
  in
  let report =
    Centl_sci_oasis.inspect ~root ~current_version:Centl_version.value ~branch
  in
  Ok (Centl_sci_oasis.render report ^ "\n\n" ^ promotion_logic ())

let status () =
  let grant_text =
    match read_grant () with
    | Error message -> "grant: " ^ message
    | Ok grant ->
        Printf.sprintf "grant: role=%s commit=%b pr=%b tokens_stored=false"
          (match grant.role with
          | Contributor -> "contributor"
          | Owner -> "owner")
          grant.allow_commit grant.allow_pr
  in
  let source_text =
    match source_root () with
    | None -> "source checkout: not found"
    | Some root ->
        "source checkout: " ^ root ^ "\nofficial origin: "
        ^ if origin_is_official root then "yes" else "no"
  in
  String.concat "\n"
    [
      "CENTL publish status";
      "upstream: chasebryan/centl";
      grant_text;
      source_text;
      "published Oasis: v0.14.0 (unchanged by this command)";
      "SCi pull-request base: mirage (never oasis)";
      "approval: GitHub human review (never self-approved)";
      "forbidden: force push, oasis base, stored tokens, shell English,";
      "           self-merge, release tags, Oasis declaration";
      "No system is 100% secure. This path is deliberately narrow.";
      "";
      promotion_logic ();
    ]

let handle text =
  let trimmed = String.trim text in
  let lower = String.lowercase_ascii trimmed in
  if List.mem lower [ "publish status"; "show publish status" ] then
    Ok (status ())
  else if
    contains "achieve oasis" lower
    || contains "declare oasis" lower
    || contains "promote to oasis" lower
    || contains "inspect oasis" lower
  then oasis_inspect ()
  else if
    contains "merge to oasis" lower
    || contains "merge this pull request" lower
    || contains "approve this pull request" lower
    || contains "create the new release" lower
    || contains "create a release" lower
    || contains "tag a release" lower
  then
    Error
      ("CENTL will not self-approve, merge to oasis, or create a release tag.\n"
     ^ promotion_logic ())
  else if lower = "grant contributor publish" then
    match
      write_grant { role = Contributor; allow_commit = false; allow_pr = false }
    with
    | Error message -> Error message
    | Ok path ->
        Ok
          ("Installed a contributor publish grant at " ^ path
         ^ ".\n\
            You can prepare and pack. Commits and GitHub PRs stay manual.\n\
            Tokens were not stored.")
  else if
    String.starts_with ~prefix:"grant owner publish" lower
    && contains owner_acceptance lower
  then
    match
      write_grant { role = Owner; allow_commit = true; allow_pr = true }
    with
    | Error message -> Error message
    | Ok path ->
        Ok
          ("Installed an owner publish grant at " ^ path
         ^ ".\n\
            Commit and draft-PR verbs are enabled for this login only.\n\
            Tokens are still not stored. oasis cannot be targeted. Review \
            remains required.")
  else if String.starts_with ~prefix:"grant owner publish" lower then
    Error
      "Owner publish is powerful. Repeat exactly:\n\
       grant owner publish I accept local git and gh without storing tokens"
  else if contains "revoke publish" lower then revoke_grant ()
  else if
    List.mem lower
      [
        "prepare contribution";
        "prepare upstream contribution";
        "prepare this extension for upstream contribution";
        "prepare changes for upstream contribution";
      ]
  then
    match Centl_sci_workspace.default () with
    | None -> Error "No workspace is available."
    | Some workspace -> (
        match Centl_sci_scaffold.prepare_upstream workspace with
        | Error message -> Error message
        | Ok path ->
            Ok
              ("Prepared a local review artifact.\nPath: " ^ path
             ^ "\nNo branch, commit, push, or publication was performed."))
  else if List.mem lower [ "pack contribution"; "pack this contribution" ] then
    match Centl_sci_workspace.default () with
    | None -> Error "No workspace is available."
    | Some workspace -> (
        match pack workspace with
        | Error message -> Error message
        | Ok (_, message) -> Ok message)
  else if List.mem lower [ "stage contribution" ] then
    match Centl_sci_workspace.default () with
    | None -> Error "No workspace is available."
    | Some workspace -> stage workspace
  else if List.mem lower [ "commit contribution" ] then
    match Centl_sci_workspace.default () with
    | None -> Error "No workspace is available."
    | Some workspace -> commit workspace
  else if
    List.mem lower
      [ "open draft pull request"; "open a pull request"; "submit to github" ]
  then
    match Centl_sci_workspace.default () with
    | None -> Error "No workspace is available."
    | Some workspace -> open_pr workspace
  else if
    contains "push this to github" lower
    || contains "publish this to github" lower
    || contains "upgrade centl on github" lower
  then
    Ok
      (String.concat "\n"
         [
           "CENTL will not push English straight to GitHub.";
           "Required sequence:";
           "  1. pack contribution";
           "  2. review the pack";
           "  3. stage contribution";
           "  4. commit contribution   (owner grant, signed)";
           "  5. open draft pull request";
           "Contributors without a grant stop at the pack and open a PR by \
            hand.";
           "Approval is always a human GitHub review. oasis is never the base.";
           status ();
         ])
  else Error "Unrecognized publish request. Try `publish status`."
