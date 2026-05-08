# Fhloston Poker — Session Handoff
Date: 2026-05-08
Session duration: ~10 hrs

## Ships
~nec: git hash [unstaged] | glob hash [0v6r2il.n6v4n.9n146.19mrb.4bph8]
~bes: git hash [unstaged] | glob hash [0v6r2il.n6v4n.9n146.19mrb.4bph8]

## App URLs
~nec (Chrome):   http://localhost/apps/poker
~bes (Firefox):  http://localhost:8080/apps/poker

## Session Goal
Restore April 21 working state and fix order of play. Achieved: Y (partial)

## Three Core Competencies Status
Chat / Scry:    OK — fixed ~bes cookie bug (ourShip resolving to 'nec')
SRA:            OK — hole cards unique per player confirmed
Order of Play:  PARTIAL — preflop correct, postflop backend correct,
                frontend (room.html) not re-enabling buttons after community-dealt

## Confirmed Working This Session
- Correct app URLs documented
- Chat communicating cross-ship (ourShip cookie fix in glob/lobby.html)
- Hand 1: hole cards correct and unique per player
- Hand 1: community cards correct through all streets
- Hand 1: winner determined, hand complete message displayed
- Hand 2 auto-dealt (triggered from showdown path)
- Both players receiving postflop action prompts in backend
- mp-community-reveal correctly guarded (phase + street guards)
- advance-street no longer double-fires (removed from %street-action handler)
- Stack adjustment and next-hand trigger added to %mp-reveal-key (showdown path)
- CLAUDE.md, HANDOFF.md, BACKLOG.md committed to repo
- v0.1-hand-complete tag applied to a70dd95

## Confirmed Broken This Session
- CRITICAL: room.html not re-enabling action buttons after %community-dealt
  postflop — backend is in correct [%live %flop actor=%bob] state but JS
  does not respond to community-dealt / street-started events to enable
  controls and prompt action
- ~bes loses a hole card display postflop (JS rendering bug)
- Community cards showing during pre-flop (old hand bleeding into display)
- Flop showing 4 cards instead of 3 (progressive reveal broken in JS)
- Community cards not matching between ~nec and ~bes (JS display bug)
- T displaying instead of 10
- Wrong ship name in challenge overlay (~wicdev-wisryt instead of ~bes)
- Raise pre-selection at 360 instead of empty field
- Presence detection not working (tick-tick-tick, ships not seeing each other)
- Hand 2 UI transition broken for ~bes (only visible via direct URL)

## Files Touched Today
- glob/lobby.html — ourShip cookie fix
- app/poker-room.hoon — four fixes:
    1. mp-community-reveal phase + street guards (Fix 1)
    2. %mp-community guard changed from %revealing to %live (Fix A)
    3. advance-street removed from %street-action handler (Fix C)
    4. stack adjustment + next-hand trigger added to %mp-reveal-key (Fix B)
- sur/poker.hoon — mp-community-reveal restored to deal-action type
- desk.docket-0 — updated glob hash (both ships)
- CLAUDE.md — created
- HANDOFF.md — created
- BACKLOG.md — created with deferred unstaged changes

## DO NOT TOUCH Next Session
- glob/lobby.html — chat fix is working
- lib/poker-sra.hoon — do not touch
- app/poker-lobby.hoon — working
- app/poker-room.hoon — Hoon backend is correct, do not touch

## Next Session
Single goal: fix room.html — make %community-dealt and %street-started
events re-enable action buttons and display correct postflop action prompt.

Diagnosis: After the flop is dealt, ~nec (Bob) receives %community-dealt
from %mp-community-reveal. The backend state is correctly [%live %flop
actor=%bob]. The JS in room.html must respond to %community-dealt by:
1. Displaying the 3 flop cards (not 4 or 5)
2. Re-enabling action buttons (fold/check/raise)
3. Displaying "FLOP — YOUR ACTION" prompt for the active player

Start by: run startup ritual, issue challenge, play preflop to completion,
observe whether %community-dealt triggers button re-enable in room.html.
Tell CC to read glob/room.html and find the %community-dealt and
%street-started event handlers before touching anything.

Revert command if session regresses: git reset --hard HEAD

## BACKLOG (deferred unstaged changes — do not apply before demo)
- glob/room.html — console logs removed; dedup logic simplified;
  T→10 rank fix; event listeners simplified;
  WARNING: peer-acted no longer re-enables controls — test carefully
- mar/poker-lobby-pending.hoon — ++json arm removed from grow
- mar/poker-room-update.hoon — card index formula simplified
- app/poker-room.hoon — 2 slog lines removed; base var inlined
