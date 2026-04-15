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
        =/  msg  chat-message.u
        %-  pr
        :~  :-  'poker-chat-update'
            %-  pr
            :~  :-  'message'
                %-  pr
                :~  ['ship'  (tx (scot %p author.msg))]
                    ['text'  (tx text.msg)]
                    ['when'  (tx (scot %da timestamp.msg))]
                ==
            ==
        ==
      %join
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['join'  (tx (scot %p ship.u))]])]
        ==
      %leave
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['leave'  (tx (scot %p ship.u))]])]
        ==
      %challenge-notice
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['challenge-notice'  (tx (scot %p challenger.u))]])]
        ==
      %report-acked
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['report-acked'  (tx (scot %p target.u))]])]
        ==
      %report-rejected
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['report-rejected'  (tx reason.u)]])]
        ==
    ==
  --
++  grad  %noun
--
