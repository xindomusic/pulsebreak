# Pulsebreak

**Current Mac release: [Pulsebreak 1.1](docs/RELEASE_1_1.md)** — the player-selected first ElevenLabs DnB track, new combat sounds, richer navy/cobalt/coral colors and a layered reactor blast. Endless generated sectors, evolving weapons, flight, animated enemy breakup and Quit controls carry forward. Open **build/Pulsebreak.app**, then choose **Begin Skybound**. **F** jumps/holds to glide; **Q** switches unlocked weapons; **Esc** opens pause and Quit. The game runs offline without an API key.

![Staged native Resonance title and courier](docs/images/resonance-title.png)

*[Release notes](docs/RELEASE_1_1.md), [hear the selected DnB track](docs/audio/elevenlabs/reactor_rush.mp3), and [release review](qa/release-review.md). [Resonance](docs/RESONANCE.md), [Overdrive](docs/OVERDRIVE.md), [Skybound](docs/SKYBOUND.md), and the original experiment below remain historical.*

### A game-making experiment with GPT-6 Astra inside Codex

**Steal the storm. Break the machine.** Pulsebreak is a playable 3D arena roguelite for Apple Silicon Macs, built with Godot 4.7.2.

This repository documents an experiment by [xindomusic](https://github.com/xindomusic): take a game idea through research, design discussion, implementation, native packaging, and three sub-agent review/fix cycles using **GPT-6 Astra inside Codex**. The code, original procedural art and synthesized audio, tests, and review evidence are here so the result can be inspected and reproduced.

![Pulsebreak's native Mac title screen](docs/images/title.png)

*Actual title render from the packaged Mac app. Other illustrated scenes in the guides are explicitly staged source captures.*

**[Read the experiment](docs/EXPERIMENT.md)** · **[Play from source](docs/GETTING_STARTED.md)** · **[Browse the documentation](docs/README.md)** · **[Read the final review](qa/review-round-3.md)**

## What happened?

| Question | Recorded result |
|---|---|
| Could the workflow produce a complete local game? | Native Mac app with waves, upgrades, a boss, practice, settings, saves, and original audiovisual assets |
| Did the final packaged game complete a run? | Yes, an automated normal-difficulty run won at 405.6 seconds |
| Did the engineering checks pass? | 131 checks: 25 combat, 68 save, 38 integration |
| Did three reviews establish a score above 9/10? | **No. The final observational score was 8.2/10** |
| What is still uncertain? | Extended human control feel, perceived audio quality, and alternate-build balance |

This is a documented project experiment, not a controlled model benchmark or a claim of commercial game quality. GPT-6 Astra was used during development; **the game does not call an AI model at runtime**. Playing or building it requires no OpenAI account or API key.

## The game

Survive six minutes on the Skyforge deck, then defeat the Reactor Guardian. Your weapon fires automatically at nearby machines. The important decisions are movement, harvesting, and when to release a pulse:

1. **Dash through orange shots** to absorb them and steal energy.
2. **Spend at least 30 energy on a pulse.** More stored energy means a larger, stronger blast.
3. **Choose upgrades** at minutes one through five. Each installation repairs 20 hull.
4. **Read enemy warnings.** Charged lanes and ground hazards demand different evasive moves.

There are nine upgrades, three regular enemy roles, optional repair cores, and a two-phase boss. A victory unlocks Overdrive for tougher subsequent runs. Start with **Practice the Heist** to learn the core move.

![Staged combat scene showing a charger warning and orange projectiles](docs/images/combat.png)

*Staged scene used to inspect combat readability, not a recorded human playthrough.*

## Run it on a Mac

The repository contains source and assets. The editor, export templates, and `build/Pulsebreak.app` are deliberately excluded from Git; a fresh clone does not contain a prebuilt application.

1. Install the standard **Godot 4.7.2** editor from the [official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
2. Clone this repository and import `project.godot` in Godot.
3. Press **F6** with `main.tscn` open, or **F5** to run the project.

```sh
git clone https://github.com/xindomusic/pulsebreak.git
cd pulsebreak
```

The [getting-started guide](docs/GETTING_STARTED.md) provides exact command-line setup and troubleshooting. The [Mac export guide](docs/MACOS_EXPORT.md) explains how to create a standalone `.app`. Existing local builds can be opened with `open build/Pulsebreak.app`.

| Control | Action |
|---|---|
| WASD / arrow keys | Move |
| Space | Dash in the current movement direction, or last direction while stationary |
| E | Release a pulse |
| 1 / 2 / 3 | Select an upgrade |
| Esc | Pause / resume / back |
| F11 | Toggle fullscreen |

Gameplay uses a keyboard; menus also accept mouse clicks. Settings include remapping, Assist, Low Effects, volume, and screen shake. Changing to another app pauses live combat. See the [full player guide](docs/GAMEPLAY.md).

## How the experiment worked

The user set the platform, requested research before implementation, approved the design, and asked for independent sub-agent ratings with a maximum of three improvement cycles. Codex coordinated implementation and tools; bounded sub-agent tasks covered art, audio, saves, and independent review.

| Review/fix cycle | Initial score | Post-fix observational score | Examples of improvements |
|---|---:|---:|---|
| [1](qa/review-round-1.md) | 7.15 | 7.385 | Practice completion, charger warning, remapped prompts, HUD geometry |
| [2](qa/review-round-2.md) | 7.73 | 8.05 | Immediate-direction dash, wall-stopped charges, a pulse lesson requiring a hit |
| [3](qa/review-round-3.md) | 8.15 | 8.2 | Slow effects on lunges, next-run Overdrive labeling, focus-loss pause |

The original above-9 target was not reached. Read the [experiment protocol](docs/EXPERIMENT.md), [lessons learned](docs/LESSONS_LEARNED.md), and [evidence index](qa/README.md) for the distinction between tests, bots, screenshots, native input checks, and human fun.

## Documentation

| Guide | What it covers |
|---|---|
| [Documentation index](docs/README.md) | Reading paths for players, developers, and experiment readers |
| [Experiment](docs/EXPERIMENT.md) | GPT-6 Astra inside Codex, user involvement, delegation, review cap, evidence limits |
| [Getting started](docs/GETTING_STARTED.md) | Fresh clone, editor setup, running, local saves, troubleshooting |
| [Gameplay](docs/GAMEPLAY.md) | Controls, combat rules, enemies, all nine upgrades, practice, difficulty |
| [Architecture](docs/ARCHITECTURE.md) | Scene ownership, state transitions, collision, persistence, extension points |
| [Testing and reproduction](docs/TESTING.md) | All suites, driver flags, visual captures, performance methodology |
| [Mac export](docs/MACOS_EXPORT.md) | Matching templates, local app creation, signing, distribution limits |
| [Assets](docs/ASSETS.md) | Procedural meshes, audio synthesis, UI, screenshot provenance |
| [Lessons learned](docs/LESSONS_LEARNED.md) | Concrete defects, fixes, and the limits of the measurements |
| [Roadmap](docs/ROADMAP.md) | Remaining work and evidence needed to call it an improvement |
| [Contributing](CONTRIBUTING.md) | Reporting bugs, proposing changes, validation expectations |
| [Changelog](CHANGELOG.md) | Initial experiment and public documentation release |

## Project facts and provenance

The implementation is GDScript with Godot's Mobile renderer and Metal on the tested Mac. Start with [game.gd](scripts/game.gd), [rules.gd](scripts/rules.gd), and [the architecture guide](docs/ARCHITECTURE.md).

The recorded native benchmark used an **Apple M1 Max with 32 GB RAM**. A round-two candidate's p95 render interval was **10.353 ms** in a 1920×1080 window with 1728×1080 aspect-preserving gameplay rendering. That candidate predates the final fixes; the [performance report](qa/README.md) identifies the exact build and limits. This is not a performance guarantee for every Mac.

The original game code and assets were created for this experiment with Codex assistance. See [LICENSES.md](LICENSES.md) for provenance and Godot notices. Public source visibility does not by itself assign an open-source license to the original game content; no additional license grant has been selected.

Official product references: [GPT-6 Astra](https://developers.openai.com/api/docs/models/gpt-6-astra), [Codex documentation](https://developers.openai.com/codex/), and [Godot](https://godotengine.org/). This is xindomusic's experiment, not an official OpenAI or Godot project.
