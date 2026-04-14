::  /sur/poker-challenge.hoon
::  Challenge system types for Fhloston Poker (CC session Apr 13)
::  Reconcile with existing mar/poker-challenge.hoon at merge time
::
|%
+$  game-terms
  $:  hands=(unit @ud)       ::  ~ = no hand limit
      funds-cap=(unit @ud)   ::  ~ = no funds cap
      small-blind=@ud
      big-blind=@ud
  ==

+$  challenge-status
  ?(%pending %accepted %declined %cancelled %completed %abandoned)

+$  challenge
  $:  id=@ud
      challenger=ship
      target=ship
      terms=game-terms
      status=challenge-status
      when=@da
  ==

+$  challenge-db  (map @ud challenge)

+$  challenge-action
  $%  [%issue target=ship terms=game-terms]
      [%accept id=@ud]
      [%decline id=@ud]
      [%cancel id=@ud]
  ==
--
