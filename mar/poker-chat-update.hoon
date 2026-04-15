::  /mar/poker-chat-update.hoon
/-  poker
|_  u=chat-update:poker
++  grab
  |%
  ++  noun  chat-update:poker
  --
++  grow
  |%
  ++  noun  u
  ++  json
    =/  j    *^json
    =/  obj
      |=  a=(list [@t _j])
      ^-  _j
      [%o (~(gas by *(map @t _j)) a)]
    =/  str
      |=  a=@t
      ^-  _j
      [%s a]
    ?-  -.u
      %message
        =/  msg  chat-message.u
        =/  k1  'ship'
        =/  v1  (str ^-(@t (scot %p author.msg)))
        =/  k2  'text'
        =/  v2  (str text.msg)
        =/  k3  'when'
        =/  v3  (str ^-(@t (scot %da timestamp.msg)))
        =/  fields  (obj ~[[k1 v1] [k2 v2] [k3 v3]])
        =/  inner  (obj ~[['message' fields]])
        (obj ~[['poker-chat-update' inner]])
      %join
        =/  k1  'join'
        =/  v1  (str ^-(@t (scot %p ship.u)))
        =/  inner  (obj ~[[k1 v1]])
        =/  ko  'poker-chat-update'
        (obj ~[[ko inner]])
      %leave
        =/  k1  'leave'
        =/  v1  (str ^-(@t (scot %p ship.u)))
        =/  inner  (obj ~[[k1 v1]])
        =/  ko  'poker-chat-update'
        (obj ~[[ko inner]])
      %challenge-notice
        =/  k1  'challenge-notice'
        =/  v1  (str ^-(@t (scot %p challenger.u)))
        =/  inner  (obj ~[[k1 v1]])
        =/  ko  'poker-chat-update'
        (obj ~[[ko inner]])
      %report-acked
        =/  k1  'report-acked'
        =/  v1  (str ^-(@t (scot %p target.u)))
        =/  inner  (obj ~[[k1 v1]])
        =/  ko  'poker-chat-update'
        (obj ~[[ko inner]])
      %report-rejected
        =/  k1  'report-rejected'
        =/  v1  (str reason.u)
        =/  inner  (obj ~[[k1 v1]])
        =/  ko  'poker-chat-update'
        (obj ~[[ko inner]])
    ==
  --
++  grad  %noun
--
