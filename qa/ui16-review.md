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
| 2 | floor value restructure | 6.0 | 5.6 | 5.80 | ACCEPTED, best | (this commit) |

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
