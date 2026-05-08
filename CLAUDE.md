# Fhloston Poker — Claude Working Document

## Project
Heads-up Texas Hold'em on Urbit. Two-ship architecture. No third-party poker libraries.
Built in Hoon (backend agents) + vanilla JS (frontend desk).

## Three Core Competencies
Non-negotiable pillars. Every session must protect all three.

1. Chat / Scry — cross-ship messaging via poke/watch/scry works
2. SRA — mutual encryption of hole cards (Mersenne prime M127)
3. Order of Play — dealer/SB/BB assignment, street sequencing, button gating works

If any session breaks one of these three: STOP and REVERT before closing.

---

## Ships
| Name | Browser | Port  | Display |
|------|---------|-------|---------|
| ~nec | Chrome  | 80    | Alice   |
| ~bes | Firefox | 8080  | Bob     |

---

## Nomenclature — Canonical Terms

Three role systems operate simultaneously. Never mix vocabulary across layers.

### Ship Layer (fixed, never changes)
| Name | Ship | Display    |
|------|------|------------|
| ~nec | Alice's ship | "Alice" in UI |
| ~bes | Bob's ship   | "Bob" in UI   |

### App Layer (fixed per session)
| Term  | Meaning                         |
|-------|---------------------------------|
| Host  | Ship managing game state (~nec) |
| Guest | Ship that joins (~bes)          |

### Urbit Social Layer (per challenge)
| Term       | Meaning                              |
|------------|--------------------------------------|
| Challenger | Ship that sends the challenge poke   |
| Challenged | Ship that receives and accepts       |

Note: Challenger and Host are not always the same ship.

### Poker Rules Layer (rotates each hand)
| Term        | Meaning                                   |
|-------------|-------------------------------------------|
| Button      | Has the dealer chip — acts last postflop  |
| Small Blind | = Button in heads-up. Same player.        |
| Big Blind   | Non-button — acts last preflop only       |

### THE CRITICAL HEADS-UP RULE
In heads-up poker:

  Dealer = Button = Small Blind

These are ONE role, ONE player. Any variable, comment, or UI label
that treats them as potentially different players is a bug.

### Variable Naming Convention (Hoon + JS)
| Concept     | Use this name   | Never use           |
|-------------|-----------------|---------------------|
| Button ship | button-ship     | dealer, sb          |
| Big blind   | bb-ship         | non-dealer          |
| Host ship   | host-ship       | dealer, challenger  |
| Guest ship  | guest-ship      | opponent, other     |
| Challenger  | challenger-ship | host, initiator     |

---

## Startup Ritual (exact order every time)

1. cd ~/nec/.urb/put && python3 -m http.server 9999
2. cd ~ && urbit nec        (separate terminal)
   cd ~ && urbit bes        (separate terminal)
3. ~nec dojo: |commit %fhloston-poker
   ~bes dojo: |commit %fhloston-poker
4. Hard-refresh both browsers

Glob hash: 0v6.rel84.bl1eo.33gi1.0jcu8.hb69g

---

## Last Known Good State

Git hash:  a70dd95  (April 21)
Git tag:   v0.1-hand-complete

CONFIRMED WORKING:
- Complete hand played end-to-end across two ships
- Hole cards dealt and decrypted correctly (SRA)
- Community cards correct through all streets
- Order of play correct (button/BB, street sequencing)
- Buttons functional (fold/call/raise)
- Chat communicating cross-ship
- SRA mod-inv sign bug fixed (confirmed May 7)

KNOWN BROKEN:
- Ledger / pot display incorrect
- Raise pre-selects to 180 instead of empty
- Chat order reversed on first message
- ~unknown peer on ~bes

---

## DO NOT TOUCH (without explicit session intent)

- lib/poker-sra.hoon          — SRA is working
- app/poker-room.hoon         — core agent, branch before editing
- app/poker-game-action.hoon  — restored May 7, do not touch
- Any file not related to the session's single stated goal

---

## Session Rules

1. State single success criterion before any code is written
2. Run startup ritual and confirm prior working state before any changes
3. Hoon sessions do not touch JS. JS sessions do not touch Hoon.
4. Paste actual file contents of files to be edited — not descriptions
5. If something unrelated breaks: stop, revert, close
6. Last act of every session: update HANDOFF.md and commit it
7. Session ends in regression → hard revert before closing, no exceptions

## Git Commands
git tag v0.1-hand-complete a70dd95   # tag known good state
git checkout -b fix/[thing]           # new work always on a branch
git reset --hard a70dd95             # revert if session regresses

---

## Architecture Notes

- 65,536 stars (2^16), heads-up only
- Multi-player via Armada clone (post-demo backlog)
- L1 Azimuth check via Jael scry; L2 ships silently rejected
- SRA prime: Mersenne prime M127
- No reconnection probe (removed — was causing auto-deal loops)

## Post-Demo Backlog (do not pursue before demo)
- Agent teams for lookup / reputation thermometer
- Escrow, rake, pre-images for blockchain
- Fhloston Landscape tile
- Lobby-to-room transition videos
- SVG reverse card faces / community cards flipping by street
- Interactive seed UI

---

*Update this file at the end of every session. Commit it. This is the source of truth.*
