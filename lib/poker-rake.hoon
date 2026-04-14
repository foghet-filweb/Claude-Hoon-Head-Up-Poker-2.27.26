::  /lib/poker-rake.hoon
::  Rake calculation and settlement formula for Fhloston Poker
::  FHLO amounts are @ud base units throughout
::
|%
::  500 basis points = 5.00% rake
++  rake-bps  500

::  Calculate rake and net from a pot
::  returns [rake=@ud net=@ud]
++  calc-rake
  |=  pot=@ud
  ^-  [rake=@ud net=@ud]
  =/  rake=@ud  (div (mul pot rake-bps) 10.000)
  [rake (sub pot rake)]

::  Settlement formula: (cap + winnings - losses) - total-rake, floored at 0
::  cap      = initial buy-in / deposit
::  winnings = gross chips won across all hands
::  losses   = chips lost across all hands
::  rake     = cumulative rake paid
++  calc-settlement
  |=  $:  cap=@ud
          winnings=@ud
          losses=@ud
          total-rake=@ud
      ==
  ^-  @ud
  =/  gross=@ud   (add cap winnings)
  =/  owed=@ud    (add losses total-rake)
  ?:  (gth owed gross)  0
  (sub gross owed)
--
