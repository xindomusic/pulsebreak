# Pulsebreak verification evidence

## Skybound follow-up

The new work on `feat/skybound-showcase` is recorded in [the independent review](skybound-review.md), [native controls report](skybound-controls.md), and [runtime source manifest](skybound-source.json). Seven suites pass **261 checks**. The original evidence below remains unchanged.

- `skybound-release-normal/active-metrics.json`: full fixed-60 production campaign, all nine relays, victory at 128.40 seconds with 16 hull.
- `skybound-release-alternate/active-metrics.json`: alternate seed/build, all nine relays, victory at 123.15 seconds with 52 hull.
- `skybound-review-sim`, `skybound-normal`, `skybound-alternate`, `skybound-flight-*`, `skybound-diagnostic`, and `skybound-spatial-normal`: retained development losses. The diagnostic identifies body collisions caused by the pilot's old 3D spacing policy.
- `skybound-final-*`: successful candidate runs before the final authored route hazards. `skybound-release-*` includes those hazards.
- `skybound-native-timing`: actual single-instance native frame measurements, separately described in the independent review.
- `skybound-native-windowed`: fixed 1280×800 capture dimensions; another full victory, median 16.47 ms and p95 17.842 ms. The first native run resized during play, so its aggregate is a mixed-resolution measurement.
- `skybound-visuals/captures` and `skybound-controls/captures`: ignored raw staged/native input captures; selected staged images are published under `docs/images/skybound-*`.

Headless reports are simulations, not FPS evidence. The score is a qualified independent assessment, not a guarantee of 9/10, human enjoyment, or event acceptance.

## Original experiment

Date: 2026-09-07. Godot 4.7.2; Apple M1 Max, 32 GB, macOS 26.6.2.

## Delivered package

`build/Pulsebreak.app` contains both arm64 and x86_64 native binaries, compiled game resources, original audio, and LICENSES.md. Local ad-hoc signing passes strict deep verification. It runs without the editor. Final game PCK SHA-256:

`0f2eca2b50180c9dd17f6ea15b74ac89989059490e6e3ea44e0b6f471abdae4d`

The source remains on `build/pulsebreak`. Binaries and screenshots are available locally but intentionally excluded from Git.

## Checks and playthroughs

- Final source checks: **25 combat + 68 save + 38 integration = 131**, all pass. Integration covers swept absorption, pause, upgrades, boss transitions, practice completion, remapped prompts, immediate-direction dashes, charger wall stops and slowdown, focus-loss pause, isolated victory/unlock saving, and repeated restarts.
- [Final packaged simulation](final-native-sim/active-metrics.json): the app itself runs the complete seeded driver with actual resource limits and collisions. Headless fixed-fps means no rendering performance is claimed.
- [Post-round-two source simulation](round2-fixed-sim/active-metrics.json): normal-difficulty win at 405.6 seconds, 30 hull, 266 kills, 373 absorbed shots, 102 pulses. Build: Flare Drive, Aftershock, Hot Capacitor, Life Circuit, Chain Reaction.
- [Alternate normal build](final-alternate/active-metrics.json): recorded loss at 283.5 seconds. [Alternate Assist build](alternate-assist/active-metrics.json) reaches the boss then loses at 369.45 seconds. These are retained losses, not proof of an unwinnable build. The driver is not optimized for placing damage/slow trails.
- [Earlier passive driver](passive/passive-metrics.json) loses at 134.8 seconds without harvesting or pulsing. Its earlier candidate/seed-policy differences prevent a strict causal comparison with every later active run.

## Native render performance

[Round-two native run](native-round2/active-metrics.json) measured 48,258 real render-frame intervals after a 3-second warm-up. Normal difficulty, Assist off, Low Effects off, volume 0.65, shake 0.45. Window 1920×1080; preserved 16:10 gameplay renders 1728×1080. It completed the full run.

| Measurement | Milliseconds |
|---|---:|
| Median | 8.462 |
| p95 | 10.353 |
| p99 | 11.754 |
| Worst minute p95 (minute 5) | 10.964 |
| Boss p95 | 10.071 |

That measured PCK is `9baf31f347bf9665950003e2f29ce53728847d85aea5e16588f23c4b6285d948`. It predates the final immediate-input, wall-stop, tutorial-hit, slowdown, focus-pause, and settings-label fixes. The final package has a full simulated completion and launch verification; its entire render benchmark was not repeated. No base M1/8 GB or every-Mac performance guarantee is made. Brief headless checks and an older idle native window coexisted during the measured run.

## Visual and input evidence

`native-round2/captures` contains actual automatic-play screenshots at 15/90/190/365 seconds and victory. `final-native/captures/title.png` is the delivered package's title render. `final-visuals/captures` contains seven explicitly **staged** current-source Metal screenshots, created with `tests/visual_check.gd`; they check layout and visual language, not successful human play.

CUA operated the native app selected by its bundle: Enter started a run, W/Space moved and dashed, Escape paused, Settings opened and returned with the timer held at 00:16, and Return to Title worked. The control surface did not expose a process/PCK association, so this is supplemental native input evidence rather than a final-hash control certification. No prolonged human feel test or audible sound audition is claimed.

## Independent review cap

Three authorized review/fix cycles are recorded in [round 1](review-round-1.md), [round 2](review-round-2.md), and [round 3](review-round-3.md). Their post-fix observational scores are **7.385, 8.05, and 8.2/10**. Each report preserves its original findings and focused recheck. The requested score strictly above 9/10 was not established. Engineering correctness, automated victories, and frame timing do not establish subjective fun.

The legacy `active-metrics.json` predates the corrected render instrumentation. Its fixed physics-step statistic is not rendering-performance evidence.
