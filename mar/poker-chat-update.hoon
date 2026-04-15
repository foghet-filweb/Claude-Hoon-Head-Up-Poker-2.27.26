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
    ?-  -.u
      %message
        =/  msg  chat-message.u
        :*  %o
            %-  malt
            ^-  (list [@t ^json])
            :~  :-  'poker-chat-update'
                ^-  ^json
                :*  %o
                    %-  malt
                    ^-  (list [@t ^json])
                    :~  :-  'message'
                        ^-  ^json
                        :*  %o
                            %-  malt
                            ^-  (list [@t ^json])
                            :~  ['ship'  ^json+[%s (scot %p author.msg)]]
                                ['text'  ^json+[%s text.msg]]
                                ['when'  ^json+[%s (scot %da timestamp.msg)]]
                            ==
                        ==
                    ==
                ==
            ==
        ==
      %join
        :*  %o
            %-  malt
            ^-  (list [@t ^json])
            :~  :-  'poker-chat-update'
                ^-  ^json
                :*  %o
                    %-  malt
                    ^-  (list [@t ^json])
                    :~  ['join'  ^json+[%s (scot %p ship.u)]]
                    ==
                ==
            ==
        ==
      %leave
        :*  %o
            %-  malt
            ^-  (list [@t ^json])
            :~  :-  'poker-chat-update'
                ^-  ^json
                :*  %o
                    %-  malt
                    ^-  (list [@t ^json])
                    :~  ['leave'  ^json+[%s (scot %p ship.u)]]
                    ==
                ==
            ==
        ==
      %challenge-notice
        :*  %o
            %-  malt
            ^-  (list [@t ^json])
            :~  :-  'poker-chat-update'
                ^-  ^json
                :*  %o
                    %-  malt
                    ^-  (list [@t ^json])
                    :~  ['challenge-notice'  ^json+[%s (scot %p challenger.u)]]
                    ==
                ==
            ==
        ==
      %report-acked
        :*  %o
            %-  malt
            ^-  (list [@t ^json])
            :~  :-  'poker-chat-update'
                ^-  ^json
                :*  %o
                    %-  malt
                    ^-  (list [@t ^json])
                    :~  ['report-acked'  ^json+[%s (scot %p target.u)]]
                    ==
                ==
            ==
        ==
      %report-rejected
        :*  %o
            %-  malt
            ^-  (list [@t ^json])
            :~  :-  'poker-chat-update'
                ^-  ^json
                :*  %o
                    %-  malt
                    ^-  (list [@t ^json])
                    :~  ['report-rejected'  ^json+[%s reason.u]]
                    ==
                ==
            ==
        ==
    ==
  --
++  grad  %noun
--
