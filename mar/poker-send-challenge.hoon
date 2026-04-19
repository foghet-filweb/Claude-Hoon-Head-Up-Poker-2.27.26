::  /mar/poker-send-challenge.hoon
::
::  Mark for the front-end poke that initiates a challenge to a target ship.
::  At least one of hands or cap must be non-null.
::
::  JSON shape (from front-end):
::    {
::      "poker-send-challenge": {
::        "target":      "sampel-palnet",
::        "game":        "nlh",
::        "small-blind": 10,
::        "big-blind":   20,
::        "min-raise":   20,
::        "buy-in":      1000,
::        "hands":       20,
::        "cap":         null
::      }
::    }
::
/-  poker
|%
+$  send-challenge
  $:  target=@p
      config=game-config:poker
  ==
--
|_  s=send-challenge
++  grab
  |%
  ++  noun  send-challenge
  ++  json
    |=  j=^json
    ^-  send-challenge
    ?>  ?=([%o *] j)
    ?>  (~(has by p.j) 'poker-send-challenge')
    =/  inner-json  (~(got by p.j) 'poker-send-challenge')
    ?>  ?=([%o *] inner-json)
    =/  inner  p.inner-json
    =/  target=@p
      =/  v  (~(got by inner) 'target')
      ?>  ?=([%s *] v)
      (slav %p (cat 3 '~' p.v))
    =/  game=game-type:poker
      =/  v  (~(get by inner) 'game')
      ?~  v  %nlh
      ?.  ?=([%s *] u.v)  %nlh
      ?+  p.u.v  %nlh
        %nlh  %nlh
        %plo  %plo
        %fcd  %fcd
      ==
    =/  sb=@ud
      =/  v  (~(got by inner) 'small-blind')
      ?>  ?=([%n *] v)
      (slav %ud p.v)
    =/  bb=@ud
      =/  v  (~(got by inner) 'big-blind')
      ?>  ?=([%n *] v)
      (slav %ud p.v)
    =/  mr=@ud
      =/  v  (~(got by inner) 'min-raise')
      ?>  ?=([%n *] v)
      (slav %ud p.v)
    =/  bi=@ud
      =/  v  (~(get by inner) 'buy-in')
      ?~  v  (mul bb 50)
      ?+  u.v  (mul bb 50)
        [%n *]  (slav %ud p.u.v)
      ==
    =/  hands=(unit @ud)
      =/  v  (~(get by inner) 'hands')
      ?~  v  ~
      ?+  u.v  ~
        [%n *]  `(slav %ud p.u.v)
      ==
    =/  cap=(unit @ud)
      =/  v  (~(get by inner) 'cap')
      ?~  v  ~
      ?+  u.v  ~
        [%n *]  `(slav %ud p.u.v)
      ==
    [target [game sb bb mr bi hands cap]]
  --
++  grow
  |%
  ++  noun  s
  --
++  grad  %noun
--
