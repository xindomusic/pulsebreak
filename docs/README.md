# Documentation

**Current feature branch:** [Skybound player/developer guide](SKYBOUND.md) · [Research](SKYBOUND_RESEARCH.md) · [Independent review](../qa/skybound-review.md).

Pulsebreak has two stories: a playable native Mac game, and an experiment in building it with **GPT-6 Astra inside Codex**. These guides connect both stories to inspectable evidence.

## Choose a reading path

| You want to… | Read in this order |
|---|---|
| Play on your Mac | [Getting started](GETTING_STARTED.md) → [Gameplay](GAMEPLAY.md) |
| Understand the AI development experiment | [Experiment](EXPERIMENT.md) → [Lessons learned](LESSONS_LEARNED.md) → [Final review](../qa/review-round-3.md) |
| Modify the game | [Architecture](ARCHITECTURE.md) → [Testing](TESTING.md) → [Contributing](../CONTRIBUTING.md) |
| Build a standalone app | [Getting started](GETTING_STARTED.md) → [Mac export](MACOS_EXPORT.md) |
| Reproduce the evidence | [Testing](TESTING.md) → [QA index](../qa/README.md) → individual JSON reports |
| Inspect art and sound origins | [Assets](ASSETS.md) → [License notices](../LICENSES.md) |
| Plan a follow-up experiment | [Roadmap](ROADMAP.md) → [Experiment](EXPERIMENT.md) |

## Current guides and historical records

These guides describe the shipped experiment. The original [design](../DESIGN.md), [research notes](../findings.md), [implementation plan](superpowers/plans/2026-09-07-pulsebreak.md), and [progress log](../progress.md) preserve the development record. Some historical targets and early measurements were superseded. Use the final review and QA index for the accepted outcome.

The implementation was first committed as `a992452`. Public documentation was added afterward without changing gameplay. Native resource-pack hashes in QA reports identify evaluated packages independently of later documentation commits.

## Evidence labels

- **Engineering checks:** deterministic assertions about rules, state, persistence, and regressions.
- **Simulation:** a driver playing the rules, often headless or at fixed speed. That mode cannot measure real rendering performance.
- **Native benchmark:** actual elapsed render-frame intervals tied to a resource pack and machine.
- **Staged capture:** a constructed screen or scene used to inspect layout and cues.
- **Observational rating:** a sub-agent's judgment with documented limits, including missing extended human feel and audio audition.

The final rating is **8.2/10** after three review/fix cycles. It is not a 9+ certification, player survey, or comparison against another model.
