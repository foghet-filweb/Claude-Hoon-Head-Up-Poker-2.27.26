::  /mar/poker-chat-update.hoon
/-  poker
/+  format
|_  u=chat-update:poker
++  grab
  |%
  ++  noun  chat-update:poker
  --
++  grow
  |%
  ++  noun  u
  ++  json
    =/  pr  pairs:enjs:format
    =/  tx  text:enjs:format
    ?-  -.u
      %message
        =/  msg       chat-message.u
        =/  ship-val  (tx ^-(@t (scot %p author.msg)))
        =/  text-val  (tx text.msg)
        =/  when-val  (tx ^-(@t (scot %da timestamp.msg)))
        =/  inner     (pr ~[['ship' ship-val] ['text' text-val] ['when' when-val]])
        =/  mid       (pr ~[['message' inner]])
        (pr ~[['poker-chat-update' mid]])
      %join
        =/  val    (tx ^-(@t (scot %p ship.u)))
        =/  inner  (pr ~[['join' val]])
        (pr ~[['poker-chat-update' inner]])
      %leave
        =/  val    (tx ^-(@t (scot %p ship.u)))
        =/  inner  (pr ~[['leave' val]])
        (pr ~[['poker-chat-update' inner]])
      %challenge-notice
        =/  val    (tx ^-(@t (scot %p challenger.u)))
        =/  inner  (pr ~[['challenge-notice' val]])
        (pr ~[['poker-chat-update' inner]])
      %report-acked
        =/  val    (tx ^-(@t (scot %p target.u)))
        =/  inner  (pr ~[['report-acked' val]])
        (pr ~[['poker-chat-update' inner]])
      %report-rejected
        =/  val    (tx reason.u)
        =/  inner  (pr ~[['report-rejected' val]])
        (pr ~[['poker-chat-update' inner]])
    ==
  --
++  grad  %noun
--
