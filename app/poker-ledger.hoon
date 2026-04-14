::  /app/poker-ledger.hoon
::  Per-hand FHLO accounting ledger for Fhloston Poker (CC session Apr 13)
::  Reconcile with existing poker-settle.hoon IOU ledger at merge time
::
/-  *poker-ledger
/+  *poker-rake, default-agent, dbug
|%
+$  state-0
  $:  %0
      ledger-db=ledger-db
  ==
+$  versioned-state  $%(state-0)
--
=|  state-0
=*  state  -
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init   `this
++  on-save   !>(state)
++  on-load
  |=  =vase
  `this(state !<(state-0 vase))
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
++  on-leave  on-leave:def
++  on-agent  on-agent:def
++  on-watch  on-watch:def
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  [~ ~]
    [%x %game @ ~]
    =/  gid=@ud  (rash i.t.t.path dem)
    ``[%noun !>((~(get by ledger-db.state) gid))]
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?>  (team:title our.bowl src.bowl)
  =/  act=ledger-action  !<(ledger-action vase)
  ?-  -.act
  ::
      %open-game
    =/  blank
      |=  c=fhlo
      ^-  ship-ledger
      [cap=c balance=c winnings=0 losses=0 rake-paid=0]
    =/  players=(map ship ship-ledger)
      %-  ~(gas by *(map ship ship-ledger))
      :~  [p1.act (blank cap.act)]
          [p2.act (blank cap.act)]
      ==
    =/  new=game-ledger
      [game-id.act players hands=~ next-hand-id=1 settled=%.n]
    =.  ledger-db.state  (~(put by ledger-db.state) game-id.act new)
    `this
  ::
      %record-hand
    =/  gl=(unit game-ledger)  (~(get by ledger-db.state) game-id.act)
    ?~  gl  `this
    =/  g=game-ledger  u.gl
    ?>  !settled.g
    =/  [rake=fhlo net=fhlo]  (calc-rake pot.act)
    =/  rec=hand-record
      :*  id=next-hand-id.g
          game-id=game-id.act
          hand-num=hand-num.act
          winner=winner.act
          loser=loser.act
          pot=pot.act
          loser-bet=loser-bet.act
          rake=rake
          winner-net=net
          when=now.bowl
      ==
    =/  wl=ship-ledger  (~(got by players.g) winner.act)
    =.  winnings.wl    (add winnings.wl pot.act)
    =.  rake-paid.wl   (add rake-paid.wl rake)
    =.  balance.wl     (add balance.wl net)
    =/  ll=ship-ledger  (~(got by players.g) loser.act)
    =.  losses.ll      (add losses.ll loser-bet.act)
    =.  balance.ll
      ?:  (gth loser-bet.act balance.ll)  0
      (sub balance.ll loser-bet.act)
    =.  players.g   (~(put by players.g) winner.act wl)
    =.  players.g   (~(put by players.g) loser.act ll)
    =.  hands.g     [rec hands.g]
    =.  next-hand-id.g  +(next-hand-id.g)
    =.  ledger-db.state  (~(put by ledger-db.state) game-id.act g)
    :_  this
    ~[[%pass /rake %agent [our.bowl %poker-vault]
        %poke %noun !>([%credit-rake rake])]]
  ::
      %close-game
    =/  gl=(unit game-ledger)  (~(get by ledger-db.state) game-id.act)
    ?~  gl  `this
    =.  settled.u.gl  %.y
    =.  ledger-db.state  (~(put by ledger-db.state) game-id.act u.gl)
    `this
  ==
--
