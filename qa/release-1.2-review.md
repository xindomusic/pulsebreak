# Pulsebreak 1.2 — independent game review

Reviewed 2026-09-13. Runtime source: `38854e6`. Local application: `build/Pulsebreak.app`, version 1.2.0. Final distribution packaging updates notices and the signature while preserving the reviewed resource pack byte-for-byte. Reviewer: independent `quality_review` agent.

**Overall assessment: 8.4/10 as a small indie arcade demo.** It has a coherent combat idea, expressive presentation and unusually thorough engineering evidence for its scope. Repeated encounters and limited evidence of sustained human enjoyment keep it below 9. **AAA showcase readiness is not established.** The game is a credible playable indie release; this review does not certify event selection or premium production quality.

This is a provisional game assessment from source inspection, representative native images, automated behavior, package checks and the existing audio reports. The reviewer did not play the game or listen to its soundtrack. The score therefore carries limited confidence about feel, difficulty, musical appeal and replay value. The earlier 9.0 Resonance number covered selected observed components only; it was never a whole-game rating and is not reused here.

## Weighted rubric

Scores describe the delivered scope: 5 is functional but rough, 7 is solid, 8 is polished with identifiable limits, and 9 requires an excellent, consistently convincing experience. Each score is multiplied by its weight. The audio row assesses delivered integration and player controls, not an unheard musical performance.

| Category | Weight | Score | Contribution | Evidence and limitation |
|---|---:|---:|---:|---|
| Combat and traversal design | 25% | 8.8 | 2.20 | Dash harvesting, charged pulses, altitude-aware movement and four mechanically different weapons form a connected loop. Continuous collision and resource rules are tested. Responsiveness and balance still need uncoached human assessment. |
| Visual direction and readability | 20% | 8.6 | 1.72 | The courier silhouette, deployed wings, warm threats against cool decks and staged pulse expansion read clearly. Art remains compact and visibly procedural; small secondary labels and crowded warnings need further play observation. |
| Content and encounter depth | 20% | 7.8 | 1.56 | Three introductory sectors, six generated route templates, five modifiers and evolving weapons provide useful variation. The same deck footprint, three ordinary enemy types and recurring Guardian constrain surprise and long-term depth. |
| Audio integration and controls | 15% | 8.0 | 1.20 | Original ElevenLabs-generated dubstep, distinct combat cues, continuous looping, combat gain, ducking and reserved voices are verified. Only one global volume slider is exposed; musical quality, masking and loop fatigue are unassessed. |
| Usability and accessibility | 10% | 8.4 | 0.84 | Practice, visible controls, remapping, focus pause, Assist, Low Effects and clear Quit/bank actions are implemented. Keyboard is the supported gameplay input; separate music/effect levels and broader accessibility options are absent. |
| Reliability and Mac delivery | 10% | 8.9 | 0.89 | Regression and package evidence is strong, with a universal standalone app and a useful M4 baseline. The exact 1.2 build has audio and startup evidence, but no full native progression timing run. Distribution signing is local ad-hoc. |
| **Total** | **100%** | | **8.41 → 8.4/10** | **Provisional overall estimate, not a player-study result.** |

## What works best

The strongest design decision is making incoming fire a resource. Dashing through shots supplies a pulse, while jump/glide adds route and survival choices. Weapon ranks change behavior through spread, chaining, penetration and explosions rather than relying exclusively on damage increases. Preserving reload on weapon switching and respecting cover make those differences mechanically meaningful.

The presentation now has a recognizable identity. The inspected [title](../docs/images/resonance-title.png), [courier](../docs/images/resonance-courier.png), [pulse](../docs/images/resonance-pulse.png) and [busy Low Effects scene](../docs/images/resonance-low-effects.png) show cohesive colors, readable character shapes and a substantial blast that leaves hostile lanes visible. These are historical staged images of retained visual code. The reviewer also inspected an input-driven glide image and the prior packaged Guardian frame. Static images establish appearance, not animation feel or player reaction.

The release is concrete. Read-only checks independently confirmed the local bundle's 1.2.0 version, both `arm64` and `x86_64` architectures, successful strict deep signature verification, and matching resource-pack, ZIP and music hashes. No running game was started, stopped or modified for this review.

## Evidence and version boundaries

The [1.2 regression log](prism-tests.log) records **591 passing checks across fourteen suites**, including 91 audio checks. Its generation suite samples 768 layouts; these are sampled constraints, not 768 additional assertion counts or proof of unlimited balance. The nine [generator safety tests](prism-generator-tests.log) also pass. Existing macOS certificate-store diagnostics are present in the headless log; there are no reported script or assertion failures. This reviewer inspected the records rather than redundantly rerunning unchanged suites.

The [1.2 audio review](prism-review.md) independently verifies the complete 102.426-second track, prepared output headroom, loop transport and a 36.01-second native CoreAudio recording. The runtime Ogg measures −13.97 LUFS with a −1.35 dBFS decoded sample peak and zero full-scale samples. The native recording peaks at 0.792969 and includes production combat with staged weapons, threats, Guardian entry and charges. It establishes actual engine playback, not a successful player run or listening approval. Music adaptation changes one track's gain; it does not select new arrangements or synchronized musical layers during combat.

The [feature-build package report](prism-package.json) records integrity checks for 78 resource-pack members, exclusion of development/environment files, extracted archive checks and standalone startup. The [final distribution report](release-1.2-package.json) records the subsequent notices/signature repackaging. The reviewer independently rechecked its unchanged PCK, final ZIP and valid strict deep signature. Final artifact hashes are:

- PCK: `be784cafee01e6286036aa1bbbb00a5115de884631442f0c0521810780d64191`
- ZIP: `d8f7fefb874d4fa226cc60ccdf10b0e291ccd63b0ef48e37047175d98198c18c`
- Runtime music: `3236dbbc9897641b4e0ac433b4da2a024ecc7776720f05855288fc91bc0ec0d6`

Comparing the 1.1 and 1.2 package manifests shows that all thirteen gameplay, visual and UI compiled scripts are identical; only the compiled audio director changes. This supports carrying forward behavioral and visual findings, without relabeling an older performance measurement as 1.2.

The [packaged 1.1 M4 run](release-native/active-metrics.json), identified by its [run context](release-native/run-context.json), completed three sectors, nine air relays and one Guardian at 1280×800 with Full Effects on a Mac mini M4 / 16 GB. Across 5,622 active render intervals its median was 16.654 ms, p95 18.459 ms and p99 18.992 ms. This is encouraging target-device evidence for the retained gameplay. It is **not a measured 1.2 frame rate**, an isolated GPU measurement or a guarantee for other Macs. Missing the older 16.7 ms p95 goal alone does not decide the game grade.

## Strongest blockers to 9

1. **More meaningful encounter variety.** Generated routes rearrange familiar targets, gates and hazards on the same deck. Add encounters that change how the player reads the space: a different Guardian, distinct traversal structures, or objectives that force a new combat decision. Validate these through repeated play rather than counting generated seeds.
2. **Evidence of enjoyable first and repeat runs.** Watch several new players learn harvesting and flight without coaching, then return for another run. Record confusing instructions, avoidable deaths, idle periods and whether weapon decisions matter. Automated wins establish reachability; they cannot establish tension, fairness or desire to replay.
3. **Finish the player's sound and control experience.** Audition the current soundtrack with every weapon and a crowded Guardian fight, including repeated loops. Separate music and effects sliders would let players preserve warning clarity while choosing their preferred musical intensity. Controller support would also make a public hands-on demonstration more flexible.
4. **Close the final-build release evidence.** Run a complete native 1.2 campaign on the target M4, preserve its exact PCK and settings, and check installation on a clean Mac. The current local ad-hoc signature is valid; notarization or explicit installation guidance is still relevant to broader distribution. Release verification should remain separate from any fun score.

No new blocking runtime defect was found in this review. Pulsebreak 1.2 is suitable to present as a polished indie arcade demo with clearly stated support and evidence limits. Its next meaningful improvement is deeper, player-tested encounters and presentation, followed by another independent assessment of the complete experience.
