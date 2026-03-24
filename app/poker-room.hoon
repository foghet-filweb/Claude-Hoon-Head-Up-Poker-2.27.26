::  /app/poker-room.hoon
/-  poker
/+  default-agent, poker-sra
|%
+$  role    ?(%alice %bob)
+$  card    card:agent:gall
+$  state-0
  $:  %0
      =room-state:poker
      role=role
  ==
--
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
++  on-init   `this
++  on-save   !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =.  state  !<(state-0 old)
  `this
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
    %poker-room-init
      =/  init  !<([room-id=@uv peer=@p config=game-config:poker challenger=@p] vase)
      =/  my-role  ?:(=(our.bowl challenger.init) %alice %bob)
      =/  our-seed=entropy:poker
        %+  mix  eny.bowl
        (mix (sham [our.bowl now.bowl]) (sham now.bowl))
      =/  our-key  (gen-sra-key:poker-sra [sra-prime:poker-sra our-seed])
      =/  new-state=room-state:poker
        :*  room-id=room-id.init
            peer=peer.init
            config=config.init
            method=[%mental-poker sra-prime:poker-sra]
            phase=[%awaiting-seeds `our-seed ~]
            our-stack=1.000
            peer-stack=1.000
            pot=0
            our-bet=0
            peer-bet=0
            our-key=`our-key
            our-hand=~
            community=~
            pending-community=~
            dbl-enc-deck=~
            our-positions=~
            timeout-wire=/timeout/(scot %uv room-id.init)
            deck-commit=`@ux`0
            hands-played=0
            total-wagered=0
        ==
      =.  state  [%0 new-state my-role]
      :_  this
      :~  [%pass /peer %agent [peer.new-state %poker-room] %poke %poker-deal-action !>([%mp-partial-dec ~])]
          [%pass timeout-wire.new-state %arvo %b %wait (add now.bowl ~m1)]
      ==
    %poker-deal-action
      =/  action  !<(deal-action:poker vase)
      ~|  'poker-room: poke from unknown ship'
      ?>  =(src.bowl peer.room-state.state)
      =/  peer  peer.room-state.state
      =/  twire  timeout-wire.room-state.state
      ?+  -.action  `this
        %mp-enc-deck
          ~|  'mp-enc-deck: wrong phase'
          =/  rs0  room-state.state
          ?>  ?=([%alice-encrypting ~] phase.rs0)
          =/  actual-commit  (commit-deck:poker-sra deck.action room-id.rs0)
          ~|  'mp-enc-deck: commitment mismatch'
          ?>  =(commit.action actual-commit)
          =/  our-key  (need our-key.rs0)
          =/  reenc-deck  (reencrypt-deck:poker-sra deck.action our-key)
          =/  new-phase
            :*  %dealing
                dbl-enc-deck=reenc-deck
                alice-positions=~[0 1]
                bob-positions=~[2 3]
                community-positions=~[4 5 6 7 8]
            ==
          =/  our-pos  bob-positions.new-phase
          =/  our-partial  (partial-decrypt-positions:poker-sra reenc-deck our-pos our-key)
          =.  state  [%0 rs0(phase new-phase) role.state]
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-reenc-deck reenc-deck])]
              [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-partial-dec our-partial])]
              [%pass twire %arvo %b %rest (add now.bowl ~m1)]
              [%pass twire %arvo %b %wait (add now.bowl ~m1)]
          ==
        %mp-reenc-deck
          ~|  'mp-reenc-deck: wrong phase'
          =/  rs0  room-state.state
          ?>  ?=([%bob-reencrypting *] phase.rs0)
          ~|  'mp-reenc-deck: wrong deck length'
          ?>  =(52 (lent deck.action))
          =/  our-key  (need our-key.rs0)
          =/  new-phase
            :*  %dealing
                dbl-enc-deck=deck.action
                alice-positions=~[0 1]
                bob-positions=~[2 3]
                community-positions=~[4 5 6 7 8]
            ==
          =/  bob-partial  (partial-decrypt-positions:poker-sra deck.action ~[2 3] our-key)
          =.  state  [%0 rs0(phase new-phase) role.state]
          :_  this
          ~[[%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-partial-dec bob-partial])]]
        %mp-partial-dec
          ~|  'mp-partial-dec: wrong phase'
          =/  rs0  room-state.state
          ?>  ?=([%dealing *] phase.rs0)
          =/  our-key  (need our-key.rs0)
          =/  incoming-positions  (turn cards.action |=(p=partial-dec:poker idx.p))
          =/  our-pos
            ?:  =(role.state %alice)
              alice-positions.phase.rs0
            bob-positions.phase.rs0
          =/  is-our-cards
            %+  levy  incoming-positions
            |=  n=@ud
            (lien our-pos |=(h=@ud =(h n)))
          ?.  is-our-cards  `this
          =/  decrypted
            %+  turn  cards.action
            |=  pd=partial-dec:poker
            (sra-decrypt:poker-sra val.pd our-key)
          =/  rs1  rs0(our-hand decrypted)
          ?.  =(2 (lent decrypted))  `this
          =.  state  [%0 rs1(phase [%live %preflop *street-status:poker]) role.state]
          :_  this
          :~  [%give %fact ~[/game] %poker-room-update !>([%hand-dealt our.bowl decrypted])]
              [%pass twire %arvo %b %rest (add now.bowl ~m1)]
          ==
        %mp-reveal-key
          ~>  %slog.[0 leaf+"poker-room: key reveal received from peer"]
          :_  this
          :~  [%give %fact ~[/game] %poker-room-update !>([%key-revealed peer])]
          ==
        %abort
          :_  this
          :~  [%give %fact ~[/game] %poker-room-update !>([%timeout-forfeit peer])]
              [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%abort 'timeout'])]
              [%give %kick ~[/game] ~]
          ==
        %timeout
          :_  this
          :~  [%give %fact ~[/game] %poker-room-update !>([%timeout-forfeit peer])]
              [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%abort 'timeout'])]
              [%give %kick ~[/game] ~]
          ==
      ==
    %poker-game-action
      =/  action  !<(action:poker vase)
      ~|  'poker-room: game action from wrong ship'
      ?>  =(src.bowl our.bowl)
      ~|  'handle-game-action: not in live phase'
      =/  rs0  room-state.state
      =/  ph  phase.rs0
      ?>  ?=([%live *] ph)
      =/  peer  peer.rs0
      ?+  -.action  `this
        %fold
          =/  new-peer-stack  (add peer-stack.rs0 pot.rs0)
          =/  rs1  rs0(peer-stack new-peer-stack, pot 0, phase [%awaiting-audit peer])
          =.  state  [%0 rs1 role.state]
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-game-action !>([%fold ~])]
              [%give %fact ~[/game] %poker-room-update !>([%player-folded our.bowl])]
              [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-reveal-key d:(need our-key.rs0) `@ux`0])]
          ==
        %check
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-game-action !>([%check ~])]
              [%give %fact ~[/game] %poker-room-update !>([%player-checked our.bowl])]
          ==
        %call
          =/  to-call  (sub peer-bet.room-state.state our-bet.room-state.state)
          ~|  'do-call: insufficient stack'
          ?>  (gte our-stack.room-state.state to-call)
          =.  our-stack.room-state.state  (sub our-stack.room-state.state to-call)
          =.  our-bet.room-state.state    (add our-bet.room-state.state to-call)
          =.  pot.room-state.state        (add pot.room-state.state to-call)
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-game-action !>([%call ~])]
              [%give %fact ~[/game] %poker-room-update !>([%player-called our.bowl to-call])]
          ==
        %raise
          =/  amount  amount.action
          ~|  'do-raise: insufficient stack'
          ?>  (gte our-stack.room-state.state amount)
          =.  our-stack.room-state.state  (sub our-stack.room-state.state amount)
          =.  our-bet.room-state.state    (add our-bet.room-state.state amount)
          =.  pot.room-state.state        (add pot.room-state.state amount)
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-game-action !>([%raise amount])]
              [%give %fact ~[/game] %poker-room-update !>([%player-raised our.bowl amount])]
          ==
      ==
  ==
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  -.sign  (on-agent:def wire sign)
    %poke-ack
      ?~  p.sign
        `this
      %-  (slog leaf+"poker-room: poke nack on wire {<wire>}" u.p.sign)
      `this
  ==
++  on-arvo
  |=  [=wire s=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire s)
    [%timeout @ ~]
      ?.  ?=([%b %wake *] s)  (on-arvo:def wire s)
      =/  peer  peer.room-state.state
      =.  phase.room-state.state  [%abandoned ~]
      :_  this
      :~  [%give %fact ~[/game] %poker-room-update !>([%timeout-forfeit peer])]
          [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%abort 'timeout'])]
          [%give %kick ~[/game] ~]
      ==
  ==
++  on-watch  |=(=path `this)
++  on-leave  |=(=path `this)
++  on-peek   |=(=path ~)
++  on-fail   on-fail:def
--
