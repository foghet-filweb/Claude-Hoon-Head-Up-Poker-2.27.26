::  /app/poker-settle.hoon
::
::  %poker-settle: IOU ledger and reputation tracking agent.
::
::  Jael integration:
::    on-init sends [%pass /jael %arvo %j %private-keys ~]
::    on-arvo handles the resulting %private-keys gift, which
::    carries [=life vein=(map life ring)]. We cache the ring
::    for the current life in our-ring and use it via /app/poker-sig
::    to sign game results.
::
::    Key rotation: Jael re-sends %private-keys whenever keys change
::    (e.g. after a breach). on-arvo updates our-ring each time.
::
::    Verification: done synchronously via %lyfe + %deed scries
::    inside /app/poker-sig, so no additional subscriptions needed.
::
/-  poker
/+  default-agent, poker-sig
|%
::  settle-action, settle-update, settle-balance, iou-entry are in sur/poker.hoon

::  +$ peer-ledger: per-peer running IOU ledger (local to this agent)
+$  peer-ledger
  $:  peer=@p
      net=settle-balance:poker
      history=(list iou-entry:poker)
      oldest-unpaid=@da
  ==

::  +$ reputation: per-peer track record (local to this agent)
+$  reputation
  $:  ship=@p
      games-played=@ud
      games-won=@ud
      total-won=@ud
      total-lost=@ud
      outstanding-debt=@ud
      disputes=@ud
      no-shows=@ud
      pay-confirmations=@ud
      last-seen=@da
      mode=settle-mode:poker
  ==

::  +$ reputation-gate: admission criteria for challenging
+$  reputation-gate
  $:  min-games=@ud
      max-outstanding-debt=@ud
      max-disputes=@ud
      max-no-shows=@ud
  ==

::  +$ settle-state: full agent state
+$  settle-state
  $:  %0
      mode=settle-mode:poker
      ledger=(map @p peer-ledger)
      reputations=(map @p reputation)
      pending=(map @uv game-result:poker)
      gate=reputation-gate
      our-life=(unit @ud)
      our-ring=(unit ring)
  ==

+$  card  card:agent:gall

++  default-gate  ^-  reputation-gate  [0 0 5 3]
++  real-gate     ^-  reputation-gate  [10 500 1 1]
--


|%
::  ──────────────────────────────────────────────────────────────

++  record-result
  |=  [=bowl:gall ss=settle-state result=game-result:poker]
  ^-  (quip card settle-state)
  =/  signed-result=game-result:poker
    ?~  our-ring.ss
      ~&  [%poker-settle-warn %signing-without-key room-id.result]
      result
    (attach-sig:poker-sig result u.our-ring.ss our.bowl)
  =/  we-won   =(our.bowl winner.signed-result)
  =/  peer     ?:(=(our.bowl alice.signed-result) bob.signed-result alice.signed-result)
  =/  delta=@s
    ?:  we-won  (new:si %.y amount.signed-result)
    (new:si & amount.signed-result)
  =.  ss  (update-ledger bowl ss peer delta signed-result)
  =.  ss  (update-reputation bowl ss peer signed-result)
  =.  pending.ss  (~(put by pending.ss) room-id.signed-result signed-result)
  =/  settle-cards=(list card)
    ?:  we-won
      ~[(give-update [%awaiting-settlement peer amount.signed-result room-id.signed-result])]
    :~
      (poke-peer peer [%propose-settlement signed-result 'GG'])
      (give-update [%settlement-proposed peer amount.signed-result room-id.signed-result])
    ==
  [settle-cards ss]

++  handle-action
  |=  [=bowl:gall ss=settle-state peer=@p action=settle-action:poker]
  ^-  (quip card settle-state)
  ?-  -.action
    %propose-settlement
      =/  their-result  result.action
      ?.  ?~(our-ring.ss %.y (verify-body:poker-sig bowl peer bob-sig.their-result (result-body:poker-sig their-result)))
        ~&  [%poker-settle-warn %bad-sig-from peer]
        [~[(give-update [%sig-failed room-id.their-result 'peer signature invalid'])] ss]
      =/  our-result  (~(get by pending.ss) room-id.their-result)
      ?~  our-result
        =.  pending.ss  (~(put by pending.ss) room-id.their-result their-result)
        `ss
      ?.  =((result-body:poker-sig their-result) (result-body:poker-sig u.our-result))
        :-
          ~[(poke-peer peer [%dispute room-id.their-result 'result body mismatch' (shax (jam (result-body:poker-sig their-result)))]) (give-update [%dispute-raised peer room-id.their-result])]
        ss
      :-
        ~[(poke-peer peer [%ack-result room-id.their-result]) (give-update [%settlement-received peer amount.their-result room-id.their-result])]
      ss
    %ack-result
      [~[(give-update [%settlement-acked peer room-id.action])] ss]
    %confirm-paid
      =.  ss  (add-pay-confirmation ss peer room-id.action)
      [~[(give-update [%payment-confirmed peer room-id.action memo.action])] ss]
    %dispute
      =.  ss  (record-dispute ss peer room-id.action)
      [~[(give-update [%dispute-received peer room-id.action reason.action])] ss]
    %request-balance
      =/  led  (~(get by ledger.ss) peer)
      =/  reply=settle-action:poker
        ?~  led  [%balance-response (new:si | 0) ~]
        [%balance-response net.u.led history.u.led]
      [~[(poke-peer peer reply)] ss]
    %balance-response
      =/  our-led  (~(get by ledger.ss) peer)
      =/  our-net=settle-balance:poker  ?~(our-led (new:si | 0) net.u.our-led)
      =/  sum  (sum:si our-net net.action)
      ?.  !=(sum (new:si | 0))  `ss
      [~[(give-update [%ledger-divergence peer our-net net.action])] ss]
  ==

++  do-confirm-paid
  |=  [=bowl:gall ss=settle-state room-id=@uv memo=cord]
  ^-  (quip card settle-state)
  =/  result  (~(get by pending.ss) room-id)
  ?~  result  `ss
  =/  peer  ?:(=(our.bowl alice.u.result) bob.u.result alice.u.result)
  =.  ss  (add-pay-confirmation ss peer room-id)
  =.  pending.ss  (~(del by pending.ss) room-id)
  :-
    ~[(poke-peer peer [%confirm-paid room-id memo]) (give-update [%payment-confirmed peer room-id memo])]
  ss

::  ── Ledger / reputation helpers ──────────────────────────────

++  update-ledger
  |=  [=bowl:gall ss=settle-state peer=@p delta=@s result=game-result:poker]
  ^-  settle-state
  =/  existing  (~(gut by ledger.ss) peer *peer-ledger)
  =/  new-net   (sum:si net.existing delta)
  =/  entry=iou-entry:poker  [room-id.result delta now.bowl result]
  =/  updated=peer-ledger
    :*  peer=peer
        net=new-net
        history=[entry history.existing]
        oldest-unpaid=?~(history.existing now.bowl oldest-unpaid.existing)
    ==
  ss(ledger (~(put by ledger.ss) peer updated))

++  update-reputation
  |=  [=bowl:gall ss=settle-state peer=@p result=game-result:poker]
  ^-  settle-state
  =/  existing=reputation
    %+  ~(gut by reputations.ss)  peer
    [peer 0 0 0 0 0 0 0 0 now.bowl mode.ss]
  =/  we-won  =(our.bowl winner.result)
  =/  new-debt
    ?:(we-won (add outstanding-debt.existing amount.result) outstanding-debt.existing)
  =/  updated=reputation
    %_  existing
      games-played     +(games-played.existing)
      games-won        ?:(=(peer winner.result) +(games-won.existing) games-won.existing)
      total-won        ?:(we-won total-won.existing (add total-won.existing amount.result))
      total-lost       ?:(we-won (add total-lost.existing amount.result) total-lost.existing)
      outstanding-debt  new-debt
      last-seen        now.bowl
    ==
  ss(reputations (~(put by reputations.ss) peer updated))

++  add-pay-confirmation
  |=  [ss=settle-state peer=@p room-id=@uv]
  ^-  settle-state
  =/  existing=reputation  (~(gut by reputations.ss) peer *reputation)
  =/  result  (~(get by pending.ss) room-id)
  =/  paid=@ud  ?~(result 0 amount.u.result)
  =/  updated=reputation
    %_  existing
      pay-confirmations  +(pay-confirmations.existing)
      outstanding-debt   (sub outstanding-debt.existing (min outstanding-debt.existing paid))
    ==
  ss(reputations (~(put by reputations.ss) peer updated))

++  record-dispute
  |=  [ss=settle-state peer=@p room-id=@uv]
  ^-  settle-state
  =/  existing=reputation  (~(gut by reputations.ss) peer *reputation)
  ss(reputations (~(put by reputations.ss) peer existing(disputes +(disputes.existing))))

++  check-gate
  |=  [ss=settle-state peer=@p]
  ^-  ?
  =/  rep  (~(get by reputations.ss) peer)
  ?~  rep  %.y
  =/  r  u.rep
  ?&  (gte games-played.r min-games.gate.ss)
      (lth outstanding-debt.r max-outstanding-debt.gate.ss)
      (lth disputes.r max-disputes.gate.ss)
      (lth no-shows.r max-no-shows.gate.ss)
  ==

::  ── Infrastructure helpers ───────────────────────────────────

++  poke-peer
  |=  [peer=@p action=settle-action:poker]
  ^-  card
  [%pass /settle/(scot %p peer) %agent [peer %poker-settle] %poke %poker-settle-action !>(action)]

++  give-update
  |=  upd=settle-update:poker
  ^-  card
  [%give %fact ~[/updates] %poker-settle-update !>(upd)]
--

=|  settle-state
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    sig   ~(. poker-sig bowl)

::  ──────────────────────────────────────────────────────────────
++  on-init
  ^-  (quip card _this)
  =.  mode.state  %play
  =.  gate.state  default-gate
  =/  jael-sub=card  [%pass /jael %arvo %j %private-keys ~]
  [[jael-sub]~ this]

++  on-save   !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  [~[[%pass /jael %arvo %j %private-keys ~]] this(state !<(settle-state old))]

::  ──────────────────────────────────────────────────────────────
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire sign)
    [%jael ~]
      ?.  ?=([%jael *] sign)
        (on-arvo:def wire sign)
      =/  jael-gift  +.sign
      ?.  ?=([%private-keys *] jael-gift)
        (on-arvo:def wire sign)
      =/  new-life=@ud   life.jael-gift
      =/  new-ring=(unit ring)  (~(get by vein.jael-gift) new-life)
      =.  our-life.state  `new-life
      =.  our-ring.state  new-ring
      =/  notify=card  (give-update [%keys-received new-life])
      [[notify]~ this]
  ==

::  ──────────────────────────────────────────────────────────────
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
    %poker-settle-result
      =/  result  !<(game-result:poker vase)
      ?>  =(src.bowl our.bowl)
      =^  cards  state  (record-result bowl state result)
      [cards this]
    %poker-settle-action
      =/  action  !<(settle-action:poker vase)
      =^  cards  state  (handle-action bowl state src.bowl action)
      [cards this]
    %poker-settle-set-mode
      =/  new-mode  !<(settle-mode:poker vase)
      ?>  =(src.bowl our.bowl)
      =.  mode.state  new-mode
      =.  gate.state  ?-(new-mode %play default-gate, %real real-gate)
      `this
    %poker-settle-confirm
      =/  room-id  !<(@uv vase)
      ?>  =(src.bowl our.bowl)
      =^  cards  state  (do-confirm-paid bowl state room-id 'confirmed via UI')
      [cards this]
  ==

::  ──────────────────────────────────────────────────────────────
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %reputation @ ~]
      =/  ship  (slav %p i.t.t.path)
      ``[%poker-reputation !>((~(get by reputations.state) ship))]
    [%x %balance @ ~]
      =/  ship  (slav %p i.t.t.path)
      ``[%poker-balance !>((~(get by ledger.state) ship))]
    [%x %can-challenge @ ~]
      =/  ship  (slav %p i.t.t.path)
      ``[%noun !>((check-gate state ship))]
    [%x %mode ~]
      ``[%poker-mode !>(mode.state)]
    [%x %pending ~]
      ``[%poker-pending !>(pending.state)]
    [%x %keys-ready ~]
      ``[%poker-keys-ready !>(?=(^ our-ring.state))]
  ==

++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  =(src.bowl our.bowl)
  `this

++  on-agent   |=([=wire =sign:agent:gall] (on-agent:def wire sign))
++  on-leave   on-leave:def
++  on-fail    on-fail:def

::  ──────────────────────────────────────────────────────────────
::  Core logic

--
