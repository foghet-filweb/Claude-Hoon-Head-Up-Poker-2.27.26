::  /mar/poker-log-dispute.hoon
::  Mark for the full dispute-payload sent to %poker-log-bridge.
::
::  TODO-BLOCKCHAIN-010: When the bridge agent is implemented,
::  this mark may need grow arms for the target chain's encoding.
/-  poker
|_  p=dispute-payload:poker
++  grab
  |%
  ++  noun  dispute-payload:poker
  --
++  grow
  |%
  ++  noun  p
  --
++  grad  %noun
--
