::  /mar/poker-escrow-action.hoon
::  Poke mark: browser/agent -> poker-settle (CC session Apr 13)
::  amount sent as cord to avoid JSON number precision loss on large values
::
/-  *poker-escrow
/+  *poker-wallet
|_  =escrow-action
++  grab
  |%
  ++  noun  escrow-action
  ++  json
    |=  j=json
    ^-  escrow-action
    ?>  ?=(%o -.j)
    =/  m  p.j
    =/  get-str
      |=  k=@t
      =/  v  (~(got by m) k)
      ?>  ?=(%s -.v)  p.v
    =/  get-ud
      |=  k=@t
      =/  v  (~(got by m) k)
      ?>  ?=(%n -.v)  (rash p.v dem)
    =/  act=@t  (get-str 'action')
    ?+  act  !!
      'open'
      =/  amount=@ud  (rash (get-str 'amount') dem)
      :+  %open
        (get-ud 'gameId')
        :*  p1=(slav %p (get-str 'p1'))
            p2=(slav %p (get-str 'p2'))
            amount=amount
        ==
      'submit-wallet'
      =/  wallet=@t  (get-str 'wallet')
      ?>  (valid-eth-addr wallet)
      [%submit-wallet game-id=(get-ud 'gameId') wallet=wallet]
      'release'
      [%release game-id=(get-ud 'gameId') winner=(slav %p (get-str 'winner'))]
      'return'
      [%return game-id=(get-ud 'gameId')]
      'dispute'
      [%dispute game-id=(get-ud 'gameId')]
      'deposit-confirmed'
      [%deposit-confirmed game-id=(get-ud 'gameId') who=(slav %p (get-str 'who')) amount=(rash (get-str 'amount') dem)]
    ==
  --
++  grow
  |%
  ++  noun  escrow-action
  --
++  grad  %noun
--
