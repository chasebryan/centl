module Centl.PhysicsSimulation

module P = Centl.Physics
module C = Centl.Core

type particle_state_1d = {
  state_time: P.quantity;
  state_mass: P.quantity;
  state_position: P.quantity;
  state_velocity: P.quantity
}

type force_model_1d =
  | UniformAcceleration: P.quantity -> force_model_1d
  | ConstantForce: P.quantity -> force_model_1d
  | IdealSpring: P.quantity -> force_model_1d

type simulation_error =
  | InvalidState
  | InvalidStep
  | InvalidModel
  | ZeroMass
  | ArithmeticFailure

type step_result =
  | StepOk: particle_state_1d -> step_result
  | StepError: simulation_error -> step_result

let quantity_positive (value:P.quantity) : Tot bool =
  value.magnitude.numerator > 0

let state_valid (state:particle_state_1d) : Tot bool =
  P.quantity_has_dimension state.state_time P.time_dimension &&
  P.quantity_has_dimension state.state_mass P.mass_dimension &&
  P.quantity_has_dimension state.state_position P.length_dimension &&
  P.quantity_has_dimension state.state_velocity P.velocity_dimension &&
  quantity_positive state.state_mass

let force_model_valid (model:force_model_1d) : Tot bool =
  match model with
  | UniformAcceleration acceleration ->
      P.quantity_has_dimension acceleration P.acceleration_dimension
  | ConstantForce force ->
      P.quantity_has_dimension force P.force_dimension
  | IdealSpring spring_constant ->
      P.quantity_has_dimension spring_constant P.spring_constant_dimension

let acceleration_from_force (mass force:P.quantity) : Tot P.quantity_result =
  if not (P.quantity_has_dimension mass P.mass_dimension) ||
     not (P.quantity_has_dimension force P.force_dimension)
  then P.DimensionMismatch
  else if mass.magnitude.numerator = 0 then P.DivisionByZero
  else P.quantity_divide force mass

let acceleration_at (state:particle_state_1d) (model:force_model_1d)
  : Tot P.quantity_result
=
  match model with
  | UniformAcceleration acceleration ->
      if P.quantity_has_dimension acceleration P.acceleration_dimension
      then P.QuantityOk acceleration
      else P.DimensionMismatch
  | ConstantForce force ->
      acceleration_from_force state.state_mass force
  | IdealSpring spring_constant ->
      begin match P.mechanics_hooke_force spring_constant state.state_position with
      | P.QuantityOk force -> acceleration_from_force state.state_mass force
      | P.DimensionMismatch -> P.DimensionMismatch
      | P.DivisionByZero -> P.DivisionByZero
      | P.InvalidUnit -> P.InvalidUnit
      | P.UndefinedPower -> P.UndefinedPower
      | P.InvalidSquareRoot -> P.InvalidSquareRoot
      | P.NonDimensionlessArgument -> P.NonDimensionlessArgument
      end

let half : P.exact_scalar = P.scalar 1 2

let velocity_verlet_step
    (state:particle_state_1d)
    (model:force_model_1d)
    (step:P.quantity)
  : Tot step_result
=
  if not (state_valid state) then
    if state.state_mass.magnitude.numerator = 0 then StepError ZeroMass
    else StepError InvalidState
  else if not (P.quantity_has_dimension step P.time_dimension) ||
          not (quantity_positive step)
  then StepError InvalidStep
  else if not (force_model_valid model) then StepError InvalidModel
  else
    begin match acceleration_at state model with
    | P.QuantityOk acceleration0 ->
        let velocity_term = P.quantity_multiply state.state_velocity step in
        let step_squared = P.quantity_multiply step step in
        let acceleration_term = P.quantity_multiply acceleration0 step_squared in
        begin match
          P.quantity_add velocity_term (P.quantity_scale half acceleration_term)
        with
        | P.QuantityOk displacement ->
            begin match P.quantity_add state.state_position displacement with
            | P.QuantityOk position1 ->
                let position_state = {
                  state_time = state.state_time;
                  state_mass = state.state_mass;
                  state_position = position1;
                  state_velocity = state.state_velocity
                } in
                begin match acceleration_at position_state model with
                | P.QuantityOk acceleration1 ->
                    begin match P.quantity_add acceleration0 acceleration1 with
                    | P.QuantityOk acceleration_sum ->
                        let velocity_delta =
                          P.quantity_scale half
                            (P.quantity_multiply acceleration_sum step)
                        in
                        begin match
                          P.quantity_add state.state_velocity velocity_delta
                        with
                        | P.QuantityOk velocity1 ->
                            begin match P.quantity_add state.state_time step with
                            | P.QuantityOk time1 ->
                                StepOk {
                                  state_time = time1;
                                  state_mass = state.state_mass;
                                  state_position = position1;
                                  state_velocity = velocity1
                                }
                            | _ -> StepError ArithmeticFailure
                            end
                        | _ -> StepError ArithmeticFailure
                        end
                    | _ -> StepError ArithmeticFailure
                    end
                | _ -> StepError ArithmeticFailure
                end
            | _ -> StepError ArithmeticFailure
            end
        | _ -> StepError ArithmeticFailure
        end
    | P.DivisionByZero -> StepError ZeroMass
    | _ -> StepError ArithmeticFailure
    end

let analytic_constant_acceleration_step
    (state:particle_state_1d)
    (acceleration:P.quantity)
    (step:P.quantity)
  : Tot step_result
=
  if not (state_valid state) then StepError InvalidState
  else if not (P.quantity_has_dimension acceleration P.acceleration_dimension)
  then StepError InvalidModel
  else if not (P.quantity_has_dimension step P.time_dimension) ||
          not (quantity_positive step)
  then StepError InvalidStep
  else
    let velocity_term = P.quantity_multiply state.state_velocity step in
    let step_squared = P.quantity_multiply step step in
    let acceleration_term = P.quantity_multiply acceleration step_squared in
    begin match P.quantity_add velocity_term (P.quantity_scale half acceleration_term) with
    | P.QuantityOk displacement ->
        begin match P.quantity_add state.state_position displacement with
        | P.QuantityOk position1 ->
            begin match P.quantity_add state.state_velocity
              (P.quantity_multiply acceleration step)
            with
            | P.QuantityOk velocity1 ->
                begin match P.quantity_add state.state_time step with
                | P.QuantityOk time1 ->
                    StepOk {
                      state_time = time1;
                      state_mass = state.state_mass;
                      state_position = position1;
                      state_velocity = velocity1
                    }
                | _ -> StepError ArithmeticFailure
                end
            | _ -> StepError ArithmeticFailure
            end
        | _ -> StepError ArithmeticFailure
        end
    | _ -> StepError ArithmeticFailure
    end

let state_dimensions_preserved (state:particle_state_1d) : Tot bool =
  P.quantity_has_dimension state.state_time P.time_dimension &&
  P.quantity_has_dimension state.state_mass P.mass_dimension &&
  P.quantity_has_dimension state.state_position P.length_dimension &&
  P.quantity_has_dimension state.state_velocity P.velocity_dimension

let uniform_acceleration_example ()
  : Lemma
      (ensures
        velocity_verlet_step
          {
            state_time = P.quantity_of_unit (P.scalar 0 1) P.second;
            state_mass = P.quantity_of_unit (P.scalar 2 1) P.kilogram;
            state_position = P.quantity_of_unit (P.scalar 0 1) P.meter;
            state_velocity =
              P.quantity_of_unit (P.scalar 3 1) P.meter_per_second
          }
          (UniformAcceleration
            (P.quantity_of_unit (P.scalar (-4) 1)
              P.meter_per_second_squared))
          (P.quantity_of_unit (P.scalar 1 1) P.second)
        =
        StepOk {
          state_time = P.quantity_of_unit (P.scalar 1 1) P.second;
          state_mass = P.quantity_of_unit (P.scalar 2 1) P.kilogram;
          state_position = P.quantity_of_unit (P.scalar 1 1) P.meter;
          state_velocity =
            P.quantity_of_unit (P.scalar (-1) 1) P.meter_per_second
        })
= ()
