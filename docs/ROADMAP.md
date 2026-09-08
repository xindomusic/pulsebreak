# Possible next steps

The initial experiment is complete: a playable game, three review/fix cycles, and an 8.2/10 observational result. This page proposes follow-up work; it does not claim those features or evaluations already exist.

## Improve the evidence first

| Priority | Work | Evidence needed to call it improved |
|---|---|---|
| 1 | New-player onboarding and control sessions | Uncoached practice completion, explained hits, deliberate harvesting, input-direction feedback |
| 1 | Listen to music and cues during dense combat | Actual audition of cue priorities, loop transitions, fatigue and perceived mix |
| 1 | Alternate-build balance study | Matched seeds/difficulty, suitable field-placement decisions, several documented wins and losses |
| 2 | Fresh final-build rendering benchmark | Exact source/PCK, hardware, settings, real frame samples, worst-wave and boss segments |
| 2 | Wider Mac coverage | At least one lower-memory Apple Silicon Mac, recorded resolution/settings and failures |
| 2 | Longer restart and focus-loss sessions | Repeated manual flows, stable resources, no lost controls or lingering hostile state |

## Small product improvements to evaluate

- Make the early encounter rhythm more engaging while preserving learning space and predictable harvest opportunities.
- Improve the visibility and impact of successful absorption through carefully tuned animation and sound.
- Refine boss pacing against human play; the recorded driver's finale was shorter than the original design target.
- Add controller support if a real player need justifies input and prompt work.
- Consider a replay seed visible to players so a bug or build can be reproduced without development flags.

Each proposal should begin with a concrete player problem and an observation that would validate the change. More effects, damage, enemies, or content do not automatically make the game more fun.

## Engineering work if the project grows

- Separate the QA driver and reporting helpers from the main director while retaining the same production ability path.
- Move tuning into a more convenient data format if balancing becomes frequent.
- Automate the documented engineering checks in CI after choosing the supported runner and engine-download policy.
- Add a signed/notarized distribution pipeline only if a downloadable Mac release becomes a project goal.

No CI badge, controller implementation, notarized public binary, or broad hardware guarantee is implied by this list.

## A stronger follow-up model experiment

Use a fixed task scope and review budget, capture time/cost/model settings, preserve all attempts, and evaluate several projects. Add independent human players and, if comparing models, matched tasks and blinded evaluation where practical. Keep the existing three-round scores unchanged and record new rounds as a separate experiment.
