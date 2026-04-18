::  /mar/poker-chat-action.hoon
/-  poker
|_  a=chat-action:poker
++  grab
  |%
  ++  noun  chat-action:poker
  ++  json
    |=  j=^json
    ^-  chat-action:poker
    ?>  ?=([%o *] j)
    =/  obj  p.j
    ?>  (~(has by obj) 'poker-chat-action')
    =/  inner  (~(got by obj) 'poker-chat-action')
    ?>  ?=([%o *] inner)
    =/  act  p.inner
    ?:  (~(has by act) 'message')
      =/  msg   (~(got by act) 'message')
      ?>  ?=([%o *] msg)
      =/  txt   (~(got by p.msg) 'text')
      ?>  ?=([%s *] txt)
      [%send p.txt]
    ?:  (~(has by act) 'presence')
      =/  pres  (~(got by act) 'presence')
      ?>  ?=([%s *] pres)
      ?:  =('join' p.pres)  [%presence %join]
      [%presence %leave]
    !!
  --
++  grow
  |%
  ++  noun  a
  --
++  grad  %noun
--
