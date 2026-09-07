# Playable review round 3 — final authorized review cycle

Date: 2026-09-07. Reviewer: independent `playable_review` agent. This is the **third and last authorized review-and-fix cycle**. The rating remains observational: this reviewer has not directly controlled a complete native run or listened to the soundtrack and cues. Those limits are separate from the concrete usability findings below.

## Reviewed candidate

- Export: `build/Pulsebreak.app`.
- Exported PCK SHA-256: `1f62983a5b959a0584f3c071ef52e654ead01231db20252dbf64e8e233983d76`.
- Inspected gameplay SHA-256: `scripts/game.gd` = `00220b83695db476556d5074b313d1350a4a0e263c5d614282d3a7d1833bf4aa`; `scripts/enemy.gd` = `a293864a5f6188e3bb1b58dd5be5cf3a6a01f727014e5130d43c0d949d83f387`. These include the round-2 control, wall-stop, and practice-impact fixes.
- Environment: Godot 4.7.2; macOS 26.6.2; MacBook Pro `MacBookPro18,2`, Apple M1 Max, 10 CPU cores, 32 GB memory. This is not an M1/8 GB test.

## Independent verification

The reviewer reran the engineering suites for this source: **25 combat-rule checks, 68 save checks, and 36 integration checks — 129 total, all passed without warnings/errors.** Logs are `/tmp/pulsebreak-review3-rules.log`, `/tmp/pulsebreak-review3-save.log`, and `/tmp/pulsebreak-review3-integration.log`. The integration suite covers the previous findings, isolated victory/unlock saving, and repeated restart cleanup.

`codesign --verify --deep --strict --verbose=2 build/Pulsebreak.app` passed: valid on disk and satisfying its designated requirement. `file` independently identified both x86_64 and ARM64 architectures. The bundled `Contents/Resources/LICENSES.md` matches the project notice byte for byte. The **exported executable itself** launched and exited cleanly in a two-frame headless smoke check (`/tmp/pulsebreak-review3-export-launch.log`). That check verifies the packaged application's load path, not graphical frame performance or control feel.

The post-fix full simulation already recorded in `qa/round2-fixed-sim/active-metrics.json` wins at **405.6 seconds with 30 hull**, 266 kills, 373 absorbed shots, and 102 pulses. It is correctly labeled as a simulation with no rendering samples. The original and alternate-build losses remain documented in round 2; no alternate full victory is claimed here.

## Visual inspection

Independently inspected all seven images under `qa/final-visuals/captures`: title, unlocked settings, upgrades, practice completion, combat, boss, and result. Read `tests/visual_check.gd` to establish their provenance. They are **staged current-source graphical captures**, not seven moments in a natural playthrough and not a frame-time benchmark.

- Title has a clear primary action and legible controls. Settings with Overdrive unlocked fits the viewport, including all six bindings, reset, and Back.
- All three staged upgrade cards fit their titles, descriptions, and install controls. The shared 20-hull repair is communicated before choosing.
- Practice completion has clear full-run/retry/title actions. Result shows score, time, five upgrades, unlock message, and restart/title without clipping.
- Combat presents distinct player/gunner/charger/bruiser silhouettes, orange diamonds, a broad pink charger warning, separate dash/energy indicators, and the corrected thin health bars.
- The staged phase-two boss frame has a readable boss bar, volley, ground ring, and announcement. It is not peak-intensity evidence: only one staged hazard and one volley are shown. Actors are still small relative to the arena, and sustained readable motion cannot be proven from stills.

No layout blocker or major overlap was found in these seven screens. They materially improve visual coverage over the previous rounds.

## Native performance evidence and its boundary

Independently read `qa/native-round2/active-metrics.json`. It records the earlier round-2 PCK (`9baf31f…`, identified in that round's report), before the final input/wall/practice fixes. Its complete automated native win used a 1920×1080 window, a preserved 16:10 game image of **1728×1080**, Mobile/Metal, normal mode, Assist off, Low Effects off, shake 0.45, volume 0.65. The logical viewport is 1440×900.

| Native elapsed-frame measure | Result |
|---|---:|
| Samples after the initial 3 seconds | 48,258 |
| Overall median | 8.462 ms |
| Overall p95 | 10.353 ms |
| Overall p99 | 11.754 ms |
| Worst minute by p95: minute 5 | 10.964 ms |
| Minute-5 p99 | 12.425 ms |
| Boss p95 | 10.071 ms |
| Boss p99 | 11.172 ms |

All reported stage p95 values meet 16.7 ms on that candidate and machine. This is real elapsed render-frame evidence, unlike the obsolete fixed physics-step number from the initial build. It does **not** establish an exact 1920×1080 rendered game image, an M1/8 GB guarantee, a benchmark of the final PCK, or measured shader/loading warm-up; the first three seconds are excluded rather than separately characterized. The later fixes are narrow, but transferring the earlier performance result to the final PCK remains an inference.

## Three remaining findings

These are lower-priority correctness/usability issues, not main-run blockers. Their paths are source-traced unless a test is stated; native user interaction was not used to reproduce them by this reviewer.

### 1. Static Field's description promises a slow that charger lunges ignore

**P2 — upgrade expectation.** `scripts/rules.gd:12` says the field slows enemy movement by 50%. `scripts/enemy.gd:85` calculates the slow-adjusted `move_speed`, but the charge branch at lines 86–90 moves using fixed 14/9-unit speeds, independent of `slow`.

Repro path: acquire Static Field, leave a field in a charger's route, and let it cross while lunging. Normal walking is slowed, but the dangerous lunge retains full speed despite the broad card claim. This does not mean the upgrade has no effect; its effect is narrower than described.

**Concrete fix:** state explicitly that the field slows walking/approach movement and not lunges, or consistently apply the slow to the lunge and verify the resulting telegraph remains conservative. Clarifying the card is the smaller change. Check both the displayed card and the actual movement condition.

### 2. Overdrive can be changed during a run without explaining that it applies next run

**P2 — settings feedback.** `scripts/game.gd:212` snapshots `settings.overdrive` into `hard_mode` only in `start_run()`. The settings action at line 244 changes the saved preference immediately but does not change `hard_mode`. The unlocked settings text (`scripts/hud.gd:273`) does not disclose this timing.

Repro path: on an unlocked profile, start normal mode, pause, enable Overdrive, and resume. The toggle remains enabled while this run continues with normal enemy/wave tuning. The inverse also occurs when disabling it during an Overdrive run. Deferring difficulty to the next run is reasonable; the UI should say so.

**Concrete fix:** label the setting as applying to the next run and display the current run's difficulty in HUD/result, or disable that toggle for an active run with a clear explanation. Do not silently retune existing enemies mid-encounter.

### 3. Losing native window focus leaves combat running

**P2 — native usability.** `scripts/game.gd` has no focus-loss notification handler. Its active simulation guard (`_physics_process`, around lines 296–307) depends on run/boss state, not window focus. A user switching applications or minimizing during an active run can return to lost health or a defeat.

This is an observable implication of the source's state handling, not a claimed native reproduction. DESIGN does not explicitly mandate focus-loss pause, so it is **not treated as a specification blocker**. It is a concrete usability concern for a single-player native keyboard game.

**Concrete fix:** pause an active run/boss on window focus loss, preserve its previous state, and require deliberate resume on return. Keep headless/QA automation behavior explicit. Verify timer/health freeze while unfocused and no automatic resume surprise.

## Initial round-3 observational rating

| Category | Weight | Score | Basis and remaining limit |
|---|---:|---:|---|
| Movement, dash, and impact feel | 25% | 8.0 | Corrected input and collision paths, clean regressions; repeated human feel remains unobserved. |
| Combat decisions and fairness | 20% | 8.0 | Completed active run, explicit lanes, corrected boundary behavior; full human boss fairness unverified. |
| Build choices and replayability | 15% | 7.4 | Nine effects and persistent Overdrive; alternate builds tried but not completed, card exception remains. |
| Visual clarity, art, and audio | 15% | 8.3 | Seven clean staged screens plus earlier natural gameplay captures; audio listening and peak motion still unverified. |
| Onboarding, controls, and usability | 10% | 8.6 | Prior tutorial/remap defects closed and screens readable; two settings/focus behaviors need clearer handling. |
| Mac performance and reliability | 15% | 8.9 | 129 independently clean checks, packaged launch/signature/architectures verified, strong prior native stage timings; final-PCK full benchmark absent. |
| **Weighted total** | **100%** | **8.15 / 10 (8.2 rounded)** | **Observational only.** |

The >9 target is **not established**, and build/replay evidence remains below the rubric's minimum category threshold. The game has a complete evidenced automated loop and no identified serious functional blocker. Direct human control, listening, and additional successful build strategies are missing evidence rather than defects that can be fixed by changing a score. Any focused recheck of the three findings above belongs to this final cycle; a fourth quality-improvement round is not authorized.

## Final post-fix assessment — review cycles complete

This focused recheck completes round 3. **No fourth improvement round was performed.** The final delivered PCK SHA-256 is **`0f2eca2b50180c9dd17f6ea15b74ac89989059490e6e3ea44e0b6f471abdae4d`**. Source identifiers independently read at this checkpoint:

| File | SHA-256 |
|---|---|
| `scripts/game.gd` | `c53a4dd18d46be92b8e2a6b2a4fe0617cccf29342a1964144df5f69d65bdd352` |
| `scripts/enemy.gd` | `59608500105ab2ee33932e4c6018b018f213b9dd070d751d9b9543ebbef490db` |
| `scripts/hud.gd` | `d64b0828829a629fc69e32240a14907334b94dc70a748dbce97378f67d245c9b` |

All three final-cycle findings are addressed:

1. **Static Field now affects committed charger movement.** `enemy.gd:88–90` multiplies charge travel by 0.5 while slowed, before applying the common wall limit. The new regression observes 0.7 units traveled during 0.1 seconds instead of the unslowed 1.4. The fixed attack duration means a slowed lunge travels less far, so the existing warning remains conservative rather than understating its reach.
2. **Overdrive clearly applies next run.** The setting now says “tougher enemies + waves, next run.” Independently inspected the refreshed staged unlocked-settings image: the complete text fits beside the toggle. Existing run difficulty is deliberately unchanged.
3. **Focus loss pauses ordinary live play.** `_ready()` connects the window's `focus_exited` signal to `pause_on_focus_loss()` (`game.gd:121–125`). The handler preserves run/boss state, opens Pause, and exempts the explicit QA driver. There is no automatic focus-return resume. The regression emits the actual connected signal and verifies paused state with the previous run state retained; the existing pause test establishes timer/cooldown freezing.

Independently inspected `/tmp/pulsebreak-review3-red.log` and `/tmp/pulsebreak-review3-green.log`: both new behavior checks failed before implementation, then **38 integration checks passed**. Independently read the fresh delivery logs `/tmp/pulsebreak-delivery-rules.log`, `/tmp/pulsebreak-delivery-save.log`, and `/tmp/pulsebreak-delivery-integration.log`: **25 + 68 + 38 = 131 passing checks**, no errors/warnings. The initial round-3 suites were independently executed by this reviewer; the final two added behaviors were verified through source, assertions, and the recorded fresh executions.

Repeated independent strict signature verification passed for the final PCK's application, and its bundled license notice still matches the project file. Independently inspected `qa/final-native-sim/active-metrics.json`, produced by the main agent's final exported-app headless run: **full normal victory at 405.6 seconds, 30 hull, score 12,830**, 266 kills, 373 absorbed shots, 102 pulses. It correctly records `simulation: true`, no GPU name, zero render samples, and null frame percentiles. This closes the final package's automated complete-loop evidence; it is not a final native graphics benchmark.

The final alternate run (`qa/final-alternate/active-metrics.json`) still dies at 283.5 seconds with Flare Drive / Static Field / Wide Receiver / Plasma Wake. The targeted slow correction is proven by its regression; this unchanged bot outcome neither invalidates the correction nor demonstrates successful alternate-build balance. The retained loss remains a material limit on build/replay confidence.

Also independently inspected the final packaged native title capture, `qa/final-native/captures/title.png`, and its launch log: the actual final application renders its title correctly using Metal 4.0 / Forward Mobile on the M1 Max. The title and refreshed staged-capture logs contain no errors/warnings. This closes basic graphical launch verification for the final package, while full final-PCK graphical performance remains unmeasured.

The main agent additionally reports native Return-to-start, movement/dash, Escape pause, settings/back with a frozen timer, and return-to-title checks. These are useful supplementary input checks, but the UI tool did not expose a reliable PID/PCK association, so they are not treated as proof of the exact final candidate or as a human judgment of sustained feel. Actual audio audition is still absent. Earlier real native stage timings retain the candidate/resolution boundaries stated above.

### Final observational score

| Category | Weight | Final score |
|---|---:|---:|
| Movement, dash, and impact feel | 25% | 8.0 |
| Combat decisions and fairness | 20% | 8.0 |
| Build choices and replayability | 15% | 7.5 |
| Visual clarity, art, and audio | 15% | 8.3 |
| Onboarding, controls, and usability | 10% | 9.0 |
| Mac performance and reliability | 15% | 8.9 |
| **Final weighted observational rating** | **100%** | **8.205 / 10 — 8.2 rounded** |

The small final increase credits the corrected upgrade promise and the resolved settings/focus behaviors. **The requested above-9 threshold was not achieved or evidenced.** No serious functional blocker remains identified in this review, and the final exported package completes the automated full loop. The principal remaining limits are human control/sound assessment, successful complete play with other upgrade families, and a full graphical performance run tied to the exact final PCK. These limits are disclosed without extending the authorized three-cycle process.
