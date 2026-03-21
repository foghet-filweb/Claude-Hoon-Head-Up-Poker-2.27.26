::  /mar/poker-lobby-set-mint-host.hoon
::  Mark for the owner poke that sets the %slab-mint host ship.
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
