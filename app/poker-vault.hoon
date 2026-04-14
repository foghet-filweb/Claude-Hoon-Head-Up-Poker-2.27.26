::  /app/poker-vault.hoon
::  FHLO vault — balances, rake accumulation, ETH withdrawals (CC session Apr 13)
::  Reconcile with existing poker-settle.hoon IOU approach at merge time
::
/-  *poker-vault
/+  *poker-wallet, default-agent, dbug
|%
+$  state-0
  $:  %0
      vault-db=vault-db
      withdrawal-db=withdrawal-db
      next-wid=@ud
  ==
+$  versioned-state  $%(state-0)
--
=|  state-0
=*  state  -
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init   `this
++  on-save   !>(state)
++  on-load
  |=  =vase
  `this(state !<(state-0 vase))
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
++  on-agent  on-agent:def
++  on-leave  on-leave:def
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
    [%vault @ ~]
    =/  who=ship  (slav %p i.t.path)
    ?>  =(src.bowl who)
    =/  acct=(unit vault-account)  (~(get by vault-db.state) who)
    :_  this
    ~[[%give %fact ~[path] %poker-vault-update !>(acct)]]
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  [~ ~]
    [%x %balance @ ~]
    =/  who=ship  (slav %p i.t.t.path)
    ``[%noun !>((~(get by vault-db.state) who))]
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =/  act=vault-action  !<(vault-action vase)
  ?-  -.act
  ::
      %credit
    ?>  (team:title our.bowl src.bowl)
    =/  acct=vault-account  (get-or-blank who.act)
    =.  balance.acct          (add balance.acct amount.act)
    =.  total-deposited.acct  (add total-deposited.acct amount.act)
    =.  vault-db.state  (~(put by vault-db.state) who.act acct)
    :_  this
    (vault-fact who.act acct)
  ::
      %credit-rake
    ?>  (team:title our.bowl src.bowl)
    =/  house=vault-account  (get-or-blank our.bowl)
    =.  balance.house  (add balance.house amount.act)
    =.  vault-db.state  (~(put by vault-db.state) our.bowl house)
    `this
  ::
      %set-wallet
    ?>  |(=(src.bowl who.act) (team:title our.bowl src.bowl))
    =/  parsed=(unit @ux)  (cordtohex wallet.act)
    ?>  ?=(^ parsed)
    ?>  (valid-eth-addr wallet.act)
    =/  canonical=@t  (hextocord u.parsed)
    =/  acct=vault-account  (get-or-blank who.act)
    =.  eth-wallet.acct  `canonical
    =.  vault-db.state  (~(put by vault-db.state) who.act acct)
    :_  this
    (vault-fact who.act acct)
  ::
      %withdraw
    ?>  =(src.bowl who.act)
    =/  acct=(unit vault-account)  (~(get by vault-db.state) who.act)
    ?~  acct  `this
    ?>  (gte balance.u.acct amount.act)
    ?>  ?=(^ eth-wallet.u.acct)
    =.  balance.u.acct          (sub balance.u.acct amount.act)
    =.  total-withdrawn.u.acct  (add total-withdrawn.u.acct amount.act)
    =.  vault-db.state  (~(put by vault-db.state) who.act u.acct)
    =/  wid=@ud  next-wid.state
    =/  w=withdrawal
      :*  id=wid
          who=who.act
          amount=amount.act
          to-wallet=u.eth-wallet.u.acct
          status=%pending
          when=now.bowl
      ==
    =.  withdrawal-db.state  (~(put by withdrawal-db.state) wid w)
    =.  next-wid.state  +(next-wid.state)
    :_  this
    :~  (vault-fact who.act u.acct)
        [%pass /withdraw/(scot %ud wid) %agent [our.bowl %poker-log-bridge]
          %poke %noun !>(w)]
    ==
  ::
      %withdrawal-complete
    ?>  (team:title our.bowl src.bowl)
    =/  w=(unit withdrawal)  (~(get by withdrawal-db.state) id.act)
    ?~  w  `this
    =.  withdrawal-db.state
      (~(put by withdrawal-db.state) id.act u.w(status %completed))
    `this
  ::
      %withdrawal-failed
    ?>  (team:title our.bowl src.bowl)
    =/  w=(unit withdrawal)  (~(get by withdrawal-db.state) id.act)
    ?~  w  `this
    =/  acct=(unit vault-account)  (~(get by vault-db.state) who.u.w)
    ?~  acct  `this
    =.  balance.u.acct          (add balance.u.acct amount.u.w)
    =.  total-withdrawn.u.acct  (sub total-withdrawn.u.acct amount.u.w)
    =.  vault-db.state  (~(put by vault-db.state) who.u.w u.acct)
    =.  withdrawal-db.state
      (~(put by withdrawal-db.state) id.act u.w(status %failed))
    :_  this
    (vault-fact who.u.w u.acct)
  ==
::
++  get-or-blank
  |=  who=ship
  ^-  vault-account
  (~(gut by vault-db.state) who
    [who=who balance=0 eth-wallet=~ total-deposited=0 total-withdrawn=0])
::
++  vault-fact
  |=  [who=ship acct=vault-account]
  ^-  (list card)
  =/  =path  /vault/(scot %p who)
  ~[[%give %fact ~[path] %poker-vault-update !>(acct)]]
--
