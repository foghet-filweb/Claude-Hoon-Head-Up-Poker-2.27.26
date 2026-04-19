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
        =/  jmap
          |=  [k=@tas v=^json]
          ^-  (map @t ^json)
          (~(gas by *(map @t ^json)) ~[[k v]])
        =/  inner
          [%o (~(uni by (jmap %challenger [%s (scot %p challenger.u)])) (~(uni by (jmap %small-blind [%n (scot %ud small-blind.c.u)])) (~(uni by (jmap %big-blind [%n (scot %ud big-blind.c.u)])) (~(uni by (jmap %min-raise [%n (scot %ud min-raise.c.u)])) (jmap %buy-in [%n (scot %ud buy-in.c.u)])))))]
        %+  mk  %poker-challenge-notify
        %+  mk  %incoming
        inner
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
