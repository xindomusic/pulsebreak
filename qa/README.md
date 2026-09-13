# Pulsebreak verification evidence

## Release 1.2.0 — current

[Release notes](../docs/RELEASE_1_2.md) · [Independent game grade](release-1.2-review.md) · [Final distribution package](release-1.2-package.json) · [GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.2.0).

- [Regression log](prism-tests.log): 591 checks in fourteen suites, including 91 audio checks and 768 generated layouts. [Generator safety log](prism-generator-tests.log): nine offline tests.
- [Audio review](prism-review.md) and [manifest](prism-music.json): 102.426-second original Prism Drive track; existing combat effects retained, no decoded clipping.
- [Native audio capture](prism-native-audio/release-engine-audio.json): 36 seconds of CoreAudio output and a verified live loop wrap. This is a staged audio demonstration.
- [Final package report](release-1.2-package.json): the release ZIP and checksum, updated asset notices, signatures and unchanged runtime PCK. [Feature-build package report](prism-package.json) preserves the previous local archive and exact resource/launch checks.
- [Overall game review](release-1.2-review.md): **8.4/10**, a weighted observational grade for the indie arcade demo, with human feel, current soundtrack taste and AAA readiness explicitly limited.

The 1.1 campaign/frame measurements below remain specific to that earlier package; a music-only update does not turn them into new performance evidence.

## Release 1.1.0 — historical

[Release notes](../docs/RELEASE_1_1.md) document the selected first ElevenLabs music candidate and packaged Mac game. Version-specific evidence:

- [Validation inventory](release-validation.json): **591 checks in fourteen suites**, all passed; the generation suite exercises 768 layouts. The 91 focused audio checks cover selected resources, looping, mixing, voice priority and mute/volume behavior.
- [Independent audio review](release-review.md) and [asset manifest](release-audio.json): accepted first-track provenance, five byte-identical prepared effects, four derived cues and all installed asset hashes.
- [Native audio recording metadata](release-native-audio/release-engine-audio.json): 36.01 seconds of production CoreAudio output with staged events, zero near-full-scale samples and verified loop transport. This is an audio demonstration, not a progression test or listening score.
- [Packaged native run](release-native/active-metrics.json) and [run context](release-native/run-context.json): M4 / 16 GB, 1280×800, Full Effects; three sectors, nine airborne relays and one Guardian completed at 97.13 game seconds. Active render intervals: median 16.654 ms, p95 18.459 ms, p99 18.992 ms across 5,622 samples.
- [Package report](release-package.json): universal 1.1.0 app, original/extracted signature checks, archive hashes and integrity checks for all 78 resource-pack members. The app and ZIP are local build artifacts, excluded from Git.
- [Source manifest](release-source.json): runtime source and import hashes at packaging, plus exact PCK and ZIP hashes. Its feature-branch label records packaging provenance; that revision was subsequently merged to `main`.

The player selected the first music audition for release. The review does not assign a new overall game rating. All version-specific reports below are retained historical evidence.

## Resonance follow-up

The earlier Resonance update is documented in [Resonance](../docs/RESONANCE.md), [research](../docs/RESONANCE_RESEARCH.md), [independent review](resonance-review.md), and [runtime source manifest](resonance-source.json). At that revision, **592 checks in fourteen suites** passed, including 53 pulse and 48 adaptive-audio checks. The [validation inventory](resonance-validation.json) separates numeric checks, native automation, staged visual captures, recorded engine audio and unverified human listening/play.

- `resonance-visual/visual-evidence.json`: 20 staged native images, with selected examples in `docs/images/resonance-*`.
- `resonance-audio.json`: source synthesis statistics; `docs/audio/resonance-dnb.mp3` is the full arrangement and `resonance-battle.mp3` is an offline representative combat mix.
- `resonance-audio-decoded.json`: independent decoding of the heavier revision requested after the player's first audition.
- `resonance-engine-audio.json` and `.wav`: actual native Master output, with scripted weapons/pulses and a staged Guardian encounter; an audition MP3 is in `docs/audio/resonance-engine.mp3`. The first candidate's engine recording is archived under `resonance-initial-audio`.
- `resonance-native/active-metrics.json`: target M4 six-sector native automation at 1280×800; consult the current review for exact results and interval limits.

Earlier reports below remain historical and do not describe the current source.

## Overdrive follow-up

The earlier Overdrive update is documented in [the Overdrive guide](../docs/OVERDRIVE.md), [research](../docs/OVERDRIVE_RESEARCH.md), [independent review](overdrive-review.md), and [runtime source manifest](overdrive-source.json). Its audited total was **491 checks in twelve suites**, with 768 generated layouts. See [the validation inventory](overdrive-validation.json).

- `overdrive-final-normal/active-metrics.json`: corrected weapon cadence; continuous fixed-60 simulation through twelve sectors, four Guardians and 38 relays; banked at 391.20 seconds with 98 hull. All nine reactor upgrades installed; later service rewards exercised.
- `overdrive-final-alternate/active-metrics.json`: second seed with different legal weapon choices; six sectors/two Guardians/18 relays, banked at 223.82 seconds with 76 hull.
- `overdrive-native`: final single-instance native alternate run; all captures 1280×800, six-sector success. 15,008 render samples, median 16.508 ms / p95 18.143 ms / p99 18.796 ms. The strict 16.7 ms p95 target is unmet.
- `overdrive-controls/native-controls.log`: native injected-keyboard run, 36 passing checks and 11 pose captures. These are synthetic inputs, not a human playtest.
- `overdrive-normal` and `overdrive-alternate`: earlier six-sector successes before the firing-scheduler correction. Retained as development evidence.
- `overdrive-simulation`: retained accelerated-driver loss at 64.60 seconds; the driver repeatedly attempted the glide lesson with depleted wing fuel. The later policy waits for enough fuel before a required glide. This is not a normal-frame-rate rendering or human-play result.
- `overdrive-visual/visual-evidence.json`: staged native appearance/motion evidence; raw 52 captures are ignored. Four weapon models at ranks I/III/V, normal-camera firing, hit/death time series, matched busy/LowEffects scenes, generated routes, and the armory. Selected images are copied into `docs/images/overdrive-*`.
- `overdrive-audio.json` and `overdrive-audio-preview.wav`: original stereo cue measurements and a 12-second audition reel. `tests/audio_test.gd` validates source PCM and runtime voice priority/ducking; no actual listening acceptance is claimed.

The independent review separates mechanical verification, staged imagery, native performance, and human/audio acceptance. A numerical score cannot certify showcase selection or AAA production quality.

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
