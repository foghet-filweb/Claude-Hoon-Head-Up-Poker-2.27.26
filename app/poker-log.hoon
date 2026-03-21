::  /app/poker-log.hoon
::
::  %poker-log: append-only hand transcript with hash chain.
::
::  Lifecycle:
::    - Spawned by %poker-room on hand start (%poker-log-init poke)
::    - Receives %log-record pokes from %poker-room on every event
::    - Posts each chain-head commitment to the blockchain bridge
::    - On %log-agree from both players: discards the preimage log
::    - On %log-dispute-raise from either player: assembles the full
::      dispute-payload and hands it to the blockchain bridge for
::      on-chain submission
::    - Self-terminates after agreement or dispute submission
::
::  Hash chain construction:
::    entry-hash_n  = sha256(room-id || seq_n || event_n)
::    chain-head_n  = sha256(chain-head_{n-1} || entry-hash_n)
::    genesis head  = sha256(room-id || alice || bob)
::
::  The blockchain sees only chain-head_n at each step (cheap).
::  The preimage log is held in agent state and discarded on agreement.
::  On dispute, the full entry list is sent so the chain can re-derive
::  and verify every head.
::
/-  poker
/+  default-agent
::
|%
+$  state-0
  $:  %0
      =log-state:poker
      alice=@p
      bob=@p
  ==
+$  card  card:agent:gall
--
::
=|  state-0
=*  state  -
::
|%
::  ──────────────────────────────────────────────────────────────
::  Internal arms
::  ──────────────────────────────────────────────────────────────

::  ++handle-record: append an event to the chain
++  handle-record
  |=  [=bowl:gall ss=state-0 event=log-event:poker]
  ^-  (quip card state-0)
  =/  ls   log-state.ss
  =/  seq  seq.ls
  =/  rid  room-id.ls
  =/  entry-hash=commitment:poker
    (shax (jam [rid seq event]))
  =/  new-head=commitment:poker
    (shax (jam [chain-head.ls entry-hash]))
  =/  entry=log-entry:poker
    :*  room-id=rid
        seq=seq
        timestamp=now.bowl
        event=event
        entry-hash=entry-hash
        chain-head=new-head
    ==
  =.  log-state.ss
    %_  ls
      entries     [entry entries.ls]
      chain-head  new-head
      seq         +(seq)
    ==
  =/  post  (post-commitment bowl new-head rid +(seq))
  [[post]~ ss]

::  ++handle-agree: one player signals the outcome is correct
::  When both have agreed, discard the preimage log and self-destruct.
++  handle-agree
  |=  [=bowl:gall ss=state-0 who=@p]
  ^-  (quip card state-0)
  =/  ls  log-state.ss
  ~|  'poker-log: agree from unknown ship'
  ?>  ?|(=(who alice.ss) =(who bob.ss))
  =.  log-state.ss
    ?:  =(who alice.ss)
      ls(alice-agreed %.y)
    ls(bob-agreed %.y)
  ?.  &(alice-agreed.log-state.ss bob-agreed.log-state.ss)
    `ss
  ::  Both agreed — discard log and self-destruct.
  ::
  ::  TODO-BLOCKCHAIN-002: On agreement, notify the blockchain that
  ::  this room-id resolved without dispute so any gas/bond held
  ::  in escrow can be released. The specific call depends on the
  ::  contract interface (e.g. calling settle() vs. letting the
  ::  commitment TTL expire naturally).
  [[self-destruct]~ ss]

::  ++handle-dispute: a player contests the outcome
::  Assembles the full dispute-payload and sends to the bridge.
++  handle-dispute
  |=  [=bowl:gall ss=state-0 who=@p reason=cord]
  ^-  (quip card state-0)
  =/  ls  log-state.ss
  ~|  'poker-log: dispute from unknown ship'
  ?>  ?|(=(who alice.ss) =(who bob.ss))
  =.  disputed.log-state.ss  %.y
  =/  dispute-event=log-event:poker
    [%log-dispute who reason]
  =^  record-cards  ss  (handle-record bowl ss dispute-event)
  =/  payload=dispute-payload:poker
    :*  room-id=room-id.ls
        alice=alice.ss
        bob=bob.ss
        entries=(flop entries.ls)
        final-chain-head=chain-head.log-state.ss
        alice-final-sig=alice-final-sig.ls
        bob-final-sig=bob-final-sig.ls
        disputing-party=who
        dispute-reason=reason
        config=config.ls
    ==
  =/  submit  (submit-dispute bowl payload)
  [(weld record-cards [submit]~) ss]

::  ──────────────────────────────────────────────────────────────
::  Blockchain bridge stubs
::  ──────────────────────────────────────────────────────────────
::
::  These arms are the ONLY points where chain-specific code lives.
::  Every TODO-BLOCKCHAIN tag below maps to a line in BLOCKCHAIN-TODO.md.
::
::  The stubs currently produce no-op cards (poke to %poker-log-bridge).
::  When a chain is identified, replace the stub body with the
::  appropriate transaction construction and submission logic.

::  ++post-commitment: post a chain-head hash to the blockchain
::  Called after every event. On-chain footprint: one hash per event.
++  post-commitment
  |=  [=bowl:gall head=commitment:poker room-id=@uv seq=@ud]
  ^-  card
  ::
  ::  TODO-BLOCKCHAIN-003: Construct and submit a transaction that
  ::  records `head` on-chain for `room-id` at sequence `seq`.
  ::
  ::  The on-chain record should store at minimum:
  ::    - room-id  (@uv → bytes32)
  ::    - seq      (@ud → uint256)
  ::    - head     (@ux → bytes32)
  ::    - block timestamp (chain-supplied)
  ::
  ::  Example shape for an EVM target:
  ::    contract.commitHead(room_id, seq, head)
  ::
  ::  Example shape for a UTXO target:
  ::    OP_RETURN <room-id><seq><head>
  ::
  ::  TODO-BLOCKCHAIN-004: Determine gas/fee strategy.
  ::  Options: alice pre-funds, both split, fee relay via bridge ship.
  ::
  ::  TODO-BLOCKCHAIN-005: Determine the bridge mechanism.
  ::  Options:
  ::    (a) An Urbit ship running a signing daemon with a funded wallet
  ::    (b) A browser wallet (MetaMask etc.) injected via the front-end
  ::    (c) A relay service that accepts signed payloads over HTTP
  ::  The card produced here must match whichever bridge is chosen.
  ::
  ::  STUB — no-op until bridge is implemented:
  [%pass /blockchain/commit %agent [our.bowl %poker-log-bridge] %poke %poker-bridge-commit !>([room-id seq head])]

::  ++submit-dispute: submit full preimage transcript to blockchain
::  Called only on dispute. Contains all event preimages for verification.
++  submit-dispute
  |=  [=bowl:gall payload=dispute-payload:poker]
  ^-  card
  ::
  ::  TODO-BLOCKCHAIN-006: Construct and submit a dispute transaction.
  ::
  ::  The on-chain verifier must:
  ::    1. Re-derive every chain-head from the entry preimages
  ::    2. Verify the final derived head matches final-chain-head
  ::    3. Verify alice-final-sig and bob-final-sig over final-chain-head
  ::    4. Interpret the event log to determine the correct outcome
  ::    5. Adjudicate: award pot to the correct party or slash the
  ::       cheating party
  ::
  ::  TODO-BLOCKCHAIN-007: Define adjudication rules on-chain.
  ::  The contract (or equivalent) must encode what constitutes a
  ::  valid dispute vs. a frivolous one, and what the penalty for
  ::  the losing party is. This is game-theory territory:
  ::    - Frivolous dispute penalty (to deter spam)
  ::    - Cheating confirmation penalty (slashing / forfeiture)
  ::    - Timeout handling if a party goes offline during dispute
  ::
  ::  TODO-BLOCKCHAIN-008: Decide whether dispute submission is
  ::  submitted by the disputing party directly, or via a neutral
  ::  relay. A neutral relay prevents the other party from front-running
  ::  the dispute transaction (e.g. submitting a conflicting tx first).
  ::
  ::  TODO-BLOCKCHAIN-009: Define the data encoding for the payload.
  ::  The full entry list may be large. Options:
  ::    (a) Submit all entries in one transaction (simple, costly)
  ::    (b) Submit entries in batches with a Merkle root
  ::    (c) Submit only the final head + sigs; store entries in
  ::        a content-addressed store (IPFS, Arweave) with the
  ::        CID posted on-chain
  ::  For a two-player game, option (a) is likely acceptable;
  ::  a typical hand has fewer than 30 events.
  ::
  ::  STUB — no-op until bridge is implemented:
  [%pass /blockchain/dispute %agent [our.bowl %poker-log-bridge] %poke %poker-bridge-dispute !>(payload)]

::  ──────────────────────────────────────────────────────────────
::  Infrastructure
::  ──────────────────────────────────────────────────────────────

++  self-destruct
  ^-  card
  [%give %kick ~[/log] ~]
--

^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
::
::  ──────────────────────────────────────────────────────────────
++  on-init   `this
++  on-save   !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  `this(state !<(state-0 old))
::
::  ──────────────────────────────────────────────────────────────
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
    ::  Initialise the log for a new hand
    %poker-log-init
      =/  init  !<([room-id=@uv alice=@p bob=@p config=game-config:poker] vase)
      =/  genesis=commitment:poker
        (shax (jam [room-id.init alice.init bob.init]))
      =/  new-log=log-state:poker
        :*  room-id=room-id.init
            alice=alice.init
            bob=bob.init
            config=config.init
            entries=~
            chain-head=genesis
            seq=0
            alice-agreed=%.n
            bob-agreed=%.n
            alice-final-sig=0x0
            bob-final-sig=0x0
            disputed=%.n
        ==
      =.  state  [%0 new-log alice.init bob.init]
      =/  genesis-post  (post-commitment bowl genesis room-id.init 0)
      [[genesis-post]~ this]
    ::  Record a new event from %poker-room
    %poker-log-action
      =/  act  !<(log-action:poker vase)
      ?-  -.act
        %log-record
          =^  cards  state  (handle-record bowl state log-event.act)
          [cards this]
        %log-agree
          =^  cards  state  (handle-agree bowl state src.bowl)
          [cards this]
        %log-dispute-raise
          =^  cards  state  (handle-dispute bowl state src.bowl reason.act)
          [cards this]
      ==
  ==
::
++  on-agent  |=([=wire =sign:agent:gall] (on-agent:def wire sign))
++  on-arvo   |=([=wire s=sign-arvo] (on-arvo:def wire s))
++  on-watch  |=([=path] `this)
++  on-leave  on-leave:def
++  on-peek   |=(=path ~)
++  on-fail   on-fail:def
::

--
