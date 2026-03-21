::  /mar/poker-room-init.hoon
::  Mark for the %poker-lobby → %poker-room initialisation poke.
::  Payload: [room-id=@uv peer=@p config=game-config:poker challenger=@p]
/-  poker
|%
+$  room-init  [room-id=@uv peer=@p config=game-config:poker challenger=@p]
--
|_  r=room-init
++  grab
  |%
  ++  noun  room-init
  --
++  grow
  |%
  ++  noun  r
  --
++  grad  %noun
--
