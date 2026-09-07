# Pulsebreak — discussion draft

Date: 2026-09-07. Status: approved for implementation by the user's “let’s do it,” following the design and Astra model recommendation.

## Recommendation

Build a compact, native Mac 3D action roguelite in **Godot 4.7.2**, using GDScript. Working title: **Pulsebreak**.

You are a courier with a stolen reactor core, trapped on a sky foundry. Enemy fire becomes your ammunition: bait a volley, dash through it to absorb energy, then release a pulse that tears through the surrounding machines. Survive six minutes of escalating combat and defeat the reactor guardian in a roughly one-to-two-minute finale.

The main promise is a satisfying repeated decision: spend charge now to escape a bad position, or risk moving through another volley for a bigger detonation. Basic shooting is automatic; positioning, dash direction, and pulse timing are controlled by the player.

The user approved proceeding with the recommended action roguelite direction.

## Research and engine choice

| Engine | Mac evidence | Assessment for this project |
|---|---|---|
| Godot 4.7.2 | Current official download includes Apple Silicon; official export templates produce a Universal 2 Mac app. | Recommended: sufficient 3D tools, compact self-contained editor, straightforward source project, free and open source. |
| Unity 6 | Official documentation supports Apple Silicon editors and Mac players. | Strong alternative, especially for an existing Unity project or asset investment. Larger ecosystem is useful, but this game has modest requirements. |
| Unreal Engine | Official Mac support; current development guidance recommends M3 and 32 GB memory. | Capable, but its advanced rendering and heavier development setup offer limited benefit for this small stylized arena. |

Sources: [Godot Mac download](https://godotengine.org/download/macos/), [Godot Mac export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html), [Unity 6.0 requirements](https://docs.unity3d.com/6000.0/Documentation/Manual/system-requirements.html), [Epic Mac development requirements](https://dev.epicgames.com/documentation/unreal-engine/macos-development-requirements-for-unreal-engine). The Unity source demonstrates support for a documented version; no claim is made that 6.0 is the newest Unity release. Editor requirements are not game runtime requirements.

Godot has an established indie community. In GDC's 2026 survey, Unreal was the primary engine for 42% of surveyed developers and Unity 30%; Godot was used by 11% of newer indie developers. These are different populations, not directly comparable market shares. [GDC report summary](https://gdconf.com/article/gdc-2026-state-of-the-game-industry-reveals-impact-of-layoffs-generative-ai-and-more/).

The recommendation prioritizes fit for a small native game. It does not claim Godot is the most popular engine overall.

## Successful references and alternatives

The references are design precedents, not games being copied or promised to run on this Mac.

| Reference | Relevant evidence | Design inference |
|---|---|---|
| [Furi](https://store.steampowered.com/app/423230/Furi/) | Focused responsive combat and boss encounters; 91% positive among 7,078 English Steam reviews when checked. | Invest in clear anticipation, strong impact, and one memorable boss. |
| [Hades](https://store.steampowered.com/app/1145360/Hades/) | Ability combinations and replayable runs; 98% positive among 142,352 English reviews when checked. | Each upgrade should make the next encounter feel different. |
| [Nova Drift](https://store.steampowered.com/app/858210/Nova_Drift/) | Short runs and transformative build combinations; 96% positive among 9,088 English reviews when checked. | A small arena can sustain experimentation through meaningful builds. |

Review counts are a dated snapshot, not a forecast. These games show an audience for the ingredients; the new game's popularity and fun remain to be established.

Other viable directions:
- **Arcade hover racing:** drift and boost through one polished time-trial course. Strong speed fantasy; depends heavily on vehicle feel and course design.
- **Adventure platformer:** a compact floating-island traversal challenge. Strong exploration appeal; requires more traversal content, camera tuning, and animation work.

Pulsebreak is recommended because a complete short run can concentrate development effort on combat, replayability, and presentation.

## What playing feels like

First encounter: three orange diamond-shaped shots approach. You dash diagonally through them. They curve into the reactor on your back with three rising musical notes. Your energy ring fills. You turn toward a clustered group and press pulse: a bright ring expands, machines recoil, and a short chain of explosions clears a route to a bonus core.

The next group includes a charger that predicts your path. You must break your circling pattern, reserve a dash, or spend energy before it reaches you. The boss later combines the same learned language into larger patterns.

## Controls and camera

| Input | Action |
|---|---|
| WASD / arrow keys | Move relative to the screen |
| Space | Dash in movement direction; use last movement direction if stationary |
| E | Release stored energy as a pulse |
| 1 / 2 / 3 | Choose an upgrade while combat is paused |
| Esc | Pause, resume, settings, or return to title |

A fixed elevated perspective camera shows real 3D characters, arena geometry, lighting, and effects. Combat uses one consistent height plane for reliable hit reading. Low scenery, ground shadows, and edge barriers keep threats visible. Mouse aiming is unnecessary. Keyboard remapping, clear focus states, and an adjustable shake setting are included. A clearly labeled assist setting can slow enemy attack cadence.

Initial delivery focuses on keyboard play. Controller support and manual aiming can be considered after the core loop is proven.

## Combat rules to prototype

All numbers below are starting tuning values, not validated balance.

- Two dash charges, replenished sequentially at one charge per 1.5 seconds. A dash lasts about 0.18 seconds. Direction, distance, and recovery will be tuned in the first playable slice.
- During the dash, absorbable projectiles are collected and body contact does not damage the player. Dash is not a promise of protection from sustained ground hazards. Hazard shapes and safe areas must remain unambiguous.
- Movement starts on the button press. Projectile/contact protection lasts for the dash duration; ground-hazard damage remains active. Walls truncate dash travel without teleporting or consuming another charge; the original protection timer still expires normally. Charger's body contact follows the same rule as other bodies. The HUD shows dash charges separately from pulse energy.
- Absorbable projectiles use orange diamond silhouettes, a distinctive motion trail, and a matching charge sound. Shape and motion communicate the rule in addition to color.
- Each collected projectile grants 10 energy, capped at 40 per dash; total energy caps at 100. Collection never resets dash cooldown.
- A pulse requires at least 30 energy and consumes the current amount. More energy increases its damage and visible radius. Chaining is limited to four additional enemies; a target cannot be hit repeatedly by one chain.
- The automatic short-range shot handles minor enemies. Normal kills add five energy as a fallback. It should not be the strongest way to resolve dangerous groups.
- The director provides dependable, reachable volleys during combat, including boss phases, so the mechanic does not depend on preserving a particular gunner. It never changes attack timers abruptly merely because the player lacks charge.
- Build encounter schedules with usable volley opportunities about every four seconds while active enemies remain. This is a design constraint on patterns, not reactive replacement of a gunner just killed. Reinforcements are telegraphed and pressure continues through chargers and timed progression. Test for stalling at full energy; improve partial-pulse usefulness and timing before adding artificial penalties.
- Damage gives clear hit feedback and a brief recovery window. Multiple overlapping collisions must not delete the health bar in one frame.
- Charge is not awarded score on its own. Score comes from actual encounter progress, defeated enemies, optional cores, and the boss.

## Run structure and scope

One complete first release contains one player character, one handcrafted arena, three enemy roles, nine upgrades, and one boss with two phases.

| Stage | Intended experience |
|---|---|
| First 30–45 seconds on a new profile | Learn movement, absorb one slow volley, and pulse a small cluster. A practice sequence is outside the main run timer and can be replayed. |
| Run minutes 0–2 | Gunners teach volley harvesting; chargers teach route changes. |
| Minutes 2–4 | Add shield bruisers and combinations that reward flanking or pulsing. |
| Minutes 4–6 | Mix known patterns at higher pressure; avoid simply filling the screen with more actors. |
| At six minutes | Transition cleanly to the boss; stop regular spawns and clear leftover projectiles before the introduction. |
| Boss, target 1–2 minutes | Phase one uses volley lanes and a telegraphed slam; phase two combines offset volleys with sweeping ground patterns and safe corridors. Actual duration depends on play. |
| Victory or death | Show a concise result, chosen upgrades, score, and an immediate restart action. |

Five upgrade selections pause the game at minutes one through five of the wave phase. An occasional optional bonus core appears at a telegraphed, reachable alternate arena location for about 12 seconds, with a safe arrival window but a route that may cross enemy pressure. It invites a risky route change for healing or temporary power. Skipping one cannot block progression.

Enemy roles:
- **Gunner:** recognizable wind-up followed by an absorbable volley.
- **Charger:** forecasts an intercept lane before committing, encouraging a direction change.
- **Shield bruiser:** slow pressure with a visible front shield. Rear attacks bypass it; a pulse breaks the shield for a short visible vulnerability window, including for automatic fire.

The director must not overlap attack lanes so that damage becomes unavoidable. Ground telegraphs start at roughly 0.75 seconds and are tuned through play.

## Upgrades and replayability

Nine distinct upgrades are offered in choices of three; selected upgrades are removed from the current run's pool. Five choices are feasible from nine without forcing duplicates. Every card works independently, describes its effect plainly, and visibly changes the relevant ability. Final numerical tuning follows the combat prototype.

Three thematic families guide the pool:
- **Harvest:** wider absorption, stronger charge economy, or close-range rewards; encourages taking a deliberate line through fire.
- **Echo:** a delayed repeat pulse, a wider pulse ring, or stronger bounded chains; rewards timing and enemy grouping.
- **Wake:** damaging dash trails, a short slow field, or a pulse that ignites the trail; rewards route planning.

Examples of explicit tradeoffs: a wider harvest dash travels less far; an echo delays part of the pulse damage; a damaging trail has a short lifetime and cannot stack indefinitely. No upgrade should remove the need to move or make another offered card useless.

Replay comes from different combinations, shuffled fair encounter sequences, personal score improvement, and optional higher pressure after a win. Core abilities are available immediately. Persistent storage keeps settings, tutorial completion, and best results; a long permanent-stat grind is outside this first release.

## Art and sound direction

Use a bold stylized 3D look: dark blue industrial surfaces, warm orange enemy energy, a pale cyan player silhouette, and an illuminated reactor. A large turbine and distant clouds establish the sky-foundry setting. Model detail stays subordinate to silhouettes and readable combat space.

Presentation priorities are responsive lean and dash poses, convincing enemy recoil, brief debris bursts, pulse rings that clear quickly, legible UI, and a restrained camera impulse. Audio gives separate cues for dash readiness, each absorbed shot, pulse strength, incoming charge attacks, damage, and boss phases. Music intensity follows encounter pressure. Assets must be original or appropriately licensed and recorded with attribution when needed.

## Native Mac delivery and technical outline

Deliver a locally exported `Pulsebreak.app`, the editable Godot project, and concise launch instructions. The goal is playing the exported app without opening the editor. Godot's official Mac templates include ARM64; use built-in ad-hoc signing for the local development export. Public distribution and notarization are separate from this local deliverable. [Export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html).

Start with Godot's Mobile renderer using Metal; it supports desktop and is intended to render simpler scenes efficiently. Benchmark it before freezing settings. [Renderer documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

Provisional target: 60 fps at 1920×1080 on an M1-class Mac with 8 GB memory. This is a target, not a measured or guaranteed result. This environment reports macOS 26.6.2; exact chip and RAM have not been confirmed. Use the actual named test machine in every performance report. Provide a lower resolution/effects setting if needed, without hiding danger cues.

Separate components own player movement and abilities, damage/energy resolution, enemy patterns, encounter timing, upgrades, UI, audio, and local saves. Data resources define tuning and upgrade effects. Pooled projectiles and bounded effects prevent unbounded work. Menu, practice, run, upgrade selection, boss, pause, and result are explicit states; timers respect pauses and state transitions. Save failures or invalid files must retain usable default settings and never prevent a new run.

## Development and quality review after discussion

1. Prove a short combat slice: practice followed by 90 seconds of movement, gunner-plus-charger combat, absorption, pulse, one upgrade, and a brief bruiser introduction. Continue only after observed play shows that the player understands harvesting, deliberately chooses between spending and saving charge, and can explain incoming damage. Compare against circling with automatic fire: active harvesting/pulsing must create a noticeable advantage and different movement decisions. If it does not, revise the hook before adding full content. Treat the nine-upgrade catalogue as provisional until these decisions are useful in play.
2. Build the complete run, upgrade choices, boss, title/settings/results, audio/art, and native export.
3. Run up to three independent sub-agent review-and-fix rounds on playable builds. Preliminary design critiques do not count as these build rounds.

Each round records a build identifier, test hardware, settings, evidence, category scores, and the three most consequential issues, followed by fixes and a focused independent recheck of the resulting build. Report both the initial and post-fix rating when fixes change the candidate. Stop early when the threshold is met. After the third round, report the final evidenced score honestly; do not add further improvement rounds to chase a number.

| Category | Weight | Evidence |
|---|---:|---|
| Movement, dash, and impact feel | 25% | Direct control and repeated use in quiet and crowded encounters |
| Combat decisions and fairness | 20% | Normal waves, mixed enemies, and both boss phases |
| Build choices and replayability | 15% | Multiple complete runs using different upgrade families |
| Visual clarity, art, and audio | 15% | Actual gameplay at peak intensity with sound |
| Onboarding, controls, and usability | 10% | Fresh profile, practice, settings, pause, failure, and restart |
| Mac performance and reliability | 15% | Exported app launch, named hardware, frame-time capture, and repeat runs |

Passing means weighted score strictly greater than 9/10, no category below 8, no serious functional blocker, and observed completion of the full game loop. Frame-time reports include steady-state and worst-wave behavior, not just average FPS; note loading and shader warm-up separately. A practical 60 fps target includes 95th-percentile active-play frame time at or below 16.7 ms on the declared settings, subject to actual profiling.

Meaningful engineering checks cover charge/cooldown limits, upgrade application, run-state transitions, save recovery, damage recovery, and repeated restart. Runtime review must also check readable enemies, input feel, sound, boss fairness, and the exported app. Passing headless checks does not establish fun.

If the reviewer cannot directly play with the available tools, report an observational review and leave control-feel judgments provisional. The user's hands-on feedback is essential evidence of whether the game is fun for them. A number cannot guarantee universal quality or future popularity.

## Current review status

Initial independent design critique: **7/10 readiness**, with actual game quality **unscored**. Main concerns were passive circle-kiting, unavailable charge, unclear absorption, and excessive scope. This draft responds with intercepting chargers, reliable volleys plus fallback charge, redundant visual/audio cues, bounded dash/pulse loops, and a deliberately small content set.

Second independent design critique: **8.5/10 completeness; 8/10 feasibility**, actual fun still **unscored**. It requested explicit collision safety, pressure instead of reactive gunner replacement, a concrete prototype decision, clear timing, and a precise bruiser counter. These are now incorporated. No third paper review has been used to inflate the rating; the final edits have not received a new independent score.

Implementation is now authorized. The requested above-9 quality target applies to playable-build reviews, with a maximum of three review-and-fix rounds.

## Implemented candidate notes — 2026-09-07

The approved design above records the intent. The current local build implements the complete wave/boss loop, original procedural art/audio, practice, settings/remapping, local persistence, and a victory-unlocked Overdrive setting. Each of the five upgrade installations also repairs20hull to reduce reliance on the Life Circuit upgrade. Aftershock repeats the original radius at exactly45%damage after0.45seconds.

The current automated standard run finishes at405.6seconds: six wave minutes and about46seconds for the boss including its defeat transition. This is shorter than the original one-to-two-minute boss target; timing remains tuning, not a measured human completion estimate. The alternate trail/field build reaches4:43onNormal and reaches the boss withAssist; both recorded drivers eventually lose. These observations do not establish everybuild'sbalance or humanfun.

Harvesting cadence comes from regularly scheduled anchor gunners and volleys on every boss attack. There is no independent arena cannon scheduler or global proof that every overlapping attack lane is avoidable. The implemented training, readable lane geometry, and recovery window improve fairness, but human difficulty assessment remains open.

Native frame timing and independent review evidence are in qa/. Fixed-fps/headless runs are simulations with null render percentiles. Review ratings are observational and must not be represented as direct hands-on quality certification.
