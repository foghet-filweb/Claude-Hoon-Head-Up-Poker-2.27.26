::  /lib/poker-wallet.hoon
::  Wallet address utilities — hex<->cord conversion and ETH address validation
::
|%
::  @ux atom → "0x..." cord
++  hextocord
  |=  x=@ux
  (crip ['0' 'x' ((x-co:co (met 3 x)) x)])
::
::  "0x..." cord → @ux, ~ if malformed
++  cordtohex
  |=  c=@t
  ^-  (unit @ux)
  (rush c ;~(pfix (jest '0x') hex))
::
::  ETH address: exactly 20 bytes, valid hex, 0x-prefixed
++  valid-eth-addr
  |=  c=@t
  ^-  ?
  =/  parsed=(unit @ux)  (cordtohex c)
  ?~  parsed  %.n
  =(20 (met 3 u.parsed))
--
