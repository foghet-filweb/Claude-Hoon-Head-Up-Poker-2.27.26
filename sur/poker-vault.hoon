::  /sur/poker-vault.hoon
::  FHLO vault types (CC session Apr 13)
::
/-  *poker-ledger
|%
+$  vault-account
  $:  who=ship
      balance=fhlo
      eth-wallet=(unit @t)
      total-deposited=fhlo
      total-withdrawn=fhlo
  ==

+$  vault-db  (map ship vault-account)

+$  withdrawal-status  ?(%pending %completed %failed)

+$  withdrawal
  $:  id=@ud
      who=ship
      amount=fhlo
      to-wallet=@t
      status=withdrawal-status
      when=@da
  ==

+$  withdrawal-db  (map @ud withdrawal)

+$  vault-action
  $%  [%credit who=ship amount=fhlo]
      [%credit-rake amount=fhlo]
      [%set-wallet who=ship wallet=@t]
      [%withdraw who=ship amount=fhlo]
      [%withdrawal-complete id=@ud]
      [%withdrawal-failed id=@ud]
  ==
--
