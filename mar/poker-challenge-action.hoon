::  /mar/poker-challenge-action.hoon
::  Poke mark: browser -> poker-lobby challenge actions (CC session Apr 13)
::  JS sends 0 for "no limit" on hands/fundsCap
::
/-  *poker-challenge
|_  =challenge-action
++  grab
  |%
  ++  noun  challenge-action
  ++  json
    |=  j=json
    ^-  challenge-action
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
      'issue'
      =/  raw-hands=@ud   (get-ud 'hands')
      =/  raw-cap=@ud     (get-ud 'fundsCap')
      :+  %issue
        (slav %p (get-str 'target'))
      :*  hands=?:(=(0 raw-hands) ~ `raw-hands)
          funds-cap=?:(=(0 raw-cap) ~ `raw-cap)
          small-blind=(get-ud 'smallBlind')
          big-blind=(get-ud 'bigBlind')
      ==
      'accept'   [%accept id=(get-ud 'id')]
      'decline'  [%decline id=(get-ud 'id')]
      'cancel'   [%cancel id=(get-ud 'id')]
    ==
  --
++  grow
  |%
  ++  noun  challenge-action
  --
++  grad  %noun
--
