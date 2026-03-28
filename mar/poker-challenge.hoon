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
  ++  json
    |=  j=^json
    ^-  challenge:poker
    =/  inner  ((ot ~[poker-challenge+jo]) j)
    ?:  (~(has by inner) 'accept')
      =/  a    (~(got by inner) 'accept')
      =/  rid  ((ot ~[room-id+so]) a)
      [%accept (slav %uv rid)]
    ?:  (~(has by inner) 'decline')
      [%decline ~]
    ?:  (~(has by inner) 'busy')
      [%busy ~]
    ~|('poker-challenge: unrecognised json shape' !!)
  --
++  grow
  |%
  ++  noun  c
  ++  json
    ^-  ^json
    ?-  -.c
      %propose
        =/  game-name=@t  `@t`game.c
        %-  pairs:enjs:format
        :~  ['game'        s+game-name]
            ['small-blind' (numb:enjs:format small-blind.c)]
            ['big-blind'   (numb:enjs:format big-blind.c)]
            ['min-raise'   (numb:enjs:format min-raise.c)]
            ['hands'  ?~(hands.c [%n '0'] (numb:enjs:format u.hands.c))]
            ['cap'    ?~(cap.c   [%n '0'] (numb:enjs:format u.cap.c))]
            ['expires' (numb:enjs:format (unm:chrono:userlib expires.c))]
        ==
      %accept
        %-  pairs:enjs:format
        ~[['room-id' s+(scot %uv room-id.c)]]
      %decline  (pairs:enjs:format ~[['declined' b+&]])
      %busy     (pairs:enjs:format ~[['busy' b+&]])
    ==
  --
++  grad  %noun
--
