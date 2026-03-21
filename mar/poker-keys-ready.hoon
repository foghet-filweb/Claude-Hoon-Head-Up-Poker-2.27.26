::  /mar/poker-keys-ready.hoon
::  Mark for /x/keys-ready scry result from %poker-settle and %slab-mint.
::  Payload: ? (%.y if keys are cached, %.n if not)
|_  ready=?
++  grab
  |%
  ++  noun  ?
  --
++  grow
  |%
  ++  noun  ready
  --
++  grad  %noun
--
