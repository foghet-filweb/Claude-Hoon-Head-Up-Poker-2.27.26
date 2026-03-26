::  /app/poker-room.hoon
/-  poker
/+  default-agent, dbug, poker-sra
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
%-  agent:dbug
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
            phase=?:(=(my-role %alice) [%awaiting-seeds `our-seed ~] [%awaiting-seeds ~ `our-seed])
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
      :~  [%pass /peer %agent [peer.new-state %poker-room] %poke %poker-deal-action !>([%mp-seed seed=our-seed])]
          [%pass timeout-wire.new-state %arvo %b %wait (add now.bowl ~m1)]
      ==
    %poker-deal-action
      =/  action  !<(deal-action:poker vase)
      ?.  |(?=(%mp-seed -.action) =(src.bowl peer.room-state.state))
        `this
      =/  peer  peer.room-state.state
      =/  twire  timeout-wire.room-state.state
      ?+  -.action  `this
        %mp-seed
          =/  rs0  room-state.state
          ::  drop silently if not awaiting seeds (late or duplicate delivery)
          ?.  ?=([%awaiting-seeds *] phase.rs0)
            `this
          ::  store peer's seed in the slot we don't own
          =/  ph1
            ?:  =(role.state %alice)
              phase.rs0(bob-seed `seed.action)
            phase.rs0(alice-seed `seed.action)
          ::  extract own seed before ?~ guards narrow ph1's type
          =/  my-seed=@uv  ?:(=(role.state %alice) (need alice-seed.ph1) (need bob-seed.ph1))
          =/  peer-seed=@uv  seed.action
          ::  defensive: if our own slot is somehow empty, persist and wait
          ?~  alice-seed.ph1
            `this(room-state.state rs0(phase ph1))
          ?~  bob-seed.ph1
            `this(room-state.state rs0(phase ph1))
          ::  both seeds present — combine and advance
          =/  combined  (mix my-seed peer-seed)
          ?:  =(role.state %alice)
            ::  alice: shuffle plaintext deck, encrypt, commit, send to bob
            ::  re-send alice's own seed first so bob can combine if he missed it
            =/  our-key  (need our-key.rs0)
            =/  pairs
              %+  turn  (gulf 0 51)
              |=  n=@ud
              [(shax (mix combined n)) n]
            =/  plain-deck
              ^-  enc-deck:poker
              %+  turn
                (sort pairs |=([a=[@ @] b=[@ @]] (lth -.a -.b)))
              |=([k=@ v=@ud] `enc-card:poker``@ux`v)
            =/  enc  (reencrypt-deck:poker-sra plain-deck our-key)
            =/  com  (commit-deck:poker-sra enc room-id.rs0)
            :_  this(room-state.state rs0(phase [%bob-reencrypting enc-deck=enc alice-commit=com]))
            :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-seed seed=my-seed])]
                [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-enc-deck enc com])]
                [%pass twire %arvo %b %rest (add now.bowl ~m1)]
                [%pass twire %arvo %b %wait (add now.bowl ~m1)]
            ==
          ::  bob: advance to waiting-for-alice, re-send bob's own seed so alice can combine
          :_  this(room-state.state rs0(phase [%alice-encrypting ~]))
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-seed seed=my-seed])]
              [%pass twire %arvo %b %rest (add now.bowl ~m1)]
              [%pass twire %arvo %b %wait (add now.bowl ~m1)]
          ==
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
          =/  alice-partial  (partial-decrypt-positions:poker-sra reenc-deck alice-positions.new-phase our-key)
          =.  state  [%0 rs0(phase new-phase) role.state]
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-reenc-deck reenc-deck])]
              [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-partial-dec alice-partial])]
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
          ::  post blinds — alice=SB, bob=BB
          =/  cfg  config.rs1
          =/  sb=@ud  small-blind.cfg
          =/  bb=@ud  big-blind.cfg
          =/  rs2=room-state:poker
            ?:  =(role.state %alice)
              rs1(our-stack (sub our-stack.rs1 sb), our-bet sb, peer-stack (sub peer-stack.rs1 bb), peer-bet bb, pot (add sb bb))
            rs1(our-stack (sub our-stack.rs1 bb), our-bet bb, peer-stack (sub peer-stack.rs1 sb), peer-bet sb, pot (add sb bb))
          =/  ss=street-status:poker
            [%alice `%bob %.n %.n %.n]
          =.  state  [%0 rs2(phase [%live %preflop ss]) role.state]
          =/  to-call=@ud  (sub bb sb)
          :_  this
          ?:  =(role.state %alice)
            :~  [%give %fact ~[/game] %poker-room-update !>([%hand-dealt our.bowl decrypted])]
                [%give %fact ~[/game] %poker-room-update !>([%your-turn %preflop ss pot.rs2 to-call min-raise.cfg])]
                [%pass twire %arvo %b %rest (add now.bowl ~m1)]
            ==
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
++  on-arvo  on-arvo:def
++  on-watch  |=(=path `this)
++  on-leave  |=(=path `this)
++  on-peek   |=(=path ~)
++  on-fail   on-fail:def
--
