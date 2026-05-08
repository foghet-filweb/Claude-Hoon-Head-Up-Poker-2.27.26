# Fhloston Poker — Backlog

---

## Item: Scrub stale ship references; make Alice/Bob display dynamic

**Context:**
The codebase contains hardcoded references to ships that are no longer in use or that cause confusion:
- Fakezods ~zod, ~wes, ~bus — discarded, should be removed
- ~foghet-filweb — L2 ship, not viable for cross-ship testing, source of confusion
- ~sampel-palnet and ~wicdev-wysryt — appear in various fields

**Work:**
1. Grep the full codebase (Hoon, JS, HTML, config files) for ~zod, ~wes, ~bus, ~foghet-filweb, ~sampel-palnet, ~wicdev-wysryt.
2. Remove or comment out any dead references to the fakezods and ~foghet-filweb. Do NOT touch any logic that is load-bearing for working code — audit each occurrence before deleting.
3. Wherever ~sampel-palnet or ~wicdev-wysryt appear as static values in UI fields or display logic, replace them with dynamic lookups derived from the actual ships playing as Alice (Host) and Bob (Guest) in the current session. Use the canonical variable names: `host-ship` (Alice) and `guest-ship` (Bob).

**Constraint:** Do not endanger any of the Three Core Competencies (Chat/Scry, SRA, Order of Play). Branch before touching app/ or lib/ files.

**Definition of done:** No hardcoded legacy ship names remain anywhere in the repo. All player-facing display of ship names is driven by `host-ship` / `guest-ship` at runtime.

---
