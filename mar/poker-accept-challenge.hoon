::  /mar/poker-accept-challenge.hoon
|_  challenger=@p
++  grab
  |%
  ++  noun  @p
  ++  json
    |=  j=^json
    ^-  @p
    ?>  ?=([%o *] j)
    =/  v  (~(got by p.j) 'poker-accept-challenge')
    ?>  ?=([%s *] v)
    (slav %p p.v)
  --
++  grow
  |%
  ++  noun  challenger
  --
++  grad  %noun
--
