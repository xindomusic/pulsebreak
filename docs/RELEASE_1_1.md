# Pulsebreak 1.1 for Mac

Open **build/Pulsebreak.app** and choose **Begin Skybound**. The standalone app includes the selected first ElevenLabs soundtrack and combat audio; it needs no editor, network connection or API key. The archive is **build/Pulsebreak-1.1.0-macOS-universal.zip**.

Move with **WASD/arrows**, dash with **Space**, pulse with **E**, and jump/hold to glide with **F**. **Q** switches unlocked weapons. **Esc** opens the pause menu, including **Quit Game**. At sector checkpoints, continue the run or bank the score. New seeded sectors continue after each Guardian.

## Selected audio

The player chose the first **Reactor Rush** audition after comparing both versions. Release 1.1 plays its full 44.199-second arrangement as a looping Vorbis stream. Music gain responds smoothly to threats, and important events briefly duck the music. The selected arrangement is preserved; no measured-tempo or beat-perfect-loop claim is made.

Kinetic fire, plasma fire, armor impact, robot destruction and the reactor pulse use the accepted prepared effects exactly. Scatter, arc, Guardian destruction and weapon installation use documented local edits of those effects. No additional paid generation was needed for release integration. The [asset manifest](../qa/release-audio.json) records source/output hashes and processing. The [audio review](../qa/release-review.md) verifies the integration independently.

The game retains the existing four weapons and five ranks, animated hit/death effects, flight and moving gates, three environment styles, endless generated sectors, checkpoints and Quit controls. Earlier feature and performance evidence remains in [Resonance](RESONANCE.md) and [Overdrive](OVERDRIVE.md).

## Validation and package

All fourteen regression suites passed **591 checks**, including 768 generated layouts, weapon/flight behavior, saves, actual Quit-button subprocess exits and 91 focused audio checks. The [validation inventory](../qa/release-validation.json) identifies this run. A separate 36.01-second native CoreAudio capture verifies the production mix after the limiter: peak 0.891235, zero near-full-scale samples, four staged weapon installations and two full-charge pulses. A native transport check verifies that the accepted track wraps and continues playing. These are automated checks, not a new human enjoyment rating.

The package contains universal **arm64 and x86_64** executables, version **1.1.0**. Original and ZIP-extracted apps pass strict signature verification; their resource packs and notices match. All 78 resource-pack members pass integrity checks. The pack includes the selected music, nine release effects and ten retained interface cues, and excludes auditions, development files and superseded music. The [package report](../qa/release-package.json) and **build/SHA256SUMS.txt** identify the exact archive and resource pack.

The exported app also completed a native automated three-sector run on **Mac mini M4 / 16 GB**, at 1280×800 with Full Effects: nine airborne relays, one Guardian defeated, and 64 hull remaining at 97.13 game seconds. Across 5,622 active render intervals, median was **16.654 ms**, p95 **18.459 ms**, and p99 **18.992 ms**. This run used the bundled resource pack from outside the source directory, normal wall-clock simulation and CoreAudio. It is a packaged-game progression/render check, not a human playthrough. See [native results](../qa/release-native/active-metrics.json) and [run context](../qa/release-native/run-context.json).

This is a local ad-hoc signed Mac build; it is not Apple notarized. The accepted first soundtrack is bundled for offline playback, and the private generation key remains outside the project and package.

## Rebuild

With the local Godot 4.7.2 editor and matching macOS export template installed, run:

```sh
sh tools/test.sh
bash tools/export_macos.sh
open build/Pulsebreak.app
```

The export workflow refreshes imports, builds the app, adds asset/engine notices, signs, verifies and creates the versioned ZIP and checksums. See [Mac export setup](MACOS_EXPORT.md) for installing the editor/template on another development machine. Prepared release assets are checked into the source; rebuilding the game does not call ElevenLabs.
