# Fhloston Poker — Session Handoff
Date: 2026-05-08
Session duration: ~6 hrs

## Ships
~nec: git hash [25e8d5c + unstaged] | glob hash [0v6r2il.n6v4n.9n146.19mrb.4bph8]
~bes: git hash [25e8d5c + unstaged] | glob hash [0v6r2il.n6v4n.9n146.19mrb.4bph8]

## Session Goal
Restore April 21 working state and confirm hand plays end-to-end. Achieved: Y (partial)

## Three Core Competencies Status
Chat / Scry:    OK — fixed ~bes cookie bug (ourShip resolving to 'nec')
SRA:            OK on hand 1 / BROKEN on hand 2+ (deck not resetting between hands)
Order of Play:  PARTIAL — postflop gating fixed, but ~nec gets double turns

## Confirmed Working This Session
- Correct app URLs: ~nec = http://localhost/apps/poker, ~bes = http://localhost:8080/apps/poker
- Chat communicating cross-ship (fixed ourShip cookie bug in glob/lobby.html)
- Hand 1: hole cards correct and unique per player
- Hand 1: community cards correct through all streets
- Hand 1: both players receiving postflop action prompts (mp-community-reveal restored)
- Hand 1: winner determined, hand complete message displayed
- Hand 2 auto-dealt (first time achieved)

## Confirmed Broken This Session
- CRITICAL: Shared hole cards on hand 2+ — SRA deck not resetting between hands
- CRITICAL: Community cards changing mid-hand — extra deal triggered during street advance
- CRITICAL: Duplicate community cards — deck sampling hitting same positions twice
- CRITICAL: ~nec getting double turns postflop — mp-community-reveal restoration side effect
- CRITICAL: Hand not resolving — no winner, chips not moving, buttons locking
- Hand 2 visible to ~nec only via accidental direct URL
  (http://localhost/apps/poker/room.html?peer=bes) —
  ~bes UI did not transition to hand 2 automatically
- Community cards showing during pre-flop (old hand bleeding into new)
- Flop showing 5 cards instead of 3 (progressive reveal broken)
- T displaying instead of 10
- Wrong ship name in challenge overlay (~wicdev-wisryt instead of ~bes)
- Raise pre-selection at 360 instead of empty field
- Presence detection not working (tick-tick-tick, ships not seeing each other)

## Files Touched Today
- glob/lobby.html — ourShip cookie fix (ship: ourShip, removed window.ship fallback)
- app/poker-room.hoon — mp-community-reveal restored
- sur/poker.hoon — mp-community-reveal restored to deal-action type
- desk.docket-0 — updated glob hash (both ships)
- CLAUDE.md — created, committed
- HANDOFF.md — created, committed
- BACKLOG.md — created with deferred unstaged changes

## DO NOT TOUCH Next Session
- glob/lobby.html — chat fix is working
- lib/poker-sra.hoon — do not touch
- app/poker-lobby.hoon — working

## Next Session
Single goal: fix hand reset — SRA deck state and community cards must
clear cleanly between hands. Both players must receive unique hole cards
on hand 2+.
Start by: run startup ritual, play hand 1 (confirm still works), then
play hand 2 and observe shared hole card bug.
If hand 1 breaks: git reset --hard 25e8d5c and diagnose.
Revert command if session regresses: git reset --hard 25e8d5c
