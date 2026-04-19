::  /mar/poker-challenge-action.hoon
/-  poker
|_  =challenge-action:poker
++  grab
  |%
  ++  noun  challenge-action:poker
  ++  json
    |=  j=^json
    ^-  challenge-action:poker
    ?>  ?=([%o *] j)
    =/  m  p.j
    =/  act=@t
      =/  v  (~(got by m) 'action')
      ?>  ?=([%s *] v)
      p.v
    ?.  =(act 'issue')  !!
    =/  tgt=@p
      =/  v  (~(got by m) 'target')
      ?>  ?=([%s *] v)
      (slav %p (cat 3 '~' p.v))
    =/  sb=@ud
      =/  v  (~(got by m) 'smallBlind')
      ?>  ?=([%n *] v)
      (slav %ud p.v)
    =/  bb=@ud
      =/  v  (~(got by m) 'bigBlind')
      ?>  ?=([%n *] v)
      (slav %ud p.v)
    =/  hands=(unit @ud)
      =/  v  (~(get by m) 'hands')
      ?~  v  ~
      ?+  u.v  ~
        [%n *]  `(slav %ud p.u.v)
      ==
    =/  cap=(unit @ud)
      =/  v  (~(get by m) 'fundsCap')
      ?~  v  ~
      ?+  u.v  ~
        [%n *]  `(slav %ud p.u.v)
      ==
    [%issue tgt [%nlh sb bb bb bb hands cap]]
  --
++  grow
  |%
  ++  noun  challenge-action
  --
++  grad  %noun
--
