let k =
  [|
    0x428a2f98l;
    0x71374491l;
    0xb5c0fbcfl;
    0xe9b5dba5l;
    0x3956c25bl;
    0x59f111f1l;
    0x923f82a4l;
    0xab1c5ed5l;
    0xd807aa98l;
    0x12835b01l;
    0x243185bel;
    0x550c7dc3l;
    0x72be5d74l;
    0x80deb1fel;
    0x9bdc06a7l;
    0xc19bf174l;
    0xe49b69c1l;
    0xefbe4786l;
    0x0fc19dc6l;
    0x240ca1ccl;
    0x2de92c6fl;
    0x4a7484aal;
    0x5cb0a9dcl;
    0x76f988dal;
    0x983e5152l;
    0xa831c66dl;
    0xb00327c8l;
    0xbf597fc7l;
    0xc6e00bf3l;
    0xd5a79147l;
    0x06ca6351l;
    0x14292967l;
    0x27b70a85l;
    0x2e1b2138l;
    0x4d2c6dfcl;
    0x53380d13l;
    0x650a7354l;
    0x766a0abbl;
    0x81c2c92el;
    0x92722c85l;
    0xa2bfe8a1l;
    0xa81a664bl;
    0xc24b8b70l;
    0xc76c51a3l;
    0xd192e819l;
    0xd6990624l;
    0xf40e3585l;
    0x106aa070l;
    0x19a4c116l;
    0x1e376c08l;
    0x2748774cl;
    0x34b0bcb5l;
    0x391c0cb3l;
    0x4ed8aa4al;
    0x5b9cca4fl;
    0x682e6ff3l;
    0x748f82eel;
    0x78a5636fl;
    0x84c87814l;
    0x8cc70208l;
    0x90befffal;
    0xa4506cebl;
    0xbef9a3f7l;
    0xc67178f2l;
  |]

let rotr value bits =
  Int32.logor
    (Int32.shift_right_logical value bits)
    (Int32.shift_left value (32 - bits))

let ch x y z = Int32.logxor (Int32.logand x y) (Int32.logand (Int32.lognot x) z)

let maj x y z =
  Int32.logxor
    (Int32.logxor (Int32.logand x y) (Int32.logand x z))
    (Int32.logand y z)

let big_sigma0 x =
  Int32.logxor (Int32.logxor (rotr x 2) (rotr x 13)) (rotr x 22)

let big_sigma1 x =
  Int32.logxor (Int32.logxor (rotr x 6) (rotr x 11)) (rotr x 25)

let small_sigma0 x =
  Int32.logxor
    (Int32.logxor (rotr x 7) (rotr x 18))
    (Int32.shift_right_logical x 3)

let small_sigma1 x =
  Int32.logxor
    (Int32.logxor (rotr x 17) (rotr x 19))
    (Int32.shift_right_logical x 10)

let byte bytes index = Char.code (Bytes.get bytes index)

let word32_be bytes offset =
  let open Int32 in
  logor
    (shift_left (of_int (byte bytes offset)) 24)
    (logor
       (shift_left (of_int (byte bytes (offset + 1))) 16)
       (logor
          (shift_left (of_int (byte bytes (offset + 2))) 8)
          (of_int (byte bytes (offset + 3)))))

let write_u64_be bytes offset value =
  for index = 0 to 7 do
    let shift = (7 - index) * 8 in
    let octet =
      Int64.(to_int (logand (shift_right_logical value shift) 0xffL))
    in
    Bytes.set bytes (offset + index) (Char.chr octet)
  done

let padded input =
  let length = String.length input in
  let zeroes = (56 - ((length + 1) mod 64) + 64) mod 64 in
  let total = length + 1 + zeroes + 8 in
  let bytes = Bytes.make total '\000' in
  Bytes.blit_string input 0 bytes 0 length;
  Bytes.set bytes length (Char.chr 0x80);
  write_u64_be bytes (total - 8) Int64.(mul (of_int length) 8L);
  bytes

let add4 a b c d = Int32.add (Int32.add a b) (Int32.add c d)
let add5 a b c d e = Int32.add (add4 a b c d) e

let digest_words input =
  let state =
    [|
      0x6a09e667l;
      0xbb67ae85l;
      0x3c6ef372l;
      0xa54ff53al;
      0x510e527fl;
      0x9b05688cl;
      0x1f83d9abl;
      0x5be0cd19l;
    |]
  in
  let bytes = padded input in
  let schedule = Array.make 64 0l in
  let block_count = Bytes.length bytes / 64 in
  for block = 0 to block_count - 1 do
    let base = block * 64 in
    for index = 0 to 15 do
      schedule.(index) <- word32_be bytes (base + (index * 4))
    done;
    for index = 16 to 63 do
      schedule.(index) <-
        add4
          (small_sigma1 schedule.(index - 2))
          schedule.(index - 7)
          (small_sigma0 schedule.(index - 15))
          schedule.(index - 16)
    done;
    let a = ref state.(0) in
    let b = ref state.(1) in
    let c = ref state.(2) in
    let d = ref state.(3) in
    let e = ref state.(4) in
    let f = ref state.(5) in
    let g = ref state.(6) in
    let h = ref state.(7) in
    for index = 0 to 63 do
      let t1 =
        add5 !h (big_sigma1 !e) (ch !e !f !g) k.(index) schedule.(index)
      in
      let t2 = Int32.add (big_sigma0 !a) (maj !a !b !c) in
      h := !g;
      g := !f;
      f := !e;
      e := Int32.add !d t1;
      d := !c;
      c := !b;
      b := !a;
      a := Int32.add t1 t2
    done;
    state.(0) <- Int32.add state.(0) !a;
    state.(1) <- Int32.add state.(1) !b;
    state.(2) <- Int32.add state.(2) !c;
    state.(3) <- Int32.add state.(3) !d;
    state.(4) <- Int32.add state.(4) !e;
    state.(5) <- Int32.add state.(5) !f;
    state.(6) <- Int32.add state.(6) !g;
    state.(7) <- Int32.add state.(7) !h
  done;
  state

let hex_string input =
  digest_words input |> Array.to_list
  |> List.map (fun word -> Printf.sprintf "%08lx" word)
  |> String.concat ""
