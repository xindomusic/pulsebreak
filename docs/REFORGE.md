# Pulsebreak Reforge — lifelike models, juicy combat, hours of progression

Shipped as **Pulsebreak 1.3.0** (tag `v1.3.0`, merged via PR #1). Base was 1.2.0 (independent grade 8.4/10 as an indie arcade demo).

## Design review — initial ratings (evidence from code at base)

| Dimension | Was | Why | What 10/10 looks like |
|---|---:|---|---|
| 3D model / lifelike | 5 | One flat material recipe (`roughness .78`) for almost everything, 12-segment spheres, ambient is a flat color, filmic tonemap, no bloom, no sky reflections | PBR per-surface recipes (ceramic clearcoat, brushed titanium, rubber, worn steel), sky ambient + reflections, ACES + bloom, 3-point lighting, panel lines, cables, worn edges, pulsing cores |
| UI color | 5 | HUD cyan `#76f7df`, art teal/cyan/violet/storm-purple all compete; purple rim light; no shared tokens | One token set shared by 3D, FX and HUD: deep-navy ink, mint-cyan player, amber harvest, coral threat, ice/amber/electric/mint weapons. No purple anywhere |
| Combat animation / FX | 6 | Good gait, flinch, pulse and debris; no hitstop, no dash afterimages, no damage numbers, no combo feedback, windups don't read on the body | Hitstop on kills/pulse, dash ghosts, floating damage numbers, combo counter with score multiplier, windup squash + eye flare, camera punch, landing dust |
| Upgrades | 4 | 9 one-and-done picks; a long endless run exhausts the pool and choices stop mattering | 9 upgrades × 3 marks (27 picks), each mark scales the effect and its tradeoff, mark III adds a twist; family resonance when all 3 of a family are owned |
| Complexity / longevity | 5 | 3 enemy roles + boss; no meta-progression, so a run leaves nothing behind | Splitter + mites, elite affixes (swift/armored/volatile) in deep sectors, salvage cores earned every run, Hangar with 6 permanent perks × 3 ranks |
| Readability | 7 | Shape + color + sound cues already; damage source still sometimes unclear at peak | Damage numbers colored by source, combo timer bar, low-hull vignette, energy threshold tick at 30 |
| Performance | 7 | Bounded pools everywhere; must stay that way | Every new effect pooled and capped; low-effects mode disables ghosts/numbers bloom extras |

## Rules that do not change

- Dash harvests orange shots; pulse needs 30 energy; two base dash charges.
- All effects stay bounded (`combat_fx` cap, projectile caps).
- Saves stay validated: bad data falls back to defaults and never blocks a run.
- Keyboard-first, fixed camera, practice teaches the same core move.

## What shipped in this branch

- **Lifelike models:** per-surface PBR recipes, procedural roughness grain (planar UVs on chamfered armor), sky ambient/reflections, ACES + bloom, warm-key/cool-fill/amber-rim lighting, contact shadows, pulsing reactor cores, 28-segment spheres, enemy builders on chamfered armor.
- **UI color:** one token file (`scripts/palette.gd`) referenced by HUD, weapons and FX; mint/amber/coral semantics everywhere; purple removed.
- **Combat:** hitstop, knockback, ungated impact sparks, dash ghosts, pooled damage numbers, combo multiplier, camera punch + boss camera, landing dust, windup anticipation, authoritative telegraphs (chargers commit; shooters lock aim halfway), hazard fill timers, stretched harvest shots, harvest marker flare, boss phase/death bursts.
- **Depth:** 9 upgrades x 3 marks with scaled tradeoffs and family resonances; Splitter/mites; elite affixes; salvage cores; Hangar (6 perks x 3 ranks) + repeatable Overcharge prestige.
- **Evidence:** 15/15 test suites, simulated Classic win, 4-sector Skybound completion, windowed native run and captures under `qa/reforge/`. Final independent weighted review: **7.4/10** — see `qa/reforge-review.md` for every round, including what still stands between here and 9.
