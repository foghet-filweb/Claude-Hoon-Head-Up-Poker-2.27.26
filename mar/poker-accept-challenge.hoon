::  /mar/poker-accept-challenge.hoon
::  Mark for the front-end poke accepting an incoming challenge.
::  Payload: @p (the challenger's ship address)
::
::  JSON shape: { "poker-accept-challenge": "sampel-palnet" }
/+  format
|_  challenger=@p
++  grab
  |%
  ++  noun  @p
  ++  json
    |=  j=^json
    ^-  @p
    =/  inner  ((ot ~[poker-accept-challenge+so]) j)
    (slav %p (cat 3 '~' inner))
  --
++  grow
  |%
  ++  noun  challenger
  --
++  grad  %noun
--
