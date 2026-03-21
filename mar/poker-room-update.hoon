::  /mar/poker-room-update.hoon
::
::  Mark for %facts sent from %poker-room to the front-end on /game.
::  The ++grow +json arm serializes each update variant to JSON for Eyre SSE.
::
::  JSON shapes sent to front-end:
::    hand-dealt:      { "poker-room-update": { "hand-dealt":      { "cards": [...] } } }
::    your-turn:       { "poker-room-update": { "your-turn":       { "street": "...", "actor": "alice"|"bob", "pot": N, "to-call": N, "min-raise": N } } }
::    peer-acted:      { "poker-room-update": { "peer-acted":      { "action": {...}, "betting-state": { "street": "...", "pot": N, "to-call": N, "peer-bet": N } } } }
::    community-dealt: { "poker-room-update": { "community-dealt": { "street": "...", "cards": [...] } } }
::    street-started:  { "poker-room-update": { "street-started":  { "street": "...", "actor": "alice"|"bob", "betting-state": { "pot": N, "to-call": N, "min-raise": N } } } }
::    player-folded:   { "poker-room-update": { "player-folded":   "~ship" } }
::    hand-complete:   { "poker-room-update": { "hand-complete":   { "outcome": "..." } } }
::    game-audited:    { "poker-room-update": { "game-audited":    true } }
::    timeout-forfeit: { "poker-room-update": { "timeout-forfeit": "~ship" } }
::    session-over:    { "poker-room-update": { "session-over":    { "reason": "...", "hands-played": N, "total-wagered": N } } }
::
/-  poker
/+  format
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
    =/  wrap  |=(inner=^json (pairs:enjs:format ~[['poker-room-update' inner]]))
    %+  wrap
    ?-  -.u
      %hand-dealt
        %-  pairs:enjs:format
        ~[['hand-dealt' (pairs:enjs:format ~[['cards' (card-list hand.u)]])]]
      %your-turn
        %-  pairs:enjs:format
        :~  :-  'your-turn'
            %-  pairs:enjs:format
            :~  ['street'    s+(street-name street.u)]
                ['actor'     s+?:(=(actor.street-status.u %alice) 'alice' 'bob')]
                ['pot'       (numb:enjs:format pot.u)]
                ['to-call'   (numb:enjs:format to-call.u)]
                ['min-raise' (numb:enjs:format min-raise.u)]
            ==
        ==
      %peer-acted
        %-  pairs:enjs:format
        :~  :-  'peer-acted'
            %-  pairs:enjs:format
            :~  ['action'   (action-json action.u)]
                :-  'betting-state'
                %-  pairs:enjs:format
                :~  ['street'   s+(street-name street.u)]
                    ['pot'      (numb:enjs:format pot.u)]
                    ['to-call'  (numb:enjs:format to-call.u)]
                    ['peer-bet' (numb:enjs:format peer-bet.u)]
                ==
            ==
        ==
      %community-dealt
        %-  pairs:enjs:format
        :~  :-  'community-dealt'
            %-  pairs:enjs:format
            :~  ['street' s+(street-name street.u)]
                ['cards'  (card-list cards.u)]
            ==
        ==
      %street-started
        %-  pairs:enjs:format
        :~  :-  'street-started'
            %-  pairs:enjs:format
            :~  ['street'    s+(street-name street.u)]
                ['actor'     s+?:(=(actor.street-status.u %alice) 'alice' 'bob')]
                :-  'betting-state'
                %-  pairs:enjs:format
                :~  ['pot'      (numb:enjs:format pot.u)]
                    ['to-call'  (numb:enjs:format to-call.u)]
                    ['min-raise' (numb:enjs:format min-raise.u)]
                ==
            ==
        ==
      %player-folded
        %-  pairs:enjs:format
        ~[['player-folded' s+(scot %p ship.u)]]
      %hand-complete
        %-  pairs:enjs:format
        :~  :-  'hand-complete'
            %-  pairs:enjs:format
            ~[['outcome' s+(~(scot %tas outcome.u))]]
        ==
      %game-audited
        %-  pairs:enjs:format
        ~[['game-audited' b+&]]
      %session-over
        %-  pairs:enjs:format
        :~  :-  'session-over'
            %-  pairs:enjs:format
            :~  ['reason'        s+?:(=(reason.u %hands-limit) 'hands-limit' 'cap-limit')]
                ['hands-played'  (numb:enjs:format hands-played.u)]
                ['total-wagered' (numb:enjs:format total-wagered.u)]
            ==
        ==
      %timeout-forfeit
        %-  pairs:enjs:format
        ~[['timeout-forfeit' s+(scot %p winner.u)]]
    ==
  --
++  grad  %noun
--
::  ── helpers ─────────────────────────────────────────────────────
::  Card index → {rank, suit} JSON object
::  Cards encoded as 0-51:
::    rank = idx / 4  (0=2, 1=3 … 8=T, 9=J, 10=Q, 11=K, 12=A)
::    suit = idx % 4  (0=s, 1=h, 2=d, 3=c)
++  card-json
  |=  idx=@ud
  ^-  ^json
  =/  rank-names  `(list cord)`~['2' '3' '4' '5' '6' '7' '8' '9' 'T' 'J' 'Q' 'K' 'A']
  =/  suit-names  `(list cord)`~['s' 'h' 'd' 'c']
  =/  r=@ud  (div idx 4)
  =/  s=@ud  (mod idx 4)
  %-  pairs:enjs:format
  :~  ['rank' s+(snag r rank-names)]
      ['suit' s+(snag s suit-names)]
  ==
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
  ?-  -.a
    %fold   (pairs:enjs:format ~[['fold'  b+&]])
    %check  (pairs:enjs:format ~[['check' b+&]])
    %call   (pairs:enjs:format ~[['call'  b+&]])
    %raise  (pairs:enjs:format ~[['raise' (pairs:enjs:format ~[['amount' (numb:enjs:format amount.a)]])]])
    %all-in (pairs:enjs:format ~[['all-in' b+&]])
  ==
++  street-state-json
  |=  [st=street:poker ss=street-status:poker]
  ^-  ^json
  %-  pairs:enjs:format
  :~  ['street' s+(street-name st)]
      ['actor'  s+?:(=(actor.ss %alice) 'alice' 'bob')]
  ==
