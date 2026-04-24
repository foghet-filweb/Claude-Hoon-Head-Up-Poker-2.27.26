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
  ++  json
    ^-  ^json
    ?~  p  [%b %.n]
    =/  c  c.u.p
    ?.  ?=([%propose *] c)  [%b %.n]
    =/  mk
      |=  [k=@tas v=^json]
      ^-  ^json
      [%o (~(gas by *(map @t ^json)) ~[[k v]])]
    =/  ud
      |=  n=@ud  ^-  ^json
      [%n (crip (skim (trip (scot %ud n)) |=(c=@t !=(c '.'))))]
    =/  opt-ud
      |=  u=(unit @ud)  ^-  ^json
      ?~  u  [%n '0']
      (ud u.u)
    [%o (~(gas by *(map @t ^json)) ~[['challenger' `^json`[%s (scot %p challenger.u.p)]] ['small-blind' (ud small-blind.c)] ['big-blind' (ud big-blind.c)] ['hands' (opt-ud hands.c)] ['cap' (opt-ud cap.c)]])]
  --
++  grad  %noun
--
