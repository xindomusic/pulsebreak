# Documentation

**Current release: [Pulsebreak 1.2.0](RELEASE_1_2.md).** Download the universal Mac app from the [GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.2.0). The release includes original Prism Drive dubstep, combat effects, endless sectors, evolving weapons, flight and Quit controls.

[Game grade and review](../qa/release-1.2-review.md) · [Changelog](../CHANGELOG.md) · [Verification index](../qa/README.md). The source is on `main`, tagged `v1.2.0`; `v1.1.0` marks the previous verified release revision.

[Resonance](RESONANCE.md) records the earlier visual and procedural-music iteration. [Overdrive](OVERDRIVE.md) records evolving weapons and continuous levels. Those reports retain their original measurements and audio versions.

**Earlier Skybound update:** [Player/developer guide](SKYBOUND.md) · [Research](SKYBOUND_RESEARCH.md) · [Independent review](../qa/skybound-review.md).

Pulsebreak has two stories: a playable native Mac game, and an experiment in building it with **GPT-6 Astra inside Codex**. These guides connect both stories to inspectable evidence.

## Choose a reading path

| You want to… | Read in this order |
|---|---|
| Play on your Mac | [Release 1.2](RELEASE_1_2.md) → [Getting started](GETTING_STARTED.md) → [Gameplay](GAMEPLAY.md) |
| See what shipped and what passed | [Release notes](RELEASE_1_2.md) → [QA index](../qa/README.md) → [Package evidence](../qa/release-1.2-package.json) |
| Understand the AI development experiment | [Experiment](EXPERIMENT.md) → [Lessons learned](LESSONS_LEARNED.md) → [Final review](../qa/review-round-3.md) |
| Modify the game | [Architecture](ARCHITECTURE.md) → [Testing](TESTING.md) → [Contributing](../CONTRIBUTING.md) |
| Build a standalone app | [Getting started](GETTING_STARTED.md) → [Mac export](MACOS_EXPORT.md) |
| Reproduce the evidence | [Testing](TESTING.md) → [QA index](../qa/README.md) → individual JSON reports |
| Inspect art and sound origins | [Assets](ASSETS.md) → [License notices](../LICENSES.md) |
| Plan a follow-up experiment | [Roadmap](ROADMAP.md) → [Experiment](EXPERIMENT.md) |

## Current guides and historical records

Release 1.2 and Prism Drive notes describe the current build; release 1.1 notes preserve the preceding version. The original [design](../DESIGN.md), [research notes](../findings.md), [implementation plan](superpowers/plans/2026-09-07-pulsebreak.md), and [progress log](../progress.md) preserve the development record. Some historical targets and early measurements were superseded. Use the release validation and QA index for the current outcome.

The implementation was first committed as `a992452`. Public documentation was added afterward without changing gameplay. Native resource-pack hashes in QA reports identify evaluated packages independently of later documentation commits.

## Evidence labels

- **Engineering checks:** deterministic assertions about rules, state, persistence, and regressions.
- **Simulation:** a driver playing the rules, often headless or at fixed speed. That mode cannot measure real rendering performance.
- **Native benchmark:** actual elapsed render-frame intervals tied to a resource pack and machine.
- **Staged capture:** a constructed screen or scene used to inspect layout and cues.
- **Observational rating:** a sub-agent's judgment with documented limits, including missing extended human feel and audio audition.

The [current independent grade is **8.4/10 as a small indie arcade demo**](../qa/release-1.2-review.md). It uses a whole-game indie-demo rubric and states its evidence limits. The original experiment's 8.2/10 rating and the later component-only scores remain historical. Test counts and automation establish technical behavior; they are separate from uncoached play and listening feedback.
