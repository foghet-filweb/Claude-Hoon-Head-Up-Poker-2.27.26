::  /mar/poker-settle-set-mode.hoon
::  Mark for the mode-change poke to %poker-settle (%play or %real).
|_  m=?(%play %real)
++  grab
  |%
  ++  noun  ?(%play %real)
  --
++  grow
  |%
  ++  noun  m
  --
++  grad  %noun
--
