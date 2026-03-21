::  /mar/poker-game-action.hoon
::
::  Mark for front-end betting action pokes to %poker-room.
::  Only accepted from our own ship (enforced in poker-room.hoon).
::
::  JSON shapes (from front-end):
::    { "poker-game-action": { "fold": null } }
::    { "poker-game-action": { "check": null } }
::    { "poker-game-action": { "call": null } }
::    { "poker-game-action": { "raise": { "amount": 360 } } }
::
/-  poker
/+  format
|_  a=action:poker
++  grab
  |%
  ++  noun  action:poker
  ++  json
    |=  j=^json
    ^-  action:poker
    =/  inner  ((ot ~[poker-game-action+jo]) j)
    ?:  (~(has by inner) 'fold')   [%fold ~]
    ?:  (~(has by inner) 'check')  [%check ~]
    ?:  (~(has by inner) 'call')   [%call ~]
    ?:  (~(has by inner) 'raise')
      =/  r        (~(got by inner) 'raise')
      =/  amount=@ud  (ni:dejs:format ((ot ~[amount+ni]) r))
      [%raise amount]
    ~|('poker-game-action: unrecognised action' !!)
  --
++  grow
  |%
  ++  noun  a
  ++  json
    ^-  ^json
    %-  pairs:enjs:format
    ?-  -.a
      %fold   ~[['action' s+'fold']]
      %check  ~[['action' s+'check']]
      %call   ~[['action' s+'call']]
      %raise  ~[['action' s+'raise'] ['amount' (numb:enjs:format amount.a)]]
      %all-in ~[['action' s+'all-in']]
    ==
  --
++  grad  %noun
--
