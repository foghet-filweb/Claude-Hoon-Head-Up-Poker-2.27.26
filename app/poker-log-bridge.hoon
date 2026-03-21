::  /app/poker-log-bridge.hoon
::
::  %poker-log-bridge: blockchain bridge stub.
::
::  This agent receives two poke types from %poker-log:
::    %poker-bridge-commit  — a per-event chain-head hash to post on-chain
::    %poker-bridge-dispute — a full dispute payload for on-chain submission
::
::  Currently a no-op stub. Both poke types are accepted and logged
::  to the dojo so the desk does not crash, but no chain transaction
::  is constructed or submitted.
::
::  When a blockchain target is identified, replace the handlers below
::  with real transaction construction and submission logic.
::  See BLOCKCHAIN-TODO.md items 003–012 for the full checklist.
::
::  TODO-BLOCKCHAIN-005: Replace this stub with a real bridge agent.
::
/-  poker
/+  default-agent
::
|%
+$  state-0  [%0 ~]
+$  card  card:agent:gall
--
::
=|  state-0
=*  state  -
::
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
::
++  on-init   `this
++  on-save   !>(state)
++  on-load   |=(old=vase `this(state !<(state-0 old)))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
    ::  Per-event chain-head commitment
    ::  TODO-BLOCKCHAIN-003: construct and submit chain transaction here
    %poker-bridge-commit
      =/  commit  !<([room-id=@uv seq=@ud head=commitment:poker] vase)
      ~>  %slog.[0 leaf+"poker-log-bridge: commit stub room={<room-id.commit>} seq={<seq.commit>}"]
      `this
    ::  Full dispute payload submission
    ::  TODO-BLOCKCHAIN-006: construct and submit dispute transaction here
    %poker-bridge-dispute
      =/  payload  !<(dispute-payload:poker vase)
      ~>  %slog.[0 leaf+"poker-log-bridge: dispute stub room={<room-id.payload>} party={<disputing-party.payload>}"]
      `this
  ==
::
++  on-agent  |=([=wire =sign:agent:gall] (on-agent:def wire sign))
++  on-arvo   |=([=wire s=sign-arvo] (on-arvo:def wire s))
++  on-watch  |=([=path] `this)
++  on-leave  on-leave:def
++  on-peek   |=(=path ~)
++  on-fail   on-fail:def
--
