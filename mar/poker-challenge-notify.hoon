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
  ++  json
    ^-  ^json
    =/  mk
      |=  [k=@tas v=^json]
      ^-  ^json
      [%o (~(gas by *(map @t ^json)) ~[[k v]])]
    =/  inner=^json
      ?-  -.n
        %incoming
          =/  c  c.n
          %+  mk  %incoming
          :-  %o
          %-  malt
          :~  ['challenger'  [%s (scot %p challenger.n)]]
              ['challenge'
                :-  %o
                %-  malt
                :~  ['small-blind'  [%n (scot %ud small-blind.c)]]
                    ['big-blind'    [%n (scot %ud big-blind.c)]]
                    ['min-raise'    [%n (scot %ud min-raise.c)]]
                    ['buy-in'       [%n (scot %ud buy-in.c)]]
                    ['hands'
                      ?~  hands.c  [%~ ~]
                      [%n (scot %ud u.hands.c)]]
                    ['cap'
                      ?~  cap.c  [%~ ~]
                      [%n (scot %ud u.cap.c)]]
                ==
              ]
          ==
        %accepted
          %+  mk  %accepted
          :-  %o
          %-  malt
          :~  ['target'   [%s (scot %p target.n)]]
              ['room-id'  [%s (scot %uv room-id.n)]]
          ==
        %declined
          %+  mk  %declined
          [%o (~(gas by *(map @t ^json)) ~[['target' [%s (scot %p target.n)]]])]
        %busy
          %+  mk  %busy
          [%o (~(gas by *(map @t ^json)) ~[['target' [%s (scot %p target.n)]]])]
        %timeout
          %+  mk  %timeout
          [%o (~(gas by *(map @t ^json)) ~[['target' [%s (scot %p target.n)]]])]
      ==
    (mk %poker-challenge-notify inner)
  --
++  grad  %noun
--
