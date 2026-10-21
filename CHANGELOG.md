# Changelog

## 1.3.2 — 2026-10-21 — UI/theme loops toward 9/10

- Five independent-review UI loops on top of 1.3.1: a drawn UI kit (reactor-seal glyphs, corner frames, ticked meters, diamond pips), authored card art (family seals, weapon blueprints with stat meters, NOW→NEXT hangar rows), framed modal sheets with a result debrief grid, a stronger combat frame (chunked hull, boss/banner plates, screen corners), grey deck paint so floor orange means telegraph only, and modal/hover motion that Low Effects and QA disable. Scores moved 6.6 → 7.6/7.2 across the loops; **9/10 was not reached in the five-loop cap** — see [the loop record](qa/ui9-review.md) for per-loop verdicts and the remaining gaps. All 15 suites (632 checks) pass; gameplay and saves are unchanged.

## 1.3.1 — 2026-10-18 — UI palette overhaul

- Killed the neon-mint/purple AI-template look. New "aerospace instrument" direction: warm off-white type on graphite, one signal-orange accent (the color of the shots you steal), gold only for salvage money, red only for danger, ice only for the player marker and glide. Researched against Destiny/Hades/Dead Space UI practice; see [the loop record](qa/ui131-review.md).
- Embedded real type (OFL): Barlow for text, Barlow Condensed for display, IBM Plex Mono for timer/score/costs. No more system-font UI.
- One primary button per screen (off-white, Destiny-style); focus is a white outline that never impersonates the primary; settings show ON/OFF state and numeric slider readouts.
- Combat color law: hostile fire saturated red-orange, friendly pulse cream/ice, ice player ring, coral hazards with a readable fill.
- Three independent agent review loops: UI/theme rose 4.8-6.0 -> 6.2-6.5 -> **6.6/10 final**. Green/purple/neon verified gone; 9/10 not claimed - the remaining gap is bespoke art, not color.
- Gameplay is unchanged from 1.3.0. Published the universal Mac ZIP and checksums under `v1.3.1`; exported app verified with a simulated Classic win. [Package report](qa/release-1.3.1-package.json).

## 1.3.0 — 2026-10-18 — Reforge Mac release

- Lifelike pass: per-surface PBR (clearcoat ceramic, titanium, copper, rubber), procedural roughness grain with planar UVs on chamfered armor, sky ambient/reflections, ACES + bloom, three-point lighting, contact shadows, pulsing reactor cores, higher-fidelity round meshes.
- One color-token set (`scripts/palette.gd`): mint = player, amber = harvest economy, coral = threat; the purple family is gone from models, FX, HUD and lighting.
- Combat juice: hitstop that slows only its own window, knockback, per-hit sparks, dash ghosts sorted by size, pooled damage numbers, combo counter with score multiplier, camera punch, boss camera, landing dust, windup anticipation with authoritative telegraphs (chargers commit; shooters lock aim halfway), hazard fill timers, stretched projectiles.
- Progression for hours: 9 reactor upgrades x 3 marks (27 picks) with scaled tradeoffs and family resonances; Splitter + mites and elite affixes (swift/armored/volatile); salvage cores earned every run; Hangar with 6 permanent perks x 3 ranks plus repeatable Overcharge prestige cells.
- Fifteen test suites pass (new `reforge` suite, 31 checks); simulated Classic win and 4-sector Skybound run recorded under `qa/reforge/`.
- Published the universal Mac ZIP and SHA-256 checksums under `v1.3.0`; the exported app completed a simulated Classic win with zero script errors.
- See [release notes](docs/RELEASE_1_3.md), [the Reforge design record](docs/REFORGE.md), [agent review loops](qa/reforge-review.md) and the [package report](qa/release-1.3-package.json).

## 1.2.0 — 2026-09-13 — Prism Drive Mac release

- Replaced the background track with original ElevenLabs half-time festival dubstep, with growling bass, heavy drums and sharp synth stabs.
- Bundled the full 102.426-second arrangement for offline looping playback, retaining combat-driven gain and blast ducking.
- Added full-track and battle previews, provenance and independent playback checks; retained previous music and release evidence.
- Published the universal Mac ZIP, SHA-256 checksum and release notes under `v1.2.0`; tagged the preceding verified revision as `v1.1.0`.
- Updated every project README and current setup/player/audio/export guide, with an independent whole-game grade and version-specific evidence.
- See [release notes](docs/RELEASE_1_2.md), [music details](docs/PRISM_DRIVE.md) and [game review](qa/release-1.2-review.md).

## 1.1.0 — 2026-09-13 — Mac release

- Integrated the player-selected first ElevenLabs DnB track as an offline looping score, with smoothed combat gain and major-event ducking.
- Installed accepted weapon, impact, robot destruction and reactor pulse effects; derived the remaining weapon roles from those recordings.
- Retained endless sectors, weapon upgrades, flight, moving gates, animated hit/death effects and Quit controls.
- Passed 591 regression checks and a separate native audio/loop check; packaged a signed universal Mac app and ZIP with verified resource integrity.
- Updated the root, documentation and QA READMEs, release navigation and current setup/player/audio/test/export summaries; retained earlier reviews as version-specific history.
- See [release notes](docs/RELEASE_1_1.md), [audio review](qa/release-review.md) and [package evidence](qa/release-package.json).

## 2026-09-13 — Resonance follow-up

- Composed original 174 BPM drum and bass with a 64-bar arrangement and three synchronized stereo stems responding to nearby threats, incoming attacks, charge and Guardians.
- Recolored the courier, enemies and three environments; added shared exterior power rails and soft colored light washes.
- Replaced simple pulse rings with bounded core/gather/shard/shock-front/aftermath animation and an original layered stereo discharge; retained immediate damage and actual radius.
- Added a Master peak limiter, meaningful pulse/Low Effects/transition checks and production Classic-mode music regression coverage.
- See [Resonance](docs/RESONANCE.md) and [its independent review](qa/resonance-review.md) for previews, current evidence and listening limits.

## 2026-09-13 — Overdrive follow-up

- Added visible working Quit controls on title, pause, checkpoint and results screens.
- Added four projectile weapons with distinct fire/impact audio, five ranks, model evolutions, and remappable Q switching.
- Refined the courier, held weapons and recoil; added localized hit reactions and pooled enemy armor breakup with Low Effects support.
- Added seeded continuous sector generation, route-specific floor dressing, recurring Guardians, bank/continue checkpoints and rewards after reactor upgrades are exhausted.
- Added independent projectile, audio, generation, continuity, actual Quit-exit and weapon-keyboard regressions; fixed range/cover/cadence defects found during review.
- See [Overdrive](docs/OVERDRIVE.md) and [its independent review](qa/overdrive-review.md) for evidence and remaining quality limits.

## 2026-09-13 — Skybound feature branch

- Added the three-sector Skybound campaign, airborne relay objectives, upgrade transitions, timed gates and authored shock-pad patterns.
- Added buffered jump, finite hold-to-glide flight, actual altitude-aware collision and cover-aware shots/harvesting/AI.
- Rebuilt the courier with beveled armor, articulated gait, wing deployment, jet effects and landing compression; added distinct sector scenery and closer framing.
- Added remappable flight controls with legacy-binding migration, persistent objectives, fuel/height HUD and a local source launcher.
- Added traversal, altitude/gate, campaign and injected-keyboard suites; preserved the original experiment reports and development losses.
- See [Skybound](docs/SKYBOUND.md) and the [independent review](qa/skybound-review.md) for exact validation and quality limits.

## Public experiment documentation — 2026-09-07

- Published the source under xindomusic with the GPT-6 Astra-inside-Codex experiment explained prominently.
- Added guides for setup, gameplay, architecture, tests, native export, assets, lessons, roadmap, and contribution feedback.
- Included selected title and staged scene screenshots with explicit provenance.
- Preserved the three independent review/fix cycles and final 8.2/10 observational outcome.
- Added fresh-clone instructions; engine binaries, templates and generated apps remain outside Git.
- No gameplay code changes in this documentation/publication iteration.

## Initial playable experiment — 2026-09-07

Initial source commit: `a992452`. The original native export preset reports game version `1.0.0`; this entry records the experiment, not a notarized public binary release.

- Built one native 3D arena, three regular enemy roles, nine upgrades, a six-minute wave phase, and a two-phase Guardian.
- Added dash harvesting, energy pulses, automatic fire, optional repair cores and a victory-unlocked Overdrive mode.
- Added practice, menus, keyboard remapping, local preferences/best score, Assist, Low Effects, and focus-loss pause.
- Created procedural art and synthesized original music/cues.
- Passed 25 combat, 68 save and 38 integration checks; verified a complete final packaged headless victory.
- Completed three independent review/fix cycles. The requested score strictly above 9/10 was not established; the final observational score was 8.2/10.

See [QA evidence](qa/README.md) for candidate hashes, benchmark conditions and retained alternate-build losses.
