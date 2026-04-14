::  /sur/poker-escrow.hoon
::  Escrow types for Fhloston Poker (CC session Apr 13)
::
/-  *poker-ledger
|%
+$  wallet-addr  @t          ::  "0x..." ETH address as cord

+$  escrow-status
  ?(%awaiting-wallets %locked %released %returned %disputed)

+$  player-stake
  $:  who=ship
      wallet=(unit wallet-addr)
      amount=@ud              ::  in FHLO base units
      submitted=?
  ==

+$  escrow-entry
  $:  id=@ud
      game-id=@ud
      p1=player-stake
      p2=player-stake
      status=escrow-status
      winner=(unit ship)
      when-locked=(unit @da)
      when-settled=(unit @da)
  ==

+$  escrow-db  (map @ud escrow-entry)

+$  escrow-action
  $%  [%open game-id=@ud p1=ship p2=ship amount=@ud]
      [%submit-wallet game-id=@ud wallet=wallet-addr]
      [%release game-id=@ud winner=ship]
      [%return game-id=@ud]
      [%dispute game-id=@ud]
      [%deposit-confirmed game-id=@ud who=ship amount=@ud]
  ==
--
