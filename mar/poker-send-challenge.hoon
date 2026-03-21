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
/+  format
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
    =/  inner   ((ot ~[poker-send-challenge+jo]) j)
    =/  target=@p
      (slav %p (cat 3 '~' ((ot ~[target+so]) inner)))
    =/  game=game-type:poker
      =/  g  (~(get by inner) 'game')
      ?~  g  %nlh
      ?+  (so:dejs:format u.g)  %nlh
        %nlh  %nlh
        %plo  %plo
        %fcd  %fcd
      ==
    =/  sb=@ud    ((ot ~[small-blind+ni]) inner)
    =/  bb=@ud    ((ot ~[big-blind+ni])   inner)
    =/  mr=@ud    ((ot ~[min-raise+ni])   inner)
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
    [target game sb bb mr bi hands cap]
  --
++  grow
  |%
  ++  noun  s
  --
++  grad  %noun
--
