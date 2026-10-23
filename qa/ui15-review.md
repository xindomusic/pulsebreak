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
| 2 | a813585 | Remove all corner-tick Frames + sheet backdrop watermarks | 6.0 | 6.0 | 6.00 | ACCEPTED → a319967 |
| 3 | a319967 | Baked vertical-gradient panel texture (all panel() fills; shadows dropped) | 6.2 | 6.0 | 6.10 | ACCEPTED → 6cb2e89 |
| 4 | 6cb2e89 | Deep-shadow sharp-corner flat panels (material via depth) | 5.9 | 5.8 | 5.85 | REJECTED |
| 5 | 6cb2e89 | Center result/sector/practice sheets | 6.4 | 5.9 | 6.15 | ACCEPTED → 32f1748 |
| 6 | 32f1748 | White focus ring + Aftershock copy-contradiction fix | 5.8 | 5.9 | 5.85 | REJECTED |
| 7 | 32f1748 | Focus as fill-lift wash + footer restructure (FINAL MARK, bottom-aligned) | 6.5 | 6.2 | 6.35 | ACCEPTED → ac1841e |
| 8 | ac1841e | Title annotation cleanup (hide floor labels on title, drop leader ticks) | 6.3 | 6.3 | 6.30 | REJECTED |
| 9 | ac1841e | Affordability off borders (signal text), neutral unselected theme borders | 6.2 | 6.6 | 6.40 | ACCEPTED → 475eaf6 |
| 10 | 475eaf6 | One focus grammar: opaque cream focus fill everywhere | 6.6 | 6.4 | 6.50 | ACCEPTED (final) |

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

## Attempt 2 outcome (accepted, 6.00 > 5.75)

Corner ticks gone from all menu panels (A: PARTIAL — remaining
"ticks" are 3D deck inlays, not UI), watermarks gone. B rose
5.4 → 6.0; A flat at ~6. B's new #2: title artefacts ("three
disconnected grey horizontal bars hover beneath the platform").
A's key line for what comes next: "Removing ornament has not
replaced it with a distinctive material or frame system."
Design consequence: attempt 3 gives panels a material — a baked
vertical-gradient panel texture (lighter top edge → darker base,
border baked in) replacing flat StyleBoxFlat fills everywhere
panel() is used. Trade-off accepted upfront: StyleBoxTexture has
no shadow, so panel drop shadows go away with it; the attempt
tests whether material beats shadow.

## Attempt 3 outcome (accepted, 6.10 > 6.00)

Small win, but A's verdict on the material blocker stayed OPEN:
"identical flat gradient + hairline in every still. No panel in
any capture has cast shadow, edge thickness, texture, or fastening
detail." The gradient is below perception at still scale while the
lost shadow was doing real depth work. Design consequence:
attempt 4 tests the opposite material lever from the same
checkpoint question — flat fills return, but with sharp (0-radius)
corners and a much stronger cast shadow (size 9, offset 4), i.e.
material read through depth and edge instead of surface gradient.
Whichever of attempt 3/4 scores higher becomes the panel system;
the loser is discarded by construction.

## Attempt 4 diagnosis (rejected, 5.85 < 6.10)

- Changed: panel() back to StyleBoxFlat, corner radius 3 → 0,
  shadow 5 → 9 (offset 4, alpha .55); gradient texture removed.
- Evidence: A improved the material verdict OPEN → PARTIAL
  ("Buttons now cast a soft bottom shadow… panels themselves
  remain a single flat fill with a 1px hairline") yet scored the
  attempt lower overall (5.9 vs 6.2; B 5.8 vs 6.0). Sheet shadows
  are invisible against the dark shade; only button shadows read.
- Why it failed: the depth cue lands where it is least needed
  (buttons on panels) and vanishes where it matters (sheet on
  black). Sharp corners alone read harsher without the gradient's
  surface variation. Gradient (attempt 3) is the better panel
  system of the two; checkpoint 6cb2e89 stands.
- Design consequence: panel material is settled — further attempts
  keep the gradient. Attempt 5 attacks the longest-running
  composition defect instead: result/sector/practice sheets are
  "one cloned composition" parked at left with a dead right half
  (A attempt 4 defect #2; B every attempt). Center all three
  sheets so the negative space becomes symmetric margins around a
  single composed column.

## Attempt 5 outcome (accepted, 6.15 > 6.10)

Centered sheets landed as composed columns; the practice mech no
longer peeks from behind a panel edge. Marginal win (+0.05, inside
reviewer noise, but a strict win per the rule). Sheets still share
one skeleton — accepted as the system, not a defect to chase further
this series.

## Attempt 6 diagnosis (rejected, 5.85 < 6.15)

- Changed: focus ring orange → white (orange border reserved for
  "affordable"); Aftershock card's contradictory fallback text removed.
- Evidence: A confirmed Aftershock FIXED, but focus stayed OPEN:
  "Focus on Ion Servos is only a second white hairline inside that
  orange border. At a glance all four look identical; you have to
  pixel-peep to find focus… no fill, lift, or card-level emphasis
  separates the selected purchase." B: focus "inconsistent — single
  white (armory/upgrades) vs white+orange double (hangar)". B also
  caught a regression my copy fix caused: card 1 lost its filler
  line, so "its RESONANCE line floats high above a dead gap while
  cards 2–3 are dense — baselines across the row don't line up."
- Why it failed: swapping one hairline color for another does not
  create a glanceable state; nested hairlines (focus inside
  affordable) are worse than either alone. And deleting text
  without restructuring the card footer broke cross-card rhythm.
- Design consequence: attempt 7 makes focus a *fill lift* (pale
  wash + white offset ring) instead of another hairline color, and
  re-enters the Aftershock fix together with a restructured card
  footer: spacer moves above the NEXT/RESONANCE block so the block
  bottom-aligns on every card, and max-mark cards show "FINAL
  MARK" so the block height is identical across the row.

## Attempt 7 outcome (accepted, 6.35 > 6.15)

Footer baselines confirmed fixed ("the three resonance lines and
the three buttons now share common baselines"). Focus verdict
stayed OPEN but softened — the wash reads, yet affordable orange
borders still nest against it.

## Attempt 8 diagnosis (rejected, 6.30 < 6.35)

- Changed: title floor labels hidden on the title stage; caption
  leader ticks removed.
- Evidence: captions no longer garble (no reviewer re-flagged the
  collision), but scores moved −0.05 — inside reviewer noise. The
  title is 1 of 10 captures and was already the strongest screen;
  cleaning it cannot move the weighted average.
- Why it failed: effort spent on the best screen instead of the
  worst axes. Grey platform bars (3D geometry) also remain.
- Design consequence: remaining attempts must touch the heavy
  axes. Attempt 9 finishes the state language: affordability moves
  off borders entirely (signal-colored button text; price stays
  amber), unselected theme buttons get neutral borders (only the
  selected theme and keyboard focus may draw a strong border).
  That directly answers "four orange rectangles" (A a6/a7) and
  "all four swatches carry a coloured border" (B a7).

## Attempt 9 outcome (accepted, 6.40 > 6.35)

Borders quieted; B's 6.6 is the series-best fresh-eyes score. But
A a9 names the remaining grammar split: "primary actions are
cream-filled on linear menus but merely white-outlined on card
screens, so [1] UNLOCK & EQUIP looks less selected than UPGRADE &
DIVE DEEPER." Design consequence for the final attempt: one focus
grammar everywhere — keyboard focus becomes the same opaque cream
fill as primary CTAs (ink text), so "the action Enter will fire"
wears one uniform on every screen. Affordability stays on text
color (attempt 9), selection stays on borders — three channels,
three meanings.

## Attempt 10 outcome (accepted, 6.50 > 6.40) — series complete

Cream focus unified the grammar; A (6.6) is the highest
history-aware score of the series. The 10-attempt cap is now
exhausted with the best checkpoint also being the last:
5.75 (baseline) → 6.00 → 6.10 → 6.15 → 6.35 → 6.40 → **6.50**.
Four attempts were rejected and thrown out (1, 4, 6, 8), each with
a diagnosis above that shaped the next accepted attempt.

9/10 (≥8.5) was not reached. The hill-climb guarantees the shipped
state is the best measured state, not that the target is met: the
remaining blockers named in the final reviews are the same
structural three as ui14 — combat stills do not parse (white FX
over a bare floor), the glyph set is not one authored family, and
settings uses OS-idiom controls. Those need an art pass
(combat presentation, authored icons, diegetic settings), which is
a different kind of project than scored polish attempts. What the
series demonstrably bought: no layout breakage in any final
capture, one focus grammar, affordability/selection/focus on
separate channels, panel material, centered composed sheets, and
contradiction-free card copy — each kept only because two
independent reviewers scored it higher than what it replaced.
