(** Build identity stamped into a CENTL binary. *)

val commit : string option
(** Immutable source commit supplied by release automation, when available. *)

val generated_core_hash : string option
(** SHA-256 of the concatenated extracted F* OCaml core snapshot files. *)
