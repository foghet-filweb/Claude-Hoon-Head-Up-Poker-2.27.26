::  /sur/poker.hoon
::
::  Shared type definitions for Fhloston Poker.
::  Imported by %poker-lobby, %poker-room, and all related agents.
::  Target: Zuse 409 / Urbit 4.3
::
|%
::  ────────────────────────────────────────────────
::  Game types
::  ────────────────────────────────────────────────

::  +$ game-type: the variant of poker being played
::    %nlh  No Limit Hold'em
::    %plo  Pot Limit Omaha
::    %fcd  5-Card Draw
+$  game-type  ?(%nlh %plo %fcd)

::  +$ game-config: parameters agreed upon at challenge time
::
::    Session termination: at least one of hands or cap must be set.
::    The room dissolves when either threshold is first reached.
::      hands: maximum number of hands to be played this session
::      cap:   maximum total chips wagered across the session (both players combined)
+$  game-config
  $:  game=game-type
      small-blind=@ud
      big-blind=@ud
      min-raise=@ud
      buy-in=@ud
      hands=(unit @ud)
      cap=(unit @ud)
  ==

::  +$ street: betting round in Hold'em / Omaha
+$  street  ?(%preflop %flop %turn %river %showdown)

::  +$ action: a player's betting action
+$  action
  $%  [%fold ~]
      [%check ~]
      [%call ~]
      [%raise amount=@ud]
      [%all-in ~]
  ==

::  +$ hand-rank: standard poker hand rankings
+$  hand-rank
  $?  %high-card
      %one-pair
      %two-pair
      %three-of-a-kind
      %straight
      %flush
      %full-house
      %four-of-a-kind
      %straight-flush
      %royal-flush
  ==

::  ────────────────────────────────────────────────
::  Deal protocol types (protocol-agnostic)
::  ────────────────────────────────────────────────

::  +$ deal-method: which protocol is in use this game
+$  deal-method
  $%  [%mental-poker prime=@ud]
      [%dealer-ship dealer=@p]
  ==

::  +$ entropy: 256-bit random atom contributed by each player
+$  entropy  @uv

::  +$ commitment: SHA-256 hash binding a value before reveal
+$  commitment  @ux

::  +$ enc-card: an SRA-encrypted card atom
+$  enc-card  @ux

::  +$ enc-deck: the full 52-card encrypted deck
+$  enc-deck  (list enc-card)

::  +$ partial-dec: one player's partial decryption of a card
+$  partial-dec
  $:  idx=@ud
      val=enc-card
  ==

::  +$ audit-record: published post-game for full verifiability
+$  audit-record
  $:  room-id=@uv
      method=deal-method
      deck=(list @ud)
      alice-key=@ud
      bob-key=@ud
      deck-commit=commitment
  ==

::  ────────────────────────────────────────────────
::  Room state machine
::  ────────────────────────────────────────────────

::  +$ actor: whose turn it is to act
+$  actor  ?(%alice %bob)

::  +$ street-status: state of betting within a street
::
::    Heads-up NLH turn order:
::      alice = dealer = small blind (BTN)
::      bob   = non-dealer = big blind
::
::    Preflop:  alice (dealer/SB) acts first; bob (BB) acts last.
::              Bob's BB is a live bet — he may raise even if alice calls.
::    Postflop: bob (non-dealer/BB) acts first; alice (dealer/SB) acts last.
::
::    A street ends when:
::      - One player folds                      → hand over
::      - Both players check                    → advance
::      - One player calls after a raise/bet    → advance
::      - One or both players go all-in         → advance to showdown
+$  street-status
  $:  actor=actor
      last-aggressor=(unit actor)
      alice-acted=?
      alice-all-in=?
      bob-all-in=?
  ==

::  +$ deal-phase: enforced sequence for the deal sub-protocol
+$  deal-phase
  $%  $:  %awaiting-seeds
          alice-seed=(unit entropy)
          bob-seed=(unit entropy)
      ==
      [%alice-encrypting ~]
      $:  %bob-reencrypting
          enc-deck=enc-deck
          alice-commit=commitment
      ==
      $:  %dealing
          dbl-enc-deck=enc-deck
          alice-positions=(list @ud)
          bob-positions=(list @ud)
          community-positions=(list @ud)
      ==
      $:  %live
          =street
          =street-status
      ==
      $:  %revealing
          =street
          pending=(list @ud)
      ==
      [%awaiting-audit winner=@p]
      [%audited audit=audit-record]
  ==

::  +$ room-state: full state of a %poker-room agent instance
+$  room-state
  $:  room-id=@uv
      peer=@p
      dealer=@p
      config=game-config
      method=deal-method
      phase=deal-phase
      our-stack=@ud
      peer-stack=@ud
      pot=@ud
      our-bet=@ud
      peer-bet=@ud
      our-key=(unit [e=@ud d=@ud p=@ud])
      our-hand=(list @ud)
      community=(list @ud)
      pending-community=(map @ud enc-card)
      dbl-enc-deck=enc-deck
      our-positions=(list @ud)
      timeout-wire=wire
      deck-commit=commitment
      hands-played=@ud
      total-wagered=@ud
  ==

::  ────────────────────────────────────────────────
::  Poke marks (deal phase)
::  ────────────────────────────────────────────────

::  +$ deal-action: pokes exchanged between the two room agents
+$  deal-action
  $%  ::  ── Mental Poker ──────────────────────────────────────
      ::  Step 0: both ships → each other (simultaneously)
      ::  Exchange entropy seeds before Alice starts encrypting.
      $:  %mp-seed
          seed=entropy
      ==
      ::  Step 1: Alice → Bob
      ::  Alice sends her-encrypted, shuffled deck + commitment
      $:  %mp-enc-deck
          deck=enc-deck
          commit=commitment
      ==
      ::  Step 2: Bob → Alice
      ::  Bob re-encrypts each card, returns doubly-encrypted deck
      $:  %mp-reenc-deck
          deck=enc-deck
      ==
      ::  Step 3+: either player → other
      ::  Partial decrypt of assigned card positions
      $:  %mp-partial-dec
          cards=(list partial-dec)
      ==
      ::  Post-game: both players publish their SRA decryption key
      $:  %mp-reveal-key
          key=@ud
          commit-proof=commitment
      ==
      ::  ── Dealer Ship ───────────────────────────────────────
      ::  Player → dealer: submit entropy + public key
      $:  %ds-seed
          seed=entropy
          pubkey=@ux
      ==
      ::  Dealer → player: encrypted hand + deck commitment
      $:  %ds-deal
          deck-hash=commitment
          hand=(list enc-card)
      ==
      ::  Player → dealer: request community card reveal
      $:  %ds-reveal-request
          street=street
      ==
      ::  Dealer → both players: community cards for a street
      $:  %ds-community
          street=street
          cards=(list @ud)
          proof=commitment
      ==
      ::  ── Shared ────────────────────────────────────────────
      [%abort reason=cord]
      [%timeout ~]
      ::  Community card partial-decrypt for a street reveal.
      ::  Each player sends this once per street.
      $:  %mp-community
          =street
          cards=(list partial-dec)
      ==
      ::  Betting action forwarded peer-to-peer
      $:  %street-action
          =action
      ==
      [%street-complete =street]
  ==

::  ────────────────────────────────────────────────
::  Room update facts
::  ────────────────────────────────────────────────

::  +$ room-update: facts sent from %poker-room to the front-end
+$  room-update
  $%  [%hand-dealt p=@p hand=(list @ud)]
      $:  %your-turn
          =street
          =street-status
          pot=@ud
          to-call=@ud
          min-raise=@ud
          small-blind=@ud
          big-blind=@ud
      ==
      $:  %peer-acted
          =action
          =street-status
          pot=@ud
          to-call=@ud
          peer-bet=@ud
      ==
      [%community-dealt =street cards=(list @ud)]
      $:  %street-started
          =street
          =street-status
          pot=@ud
          to-call=@ud
          min-raise=@ud
      ==
      [%hand-complete alice-result=* bob-result=* outcome=*]
      [%game-audited audit=audit-record]
      [%player-folded ship=@p]
      [%fold-complete winner=@p our-stack=@ud peer-stack=@ud]
      [%key-revealed peer=@p]
      [%timeout-forfeit winner=@p]
      [%session-over reason=?(%hands-limit %cap-limit) hands-played=@ud total-wagered=@ud]
  ==

::  ────────────────────────────────────────────────
::  Lobby types
::  ────────────────────────────────────────────────

::  +$ chat-message: a single lobby chat message
+$  chat-message
  $:  author=@p
      timestamp=@da
      text=cord
  ==

::  +$ complaint-category: reason for a chat complaint
+$  complaint-category
  $%  [%slow-play ~]
      [%abusive-language ~]
      [%premature-disconnect ~]
      [%failure-to-pay ~]
  ==

::  +$ chat-action: poke mark for lobby chat
+$  chat-action
  $%  [%send text=cord]
      [%presence p=?(%join %leave)]
      $:  %report
          target=@p
          category=complaint-category
          memo=cord
      ==
  ==

::  +$ challenge-action: poke mark for browser challenge actions
+$  challenge-action
  $%  [%issue target=@p terms=game-config]
      [%accept id=@ud]
      [%decline id=@ud]
      [%cancel id=@ud]
  ==

::  +$ challenge-notify: fact mark broadcast by lobby host on /challenges
+$  challenge-notify
  $%  [%incoming challenger=@p c=challenge]
      [%accepted challenger=@p]
      [%declined challenger=@p]
      [%busy challenger=@p]
      [%timeout challenger=@p]
  ==

::  +$ chat-update: fact mark broadcast by lobby host
+$  chat-update
  $%  [%message =chat-message]
      [%join ship=@p]
      [%leave ship=@p]
      [%challenge-notice challenger=@p target=@p game=game-type]
      [%report-acked target=@p category=complaint-category]
      [%report-rejected target=@p reason=cord]
  ==

::  +$ challenge: direct ship-to-ship challenge poke
+$  challenge
  $%  ::  Challenger → target: propose a game with specific terms.
      ::  At least one of hands or cap must be set (unit not ~).
      $:  %propose
          game=game-type
          small-blind=@ud
          big-blind=@ud
          min-raise=@ud
          buy-in=@ud
          hands=(unit @ud)
          cap=(unit @ud)
          expires=@da
      ==
      [%accept room-id=@uv]
      [%decline ~]
      [%busy ~]
  ==

::  ────────────────────────────────────────────────
::  Settlement types
::  ────────────────────────────────────────────────

::  +$ game-result-body: the fields both players sign
+$  game-result-body
  $:  room-id=@uv
      alice=@p
      bob=@p
      winner=@p
      amount=@ud
      timestamp=@da
  ==

::  +$ game-result: a fully signed game outcome
+$  game-result
  $:  room-id=@uv
      alice=@p
      bob=@p
      winner=@p
      amount=@ud
      timestamp=@da
      audit=audit-record
      alice-sig=@ux
      bob-sig=@ux
  ==

::  ────────────────────────────────────────────────
::  Dispute log types
::  ────────────────────────────────────────────────
::
::  Design: commit-reveal hash chain.
::
::  Every event in a hand produces a log-entry. Each entry is
::  hashed together with the previous chain head to form a new
::  chain head:
::
::    head_n = sha256(head_{n-1} || sha256(entry_n))
::
::  The chain head after every event is posted to the blockchain
::  as a cheap hash commitment. Preimages are held off-chain and
::  discarded on agreement. On dispute, preimages are revealed
::  and the chain re-derives each head for verification.

::  +$ log-event: every distinct recordable event in a hand
+$  log-event
  $%  ::  ── Deal protocol ─────────────────────────────────────────
      $:  %log-seeds
          alice-seed=entropy
          bob-seed=entropy
          combined-commit=commitment
      ==
      $:  %log-enc-deck
          =commitment
      ==
      $:  %log-reenc-deck
          reenc-commit=commitment
      ==
      $:  %log-partial-dec
          who=actor
          positions=(list @ud)
          partial-commit=commitment
      ==
      $:  %log-community
          =street
          card-commit=commitment
      ==
      ::  ── Betting ───────────────────────────────────────────────
      $:  %log-blind
          who=actor
          amount=@ud
      ==
      $:  %log-action
          who=actor
          =action
          =street
          pot-after=@ud
      ==
      ::  ── Hand resolution ───────────────────────────────────────
      $:  %log-showdown
          alice-hole-commit=commitment
          bob-hole-commit=commitment
          board-commit=commitment
      ==
      $:  %log-award
          winner=@p
          amount=@ud
          by-fold=?
      ==
      $:  %log-audit-keys
          alice-d=@ud
          bob-d=@ud
      ==
      $:  %log-dispute
          who=@p
          reason=cord
      ==
  ==

::  +$ log-entry: a single entry in the hand transcript
+$  log-entry
  $:  room-id=@uv
      seq=@ud
      timestamp=@da
      event=log-event
      entry-hash=commitment
      chain-head=commitment
  ==

::  +$ log-state: full state held by %poker-log
+$  log-state
  $:  room-id=@uv
      alice=@p
      bob=@p
      config=game-config
      entries=(list log-entry)
      chain-head=commitment
      seq=@ud
      alice-agreed=?
      bob-agreed=?
      alice-final-sig=@ux
      bob-final-sig=@ux
      disputed=?
  ==

::  +$ dispute-payload: everything needed for blockchain submission
::
::  TODO-BLOCKCHAIN-001: The blockchain target determines what
::  additional fields (chain ID, contract address, nonce, gas)
::  must be appended to this payload before submission.
+$  dispute-payload
  $:  room-id=@uv
      alice=@p
      bob=@p
      entries=(list log-entry)
      final-chain-head=commitment
      alice-final-sig=@ux
      bob-final-sig=@ux
      disputing-party=@p
      dispute-reason=cord
      config=game-config
  ==

::  +$ log-action: pokes sent to %poker-log from %poker-room
+$  log-action
  $%  $:  %log-record
          =log-event
      ==
      [%log-agree ~]
      $:  %log-dispute-raise
          reason=cord
      ==
  ==

::  ════════════════════════════════════════════════════════════
::  Settlement types (%poker-settle)
::  ════════════════════════════════════════════════════════════

::  +$ settle-mode: play money vs real stakes
+$  settle-mode  ?(%play %real)

::  +$ settle-balance: signed IOU balance between two players
+$  settle-balance  @s

::  +$ iou-entry: one game's contribution to the per-peer IOU ledger
+$  iou-entry
  $:  room-id=@uv
      delta=settle-balance
      timestamp=@da
      result=game-result
  ==

::  +$ settle-action: poke mark exchanged between %poker-settle instances
+$  settle-action
  $%  $:  %propose-settlement
          result=game-result
          memo=cord
      ==
      [%ack-result room-id=@uv]
      [%confirm-paid room-id=@uv memo=cord]
      $:  %dispute
          room-id=@uv
          reason=cord
          evidence=@ux
      ==
      [%request-balance ~]
      $:  %balance-response
          net=settle-balance
          entries=(list iou-entry)
      ==
  ==

::  +$ settle-update: fact mark broadcast by %poker-settle on /updates
+$  settle-update
  $%  [%awaiting-settlement peer=@p amount=@ud room-id=@uv]
      [%settlement-proposed peer=@p amount=@ud room-id=@uv]
      [%settlement-received peer=@p amount=@ud room-id=@uv]
      [%settlement-acked peer=@p room-id=@uv]
      [%payment-confirmed peer=@p room-id=@uv memo=cord]
      [%dispute-raised peer=@p room-id=@uv]
      [%dispute-received peer=@p room-id=@uv reason=cord]
      [%ledger-divergence peer=@p our=settle-balance theirs=settle-balance]
      [%keys-received life=@ud]
      [%sig-failed room-id=@uv reason=cord]
  ==

::  ════════════════════════════════════════════════════════════
::  SLAB token types (%slab-mint / %poker-settle)
::  ════════════════════════════════════════════════════════════

::  +$ slab-entry: a signed chip issuance record delivered to a planet
+$  slab-entry
  $:  amount=@ud
      issuer=@p
      issued-at=@da
      sig=@ux
      transferable=?
  ==

::  +$ mint-action: poke mark for %slab-mint
+$  mint-action
  $%  [%claim ~]
      [%gift ship=@p]
      [%set-allocation amount=@ud]
      [%set-paused paused=?]
      [%set-lobby-host ship=@p]
      [%transfer target=@p amount=@ud]
  ==

::  +$ mint-update: fact mark broadcast by %slab-mint on /updates
+$  mint-update
  $%  [%claimed ship=@p amount=@ud]
      [%gifted ship=@p amount=@ud]
      [%rejected ship=@p reason=cord]
      [%allocation-changed amount=@ud]
      [%paused paused=?]
      [%keys-received life=@ud]
      [%cap-reached ship=@p total=@ud cap=@ud]
  ==
--
