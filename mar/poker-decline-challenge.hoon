::  /mar/poker-decline-challenge.hoon
::  Mark for the front-end poke declining an incoming challenge.
::  Payload: @p (the challenger's ship address)
::
::  JSON shape: { "poker-decline-challenge": "sampel-palnet" }
/+  format
|_  challenger=@p
++  grab
  |%
  ++  noun  @p
  --
++  grow
  |%
  ++  noun  challenger
  --
++  grad  %noun
--
