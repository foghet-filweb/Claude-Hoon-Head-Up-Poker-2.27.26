::  /mar/poker-vault-update.hoon
::  SSE fact mark: poker-vault -> browser (CC session Apr 13)
::  All FHLO amounts sent as cords to preserve precision in JS BigInt
::
/-  *poker-vault
|_  acct=(unit vault-account)
++  grab
  |%
  ++  noun  (unit vault-account)
  --
++  grow
  |%
  ++  json
    ?~  acct
      (pairs:enjs:format ~[['found' b+%.n]])
    %-  pairs:enjs:format
    :~  ['found'          b+%.y]
        ['balance'        s+(scot %ud balance.u.acct)]
        ['ethWallet'      ?~(eth-wallet.u.acct s+'' s+u.eth-wallet.u.acct)]
        ['totalDeposited' s+(scot %ud total-deposited.u.acct)]
        ['totalWithdrawn' s+(scot %ud total-withdrawn.u.acct)]
    ==
  --
++  grad  %noun
--
