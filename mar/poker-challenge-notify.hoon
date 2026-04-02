::  /mar/poker-challenge-notify.hoon
::
::  Mark for front-end challenge notification facts on /challenges path.
::
::  JSON shapes:
::    incoming:  { "poker-challenge-notify": { "incoming": { "challenger": "~ship", "challenge": { "small-blind": N, "big-blind": N, "min-raise": N, "hands": N|null, "cap": N|null } } } }
::    accepted:  { "poker-challenge-notify": { "accepted": { "target": "~ship", "room-id": "0x..." } } }
::    declined:  { "poker-challenge-notify": { "declined": { "target": "~ship" } } }
::    busy:      { "poker-challenge-notify": { "busy":     { "target": "~ship" } } }
::    timeout:   { "poker-challenge-notify": { "timeout":  { "target": "~ship" } } }
::
/-  poker
/+  format
|%
+$  challenge-notify
  $%  [%incoming challenger=@p c=challenge:poker]
      [%accepted target=@p room-id=@uv]
      [%declined target=@p]
      [%busy target=@p]
      [%timeout target=@p]
  ==
--
|_  n=challenge-notify
++  grab
  |%
  ++  noun  challenge-notify
  --
++  grow
  |%
  ++  noun  n
  --
++  grad  %noun
--
