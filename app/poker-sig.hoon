::  /lib/poker-sig.hoon
::
::  Jael-backed Ed25519 signing and verification for Fhloston Poker game results.
::
::  KEY ARCHITECTURE INSIGHT:
::  Private keys cannot be scried synchronously from a Gall agent.
::  They arrive as a %private-keys gift from Jael in response to a
::  [%pass /wire %arvo %j %private-keys ~] task. %poker-settle
::  sends this task on on-init, caches the ring in its state, and
::  calls ++sign-body / ++verify-body from this library.
::
::  Public keys for peers ARE available via synchronous scry:
::    .^([=life =pass sig=(unit @ux)] %j /our/deed/ship/life)
::  We first scry %lyfe to get the (unit @ud) life safely, then
::  use %deed to get the pass at that life.
::
::  The message signed is: sha256(jam(game-result-body))
::  This is deterministic, compact, and collision-resistant.
::
/-  poker
|%

::  ++sign-body: produce Ed25519 signature over a result body.
::  Caller passes the ring (private key atom) cached from Jael.
++  sign-body
  |=  [body=game-result-body:poker =ring]
  ^-  @ux
  =/  cub  (nol:nu:crub:crypto ring)
  =/  msg=@  (shax (jam body))
  (sign:as:cub msg)

::  ++verify-body: verify a peer's Ed25519 signature.
::  Scries Jael synchronously for the peer's public key.
::  Returns %.n (rather than crashing) when peer is unknown to Jael.
++  verify-body
  |=  [=bowl:gall ship=@p sig=@ux body=game-result-body:poker]
  ^-  ?
  =/  peer-life=(unit @ud)
    .^((unit @ud) %j /(scot %p our.bowl)/lyfe/(scot %p ship))
  ?~  peer-life
    ~&  [%poker-sig %unknown-ship ship]
    %.n
  =/  deed  .^([=life =pass sig=(unit @ux)] %j /(scot %p our.bowl)/deed/(scot %p ship)/(scot %ud u.peer-life))
  =/  cub  (com:nu:crub:crypto pass.deed)
  =/  msg=@  (shax (jam body))
  =/  result=(unit @)  (sure:as:cub sig)
  ?~  result  %.n
  =(msg u.result)

::  ++attach-sig: sign a result and write our sig into the correct field
++  attach-sig
  |=  [result=game-result:poker =ring our=@p]
  ^-  game-result:poker
  =/  body  (result-body result)
  =/  sig=@ux  (sign-body body ring)
  ?:  =(our alice.result)
    result(alice-sig sig)
  result(bob-sig sig)

::  ++verify-both: verify that alice and bob both signed correctly
++  verify-both
  |=  [=bowl:gall result=game-result:poker]
  ^-  ?
  =/  body  (result-body result)
  =/  alice-ok  (verify-body bowl alice.result alice-sig.result body)
  =/  bob-ok    (verify-body bowl bob.result bob-sig.result body)
  &(alice-ok bob-ok)

::  ++result-body: extract the signable fields from a game-result
++  result-body
  |=  r=game-result:poker
  ^-  game-result-body:poker
  [room-id.r alice.r bob.r winner.r amount.r timestamp.r]
--
