# Skybound: research and design decisions

Research date: 2026-09-13. This follow-up targets a polished, short playable showcase. It does not establish that Pulsebreak has an AAA production budget, commercial readiness, or admission to any particular event. Recommendations below are project-specific design judgments informed by the linked primary sources; their effectiveness still needs playtesting.

## What the existing game needs

The starting game has a distinctive harvest-and-pulse loop, readable enemy warnings, original procedural art, local saves, practice, and a complete six-minute encounter. Its [historical final review](../qa/review-round-3.md) scored it **8.2/10 observationally**, while explicitly lacking extended human control and audio evaluation. Preserve that record.

The current implementation fixes the player's height to zero, tilts the body instead of articulating a gait, and uses one flat arena through the run. The [published combat capture](images/combat.png) also shows a small player against a large, mostly empty deck. Merely increasing polygon count would leave the largest player-facing gaps intact: movement expression, a reason to traverse vertically, and encounter progression.

## Findings translated into implementation

| Primary source and finding | Decision for Pulsebreak | Evidence to collect |
|---|---|---|
| [Celeste player source, published by developer Noel Berry](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs) implements a 0.1-second jump-grace timer and variable jump duration. | Add a short jump-input buffer and controllable ascent/descent. Add ledge grace if traversal includes actual ledges. Tune the timings for this camera and speed; Celeste's values are a reference, not a universal prescription. | Inputs slightly before landing work once; holding does not create infinite jumps; releasing changes the arc predictably. |
| [Riot: Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/) prioritizes recognizable silhouettes, visible facing, matching effects and hitboxes, and attention proportional to gameplay importance. | Give the player a recognizable articulated exosuit and unfolded flight silhouette. Reserve the brightest shapes for the player, imminent danger, and the active objective. Keep a ground marker while airborne. Ground-clearance mechanics must match the visual pose. | Gameplay-scale captures and motion at normal/low effects; identify player direction, target, projectile and danger without zooming. |
| [Riot: VALORANT Shaders and Gameplay Clarity](https://www.riotgames.com/en/news/valorant-shaders-and-gameplay-clarity) keeps gameplay-impacting character/VFX information when reducing quality and tests effects on lower-spec machines. | Reduce scenery, shadow cost and cosmetic particles first. Retain hazard borders, moving-gate state, player ground marker and target altitude cues. Rebenchmark the final candidate under the busiest encounter. | Same attack boundaries in both effects modes; actual render timings, machine and settings recorded. |
| [Nintendo: Tears of the Kingdom developer interview, part 3](https://www.nintendo.com/en-ca/whatsnew/ask-the-developer-vol-9-the-legend-of-zelda-tears-of-the-kingdom-part-3/) describes how sky content became cluttered and appeared too small at actual world scale, requiring visual adjustment; it also describes situation-dependent audio transitions. | Evaluate targets and the new model from the real game camera early. Use a few strong landmarks per sector, distinct atmosphere and an audible transition. Avoid filling the deck with decorative geometry that competes with combat. | Before/after at identical viewport, target visibility while flying, and a listened-to transition recording. |
| [Greg Donovan / Volition: The Vertical Slice Challenge, GDC 2015](https://gdcvault.com/play/1022328/The-Vertical-Slice) frames a slice as evidence that the team knows what it is making and how to make it. | Build one complete beginning-to-ending showcase with traversal, combat, progression, boss, results and replay. Evaluate the assembled experience rather than counting features or using an isolated beauty shot. | Uninterrupted full-campaign run, retry/quit flows and reproducible source/build identity. |
| [Godot: Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) documents glTF and Blender import; [Using AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html) covers state/blend control and root motion. | A Blender-to-GLB rig is a valid future asset pipeline. For this existing procedural style, a pivot rig with speed-driven gait, jump tuck, glide deployment and landing compression can deliver the immediate need with reproducible assets. Keep gameplay movement authoritative and synchronize animation to it. | No foot sliding at rest, distinct airborne poses, no limb discontinuities or model drift from its actual collision location. |

## Proposed short campaign

These stages and timings are design recommendations, not claims copied from a shipped game's structure.

1. **Teach:** a safe launch deck introduces jump, a nearby low aerial target, then a ground wave to clear. Show one active objective and retain the input hint until the action succeeds.
2. **Develop:** a wind sector spaces targets beyond a simple hop, giving finite glide and landing/refill decisions a purpose. Combine familiar shooting pressure with the new route.
3. **Master:** a reactor sector introduces visibly moving gates and combines jump, glide, harvesting and timed hazards. A boss concludes the campaign with previously taught warning language.

Each sector needs a distinct objective arrangement or hazard pattern, a legible transition, and explicit completion. A new palette or background label alone does not qualify as a new authored level for this review. Offer level replay for quick practice once the campaign route is coherent.

## Movement contract

- Jump and glide must change collision outcomes. Low ground damage can be cleared above a communicated height; airborne danger must still pose a threat where intended.
- Aerial targets need altitude eligibility, a forgiving horizontal capture volume and feedback on success. Walking under them cannot silently count as flying over them.
- Flight has a finite resource, a visible resource state, and a clear landing/refill rule. It cannot bypass the complete combat loop indefinitely.
- A ground marker separates projected screen position from actual landing position. Gates expose their opening, movement and danger state before a player commits.
- Rebinding, pause, settings, focus loss, death, sector transitions and restart must clear or preserve traversal state deliberately.

## Review standard

Use the [independent review protocol](../qa/skybound-review.md). The 9/10 target is a quality threshold to test against, not a score to award in advance. Automated victories demonstrate reachability and regression resistance. Screenshots demonstrate composition and layout. Human play and audio audition establish the parts those tools cannot establish.
