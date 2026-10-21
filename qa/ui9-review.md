# UI/theme loops toward 9/10 — record (2026-10-20)

Trigger: after 1.3.1's palette overhaul froze UI/theme at **6.6/10** with the verdict "the remaining distance to 9 is bespoke craft — custom iconography, authored card art, combat-frame art direction — not color discipline," the user asked for up to five more loops, stopping early only if a loop landed close to 9 (read here as ≥ 8.5 from independent reviewers scoring staged captures).

**Result: 9 was not reached in five loops.** Independent scores moved 6.6 → 6.9 → 7.2 → 7.3 → 7.5 → **7.6 / 7.2 (two reviewers, final)**. The loops were spent and stopped at the cap, same as 1.3.1: the score is reported, not chased with extra rounds.

## Method

- Each loop: implement in `scripts/hud.gd` (+ `scripts/palette.gd` tokens; deck paint in `scripts/art.gd` / `scripts/showcase_art.gd`; one `effects_low` line in `scripts/game.gd`; stat keys in `scripts/weapons.gd` offer dicts), regenerate staged captures with `tests/visual_check.gd` into `qa/ui9/loopN/captures/` (gitignored), then an independent agent reviewer scores the pixels only — Palette 15 / Typography 15 / Iconography 15 / HUD 20 / Cards 15 / States 10 / Not-AI 10 — and verifies the previous loop's defects from the captures.
- Captures are staged states, not playthroughs. Motion added in Loop 3 (modal fade, HUD fade, button hover scale, disabled in QA) is not visible in stills and was explicitly not credited.
- `sh tools/test.sh` — 15 suites, 632 checks — passed after every loop that touched shared code, including the final tree.

## Scores

| Loop | Score | What it bought |
|---|---:|---|
| Baseline (1.3.1) | 6.6 | Aerospace palette, embedded fonts, combat color law |
| 1 | 6.9 | UI kit: drawn `Glyph`/`Frame`/`Ticks`/`Pips` controls, ticked meters with threshold notch, diamond dash pips, combo timer bar, weapon pod, pill switches, thin-Line sliders, condensed left-aligned buttons, disabled states |
| 2 | 7.2 | Title sigil + courier leader line + caption rail + footer fixes; family glyphs/pips/frames on upgrade cards, graph-paper weapon blueprints, whole-card clicks; hangar glyphs, pips, core prices |
| 3 | 7.3 | Framed `sheet()` modals (pause/practice/settings/rebind), result debrief stat grid + build chips, sector sheet; chunked hull, screen corner frame, boss nameplate; motion system; staged ON/disabled/MASTERED states, armory + sector captures added to the harness |
| 4 | 7.5 | Reactor-seal ring unifying all glyphs, ghost seal watermarks, authored polygon gun silhouettes; neutral card borders/chips (orange de-overloaded), white card hover; deck rings repainted grey (floor orange = telegraph only), etch labels shrunk/moved in; boss name enlarged, banner plate; hangar NOW→NEXT lines, practice core-move legend, stage panels behind card rows |
| 5 | 7.6 / 7.2 | Glyph interiors redesigned (hex slow-field, courier wing, riveted armor plate, scoop claw, reactor cell, metronome, mini-carbine); Arc/Nova blueprints reworked; deck etch text removed, service rings sparse dashes; armory DMG/RATE/RANGE meters; `NEED N MORE CORES` disabled copy; family-diamond result chips; sigils on result/sector sheets; banner raised, timer dims under boss |

A regression pass after the Loop 5 review (no new score claimed) fixed what both final reviewers caught in Loop 5's own output: result sheet no longer clips `QUIT GAME` off-frame, Arc Relay blueprint pieces are connected by rails, per-card corner frames removed so the white focus outline is the only selection cue, sparse upgrade cards gained a `NEXT MK →` preview line, disabled button text raised to legible contrast, and unaffordable prices returned to white (red stays danger-only).

## Root cause found en route

Loop 2's first capture hung with `root.scale` Nil errors at `hud.gd` `_process`. First error in the log was the cause: assigning `anti_aliasing` on `StyleBoxLine` (no such property in Godot 4.7) aborted `_ready` before the root control was built. Fixed by removing the property; capture then completed with zero script errors.

## Why 9 is still not close, per the final reviewers

1. **No legible shape vocabulary at rendered size.** Sealed glyphs still collapse into a generic broken-circle icon pack below ~40px; several interiors misread (hex-nut, play button, paper plane). Both reviewers ask for bold silhouettes that survive 30px, likely without the universal seal.
2. **Combat uses an ellipse for almost everything.** Deck service rings (now grey dashes), enemy base rings, dashed pulse ring, and blast ellipse coexist in one frame; the staged pulse ring also spills outside the arena. One shape per meaning is a combat-FX art-direction project, not a HUD pass.
3. **Modal slabs vs the title.** The title screen is repeatedly called near-9; sector/result/practice sheets, settings, and hangar grids remain dark panels on black with corner ticks — coherent, but a genre template next to the title's authored composition.
4. **Microtype.** HUD sublabels, build lines, meter labels, and footers sit at 10–12px mid-grey; legible in captures, marginal at play distance.
5. **Focus/primary language still has two dialects** (solid cream primary vs white outline focus), even after the orange card frames were removed.

Evidence: `qa/ui9/{baseline,loop1..loop5}/captures/` (regenerable via `tests/visual_check.gd`, which now also stages the armory, a sector-complete sheet, an ON toggle, and affordable/unaffordable/mastered hangar states). No gameplay, balance, save-format, or audio behavior changed; `weapons.offer()` only gained display stat keys.
