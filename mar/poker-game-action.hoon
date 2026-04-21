::  /mar/poker-game-action.hoon
::
/-  poker
/+  format
|_  a=action:poker
++  grab
  |%
  ++  noun  action:poker
  ++  json
    |=  j=^json
    ^-  action:poker
    ?>  ?=([%o *] j)
    =/  outer  (~(got by p.j) 'poker-game-action')
    ?>  ?=([%o *] outer)
    =/  keys  ~(tap by p.outer)
    ?>  ?=(^ keys)
    =/  k=@t  p.i.keys
    ?.  =(k 'raise')
      ?.  =(k 'call')
        ?.  =(k 'check')
          ?>  =(k 'fold')
          [%fold ~]
        [%check ~]
      [%call ~]
    =/  inner  q.i.keys
    ?>  ?=([%o *] inner)
    =/  amt  (~(got by p.inner) 'amount')
    ?>  ?=([%n *] amt)
    [%raise (rash p.amt dem:ag)]
  --
++  grow
  |%
  ++  noun  a
  --
++  grad  %noun
--
