# Testing and reproducing the evidence

**Current release: [Pulsebreak 1.2](RELEASE_1_2.md).** The [regression log](../qa/prism-tests.log), [audio review](../qa/prism-review.md), [game grade](../qa/release-1.2-review.md) and [distribution package report](../qa/release-1.2-package.json) describe the current version. The [packaged M4 progression run](../qa/release-native/active-metrics.json) remains 1.1 evidence.

**Current checks:** run `sh tools/test.sh` for fourteen suites (**591 checks**). Add `--qa-campaign --qa-sectors=6` to exercise a finite six-sector slice of continuous play. Record native release audio with `tools/release_audio_capture.gd`; it writes separate release evidence and verifies music-loop transport before a 36-second staged recording.

**Historical Skybound follow-up:** seven suites recorded **261 passing checks** at that revision. Use `tests/skybound_visuals.gd` for its historical staged screens; the current `tests/native_controls_check.gd` includes weapon switching and records new captures under `qa/overdrive-controls`. See [Skybound](SKYBOUND.md), [native controls evidence](../qa/skybound-controls.md), and [independent review](../qa/skybound-review.md). Counts and results in the original experiment sections below are historical.

Run commands from the repository root after the import step in [Getting started](GETTING_STARTED.md). This guide distinguishes correctness, simulated completion, visual inspection, and real rendering performance.

## Engineering suites

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . \
  --log-file /tmp/pulsebreak-rules.log --script tests/rules_test.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . \
  --log-file /tmp/pulsebreak-save.log --script tests/save_test.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . \
  --log-file /tmp/pulsebreak-integration.log --script tests/integration_test.gd
```

| Suite | Recorded checks | Coverage |
|---|---:|---|
| Combat rules | 25 | Charges/recharge, harvesting caps, pulse threshold, damage recovery, unique upgrades |
| Save store | 84 | Missing/corrupt input, clamping, bindings, atomic replacement and isolated fixtures |
| Integration | 39 | Combat, pause, progression, practice, input and restart behavior |
| Traversal | 34 | Jump, glide, fuel and landing rules |
| Altitude integration | 34 | Airborne collision, gates and attacks |
| Campaign | 31 | Relays, sectors and Guardian progression |
| Generation | 47 | Layout invariants across 768 generated layouts |
| Weapons | 50 | Projectiles, ranks, range, cover and firing cadence |
| Endless handoffs | 45 | Continuing sectors, checkpoints and Quit-button subprocess exits |
| Combat FX | 22 | Bounded hit, muzzle and destruction effects |
| Pulse FX | 53 | Pulse geometry, timing, pooling and Low Effects |
| Audio | 44 | Imported effects, voice priority, cooldown, volume and ducking |
| Release audio | 47 | Selected soundtrack, loop, smoothing, production callbacks and limiter |
| Native keyboard controls | 36 | Injected movement/menu/weapon controls; headless suite run has no native captures |
| **Total** | **591** | All passed on release 1.2 |

Each suite counts failures and exits nonzero when assertions fail. Read the Godot log as well as the shell exit status: resource import and script errors deserve investigation even when an unrelated process exits successfully. The save and integration suites redirect persistence to isolated test fixtures and clean them up; they do not replace the player's settings file.

## Complete simulated run

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . \
  --log-file /tmp/pulsebreak-active.log --fixed-fps 60 -- \
  --qa --qa-dir="$PWD/qa/local-active"
```

Godot engine flags appear before the standalone `--`; project driver flags appear after it. Use a separate output directory per candidate/policy to preserve comparisons. A report is written as `active-metrics.json`, or `passive-metrics.json` for the passive policy. The game prints `QA_RESULT` and quits after the result.

The driver uses the same dash charges, energy, collisions, health and attacks as gameplay. It circles targets, attempts harvests, responds to visible charger lanes, seeks repairs and uses pulses. It does not grant invulnerability. However, it reads game state and follows a policy that is not equivalent to human input.

| Project flag | Meaning |
|---|---|
| `--qa` | Enable the seeded driver; required for the gameplay variations below |
| `--qa-campaign` | Run the continuous Skybound sector mode |
| `--qa-sectors=6` | Bank after the requested number of sectors; minimum three |
| `--qa-alt` | Use seed 42 and a trail/field-oriented upgrade preference, instead of the normal seed 271828 |
| `--qa-passive` | Disable the driver's deliberate dash/pulse use |
| `--qa-assist` | Enable the same slower-attack Assist setting exposed in the UI |
| `--qa-overdrive` | Enable the tougher next-run mode for the driver |
| `--qa-boss` | Start at the boss transition with a preset five-upgrade build; not a full-run victory test |
| `--qa-fast` | Multiply simulation step size by four; useful for smoke coverage, not a frame benchmark |
| `--qa-dir=/absolute/path` | Set the output directory; strongly recommended, especially for packaged apps |
| `--capture-title` | Render a title capture and quit; does not need `--qa` |

For example, repeat the alternate policy without overwriting the normal report:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . \
  --log-file /tmp/pulsebreak-alternate.log --fixed-fps 60 -- \
  --qa --qa-alt --qa-dir="$PWD/qa/local-alternate"
```

QA mode skips ordinary game-progress saves and sets Assist/Overdrive from the QA flags. Other preferences such as volume, shake, and Low Effects can come from the local profile and are recorded in the report. Keep those settings consistent when comparing candidates.

## Test the packaged app

After [exporting](MACOS_EXPORT.md), use its actual executable:

```sh
build/Pulsebreak.app/Contents/MacOS/Pulsebreak --headless \
  --log-file /tmp/pulsebreak-packaged-sim.log --fixed-fps 60 -- \
  --qa --qa-dir="$PWD/qa/local-packaged-sim"
```

Release 1.1 completed a native three-sector packaged run on M4: nine relays, one Guardian, 64 hull and 97.13 game seconds. [Run context](../qa/release-native/run-context.json) records the executable, bundled PCK and normal wall-clock settings. The original Classic packaged simulation below is historical: it won at 405.6 seconds with 30 hull, 266 kills, 373 absorbed shots and 102 pulses; see its [JSON report](../qa/final-native-sim/active-metrics.json).

Different engine versions, source changes, seeds or driver changes can alter a result. Retain losses and record the candidate. The alternate normal trial lost at 283.5 seconds; an Assist variant reached the boss and lost at 369.45 seconds. Neither is omitted from the experiment.

## Actual render timing

Run the graphical app without `--headless`, `--fixed-fps`, or `--qa-fast`:

```sh
build/Pulsebreak.app/Contents/MacOS/Pulsebreak \
  --log-file /tmp/pulsebreak-native-timing.log --resolution 1920x1080 -- \
  --qa --qa-dir="$PWD/qa/local-native-timing"
```

The report records elapsed `_process` frame intervals, excludes the first three seconds, and partitions samples by minute and boss. It includes settings, engine, OS, CPU/GPU, memory, viewport, and window dimensions. Transitions that leave gameplay are excluded from consecutive gameplay sampling. This does not measure input-to-photon latency or GPU execution time directly.

The original fixed physics step of 16.67 ms was discarded as performance evidence. Headless, fixed-fps, and accelerated runs set `simulation: true` and leave real render percentiles null. Do not turn those numbers into an FPS claim.

The recorded graphical window was 1920×1080. The game's 16:10 aspect is preserved, so its image rendered at 1728×1080. The [QA index](../qa/README.md) reports the exact candidate hash, 48,258 samples, p95 10.353 ms, and the limitations of that measurement. The final full render benchmark was not repeated after the last fixes.

## Visual capture

For an actual packaged title:

```sh
build/Pulsebreak.app/Contents/MacOS/Pulsebreak \
  --log-file /tmp/pulsebreak-title.log -- \
  --capture-title --qa-dir="$PWD/qa/local-title"
```

For seven deliberately staged screens from source:

```sh
.tools/Godot.app/Contents/MacOS/Godot --path . \
  --log-file /tmp/pulsebreak-visuals.log --script tests/visual_check.gd -- \
  --qa-dir="$PWD/qa/local-visuals"
```

The harness stages title, unlocked settings, upgrades, practice completion, combat, boss, and result. It is a layout tool, not a proof that a player completed those scenes. The standalone release template was not used to execute this external script; the recorded staged images were rendered with the editor executable. Raw capture directories are ignored by Git; selected publication images live in `docs/images/`.

## Human play protocol for a follow-up

Ask a new player to complete practice without coaching, then attempt a normal run. Record where instructions fail, whether dash direction matches intent, whether each hit is explainable, whether the audio communicates danger, and how build choices change movement. Try a trail-oriented build as well as a healing/harvest build. Check keyboard remapping, pause/settings, focus loss, death, victory, and restart.

The original native CUA checks covered basic input and menus, not extended human feel or listening. New human feedback should be recorded separately from the completed three-round AI review protocol; do not retrospectively change those historical scores.
