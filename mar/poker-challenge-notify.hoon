::  /mar/poker-challenge-notify.hoon
/-  poker
|_  u=challenge-notify:poker
++  grab
  |%
  ++  noun  challenge-notify:poker
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
      %incoming
        ?>  ?=(%propose -.c.u)
        %+  mk  %poker-challenge-notify
        %+  mk  %incoming
        (mk %challenger [%s (scot %p challenger.u)])
      %accepted
        %+  mk  %poker-challenge-notify
        %+  mk  %accepted
        [%s (scot %p challenger.u)]
      %declined
        %+  mk  %poker-challenge-notify
        %+  mk  %declined
        [%s (scot %p challenger.u)]
      %busy
        %+  mk  %poker-challenge-notify
        %+  mk  %busy
        [%s (scot %p challenger.u)]
      %timeout
        %+  mk  %poker-challenge-notify
        %+  mk  %timeout
        [%s (scot %p challenger.u)]
    ==
  --
++  grad  %noun
--
