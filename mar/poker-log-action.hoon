::  /mar/poker-log-action.hoon
::  Mark for %poker-room → %poker-log event pokes.
::  Covers: %log-record, %log-agree, %log-dispute-raise
/-  poker
|_  a=log-action:poker
++  grab
  |%
  ++  noun  log-action:poker
  --
++  grow
  |%
  ++  noun  a
  --
++  grad  %noun
--
