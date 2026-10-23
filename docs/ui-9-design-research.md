# Pulsebreak — design research: what 9/10 UI would take

Date: 2026-10-23. Status: research only, nothing here is implemented.
Method note: dimensions rated 0-10 with an explicit "what a 10 is"
per dimension (plan-design-review method), grounded in teardowns of
shipped games in Pulsebreak's class. Current scores are the measured
ui15 hill-climb endpoint (attempt 10, average 6.50; record:
`qa/ui15-review.md`). Scores below translate that measured state
into this doc's dimensions; they are design ratings, not new
reviewer scores.

## The one-sentence diagnosis

Pulsebreak has a competent UI *system* and no visual *author*. Every
reference that scores 9+ gets there one of two ways: one painted
material + one color-ownership code reused on every surface
(Hades), or near-zero ornament with a brutally strict role code
carried by every pixel (Dead Cells, Geometry Wars). Pulsebreak
currently has templated panels *and* a color code that does no
work (orange = accent + enemy shots + telegraphs + affordability +
selection at various times). Polish attempts cannot fix that;
only an art pass that picks one of the two strategies can.

Classifier (what kind of surface each screen is):
- Title + combat = EXPERIENCE: the game world is the hero; chrome
  must earn every pixel.
- Cards, hangar, settings, sheets = OPERATE: scanability and one
  state grammar beat expression; brand lives in details.
Pulsebreak currently treats both kinds the same (dark slab +
condensed caps), which is why reviewers call it a template.

## Dimension ratings: now vs what a 10 is

### 1. Combat readability — now 5/10 (heaviest weight, the ceiling)

Evidence: every reviewer round scored HUD/combat 5–6/10. Player
~45px in a still; white pulse rings/orbs/starburst are the loudest
and least intelligible elements; enemy shots, telegraphs, and deck
hairlines share one orange class; floor is bare; HUD pods carry
prose into combat.

**A 10 is:** a frozen frame parses in under a second, in
grayscale, at thumbnail size. Player, nearest threat, and nearest
pickup are each identifiable by silhouette + value alone. Every
bright pixel has a role: one hue/shape family = player, one =
hostile, one = harvestable, floor = darkest desaturated layer.
Areas of effect are filled translucent zones, never thin white
outlines. No sentences anywhere in the combat frame.

Gap: role-coding (Pulsebreak's orange does 5 jobs), filled
telegraphs, floor structure, player backing/halo, pod removal.

### 2. Iconography — now 4/10

Evidence: "six orange marks, six construction logics"; upgrade
row reads as three clip-art packs; Greedy Coils illegible at size
across 20 review rounds despite two redraws.

**A 10 is:** one construction system — shared grid/keylines, one
stroke-or-silhouette logic, one corner language, optical-weight
equalized — where each icon also carries its family's owned hue.
Every icon passes a 24px black-and-white silhouette test. A viewer
can sort icons into families without reading names. (Hades: one
symbol + one hue per god, 194 boon icons, silhouette-first with
ink outlines. Dead Cells: stat color carried identically by icon,
text, and gear.)

Gap: no construction grid, mixed metaphor/stroke/fill per icon,
family color exists but icon shapes don't share a system.

### 3. Surface, material, palette identity — now 6/10

Evidence: palette discipline is the best axis (11–12/15) but
"monotony"; panels called flat slabs in every round; gradient
attempt accepted yet still read as flat.

**A 10 is:** one material everywhere, shared with the world art
(painted metalwork in Hades; flat slab + rim-lit world art in Dead
Cells — either works, mixing neither fully doesn't). The frame
carries data (rarity/permanence/stat in the border itself), so
decoration and information are the same pixels. Removing all
decorative shadow would not collapse the design.

Gap: gradient is a tint, not a material; borders carry no data
(rarity/family live in text); arena's warm rust floor fights the
cold slate chrome.

### 4. Information architecture & hierarchy — now 6/10

Evidence: sheets/cards are tidy but cloned; title footer packs
best score + tutorial hint + key list at equal microtype weight;
sector/result/practice are the same composition for different
emotional beats.

**A 10 is:** every screen answers "first, second, third" without
reading: one hero element per screen (score, weapon blueprint,
mech), decision data second, system text last and quietest.
Victory, sector-clear, and practice-complete are visibly different
moments, not one modal with swapped headlines. If only 3 things
could show per screen, the design already knows which 3.

Gap: no per-screen hierarchy spec; everything set at similar
weight; emotional beats undifferentiated.

### 5. Typography & decision data — now 6/10

Evidence: "the actual numbers a player compares are the least
legible element on each card" (NOW → NEXT rows, resonance lines at
11–12px mid-grey); flavor and mechanics share styles.

**A 10 is:** two type voices max — a display face for names/titles
and a clean face for mechanics — with numbers never below ~14px,
never mid-grey on slate, tabular alignment for comparisons, and
stat-color doing emphasis (Dead Cells). Flavor text is typeface-
distinguishable from mechanics at a glance (Hades).

Gap: decision-critical deltas are the smallest, dimmest text;
three+ micro-label styles; slash/dot label tic (largely fixed).

### 6. Cards & choice architecture — now 6/10

Evidence: armory blueprints praised every round (the one bespoke
element); upgrade/hangar cards "assembled, not designed"; repeated
void/rhythm defects across series (mostly fixed by ui15).

**A 10 is:** a choice screen that inherits authorship from the
world — a character, object, or place presents the choice (Hades:
god portrait + voice precedes cards; Dead Cells: NPC/pedestal),
rarity/value reads from the frame before any text, and each card's
anatomy is icon → name → one-line effect with numbers inline.
Three options, one job: "which slot/family do I grow," not three
interchangeable stat sticks.

Gap: choices presented by nobody, in identical slabs; value read
from text, not frame; card art limited to armory blueprints.

### 7. Interaction states — now 6/10

Evidence: three hill-climb attempts spent here; final state
(cream focus fill, affordability as text color, selection as
border) is the first coherent grammar, scored best — but still
"focus systems remain templated" and hover/pressed are invisible
in stills by construction.

**A 10 is:** focus, selection, affordability, disabled, and
mastered each own a separate channel (fill / border / text color /
value / ornament) and the focused element is findable in a
freeze-frame without pixel-peeping (Hades: brightened frame +
unique ornament on a channel that never fights rarity color).
Keyboard-first: focus is the loudest state on screen, always.

Gap: grammar now consistent but quiet; states still mostly
border/fill swaps on identical rectangles.

### 8. Journey & diegesis — now 4/10

Evidence: settings is "a phone preferences sheet" in nearly every
round; gameplay-affecting options (Assist, Overdrive) sit in the
same OS-idiom list as volume.

**A 10 is:** gameplay-affecting choices live in fiction (Hades'
Pact of Punishment and God Mode-as-boon; Dead Cells' Guillain and
Collector), so the real settings screen handles only presentation
and input and is almost never the screenshot. Meta-progression
happens at a place (Mirror of Night, the Collector), not a menu.
The run's emotional arc — title promise → first harvest →
checkpoint relief → boss dread → debrief — is storyboarded, and
each beat has its own composition.

Gap: Assist/Overdrive/themes presented as OS toggles; hangar is a
grid screen, not a place; no storyboarded beats.

### 9. Motion & feedback — not scored by stills (real-game 10 needs it)

Our reviewer gate scores screenshots, so this dimension is
invisible to the hill-climb — a real 9/10 game is judged in motion.
References: Hades' panel transitions and easing; Geometry Wars'
grid warp as feedback; Nova Drift's scale-graded explosions;
Vampire Survivors treating damage numbers/flash as toggleable
juice. A 10 here: one authored motion moment per transition type,
exponential ease-out from a visible default, hit feedback readable
without numbers. Any future 9/10 claim based on stills alone
should disclose this dimension as unscored.

## Reference teardowns (condensed; sources at end)

**Hades** — one painted material + color ownership. Boons: 3 picks
mapped to exclusive slots; rarity read from frame color (white →
blue → purple → red) before text; frame color also encodes
temporary (gold laurel) vs permanent (blue laurel). One symbol +
one hue per god across doors, boons, codex. UI framed in Greek
metalwork in the same painted style as the world; Codex switches
material (parchment) to mark lore space. Divine serif for names,
clean sans for mechanics. Gameplay options fictionalized: Pact of
Punishment, Mirror of Night, God Mode as an actual boon.

**Dead Cells** — near-zero ornament, strict 3-color code
(Brutality red / Tactics purple / Survival green, Legendary gold)
carried identically by icons, text, and gear; affixes use prefix
glyphs in the text list. No card-draft: scroll picker, mutations
at an NPC, gear on pedestals. Icons from a 3D-to-2D pipeline at
~50px — chunky silhouettes by necessity. Settings honestly an OS
menu, but everything run-relevant happens at NPCs. Telegraphs are
unmissable (giant exclamation before attacks).

**Nova Drift** — whole arena on one fixed screen (wrap edges);
tiny ship compensated by glow/trail and an actual shipped
visibility-halo option. Cautionary tale: enemies sharing the
player's color is its documented legibility failure. One enemy
hull bar (last damaged) in the boss-bar slot; all stats exiled to
the pause screen. Dim static backdrop; a popular mod exists just
to fade bright backgrounds — the market asking for floor discipline.

**Vampire Survivors** — camera center-locked on a small player;
XP gems are geometry, enemies are sprites (sort threats from
pickups pre-attentively); areas are filled translucent circles,
never outline rings. HUD = full-width XP bar on the top edge +
two icon rows + in-world health; level-up pauses into a 3–4 card
takeover with reroll/skip/banish. Damage numbers and flashing are
options toggles — juice, not information.

**Geometry Wars: Retro Evolved** — the strictest role code:
1 enemy = 1 neon shape + 1 color + 1 behavior. The floor is a
reactive gravity grid that ripples under explosions: structured
and alive, yet near-black under actors at rest. HUD is almost
nothing (lives/bombs top-center, score at edge). No upgrade
screen at all — proof that zero interruption is a legitimate answer.

Transferable rules distilled from all five:
1. One hue + one silhouette family per role (player / hostile /
   harvestable), never reused across roles.
2. Frames carry data (rarity, permanence, scaling stat).
3. Two type voices; numbers are never the smallest text.
4. One panel material shared with world art; a second material
   only to mark a different kind of space.
5. Gameplay-affecting settings move into fiction (pact, NPC,
   console); the OS-style remainder shrinks.
6. Selection survives a freeze-frame on its own channel.
7. Icons pass a 24px black-and-white silhouette test.
8. A character/object moment precedes choice cards.
9. Areas are filled translucent zones; telegraph membership
   (in/out) must be decidable from one still.
10. Combat HUD = edge bars + icon rows; all prose on paused screens.

## Three candidate directions (divergent on purpose)

### A. Instrument Vector (evolve current identity) — recommended base

Keep the aerospace-technical brand and title (already the best
screens), rebuild the systems underneath:

- **Role-color law:** ice/cyan = player + harvestable energy
  only; signal orange = hostile shots + telegraphs only; amber =
  currency only; coral/red = boss/marked ground only. Orange
  stops being the UI accent in combat contexts; menus keep a
  desaturated steel + cream base so combat hues stay sacred.
- **Combat layer:** filled translucent telegraphs and pulse zones
  (no thin white rings); pulse gets a filled shock disc with a
  leading edge, clipped *visually* to the deck by a floor shader
  mask so FX never float over void; persistent soft halo disc
  under the player (Nova Drift's visibility option, on by default);
  deck gets a fine reactive-feeling grid + lane zoning at very low
  contrast (Geometry Wars lesson: structured, near-black at rest).
- **HUD:** pods die. Hull = top-left bar (unchanged), pulse charge
  = full-width thin bar on the bottom edge (VS XP-bar pattern),
  dash pips + weapon = one icon cluster bottom-left, build icons
  as a small glyph row. No sentences in combat; charge state is
  bar color + one word at most.
- **Icon system:** one construction grid (48 unit keylines:
  circle, diamond, chevron, bar), filled silhouettes with one
  negative-space cut, optical-weight equalized, family hue =
  Echo ice / Harvest orange / Wake cream *only* (and those hues
  then never mean anything else). 24px B/W test as the gate.
- **Cards:** frame carries mark/rarity (family-colored frame +
  mark pips in the frame, not floating text); blueprint plates
  (grid + dimension ticks, the armory's bespoke device) become
  the shared card material for upgrades and hangar too.
- **Settings → "Ship Systems" console:** custom steppers/segmented
  controls drawn in the same vector language (no iOS pills);
  Assist/Overdrive reframed as reactor limiter/governor toggles
  with in-fiction labels; theme picker becomes "Hull Finish"
  swatch plates. Same functionality, diegetic skin.
- **Type:** keep Oswald/IBM Plex pairing but enforce floors:
  decision numbers ≥14px at full contrast, flavor in italic serif
  or letterspaced caps at lower contrast — distinguishable by style.

Cost: medium. All vector-drawn in Godot (existing Glyph/Blueprint
code paths), floor is shader/material work, no illustration
pipeline. Keeps the title screen that already scores ~9 locally.

### B. Neon Vector Arena (Geometry Wars lineage, most different)

Re-skin combat wholesale: black void, wireframe/neon actors, one
shape+color per enemy behavior, reactive grid, almost no HUD
(score/combo top, charge as a ring around the player). Menus go
near-bare: big type on black, hairline rules, no panels at all.

Highest ceiling on combat legibility (the heaviest axis) and the
strongest screenshot identity — but it throws away the mech, the
3D arena, and the title screen, i.e. the two things reviewers
already rate as bespoke. It also fights the game's fiction
(stolen reactor, sky foundry) and would read as a different game.

### C. Painted Relic (Hades lineage, highest bespoke ceiling)

Commission-style painted frames, hangar as an illustrated place
with a quartermaster presence, god-tier presentation before each
upgrade choice (the reactor "speaks"), parchment-vs-metal
material split for lore vs gameplay.

Highest Iconography/Cards ceiling and the clearest path past
"template," but needs an illustration pipeline this project does
not have (Hades II: 194 boon icons, six-person art team). With
procedural Godot drawing it risks reading as imitation. Not
recommended solo; steal its *rules* (frame-as-data, choice
presented by an object) inside Direction A.

**Recommendation: A, with B's combat layer rules and C's
frame-as-data rule.** It is the only direction that raises the
three capped dimensions (combat, icons, diegesis) without
discarding the title/blueprint strengths or requiring painters.

## What 9/10 requires, axis by axis (hill-climb rubric)

| Axis (weight) | Now ~ | 9/10 requires |
|---|---|---|
| HUD/combat (20) | 5.5 | Role-coded still parse; filled zones; edge HUD; player halo |
| Palette (15) | 7.7 | Role-color law; arena wash regraded to chrome family |
| Typography (15) | 7.2 | Decision numbers ≥14px full contrast; two voices only |
| Iconography (15) | 5.5 | One construction grid; 24px B/W pass; family hue law |
| Cards & menus (15) | 6.8 | Frame-as-data; blueprint plate material everywhere; presenter moment |
| States (10) | 6.0 | Focus loudest on screen; one channel per state (close now) |
| Not-AI feel (10) | 5.0 | A material + codes a thumbnail can decode; no generic kit tells |

## Suggested art-pass phases (each = scored hill-climb attempts)

Run under `.agents/skills/ui-hill-climb` (art-pass mode): bigger
single-system swings, same keep-or-throw-out rule, diagnoses cite
which dimension's "10" definition the attempt aimed at.

1. **Role-color + filled zones** (combat): recolor shots/telegraphs
   to the law, filled pulse/telegraph zones, deck-masked FX.
   Gate: grayscale + squint test on staged combat/boss.
2. **Floor + player presence**: grid/zoning pass, player halo,
   arena wash regrade toward UI chrome temperatures.
3. **HUD edge rebuild**: pods → edge bars + icon cluster.
4. **Icon family v2**: construction grid redraw of all upgrade/
   perk glyphs; 24px B/W gate before review.
5. **Frame-as-data cards**: family/mark in frames; blueprint
   plates for upgrades + hangar.
6. **Ship Systems settings**: custom controls, fictional labels
   for Assist/Overdrive/themes.
7. **Type floors**: decision-data sizes/contrast pass (may fold
   into 4–6 if scores demand).

Each phase will likely take 1–3 attempts; expect rejections.
Realistic outcome if phases 1–6 land: combat 5.5→8, icons 5.5→8,
cards 6.8→8.5, weighted ≈ 8.3–8.7 — at or near the "close to 9"
bar. The last stretch past that is motion/juice and bespoke art
volume, which screenshot review cannot credit anyway.

## Risks and open questions

- Reviewer noise (±0.5–0.9) can reject good art-pass attempts;
  the hill-climb diagnosis step is the guard — a rejected phase
  with strong axis-level gains should be retried in refined form,
  not abandoned (skill step 5 covers this).
- Role-color law touches gameplay readability: recoloring enemy
  shots changes learned language for existing players. Needs a
  playability pass (suites + packaged sim don't judge this).
- Filled FX zones and floor masking are shader work; scope is
  real but bounded to combat_field/combat_fx.
- No visual DESIGN.md exists (DESIGN.md is the game-design
  draft). If Direction A is approved, seed a short visual design
  system doc from this research before implementation.
- Mockups: no gstack designer check was run for this research;
  generating 2–3 combat-frame mockups before phase 1 would de-risk
  the role-color law cheaply.

## Sources

Hades: [ArtStation art breakdown](https://retrostyle-games1.artstation.com/blog/boGL0/hades-game-art-style-a-deep-dive-breakdown),
[Inverse symbol guide](https://www.inverse.com/gaming/hades-symbol-meaning-guide-hera-dionysus-apollo-ares-aphrodite),
[Hades Wiki – God Mode](https://hades.fandom.com/God_Mode),
[Interface In Game – Hades](https://interfaceingame.com/games/hades/),
[Hyperlific on Jen Zee / Hades II icon count](https://www.hyperlific.com/articles/jen-zees-2d-defiance-and-the-hand-that-paints-hades-ii/).
Dead Cells: [Official Wiki – Stats](https://deadcells.wiki.gg/wiki/Stats),
[The Brutal Update (3-color code)](https://deadcells.wiki.gg/wiki/The_Brutal_Update),
[Modifiers/affix glyphs](https://deadcells.wiki.gg/wiki/Modifiers),
[Patch notes 11](https://dead-cells.com/patchnotes/11),
[Game Developer 3D-pipeline deep dive](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-),
[GamesBeat on telegraph exclamation](https://gamesbeat.com/dead-cells-review-the-apotheosis-of-the-roguelike/).
Nova Drift: [Wiki – Basics](https://nova-drift.fandom.com/wiki/Basics),
[V0.17.6 hull-bar notes](https://nova-drift.fandom.com/wiki/V0.17.6),
[Lords of Gaming review (visibility halo, backdrop)](https://lordsofgaming.net/2025/05/nova-drift-review-a-unique-retro-rogue-lite/),
[background-fade mod](https://yellowafterlife.itch.io/nova-drift-tweaks).
Vampire Survivors: [Level up](https://vampire.survivors.wiki/w/Random_LevelUp),
[Experience Gem](https://vampire.survivors.wiki/w/Experience_Gem),
[Options (damage numbers/flash toggles)](https://vampire.survivors.wiki/w/Options),
[Garlic filled area](https://vampire-survivors.fandom.com/wiki/Garlic).
Geometry Wars: [Giant Bomb wiki (shape=color=behavior, grid ripple)](https://giantbomb.com/wiki/Games/Geometry_Wars_Retro_Evolved),
[Eurogamer interview (gravity grid, HUD)](https://www.eurogamer.net/a-geometrywars-x360).
Icon systems: [Material icon keylines](https://m1.material.io/style/icons.html),
[Telerik icon guidelines](https://www.telerik.com/design-system/docs/foundation/iconography/styles-and-guidelines/).
Reference library for future teardowns: [Game UI Database](https://www.gameuidatabase.com/).
Internal evidence: `qa/ui14-review.md`, `qa/ui15-review.md`
(20 scored loops, 40 independent reviews).

