# Pulsebreak Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development for scoped implementation and independent review. The user has approved building the design and Astra model recommendation. Execute continuously.

**Goal:** Deliver a complete playable native Mac arena action game and honestly evaluate it through at most three independent review/fix rounds.
**Architecture:** A Godot Node3D game director owns run states and entities. Pure combat rules, procedural art, UI, audio, and persistence are separate scripts. Single-plane 3D combat uses swept projectile collision and bounded entity/effect collections.
**Tech Stack:** Godot stable, GDScript, Metal renderer, procedural meshes, generated audio, native macOS export.
**Spec:** ../../../DESIGN.md

## Global Constraints
- Native Apple Silicon local Mac app plus editable source.
- Two dash charges; 100 energy maximum; pulse requires 30; nine upgrades; three standard enemy roles; two-phase boss after six wave minutes.
- Keyboard movement/dash/pulse, tutorial, pause/settings, result/restart, local saves, accessible shape-coded attacks.
- 60 fps at 1080p is a target to measure, not a promised result.
- At most three playable review/fix rounds; weighted score must be strictly above 9 to claim the target met. Observational review cannot substantiate subjective control feel.
- User's “let’s do it” approves implementation. All edits isolated in the new astra-game repository on build/pulsebreak; no other source project exists.

## Task 1: Engine setup and tested combat rules
Files: project.godot, main.tscn, scripts/rules.gd, tests/rules_test.gd, .tools/, .gitignore.
Interfaces: Rules extends RefCounted: reset(), tick(delta), try_dash() -> bool, harvest(amount) -> float, spend_pulse() -> float, damage(amount) -> bool, apply_upgrade(id), upgrade_options(rng) -> Array.
- [x] Obtain official stable engine and native export template, keeping binaries ignored in .tools. If proposed release unavailable, use the newest official stable actually obtainable and document the correction.
- [x] Write assertions for two immediate dashes then rejection, sequential cooldown, harvest caps, pulse threshold/spend, damage recovery, and five nonduplicate upgrade picks. Run before implementation to verify missing rules fail.
```gdscript
assert(r.try_dash()); assert(r.try_dash()); assert(not r.try_dash())
r.tick(1.5); assert(r.try_dash())
r.energy = 29; assert(r.spend_pulse() == 0)
r.energy = 100; assert(r.spend_pulse() == 100); assert(r.energy == 0)
```
- [x] Implement Rules state and methods, then run engine --headless --path . --script tests/rules_test.gd.

## Task 2: Art and interactive combat slice
Files: scripts/art.gd, scripts/game.gd, scripts/enemy.gd, scripts/hud.gd.
Art interface: static build_arena(parent: Node3D), player() -> Node3D, enemy(kind: String) -> Node3D, boss() -> Node3D. Visual nodes use local origin at ground level; player/enemies are 1–2 units tall; arena traversable x/z [-15,15], base ground y=0; palette navy/cyan/amber.
Game interface: start_run(practice=false), spawn_enemy(kind,at), fire_volley(origin,direction,count,speed), damage_enemy(enemy,amount,from_pulse=false), add_effect(at,color,size), player_position, rules, state.
- [x] Delegate procedural art in its own file while controller implements combat. No shared file edits and no concurrent implementation sub-agents.
- [x] Implement immediate screen-relative movement, wall clamping, dash, swept absorption, automatic weapon, gunner, charger and bruiser behavior.
- [x] Add minimal HUD with energy, dash and health plus practice instructions. Run graphical engine, capture gameplay, check harvesting and pulse payoff before expanding.
- [x] Implement smoke assertions for no projectiles crossing dash undetected, paused timers, invalid targets, and safe restart.

## Task 3: Complete run, upgrades, boss, and presentation
Files: scripts/game.gd, scripts/enemy.gd, scripts/hud.gd, scripts/audio_director.gd, tools/generate_audio.py, assets/audio/.
Audio interface: play_cue(name: String, strength=1.0), set_intensity(amount), set_volume(amount), set_muted(value).
- [x] Implement six-minute director, minute 1–5 upgrade picks, nine behavior-changing upgrades, telegraphed bonus cores, two-phase boss, victory/failure, score and restart.
- [x] Build title and pause screens, upgrade cards, readable boss health, tutorial progression, animated hit and absorption feedback, enemy recoil, and bounded effects.
- [x] Delegate original sound/music generation and playback script; verify imports, bounded voices, signal levels and clean shutdown.
- [ ] Audible mix audition remains unverified and is explicitly reflected in the review score.
- [x] Compare active and passive drivers, verify boss volley availability, and inspect native captures. Human combat feel and peak-density judgment remain provisional.

## Task 4: Settings, persistence and native packaging
Files: scripts/save_store.gd, scripts/hud.gd, export_presets.cfg, README.md, LICENSES.md, tools/export_macos.sh.
Store interface: load_data() -> Dictionary, save_data(data: Dictionary) -> bool, default_data() -> Dictionary.
- [x] Test invalid/empty saves preserve defaults; implement preferences, best score, tutorial completion, keyboard remapping, assist, volume and shake.
- [x] Export ad-hoc signed .app using official template; verify ARM64 and signature, launch the exported app, and exercise menu → game → pause → result/restart.
- [x] Write launch instructions, source-run and test commands, asset provenance, known limitations.

## Task 5: Up to three independent quality rounds
Files: qa/review-round-1.md through qa/review-round-3.md, qa/metrics.json, qa/captures/.
- [x] Record hardware, engine version, build ID, real frame times and screenshots. A standard build wins; alternate build losses are retained. Multiple distinct human wins were not established.
- [x] Reviewer uses DESIGN.md weighted rubric; record evidence and explicit limits for each score. Pair source/code review with actual captured runtime; direct control if tools permit.
- [x] Fix three highest-impact findings each round, independently recheck, stop when above-nine criterion met or after round three; report shortfall honestly.

## Task 6: Delivery
- [x] Fresh headless rules and integration checks, release export launch and signature checks, then inspect Git diff/status.
- [x] Prepare coherent source and documentation for local commit on build/pulsebreak. Keep binaries in ignored build directory.
- [x] Prepare app/source/README links, controls, hardware/performance evidence, actual reviewer results, and limitations for delivery.

## Preflight interface review
| Pair/task | Boundary | Finding |
|---|---|---|
| 1 / 2 | Rules methods consumed by Game | Explicit API above; tests use same names |
| 2 / 3 | Entity/game callbacks | Controller owns game/enemy/HUD; art agent only art.gd |
| 3 / 4 | HUD state and preferences | Controller owns integration; audio agent only isolated audio files |
| 4 / 5 | Export and evidence | Score actual native build; headless checks are supplemental |
| 1–6 individually | Files, tests, deliverables | No established project code; new branch is sufficient isolation |

## Delivery checkpoint

Implementation and the three authorized review/fix rounds are finished. See qa/README.md and the final round-three addendum for measured outcomes. The requested score above9/10 is not established. The finished local game is being delivered with that limitation, without claiming direct human fun or sound validation.
