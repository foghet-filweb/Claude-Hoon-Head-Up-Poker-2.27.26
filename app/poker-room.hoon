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
++  advance-street
  ::  Compute our partial decrypts of the next street's community positions,
  ::  send %mp-community to peer, and transition phase to %revealing.
  |=  [rs=room-state:poker cur=street:poker]
  ^-  (quip card room-state:poker)
  =/  next-str=street:poker
    ?-  cur
      %preflop   %flop
      %flop      %turn
      %turn      %river
      %river     %showdown
      %showdown  !!
    ==
  =/  positions=(list @ud)
    ?-  next-str
      %flop      ~[4 5 6]
      %turn      ~[7]
      %river     ~[8]
      %preflop   ~
      %showdown  ~
    ==
  =/  our-key  (need our-key.rs)
  =/  partials  (partial-decrypt-positions:poker-sra dbl-enc-deck.rs positions our-key)
  =/  rs1  rs(phase [%revealing next-str positions])
  :_  rs1
  :~  [%pass /peer %agent [peer.rs %poker-room] %poke %poker-deal-action !>([%mp-community next-str partials])]
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
      =/  new-dealer=@p
        ?:  =(0 hands-played.room-state.state)
          challenger.init
        ?:(=(our.bowl dealer.room-state.state) peer.init our.bowl)
      =/  my-role  ?:(=(our.bowl new-dealer) %alice %bob)
      =/  our-seed=entropy:poker
        %+  mix  eny.bowl
        (mix (sham [our.bowl now.bowl]) (sham now.bowl))
      =/  our-key  (gen-sra-key:poker-sra [sra-prime:poker-sra our-seed])
      =/  new-state=room-state:poker
        :*  room-id=room-id.init
            peer=peer.init
            dealer=new-dealer
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
          ::  save deck to top-level for community reveals
          =/  rs1  rs0(our-hand decrypted, dbl-enc-deck dbl-enc-deck.phase.rs0)
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
        %street-action
          =/  rs0  room-state.state
          ?.  ?=([%live *] phase.rs0)
            `this
          =/  ss   street-status.phase.rs0
          =/  str  street.phase.rs0
          =/  act  action.action
          =/  peer-actor  ?:(=(role.state %alice) %bob %alice)
          =/  our-actor   ?:(=(role.state %alice) %alice %bob)
          ?+  -.act  `this
            %fold
              =/  rs1
                %=  rs0
                  our-stack     (add our-stack.rs0 pot.rs0)
                  pot           0
                  phase         [%awaiting-audit our.bowl]
                  hands-played  (add hands-played.rs0 1)
                  total-wagered  (add total-wagered.rs0 pot.rs0)
                ==
              =.  state  [%0 rs1 role.state]
              :_  this
              :~  [%give %fact ~[/game] %poker-room-update !>([%player-folded peer])]
              ==
            %check
              =/  ss1
                ?:  =(peer-actor %alice)
                  ss(actor our-actor, alice-acted %.y)
                ss(actor our-actor)
              =/  street-done=?
                ?&  ?=(~ last-aggressor.ss1)
                    alice-acted.ss1
                ==
              =/  rs1  rs0(phase [%live str ss1])
              ?:  street-done
                =/  adv  (advance-street rs1 str)
                =.  state  [%0 +.adv role.state]
                :_  this
                %+  weld
                  `(list card)`-.adv
                `(list card)`:~  [%give %fact ~[/game] %poker-room-update !>([%peer-acted act ss1 pot.+.adv 0 peer-bet.+.adv])]
                ==
              =.  state  [%0 rs1 role.state]
              :_  this
              :~  [%give %fact ~[/game] %poker-room-update !>([%peer-acted act ss1 pot.rs1 0 peer-bet.rs1])]
                  [%give %fact ~[/game] %poker-room-update !>([%your-turn str ss1 pot.rs1 0 min-raise.config.rs1])]
              ==
            %call
              =/  to-call  (sub our-bet.rs0 peer-bet.rs0)
              =/  rs1
                rs0(peer-stack (sub peer-stack.rs0 to-call), peer-bet (add peer-bet.rs0 to-call), pot (add pot.rs0 to-call))
              =/  adv  (advance-street rs1 str)
              =.  state  [%0 +.adv role.state]
              :_  this
              %+  weld
                `(list card)`-.adv
              `(list card)`:~  [%give %fact ~[/game] %poker-room-update !>([%peer-acted act ss pot.+.adv 0 peer-bet.+.adv])]
              ==
            %raise
              =/  amount  amount.act
              =/  rs1
                rs0(peer-stack (sub peer-stack.rs0 amount), peer-bet (add peer-bet.rs0 amount), pot (add pot.rs0 amount))
              =/  ss1  ss(actor our-actor, last-aggressor `peer-actor)
              =/  rs2  rs1(phase [%live str ss1])
              =/  to-call  (sub peer-bet.rs2 our-bet.rs2)
              =.  state  [%0 rs2 role.state]
              :_  this
              :~  [%give %fact ~[/game] %poker-room-update !>([%peer-acted act ss1 pot.rs2 to-call peer-bet.rs2])]
                  [%give %fact ~[/game] %poker-room-update !>([%your-turn str ss1 pot.rs2 to-call min-raise.config.rs2])]
              ==
          ==
        %mp-community
          =/  rs0  room-state.state
          ?.  ?=([%revealing *] phase.rs0)
            `this
          ?.  =(street.action street.phase.rs0)
            `this
          =/  our-key  (need our-key.rs0)
          =/  plaintext=(list @ud)
            %+  turn  cards.action
            |=  pd=partial-dec:poker
            (sra-decrypt:poker-sra val.pd our-key)
          =/  new-community  (weld community.rs0 plaintext)
          =/  next-str  street.phase.rs0
          ::  postflop: bob (non-dealer/BB) acts first
          =/  ss=street-status:poker  [%bob ~ %.n %.n %.n]
          =/  rs1
            rs0(community new-community, phase [%live next-str ss], our-bet 0, peer-bet 0)
          =.  state  [%0 rs1 role.state]
          :_  this
          ?:  =(role.state %bob)
            ::  we act first
            :~  [%give %fact ~[/game] %poker-room-update !>([%community-dealt next-str plaintext])]
                [%give %fact ~[/game] %poker-room-update !>([%your-turn next-str ss pot.rs1 0 min-raise.config.rs1])]
            ==
          ::  peer acts first
          :~  [%give %fact ~[/game] %poker-room-update !>([%community-dealt next-str plaintext])]
              [%give %fact ~[/game] %poker-room-update !>([%street-started next-str ss pot.rs1 0 min-raise.config.rs1])]
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
      ::  enforce turn order — drop if it's not our turn
      =/  our-actor  ?:(=(role.state %alice) %alice %bob)
      =/  peer-actor=?(%alice %bob)  ?:(=(role.state %alice) %bob %alice)
      ?.  =(actor.street-status.ph our-actor)
        `this
      =/  peer  peer.rs0
      ?+  -.action  `this
        %fold
          =/  new-peer-stack  (add peer-stack.rs0 pot.rs0)
          =/  rs1
            %=  rs0
              peer-stack    new-peer-stack
              pot           0
              phase         [%awaiting-audit peer]
              hands-played  (add hands-played.rs0 1)
              total-wagered  (add total-wagered.rs0 pot.rs0)
            ==
          =.  state  [%0 rs1 role.state]
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%street-action action])]
              [%give %fact ~[/game] %poker-room-update !>([%player-folded our.bowl])]
              [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%mp-reveal-key d:(need our-key.rs0) `@ux`0])]
          ==
        %check
          =/  ss1
            ?:  =(our-actor %alice)
              street-status.ph(actor peer-actor, alice-acted %.y)
            street-status.ph(actor peer-actor)
          =/  street-done=?
            ?&  ?=(~ last-aggressor.ss1)
                alice-acted.ss1
            ==
          =/  rs1  rs0(phase [%live street.ph ss1])
          ?:  street-done
            =/  adv  (advance-street rs1 street.ph)
            =.  state  [%0 +.adv role.state]
            :_  this
            %+  weld
              `(list card)`-.adv
            `(list card)`:~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%street-action action])]
                [%give %fact ~[/game] %poker-room-update !>([%player-checked our.bowl])]
            ==
          =.  state  [%0 rs1 role.state]
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%street-action action])]
              [%give %fact ~[/game] %poker-room-update !>([%player-checked our.bowl])]
          ==
        %call
          =/  to-call  (sub peer-bet.rs0 our-bet.rs0)
          ~|  'do-call: insufficient stack'
          ?>  (gte our-stack.rs0 to-call)
          =/  rs1
            rs0(our-stack (sub our-stack.rs0 to-call), our-bet (add our-bet.rs0 to-call), pot (add pot.rs0 to-call))
          ::  preflop BB option: Alice called the BB, Bob still has option to raise
          =/  bb-option=?
            ?&  =(%preflop street.ph)
                =(our-bet.rs1 peer-bet.rs1)
            ==
          ?:  bb-option
            =.  state  [%0 rs1 role.state]
            :_  this
            :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%street-action action])]
                [%give %fact ~[/game] %poker-room-update !>([%player-called our.bowl to-call])]
            ==
          =/  adv  (advance-street rs1 street.ph)
          =.  state  [%0 +.adv role.state]
          :_  this
          %+  weld
            `(list card)`-.adv
          `(list card)`:~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%street-action action])]
              [%give %fact ~[/game] %poker-room-update !>([%player-called our.bowl to-call])]
          ==
        %raise
          =/  amount  amount.action
          ~|  'do-raise: insufficient stack'
          ?>  (gte our-stack.room-state.state amount)
          =.  our-stack.room-state.state  (sub our-stack.room-state.state amount)
          =.  our-bet.room-state.state    (add our-bet.room-state.state amount)
          =.  pot.room-state.state        (add pot.room-state.state amount)
          =/  ss1  street-status.ph(actor peer-actor, last-aggressor `our-actor)
          =.  phase.room-state.state  [%live street.ph ss1]
          :_  this
          :~  [%pass /peer %agent [peer %poker-room] %poke %poker-deal-action !>([%street-action action])]
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
