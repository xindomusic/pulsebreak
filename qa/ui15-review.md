# Pulsebreak UI hill-climb series (ui15)

Method: `.agents/skills/ui-hill-climb/SKILL.md`. Every attempt starts
from the best-scoring checkpoint; a tie or drop throws the code out
and produces a written diagnosis that designs the next attempt.
Target: average ≥ 8.5 ("close to 9"). Cap: 10 attempts.
Score = average of two independent screenshot-only reviewers
(A history-aware /100, B fresh-eyes /10), fixed rubric:
Palette 15, Typography 15, Iconography 15, HUD/combat 20,
Cards 15, States 10, Not-AI feel 10. Same 10 captures per attempt
(`tests/visual_check.gd`, 1440x900). Motion not credited.

| Attempt | Base | Direction | A | B | Avg | Verdict |
|---|---|---|---|---|---|---|
| 0 (baseline) | a813585 (= 1.4.1) | — | 6.1 | 5.4 | 5.75 | checkpoint |
| 1 | a813585 | Gameplay camera zoom 31.8 → 29.8 (boss 26.6) | 6.1 | 5.4 | 5.75 | REJECTED (tie) |

## Baseline diagnosis (designs attempt 1)

Both reviewers rank combat scale/readability #1 (20% axis):
"player is a thumbnail in an empty warehouse floor", "roughly 40px
tall in a mostly empty 920px arena", "larger actors / tighter arena
framing" (A's prescribed fix kind: structural, not recolor). The
gameplay camera is orthographic size 31.8 while the arena is ~32
units wide inside a ~51-unit horizontal view — the fight occupies
barely 60% of the frame width. Attempt 1: zoom the gameplay camera and change nothing else, so the
score delta attributes cleanly to scale. (27.0 was tried first and
rejected pre-review by pixel check: arena top/bottom rows slid
under the HUD. Scored at 29.8.)

## Attempt 1 diagnosis (rejected, tie 5.75)

- Changed: gameplay ortho size 31.8 → 29.8 (boss 26.6), +7% actor scale.
- Evidence: both reviewers returned *identical* scores to baseline
  (A 61/100, B 5.4). Combat stayed defect #1 for both: A "player
  mech is roughly 45×65 px… arena spanning ~68% of frame width…
  off-arena fans are cropped mid-object at the frame edges"; B
  "enemies are ~20px… white pulse effect is broken dashes".
  HUD/combat axis unchanged (B 5/10).
- Why it failed: +7% scale is below the reviewers' perception
  threshold, and the axis is capped by floor emptiness and FX
  shape-language, not actor pixels. Tighter framing also cropped
  backdrop turbines at the edges — trading one complaint for another.
  Harder zoom is not available: 27.0 put arena rows under the HUD.
- Design consequence: camera direction abandoned. Attempt 2 attacks
  the other axis both reviewers rank top-3 in every series — the
  template signature (B: "navy cards, orange corner-brackets on
  every panel"; A: "cloned left-sheet menus") — by removing all
  corner-tick frames and the sheet backdrop watermarks (B baseline:
  "cropped watermark… reads as placeholder art") in one pass, a
  change visible on all 10 captures at once.
