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
      |=  raw-idx=@ud
      ^-  ^json
      =/  rank-names  `(list cord)`~['2' '3' '4' '5' '6' '7' '8' '9' 'T' 'J' 'Q' 'K' 'A']
      =/  suit-names  `(list cord)`~['s' 'h' 'd' 'c']
      =/  idx  (mod raw-idx 52)
      =/  r=@ud  (div idx 4)
      =/  s=@ud  (mod idx 4)
      =/  rn=cord  (snag r rank-names)
      =/  sn=cord  (snag s suit-names)
      [%o (~(gas by *(map @t ^json)) ~[['rank' `^json`[%s rn]] ['suit' `^json`[%s sn]]])]
    =/  card-list
      |=  cards=(list @ud)
      ^-  ^json
      [%a (turn cards card-json)]
    =/  ud-json
      |=  n=@ud  ^-  ^json
      [%n (crip (skim (trip (scot %ud n)) |=(c=@t !=(c '.'))))]
    =/  action-json
      |=  a=action:poker
      ^-  ^json
      ?-  -.a
        %fold    %+  mk  %fold   `^json`[%b %.y]
        %check   %+  mk  %check  `^json`[%b %.y]
        %call    %+  mk  %call   `^json`[%b %.y]
        %all-in
          %+  mk  %all-in
          [%b %.y]
        %raise
          %+  mk  %raise
          %+  mk  %amount
          (ud-json amount.a)
      ==
    ?-  -.u
      %hand-dealt
        %+  mk  %poker-room-update
        %+  mk  %hand-dealt
        %+  mk  %cards
        (card-list hand.u)
      %your-turn
        %+  mk  %poker-room-update
        %+  mk  %your-turn
        [%o (~(gas by *(map @t ^json)) ~[['street' `^json`[%s (street-name street.u)]] ['pot' (ud-json pot.u)] ['to-call' (ud-json to-call.u)] ['min-raise' (ud-json min-raise.u)] ['small-blind' (ud-json small-blind.u)] ['big-blind' (ud-json big-blind.u)]])]
      %peer-acted
        =/  bs=^json
          [%o (~(gas by *(map @t ^json)) ~[['pot' (ud-json pot.u)] ['to-call' (ud-json to-call.u)] ['peer-bet' (ud-json peer-bet.u)]])]
        %+  mk  %poker-room-update
        %+  mk  %peer-acted
        [%o (~(gas by *(map @t ^json)) ~[['betting-state' bs] ['action' (action-json action.u)]])]
      %community-dealt
        %+  mk  %poker-room-update
        %+  mk  %community-dealt
        [%o (~(gas by *(map @t ^json)) ~[['street' `^json`[%s (street-name street.u)]] ['cards' (card-list cards.u)]])]
      %street-started
        %+  mk  %poker-room-update
        %+  mk  %street-started
        [%o (~(gas by *(map @t ^json)) ~[['street' `^json`[%s (street-name street.u)]] ['pot' (ud-json pot.u)] ['to-call' (ud-json to-call.u)] ['min-raise' (ud-json min-raise.u)]])]
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
      %fold-complete
        %+  mk  %poker-room-update
        %+  mk  %fold-complete
        [%o (~(gas by *(map @t ^json)) ~[['winner' `^json`[%s (scot %p winner.u)]] ['our-stack' (ud-json our-stack.u)] ['peer-stack' (ud-json peer-stack.u)]])]
      %key-revealed
        %+  mk  %poker-room-update
        %+  mk  %key-revealed
        [%s 'ok']
    ==
  --
++  grad  %noun
--
