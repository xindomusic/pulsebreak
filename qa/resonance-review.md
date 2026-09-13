# Resonance independent review

Date: 2026-09-13. Reviewer: independent `quality_review` agent. Baseline: `dd5608f`. Scope: stronger colors, a drum-and-bass soundtrack selected by the player, engaging combat sound and cooler pulse/blast feedback. No prior review is rewritten or inherited as player acceptance.

The earlier player response remains negative evidence about presentation. This review will judge the current visible/audible result, not reward implementation effort, feature counts or a requested numerical target. The [research](../docs/RESONANCE_RESEARCH.md) records baseline source observations, a 174 BPM arrangement proposal and primary-source limits.

## Rubric

Each category receives a 0–10 score multiplied by its weight divided by ten. Weights sum to ten. Unverified audio is not silently awarded a score; any partial technical/visual score must disclose its denominator.

| Category | Weight | Evidence for an excellent result |
|---|---:|---|
| Color direction and readability | 2.00 | Clearly stronger environment/character separation, cohesive vivid accents and readable threats/objectives at the gameplay camera, including Low Effects. |
| Combat visual impact | 2.00 | A decisive pulse with readable origin, expansion and decay; varied meaningful blasts; no misleading damage area or obscured next threat. |
| Drum-and-bass composition and adaptation | 2.00 | An actually heard rolling groove, sub/mid-bass definition, evolving arrangement, convincing breaks/drops and combat changes that preserve musical continuity. |
| Sound effects and mix | 1.50 | Actually heard shot/contact/kill/pulse identities that remain clear under music and multiple enemies, with controlled loudness and useful danger cues. |
| Playable flow and retained depth | 1.50 | Responsive flight/combat, meaningful weapon builds, legible upgrade/exit flow and continued generated progression without new regressions. |
| Stable target-device experience | 1.00 | A complete native M4 run with consistent settings, clear source identity and no material freezes, runaway effects/audio or broken transitions. |

5 = functional prototype; 7 = solid with clear roughness; 8 = polished with evident limits; 9 = excellent short showcase supported by direct evidence; 10 = exceptional within the stated scope. This is not an event-selection or AAA certification. The 16.7 ms p95 optimization goal will be reported honestly, but it is not an automatic blocker to a 9-level judgment; sustained stability and actual player impact determine the performance assessment.

## Acceptance protocol

1. Inspect exact source/assets and record final identity. Read baseline and new generators to establish changed musical structure rather than a tempo-only edit.
2. Decode PCM independently: matching sample lengths/rates/channels, bounded peaks/DC, loop-boundary continuity and meaningful section contrast. Inspect the summed representative mix, not only individual stems. These checks establish physical properties, not taste or perceived loudness.
3. Test the selected engine API: synchronized looped stems, intensity smoothing and limits, no playhead reset on state/gain changes, meaningful battle response, event duck/recovery, mute/volume, pause/title transitions and clean resource shutdown. Preserve existing priority/reserved-voice checks.
4. Produce a playable preview covering the arrangement plus representative combat sounds and ducking. State whether it is an offline mix or actual engine recording, and whether anyone actually listened. A file's existence is not listening evidence.
5. Inspect matched native shots across all environments, busy Full/Low Effects combat and a timed pulse sequence. Compare output at normal camera size; close-ups supplement rather than replace it. Preserve threat shapes and actual damage boundaries.
6. Rerun relevant gameplay/effect/audio regressions and complete a production-policy route through generated travel and bosses. Distinguish fixture checks from actual completion.
7. Run a coordinated single-instance native M4 measurement. Record actual output/window dimensions, settings, warm-up policy, active-combat and transition behavior. Compare tails and sustained pacing without treating `_process` intervals as direct GPU execution time.
8. Record uncoached play and listening when available. If missing, leave those conclusions unverified and issue only a clearly qualified observed-component score.

## Candidate review

The new palette and pulse sequence visibly improve contrast and event emphasis. All 592 automated checks passed on the first Resonance audio candidate. After the player auditioned a preview and requested more aggressive bass and drums, both audio suites passed again on the revised assets and mix: 92 checks, with no new failures. The revised stems preserve identical sample timelines and the music director responds to battle without restarting playback. A final native M4 run completed six sectors and two Guardians.

**Observed-component assessment: 9.0/10, covering 6.5 of the rubric's 10 weight points. Overall game/audio quality remains unrated.** The 3.5 points assigned to composition and perceived sound quality are ungraded. This is a provisional short-showcase assessment of directly inspected visual and technical evidence, not a confirmed whole-game score above 9 or an AAA qualification. It is not directly comparable with earlier whole-rubric estimates.

Initial arrangement recommendation was changed after the player selected drum and bass: 174 BPM with a broken kick/snare groove, ghost hits, sub plus upper bass, evolving lead, three synchronized layers and a composed 64-bar arc. There is no remaining four-on-the-floor requirement.

Listening status: this reviewer has not listened to the baseline or new soundtrack. The player has auditioned a preview and requested stronger bass and drums; that is a revision request, not acceptance. Research source text and code inspection must not be described as an audition.

### Visual inspection

The [staged visual manifest](resonance-visual/visual-evidence.json) records 20 native Metal images on Apple M4. Independent PNG-header inspection confirms all are 1440×900. Inspected images include title, all three sector palettes, busy combat, full-charge pulse at 60/180/450 ms, Low Effects at 180 ms, minimum-charge pulse and echo. Normal gameplay examples use camera size 31.8. The script manually advances fixtures at fixed steps; these captures are not a human playthrough or performance sample.

The new navy/cobalt and aubergine/violet surfaces give the pearl/cobalt courier and warm enemy armor stronger separation. Thin perimeter accents establish a more deliberate color composition. The three environments retain their machinery and route language, while the richer colors avoid washing the whole screen into one bright hue. HUD and required relay instructions remain readable.

The pulse shows its source, an expanding cyan boundary and tapered radial shards. At 180 ms the effect is visibly more substantial, with red charger lanes and orange shot fans still distinguishable. By 450 ms the major core/front have cleared, leaving faint arc remnants and damaged-machine fragments. The minimum-charge effect occupies a smaller area; the echo retains its intended radius. Low Effects reduces secondary light/debris while retaining the principal ring and source. This supports the requested visual improvement without claiming that screenshots establish felt impact.

The full-charge fixture peaks at 144 active effects against a 160 limit; the matching Low Effects fixture has 62 against a 72 limit. At 450 ms these fall to 31 and 15. The matched busy scenes retain 12 enemies and 37 hostile projectiles, with 63 versus 25 effects. There is no visible opaque arena-wide flash or new blocking label overlap in the inspected images. The underlying arenas remain compact repeated deck spaces; richer color and blast presentation do not establish new environmental scope. The final native Guardian frame has a minor copy inconsistency: the small gate subtitle still says "LINK RELAYS TO UNLOCK" while the larger objective correctly directs the player to break the Guardian.

### Composition and independent asset checks

Source inspection confirms a new composition rather than a faster version of the old loop: 174 BPM, syncopated kicks, backbeat snares and ghost hits, variable hats, centered sub, detuned upper bass, chord changes and evolving lead phrases. Its 64 bars contain an introduction, first drop, development, suspension/rebuild, varied second drop and a return section. Three stereo stems share one `AudioStreamSynchronized` resource. The foundation remains present while drive and lead gain respond to local threats, incoming shots, charge and Guardian state.

The revised synthesis raises Reese upper-bass and sub contributions, increases the snare body, reinforces backbeats and blends a saturated drum/bass signal with its dry signal. Runtime gains also favor foundation and drive while reducing lead prominence. This directly addresses the player's request in timbre, density and balance. It remains a candidate for listening approval.

The reviewer independently decoded the final Ogg/WAV assets with FFmpeg to floating-point PCM, without calling the synthesis generator or trusting its reported peaks. All three music files contain exactly 3,892,966 stereo frames at 44,100 Hz: 88.275873 seconds, the rounded duration of 256 beats at 174 BPM. Ogg page granules and the imported engine resource lengths also agree in the automated suite.

| Decoded asset | Sample peak | RMS | Largest endpoint step |
|---|---:|---:|---:|
| Foundation Ogg | 0.927165 | 0.184066 | 0.002324 |
| Drive Ogg | 0.832902 | 0.070150 | 0.001038 |
| Lead Ogg | 0.743622 | 0.138517 | 0.001479 |
| Pulse WAV, 1.25 seconds | 0.879944 | 0.080958 | 0 |
| Independently summed music at −4/−5/−12 dB stem gains | 0.893915 | 0.133097 | 0.000829 |

No decoded sample reaches full scale. The summed music's RMS rose from the first candidate's 0.072299 to 0.133097, approximately 5.3 dB more average signal level; this is not a perceptual loudness score. Arrangement contrast remains measurable: drive RMS falls to 0.01709 in bars 32–35 and rises to 0.09339 during the following rebuild; lead RMS rises from 0.08846 in the introduction to 0.17287 in the second drop. The foundation's largest channel DC offset is 0.001156, approximately −59 dBFS, a small residual introduced by the added nonlinear processing. This was reported to the coordinator; it does not cause full-scale clipping in these files.

These measurements establish changed content, section contrast and sample headroom. They do not establish musical quality, perceived loudness, a subjectively clean loop or output true peak. Source PCM and final lossy-file endpoints are different measurements, so a tapered source cannot by itself establish an inaudible encoded seam.

Two playable artifacts are supplied: the [full arrangement](../docs/audio/resonance-dnb.mp3) and a [36-second representative battle mix](../docs/audio/resonance-battle.mp3). Both are offline exports. The latter uses normal volume, family-specific firing cadences and scripted event ducking; it is not a recording of actual gameplay. Independent decoding gives peaks of 0.923450 and 0.619308, with no full-scale samples. The battle preview's new 300 ms end fade leaves a final sample amplitude of 0.0000025, correcting its earlier abrupt cutoff.

### Actual engine audio artifact

The [engine recording metadata](resonance-engine-audio.json) and [playable MP3](../docs/audio/resonance-engine.mp3) document a separate 36-second native CoreAudio capture at volume 0.65. The recorder follows the production Master limiter. The first half installs each rank III weapon; at 18 seconds the fixture invokes production Guardian entry with four escorts. Two full charges are injected. Enemy attacks, weapon collision, the automated pilot and music adaptation then use production behavior. This is explicitly staged audio evidence, not a completed route or human playthrough.

Its recorded telemetry reaches 10 hostile projectiles and approximately 0.639 music intensity. The capture therefore covers actual incoming-fire and Guardian response, while not demonstrating a maximally saturated encounter. Independent WAV-header and sample inspection confirms 1,728,512 frames of 48 kHz stereo PCM: 36.010667 seconds, peak 0.436523 and RMS 0.064030, with no near-full-scale samples. Independent decoding of its MP3 gives the same duration, peak 0.433122 and a final sample amplitude below 0.000005 after the preview fade. The reviewer has not listened to this artifact.

### Automated evidence

The reviewer ran `sh tools/test.sh` after final asset import: all 14 suites passed, totaling **592 checks**. The generation suite separately samples 768 layouts; that sample count is not added to the assertion count.

| Suite | Checks | Suite | Checks |
|---|---:|---|---:|
| Rules | 25 | Save | 84 |
| Integration | 39 | Traversal | 34 |
| Altitude | 34 | Campaign | 31 |
| Generation | 47 | Weapons | 50 |
| Endless | 45 | Combat effects | 22 |
| Pulse effects | 53 | Existing audio regression | 44 |
| Resonance audio | 48 | Native-control logic in headless mode | 36 |

The new audio suite verifies the final Ogg files directly, synchronized playback ownership and loop metadata, independent pressure inputs, finite-value guards, attack/release behavior, gains and mute without player replacement, pulse duck/recovery, routine-fire exemption and the actual enabled Master limiter at a −1 dB ceiling. The existing audio suite preserves voice priorities, reserved slots, cue limits and cleanup. Pulse checks include actual mesh vertices against the damage sphere, airborne footprints, immediate damage/spend, echo behavior, pause and Low Effects changes, and bounded cleanup.

Logs are in the local test output directory `/tmp/pulsebreak-tests.dqRoBe`. The macOS certificate-store permission diagnostic appears in these sandboxed engine launches; no script, parse or assertion error occurs. Headless control checks establish input/state logic, not fresh native keyboard or human-play evidence.

After the stronger rhythm revision, the reviewer reran the existing and new audio suites: 44 and 48 checks passed with clean logs at `/tmp/pulsebreak-resonance-revised-audio.log` and `/tmp/pulsebreak-resonance-revised-adaptive.log`. These are repeated checks, not 92 additional unique assertions. The unchanged gameplay/effect suite results remain applicable. A separate [native control run](resonance-controls/native-controls.log) also passes all 36 checks on Metal/Apple M4 and supplies 11 input-driven captures. The reviewer inspected its successful log; this automated native run is not uncoached human play.

### Independent integration finding

The new battle-state update initially ran before the old Classic director's time-based `set_intensity(run_time/360)` call. That later call overwrote threat-driven music during Classic play. The coordinator removed the obsolete overrides. Four passing cases now exercise the actual complete Classic callback at early/late calm states, with a nearby threat and when pausing. Director-only tests would miss the ordering defect.

### Native M4 completion and pacing

The [final native metrics](resonance-native/active-metrics.json) record one native automated run without accelerated simulation or a forced frame rate, on Apple M4, 16 GB memory, macOS 26.6.2 and Godot 4.7.2 using the Mobile Metal renderer. The coordinator reports one engine instance and no competing test or capture engines. Full Effects, volume 0.65 and shake 0.45 were enabled; Assist and Overdrive were disabled. Window dimensions and independent headers of all four captured PNGs agree at **1280×800**, with a 1440×900 design viewport.

Seed 42 completed six sectors, two Guardians and 18 air relays, banking at **223.82 game-clock seconds with 76 hull**. Its legal build ended with kinetic III, plasma I and scatter II, five reactor upgrades, 18 pulses and 37 absorbed shots. The reviewer inspected the Guardian and banked-result images. This is a production-policy automated completion, distinct from the staged audio Guardian fixture and from human play.

| Native render-interval measurement | Samples | Median | p95 | p99 |
|---|---:|---:|---:|---:|
| Active run, excluding initial three-second warm-up | 15,856 | 16.332 ms | 18.250 ms | 18.979 ms |
| Guardian segments | 6,999 | 16.015 ms | 18.313 ms | 19.047 ms |

The 16.7 ms p95 optimization goal is not met. The observed central and tail pacing nevertheless supports a stable short session on this M4 configuration, with completed transitions and no remaining active enemies, hostile projectiles or effects at banking. The effect pool retains 100 allocated nodes against its 160 cap. These frame intervals are not direct GPU execution times, a worst-frame bound or evidence about other resolutions/devices. No human-observed input-latency or long-session stability claim is made.

### Category judgment

| Category | Score | Weighted contribution | Reason and remaining limit |
|---|---:|---:|---|
| Color direction and readability | 9.0 | 1.80 / 2.00 | Richer, coherent sector colors separate the courier, hostile attacks and objectives. The small Guardian gate subtitle remains inconsistent. |
| Combat visual impact | 9.1 | 1.82 / 2.00 | Clear pulse origin, expansion and decay, meaningful scale, readable danger lanes and retained Low Effects identity. Felt impact still needs play/listening. |
| Drum-and-bass composition and adaptation | Ungraded | — / 2.00 | Arrangement, stronger rhythm, stream alignment and battle response are verified; the revised musical result has not been accepted by a listener. |
| Sound effects and mix | Ungraded | — / 1.50 | Actual engine output, cue priorities, ducking and numeric headroom are verified. Perceived impact, masking and tonal balance have not been assessed by this reviewer. |
| Playable flow and retained depth | 8.8 | 1.32 / 1.50 | Flight, weapons, generated travel and repeated Guardian completion remain supported by tests and the final route. Repeated arena structure and missing uncoached play limit the conclusion. |
| Stable target-device experience | 9.0 | 0.90 / 1.00 | Complete native M4 route with consistent settings and sub-20 ms p99 pacing. One measured configuration and no worst-frame trace limit generalization. |

Scored contribution is **5.84 / 6.50**, normalized to **8.98/10**, rounded to **9.0/10** for the observed portion. Unverified audio is neither assigned zero nor silently assumed excellent. The player's explicit request for more aggressive bass and drums drove a substantial revision; only another audition can establish whether that request is now satisfied.

### Final source identity and limits

After the native run, the reviewer independently recalculated all 73 runtime file hashes and the sorted-record aggregate in the revised [source manifest](resonance-source.json), with no mismatch. Its aggregate is `c08ceb78fc101c6c3ce857d27bade937e9562ccc04075b5dc6e0a7b665b2eaea`. The manifest includes runtime scripts, scenes, project/bus configuration, source assets and import settings; it excludes tools, tests, documentation and previews. Preview-only polish therefore requires its own artifact check, not a changed runtime identity. The superseded first engine recording and its source identity are retained under `qa/resonance-initial-audio/`.

No blocking regression was found in the reviewed candidate. Small remaining issues are the Guardian gate subtitle and the low-level foundation DC residual. The player's first listening response is recorded above. No acceptance of the revised mix or uncoached play observation has been received; perceived impact and player acceptance remain unverified. The review does not certify an overall score above 9 or AAA-show readiness.
