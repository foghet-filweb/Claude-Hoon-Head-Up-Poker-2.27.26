::  /mar/poker-settle-result.hoon
::  Mark for the %poker-room → %poker-settle game result poke.
::  Payload: game-result:poker
/-  poker
|_  r=game-result:poker
++  grab
  |%
  ++  noun  game-result:poker
  --
++  grow
  |%
  ++  noun  r
  --
++  grad  %noun
--
