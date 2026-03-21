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
    =/  wrap  |=(inner=^json (pairs:enjs:format ~[['poker-challenge-notify' inner]]))
    %+  wrap
    ?-  -.n
      %incoming
        %-  pairs:enjs:format
        :~  :-  'incoming'
            %-  pairs:enjs:format
            :~  ['challenger' s+(scot %p challenger.n)]
                :-  'challenge'
                ?-  -.c.n
                  %propose
                    %-  pairs:enjs:format
                    :~  ['small-blind' (numb:enjs:format small-blind.c.n)]
                        ['big-blind'   (numb:enjs:format big-blind.c.n)]
                        ['min-raise'   (numb:enjs:format min-raise.c.n)]
                        :-  'hands'
                        ?~  hands.c.n  ~[%n '0']
                        (numb:enjs:format u.hands.c.n)
                        :-  'cap'
                        ?~  cap.c.n  ~[%n '0']
                        (numb:enjs:format u.cap.c.n)
                    ==
                  %accept   (pairs:enjs:format ~[['room-id' s+(scot %uv room-id.c.n)]])
                  %decline  (pairs:enjs:format ~[['declined' b+&]])
                  %busy     (pairs:enjs:format ~[['busy' b+&]])
                ==
            ==
        ==
      %accepted
        %-  pairs:enjs:format
        :~  :-  'accepted'
            %-  pairs:enjs:format
            :~  ['target'  s+(scot %p target.n)]
                ['room-id' s+(scot %uv room-id.n)]
            ==
        ==
      %declined
        (pairs:enjs:format ~[['declined' (pairs:enjs:format ~[['target' s+(scot %p target.n)]])]])
      %busy
        (pairs:enjs:format ~[['busy' (pairs:enjs:format ~[['target' s+(scot %p target.n)]])]])
      %timeout
        (pairs:enjs:format ~[['timeout' (pairs:enjs:format ~[['target' s+(scot %p target.n)]])]])
    ==
  --
++  grad  %noun
--
