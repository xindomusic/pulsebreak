# Overdrive independent review

Date: 2026-09-13. Reviewer: independent `quality_review` agent. Starting commit: `c4fa60b`. Scope: the user's follow-up about Quit, model quality, laser/weapon feel, hit and death satisfaction, audiovisual weapon upgrades, and randomly generated continuous levels.

This is a fresh review. The prior Skybound technical/visual rating was provisional and did not include human feel or listening acceptance. In particular, its model score does not override the original player's dissatisfaction. Prior reviews remain unchanged. The rubric below responds to the new feedback, so its result is not directly comparable with the earlier rubric.

## Baseline and priorities

The baseline has real jump/glide, three ordered sectors, gate collision, an articulated courier, menus and a functioning harvest/pulse loop. Its shot is a brief generic line, hit/death feedback is limited, and it ends after a predetermined third-sector Guardian. The player explicitly finds the model and impacts insufficient and cannot find a Quit action. These are relevant experience failures even where earlier code tests passed.

The implementation team received four initial recommendations: distinct behavioral weapon roles with distinct audiovisual signatures; separate contact and destruction feedback with bounded clutter; seeded valid encounter modules with pressure/recovery and indefinite travel; and visible working Quit plus an understandable end-of-run path. [Research and source limits](../docs/OVERDRIVE_RESEARCH.md) accompany these recommendations.

## Weighted rubric

Score each category 0–10 and multiply by its weight divided by ten. The weights sum to ten. Scores describe the user's requested experience, not mesh counts, test counts or implementation effort. Missing evidence remains unverified and cannot earn excellence by default.

| Category | Weight | Evidence needed for a 9-level assessment |
|---|---:|---|
| Weapon behavior and visual identity | 2.00 | Clearly different useful roles, satisfying visible attacks, meaningful upgrades and readable results in actual combat; visuals agree with range and collision. |
| Hit and death feedback | 1.50 | Immediate comprehensible contact, directional reaction, satisfying distinct destruction, preserved movement responsiveness and danger readability during overlapping kills. |
| Player model and animation | 1.25 | A persuasive silhouette/material presentation at gameplay scale, coherent weapon integration, expressive motion and a materially better player-facing result than the rejected candidate. |
| Generated levels and continuous pacing | 2.00 | Reproducible real layout/encounter differences, valid traversable space, pressure and recovery, recurring milestones, indefinite working travel and convincing variety across repeated play. |
| Progression and reward | 0.75 | Upgrades change the next fight and support distinct builds; choices and equipment remain clear; later levels avoid an unbounded health grind or exhausted choices. |
| Usability and exit flow | 0.50 | Discoverable working Quit, pause/title/results flow, readable controls/objectives and no loss of run context when ending continuous play. |
| Audio identity and mix | 1.00 | Actually auditioned distinctive firing/impact/upgrade cues, clean layering and danger audibility under sustained combat; file existence and waveform differences are insufficient. |
| Reliability and performance | 1.00 | Relevant regressions, independent seed/continuity checks and final native evidence pass without crashes, softlocks, invalid layouts or accumulating transient objects. |
| **Total** | **10.00** | A strong numerical result still requires the acceptance gates below. |

5 = functional prototype; 7 = solid with clear roughness; 8 = polished but limited; 9 = excellent short playable showcase supported by direct evidence; 10 = exceptional with negligible relevant weaknesses. This is a local rubric, not an event-selection or AAA certification.

## Acceptance protocol

1. Record exact candidate identity, engine/platform, settings, viewport and artifact provenance. Separate staged visual fixtures, production-input simulations and native runs. Do not label headless/fixed-step timings as rendering performance.
2. Independently rerun relevant rules, saves, integration, traversal, gate and campaign suites. Inspect failed and successful logs. Add or review behavioral weapon checks, actual Quit invocation in an isolated process, boss-to-next-level travel and reset/equipment persistence.
3. Sweep many seed/level pairs, including early lessons, boss multiples and large indices. Check deterministic equality, meaningful diversity, bounds, objective/shutter/spawn clearances, safe entry and traversability. Inspect multiple actual renders rather than accepting a changed seed label as visual variety.
4. Exercise repeated completion and travel across at least two boss milestones. Check transient cleanup and persistent run state after every handoff; retain failure cases. Also run a continuous production-policy attempt so fixture travel is not confused with normal combat viability.
5. Inspect normal-camera weapon and model motion, nonlethal hits, kills, busy combat, Low Effects, generated variations, upgrades, title/pause/Quit and results. Inspect effect timing and readable direction, not only a single attractive frame.
6. Measure final native frame intervals through busy combat and later levels without parallel engine load. The existing local p95 target is 16.7 ms at the stated settings; report actual values and presentation limits honestly. Check active-object counts over repeated travel.
7. Qualitative audio requires actual listening. Human feel and learning require actual play. The original player's follow-up is negative baseline evidence; improved code alone cannot establish that their experience is now satisfying. Record what was heard/played and by whom, or leave it explicitly unverified.

No unresolved crash, softlock, impossible required objective, broken Quit, major misleading damage effect or progression reset is compatible with acceptance. A confirmed overall score above nine additionally needs convincing player and listening evidence; a technical/visual provisional result must retain that qualification and disclose its denominator. Do not extrapolate ten minutes of generated continuity to proven indefinite balance.

## Candidate findings and evidence

The candidate materially improves every requested area. It has visible working Quit actions; a redesigned articulated courier with a mounted weapon; four projectile weapon families and ranked upgrades; localized hits and mechanical destruction; and seeded generated sectors after the three authored lessons. The following independent findings were corrected during review:

| Priority | Finding | State |
|---|---|---|
| P2 | `SYNCHRONIZED GATES` shared a phase but randomized individual speeds, so the advertised beat drifted. | Shared speed and sampled-time equality checks pass. |
| P2 | Projectiles tested their full last-frame travel before checking remaining range, allowing hits beyond the advertised range. | Travel is clipped before collision; boundary regressions pass. |
| P2 | After clipping, swept enemy motion still covered the whole frame rather than the projectile's shorter lifetime, allowing a late-crossing false hit. Position-distance subtraction also left a tiny range residue. | Independent reproductions now pass after time-fraction and scalar-distance corrections. |
| P2 | Splash damage ignored shutters although direct and chain fire respected them. | Same-side splash works; targets behind a closed shutter remain protected. |
| P2 | The production targeting poll quantized both base and rank-V carbine firing to 0.300 s, swallowing the advertised cadence upgrade. | Polling now permits the weapon's own cooldown to determine firing. Actual 60 Hz game-loop tests establish faster upgraded cadence; complete runs were repeated afterward. |
| P2 | Arc/plasma profile colors disagreed with effects; the HUD additionally multiplied those colors by an existing cyan tint. | Model, projectiles, cards and refreshed HUD use aligned weapon colors. |
| P2 | Rank-up cards emphasized later tiers without explaining the immediate purchase benefit. | Current damage changes or unlock cadence appear in the refreshed draft. |
| P2 | Repeated full shutter instructions overlapped the required glide relay. | Full teaching text remains in the first sector; later compact status labels sit above the left post. Refreshed sector 07 shows the primary instruction clearly. |

Art review also led to coherent torso/weapon aiming, compact folded wings, generated route floor graphics and bounded landmark variation. The art agent found and fixed Low Effects trimming that could discard the newest essential contact cue; its regression was independently rerun. These observations describe resolved development defects, not outstanding blockers.

### Independent behavioral checks

The coordinator authorized this reviewer to own [weapon](../tests/weapons_test.gd) and [audio](../tests/audio_test.gd) tests. The initial weapon run exposed the two post-clamp boundary problems above; a later production-loop check exposed the cadence issue. The final expanded suite passes **50/50**. It covers actual projectile-triggered flash/recoil and restoration, one-time kill rewards, fragments surviving source-enemy removal and expiring, delayed contact, moving-target collision, cone/chain/pierce behavior, altitude and cover, upgrade/cycling limits, projectile caps, pause/cleanup and actual game-loop firing cadence.

The independent audio suite passed **44/44**. It decoded all eight new source WAVs as stereo 44.1 kHz, 16-bit PCM: non-silent, no saturated samples, small DC offset and distinct channels/data. The highest measured source peak was **0.7260** of full scale. It also verified all 21 declared engine cues load, twelve reusable voices, priority/reserved-slot behavior, cooldowns, bounded pitch variation, music duck/recovery, intensity, volume and mute. These are objective asset and runtime-state checks. They do **not** establish perceived weapon identity, mix clarity, combined-output headroom or enjoyment; this reviewer did not listen to the cue reel or gameplay.

Independent execution covered all twelve suites. The initial complete wrapper run passed 479 checks; subsequent relevant final reruns bring the audited suite inventory to **491 checks, zero assertion failures**:

| Suite | Passed checks | Relevant evidence |
|---|---:|---|
| Rules / save / integration | 25 / 84 / 39 | Core state, migrations and production integration. |
| Traversal / altitude / campaign | 34 / 34 / 31 | Jump/glide, shared gate geometry and campaign progression. |
| Generation | 47 | 768 sampled layouts plus determinism, clearance, time-dependent gates, live relay collection, distant indices and cosmetic isolation. |
| Weapons / audio | 50 / 44 | Independent behavioral and asset/runtime checks described above. |
| Endless | 45 | Production checkpoint callbacks, multiple boss handoffs, exhausted upgrades, reset/bank and actual Quit exits. |
| Combat FX | 22 | Pool caps, source removal, pause/expiry, Low Effects and preservation of recent essential feedback. |
| Native controls | 36 | Injected keyboard movement, gait/jump/glide/landing, weapon cycling, rebinding and focus behavior. |

Changed weapon, audio, FX, generation, campaign, endless and integration suites were independently rerun after their relevant fixes. The last runtime change only repositions compact gate text. The wrapper's sandboxed processes emitted a macOS certificate-store permission diagnostic; there were no script/parse/assertion failures. Direct approved-engine reruns did not emit that diagnostic. This environmental output is not silently described as an error-free log.

The endless test activates the actual Quit button in four isolated engine subprocesses: title, pause, results and checkpoint. Its boss handoff fixtures deliberately kill a fixture boss; those checks establish transition correctness and are separate from the complete combat attempts below. Save fixtures use isolated paths. Final native execution separately reports **36 checks, zero failures and 11 captures** on Metal/Apple M4; it injects input events into production handlers rather than using human keyboard play. Focus isolation for capture and the explicit original focus callback check are documented in the test source.

### Observed visual evidence

The [visual manifest](overdrive-visual/visual-evidence.json) has 52 staged native Metal images, including refreshed affected generated, hit and busy-combat frames. PNG headers independently confirm all 52 are **1440×900**. Inspection covered title/armory, each weapon's normal-camera flight/contact, close/mid courier, side/rear aiming, nonlethal hit at 0/80/200 ms, destruction at 80/240/600 ms, matched Full/Low Effects combat, and generated sectors 04/05/07. Weapon examples use the production camera size 31.8; hero close/mid views use 5.4/10 and impact studies 14. These are staged fixed-step presentation studies, not human gameplay or native frame benchmarks.

The courier has a shaped helmet/chest, dark mechanical joints, a visible mounted firearm, distinct family/rank attachments and upper-body aiming. The side/rear examples retain coherent weapon mounting. Native input captures separately show gait, takeoff, deployed wings and landing; all eleven control-capture PNGs are **1280×800**. This is a materially stronger visual result than the rejected baseline, though the small gameplay-scale figure and geometric construction still set a limit on character expressiveness. Close-up quality does not by itself establish animation feel.

Projectile source and travel are visible; spread and chain attacks have distinct shapes and results. Hits briefly alter the struck silhouette and then restore the original material. Death separates recognizable armor pieces and dissipates afterward. The refreshed draft communicates the immediate upgrade benefit and title Quit is obvious. In the matched busy scene, twelve enemies and 37 remaining hostile shots coexist with readable red warning shapes. Full Effects has 63 active FX; Low Effects has 25 and disables shadows. Essential contacts and threats remain visible in both. These observations support visual readability and feedback differentiation, not a claim that the original player now finds killing satisfying.

Generated examples visibly change relay routes, shutter counts, floor inlays and conservative side scenery placement. The gold required GLIDE instruction remains clear after the final status-label move. Static arena branding contains “07” while the route/HUD can show another number; this is inherited arena branding, not a stage-state reset, but can be mistaken for a sector number. It is a minor presentation ambiguity.

### Procedural scope and limits

Source review and 768 sampled layouts establish reproducible structured generation after the three authored introductory sectors. Six mirrored/jittered route templates support three or four relays, one to three shutters, five mechanically mapped modifiers, varied enemy order and hazard sites/rhythm. Every third sector has a Guardian. The generator bounds active pressure and preserves safe entry/exit, objective approaches, opening windows and a central hazard-safe lane. Generated floor dressing follows the real route using a separate cosmetic random stream; tests confirm it does not change the gameplay dictionary or combat random state.

Absolute stage indexing continues beyond the initial campaign and recent checkpoint history is capped at 32. Testing sampled distant indices and real base-glide collection supports continuity and reachability within those constraints. It does not prove every possible seed, infinite balance or a fresh experience forever. The arena footprint, three environments and recurring Guardian moves remain familiar. This is meaningful generated encounter variety within a repeated arena grammar; it is the clearest remaining content limitation for a stronger showcase score.

### Complete-run evidence inspected

The reviewer independently read these final coordinator-run reports after the firing-cadence fix and generated dressing were saved:

| Artifact | Seed | Result | Evidence |
|---|---:|---|---|
| [Final normal metrics](overdrive-final-normal/active-metrics.json) | 271828 | **Twelve sectors, four Guardians, 38 relays; banked at 391.20 s with 98 hull.** | Carbine V and seven overclocks; all nine reactor upgrades, then later service checkpoints. Final active enemies/projectiles/hazards/FX were zero; 85 FX objects were pooled. |
| [Final alternate metrics](overdrive-final-alternate/active-metrics.json) | 42 | **Six sectors, two Guardians, 18 relays; banked at 223.82 s with 76 hull.** | Carbine III, plasma I and scatter II; different reactor build. Final active enemies/projectiles/hazards/FX were zero; 92 FX objects were pooled. |

Both reports explicitly identify simulation, `accelerated:false`, and zero render-frame samples. They establish finite continuous production-policy progress through generated levels and multiple bosses. Final cleanup counts and bounded-pool tests support resource handling but are not a full memory-leak proof. They do not establish rendering performance, indefinite balance or human difficulty.

Earlier six-sector wins remain at `qa/overdrive-normal` and `qa/overdrive-alternate` as pre-cadence candidate evidence. The earlier accelerated failure remains at `qa/overdrive-simulation`; the coordinator corrected the driver's low-fuel glide retry policy before the successful nonaccelerated runs. The failure was not converted into a win or discarded.

### Final identity and native performance

Runtime identity: branch `feat/skybound-showcase`, baseline `c4fa60b`, [runtime manifest](overdrive-source.json) aggregate identifier `250ced67026099d57dae50e83037227c0954ed22557c2c943a94f2d91792ac80`. The reviewer independently recomputed and matched all 64 individual file hashes, including assets and import settings. QA scripts, captures and this review are outside that runtime manifest. Platform: Godot 4.7.2, Metal Forward Mobile, Apple M4 / 16 GB, macOS 26.6.2.

The reviewer read the final [native metrics](overdrive-native/active-metrics.json) and [engine log](overdrive-native/native-run.log), and inspected its actual combat/result captures. The coordinator ran one native engine with no other test/capture engine alongside it, without headless, fixed-fps or accelerated simulation, and with `--disable-vsync`. Assist, Overdrive and Low Effects were off; shake was 0.45 and volume 0.65. The run banked six sectors, two Guardians and 18 relays at 223.82 game seconds with 76 hull, matching the final alternate simulation's build and outcome. The log has no script or engine errors.

All four native PNG headers independently confirm **1280×800**, agreeing with the recorded OS window. The **1440×900 design viewport** in the JSON is a separate value, not the captured output size. Warm-up excludes the first three seconds; these are elapsed render-loop intervals, not direct GPU execution time or input latency.

| Native measurement | Result |
|---|---:|
| Measured intervals | 15,008 |
| Median | 16.508 ms |
| p95 | 18.143 ms |
| p99 | 18.796 ms |
| Boss p95 | 18.230 ms |
| Worst non-boss sector p95 | 18.177 ms, sector 5 |

The strict **16.7 ms p95 target remains unmet**. Despite the disable-vsync request, intervals cluster near a 60 Hz presentation cadence; compositor or driver pacing may contribute, but this run does not establish the cause or hidden GPU headroom. It supports a completed stable native run at the stated resolution and settings, not a universal 60 fps guarantee. The benchmark has the same 64-file runtime identity verified again after completion.

### Provisional assessment

The independent **provisional technical/visual score is 8.9/10**. The observed categories earn 7.985 of their available 9.00 weighted points: `7.985 / 9.00 × 10 = 8.872`, rounded to one decimal. Audio's 1.00 weight remains unscored because there was no listening. This is an assessment of the observed portion, not a confirmed overall audiovisual or human-fun score. The numerical result is an independent judgment, not proof of AAA or event-selection quality.

| Category | Provisional score | Main reason and remaining limit |
|---|---:|---|
| Weapon behavior and visual identity | 9.1 | Four genuinely different collision/attack roles, visible travel and meaningful ranks; corrected range, cover and production cadence. Human preference and sustained build balance remain untested. |
| Hit and death feedback | 9.0 | Localized reactions and readable timed destruction, with essential Low Effects cues preserved. Visual response is established; subjective satisfaction is not. |
| Player model and animation | 8.8 | Stronger courier silhouette, integrated weapons, aiming and input-driven flight/landing. Geometry and gameplay-scale expressiveness remain limited, and the original player has not accepted the redesign. |
| Generated levels and continuous pacing | 8.5 | Real seeded route/mechanic differences and a twelve-sector completion. Repeated arena and Guardian grammar limits sustained surprise. |
| Progression and reward | 9.0 | Distinct ranks/builds, immediate benefit descriptions, preserved equipment and service after choices exhaust. Only finite automated build trajectories were tested. |
| Usability and exit flow | 9.2 | Visible functioning Quit, bank/continue, clear equipment and compact relay guidance. Minor arena-number branding ambiguity remains. |
| Audio identity and mix | Unverified | 44 objective checks pass; no audition or human mix acceptance. |
| Reliability and performance | 8.8 | 491 audited behavioral checks, repeated completed runs and a clean final native completion. Native p95 is 18.143 ms, above the 16.7 ms target. |

The next substantial improvements should target distinct arena topology/Guardian encounters and expressive character/combat motion, then compare those changes in uncoached play and listening with the original player. Presentation pacing also needs investigation to meet the stated performance target. More particles or a favorable number alone would not close those gaps. No blocking gameplay defect remains in the tested scope, but the performance gate and human/audio acceptance remain open. The current evidence supports a substantially improved playable candidate; it does not support a confirmed score above nine.
