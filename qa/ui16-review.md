# ui16 art-pass hill-climb record

Method: .agents/skills/ui-hill-climb (art-pass mode). Design source:
docs/ui-9-design-research.md, Direction A "Instrument Vector".
Baseline checkpoint 9d35e0b (= v1.4.2 UI). Fixed 10 staged captures
(qa/ui16/*/captures), 1440x900, two independent screenshot-only
reviewers (A /100 weighted rubric, B fresh-eyes /10). Accept only on
strict average win; tie/drop discards the attempt fully and restores
best checkpoint. Every rejection gets a written diagnosis.

## Baseline (loop 0) — 9d35e0b
- A: 56/100 = 5.6 (Palette 10/15, Type 9/15, Icons 7/15, Combat 10/20,
  Cards 9/15, States 6/10, Not-AI 5/10)
- B: 5.6/10 (Identity 6, Type 6, Icons 5, Combat 4, Cards 6, Flow 6,
  Originality 6) — "menus look like a real indie; combat looks like a
  prototype wearing those menus."
- Average: 5.60

| Attempt | Direction | A | B | Avg | Verdict | Checkpoint |
|---|---|---|---|---|---|---|
| 0 | baseline (v1.4.2) | 5.6 | 5.6 | 5.60 | — | 9d35e0b |
| 1 | role-color + filled zones + halo | 5.4 | 5.8 | 5.60 | REJECTED (tie) | — |
| 2 | floor value restructure | 6.0 | 5.6 | 5.80 | ACCEPTED, best | 9cff6ef |
| 3 | role-color retry (refined) | 5.6 | 5.9 | 5.75 | REJECTED | — |
| 4 | icon family v2 (bold grid) | 5.8 | 6.1 | 5.95 | ACCEPTED, best | cb70c1f |
| 5 | frame-as-data cards | 6.1 | 4.7 | 5.40 | REJECTED | — |
| 6 | frame rails refined | 5.7 | 6.1 | 5.90 | REJECTED | — |

## Attempt 1 — role-color law + filled zones + player halo — REJECTED (tie)
Change: pulse recolored cream→constant ice (a9e3ff/4fb4ff), aftermath
opacity .18→.30, ground FX inscribed into deck, enemy telegraph gained
filled disc (alpha .15, elite-tinted), player halo disc (alpha .32).
Gates passed (grayscale parse OK, zones visible). Scores: A 5.4
(Palette 10, Type 10, Icons 6, Combat 10/20, Cards 8, States 6, Not-AI
4), B 5.8 (Identity 6, Type 7.5, Icons 4.5, Combat 5.0, Cards 6.5,
Flow 7, Originality 4). Avg 5.60 = baseline → discarded in full.

Diagnosis:
- Targeted axis (combat, 20%) barely moved: A flat 10/20, B 4→5. Both
  reviewers name the same binding constraint, and it is not zone coding:
  "actors are tiny specks on a dominant empty grid" (A), "action
  occupies <5% of frame" (B). Filled 60px telegraph discs and a halo
  under an already-white mech are below the perception threshold at
  capture scale; the halo was invisible in my own gate read.
- The ice pulse actively hurt with A: "oversized cyan dashed ellipse
  and blown-white blast obscure what is actually dangerous" — the hue
  swap + aftermath .30 made the pulse louder without making threats
  clearer. Role color alone does not create hierarchy when the floor
  and FX out-shout the actors.
- Not-AI fell (A 5→4, B 6→4) on untouched evidence (settings pills);
  treated as reviewer noise, not caused by this change.
- ui15 attempt 1 already proved camera zoom cannot fix actor scale
  (27.0 hid deck rows under the HUD). The remaining lever is VALUE:
  darken/flatten the floor so actors win by contrast instead of size.
Consequence: attempt 2 = phase 2 floor value restructure (darker,
lower-contrast deck, dimmed inlays/props, subtle center arena wash).
Role-color/filled zones may return later as their own scored attempt
on top of a quieter floor, where 60px discs can actually be seen.

## Attempt 2 — floor value restructure — ACCEPTED (5.80)
Change (scripts/art.gd only): deck #232a31→#171d24, deck_alt
#2a323a→#1a2029 (checker delta ~7→3), deck_deep→#10141a, inlay
teal_dim #8a4d1e→#5f3413 with emission .35→.22. Measured deck-corner
luminance 41→26 (−37%). A center "arena wash" disc was tried in-attempt
and removed pre-score: it rendered as a hard-edged blue decal ellipse.
Scores: A 60/100 (Palette 11, Type 11, Icons 6, Combat 11/20, Cards 10,
States 6, Not-AI 5), B 5.6 (Identity 6, Type 7, Icons 5, Combat 4.5,
Cards 6.5, Flow 6, Originality 4.5). Avg 5.80 > 5.60 → new best.
Notes: gain concentrated in A (palette/combat/cards/type +1..2); B flat
overall, still calls combat an "empty prototype" — floor value helped
contrast but arena emptiness/actor scale remain the combat cap. Icons
now the worst axis for both (6/15, 5.0).
Next (per attempt-1 diagnosis): retry role-color + filled zones on the
quieter floor, refined — pulse loudness reduced (A: "oversized ellipse
obscures"), telegraph fills/halo stronger since the floor is darker.

## Attempt 3 — role-color retry on quiet floor — REJECTED (5.75 < 5.80)
Change: attempt-1 system refined — ice pulse with boundary opacity cut
(.12-.18→.09-.14, aftermath back to .18), deck-inscribed ground FX,
telegraph fills alpha .22, halo r1.05 alpha .28. Gates passed.
Scores: A 56/100 (Palette 10, Type 9, Icons 7, Combat 11/20, Not-AI 4),
B 5.9 (Identity 6, Type 6.5, Icons 4.5, Combat 5.5, Cards 7, Flow 7,
Originality 5). Avg 5.75 → discarded in full.

Diagnosis:
- Combat (target): A flat 11/20, B 4.5→5.5. The filled zones likely
  earned B's point, but A explicitly charged the hue: palette 11→10,
  "powder-blue dash arcs fracture [the palette] in play". Net −0.05.
- Two attempts, same lesson: this game's identity is warm (cream/
  burnt-orange/ochre). Importing a saturated azure family (#a9e3ff/
  #4fb4ff) to code "player" reads as foreign, and the palette axis
  bills what the combat axis gains. Role separation here must come
  from value and shape (cream filled vs orange outline), not hue.
- Type swung A 11→9 untouched — reviewer noise band confirmed ±2/15.
Consequence: role-color-by-hue is closed. A future combat attempt may
test filled zones ALONE (cream pulse untouched). Next: icons — the
worst axis for both reviewers across all four scorings (A 6-7/15,
B 4.5-5.0) and named a top-3 problem; independent of combat noise and
it also feeds the Cards axis.

## Attempt 4 — icon family v2 (bold construction grid) — ACCEPTED (5.95)
Change (scripts/hud.gd Glyph): bold set completed from 7 to all kinds —
new filled silhouettes for capacitor, radius, chain, wake, dash, armory,
combo, core; collector thickened; armory/hull tuned after the 24px B/W
gate (all 9 visible glyphs survive as distinct silhouettes;
qa/ui16/attempt4/gates/icons-24bw.png). Non-bold small marks untouched.
Scores: A 58/100 (Palette 11, Type 9, Icons 8, Combat 11/20, Cards 9,
States 5, Not-AI 5), B 6.1 (Identity 6.5, Type 7.5, Icons 5.0, Combat
5.5, Cards 7, Flow 6.5, Originality 4.5). Avg 5.95 > 5.80 → new best.
Notes: A rewarded icons +2 (6→8); B held icons at 5.0 but lifted
combat/cards. Worst axes now: States (A 5), Not-AI (5/4.5), Combat
(11/20, 5.5). Recurring verbatims: cards are "identical flat slate
slabs with dead vertical gaps"; combat "prototype-looking".
Next: phase 5 frame-as-data cards (family-coded frames, cost/state in
the frame itself, kill dead card space).

## Attempt 5 — frame-as-data cards — REJECTED (5.40 < 5.95)
Change: CardRail overlay (left family bar + top segmented marks rail)
on upgrade/weapon/hangar cards, family-tinted card borders (alpha
.38), upgrade card height 452→430.
Scores: A 61/100 (Palette 12, Type 10, Icons 7, Combat 10/20, Cards
11, States 6, Not-AI 5), B 4.7 (Identity 5.5, Type 6, Icons 3.5,
Combat 4.0, Cards 5.5, Flow 5.0, Originality 3.5). Avg 5.40 →
discarded in full.

Diagnosis:
- A rewarded the system (cards 11/15 "strongest system", palette 12
  series-high) BUT both reviewers independently flagged the same flaw:
  dual focus cues — "cream [1] button vs. orange border on card 02"
  (A), "card 1 bone-white button + card 2 orange edge — dual focus"
  (B). In this game's settled grammar (ui15 attempts 9-10) a colored
  border MEANS selection; tinting borders by family — HARVEST is the
  signal orange — manufactures a false selected card. Real defect.
- B still measured "~150px empty void mid-card above FINAL MARK":
  height 452→430 did not fix the spacer placement (gap sits between
  description and the NEXT/resonance block).
- B's draw was also globally harsh: combat scored 4.0 on pixels
  unchanged since attempt 2 (B combat history 4.5→5.5→4.0) and icons
  3.5 vs 5.0 on the same glyphs A scored 7-8. Inter-reviewer noise is
  ±0.75 on untouched axes; the total cannot be re-rolled, only the
  design refined.
Consequence (refined retry, attempt 6): frame data stays in the RAIL
only (segmented top rail + left bar read as progress/identity, not
selection); borders return to neutral PANEL_LINE; card content
regrouped so NEXT/resonance sit under the description and the only
flex space is a short gap above the button; card height trims to fit.

## Attempt 6 — frame rails refined (neutral borders, regrouped) — REJECTED (5.90)
Change: attempt-5 rails without border tint; upgrade-card NEXT/
resonance regrouped under description, spacer only above button,
height 430. Scores: A 57/100 (Palette 11, Type 10, Icons 7, Combat
9/20, Cards 9, States 6, Not-AI 5), B 6.1 (Identity 6.5, Type 7,
Icons 5, Combat 5.5, Cards 7, Flow 6.5). Avg 5.90 < 5.95 → discarded.

Diagnosis: dual-focus complaint is gone, but cards land exactly where
attempt 4 left them (A 9, B 7.0) — the rail/regroup is below the
reviewers' reward threshold for this panel language; two attempts say
cards are at a local plateau. A combat dipped 11→9 on untouched
pixels (noise). Consequence: stop spending attempts on cards. The
heaviest remaining lever is combat structure — every B review names
the three bottom HUD slabs ("exiled boxes", "dashboard") and the
prototype arena. Attempt 7 = phase 3 edge HUD.
