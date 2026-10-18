# Reforge — agent review loops

Branch `feat/lifelike-reforge`. Three independent reviewers per round (visual, combat feel, systems), strict 0–10 scoring, fixes applied between rounds. Round 5 is a single final weighted review.

## Scores by round

| Dimension | Base (1.2) | Round 1 | Round 2 | Round 3 |
|---|---:|---:|---:|---:|
| 3D model / lifelike | 5 | 6 | 6 | 5.5 |
| UI color | 5 | 7 | 7 | 7.5 |
| Combat animation / FX | 6 | 5 | 6 | 5.5 |
| Readability | 7 | 6 | 7 | 5 |
| Upgrade depth | 4 | 5 | 6 | 6 |
| Complexity / longevity | 5 | 4 | 5 | 5 |

## What each round caught and what changed

**Round 1 → fixes:** practice-run perk ordering bug; Capacitor III vent was free/infinite; four mark texts did not match code (echo II shields, radius III life, frost III timer, capacitor); resonances unexplained; elites lost scale/identity; Hangar maxed in <1 h; ordinary hits had no juice (gated flash, no knockback); enemies used plain boxes; palette was three divergent copies; title overlap.

**Round 2 → fixes:** boss death bursts were wiped by the deferred field clear; knockback was sub-perceptual; resonance banner re-fired; elite ring died after first attack; siphon overheal bank was clipped by other heals; echoes re-triggered chain; frost slowed through radius rings; grain had no UVs on chamfered armor; palette file existed but was not referenced; resonance reward used the threat color.

**Round 3 → fixes:** windup tracking made the charger lane lie (chargers now commit at windup start per the original contract; shooters track first half then lock; lane re-aimed in world space); HUD energy tick/READY hardcoded 30 while Capacitor raised the threshold to 39; bursts survived *every* clear (now opt-in); delayed volleys fired mid-hitstop (now on gameplay step); knockback could shove charging enemies; Hangar had no post-max sink (added repeatable Overcharge prestige cells, +1% score each, cost ×1.5 per cell); capacitor tradeoff now disclosed from Mk I; grain amplitude/scale raised; player contact shadow; bigger enemy shots.

## Evidence

- `sh tools/test.sh` — all fifteen suites pass, including the new `reforge` suite (31 checks) with regressions for the perk-ordering, vent, burst-clear, elite-scale, heal-ceiling, threshold and prestige bugs.
- Simulated Classic run wins (`qa/reforge/sim/active-metrics.json`); simulated Skybound clears 4 sectors (`qa/reforge/sim-campaign/`); windowed native run on Apple M5 Max (`qa/reforge/native/`) with staged captures in `qa/reforge/captures/`.
- FX stayed bounded in every run (allocated ≤132 of the 160 cap, zero recycled essentials).

## Round 4 fixes and final (round 5) review

Round 4 fixed the lying charger lane, the HUD threshold mis-signal, burst leakage across context clears, hitstop-delayed volleys, and added the prestige core sink; the final review also caught a zero-direction quaternion (guarded), an unlocked boss aim (now locked to its telegraph), and an objective/boss-bar overlap (fixed).

Final independent weighted score: **7.4/10** (Model 7.0, UI color 8.0, Combat 7.5, Readability 7.0, Upgrade depth 8.0, Longevity 7.0), up from the 1.2 release's 8.4-as-demo baseline measured on different axes and from this branch's own 5.5 round-1 average. No gameplay ship-blocker was found.

## Honest status

The reviewers did **not** certify 9/10. Their consistent verdict: the systems and color language are now coherent and bug-audited, but at the fixed gameplay camera the procedural models still read as polished toys rather than lifelike machines, and full meta-progression completes in roughly two hours of wins before prestige score-chasing. Human hands-on play remains the missing evidence for "fun".
