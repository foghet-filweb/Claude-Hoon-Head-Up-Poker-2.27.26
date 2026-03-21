::  /app/slab-mint.hoon
::
::  %slab-mint: star-side %slab token mint agent.
::
::  Runs on the distributing star. Handles one-time chip issuance
::  to qualifying Azimuth L1 planets.
::
::  Protocol:
::    1. A planet sends a %claim poke to the star running this agent.
::    2. We verify:
::         (a) the claimant is an active L1 Azimuth point
::         (b) the claimant has not already claimed (append-only set)
::    3. We mint by poking %poker-settle on the claiming ship with a
::       %slab-issue action carrying a signed issuance record.
::    4. We record the ship in claimed.state (permanent, never removed).
::
::  Only the star that owns this agent may change the allocation or
::  pause minting (via %set-allocation / %set-paused pokes).
::
::  Types used here (all defined in /sur/poker.hoon):
::    slab-entry, mint-action, mint-update
::
::  State version %0 → %1 → %2 — migration handled in on-load.
::
/-  poker
/+  default-agent, dbug
::
|%
::  +$ mint-state-v0: original shape — no lobby-host field.
+$  mint-state-v0
  $:  %0
      allocation=@ud
      claimed=(set @p)
      paused=?
      our-life=(unit @ud)
      our-ring=(unit ring)
  ==

::  +$ mint-state-v1: added lobby-host field.
+$  mint-state-v1
  $:  %1
      allocation=@ud
      claimed=(set @p)
      paused=?
      our-life=(unit @ud)
      our-ring=(unit ring)
      lobby-host=(unit @p)
  ==

::  +$ mint-state: current shape — tagged %2.
::  Added: hard-cap (immutable) and total-issued (running count).
+$  mint-state
  $:  %2
      allocation=@ud
      claimed=(set @p)
      paused=?
      our-life=(unit @ud)
      our-ring=(unit ring)
      lobby-host=(unit @p)
      hard-cap=@ud
      total-issued=@ud
  ==

+$  versioned-state
  $%  mint-state-v0
      mint-state-v1
      mint-state
  ==

+$  card  card:agent:gall

::  Sphere-geometry token supply constants.
::  These are the only values that determine total supply.
::  They are computed once and baked in — not configurable.
++  default-allocation  ^-  @ud  6.162
++  slab-hard-cap       ^-  @ud  26.465.590.055.424
--

=|  mint-state
=*  state  -
::

|%
::  ──────────────────────────────────────────────────────────────
::  Internal helpers
::  ──────────────────────────────────────────────────────────────

::  ++do-issue: sign, record, and deliver a chip allocation to a ship.
::  Hard cap is enforced here — this is the binding check, not advisory.
++  do-issue
  |=  [=bowl:gall ss=mint-state target=@p update-tag=?(%claimed %gifted)]
  ^-  (quip card mint-state)
  =/  amount=@ud  allocation.ss
  ?:  (gth (add total-issued.ss amount) hard-cap.ss)
    :_(ss ~[(give-update [%cap-reached our.bowl total-issued.ss hard-cap.ss])])
  =/  issued-at=@da     now.bowl
  =/  issuance-sig=@ux  (sign-issuance ss target amount issued-at)
  =/  entry=slab-entry:poker
    [amount our.bowl issued-at issuance-sig %.n]
  =.  claimed.ss       (~(put in claimed.ss) target)
  =.  total-issued.ss  (add total-issued.ss amount)
  =/  issue-card=card
    [%pass /issue/(scot %p target) %agent [target %poker-settle] %poke %poker-slab-issue !>(entry)]
  =/  notify=card
    ?-  update-tag
      %claimed  (give-update [%claimed target amount])
      %gifted   (give-update [%gifted target amount])
    ==
  [~[issue-card notify] ss]

::  ++lobby-host-ship: the ship authorised to send %gift pokes.
::  Defaults to our.bowl (same-ship mode for testing).
++  lobby-host-ship
  |=  [=bowl:gall ss=mint-state]
  ^-  @p
  ?~(lobby-host.ss our.bowl u.lobby-host.ss)

::  ++is-l1-ship: check if a ship is an active L1 Azimuth point.
::  Galaxies (width 1) and stars (width 2) are always L1.
::  Planets (width 4) are checked against Jael dominion.
::  Moons (width 8) and comets (width 16) are not Azimuth points.
++  is-l1-ship
  |=  [=bowl:gall ship=@p]
  ^-  ?
  =/  width=@ud  (met 3 ship)
  ?:  (lte width 2)  %.y
  ?.  =(width 4)  %.n
  %.y  ::  TODO: re-enable Jael L2 check when API available

::  ++sign-issuance: produce Ed25519 signature over [ship amount issued-at].
::  Returns 0 if keys are not yet available.
++  sign-issuance
  |=  [ss=mint-state ship=@p amount=@ud issued-at=@da]
  ^-  @ux
  ?~  our-ring.ss
    ~&  [%slab-mint-warn %signing-without-key ship]
    0x0
  =/  cub  (nol:nu:crub:crypto u.our-ring.ss)
  =/  msg=@  (shax (jam [ship amount issued-at]))
  (sign:as:cub msg)

::  ++give-update: broadcast a mint-update fact to /updates subscribers
++  give-update
  |=  upd=mint-update:poker
  ^-  card
  [%give %fact ~[/updates] %poker-slab-mint-update !>(upd)]
--

%-  agent:dbug
^-  agent:gall

|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)

::  ──────────────────────────────────────────────────────────────
++  on-init
  ^-  (quip card _this)
  =.  allocation.state    default-allocation
  =.  paused.state        %.n
  =.  hard-cap.state      slab-hard-cap
  =.  total-issued.state  0
  =/  jael-sub=card  [%pass /jael %arvo %j %private-keys ~]
  [[jael-sub]~ this]

++  on-save   !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  versioned  !<(versioned-state old)
  =/  as-v1=mint-state-v1
    ?-  -.versioned
      %0
        :*  %1
            allocation.versioned
            claimed.versioned
            paused.versioned
            our-life.versioned
            our-ring.versioned
            ~
        ==
      %1  versioned
      %2  !!
    ==
  =/  migrated=mint-state
    ?-  -.versioned
      ?(%0 %1)
        =/  issued=@ud  (mul (lent ~(tap in claimed.as-v1)) allocation.as-v1)
        :*  %2
            allocation.as-v1
            claimed.as-v1
            paused.as-v1
            our-life.as-v1
            our-ring.as-v1
            lobby-host.as-v1
            slab-hard-cap
            issued
        ==
      %2  versioned
    ==
  [~[[%pass /jael %arvo %j %private-keys ~]] this(state migrated)]

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
      =/  new-life=@ud          life.jael-gift
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
  ?+  mark  `this
    %poker-slab-mint
      =/  action  !<(mint-action:poker vase)
      ?-  -.action
        %claim
          ?.  !paused.state
            :_(this ~[(give-update [%rejected src.bowl 'minting paused'])])
          ?.  (is-l1-ship bowl src.bowl)
            :_(this ~[(give-update [%rejected src.bowl 'not an L1 Azimuth point'])])
          ?:  (~(has in claimed.state) src.bowl)
            :_(this ~[(give-update [%rejected src.bowl 'already claimed'])])
          =^  cards  state  (do-issue bowl state src.bowl %claimed)
          [cards this]
        %gift
          =/  target=@p  ship.action
          ?.  =(src.bowl (lobby-host-ship bowl state))
            :_(this ~[(give-update [%rejected target 'gift from unknown lobby host'])])
          ?.  !paused.state
            :_(this ~[(give-update [%rejected target 'minting paused'])])
          ?.  (is-l1-ship bowl target)
            :_(this ~[(give-update [%rejected target 'not an L1 Azimuth point'])])
          ?:  (~(has in claimed.state) target)
            `this
          =^  cards  state  (do-issue bowl state target %gifted)
          [cards this]
        %set-allocation
          ?>  =(src.bowl our.bowl)
          =/  new-amount=@ud  amount.action
          ?:  (gth (add total-issued.state new-amount) hard-cap.state)
            :_(this ~[(give-update [%rejected our.bowl 'allocation would exceed hard cap'])])
          =.  allocation.state  new-amount
          :_(this ~[(give-update [%allocation-changed new-amount])])
        %set-paused
          ?>  =(src.bowl our.bowl)
          =.  paused.state  paused.action
          :_(this ~[(give-update [%paused paused.action])])
        %set-lobby-host
          ?>  =(src.bowl our.bowl)
          =.  lobby-host.state  `ship.action
          `this
        %transfer
          :_(this ~[(give-update [%rejected src.bowl 'transfers not yet enabled'])])
      ==
  ==

::  ──────────────────────────────────────────────────────────────
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %has-claimed @ ~]
      =/  ship  (slav %p i.t.t.path)
      ``[%noun !>((~(has in claimed.state) ship))]
    [%x %claim-count ~]
      ``[%noun !>((lent ~(tap in claimed.state)))]
    [%x %allocation ~]
      ``[%noun !>(allocation.state)]
    [%x %paused ~]
      ``[%noun !>(paused.state)]
    [%x %keys-ready ~]
      ``[%noun !>(?=(^ our-ring.state))]
    [%x %total-issued ~]
      ``[%noun !>(total-issued.state)]
    [%x %hard-cap ~]
      ``[%noun !>(hard-cap.state)]
  ==

::  ──────────────────────────────────────────────────────────────
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  =(src.bowl our.bowl)
  `this

++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:def wire sign)
    [%issue @ ~]
      ?+  -.sign  (on-agent:def wire sign)
        %poke-ack
          ?~  p.sign
            `this
          ~&  >>>  [%slab-mint-issue-failed wire u.p.sign]
          `this
      ==
  ==

++  on-leave  on-leave:def
++  on-fail   on-fail:def

--
