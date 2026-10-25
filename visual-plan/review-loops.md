# AAA playable build — 2 review loops (2026-10-25)

Build: `design-aaa.html` — real playable three.js game (hand-built, verified headless end-to-end:
title → combat → dash-absorb → pulse → glide → upgrade cards ×2 → Reactor Guardian → victory;
damage → defeat → retry; pause/resume; phone touch layout). Zero console errors in every run.

Method: fixed captures `01-title … 07-end` at 1440×900 from scripted keyboard play,
scored independently by two screenshot-only reviewers against `refs/hero.png` + `refs/combat.png`.
Loop snapshots kept: `loop1/design-aaa-loop1.html`, `loop2/design-aaa-loop2.html`.

## Scores

| Loop | Reviewer A | Reviewer B | Mean | Fidelity | HUD+UI | Camera |
|------|-----------|-----------|------|----------|--------|--------|
| 1 | 4.3 | 4.1 | **4.20** | 3.5 / 3.2 | 6.0 / 5.6 | 4.0 / 4.0 |
| 2 | 4.3 | 4.8 | **4.55** | 3.8 / 4.2 | 6.5 / 7.0 | 4.0 / 4.1 |

Loop 2 wins → shipped as `design-aaa.html`.

## Loop 1 → why it scored 4.2
Stacked-box characters, flat mustard sky, floating black slabs, camera too high/far,
combat FX invisible in stills (pulse/glide captures identical to combat), pale HUD microtype
unreadable against bright sky. Title/cards UI praised as the strongest element.

## Loop 2 fixes (from loop-1 findings)
Layered hero armor + glowing visor/reactor + 3-blade segmented wings + bigger detailed gun;
enemy horns/drums/spikes; boss shoulder cannons + reactor stacks; deeper teal sky & fog;
cloud sea raised + sea floor disc; gantry cranes in silhouette ring; deck pipes/vent stacks;
camera lower/closer; player scale up; deck emissive dimmed; double pulse ring; thicker tracers;
glide thruster wash; HUD text-shadow + larger labels; faster boss banner.

## Loop 2 → remaining gaps (reviewers, honest)
Still reads as stylized blockout vs AI key art: "Tron circuit board" deck wants desaturating into
wet gunmetal plates with thin amber inlays; foundry skyline/cloud sea should survive in the
gameplay camera frame; boss framing clips at arena edges; pulse/glide still under-sold in stills;
boss timer shows `-:-`; combat HUD ghosts under card/end blur. UI/type system (6.5–7.0) is the
carrying strength. AAA photoreal parity was never reachable in real-time primitives — scores
reflect art-directed quality, not key-art replication.
