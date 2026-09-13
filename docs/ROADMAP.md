# Possible next steps

The original experiment completed three review/fix cycles with an 8.2/10 observational result. Since then, [release 1.1](RELEASE_1_1.md) has added endless seeded sectors, flight, weapon progression, richer effects, a player-selected soundtrack and packaged M4 validation. The proposals below began with the original experiment; current release evidence is in the [QA index](../qa/README.md).

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
- Evaluate a direct replay-seed entry flow; the current game already reports its run seed in results.

Each proposal should begin with a concrete player problem and an observation that would validate the change. More effects, damage, enemies, or content do not automatically make the game more fun.

## Engineering work if the project grows

- Separate the QA driver and reporting helpers from the main director while retaining the same production ability path.
- Move tuning into a more convenient data format if balancing becomes frequent.
- Automate the documented engineering checks in CI after choosing the supported runner and engine-download policy.
- Add a signed/notarized distribution pipeline only if a downloadable Mac release becomes a project goal.

No CI badge, controller implementation, notarized public binary, or broad hardware guarantee is implied by this list.

## A stronger follow-up model experiment

Use a fixed task scope and review budget, capture time/cost/model settings, preserve all attempts, and evaluate several projects. Add independent human players and, if comparing models, matched tasks and blinded evaluation where practical. Keep the existing three-round scores unchanged and record new rounds as a separate experiment.
