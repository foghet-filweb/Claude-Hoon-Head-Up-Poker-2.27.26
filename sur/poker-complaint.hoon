::  /sur/poker-complaint.hoon
::  Post-game complaint types for Fhloston Poker (CC session Apr 13)
::
|%
+$  complaint-reason
  ?(%slow-play %abusive-language %broken-hand %other)

+$  complaint
  $:  id=@ud
      game-id=@ud           ::  links to challenge id
      complainant=ship
      respondent=ship
      reasons=(list complaint-reason)
      notes=@t              ::  required when %other selected
      when=@da
  ==

+$  complaint-db  (map @ud complaint)

+$  complaint-action
  $%  [%file game-id=@ud respondent=ship reasons=(list complaint-reason) notes=@t]
      [%no-complaint game-id=@ud]
  ==
--
