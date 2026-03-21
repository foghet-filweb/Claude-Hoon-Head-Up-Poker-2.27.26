::  /mar/poker-lobby-game-complete.hoon
::  Mark for the %poker-room → %poker-lobby game-complete notification.
::  Payload: [alice=@p bob=@p] — both participants in the completed hand.
|_  payload=[@p @p]
++  grab
  |%
  ++  noun  [@p @p]
  --
++  grow
  |%
  ++  noun  payload
  --
++  grad  %noun
--
