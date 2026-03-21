::  /mar/poker-lobby-pending.hoon
::  Mark for the /x/pending-in scry result.
::  Payload: (unit [challenger=@p c=challenge:poker])
/-  poker
|%
+$  pending-in  (unit [challenger=@p c=challenge:poker])
--
|_  p=pending-in
++  grab
  |%
  ++  noun  pending-in
  --
++  grow
  |%
  ++  noun  p
  --
++  grad  %noun
--
