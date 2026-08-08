open Centl_physics

type limits = {
  max_request_bytes : int;
  max_requests : int;
  max_steps : int;
  max_trajectory_steps : int;
}

let default_limits =
  {
    max_request_bytes = 65_536;
    max_requests = 10_000;
    max_steps = 100_000;
    max_trajectory_steps = 4_096;
  }

type state = { limits : limits; mutable requests : int }

let create ?(limits = default_limits) () = { limits; requests = 0 }
let limits state = state.limits
