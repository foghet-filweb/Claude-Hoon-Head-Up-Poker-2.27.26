::  /app/poker-settle-cc.hoon
::  Escrow agent for Fhloston Poker (CC session Apr 13)
::  Named poker-settle-cc.hoon to avoid overwriting existing poker-settle.hoon
::  Reconcile the two approaches at merge time:
::    poker-settle.hoon     = IOU ledger + Jael signing + reputation (Claude Chat)
::    poker-settle-cc.hoon  = ETH escrow + FHLO vault + settlement formula (CC session)
::
/-  *poker-escrow, *poker-ledger, *poker-vault
/+  *poker-rake, *poker-wallet, default-agent, dbug
|%
+$  state-0
  $:  %0
      escrow-db=escrow-db
      next-eid=@ud
      next-complaint-id=@ud
      complaint-db=complaint-db:poker-complaint
      rep-db=(map ship [score=@ud games=@ud flags=@ud])
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
++  on-agent  on-agent:def
++  on-leave  on-leave:def
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
    [%escrow ~]  `this
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  [~ ~]
    [%x %reputation @ ~]
    =/  target=ship  (slav %p i.t.t.path)
    =/  result  (~(get by rep-db.state) target)
    =/  out=json
      ?~  result
        (pairs:enjs:format ~[['found' b+%.n]])
      %-  pairs:enjs:format
      :~  ['found'  b+%.y]
          ['score'  n+(scot %ud score.u.result)]
          ['games'  n+(scot %ud games.u.result)]
          ['flags'  n+(scot %ud flags.u.result)]
      ==
    ``[%json !>(out)]
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
  ::
      %poker-escrow-action
    =/  act=escrow-action  !<(escrow-action vase)
    ?-  -.act
        %open
      ?>  (team:title our.bowl src.bowl)
      =/  eid=@ud  next-eid.state
      =/  blank-stake
        |=  [who=ship amt=@ud]
        ^-  player-stake
        [who ~ amt %.n]
      =/  new=escrow-entry
        :*  id=eid
            game-id=game-id.act
            p1=(blank-stake p1.act amount.act)
            p2=(blank-stake p2.act amount.act)
            status=%awaiting-wallets
            winner=~
            when-locked=~
            when-settled=~
        ==
      =.  escrow-db.state  (~(put by escrow-db.state) eid new)
      =.  next-eid.state   +(next-eid.state)
      :_  this
      (escrow-fact new)
    ::
        %deposit-confirmed
      ?>  (team:title our.bowl src.bowl)
      :_  this
      :~  [%pass /deposit %agent [our.bowl %poker-vault]
            %poke %noun !>([%credit who.act amount.act])]
          [%pass /ledger %agent [our.bowl %poker-ledger]
            %poke %noun !>([%open-game game-id.act who.act who.act amount.act])]
      ==
    ::
        %submit-wallet
      =/  e=(unit [=id entry=escrow-entry])  (find-by-game game-id.act)
      ?~  e  `this
      =/  entry=escrow-entry  entry.u.e
      ?>  |=(=(src.bowl who.p1.entry) =(src.bowl who.p2.entry))
      ?>  =(%awaiting-wallets status.entry)
      =/  parsed=(unit @ux)  (cordtohex wallet.act)
      ?>  ?=(^ parsed)
      =/  canonical=@t  (hextocord u.parsed)
      =/  updated=escrow-entry
        ?:  =(src.bowl who.p1.entry)
          entry(wallet.p1 `canonical, submitted.p1 %.y)
        entry(wallet.p2 `canonical, submitted.p2 %.y)
      =?  status.updated  &(submitted.p1.updated submitted.p2.updated)
        %locked
      =?  when-locked.updated  =(%locked status.updated)
        `now.bowl
      =.  escrow-db.state  (~(put by escrow-db.state) id.u.e updated)
      =/  extra=(list card)
        ?.  =(%locked status.updated)  ~
        ~[[%pass /lock %agent [our.bowl %poker-log-bridge]
            %poke %noun !>(updated)]]
      :_  this
      (weld (escrow-fact updated) extra)
    ::
        %release
      ?>  (team:title our.bowl src.bowl)
      =/  e=(unit [=id entry=escrow-entry])  (find-by-game game-id.act)
      ?~  e  `this
      =/  entry=escrow-entry  entry.u.e
      =/  gl=(unit game-ledger)
        .^  (unit game-ledger)  %gx
            /(scot %p our.bowl)/poker-ledger/(scot %da now.bowl)
            /game/(scot %ud game-id.act)/noun
        ==
      ?~  gl  `this
      =/  g=game-ledger  u.gl
      =/  settle-player
        |=  [who=ship stake=player-stake]
        ^-  [ship @ud]
        =/  sl=(unit ship-ledger)  (~(get by players.g) who)
        ?~  sl  [who amount.stake]
        =/  payout=@ud
          (calc-settlement amount.stake winnings.u.sl losses.u.sl rake-paid.u.sl)
        [who payout]
      =/  [p1-ship=ship p1-pay=@ud]  (settle-player who.p1.entry p1.entry)
      =/  [p2-ship=ship p2-pay=@ud]  (settle-player who.p2.entry p2.entry)
      =/  updated=escrow-entry
        entry(status %released, winner `winner.act, when-settled `now.bowl)
      =.  escrow-db.state  (~(put by escrow-db.state) id.u.e updated)
      :_  this
      :~  [%pass /close %agent [our.bowl %poker-ledger]
            %poke %noun !>([%close-game game-id.act])]
          [%pass /cp1 %agent [our.bowl %poker-vault]
            %poke %noun !>([%credit p1-ship p1-pay])]
          [%pass /cp2 %agent [our.bowl %poker-vault]
            %poke %noun !>([%credit p2-ship p2-pay])]
          [%pass /settle %agent [our.bowl %poker-log-bridge]
            %poke %noun !>(updated)]
          [%give %fact ~[/escrow] %poker-escrow-update !>(updated)]
      ==
    ::
        %return
      ?>  (team:title our.bowl src.bowl)
      =/  e=(unit [=id entry=escrow-entry])  (find-by-game game-id.act)
      ?~  e  `this
      =/  entry=escrow-entry  entry.u.e
      =/  updated=escrow-entry
        entry(status %returned, when-settled `now.bowl)
      =.  escrow-db.state  (~(put by escrow-db.state) id.u.e updated)
      :_  this
      :~  [%pass /close %agent [our.bowl %poker-ledger]
            %poke %noun !>([%close-game game-id.act])]
          [%pass /rp1 %agent [our.bowl %poker-vault]
            %poke %noun !>([%credit who.p1.entry amount.p1.entry])]
          [%pass /rp2 %agent [our.bowl %poker-vault]
            %poke %noun !>([%credit who.p2.entry amount.p2.entry])]
          [%give %fact ~[/escrow] %poker-escrow-update !>(updated)]
      ==
    ::
        %dispute
      =/  e=(unit [=id entry=escrow-entry])  (find-by-game game-id.act)
      ?~  e  `this
      =/  entry=escrow-entry  entry.u.e
      ?>  |(=(src.bowl who.p1.entry)
            =(src.bowl who.p2.entry)
            (team:title our.bowl src.bowl))
      ?>  =(%locked status.entry)
      =/  updated=escrow-entry  entry(status %disputed)
      =.  escrow-db.state  (~(put by escrow-db.state) id.u.e updated)
      :_  this
      (escrow-fact updated)
    ==
  ::
      %poker-complaint-action
    =/  act=complaint-action:poker-complaint  !<(complaint-action:poker-complaint vase)
    ?-  -.act
      %no-complaint  `this
      %file
      ?>  !=(src.bowl respondent.act)
      =/  dup=?
        %+  lien  ~(val by complaint-db.state)
        |=(c=complaint:poker-complaint
          &(=(game-id.c game-id.act) =(complainant.c src.bowl)))
      ?:  dup  `this
      =/  has-other=?
        %+  lien  reasons.act
        |=(r=complaint-reason:poker-complaint =(%other r))
      ?.  |(!has-other !=('' notes.act))
        ~|(%other-requires-notes !!)
      =/  cid=@ud  next-complaint-id.state
      =/  new=complaint:poker-complaint
        :*  id=cid
            game-id=game-id.act
            complainant=src.bowl
            respondent=respondent.act
            reasons=reasons.act
            notes=notes.act
            when=now.bowl
        ==
      =.  complaint-db.state  (~(put by complaint-db.state) cid new)
      =.  next-complaint-id.state  +(next-complaint-id.state)
      =/  prev  (~(get by rep-db.state) respondent.act)
      =/  updated=[score=@ud games=@ud flags=@ud]
        ?~  prev  [50 0 1]
        [score.u.prev games.u.prev +(flags.u.prev)]
      =.  rep-db.state  (~(put by rep-db.state) respondent.act updated)
      `this
    ==
  ==
::
++  find-by-game
  |=  gid=@ud
  ^-  (unit [id=@ud entry=escrow-entry])
  =/  entries=(list [@ud escrow-entry])  ~(tap by escrow-db.state)
  |-
  ?~  entries  ~
  =/  [eid=@ud e=escrow-entry]  i.entries
  ?:  =(gid game-id.e)  `[eid e]
  $(entries t.entries)
::
++  escrow-fact
  |=  e=escrow-entry
  ^-  (list card)
  ~[[%give %fact ~[/escrow] %poker-escrow-update !>(e)]]
--
