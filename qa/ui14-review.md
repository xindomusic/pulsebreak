# Pulsebreak 1.4.0 UI/UX review loops

Goal: close to 9/10 (stop early at >= 8.5 average), max 10 loops.
Method: 10 staged 1440x900 captures per loop (`tests/visual_check.gd`),
two independent screenshot-only reviewers per loop (A = history-aware,
B = fresh eyes). Weights: Palette 15, Typography 15, Iconography 15,
HUD/combat 20, Cards 15, States 10, Not-AI feel 10. Motion not credited.

| Loop | A | B | Avg | Main moves |
|---|---|---|---|---|
| 1 | 7.8 | 6.6 | 7.2 | Bold filled-silhouette glyphs, dashed-arc telegraphs, unified focus dialect, left-anchored sheets, microtype floor |
| 2 | 7.3 | 5.6 | 6.5 | Overflow fixes (upgrades/settings/result), theme swatches + primary selected state, ON pill-only outline, duplicate glyphs split (battery bolt, echo crescents), neutral armory meters, deck ring reduction |
| 3 | 6.6 | 6.1 | 6.4 | Orange = focus only (cream pills/sliders), swatch header strips, sheet lockups + route strip + NEW BEST, hangar name block, title caption leaders, deck etch removal |
| 4 | 6.7 | 6.4 | 6.6 | Panel drop shadows, theme accent diamonds (strips removed), slash→dot pass 1, hangar affordability dedupe + bottom row on grid, button borders lifted |
| 5 | 6.8 | 6.4 | 6.6 | Empty-banner-plate bug fixed at HUD invariant, boss timer readable, slash→dot pass 2, upgrade CTA pinned to card foot, button fills lifted; post-review regression fix: hangar card overlap (row pitch/content budget) verified by pixel check |

Loop 2 note: scores fell despite both reviewers confirming the loop-1
top defects (overflow, selected-theme) as FIXED. Reviewer B is a fresh
agent each loop and scores harsher on template-feel; loop-2's new
swatch strips read as clipped artifacts to both reviewers and cost
more than the fixes gained. Loop 3 addresses that directly.

## Outcome: loops closed at 5 of the 10-loop cap — 9/10 not reached

Averages plateaued for four straight loops (7.2 → 6.5 → 6.4 → 6.6 →
6.6) while every concrete, fixable defect the reviewers named was
fixed and confirmed FIXED in the following loop (layout overflow,
theme picker, orange semantics, banner plate, duplicated text, grid
alignment). Best single verdict: 7.8 (loop 1, reviewer A). The
remaining gap is structural, and both reviewers name the same three
walls in every loop:

1. The combat still. A frozen max-charge pulse at the arena edge
   reads as overlapping white ellipses around thumbnail actors. In
   motion this is the game's core verb and it parses; in a still it
   cannot. No HUD-side change fixes a 3D readability/motion problem.
2. The template signature. Dark slab + corner ticks + condensed caps
   + diamond pips is the genre's shared kit. Reducing slash labels
   and adding panel shadows softened it; removing it means a new
   art direction, not another polish loop.
3. Bespoke art depth. The title and the weapon blueprints score at
   shipped standard in every loop; the drawn glyph set and flat
   panels elsewhere do not. Closing that gap is an asset-production
   project (authored icon set, textured panels), out of loop scope.

Reviewer B is a fresh agent each loop and consistently scores
0.5–1.5 below A; treat the plateau (~6.5 average, ~7.5 best-screen
average) as the honest range, not any single number. Loops 6–10
were not run: four consecutive flat averages with all named defects
fixed is the evidence that more loops of the same kind would not
reach 8.5. The 1.4.0 features (themes, level variety, self-update)
ship on this UI.
