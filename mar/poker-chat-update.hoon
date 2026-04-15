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
                :~  ['ship'  (tx `@t`(scot %p author.msg))]
                    ['text'  (tx text.msg)]
                    ['when'  (tx `@t`(scot %da timestamp.msg))]
                ==
            ==
        ==
      %join
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['join'  (tx `@t`(scot %p ship.u))]])]
        ==
      %leave
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['leave'  (tx `@t`(scot %p ship.u))]])]
        ==
      %challenge-notice
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['challenge-notice'  (tx `@t`(scot %p challenger.u))]])]
        ==
      %report-acked
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['report-acked'  (tx `@t`(scot %p target.u))]])]
        ==
      %report-rejected
        %-  pr
        :~  ['poker-chat-update'  (pr ~[['report-rejected'  (tx reason.u)]])]
        ==
    ==
  --
++  grad  %noun
--
