::  /mar/poker-escrow-update.hoon
::  SSE fact mark: poker-settle -> browser (CC session Apr 13)
::
/-  *poker-escrow
/+  *poker-wallet
|_  =escrow-entry
++  grab
  |%
  ++  noun  escrow-entry
  --
++  grow
  |%
  ++  json
    =/  stake-json
      |=  s=player-stake
      %-  pairs:enjs:format
      :~  ['who'       s+(scot %p who.s)]
          ['wallet'    ?~(wallet.s s+'' s+(hextocord (need (cordtohex u.wallet.s))))]
          ['amount'    s+(scot %ud amount.s)]
          ['submitted' b+submitted.s]
      ==
    %-  pairs:enjs:format
    :~  ['id'      n+(scot %ud id.escrow-entry)]
        ['gameId'  n+(scot %ud game-id.escrow-entry)]
        ['p1'      (stake-json p1.escrow-entry)]
        ['p2'      (stake-json p2.escrow-entry)]
        ['status'  s+(scot %tas status.escrow-entry)]
        ['winner'  ?~(winner.escrow-entry s+'' s+(scot %p u.winner.escrow-entry))]
    ==
  --
++  grad  %noun
--
