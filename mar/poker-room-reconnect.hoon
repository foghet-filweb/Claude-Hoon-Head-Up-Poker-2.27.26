::  /mar/poker-room-reconnect.hoon
::  Mark for the reconnect poke a restarted peer sends to %poker-room.
::  Payload: ~ (signal only; current state is sent back as ack)
|_  n=~
++  grab
  |%
  ++  noun  $~
  --
++  grow
  |%
  ++  noun  n
  --
++  grad  %noun
--
