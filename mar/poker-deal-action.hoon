::  /mar/poker-deal-action.hoon
::  Mark for peer-to-peer deal protocol pokes between %poker-room instances.
::  Covers all deal-action variants: %mp-seed, %mp-enc-deck, %mp-partial-dec, etc.
/-  poker
|_  a=deal-action:poker
++  grab
  |%
  ++  noun  deal-action:poker
  --
++  grow
  |%
  ++  noun  a
  --
++  grad  %noun
--
