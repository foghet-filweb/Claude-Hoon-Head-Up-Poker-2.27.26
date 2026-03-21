::  /mar/poker-settle-confirm.hoon
::  Mark for the UI poke confirming a payment was made out-of-band.
::  Payload: @uv (room-id)
|_  room-id=@uv
++  grab
  |%
  ++  noun  @uv
  --
++  grow
  |%
  ++  noun  room-id
  --
++  grad  %noun
--
