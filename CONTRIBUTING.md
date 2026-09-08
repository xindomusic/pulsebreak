# Contributing and reporting issues

Pulsebreak is an experiment in making a complete local game with GPT-6 Astra inside Codex. Contributions and feedback should help explain a player problem or strengthen the evidence, rather than merely increasing the amount of code.

The repository is public, but no additional open-source license has been selected for the original game content. Review [LICENSES.md](LICENSES.md) before proposing redistribution or reuse. Bug reports and discussion can proceed without changing that licensing decision.

## Report a bug

Open an issue on [xindomusic/pulsebreak](https://github.com/xindomusic/pulsebreak/issues) with:

1. What you expected and what happened.
2. Steps from the title screen, including practice/normal/Overdrive, upgrade choices and remapped keys.
3. Commit or package hash, Godot version, Mac chip, RAM, macOS, and window size.
4. Whether Assist or Low Effects was enabled.
5. A relevant screenshot, short reproduction, or the relevant lines from a local log.

Do not post credentials or unrelated personal files in an issue. A log excerpt is often more useful than a whole environment dump.

## Propose a change

For gameplay changes, explain the player behavior you want to improve and the tradeoff. For balance claims, record multiple runs and keep losses. For a bug fix, reproduce the issue before changing it when feasible. Keep changes focused enough to review independently.

Use the module map in [Architecture](docs/ARCHITECTURE.md). Keep resource limits explicit, preserve pause/restart behavior, and make labels describe the actual behavior. New settings should have defaults, validation, live application rules, and usable saved bindings.

## Validation expectations

- Run the suites relevant to the change using [Testing](docs/TESTING.md). Gameplay/state/save changes generally warrant all three suites.
- Inspect affected native screens for UI changes. Listen to audio changes; numerical checks alone do not establish mix quality.
- Include the command, result, candidate and conditions for simulations or performance claims.
- Documentation-only changes should have working relative links, accurate commands, and correct evidence labels; they do not need new implementation-mirroring tests.
- Keep `.tools/`, `.godot/`, generated apps, private local logs, and raw capture output out of commits. Selected intentional documentation images belong in `docs/images/`.

## Preserve the experiment record

The original design, review findings and JSON reports are historical evidence. Add a new report or a clearly dated addendum for new results; do not rewrite a loss into a win or relabel an old benchmark as current. Disclose AI assistance in a contribution description when it materially explains how the change was produced or reviewed. The original three-round score is not a target to inflate.
