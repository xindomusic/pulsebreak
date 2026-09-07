# Playable review round 2 — initial observational review

Date: 2026-09-07. Reviewer: independent `playable_review` agent. This is **round 2 of the user's maximum three playable review-and-fix cycles**. Direct human control feel and audible sound quality remain provisional. This initial report freezes the candidate below; subsequent source fixes require an addendum rather than changing the original findings.

## Candidate and evidence

Native resource PCK SHA-256: `9baf31f347bf9665950003e2f29ce53728847d85aea5e16588f23c4b6285d948`, from `build/Pulsebreak.app/Contents/Resources/Pulsebreak.pck`.

| Inspected source | SHA-256 |
|---|---|
| `scripts/game.gd` | `395a6fde63d10a4601f403213b7603962667a27421be49594bca8a577d00ab13` |
| `scripts/enemy.gd` | `83080b2e38bc757eac90d6f196b1bfe38e68be6acf9922c0bf317313bdbd5482` |
| `scripts/rules.gd` | `2aad33f667f3141984b75b545ee6d3b541d4ed408c59ee09f4a8884b056c2fa4` |
| `scripts/hud.gd` | `2f532aa72cec48b5fa19ac482c606b699c1ce27f7407dc2d4fe74b6a5f257620` |

- Hardware: Apple M1 Max, MacBook Pro `MacBookPro18,2`, 10 CPU cores, 32 GB memory, macOS 26.6.2. Godot 4.7.2, Mobile renderer / Metal.
- Inspected current exported gameplay captures: `qa/native-round2/captures/run-15.png` and `run-90.png`, each 1728×1080. The native run was still in progress during this checkpoint; no current full-run timing JSON was available. The captures confirm the corrected thin bars, no energy-helper overlap, larger player silhouette, and readable principal HUD text. They show relatively sparse early encounters, so they do not establish peak-intensity readability.
- Earlier exported native run (`qa/native/active-metrics.json`): 47,036 actual elapsed render-frame samples; median **8.431 ms**, p95 **12.172 ms**, p99 **14.475 ms**; full automated victory. This is useful measured native evidence for the **earlier candidate**, not a current-candidate benchmark or an M1/8 GB guarantee. That report lacks settings and per-stage timing; the new source records both.
- Current normal simulation (`qa/latest-sim/active-metrics.json`): win at **405.6 seconds**, 30 hull, 266 kills, 373 shots absorbed, 102 pulses; Flare Drive / Aftershock / Hot Capacitor / Life Circuit / Chain Reaction. Assist and Overdrive off, low effects off, shake 0.45, volume 0.65. Simulation is correctly labeled and has no claimed rendering samples.
- Alternate simulation (`qa/alternate/active-metrics.json`): death at **283.5 seconds** with Flare Drive / Static Field / Wide Receiver / Plasma Wake. With Assist, alternate build reached the boss but died at **369.45 seconds**, adding Horizon Ring. These retained losses improve the evidence's honesty. They do not prove those builds are unwinnable: build preference and random seed both change, and the same bot does not deliberately optimize field placement.
- Main-reported rule/save checks: 25 and 68 clean. Independently read the expanded integration suite and `/tmp/pulsebreak-result-loop.log`: **31 checks, 0 failures**, including isolated-fixture victory/unlock persistence, saved Overdrive, and three repeated result/restart cleanup cycles. Reviewer did not launch extra engine processes during the native performance run. Round 1's independent executions remain documented in its report.
- README, license notices, save validation, and current gameplay changes were inspected. Reviewer did not operate native UI or audition audio. Code and test evidence do not establish human fun.

## Improvements confirmed since round 1

The dedicated practice-complete screen persists. Current input labels and existing practice hints refresh after remapping; keypad Enter is now rejected consistently in live remapping. Charger warning width now includes player/contact radius and the warning length stops at the first wall intersection. The latter reveals a remaining discrepancy with actual movement described below.

Aftershock now repeats at the same radius and exactly 45% of the original damage formula. Dash replenishment calls the readiness cue, and pulse sound strength varies with stored charge. Scheduled anchor gunners reduce dependence on random gunner selection, and every boss attack now includes an absorbable volley. The boss has 3,400 hull; the current successful simulation's finale lasted about 45.6 seconds. Each upgrade restores 20 hull, helping builds without Life Circuit. Victory/Overdrive persistence is implemented and exercised. The revised native captures visually close the previous bar-layout defect.

## Three consequential remaining defects

### 1. Dash can commit to the old direction when movement and dash arrive together

**Priority: P1 — control correctness.** In `scripts/game.gd:310–313`, `facing` updates only in the physics callback. The keyboard handler at lines 290–292 calls `dash()` immediately, and `dash()` at lines 376–378 copies that previously sampled `facing` without reading the current movement input.

**Source-traced repro:** move right until facing points right. Between two physics ticks, release right and press up plus dash. Input state now points up, but the dash locks right for its full duration; the following physics callback updates `facing` too late to change `dash_direction`. This is especially relevant to quick defensive direction changes. It was not independently reproduced with native keyboard control; it is a deterministic path through the inspected source. The QA bot explicitly assigns `facing` immediately before dashing and therefore avoids this human input path.

**Concrete fix:** resolve a normalized current movement vector when accepting the dash input, falling back to the saved facing only when movement is zero. Give the bot an explicit direction parameter or a shared input-command path so the production fix does not accidentally break its intentional aim. Test a direction change plus dash before the next physics tick, diagonal movement, and stationary fallback.

### 2. A diagonal charger continues along the wall after its displayed lane ends

**Priority: P1 — attack telegraph fidelity.** `scripts/enemy.gd:114–121` correctly shortens the warning to the first arena-wall intersection. During the actual charge, lines 86–88 continue advancing in the original direction each tick, while lines 125–126 clamp x and z independently. After reaching one wall, the remaining component of movement slides along it, beyond the shortened warning.

**Source-traced repro:** charger at `(13, 0, 0)`, committed direction approximately `(0.707, 0, 0.707)`. The warning ends near `(14.5, 0, 1.5)`. Over the 0.65-second lunge, the charger can continue along x=14.5 toward z≈6.43. A player around `(14.4, 0, 4)` can be hit in a location outside the shown path. The precise final distance varies by tick discretization; the untelegraphed wall segment exists regardless.

**Concrete fix:** use the same precomputed travel limit for warning and motion, stopping the charge at the first boundary intersection. Alternatively, explicitly telegraph the full bent path, though stopping is simpler and matches the current visual language. Regression: near-wall diagonal lunge, prove the actor never travels beyond its shown endpoint; repeat for all four boundaries and corner cases.

### 3. Practice advances after an empty pulse, including while its targets are still invulnerable

**Priority: P2 — teaching the central ability.** When the first shot is harvested, `scripts/game.gd:488–492` spawns the teaching cluster and asks for a pulse. New enemies retain the 0.85-second spawning protection (`scripts/enemy.gd:68–74`, `158`). Practice advances whenever `rules.pulses > 0` (`game.gd:493–496`), even if no pulse damaged an enemy.

**Source-traced repro:** complete the harvest step, then immediately press pulse while the newly created cluster is spawning. The pulse is consumed and can hit none of the three teaching targets; the tutorial still announces that the core move is learned. Pulsing from empty space also satisfies the step. This makes the most important lesson able to succeed without demonstrating its effect.

**Concrete fix:** require at least one successful direct pulse hit on a valid teaching target, and make the teaching cluster ready before prompting the action. Keep the lesson recoverable after a miss by retaining or replenishing sufficient training energy and maintaining available targets. Regression: empty pulse does not advance; pulse during spawn does not advance; a damaging pulse does; the miss path remains completable.

The main agent has independently confirmed these source paths and plans focused failing regressions and fixes. This report does not pre-credit those future changes.

## Remaining evidence limits

Native menu inspection and the current full-run benchmark are in progress separately. Current captures are early gameplay, not a direct assessment of the full revised boss with sound. The alternate build losses are meaningful evidence to retain, but the available driver comparison cannot isolate upgrade balance from seed and policy differences. Scheduled anchor spawns improve harvesting availability; a measured four-second reachable-volley guarantee is still not established. These are evidence limits, not additional demands to enlarge the game's scope.

The exact >9 acceptance threshold requires direct control, repeated complete builds, peak visuals with sound, and a full current exported loop. Passing engineering checks alone cannot meet it.

## Initial observational score

| Category | Weight | Score | Evidence and limit |
|---|---:|---:|---|
| Movement, dash, and impact feel | 25% | 7.5 | Resource/collision invariants and active runs work; same-tick directional input defect remains, human feel unverified. |
| Combat decisions and fairness | 20% | 7.5 | More reliable volleys and clearer attacks; wall-slide discrepancy remains. |
| Build choices and replayability | 15% | 7.4 | Exact card behavior, universal repair, Overdrive, and retained alternate-build trials; no alternate complete victory yet. |
| Visual clarity, art, and audio | 15% | 7.8 | Corrected native HUD and coherent silhouettes; early captures only for this export, no listening. |
| Onboarding, controls, and usability | 10% | 8.0 | Practice exit, live binding labels, and persistence improved; pulse lesson can falsely succeed. |
| Mac performance and reliability | 15% | 8.5 | Earlier native p95/p99 are encouraging and restart persistence is exercised; current complete benchmark still pending. |
| **Weighted total** | **100%** | **7.73 / 10 (7.7 rounded)** | **Observational; >9 is not established.** |

No main-run blocker was identified in the available evidence. The three findings are concrete fixes to control predictability, fairness, and learning. Post-fix rating is pending a focused independent recheck of their implementation.

## Round 2 post-fix addendum

Focused recheck: 2026-09-07. This is the second round's post-fix assessment, **not round 3**. The fixes were reviewed in source and in the recorded regression outputs. The long native benchmark still uses the original round-2 export; no claim is made that it contains these later fixes.

| Revised source | SHA-256 at recheck |
|---|---|
| `scripts/game.gd` | `00220b83695db476556d5074b313d1350a4a0e263c5d614282d3a7d1833bf4aa` |
| `scripts/enemy.gd` | `a293864a5f6188e3bb1b58dd5be5cf3a6a01f727014e5130d43c0d949d83f387` |
| `tests/integration_test.gd` | `885426ffdca872749fad5cedefc0bfcf29ae3b5176e42fc1eaeb0b9aa67f7607` |

The reviewer independently read `/tmp/pulsebreak-review2-red.log` and `/tmp/pulsebreak-review2-green.log` and traced the corresponding assertions. Before the fixes, four new checks failed: immediate-direction dash, first-wall charger stop, empty pulse lesson, and immune-target pulse lesson. A fifth failure came from the test fixture entering the save check while still in practice; the revised fixture starts a normal run before testing victory persistence. The final log reports **36 checks, 0 failures**, with no errors/warnings. This is inspection of recorded execution evidence; the reviewer avoided launching a duplicate engine process during the native benchmark.

### Finding status

1. **Old-direction dash: resolved for the production input path.** `game.gd:378–383` reads current movement actions at dash acceptance when `qa_mode` is false, normalizes nonzero input, and preserves the existing facing for stationary fallback. The regression presses right, calls dash before any physics update, and verifies `Vector3.RIGHT`. The bot's explicitly aimed direction remains separate. Actual keyboard feel remains a hands-on verification item, but the identified stale-sampling path is removed.

2. **Unwarned charger wall slide: resolved for the identified case.** `enemy.gd:133–139` implements a shared `distance_to_wall()` calculation. Both the warning length and each charge movement use it; a shortened step sets `charge_time` to zero. The focused regression starts the diagonal lunge from `(13,0,0)` and verifies that it stops at exactly `(14.5,0,1.5)` with no remaining charge time. Source inspection confirms the sign handling covers both boundaries on each axis. Native crowded-edge play was not performed by this reviewer.

3. **Empty practice pulse accepted as success: resolved.** `game.gd:407–414` records a training success only from a non-echo pulse that hits a live, non-spawning target. `update_practice()` now advances on this recorded hit, which resets on each fresh run. An empty or spawn-protected pulse keeps the lesson active and shows an explicit retry message. Regressions exercise both miss cases and then a damaging pulse that advances to step 3. The teaching gunners remain alive and automatic fire is disabled before that step, preserving a source of charge for recovery. The test replenishes energy directly between assertions; it does not independently simulate the player's complete miss-and-reharvest sequence.

### Additional visual evidence

Inspected `qa/native-round2/captures/run-190.png` from the **pre-fix round-2 export**. It shows the cyan player, an explicit broad pink charger lane, several orange diamond projectiles, and separated health/energy labels with thin bars. The lane's direction is much easier to identify than in round 1. The player and enemies remain small relative to the arena, and this single mid-run frame does not establish all peak combinations or audio clarity. The capture supports the presentation score; it does not validate the later first-wall motion correction.

### Post-fix observational score

| Category | Initial round 2 | Post-fix | Reason for change |
|---|---:|---:|---|
| Movement, dash, and impact feel | 7.5 | 8.0 | Fresh-input direction is verified in the regression; direct-control feel remains provisional. |
| Combat decisions and fairness | 7.5 | 8.0 | Warning and wall-limited charge now use the same geometry. |
| Build choices and replayability | 7.4 | 7.4 | No new alternate-build completion evidence in this focused recheck. |
| Visual clarity, art, and audio | 7.8 | 8.1 | New mid-run native capture clearly shows the warning lane, diamonds, and corrected HUD; sound still unauditioned. |
| Onboarding, controls, and usability | 8.0 | 8.5 | Training now requires demonstrated pulse impact and preserves a retry path. |
| Mac performance and reliability | 8.5 | 8.5 | Regression evidence is stronger; current complete native benchmark remains separate/pending. |
| **Weighted total** | **7.73** | **8.05 / 10 (8.1 rounded)** | **Observational only; >9 is not established.** |

The three reported defects are closed at the source/regression level. The remaining score limits chiefly concern direct playing and listening, complete alternate-build evidence, and a final exported candidate's complete performance record. This addendum does not infer those missing observations from automated checks.

Late evidence received during this same recheck: independently read `qa/round2-fixed-sim/active-metrics.json`. The fixed source completes the full normal run at **405.6 seconds with 30 hull**, 266 kills, 373 absorbed shots, and 102 pulses, using the same five upgrades as before. It correctly reports simulation=true, zero render samples, and null frame percentiles. This closes the post-fix full-loop simulation check; the identical driver outcome does not independently exercise the wall or human-input cases, which are covered by the focused regressions. Also inspected the pre-fix native `run-365.png`: boss and player silhouettes, boss health bar, and wrapped five-upgrade summary are readable. It shows early boss phase one, not phase-two peak intensity. The observational rating remains **8.05/10**.
