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
    ^-  ^json
    =/  mk
      |=  [k=@tas v=^json]
      ^-  ^json
      [%o (~(gas by *(map @t ^json)) ~[[k v]])]
    ?-  -.u
      %message
        %+  mk  %poker-chat-update
        %+  mk  %message
        %-  pairs:enjs:format
        :~  ['ship' s+(scot %p author.chat-message.u)]
            ['text' s+text.chat-message.u]
            ['when' s+(scot %da timestamp.chat-message.u)]
        ==
      %join
        %+  mk  %poker-chat-update
        %+  mk  %join
        [%s (scot %p ship.u)]
      %leave
        %+  mk  %poker-chat-update
        %+  mk  %leave
        [%s (scot %p ship.u)]
      %challenge-notice
        %+  mk  %poker-chat-update
        %+  mk  %challenge-notice
        [%s (scot %p challenger.u)]
      %report-acked
        %+  mk  %poker-chat-update
        %+  mk  %report-acked
        [%s (scot %p target.u)]
      %report-rejected
        %+  mk  %poker-chat-update
        %+  mk  %report-rejected
        [%s reason.u]
    ==
  --
++  grad  %noun
--
