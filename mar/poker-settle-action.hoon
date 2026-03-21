::  /mar/poker-settle-action.hoon
::  Mark for peer-to-peer settlement pokes between %poker-settle instances.
::  Covers: %propose-settlement, %ack-result, %confirm-paid, %dispute,
::          %request-balance, %balance-response
/-  poker
|_  a=settle-action:poker
++  grab
  |%
  ++  noun  settle-action:poker
  --
++  grow
  |%
  ++  noun  a
  --
++  grad  %noun
--
