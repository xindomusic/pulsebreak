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
| 6 | 7.2 | 5.8 | 6.5 | Micro-label cuts (armory benefit folded into meters, duplicate mark reporting removed), boss banner to lower-third, frost glyph freeform chevrons + ghost watermarks removed, OFF-pill contrast, slider % units, arc blueprint coils |
| 7 | 6.8 | 5.8 | 6.3 | Armory numbered meters + tighter cards, boss banner plateless under boss bar, theme buttons wear their own theme, keybind chips right-aligned, wider/darker sheets, echo glyph mass |
| 8 | 7.2 | 6.5 | 6.9 | One focus language attempt (cream), armory single-verb buttons + labelled pips, sheet backdrop marks (sigil/sector numeral), mastered becomes non-button band, overcharge amber border, theme selection = white border + ◆ |
| 9 | 7.2 | 6.8 | 7.0 | Boss banner fully inside arena, "1 GUARDIAN" grammar, affordable installs get signal borders, reactor pod line becomes charge state, route strip contrast, stray deck "+" removed |
| 10 | 6.3 | 6.4 | 6.4 | Focus gets its own offset signal ring (cream back to CTA-only), coil + ignition-bolt glyph redraws, slider 0%/100% end labels, watermark unclipped + per-screen marks, title leader retargeted to the wing |

Loop 2 note: scores fell despite both reviewers confirming the loop-1
top defects (overflow, selected-theme) as FIXED. Reviewer B is a fresh
agent each loop and scores harsher on template-feel; loop-2's new
swatch strips read as clipped artifacts to both reviewers and cost
more than the fixes gained. Loop 3 addresses that directly.

## Outcome: all 10 loops run — 9/10 not reached

The series ran the full cap. Averages: 7.2 → 6.5 → 6.4 → 6.6 → 6.6 →
6.5 → 6.3 → 6.9 → 7.0 → 6.4. Best single verdict 7.8 (loop 1, A);
best late average 7.0 (loop 9). The ≥8.5 early-stop was never
approached. Loops 1–5 shipped in 1.4.0; loops 6–10 ship in 1.4.1.

Every concrete defect named in any loop was fixed and confirmed
FIXED or PARTIAL→FIXED by a later reviewer: layout overflow (×3
screens), theme picker (three redesigns), orange semantics, empty
banner plate, boss double-header, duplicated affordability text,
hangar grid overlap, micro-label duplication, numberless meters,
grammar, stray deck marks, watermark clipping. What never moved,
across all ten loops and both reviewers, is structural:

1. The combat still. A frozen max-charge pulse at the arena edge
   reads as overlapping white ellipses around thumbnail actors. In
   motion this is the game's core verb and it parses; in a still it
   cannot. No HUD-side change fixes a 3D readability/motion problem.
2. The template signature. Dark slab + corner ticks + condensed caps
   + diamond pips is the genre's shared kit. Ten loops softened it
   (dot separators, shadows, backdrop marks, contextual pod lines);
   removing it means a new art direction, not an eleventh loop.
3. Bespoke art depth. Title and weapon blueprints score at shipped
   standard in every loop; the drawn glyph set and flat panels
   elsewhere do not, despite three glyph redraw passes. Closing
   that gap is an asset-production project (authored icon set,
   textured panels, arena treatment), out of loop scope.

Measurement honesty: reviewer B is a fresh agent each loop and
scores 0.5–1.5 below A; reviewer A is also a new agent each loop
with ±0.9 spread (6.3–7.8 on comparable builds). Late-loop deltas
are inside reviewer noise. The defensible summary is a plateau at
~6.5 average (≈7.5 for the best screens), not any single number —
and not 9/10, which no loop claimed.
