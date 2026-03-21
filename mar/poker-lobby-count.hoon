::  /mar/poker-lobby-count.hoon
::
::  Mark for scry responses returning a single count value.
::  Used for /x/poker-lobby/ships, /x/poker-lobby/present, /x/poker-lobby/games
::
::  JSON shape: { "poker-lobby-count": 42 }
::
/+  format
|_  n=@ud
++  grab
  |%
  ++  noun  @ud
  --
++  grow
  |%
  ++  noun  n
  ++  json
    ^-  ^json
    %-  pairs:enjs:format
    ~[['poker-lobby-count' (numb:enjs:format n)]]
  --
++  grad  %noun
--
