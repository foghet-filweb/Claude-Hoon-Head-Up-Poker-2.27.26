::  /mar/poker-complaint-action.hoon
::  Poke mark: browser -> poker-lobby complaint filing (CC session Apr 13)
::
/-  *poker-complaint
|_  =complaint-action
++  grab
  |%
  ++  noun  complaint-action
  ++  json
    |=  j=json
    ^-  complaint-action
    ?>  ?=(%o -.j)
    =/  m  p.j
    =/  get-str
      |=  k=@t
      =/  v  (~(got by m) k)
      ?>  ?=(%s -.v)  p.v
    =/  get-ud
      |=  k=@t
      =/  v  (~(got by m) k)
      ?>  ?=(%n -.v)  (rash p.v dem)
    =/  str-to-reason
      |=  r=json
      ?>  ?=(%s -.r)
      ^-  complaint-reason
      ?+  p.r  !!
        'slow-play'         %slow-play
        'abusive-language'  %abusive-language
        'broken-hand'       %broken-hand
        'other'             %other
      ==
    =/  act=@t  (get-str 'action')
    ?+  act  !!
      'file'
      =/  reasons-json=json  (~(got by m) 'reasons')
      ?>  ?=(%a -.reasons-json)
      =/  notes=@t
        =/  nv  (~(get by m) 'notes')
        ?~  nv  ''
        ?>  ?=(%s -.u.nv)  p.u.nv
      :+  %file
        (get-ud 'gameId')
        :*  respondent=(slav %p (get-str 'respondent'))
            reasons=(turn p.reasons-json str-to-reason)
            notes=notes
        ==
      'no-complaint'
      [%no-complaint game-id=(get-ud 'gameId')]
    ==
  --
++  grow
  |%
  ++  noun  complaint-action
  --
++  grad  %noun
--
