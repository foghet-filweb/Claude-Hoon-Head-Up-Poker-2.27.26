# Fhloston Poker

**Peer-to-peer Texas Hold'em on a sovereign computing network.**

Fhloston Poker is a head-up (1v1) No-Limit Texas Hold'em application built in a novel functional language for a sovereign, decentralized computing platform. It is designed for licensed casino operators and tribal gaming environments as a provably fair, no-house-edge alternative to centralized poker infrastructure.

---

## Status — March 2026

Live on a DigitalOcean droplet. Two nodes running (host and guest). All six application agents compile and boot. Lobby UI loads and serves over nginx. **Single-node chat is fully working** — messages persist in agent state, load on page open, and appear in real time via polling. Two-node chat is the current development milestone.

---

## Architecture

### Network Layer
- Built on a **sovereign peer-to-peer runtime** — authenticated networking via a cryptographically signed identity layer
- No central server. Each player runs a sovereign compute node
- User identity is cryptographically guaranteed — no spoofing, no fake accounts

### Application Layer (Gall Agents)
Six agents running on the `%fhloston-poker` desk:

| Agent | Role |
|---|---|
| `poker-lobby` | Lobby state, chat, presence, challenge routing |
| `poker-room` | Game session management |
| `poker-engine` | Texas Hold'em hand logic |
| `poker-crypto` | SRA commutative encryption for trustless card dealing |
| `poker-ledger` | `%slab` token accounting (Fhloston coins) |
| `poker-dispute` | Hash-chained dispute log with blockchain bridge stubs |

### Card Security
Cards are dealt using **SRA commutative encryption** (Mental Poker protocol) over RFC 3526 Group 5 primes. Neither player can see the other's cards at any point in the protocol. Neither player can cheat without detectable cryptographic evidence. No trusted dealer required.

### Frontend
Single-page HTML/CSS/JS lobby served as an application bundle via nginx. Communicates with agents via:
- **Eyre HTTP API** — pokes (writes) to agent state
- **Scry polling** — reads from agent state every 2 seconds (workaround for Vere 4.3 SSE chunked encoding bug)

### Token System
In-app currency (`%slab` tokens, "Fhloston coins") tracked by `poker-ledger`. Designed for casino chip integration.

---

## Infrastructure

| Item | Detail |
|---|---|
| Droplet | DigitalOcean SFO3, Ubuntu 24.04, 4GB/2CPU |
| Host node | `~forbes-marmet` — port 8081 |
| Guest node | `~forbes-ramdyt` — port 80 |
| Desk | `%fhloston-poker` |
| Lobby URL | `http://64.227.102.14:8081/apps/poker/lobby.html` |
| Glob server | nginx port 8888 |

---

## Desk Layout

```
fhloston-poker/
├── app/
│   ├── poker-lobby            # Lobby, chat, presence
│   ├── poker-room             # Game sessions
│   ├── poker-engine           # Hand logic
│   ├── poker-crypto           # SRA encryption
│   ├── poker-ledger           # Token accounting
│   └── poker-dispute          # Dispute log
├── sur/
│   └── poker                  # Shared type definitions
├── lib/
│   └── format                 # JSON helpers
├── mar/
│   ├── poker-chat-action
│   ├── poker-chat-update
│   ├── poker-lobby-count
│   ├── poker-lobby-pending
│   └── poker-lobby-subscribers
├── glob/
│   ├── lobby.html             # Main lobby UI
│   ├── room.html              # In-game UI
│   └── index.html
└── desk.docket-0
```

---

## Key Design Decisions

**Why Sovereign Infrastructure?**
The platform's authenticated messaging protocol provides cryptographically signed node-to-node communication with no central broker. Every action is signed by the sender's sovereign identity. This makes cheating and impersonation structurally impossible — not policy-dependent.

**Why SRA encryption for cards?**
Standard poker software requires a trusted random number generator controlled by the house. SRA Mental Poker requires neither player to trust the other or any third party. The deck is encrypted twice — once by each player — and cards are revealed only when both players unlock them. A dispute log records every cryptographic commitment for post-hand verification.

**Why no house edge?**
The target market is licensed casino operators, not retail players. Operators charge rake directly. A provably fair, zero-house-edge system is a compliance and marketing advantage in regulated tribal gaming environments.

---

## Roadmap

**Infrastructure & Agents**
- [x] All six agents compile and boot
- [x] Lobby UI loads and serves correctly
- [x] Inter-node messaging confirmed
- [x] Chat send confirmed (204 OK)
- [x] Single-node chat display working
- [ ] Two-node chat (host sends, guest receives)
- [ ] Lookup table test and validation
- [ ] Challenge flow end-to-end
- [ ] Card deal protocol (poker-crypto integration)
- [ ] Full hand logic (poker-engine)
- [ ] Token ledger integration
- [ ] Dispute resolution flow

**Frontend & UI**
- [ ] Lobby HTML redesign
- [ ] Playing card back graphics
- [ ] Landscape tile image (app icon)
- [ ] Casino operator demo build

---

## Open Design Questions

Several consequential architectural decisions remain to be made before a production deployment. These touch compliance, user experience, and external integrations.

**Onboarding**
How does a new player get onto the network? Sovereign node provisioning is non-trivial for a non-technical casino patron. Options range from operator-managed node provisioning to custodial hosting to a fully abstracted web wrapper that hides the network layer entirely.

**Currency & Wallets**
What is the unit of account at the table? Fhloston coins (`%slab` tokens) are the in-app representation, but they need to map to something real — casino chips, a stablecoin, or fiat via an operator escrow account. Wallet UX (deposit, withdrawal, balance display) is undesigned.

**Blockchain Reporting**
The dispute log is hash-chained and designed for blockchain anchoring, but the target chain, anchoring frequency, and reporting format are not yet specified. Relevant for regulatory compliance in tribal gaming jurisdictions.

**Oracles**
Any feature that references real-world state — tournament clocks, rake schedules, jackpot triggers — requires a trusted data feed. The oracle strategy (operator-controlled, decentralized, or hybrid) affects both the trust model and the compliance posture.

---

## Development Notes

**Language runtime:** current stable version compatible
- Mark files use `%term` atoms for JSON keys (not cord literals)
- No single-quoted cord literals in `?+` arms
- `cat=@tas` not `cat=cord` in type definitions

**Claude Code setup (Mac):**
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 20
claude
```
Node 20 required. Node 25 crashes npm on this machine.

---

## Target Market

Licensed casino operators and tribal gaming compacts seeking a provably fair peer-to-peer poker solution with no infrastructure dependency on a centralized operator. Near-term demo target: Sycuan Casino (San Diego, CA).

---

*Fhloston Poker — Sovereign infrastructure. Provably fair. No house.*
