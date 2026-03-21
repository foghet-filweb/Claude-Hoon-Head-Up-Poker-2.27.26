::  /mar/poker-reputation.hoon
::  Mark for /x/reputation scry result from %poker-settle.
::  Payload: (unit reputation) — reputation is defined in poker-settle.hoon
|_  r=*
++  grab
  |%
  ++  noun  *
  --
++  grow
  |%
  ++  noun  r
  --
++  grad  %noun
--
