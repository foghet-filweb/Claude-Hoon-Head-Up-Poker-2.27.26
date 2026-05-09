# Fhloston Poker — Session Handoff
Date: 2026-05-09
Session duration: ~6 hrs

## Ships
| Ship | Browser | Port |
|------|---------|------|
| ~nec | Chrome  | 8080 | http://localhost:8080/apps/poker |
| ~bes | Firefox | 80   | http://localhost:80/apps/poker   |

glob hash: `0v7f8tq.vl53c.ev5nt.ohnb0.lmj61`

## Three Core Competencies Status
- Chat / Scry:   OK
- SRA:           OK — hole cards unique per player confirmed this session
- Order of Play: PARTIAL — preflop correct, postflop backend correct,
  frontend still not displaying postflop state reliably

---

## What Happened This Session

### Reverted May 8 Claude Code damage
CC's May 8 session left uncommitted changes that violated DO NOT TOUCH:

- `app/poker-room.hoon`: advance-street calls removed from street-done branch
  (this caused `%community-dealt` to never fire — the root bug of last session)
- `glob/room.html`: peer-acted no longer re-enabled controls (removed)

Used `git checkout -- .` to restore HEAD. advance-street confirmed intact
at 5 locations. **DO NOT TOUCH means DO NOT TOUCH.**

### Patches applied to glob/room.html
Two changes made via Python str.replace (assertions confirmed both applied):

**Eyre reconnect logic (`openSSE`):**
- BEFORE: `es.onerror = () => { es.close(); handlePeerLeft(); };`
- AFTER: on error, retry `openSSE` up to 8 times with backoff before
  calling `handlePeerLeft`. `sseReconnects` counter resets on each
  successful message.
- STATUS: Deployed but ineffective — see Confirmed Broken below.

**Face-down community card placeholders (`renderCommunityCards`):**
- BEFORE: `ph.className = 'card community placeholder';`
- AFTER:  `ph.className = 'card face-down community';`
- STATUS: Deployed. ~nec shows dark square (face-down class rendering).
  Visual CSS refinement may be needed.

### Glob build — documented workflow (hard-won, ~80k CC tokens)
The glob is a compiled binary served from `~/nec/.urb/put/` via `python3`
HTTP server on port 9999. Raw HTML edits do NOT reach the browser until
a new glob is built and `docket-0` is updated.

Full deployment sequence for `glob/room.html` changes:

1. Edit `glob/room.html` in repo
2. Copy to pier:
   ```
   cp repo/glob/room.html ~/bes/fhloston-poker/glob/
   cp repo/glob/room.html ~/nec/fhloston-poker/glob/
   ```
3. On ~bes dojo: `|commit %fhloston-poker`
4. On ~bes dojo: `-fhloston-poker!make-glob [%fhloston-poker /glob]`
   (returns `0` on success; new glob appears in `~/bes/.urb/put/`)
5. Copy to ~nec: `cp ~/bes/.urb/put/glob-NEWHASH.glob ~/nec/.urb/put/`
6. Update `desk.docket-0` in repo AND both pier desks:
   ```
   glob-http+['http://localhost:9999/glob-NEWHASH.glob' NEWHASH]
   ```
   If docket already saw this docket-0 and failed: bump `version+[0 1 N]`
   to force docket to retry the fetch on next commit.
7. Restart `python3` HTTP server if it died:
   ```
   cd ~/nec/.urb/put && python3 -m http.server 9999
   ```
8. `|commit %fhloston-poker` on both ships
   Expect: `"docket: fetching %http glob for %fhloston-poker desk"` with
   no `http: fail` lines.

`ted/make-glob.hoon` exists on ~bes (and ~wes) but NOT on ~nec.
Lens port: ~bes=12321, ~nec=12322. Use ~bes for glob builds.

---

## Confirmed Broken This Session

### CRITICAL: Stale community cards on subscribe — NEXT SESSION GOAL
When the browser subscribes to `/game`, the `on-watch` handler in
`poker-room.hoon` sends whatever community state the agent currently holds.
If the agent has community cards from a previous session, they are pushed
to the new subscriber before `hand-dealt` fires for the new hand. Result:
both players see old community cards at room open, poisoning the display
for the entire hand.

Observed: A♠K♥7♦2♣ (previous session's turn cards) appearing at room
open on both sides before any action is taken.

**Fix (frontend, DO NOT TOUCH poker-room.hoon):**
- Add a flag `gameState.handStarted = false` at init.
- Set `gameState.handStarted = true` in the `hand-dealt` handler.
- In the `community-dealt` handler: `if (!gameState.handStarted) return;`

This causes the JS to ignore replayed `community-dealt` events from the
previous session until the new hand's `hand-dealt` arrives and sets the flag.

### CRITICAL: Eyre channel reconnect fix is wrong approach
The `onerror` fix reconnects the EventSource to the same channel UID.
If that channel is clogged or dead on Urbit's side (`"eyre: no channel
to move"` / `"eyre: clogged"`), reconnecting to the same UID does nothing.

**Correct fix: full channel reconstruction on failure.**
On `onerror` (after N retries to same channel):
1. Generate new `uid`
2. Reset `eventId` to 1
3. `await eyrePut([])` — open new channel
4. Re-subscribe to `/game` and `/chat`
5. `openSSE()` with new channel

This causes the backend to send fresh state for the new subscription,
recovering display and re-enabling controls.

### Street label not updating after community-dealt
After flop is dealt, ~bes showed correct 3 cards (T♥3♣5♣) but label
stayed "PRE-FLOP" instead of updating to "FLOP". `updateStreetLabel()` is
called in the `community-dealt` handler but may not be reading
`gameState.street` correctly at that point. Investigate `updateStreetLabel()`.

### Community card count disagrees between ships
- ~nec: 4 stale cards throughout
- ~bes: 3 new flop cards after `community-dealt` fires
- Root cause: stale subscribe replay (fix above resolves this).

---

## Files Modified This Session (uncommitted at close)

- `glob/room.html` — two patches above (commit as session changes)
- `desk.docket-0` — new glob hash `0v7f8tq`, version bumped to `[0 1 1]`

---

## DO NOT TOUCH Next Session

- `lib/poker-sra.hoon`
- `app/poker-room.hoon` — DO NOT TOUCH, EVER, under any circumstances
- `app/poker-game-action.hoon`
- `glob/lobby.html` — chat fix working

---

## Next Session Single Goal
Fix stale community cards on subscribe (frontend flag approach above).

This unblocks all postflop testing. Do not attempt any other fix until
stale cards are gone and both sides open a hand with empty community area.

**Start by:** read `glob/room.html`, find the `hand-dealt` handler and
`community-dealt` handler, implement the `handStarted` flag. Build new glob
using the documented workflow above. Run hand. Confirm both sides open
with empty community. Then test Eyre channel full reconstruction fix.

**Revert command:** `git reset --hard HEAD`
