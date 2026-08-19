  $ ../src/physics_main.exe convert 100 cm m
  1

  $ ../src/physics_main.exe constant c
  c=299792458 m/s
  name=speed of light in vacuum
  provenance=SI defining constant
  exact=true

  $ ../src/physics_main.exe cherenkov 4/3 1349066061/5
  status=emission
  emits=true
  refractive_index=4/3
  speed=1349066061/5 m/s
  threshold_speed=449688687/2 m/s
  beta=9/10
  threshold_beta=3/4
  beta_n=6/5
  cos_theta=5/6
  theta=acos(5/6) rad
  exact_trigonometric_relation=true

  $ ../src/physics_main.exe gravity 2 0,0,10 1,0,0 0,0,-10 1/10 10
  integrator=symplectic-euler
  steps=10
  position=1,0,9/2 m
  velocity=1,0,-10 m/s

  $ ../src/physics_main.exe convert 1 m s 2>&1
  centl-physics: convert to s: expected dimension s but got m
  [1]

  $ printf '%s\n' '{"version":1,"id":"convert","action":"convert","value":"100","from_unit":"cm","to_unit":"m"}' | ../src/physics_main.exe --serve | grep -o '"result":"1"'
  "result":"1"

  $ printf '%s\n' '{"version":1,"action":"cherenkov","refractive_index":"4/3","speed":{"value":"1349066061/5","unit":"m/s"}}' | ../src/physics_main.exe --serve | grep -o '"cosine":"5/6"'
  "cosine":"5/6"

  $ printf '%s\n' '{"version":1,"action":"capabilities"}' | ../src/physics_main.exe --serve | grep -o '"kind":"physics_capabilities"'
  "kind":"physics_capabilities"
