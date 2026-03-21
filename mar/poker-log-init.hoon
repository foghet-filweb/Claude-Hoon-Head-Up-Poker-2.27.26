::  /mar/poker-log-init.hoon
::  Mark for the %poker-room → %poker-log hand initialisation poke.
::  Payload: [room-id=@uv alice=@p bob=@p config=game-config:poker]
/-  poker
|%
+$  log-init  [room-id=@uv alice=@p bob=@p config=game-config:poker]
--
|_  l=log-init
++  grab
  |%
  ++  noun  log-init
  --
++  grow
  |%
  ++  noun  l
  --
++  grad  %noun
--
