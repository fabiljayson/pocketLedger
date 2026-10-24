---
name: pocket-ledger
description: pocketLedger work (Flutter offline expense tracker with SQLite). Use for ANY task under /home/fabiljayson/Projects/pocketLedger — covers Day-5 scope, Flutter commands and the uncommitted-work caution.
---

# pocketLedger

Offline expense tracker (30-Day series, Day 5): record expenses offline in SQLite and display spending summaries. Flutter app, entry `lib/main.dart`.

## Commands

```bash
cd pocketLedger
flutter analyze        # run from the pocketLedger dir (global dart options otherwise leak in)
flutter test
flutter run
```

(If the project uses **fvm** like STAR's mobile does, prefix with `fvm`.)

## Non-negotiables

- **Offline-first**: no expense feature may silently require connectivity; SQLite is the source of truth.
- Data stays on device — no analytics/cloud sync unless the user explicitly asks.

## State

3 commits, last 2026-10-20, **13 modified files uncommitted** — `git status` first; don't commit or stash user WIP without asking.
