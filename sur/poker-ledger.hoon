::  /sur/poker-ledger.hoon
::  Per-hand FHLO accounting types (CC session Apr 13)
::
|%
+$  fhlo  @ud    ::  FHLO base units (like satoshis)

+$  ship-ledger
  $:  cap=fhlo           ::  initial buy-in this game
      balance=fhlo       ::  current in-game chip count
      winnings=fhlo      ::  gross chips won (before rake deduction)
      losses=fhlo        ::  chips lost in pots
      rake-paid=fhlo     ::  cumulative rake charged
  ==

+$  hand-record
  $:  id=@ud
      game-id=@ud
      hand-num=@ud
      winner=ship
      loser=ship
      pot=fhlo
      loser-bet=fhlo     ::  loser's contribution to the pot
      rake=fhlo
      winner-net=fhlo    ::  pot - rake
      when=@da
  ==

+$  game-ledger
  $:  game-id=@ud
      players=(map ship ship-ledger)
      hands=(list hand-record)
      next-hand-id=@ud
      settled=?
  ==

+$  ledger-db  (map @ud game-ledger)

+$  ledger-action
  $%  [%open-game game-id=@ud p1=ship p2=ship cap=fhlo]
      [%record-hand game-id=@ud hand-num=@ud winner=ship loser=ship pot=fhlo loser-bet=fhlo]
      [%close-game game-id=@ud]
  ==
--
