# Fhloston Poker — Claude Code Session Rules

Project: Fhloston Poker — Heads-up Texas Hold'em on Urbit. Two ships (~nec /
~bes), Hoon backend + vanilla JS frontend.

## Three Core Competencies (must never break)
1. Chat / Scry — cross-ship messaging
2. SRA — mutual encryption of hole cards (Mersenne prime M127)
3. Order of Play — dealer/SB/BB, street sequencing, button gating

## Last Known Good State
git hash 802a1a0, glob hash 0v7f8tq.vl53c.ev5nt.ohnb0.lmj61

## Ships
~nec: Chrome, http://localhost:8080/apps/poker (port 8080)
~bes: Firefox, http://localhost:80/apps/poker  (port 80)
Ports are SWAPPED from what docs say. ~bes=port 80, ~nec=port 8080.
Lens ports: ~bes=12321, ~nec=12322.

## DO NOT TOUCH (ever)
- lib/poker-sra.hoon
- app/poker-room.hoon
- app/poker-game-action.hoon
- glob/lobby.html

## Session Rules
- State one success criterion first
- Hoon sessions don't touch JS and vice versa
- Session ends in regression → hard revert before closing, no exceptions
- Revert command: git reset --hard HEAD

## Glob Build Workflow (required for any glob/room.html change)
The browser loads room.html from a compiled glob binary, NOT from raw files.
Editing glob/room.html in the repo has no effect until a new glob is built.

Full sequence:
  1. Edit glob/room.html in repo
  2. Copy to both pier desks:
       cp ~/Downloads/poker-repo/glob/room.html ~/bes/fhloston-poker/glob/
       cp ~/Downloads/poker-repo/glob/room.html ~/nec/fhloston-poker/glob/
  3. On ~bes dojo:  |commit %fhloston-poker
  4. On ~bes dojo:  -fhloston-poker!make-glob [%fhloston-poker /glob]
     Returns 0 on success. New glob appears in ~/bes/.urb/put/
  5. Copy to ~nec:  cp ~/bes/.urb/put/glob-NEWHASH.glob ~/nec/.urb/put/
  6. Update desk.docket-0 in repo AND both pier desks:
       glob-http+['http://localhost:9999/glob-NEWHASH.glob' NEWHASH]
  7. If docket already committed this docket-0 and failed to fetch:
     bump version+[0 1 N] to force a retry on next commit.
  8. Ensure glob server is running:
       cd ~/nec/.urb/put && python3 -m http.server 9999
  9. |commit %fhloston-poker on BOTH ships.
     Success looks like: "docket: fetching %http glob for %fhloston-poker desk"
     with no "http: fail" lines following it.

ted/make-glob.hoon lives on ~bes (not ~nec). Always run make-glob on ~bes.

## Startup Ritual
1. Ensure python3 HTTP server running on port 9999 from ~/nec/.urb/put/
2. Boot ships if down
3. |commit %fhloston-poker on both ships
4. Hard-refresh both browsers (Cmd+Shift+R)

## Known Broken (pre-demo backlog)
- Stale community cards on subscribe (NEXT SESSION: frontend handStarted flag)
- Eyre channel full reconstruction on failure (after stale cards fixed)
- Street label not updating on community-dealt
- Raise input pre-selects 360 instead of empty field
- Chat message order reversed on first message
- Face-down placeholder CSS (dark square, not card back pattern)
- ~bes lobby still shows ~wicdev-wisryt instead of ~bes in challenge overlay
