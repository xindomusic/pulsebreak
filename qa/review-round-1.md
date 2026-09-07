# Playable review round 1 — initial observational review

Date: 2026-09-07. Reviewer: independent `playable_review` agent. This is the first of the user's maximum three playable review-and-fix rounds. It is an **observational review**, not a hands-on endorsement of control feel or fun.

## Candidate and evidence

- Native candidate: `build/Pulsebreak.app`; exported resource PCK SHA-256 observed during review: `6b15687e2b49f2a9aaafeafb1ef430f06a1a7656408e346f63253736582c9b80`. Main agent reports universal ARM64 support and successful strict code-sign verification. Reviewer did not independently repeat launch or signing checks and did not operate the native UI.
- Source reviewed: `DESIGN.md`, all combat/game/UI/save scripts, audio integration, test suites, and existing QA reports. Source was changing during integration; locations below refer to the source inspected for this initial candidate. Fixes require a focused recheck.
- Test hardware independently identified: MacBook Pro `MacBookPro18,2`, Apple M1 Max, 10 CPU cores, 32 GB memory; macOS 26.6.2. This is not an M1/8 GB performance test.
- Inspected graphical captures: title, 00:15, 01:30, 03:10, and 06:05; also the newer native title and 00:15 captures. Earlier captures preceded the closer camera and darker ambient adjustment. Newer 00:15 capture shows improved actor scale, but the visible energy bar still overlaps its helper line; verify that the latest exported PCK includes the HUD fix.
- Independently executed existing engineering suites: **25 combat-rule checks, 68 save checks, and 14 integration checks; all passed, no warnings/errors in these runs**. Logs: `/tmp/pulsebreak-review-rules.log`, `/tmp/pulsebreak-review-save.log`, `/tmp/pulsebreak-review-integration.log`.
- Existing graphical active bot report: win at 395.8 seconds, 231 kills, 264 absorbed shots, 71 pulses, 80 hull remaining; build Aftershock / Chain Reaction / Life Circuit / Horizon Ring / Flare Drive. Existing passive simulation report: death at 134.8 seconds, 39 kills, zero harvests/pulses. This is useful evidence that active abilities matter to this driver. It is not a controlled human study, and passive play also gives up dash protection.
- The old `physics_p95_ms: 16.666...` is a fixed physics-step value and **must not be cited as rendering performance**. Source now measures elapsed render frames and labels simulations. Full native metrics were pending at this review checkpoint. Actual saved settings were not recorded by the original report; viewport captures alone do not establish assist/effects settings.
- No direct sound audition, repeated human control, alternate full-build playthrough, or worst-wave frame-time trace was available to this reviewer. These limits are reflected in the scores.

## Three highest-priority findings

### 1. Practice completion's default Resume action immediately pauses again

**Priority: P1, onboarding state defect.** `scripts/game.gd:469–473` leaves `practice_step == 3` and `practice_timer > 12` when opening the pause screen. `on_ui_action("resume")` at line 221 resumes the practice run, then the next `update_practice()` enters the same completion branch. `scripts/hud.gd:220–225` focuses Resume as the primary action.

Source-traced repro: complete movement, harvest, and pulse practice; wait for the 12-second charger segment; press Enter on the focused Resume button (or Escape); the next simulation tick returns to the completion pause. A player can escape through Restart Run or title, so this does not block the main game, but the default completion action is broken.

**Concrete fix:** introduce a consumed completion step or dedicated practice-complete state, with a primary **Start Full Run** action and a secondary replay/title action. If continued practice is supported, mark completion once before resuming. Focused regression: complete training, activate every offered exit, verify each leads to a stable state and tutorial completion saves once.

### 2. The charger telegraph does not reveal the committed intercept lane

**Priority: P1, combat readability/fairness.** `scripts/enemy.gd:92–96` captures `charge_direction` with a velocity prediction. The windup at lines 74–80 shows only the same pulsing circular ring used for other enemies. The model does not turn to the committed `charge_direction` until `perform_attack()` at lines 109–111, when the lunge begins. This contradicts DESIGN's visible intercept-lane promise.

Source-traced repro: move laterally near a charger when its cooldown expires, then change direction during its 0.8-second windup. The hazard ring signals *an attack*, but neither a ground lane nor the facing silhouette accurately shows the frozen predicted path. Mixed chargers make incoming body contact harder to explain.

**Concrete fix:** show a ground strip/arrow along the frozen `charge_direction` for the whole windup, with width matching collision and visible length matching the wall-truncated lunge. Turn the model when the direction locks. Keep the cue visible under low effects. Focused recheck: stationary, lateral, wall-edge, and two-charger cases; compare displayed lane with actual motion/contact.

### 3. Remapping works in InputMap while every teaching prompt keeps the old keys

**Priority: P2, controls/usability.** Rebind handling at `scripts/game.gd:244–253` updates input, but `scripts/hud.gd:206`, `337–338`, and practice/run hints at `scripts/game.gd:199`, `202`, `458`, `463` hardcode WASD / Space / E. The player can bind dash to Q and pulse to R, restart, and still be told to press Space/E to complete the core tutorial. Those inputs then do nothing unless rebound to another action.

**Concrete fix:** provide one binding-label formatter and pass current bindings into HUD and tutorial text; refresh visible prompts immediately after remap/reset and on every new run. Keep arrow alternatives accurately described. Validate live accepted keys with the same reserved-key rules as save validation; keypad Enter is currently excluded by save validation but not the live handler. Focused recheck: Q/R remap, a swapped movement pair, reset, restart, and reload, checking both displayed text and actual action.

## Additional quality and specification gaps

- Dependable volley scheduling is not implemented independently of live enemies. The director (`game.gd:434–446`) randomly selects gunners, and automatic fire can kill them before their first volley. In the first 15-second capture, the player has 20 fallback charge from four kills and no demonstrated harvested volley. The boss skips volleys on every third attack (`enemy.gd:117–126`), leaving approximately 6–8 seconds between volley attacks in that part of the pattern. Consider a fixed telegraphed arena volley cadence and measure usable harvest opportunities; do not reactively replace a killed gunner.
- First native gameplay still shows mostly empty floor and small enemy silhouettes. The closer camera helps, but captures do not show clear projectile motion trails or distinct charger lanes. The art has coherent cyan/orange roles, recognizable foundry machinery, and unobstructed floor; it does not yet establish polished peak-intensity readability.
- The observed boss lasted about 35.8 seconds versus the design's intended 60–120 seconds. Timing is tuning, not a blocker, but the finale's pacing and phase-two readability deserve human play before increasing health.
- Nine independent upgrade effects and five unique picks exist, but only one complete build has been demonstrated. Echo's described 45% repeat uses a nonlinear formula (`game.gd:366`, `369–371`), so actual damage varies around that figure. Verify card language against effect behavior. The optional higher-pressure mode after victory is absent.
- The current tests cover important state/resource invariants but not practice completion, live remapping, charger telegraph fidelity, human input timing, or repeated full-run restart. The available automated full win cannot substitute for these.
- Render timing should record settings and segment samples by early play, minutes 4–6, and boss, with warm-up/loading reported separately. A run-wide percentile alone can hide a bad short interval. No 1920×1080 M1/8 GB target claim is supported yet.
- Audio assets and voice-priority management are present, and shutdown regression reports plus independent clean test exits are encouraging. Readiness audio exists as an asset but no `cue("ready")` call is wired when a dash replenishes; pulse audio strength is fixed for normal pulses. Source review does not establish perceived mix quality.

## Initial score

These are **provisional observational scores**, based on the limited evidence above. They are not substitutes for the rubric's missing direct-control and sound evidence.

| Category | Weight | Initial observational score | Basis / limitation |
|---|---:|---:|---|
| Movement, dash, and impact feel | 25% | 7.5 | Swept projectile handling, bounded dash and recovery work in tests; repeated human control and impact feel unverified. |
| Combat decisions and fairness | 20% | 7.0 | Active bot strongly outperforms passive; intercept lane and dependable harvest cadence are missing. |
| Build choices and replayability | 15% | 6.8 | Nine implemented effects and unique offers; one demonstrated full build, little evidence of build-specific strategy. |
| Visual clarity, art, and audio | 15% | 7.2 | Coherent original arena and colors; small actors, HUD overlap, missing directional cue, no listening evidence. |
| Onboarding, controls, and usability | 10% | 6.5 | Settings/save recovery and menus exist; practice completion and remap instructions have reproducible source defects. |
| Mac performance and reliability | 15% | 7.5 | Native capture/export report plus 107 clean independent checks; real full native frame data and repeat loops pending. |
| **Weighted total** | **100%** | **7.15 / 10 (7.2 rounded)** | **Observational only.** |

The >9 target is **not established**. No serious main-run blocker was found in the inspected evidence, but the usability defects should be fixed and the missing direct-play/sound/performance evidence collected before declaring the playable build high quality. Post-fix rating is intentionally left pending a focused independent recheck of the resulting candidate.

## Round 1 post-fix addendum

Focused recheck: 2026-09-07. This addendum closes the first round's review-and-fix cycle; it is **not round 2**. It reviews the revised source and a headless regression run. The concurrently running native benchmark uses the earlier export, so its captures cannot establish the appearance or input behavior of these source fixes. Native re-export, frame metadata, boss tuning, and encounter scheduling changes are outside this focused recheck.

Source identifiers observed at the recheck checkpoint:

| File | SHA-256 |
|---|---|
| `scripts/game.gd` | `845c5e7c3105d16fa31e95b06967e9b8c336da4bae1a5523e6ae955903695dda` |
| `scripts/hud.gd` | `07a0e7c5e98a493c94e83e8def3655491721be1eb30946e47593baae7cc8a9b6` |
| `scripts/enemy.gd` | `88df7183ff2ccfc02df4a7e8ee28558168b667457a53805b9b59cb29441c35da` |
| `tests/integration_test.gd` | `145ef93126044af3de467eef78a73c76cbc78f44ba712f49657ae44d1e6fed9a` |

The independent command `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pulsebreak-review1-postfix-integration.log --script tests/integration_test.gd` exited 0 with **20 checks, 0 failures**, no warnings/errors. It printed `HUD_BAR_SIZE (238.0, 7.0) min (1.0, 1.0)`. The earlier 25 rule and 68 save checks were not unnecessarily repeated for this narrow recheck.

### Fix verification

1. **Practice completion trap: resolved in source and targeted runtime regression.** `game.gd:474–477` enters `practice_complete`, which is excluded from combat updates. `hud.gd:237–246` offers Begin the Full Run, Practice Again, and Return to Title, with Begin focused. There is no Resume action on this screen. The regression drives completion and verifies the primary action starts a non-practice run. The existing start/retry/title handlers reset or clear the run. Secondary buttons were inspected in source rather than individually activated by a native UI test.

2. **Missing charger direction cue: substantially addressed, with geometry caveats.** `enemy.gd:49–61` creates an `AttackLane` strip; lines 109–111 show it in the saved world direction when windup begins. Neither charger facing nor the saved direction changes during windup. The strip hides at attack launch and the model turns to the same direction. The regression checks visibility and unchanged saved direction after the player moves. This establishes the direction contract in source/runtime state, but does not yet prove screen readability in a crowded native encounter. The strip is only **0.4 units wide**, while body contact can occur across **2.14 units** of width (`2 × (0.65 + 0.42)`), and its fixed 8.8-unit length is not clipped at arena walls. Treat it as a directional warning, not an exact safe boundary; improve its width/end treatment before presenting it as a collision footprint.

3. **Hardcoded remapped controls: resolved for current HUD, rebuilt title, and newly generated tutorial hints; one live-refresh edge remains.** `configure_input()` now passes bindings into HUD, `hud.gd:358–359` reads current key names, and start/tutorial messages use the same bindings. The regression changes pulse to Q and verifies the HUD starts with Q. Pausing *during an existing practice instruction*, rebinding, and resuming does not regenerate the already stored `hint.text`; that hint can still name the previous key until another step replaces it. This is a narrower remaining issue than the original always-wrong tutorial. The live handler's keypad-Enter validation also still differs from save validation. Neither residual is covered by the current new assertion.

4. **HUD bar overlap root cause: resolved in runtime geometry.** The bar helper now disables percentage text and installs styles before assigning its final size (`hud.gd:115–130`). The independently measured health-bar height is exactly 7, supporting the main agent's diagnosis of size being clamped by the previous default minimum. The same helper creates energy/boss bars. A current exported screenshot is still needed to close visual verification; earlier native images should not be reused as evidence of the fixed layout.

The original pause trap is closed. The other two principal findings have clear implemented improvements with the residual details above. Clean teardown in this independent run is consistent with the reported audio shutdown fix; it does not establish audible sound quality.

### Post-fix observational rating

| Category | Initial | Post-fix | Reason for any change |
|---|---:|---:|---|
| Movement, dash, and impact feel | 7.5 | 7.5 | No new direct-control evidence. |
| Combat decisions and fairness | 7.0 | 7.3 | Committed direction is now shown; lane geometry and crowded play remain unverified. |
| Build choices and replayability | 6.8 | 6.8 | No new full-build evidence in this recheck. |
| Visual clarity, art, and audio | 7.2 | 7.5 | Bar geometry is corrected and directional cue exists; exported visual/sound recheck pending. |
| Onboarding, controls, and usability | 6.5 | 7.8 | Practice completion is usable and binding prompts largely fixed; live hint-refresh edge remains. |
| Mac performance and reliability | 7.5 | 7.5 | New regression is clean; full current-export frame evidence remains pending. |
| **Weighted total** | **7.15** | **7.385 / 10 (7.4 rounded)** | **Observational only; >9 is not established.** |

The increase credits demonstrated fixes, not expected future improvements. The direct-control, audio-listening, alternate-build, and native performance limitations from the initial review continue to apply.
