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
  ++  json
    |=  j=^json
    ^-  @p
    =/  inner  ((ot ~[poker-decline-challenge+so]) j)
    (slav %p (cat 3 '~' inner))
  --
++  grow
  |%
  ++  noun  challenger
  --
++  grad  %noun
--
