::  /mar/poker-room-update.hoon
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
    =/  street-name
      |=  st=street:poker
      ^-  cord
      ?-  st
        %preflop   'pre-flop'
        %flop      'flop'
        %turn      'turn'
        %river     'river'
        %showdown  'showdown'
      ==
    =/  card-json
      |=  idx=@ud
      ^-  ^json
      =/  rank-names  `(list cord)`~['2' '3' '4' '5' '6' '7' '8' '9' 'T' 'J' 'Q' 'K' 'A']
      =/  r=@ud  (div idx 4)
      %+  mk  %rank
      [%s (snag r rank-names)]
    =/  card-list
      |=  cards=(list @ud)
      ^-  ^json
      [%a (turn cards card-json)]
    =/  action-json
      |=  a=action:poker
      ^-  ^json
      ?-  -.a
        %fold
          %+  mk  %fold
          [%b %.y]
        %check
          %+  mk  %check
          [%b %.y]
        %call
          %+  mk  %call
          [%b %.y]
        %raise
          %+  mk  %raise
          %+  mk  %amount
          [%n (scot %ud amount.a)]
        %all-in
          %+  mk  %all-in
          [%b %.y]
      ==
    ?-  -.u
      %hand-dealt
        %+  mk  %poker-room-update
        %+  mk  %hand-dealt
        [%s 'ok']
      %your-turn
        %+  mk  %poker-room-update
        %+  mk  %your-turn
        [%s (street-name street.u)]
      %peer-acted
        %+  mk  %poker-room-update
        %+  mk  %peer-acted
        [%s 'ok']
      %community-dealt
        %+  mk  %poker-room-update
        %+  mk  %community-dealt
        [%s (street-name street.u)]
      %street-started
        %+  mk  %poker-room-update
        %+  mk  %street-started
        [%s (street-name street.u)]
      %player-folded
        %+  mk  %poker-room-update
        %+  mk  %player-folded
        [%s (scot %p ship.u)]
      %hand-complete
        %+  mk  %poker-room-update
        %+  mk  %hand-complete
        [%s 'complete']
      %game-audited
        %+  mk  %poker-room-update
        %+  mk  %game-audited
        [%b %.y]
      %session-over
        %+  mk  %poker-room-update
        %+  mk  %session-over
        [%s 'over']
      %timeout-forfeit
        %+  mk  %poker-room-update
        %+  mk  %timeout-forfeit
        [%s (scot %p winner.u)]
      %key-revealed
        %+  mk  %poker-room-update
        %+  mk  %key-revealed
        [%s 'ok']
    ==
  --
++  grad  %noun
--
