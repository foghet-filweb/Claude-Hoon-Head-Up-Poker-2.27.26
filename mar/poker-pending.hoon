::  /mar/poker-pending.hoon
::  Mark for /x/pending scry result from %poker-settle.
::  Payload: (map @uv game-result:poker)
/-  poker
|_  p=(map @uv game-result:poker)
++  grab
  |%
  ++  noun  (map @uv game-result:poker)
  --
++  grow
  |%
  ++  noun  p
  --
++  grad  %noun
--
