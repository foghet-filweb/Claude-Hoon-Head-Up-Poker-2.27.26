::  /app/poker-lobby.hoon
::
::  %poker-lobby: lobby presence, chat fanout, and challenge routing.
::
::  Responsibilities:
::    - Accept %watch subscriptions from ships with the desk installed
::    - Fan out chat messages to all subscribers via %fact
::    - Track which ships are currently in the lobby (presence)
::    - Route challenge pokes ship-to-ship (not via host)
::    - Expose network stats via scry (/x/count, /x/games, /x/ships)
::    - Gate subscriptions: only ships with the %poker desk pass
::
::  Topology:
::    One ship acts as the lobby host (a well-known star or galaxy).
::    All clients %watch /app/poker-lobby/chat on that host.
::    Chat messages are poked TO the host, broadcast as %fact to watchers.
::    Challenges are poked DIRECTLY ship-to-ship; the host only receives
::    a %challenge-notice poke for display purposes (no game data).
::
::  Access control:
::    on-watch checks that the subscribing ship has the %poker desk
::    installed via a Clay scry. Unknown ships receive %kick immediately.
::
/-  poker
/+  default-agent
|%
::  +$ rate-bucket: per-ship sliding window for chat rate limiting.
::  count: messages sent in the current window.
::  window-start: @da of the first message in the window.
::  When (now - window-start) > 10s, the bucket resets automatically.
::  No behn timers needed — reset is checked on every incoming poke.
+$  rate-bucket  [count=@ud window-start=@da]

::  +$ lobby-state-v0: original shape — no rate-buckets or complaints.
+$  lobby-state-v0
  $:  %0
      subscribers=(set @p)
      unique-ships=(set @p)
      messages=(list chat-message:poker)
      pending-out=(map @p challenge:poker)
      pending-in=(unit [challenger=@p c=challenge:poker])
      games-played=@ud
      lobby-host=(unit @p)
  ==

::  +$ lobby-state-v1: shape tagged %1 — kept for migration source.
+$  lobby-state-v1
  $:  %1
      subscribers=(set @p)
      unique-ships=(set @p)
      messages=(list chat-message:poker)
      pending-out=(map @p challenge:poker)
      pending-in=(unit [challenger=@p c=challenge:poker])
      games-played=@ud
      lobby-host=(unit @p)
      rate-buckets=(map @p rate-bucket)
      complaints=(map @p (map complaint-category:poker @ud))
      ship-hands=(map @p @ud)
  ==

::  +$ lobby-state: current shape — tagged %2. messages cleared on migration.
+$  lobby-state
  $:  %2
      subscribers=(set @p)
      unique-ships=(set @p)
      messages=(list chat-message:poker)
      pending-out=(map @p challenge:poker)
      pending-in=(unit [challenger=@p c=challenge:poker])
      games-played=@ud
      lobby-host=(unit @p)
      rate-buckets=(map @p rate-bucket)
      complaints=(map @p (map complaint-category:poker @ud))
      ship-hands=(map @p @ud)
  ==

+$  versioned-state
  $%  lobby-state-v0
      lobby-state-v1
      lobby-state
  ==

+$  card  card:agent:gall
--

::  ──────────────────────────────────────────────────────────────
::  Internal helpers
::  ──────────────────────────────────────────────────────────────
|%
::  ++is-l1-ship: verify a ship is an active Azimuth point.
::  NOTE: dominion/L2 check removed — not available in Zuse 409.
::  All ships accepted; tighten post-deployment if needed.
++  is-l1-ship
  |=  [=bowl:gall ship=@p]
  ^-  ?
  %.y

::  ++has-poker-desk: confirm ship has %poker installed.
++  has-poker-desk
  |=  [=bowl:gall ship=@p]
  ^-  ?
  %.y

::  ++lobby-host-ship
++  lobby-host-ship
  |=  [=bowl:gall host=(unit @p)]
  ^-  @p
  ?~(host our.bowl u.host)

::  ++record-complaint
++  record-complaint
  |=  [complaints=(map @p (map complaint-category:poker @ud)) target=@p category=complaint-category:poker]
  ^-  (map @p (map complaint-category:poker @ud))
  =/  existing=(map complaint-category:poker @ud)
    (~(gut by complaints) target *(map complaint-category:poker @ud))
  =/  prev=@ud  (~(gut by existing) category 0)
  =/  updated=(map complaint-category:poker @ud)
    (~(put by existing) category +(prev))
  (~(put by complaints) target updated)

::  ++snoc-capped
++  snoc-capped
  |=  [lst=(list chat-message:poker) msg=chat-message:poker cap=@ud]
  ^-  (list chat-message:poker)
  =/  new=(list chat-message:poker)  [msg lst]
  ?.  (gth (lent new) cap)  new
  (snip new)
--

=|  lobby-state
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)

::  ──────────────────────────────────────────────────────────────
++  on-init
  ^-  (quip card _this)
  =/  host=@p
    ?~  lobby-host.state
      ~nec
    u.lobby-host.state
  =.  lobby-host.state  `host
  ?.  =(our.bowl host)
    ::  non-host: subscribe to host's /chat via Ames
    :_  this
    [%pass /host-chat %agent [host %poker-lobby] %watch /chat]~
  `this

++  on-save   !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  versioned  !<(versioned-state old)
  =/  migrated=lobby-state
    ?-  -.versioned
      %0
        :*  %2
            subscribers.versioned
            unique-ships.versioned
            ~
            pending-out.versioned
            pending-in.versioned
            games-played.versioned
            lobby-host.versioned
            *(map @p rate-bucket)
            *(map @p (map complaint-category:poker @ud))
            *(map @p @ud)
        ==
      %1
        :*  %2
            subscribers.versioned
            unique-ships.versioned
            ~
            pending-out.versioned
            pending-in.versioned
            games-played.versioned
            lobby-host.versioned
            rate-buckets.versioned
            complaints.versioned
            ship-hands.versioned
        ==
      %2  versioned(subscribers ~)
    ==
  =/  new-this  this(state migrated)
  =/  host=@p
    ?~  lobby-host.migrated
      ~nec
    u.lobby-host.migrated
  `new-this

::  ──────────────────────────────────────────────────────────────
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ~&  [%on-watch path src.bowl]
  ?+  path  (on-watch:def path)
    [%chat ~]
      ::  TODO operator gate — filter by parent star for production deployment
      =.  subscribers.state   (~(put in subscribers.state) src.bowl)
      =.  unique-ships.state  (~(put in unique-ships.state) src.bowl)
      [~ this]
    [%challenges ~]
      `this
  ==

::  ──────────────────────────────────────────────────────────────
++  on-leave
  |=  =path
  ^-  (quip card _this)
  ~&  [%on-leave path src.bowl]
  =.  subscribers.state   (~(del in subscribers.state) src.bowl)
  =.  unique-ships.state  (~(del in unique-ships.state) src.bowl)
  [~ this]

::  ──────────────────────────────────────────────────────────────
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)

    %poker-chat-action
      =/  action  !<(chat-action:poker vase)
      ?-  -.action
        %send
          ?.  (lte (met 3 text.action) 280)
            `this
          =/  bucket=rate-bucket
            %+  ~(gut by rate-buckets.state)  src.bowl
            [0 now.bowl]
          =/  elapsed=@dr  (sub now.bowl window-start.bucket)
          =.  bucket
            ?.  (gth elapsed ~s10)  bucket
            [0 now.bowl]
          ?.  (lth count.bucket 3)
            `this
          =.  bucket  bucket(count +(count.bucket))
          =.  rate-buckets.state  (~(put by rate-buckets.state) src.bowl bucket)
          =/  msg=chat-message:poker  [src.bowl now.bowl text.action]
          =.  messages.state  (snoc-capped messages.state msg 500)
          ~&  [%send-broadcast src=src.bowl subs=subscribers.state]
          =/  host=@p  (lobby-host-ship bowl lobby-host.state)
          ?.  =(our.bowl host)
            ::  not the host — forward to host via Ames
            :_  this
            [%pass /chat-fwd %agent [host %poker-lobby] %poke %poker-chat-action !>(`chat-action:poker`[%send text.action])]~
          ::  we are the host — store and broadcast
          =/  broadcast=card
            [%give %fact ~[/chat] %poker-chat-update !>(`chat-update:poker`[%message msg])]
          [[broadcast]~ this]

        %presence
          =/  update=chat-update:poker
            ?-  p.action
              %join   [%join src.bowl]
              %leave  [%leave src.bowl]
            ==
          =/  bc=card
            [%give %fact ~[/chat] %poker-chat-update !>(update)]
          [[bc]~ this]

        %report
          ?.  !=(src.bowl target.action)
            :_(this ~[[%give %fact ~[/chat] %poker-chat-update !>(`chat-update:poker`[%report-rejected target.action 'cannot report yourself'])]])
          ?.  (~(has in subscribers.state) target.action)
            :_(this ~[[%give %fact ~[/chat] %poker-chat-update !>(`chat-update:poker`[%report-rejected target.action 'target not in lobby'])]])
          ?.  (lte (met 3 memo.action) 280)
            :_(this ~[[%give %fact ~[/chat] %poker-chat-update !>(`chat-update:poker`[%report-rejected target.action 'memo too long'])]])
          =.  complaints.state  (record-complaint complaints.state target.action category.action)
          =/  ack=card
            [%give %fact ~[/chat] %poker-chat-update !>(`chat-update:poker`[%report-acked target.action category.action])]
          [[ack]~ this]
      ==

    %poker-challenge
      =/  c  !<(challenge:poker vase)
      ~&  [%poker-challenge-received src=src.bowl tag=-.c]
      ?-  -.c
        %propose
          ::  TODO operator gate — filter by parent star for production deployment
          ?.  =(~ pending-in.state)
            =/  busy-card=card
              [%pass /challenge-busy/(scot %p src.bowl) %agent [src.bowl %poker-lobby] %poke %poker-challenge-notify !>([%busy src.bowl])]
            [[busy-card]~ this]
          =.  pending-in.state
            ^-((unit [challenger=@p c=challenge:poker]) `[src.bowl `challenge:poker`c])
          =/  notify=card
            [%give %fact ~[/challenges] %poker-challenge-notify !>([%incoming src.bowl c])]
          =/  expiry=@da  (add now.bowl ~m5)
          =/  timer=card
            [%pass /challenge-expire/(scot %p src.bowl) %arvo [%b %wait expiry]]
          [~[notify timer] this]

        %accept
          =/  our-challenge  (~(get by pending-out.state) src.bowl)
          ?~  our-challenge
            `this
          ?.  ?=(%propose -.u.our-challenge)
            `this
          =.  pending-out.state  (~(del by pending-out.state) src.bowl)
          =/  room-id=@uv  room-id.c
          =/  prop  u.our-challenge
          =/  notice=card
            [%pass /lobby-host-notify %agent [(lobby-host-ship bowl lobby-host.state) %poker-lobby] %poke %poker-lobby-notice !>([%challenge-notice our.bowl src.bowl game.prop])]
          =/  cfg=game-config:poker
            :*  game=game.prop
                small-blind=small-blind.prop
                big-blind=big-blind.prop
                min-raise=min-raise.prop
                buy-in=buy-in.prop
                hands=hands.prop
                cap=cap.prop
            ==
          =/  spin-room=card
            [%pass /room/(scot %uv room-id) %agent [our.bowl %poker-room] %poke %poker-room-init !>([room-id src.bowl cfg our.bowl])]
          =/  nav=card
            [%give %fact ~[/challenges] %poker-challenge-notify !>(`challenge-notify:poker`[%accepted src.bowl])]
          [~[notice spin-room nav] this]

        %decline
          =.  pending-out.state  (~(del by pending-out.state) src.bowl)
          =/  notify=card
            [%give %fact ~[/challenges] %poker-challenge-notify !>([%declined src.bowl])]
          [[notify]~ this]

        %busy
          =/  notify=card
            [%give %fact ~[/challenges] %poker-challenge-notify !>([%busy src.bowl])]
          [[notify]~ this]
      ==

    %poker-challenge-action
      =/  act  !<(challenge-action:poker vase)
      ~&  [%poker-challenge-action-called tag=-.act]
      ?-  -.act
        %issue
          =/  expiry=@da  (add now.bowl ~m5)
          =/  c=challenge:poker
            :*  %propose
                game=%nlh
                small-blind=small-blind.terms.act
                big-blind=big-blind.terms.act
                min-raise=big-blind.terms.act
                buy-in=(mul big-blind.terms.act 50)
                hands=hands.terms.act
                cap=cap.terms.act
                expires=expiry
            ==
          =.  pending-out.state  (~(put by pending-out.state) target.act c)
          :_  this
          [%pass /challenge/(scot %p target.act) %agent [target.act %poker-lobby] %poke %poker-challenge !>(c)]~
        %accept  `this
        %decline  `this
        %cancel  `this
      ==

    %poker-send-challenge
      =/  payload  !<([target=@p config=game-config:poker] vase)
      ~&  [%poker-send-challenge-called target=target.payload]
      ::  TODO operator gate — filter by parent star for production deployment
      =/  expiry=@da  (add now.bowl ~m5)
      =/  c=challenge:poker
        :*  %propose
            game=game.config.payload
            small-blind=small-blind.config.payload
            big-blind=big-blind.config.payload
            min-raise=min-raise.config.payload
            buy-in=buy-in.config.payload
            hands=hands.config.payload
            cap=cap.config.payload
            expires=expiry
        ==
      =.  pending-out.state  (~(put by pending-out.state) target.payload c)
      =/  poke-target=card
        [%pass /challenge/(scot %p target.payload) %agent [target.payload %poker-lobby] %poke %poker-challenge !>(c)]
      [[poke-target]~ this]

    %poker-accept-challenge
      =/  challenger  !<(@p vase)
      =/  pin  pending-in.state
      ?~  pin   `this
      ?.  =(challenger challenger.u.pin)   `this
      =/  inc  c.u.pin
      ?.  ?=(%propose -.inc)  `this
      =/  room-id=@uv
        (mix (sham [our.bowl challenger now.bowl]) eny.bowl)
      =.  pending-in.state  ~
      =/  cancel-timer=card
        [%pass /challenge-expire/(scot %p challenger) %arvo [%b %rest expires.inc]]
      =/  accept-poke=card
        [%pass /challenge-accept/(scot %p challenger) %agent [challenger %poker-lobby] %poke %poker-challenge !>([%accept room-id])]
      =/  cfg=game-config:poker
        :*  game=game.inc
            small-blind=small-blind.inc
            big-blind=big-blind.inc
            min-raise=min-raise.inc
            buy-in=buy-in.inc
            hands=hands.inc
            cap=cap.inc
        ==
      =/  spin-room=card
        [%pass /room/(scot %uv room-id) %agent [our.bowl %poker-room] %poke %poker-room-init !>([room-id challenger cfg challenger])]
      =/  nav=card
        [%give %fact ~[/challenges] %poker-challenge-notify !>(`challenge-notify:poker`[%accepted challenger])]
      [~[cancel-timer accept-poke spin-room nav] this]

    %poker-decline-challenge
      =/  challenger  !<(@p vase)
      =/  pin  pending-in.state
      ?~  pin   `this
      ?.  =(challenger challenger.u.pin)  `this
      =/  inc  c.u.pin
      ?.  ?=(%propose -.inc)  `this
      =.  pending-in.state  ~
      =/  cancel-timer=card
        [%pass /challenge-expire/(scot %p challenger) %arvo [%b %rest expires.inc]]
      =/  decline-poke=card
        [%pass /challenge-decline/(scot %p challenger) %agent [challenger %poker-lobby] %poke %poker-challenge !>(`challenge:poker`[%decline ~])]
      [~[cancel-timer decline-poke] this]

    %poker-lobby-notice
      =/  notice  !<(chat-update:poker vase)
      ?+  -.notice  `this
        %challenge-notice
          =/  bc=card
            [%give %fact ~[/chat] %poker-chat-update !>(notice)]
          [[bc]~ this]
      ==

    %poker-lobby-game-complete
      ?>  =(src.bowl our.bowl)
      =.  games-played.state  +(games-played.state)
      =/  result=game-result-body:poker  !<(game-result-body:poker vase)
      =.  ship-hands.state
        %+  ~(put by ship-hands.state)  alice.result
        +((~(gut by ship-hands.state) alice.result 0))
      =.  ship-hands.state
        %+  ~(put by ship-hands.state)  bob.result
        +((~(gut by ship-hands.state) bob.result 0))
      `this

    %poker-lobby-set-host
      ?>  =(src.bowl our.bowl)
      =/  host  !<(@p vase)
      =.  lobby-host.state  `host
      `this

    %poker-decline-challenge
      ::  Legacy mark — ignore silently to avoid crash on old clients
      `this
  ==

::  ──────────────────────────────────────────────────────────────
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?.  ?=(%fact -.sign)  `this
  ?.  ?=(%poker-chat-update p.cage.sign)  `this
  [[%give %fact ~[/chat] %poker-chat-update q.cage.sign]~ this]

::  ──────────────────────────────────────────────────────────────
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire sign)
    ::  Deferred join broadcast — fires after cross-ship subscription is committed.
    ::  Guard against the ship having left before the timer fired.
    [%join-announce @ ~]
      =/  ship  (slav %p i.t.wire)
      ?.  (~(has in subscribers.state) ship)
        `this
      =/  join-card=card
        [%give %fact ~[/chat] %poker-chat-update !>(`chat-update:poker`[%join ship])]
      [[join-card]~ this]
    [%challenge-expire @ ~]
      =/  challenger  (slav %p i.t.wire)
      =/  pin  pending-in.state
      ?~  pin  `this
      ?.  =(challenger challenger.u.pin)  `this
      =.  pending-in.state  ~
      =/  notify=card
        [%give %fact ~[/challenges] %poker-challenge-notify !>([%timeout challenger])]
      [[notify]~ this]
  ==

::  ──────────────────────────────────────────────────────────────
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %ships ~]
      ``[%poker-lobby-count !>(~(wyt in unique-ships.state))]
    [%x %online ~]
      ``[%poker-lobby-count !>(~(wyt in subscribers.state))]
    [%x %games ~]
      ``[%poker-lobby-count !>(games-played.state)]
    [%x %pending-in ~]
      ``[%poker-lobby-pending !>(pending-in.state)]
    [%x %subscribers ~]
      ``[%poker-lobby-subscribers !>(subscribers.state)]
    [%x %complaints @ ~]
      =/  ship  (slav %p i.t.t.path)
      =/  result  (~(gut by complaints.state) ship *(map complaint-category:poker @ud))
      ``[%noun !>(result)]
    [%x %rep @ ~]
      =/  ship      (slav %p i.t.t.path)
      =/  hands     (~(gut by ship-hands.state) ship 0)
      =/  comp-map  (~(gut by complaints.state) ship *(map complaint-category:poker @ud))
      =/  total-complaints=@ud
        %+  roll  ~(val by comp-map)
        |=  [n=@ud acc=@ud]  (add acc n)
      ``[%noun !>([hands total-complaints 0])]
    [%x %max-hands ~]
      =/  max=@ud
        %+  roll  ~(val by ship-hands.state)
        |=  [n=@ud acc=@ud]
        ?:((gth n acc) n acc)
      ``[%poker-lobby-count !>(max)]

      ::  /x/poker-lobby/host — lobby host ship (for chat routing)
      [%x %host ~]
        =/  host  src.bowl
        ``[%json !>([%s (scot %p host)])]
    [%x %backlog ~]
      =/  recent=(list chat-message:poker)  (scag 20 messages.state)
      =/  msgs=(list json)
        %+  turn  (flop recent)
        |=  msg=chat-message:poker
        ^-  json
        :-  %o
        %-  malt
        :~  ['author' s+(scot %p author.msg)]
            ['timestamp' s+(scot %da timestamp.msg)]
            ['text' s+text.msg]
        ==
      ``[%json !>(a+msgs)]

  ==

++  on-fail   on-fail:def

--
