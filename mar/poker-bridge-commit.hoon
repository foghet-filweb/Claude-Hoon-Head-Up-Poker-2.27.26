::  /mar/poker-bridge-commit.hoon
::  Mark for per-event chain-head commitment pokes to %poker-log-bridge.
::  Payload: [room-id=@uv seq=@ud head=commitment:poker]
::
::  TODO-BLOCKCHAIN-011: Add grow arms for chain-native encoding
::  when the bridge agent is implemented.
/-  poker
|%
+$  bridge-commit  [room-id=@uv seq=@ud head=commitment:poker]
--
|_  c=bridge-commit
++  grab
  |%
  ++  noun  bridge-commit
  --
++  grow
  |%
  ++  noun  c
  --
++  grad  %noun
--
