# Changelog

## 1.2.0 — Prism Drive music update (feature branch)

- Replaced the background track with original ElevenLabs half-time festival dubstep, following the user’s new reference direction.
- Bundled the full 102.426-second arrangement for offline looping playback, retaining combat-driven gain and blast ducking.
- Added full-track and battle previews, provenance and independent playback checks; retained previous music and release evidence.
- See [update notes](docs/PRISM_DRIVE.md) for the local Mac build and validation.

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
