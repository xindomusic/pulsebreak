# Skybound independent review

Date: 2026-09-13. Reviewer: independent `quality_review` agent. Branch: `feat/skybound-showcase`. Starting commit: `9017872180d6a90032be9dcdedcdc338c1ff8811`.

This is a new follow-up review, separate from the original three-round experiment. Its goal is to find defects and assess evidence, not to guarantee the requested 9/10. No final Skybound candidate was available when the baseline and protocol below were written.

## Baseline assessment

Read README, gameplay/testing/roadmap documentation, prior review and art reports; inspected the original movement/director/art code and `docs/images/combat.png`. The baseline is a functional flat-arena roguelite, with a distinctive dash/harvest/pulse loop and clear orange-projectile/pink-warning vocabulary. Its historical 8.2/10 rating remains an observational score, not a fresh rating by this reviewer.

The material gaps for the user's new scope are:

- **Traversal absent:** the original player height is reset to zero each gameplay step. Jumping, flight and altitude-sensitive target traversal do not exist.
- **Limited animation:** body tilt and ring rotation do not provide a readable walk/run gait, takeoff, flight, landing or impact performance.
- **Single arena:** minute-based waves do not provide multiple distinct authored spaces or traversal tasks.
- **Camera scale:** the original combat still makes the player small; fine mesh detail alone will not materially improve recognition.
- **Evidence limits:** previous human control and listening coverage is insufficient for a confident showcase-quality fun/readability judgment. Old frame timings do not benchmark a materially expanded final candidate.

## Weighted rubric, total 10 points

Rate each category from 0 to 10, then multiply by `weight / 10`. Keep an evidence note beside every score. A missing category is unverified, not automatically excellent.

| Category | Weight | 9-level expectation |
|---|---:|---|
| Movement and traversal | 2.00 | Responsive jump/glide/dash; useful altitude; forgiving deliberate inputs; no infinite-flight or stale-state exploits; expressive movement understood in play. |
| Combat and fairness | 1.50 | Core harvest/pulse loop remains useful; warnings match hitboxes; aerial evasion has clear limits; boss and varied builds are viable. |
| Levels and pacing | 1.50 | At least three meaningfully different authored challenges with teach/develop/master progression, clear transitions, completion and replay. |
| Art, model and animation | 1.50 | Cohesive environment, gameplay-scale player silhouette, articulated gait and takeoff/glide/landing, clear target and gate movement, restrained effects. |
| Onboarding and usability | 1.00 | A new player can learn all required actions without coaching; remaps, objective HUD, pause, results and replay fit and communicate correctly. |
| Audio and feedback | 0.75 | Distinct useful action/target/danger cues, legible mix during busy play and clean sector/boss transitions, actually auditioned. |
| Reliability and performance | 1.25 | Regression and new behavior checks pass; full candidate completes; no script/resource errors, leaks, softlocks or major frame spikes on the reported machine. |
| Evidence and reproducibility | 0.50 | Exact candidate identity, retained wins/losses, captures with provenance, command logs and honest human/bot limits. |
| **Total** | **10.00** | A score of 9 requires both a strong weighted result and the acceptance gates below. |

Scores: 5 = functional prototype; 7 = solid with evident roughness; 8 = polished but materially limited; 9 = excellent short showcase supported by direct evidence; 10 = exceptional, with negligible relevant weaknesses. This is a local rubric, not an industry certification or an event's selection criterion.

## Acceptance gates and protocol

1. **Candidate identity:** record Git commit or source hashes, engine, machine, viewport, effects/difficulty settings and artifact paths. Preserve the original review scores.
2. **Correctness:** rerun existing rule, save and integration suites. Add meaningful traversal/campaign cases: buffered jump, finite glide and refill, altitude-aware hits, aerial targets, moving gate collision/state, sector transition cleanup, pause/focus loss, remaps and replay reset. Inspect logs, not only exit status.
3. **Complete experience:** run a full campaign through actual production actions with deterministic bot input and retain losses. A direct sector-start fixture is useful for diagnosis but cannot establish full progression. Check death, restart, victory and campaign re-entry.
4. **Visual evidence:** inspect real rendered title, every sector, normal movement, jump, glide, gate transition, busy combat, upgrade, settings and results at the target viewport; label staged captures. Low Effects must preserve essential danger and target cues. A motion sequence or gameplay recording is required to judge gait and gate animation rather than merely node existence.
5. **Performance:** measure real render-frame intervals on the final candidate, include busy sector/boss segments, and record p95/p99 and startup behavior. The local showcase target is p95 ≤16.7 ms at the reported settings, not a guarantee for untested hardware. Headless/fixed-FPS simulation is not a frame benchmark.
6. **Human acceptance:** at least two uncoached new-player attempts plus one complete experienced-player run. Record practice completion, target misunderstandings, unexplained hits, movement intent mismatches, recovery after failure, listening observations and desire to replay. Any absent evidence must remain explicit.
7. **Decision:** no unresolved crash, data loss, softlock, required-action failure, or serious misleading visual/hitbox issue. A weighted score cannot compensate for one of these blockers. A confirmed 9/10 additionally requires the human and listening evidence above; otherwise report a qualified technical/visual assessment and the exact unverified categories.

## Candidate review

Review complete on the assembled working tree and recorded runtime manifest. The provisional technical/visual score is **8.8/10**. A confirmed overall 9/10 is not established; the evidence and outstanding acceptance limits are detailed below.

### Findings sent to implementation

| Priority | Finding | Requested resolution |
|---|---|---|
| P1 | Closed gates blocked the player while ground enemies and projectiles could pass through the same visible shutter. | Shared gate collision/occlusion and charger-warning behavior; independently recheck after integration. |
| P1 | An overhead gate beam occupied the normal jump body's path although the gate collision admitted feet above 1.85 m. | Art agent removed the beam and capped the posts as low obstacles; inspect actual render. |
| P2 | Adding default Jump F silently reset a valid legacy Pulse F to E. | Preserve existing controls and choose an unused jump fallback; parent updated migration and tests. |
| P2 | Jumping in place could satisfy practice's MOVE lesson; harvesting during a low jump spawned the next lesson's machines above the ground. | Use planar distance for the movement lesson and ground the machine spawn positions. |
| P2 | Timed interior shutters displayed an instruction to link relays, although they opened independently; sector scenery names differed from HUD names. | Distinguish timed/exit gate labels and unify sector names. |
| P2 | The original backdrop visibility lookup used the wrong parent, leaving scenery intended for one sector visible in others. | Art agent corrected the lookup through the campaign's parent. |
| Evidence | QA reports omitted campaign/relay/checkpoint metadata. | Record mode, sector, nine-relay progress, boss start and sector completion times. |

An intermediate `campaign.gd` inferred-type parse failure was also reported and fixed before further runtime checks. These are development findings, not a claim that they all remain in the final candidate.

### Independent early execution

On Godot 4.7.2, the reviewer independently ran **215 checks**: 25 combat, 71 save, 38 integration, 34 traversal, 25 altitude integration and 22 campaign. All passed. Logs are `/tmp/pulsebreak-review-*_test.log`, `/tmp/pulsebreak-review-traversal.log`, and `/tmp/pulsebreak-review-campaign2.log`. These checks predate the final shared gate-collision changes and final visual polish; final-candidate checks must be identified separately.

The reviewer also ran a complete nonaccelerated fixed-60 headless campaign policy using production movement and abilities. It reached all nine relays and the third-sector Guardian, then **lost at 75.70 seconds**: 12 kills, 51 absorbed shots, 13 pulses, Hot Capacitor and Chain Reaction. Sector completion times were 20.22 and 51.70 seconds. The loss is retained at `qa/skybound-review-sim/active-metrics.json`; log `/tmp/pulsebreak-review-campaign-run.log`. This run establishes progression reachability and a balance concern for that policy, not human difficulty or rendering performance. It ran before the shared gate-collision follow-up and later balance adjustments.

Initial sandboxed runs reported macOS certificate/`vm.swapusage` permission messages; these were distinct from the corrected script parse error. Later suite runs completed without those environment messages.

### Final source verification

After the collision, control migration, practice, gate-art, required-glide feedback and authored route-hazard changes, the reviewer independently reran **261 checks, all passing without script/resource errors**:

| Suite | Checks |
|---|---:|
| Combat rules | 25 |
| Save validation/migration | 71 |
| Existing integration | 38 |
| Traversal simulation | 34 |
| Altitude and shared gate behavior | 34 |
| Campaign, relay feedback and authored hazards | 29 |
| Keyboard/animation/control path, headless rerun | 30 |
| **Total** | **261** |

Logs: `/tmp/pulsebreak-skybound-final-<suite>.log`. In particular, closed shutters now affect enemies, player fire and hostile projectiles; expanded Wide Receiver cannot harvest across a closed shutter but still works on the same side. Required-glide relay rejection now gives a remap-aware instruction. Foundry uses alternating low shock pads, Storm combines two, and both preserve a central safe lane with at least 1.35 seconds of warning. Pause/transition state guards preserve the new behavior.

Source SHA-256 for that independent check:

```text
d6b71dc379414f3e1580ce33087d6f82465c9e95f6cb2dcbe11cafce50c1338d  scripts/game.gd
c3683cdc76f9980df0788f81b2ff904f1e948cb5c298e519be69ca9601300aec  scripts/campaign.gd
45e9eb4de07c4a8bf9a7b8737b2d30efa60e3dd0955787e17ae307f5d6075a44  scripts/traversal.gd
d18a38b458097a997ca4e2586babf7be9e3458bf929f5ec1498fa8348a3959d4  scripts/combat_field.gd
ad154d3f5b804288560a73bbf701fa3407e9b8114a6abacddc9f04af1e6f6503  scripts/enemy.gd
71d9cda7b0a3ab66506d406abfb212757b81d1f8edba88228b3337b03ebe444f  scripts/art.gd
4b63ca210fd471018904e0fc1a00848c6a5db4069b6c82e578b4f6bd60a91bfd  scripts/showcase_art.gd
cab66515c83a6fa5d29642e451d37f474048bdd039ea8b62b6c368e94be7ed70  scripts/hud.gd
8008fa7ee4aee78f7b6b7f309aa065c8f004e719716be9a40e56a3c344cdcf70  scripts/save_store.gd
```

The reviewer read both final-policy reports: `qa/skybound-release-normal/active-metrics.json` wins at **128.40 seconds with 16 hull**; `qa/skybound-release-alternate/active-metrics.json` wins at **123.15 seconds with 52 hull**. Both record all nine relays and three sectors. These are coordinator-run headless simulations. Earlier losses remain available; the implementation corrected the driver's planar spacing and aerial dash decisions, and moved the boss clear of a shutter, instead of reducing the Guardian's health or damage to force a win.

The [native controls report](skybound-controls.md) records a separate 30/30 Metal-rendered input run. This reviewer inspected its regenerated gait A/B, ascent, glide and landing captures: different articulated steps, actual height separation, deployed/folded wings and landing poses are visible. Rig close views change the camera but do not pose the joints directly. The first focus-loss-paused capture attempt was rejected as evidence and replaced by the passing run. Neither these captures nor injected key events are a human control-feel test.

### Final visual inspection

Independently inspected the refreshed title, all three sector flight frames, Foundry's required-glide lesson, Storm with Low Effects, and Guardian under `qa/skybound-visuals/captures`, plus settings, sector completion and upgrades. These are deliberately staged captures from the production scene.

- The courier has a coherent beveled ceramic/metal design, readable facing, articulated running limbs, folded wings and a broad deployed silhouette. The larger title presentation communicates the new flight identity.
- Each sector now has distinct deck-scale graphics and visible side landmarks as well as different lighting: docking markings, a solar transfer layout and circular storm containment. The normal gameplay camera gives the actor more screen space than the initial candidate.
- Gates are visibly low obstacles, with separate timed-shutter and exit messages. Removing their overhead beam resolves the prior normal-jump intersection. The Guardian appears clear of the moving shutters, which remain open during its encounter.
- The required-glide target has an amber `GLIDE / HOLD F` label, distinct from ordinary relays. The HUD names the action and the near-miss path explains how to unfold the wings. The Foundry/Storm warning rings leave a clear central route, including in Low Effects.
- Title, settings with seven bindings, upgrades, sector handoff and boss HUD fit the 1280×800 captures. Gate's small world-space labels are secondary to the readable objective/HUD instructions. Closely overlapping actor/relay/warning effects still deserve observation during dense human play.

### Provisional scored assessment

The reviewed technical/visual portion earns **8.8/10**, rounded from `8.175 / 9.25 × 10`. Audio is unscored because this review did not audition the game; its 0.75 weight is excluded from that calculation. This is a qualified score of observed implementation and presentation. Full player-experience acceptance, including perceived input feel, audio, new-player learning and replay appeal, remains unverified.

| Category | Weight | Provisional rating | Basis and limit |
|---|---:|---:|---|
| Movement and traversal | 2.00 | 9.0 | Buffered real-height jumping, finite controllable glide, remapped input checks, clear airborne and landing states; subjective feel not tested by a human. |
| Combat and fairness | 1.50 | 8.6 | Height-aware swept collision, shared shutter behavior, consistent harvesting, two complete campaign-policy wins; human boss difficulty and broader build balance remain uncertain. |
| Levels and pacing | 1.50 | 8.5 | Three ordered sectors, required glide, timed shutters, authored one/two-pad progression, boss and clean handoffs; the short campaign still shares its arena footprint and small enemy roster. |
| Art, model and animation | 1.50 | 9.0 | Cohesive original model, strong folded/deployed wing language, genuine articulated gait, landing compression, distinct deck graphics and landmarks, readable low-effect warnings. |
| Onboarding and usability | 1.00 | 8.8 | Specific relay feedback, live key prompts, persistent control migration, clear menus and transitions; uncoached completion remains to be observed. |
| Audio and feedback | 0.75 | Unverified | Existing cue prioritization and music-intensity paths were read, but source structure cannot establish the perceived mix. |
| Reliability and performance | 1.25 | 9.2 | 261 independent checks, separate native key checks and complete rendered wins; the measured p95 exceeds the strict 16.7 ms target, as recorded below. |
| Evidence and reproducibility | 0.50 | 8.6 | Source hashes, separate simulation/native/staged evidence, retained losses and written limitations; wider hardware and human evidence remain absent. |

No unresolved P0/P1 defect was found in the final reviewed source and captures. The new scope is implemented and materially improves the game. A confirmed overall **9/10** and AAA-showcase readiness are **not established** by this evidence. The next useful quality work is direct uncoached play and listening, followed by fixes to observed misunderstandings or repetitive moments; another cosmetic effect alone would not resolve that uncertainty.

### Final native timing

The reviewer independently read `qa/skybound-native-timing/active-metrics.json`. The coordinator's real-time Metal run completed the campaign at **128.40 seconds, 16 hull, nine relays**, on an **Apple M4 with 16 GB memory, macOS 26.6.2, Godot 4.7.2 Mobile renderer**. Assist, Overdrive and Low Effects were off. It used no headless, fixed-FPS or accelerated simulation flags.

| Elapsed render-frame measure | Result |
|---|---:|
| Samples after the first 3 seconds | 7,542 |
| Median | 16.689 ms |
| p95 | 17.830 ms |
| p99 | 18.375 ms |
| Worst sector p95, Skyport | 17.965 ms |
| Boss p95 / p99 | 17.725 / 18.174 ms |

This run **changed rendering size during play**. The reviewer independently read the PNG headers: `run-15.png` is 1280×800, while `run-90.png` and `result.png` are 2304×1440. The final report records a 3440×1440 window with a 1440×900 logical viewport, whose aspect-preserving gameplay image is 2304×1440. Therefore its aggregate timings are a mixed-resolution presentation measurement, not a fixed 1280×800 or fixed 2304×1440 benchmark. The intervals are consistent with roughly 60 Hz presentation, but this measurement alone does not isolate GPU cost from synchronization or scheduling. Its **p95 exceeds the protocol's 16.7 ms target**. The initial three seconds were excluded, so no startup-latency claim is made. It demonstrates a complete rendered win, including runtime resizing, on this specific configuration.

The coordinator then ran the same source explicitly windowed at 1280×800 with `--disable-vsync`. The reviewer independently read `qa/skybound-native-windowed/active-metrics.json` and checked all three PNG headers: each is **1280×800**, matching the final reported window. It also completed the campaign at **128.40 seconds with 16 hull**, with 8,664 real frame samples:

| Controlled 1280×800 elapsed-frame measure | Result |
|---|---:|
| Median | 16.470 ms |
| p95 | 17.842 ms |
| p99 | 18.430 ms |

Despite the requested VSync override, these intervals remain near a 60 Hz presentation cadence. Driver/compositor synchronization is a possible explanation, not a measured cause; this result cannot establish uncapped GPU headroom. The controlled run's **p95 also misses the 16.7 ms protocol target**. Neither measurement is converted into a higher FPS claim or used to inflate the score. Both runs remain recorded, and no additional hardware coverage is claimed.

The final runtime identity is `qa/skybound-source.json`, aggregate digest `91fd3c02b761fcfb8831369edfbc90b90f7376d23034ea62dc488bab342c753a`. Relative to the independently checked source list above, `game.gd` changed only timing segment labels; its final SHA-256 is `cf0be3d6030212413f7a99f7bb78d618ee419647a9070aed2300a4ce9d0c23e8`. The other reviewed runtime source hashes match the manifest. The remaining acceptance work is the stricter frame-interval target and direct human control, learning, replay and audio evaluation.
