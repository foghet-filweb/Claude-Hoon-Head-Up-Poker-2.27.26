::  /mar/poker-lobby-set-host.hoon
::  Mark for the owner poke that sets the lobby host ship.
::  Payload: @p
|_  host=@p
++  grab
  |%
  ++  noun  @p
  --
++  grow
  |%
  ++  noun  host
  --
++  grad  %noun
--
