::  /mar/poker-bridge-dispute.hoon
::  Mark for full dispute-payload pokes to %poker-log-bridge.
::
::  TODO-BLOCKCHAIN-012: Add grow arms for chain-native encoding
::  when the bridge agent is implemented.
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
