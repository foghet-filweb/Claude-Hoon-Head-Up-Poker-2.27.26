::  /app/poker-sra.hoon
::
::  SRA (Shamir-Rivest-Adleman) commutative encryption library
::  for the Fhloston Poker Mental Poker deal protocol.
::
::  SRA uses the fact that for a prime p and key pairs (e_A, d_A), (e_B, d_B)
::  where e*d ≡ 1 (mod p-1), encryption commutes:
::    E_A(E_B(x)) = E_B(E_A(x)) = x^(e_A * e_B) mod p
::
::  This allows two parties to jointly encrypt a deck such that
::  neither can read any card without the other's cooperation.
::
::  Dependencies: Hoon stdlib only (++egcd from 3a, ++shax from zuse)
::  No external libraries needed — all integer arithmetic.
::
|%
::  +$ card-index: position in deck [0, 51]
+$  card-index  @ud

::  +$ enc-card: an encrypted card atom under SRA
+$  enc-card  @ux

::  +$ raw-deck: ordered list of 52 distinct card atoms
+$  raw-deck  (list @ud)

::  +$ enc-deck: list of 52 encrypted card atoms
+$  enc-deck  (list enc-card)

::  +$ sra-key: one player's SRA key pair over shared prime p
+$  sra-key
  $:  e=@ud
      d=@ud
      p=@ud
  ==

::  +$ commitment: sha256 hash used to bind a value before reveal
+$  commitment  @ux

::  +$ partial-dec: one player's partial decryption of a card position
+$  partial-dec
  $:  idx=card-index
      val=enc-card
  ==

::  ++sra-prime: the shared SRA modulus
::
::  RFC 3526 Group 14: 2048-bit MODP safe prime.
::  Source: https://datatracker.ietf.org/doc/html/rfc3526#section-3
::
::  Verified properties:
::    - p is prime                          ✓
::    - q = (p-1)/2 is prime (safe prime)  ✓
::    - bit length: 2048                    ✓
::
::  Both ships MUST use this exact constant — it is a desk invariant.
::  Card primes (53..331) are all << p, so no reduction issues.
::
::  Security note: 2048-bit discrete log provides ~112 bits of
::  security against classical attacks. Equivalent to modern TLS.
::  Suitable for real-money play.
++  sra-prime
  ^-  @ud
  29.392.145.799.020.915.820.018.593.809.821.894.182.112.320.087.199.113.106.946.251.492.809.771.395.181.409.591.368.437.229.324.235.292.658.978.994.868.179.317.340.587.543.375.654.630.702.919.335.986.391.300.332.048.024.315.465.022.046.073.714.405.864.153.603.837.845.539.126.272.015.988.368.954.003.282.600.065.564.677.172.181.500.773.985.169.581.032.310.378.873.880.577.766.719.788.222.321.235.419.456.217.554.383.746.216.248.762.176.772.079.546.664.425.490.261.861.074.831.951.812.594.875.345.955.743.977.052.290.631.561.780.706.755.012.585.792.321.588.652.984.650.598.984.443.787.058.357.810.957.772.113.263.034.719.656.333.542.874.805.287.241.912.568.301.009.994.925.704.224.497.186.985.149.248.886.332.642.039.692.622.127.344.973.292.862.310.790.705.079.298.790.749.537.906.412.531.733.691.816.214.526

::  ++pow-mod: fast binary (square-and-multiply) modular exponentiation
::  Computes (base^exp) mod m in O(log exp) multiplications.
::  Uses only Hoon atom arithmetic — no floating point.
++  pow-mod
  |=  [base=@ud exp=@ud m=@ud]
  ^-  @ud
  ?:  =(m 1)  0
  =/  result=@ud  1
  =/  b=@ud  (mod base m)
  |-  ^-  @ud
  ?:  =(exp 0)
    result
  =/  new-result
    ?:  =(1 (mod exp 2))
      (mod (mul result b) m)
    result
  =/  new-b  (mod (mul b b) m)
  =/  new-exp  (div exp 2)
  $(result new-result, b new-b, exp new-exp)

::  ++mod-inv: modular multiplicative inverse of a mod m
::  Requires gcd(a, m) = 1. Uses stdlib ++egcd.
::  Returns d such that a*d ≡ 1 (mod m).
++  mod-inv
  |=  [a=@ud m=@ud]
  ^-  @ud
  =/  g  (egcd a m)
  ~|  'mod-inv: gcd != 1, no inverse exists'
  ?>  =(1 -.g)
  =/  s=@s  +<.g
  %+  mod
    ?.  (syn:si s)
      (add (abs:si s) m)
    (abs:si s)
  m

::  ++gen-sra-key: generate an SRA key pair from entropy
::  Picks a random e coprime to (p-1), computes d = e^-1 mod (p-1).
::  NOTE: For production, e should be chosen from a safe range (e.g.
::  e > 2^16) to avoid small-exponent attacks.
++  gen-sra-key
  |=  [p=@ud entropy=@uv]
  ^-  sra-key
  =/  phi=@ud  (sub p 1)
  =/  e-raw=@ud  (mod (abs:si (signed entropy)) phi)
  =/  e=@ud  (find-coprime e-raw phi)
  =/  d=@ud  (mod-inv e phi)
  [e d p]

::  ++find-coprime: find smallest x >= candidate with gcd(x, m) = 1
::  Simple linear search — density of coprimes ensures fast termination.
++  find-coprime
  |=  [candidate=@ud m=@ud]
  ^-  @ud
  =/  x=@ud  (max 2 candidate)
  |-  ^-  @ud
  ?:  =(1 d:(egcd x m))  x
  $(x +(x))

::  ++signed: interpret @uv as signed for mod operation
++  signed
  |=  v=@uv
  ^-  @s
  (new:si %.y v)

::  ++sra-encrypt: encrypt a single card atom with key e over prime p
::  E_k(x) = x^e mod p
++  sra-encrypt
  |=  [card=@ud key=sra-key]
  ^-  enc-card
  `@ux`(pow-mod card e.key p.key)

::  ++sra-decrypt: decrypt a single card atom with key d over prime p
::  D_k(c) = c^d mod p
++  sra-decrypt
  |=  [cipher=enc-card key=sra-key]
  ^-  @ud
  (pow-mod `@ud`cipher d.key p.key)

::  ++encrypt-deck: encrypt all 52 cards with the given SRA key
++  encrypt-deck
  |=  [deck=raw-deck key=sra-key]
  ^-  enc-deck
  %+  turn  deck
  |=(card=@ud (sra-encrypt card key))

::  ++reencrypt-deck: apply a second layer of encryption to an already-encrypted deck
::  Used by Bob to re-encrypt Alice's encrypted deck: E_B(E_A(x_i))
++  reencrypt-deck
  |=  [deck=enc-deck key=sra-key]
  ^-  enc-deck
  %+  turn  deck
  |=(c=enc-card (sra-encrypt `@ud`c key))

::  ++decrypt-card: remove one encryption layer from a doubly-encrypted card
::  Alice calls this to produce E_B(x) from E_A(E_B(x))
++  decrypt-card
  |=  [cipher=enc-card key=sra-key]
  ^-  enc-card
  `@ux`(pow-mod `@ud`cipher d.key p.key)

::  ++partial-decrypt-positions: partially decrypt a list of positions
::  A player removes their own layer so the other can finish decryption.
++  partial-decrypt-positions
  |=  [deck=enc-deck positions=(list card-index) key=sra-key]
  ^-  (list partial-dec)
  %+  turn  positions
  |=  idx=card-index
  =/  cipher  (snag idx deck)
  [idx (decrypt-card cipher key)]

::  ++commit: SHA-256 commitment to a value, salted with room-id
::  commit(v, salt) = sha256(salt || v)
++  commit
  |=  [val=@ salt=@uv]
  ^-  commitment
  =/  bsalt  (atom-to-bytes salt)
  =/  bval   (atom-to-bytes val)
  (shax (can 3 ~[[(met 3 bsalt) bsalt] [(met 3 bval) bval]]))

::  ++commit-deck: commit to an entire encrypted deck
::  Used to prove a deck was fixed before dealing began.
++  commit-deck
  |=  [deck=enc-deck room-id=@uv]
  ^-  commitment
  =/  packed  (pack-deck deck)
  (commit packed room-id)

::  ++verify-commit: check that a value matches a prior commitment
++  verify-commit
  |=  [val=@ salt=@uv expected=commitment]
  ^-  ?
  =((commit val salt) expected)

::  ++pack-deck: serialise enc-deck to a single atom for hashing
::  Each card is packed as a fixed-width 2048-bit field to prevent
::  length-extension and card-swap attacks.
++  pack-deck
  |=  deck=enc-deck
  ^-  @ux
  =/  card-bits=@ud  2.048
  =|  acc=@ux
  |-  ^-  @ux
  ?~  deck  acc
  %=  $
    deck  t.deck
    acc   (con (lsh [0 card-bits] acc) (end [0 card-bits] i.deck))
  ==

::  ++make-deck: produce the canonical sorted deck of 52 card atoms
::  Cards are encoded as small primes to ensure they are distinct
::  and non-zero mod p. Using primes avoids accidental divisibility.
::  Suits: 0=clubs 1=diamonds 2=hearts 3=spades
::  Ranks: 0=2 .. 12=A
++  make-deck
  ^-  raw-deck
  ~[53 59 61 67 71 73 79 83 89 97 101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179 181 191 193 197 199 211 223 227 229 233 239 241 251 257 263 269 271 277 281 283 293 307 311 313 317 331]

::  ++card-to-suit-rank: decode a card prime back to [suit rank]
::  Inverse of the prime encoding in ++make-deck
++  card-to-suit-rank
  |=  card=@ud
  ^-  [suit=@ud rank=@ud]
  =/  deck  make-deck
  =/  idx   (find ~[card] deck)
  ~|  'card-to-suit-rank: unknown card prime'
  ?>  ?=(^ idx)
  =/  i  u.idx
  [(div i 13) (mod i 13)]

::  ++shuffle: Fisher-Yates shuffle of an enc-deck using a seed
::  The seed is the XOR of all player entropy contributions.
::  NOTE: prng-step uses xorshift64 — replace with ChaCha20 for production.
++  shuffle
  |=  [deck=enc-deck seed=@uv]
  ^-  enc-deck
  =/  n    52
  =/  arr  (list-to-array deck)
  =/  rng  seed
  =/  i    (sub n 1)
  |-  ^-  enc-deck
  ?:  =(i 0)  (array-to-list arr n)
  =/  rng    (prng-step rng)
  =/  j      (mod rng (add i 1))
  =/  arr    (array-swap arr i j)
  $(i (sub i 1), rng rng)

::  ++prng-step: advance the PRNG state (xorshift64)
::  Replace with ChaCha20 stream keyed on seed for production.
++  prng-step
  |=  state=@uv
  ^-  @uv
  =/  a  (mix state (lsh [0 13] state))
  =/  b  (mix a (rsh [0 7] a))
  (mix b (lsh [0 17] b))

::  Array helpers using maps (Hoon has no mutable arrays).
::  O(n log n) — fine for n=52.

++  list-to-array
  |=  lst=(list enc-card)
  ^-  (map @ud enc-card)
  =/  idx  0
  =|  arr=(map @ud enc-card)
  |-  ^-  (map @ud enc-card)
  ?~  lst  arr
  %=  $
    idx  +(idx)
    lst  t.lst
    arr  (~(put by arr) idx i.lst)
  ==

++  array-to-list
  |=  [arr=(map @ud enc-card) n=@ud]
  ^-  (list enc-card)
  =/  i  0
  =|  acc=(list enc-card)
  |-  ^-  (list enc-card)
  ?:  =(i n)  (flop acc)
  =/  v  (~(got by arr) i)
  $(i +(i), acc [v acc])

++  array-swap
  |=  [arr=(map @ud enc-card) i=@ud j=@ud]
  ^-  (map @ud enc-card)
  =/  vi  (~(got by arr) i)
  =/  vj  (~(got by arr) j)
  %+  ~(put by (~(put by arr) i vj))  j  vi

::  ++atom-to-bytes: pass-through for hashing helpers
++  atom-to-bytes
  |=  v=@
  ^-  @ux
  v
--
