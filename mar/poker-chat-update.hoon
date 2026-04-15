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
        =/  s1  ['ship'  (str ^-(@t (scot %p author.msg)))]
        =/  s2  ['text'  (str text.msg)]
        =/  s3  ['when'  (str ^-(@t (scot %da timestamp.msg)))]
        =/  fields  (obj ~[s1 s2 s3])
        =/  inner  (obj ~[['message' fields]])
        (obj ~[['poker-chat-update' inner]])
      %join
        =/  inner  (obj ~[['join'  (str ^-(@t (scot %p ship.u)))]])
        (obj ~[['poker-chat-update' inner]])
      %leave
        =/  inner  (obj ~[['leave'  (str ^-(@t (scot %p ship.u)))]])
        (obj ~[['poker-chat-update' inner]])
      %challenge-notice
        =/  inner  (obj ~[['challenge-notice'  (str ^-(@t (scot %p challenger.u)))]])
        (obj ~[['poker-chat-update' inner]])
      %report-acked
        =/  inner  (obj ~[['report-acked'  (str ^-(@t (scot %p target.u)))]])
        (obj ~[['poker-chat-update' inner]])
      %report-rejected
        =/  inner  (obj ~[['report-rejected'  (str reason.u)]])
        (obj ~[['poker-chat-update' inner]])
    ==
  --
++  grad  %noun
--
