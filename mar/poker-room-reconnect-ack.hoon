::  /mar/poker-room-reconnect-ack.hoon
::  Mark for the reconnect acknowledgement poke carrying the sender's room-state.
::  Payload: room-state:poker
/-  poker
|_  rs=room-state:poker
++  grab
  |%
  ++  noun  room-state:poker
  --
++  grow
  |%
  ++  noun  rs
  --
++  grad  %noun
--
