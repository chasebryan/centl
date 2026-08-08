  $ ../src/physics_main.exe convert 100 cm m
  1

  $ ../src/physics_main.exe constant c
  c=299792458 m/s
  name=speed of light in vacuum
  provenance=SI defining constant
  exact=true

  $ ../src/physics_main.exe gravity 2 0,0,10 1,0,0 0,0,-10 1/10 10
  integrator=symplectic-euler
  steps=10
  position=1,0,9/2 m
  velocity=1,0,-10 m/s

  $ ../src/physics_main.exe convert 1 m s 2>&1
  centl-physics: convert to s: expected dimension s but got m
  [1]
