::  /mar/poker-game-action.hoon
::
::  Mark for front-end betting action pokes to %poker-room.
::  Only accepted from our own ship (enforced in poker-room.hoon).
::
::  JSON shapes (from front-end):
::    { "poker-game-action": { "fold": null } }
::    { "poker-game-action": { "check": null } }
::    { "poker-game-action": { "call": null } }
::    { "poker-game-action": { "raise": { "amount": 360 } } }
::
/-  poker
/+  format
|_  a=action:poker
++  grab
  |%
  ++  noun  action:poker
  --
++  grow
  |%
  ++  noun  a
  --
++  grad  %noun
--
