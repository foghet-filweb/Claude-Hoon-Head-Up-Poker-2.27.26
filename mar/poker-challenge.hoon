::  /mar/poker-challenge.hoon
::
::  Mark for ship-to-ship challenge pokes.
::  Also used when front-end sends accept/decline back through lobby.
::
::  JSON shapes:
::    Accept:  { "poker-challenge": { "accept": { "room-id": "0x1234" } } }
::    Decline: { "poker-challenge": { "decline": {} } }
::    Busy:    { "poker-challenge": { "busy": {} } }
::
/-  poker
/+  format
|_  c=challenge:poker
++  grab
  |%
  ++  noun  challenge:poker
  --
++  grow
  |%
  ++  noun  c
  --
++  grad  %noun
--
