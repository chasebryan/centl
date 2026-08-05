type queued_input =
  | Line_input of string
  | Oversized_input
  | Queue_overflow_input of string option

type queued_request
type request_queue

val create : capacity:int -> max_pending_bytes:int -> request_queue
val pending_byte_capacity : int -> int

val request :
  bytes:int -> queued_input -> Yojson.Safe.t option -> queued_request

val input : queued_request -> queued_input
val enqueue : request_queue -> ?target:Yojson.Safe.t -> queued_request -> bool
val close : request_queue -> exn option -> unit
val take : request_queue -> queued_request option
val complete : request_queue -> unit
val cancellation_callback : queued_request -> unit -> bool

val start_reader :
  channel:in_channel ->
  max_bytes:int ->
  classify_id:(Yojson.Safe.t -> Yojson.Safe.t option) ->
  classify_cancellation:(Yojson.Safe.t -> Yojson.Safe.t option) ->
  request_queue ->
  Thread.t

val reader_succeeded : request_queue -> bool

module For_testing : sig
  type snapshot = {
    pending_count : int;
    ordinary_pending_count : int;
    pending_bytes : int;
    emergency_bytes : int;
    active : queued_request option;
    waiting : int;
    closed : bool;
    reader_error : exn option;
  }

  val snapshot : request_queue -> snapshot
  val request_id : queued_request -> Yojson.Safe.t option
  val bytes : queued_request -> int
  val cancelled : queued_request -> bool
  val emergency_admission : queued_request -> bool
end
