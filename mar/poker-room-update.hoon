::  /mar/poker-room-update.hoon
::
::  Mark for %facts sent from %poker-room to the front-end on /game.
::  The ++grow +json arm serializes each update variant to JSON for Eyre SSE.
::
/-  poker
|_  u=room-update:poker
++  grab
  |%
  ++  noun  room-update:poker
  --
++  grow
  |%
  ++  noun  u
  ++  json
    ^-  ^json
    =/  mk
      |=  [k=@tas v=^json]
      ^-  ^json
      [%o (~(gas by *(map @t ^json)) ~[[k v]])]
    =/  jmap
      |=  [k=@tas v=^json]
      ^-  (map @t ^json)
      (~(gas by *(map @t ^json)) ~[[k v]])
    %+  mk  %poker-room-update
    ?-  -.u
      %hand-dealt
        (mk %hand-dealt (mk %cards (card-list hand.u)))
      %your-turn
        (mk %your-turn
          [%o (~(uni by (jmap %street    [%s (street-name street.u)]))
               (~(uni by (jmap %actor    [%s ?:(=(actor.street-status.u %alice) 'alice' 'bob')]))
               (~(uni by (jmap %pot      [%n (scot %ud pot.u)]))
               (~(uni by (jmap %to-call  [%n (scot %ud to-call.u)]))
               (jmap %min-raise          [%n (scot %ud min-raise.u)])))))])
      %peer-acted
        (mk %peer-acted
          [%o (~(uni by (jmap %action (action-json action.u)))
               (jmap %betting-state
                 [%o (~(uni by (jmap %street   [%s (street-name street.u)]))
                      (~(uni by (jmap %pot      [%n (scot %ud pot.u)]))
                      (~(uni by (jmap %to-call  [%n (scot %ud to-call.u)]))
                      (jmap %peer-bet           [%n (scot %ud peer-bet.u)]))))]))])
      %community-dealt
        (mk %community-dealt
          [%o (~(uni by (jmap %street [%s (street-name street.u)]))
               (jmap %cards (card-list cards.u)))])
      %street-started
        (mk %street-started
          [%o (~(uni by (jmap %street [%s (street-name street.u)]))
               (~(uni by (jmap %actor [%s ?:(=(actor.street-status.u %alice) 'alice' 'bob')]))
               (jmap %betting-state
                 [%o (~(uni by (jmap %pot      [%n (scot %ud pot.u)]))
                      (~(uni by (jmap %to-call  [%n (scot %ud to-call.u)]))
                      (jmap %min-raise          [%n (scot %ud min-raise.u)])))])))])
      %player-folded
        (mk %player-folded [%s (scot %p ship.u)])
      %hand-complete
        (mk %hand-complete (mk %outcome [%s (scot %tas outcome.u)]))
      %game-audited
        (mk %game-audited [%b %.y])
      %session-over
        (mk %session-over
          [%o (~(uni by (jmap %reason        [%s ?:(=(reason.u %hands-limit) 'hands-limit' 'cap-limit')]))
               (~(uni by (jmap %hands-played  [%n (scot %ud hands-played.u)]))
               (jmap %total-wagered           [%n (scot %ud total-wagered.u)])))])
      %timeout-forfeit
        (mk %timeout-forfeit [%s (scot %p winner.u)])
    ==
  --
++  grad  %noun
--
::  ── helpers ─────────────────────────────────────────────────────
++  card-json
  |=  idx=@ud
  ^-  ^json
  =/  rank-names  `(list cord)`~['2' '3' '4' '5' '6' '7' '8' '9' 'T' 'J' 'Q' 'K' 'A']
  =/  suit-names  `(list cord)`~['s' 'h' 'd' 'c']
  =/  r=@ud  (div idx 4)
  =/  s=@ud  (mod idx 4)
  =/  jmap
    |=  [k=@tas v=^json]
    ^-  (map @t ^json)
    (~(gas by *(map @t ^json)) ~[[k v]])
  [%o (~(uni by (jmap %rank [%s (snag r rank-names)])) (jmap %suit [%s (snag s suit-names)]))]
++  card-list
  |=  cards=(list @ud)
  ^-  ^json
  [%a (turn cards card-json)]
++  street-name
  |=  st=street:poker
  ^-  cord
  ?-  st
    %preflop   'pre-flop'
    %flop      'flop'
    %turn      'turn'
    %river     'river'
    %showdown  'showdown'
  ==
++  action-json
  |=  a=action:poker
  ^-  ^json
  =/  mk
    |=  [k=@tas v=^json]
    ^-  ^json
    [%o (~(gas by *(map @t ^json)) ~[[k v]])]
  ?-  -.a
    %fold   (mk %fold   [%b %.y])
    %check  (mk %check  [%b %.y])
    %call   (mk %call   [%b %.y])
    %raise  (mk %raise  (mk %amount [%n (scot %ud amount.a)]))
    %all-in (mk %all-in [%b %.y])
  ==
++  street-state-json
  |=  [st=street:poker ss=street-status:poker]
  ^-  ^json
  =/  jmap
    |=  [k=@tas v=^json]
    ^-  (map @t ^json)
    (~(gas by *(map @t ^json)) ~[[k v]])
  [%o (~(uni by (jmap %street [%s (street-name st)])) (jmap %actor [%s ?:(=(actor.ss %alice) 'alice' 'bob')]))]
