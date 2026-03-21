::  /lib/format.hoon
::
::  Minimal format library for fhloston-poker desk.
::  Provides JSON encoding helpers used by mark files.
::
|%
++  enjs
  |%
  ++  pairs
    |=  a=(list [cord json])
    ^-  json
    [%o (~(gas by *(map cord json)) a)]
  ++  numb
    |=  a=@ud
    ^-  json
    [%n (scot %ud a)]
  ++  text
    |=  a=cord
    ^-  json
    [%s a]
  ++  flag
    |=  a=?
    ^-  json
    [%b a]
  --
++  dejs
  |%
  ++  so
    |=  j=json
    ^-  cord
    ?>  ?=([%s *] j)
    p.j
  ++  jo
    |=  j=json
    ^-  (map cord json)
    ?>  ?=([%o *] j)
    p.j
  ++  ot
    |=  a=(list [cord $-(json json)])
    |=  j=json
    ?>  ?=([%o *] j)
    =/  obj  p.j
    %-  ~(gas by *(map cord json))
    %+  turn  a
    |=  [k=cord f=$-(json json)]
    [k (f (~(got by obj) k))]
  --
--
