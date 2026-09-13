# Pulsebreak 1.2.0 — Prism Drive

**[Download for Mac](https://github.com/xindomusic/pulsebreak/releases/download/v1.2.0/Pulsebreak-1.2.0-macOS-universal.zip)** · [GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.2.0) · [Source tag](https://github.com/xindomusic/pulsebreak/tree/v1.2.0) · [Changelog](../CHANGELOG.md)

Pulsebreak is a native arena roguelite: dash through enemy fire to charge a reactor blast, jump and glide through moving gates, install weapon upgrades and keep fighting through generated sectors. Version 1.2 adds **Prism Drive**, an original 102-second half-time dubstep soundtrack with combat-driven volume and blast ducking.

## Play

Download and unzip **Pulsebreak-1.2.0-macOS-universal.zip**, move **Pulsebreak.app** to Applications, and choose **Begin Skybound**. The app contains Apple Silicon and Intel binaries and runs offline without Godot, an account or an API key. Keyboard controls: WASD/arrows move, Space dashes, E pulses, F jumps/holds to glide, Q switches weapons and Esc opens pause and Quit.

The app is ad-hoc signed and has not been Apple-notarized. See the [first-launch guide](GETTING_STARTED.md#play-the-download) for Apple's per-app opening instructions. Native verification was performed on Mac mini M4 / 16 GB; Intel execution and clean installation on another Mac remain untested.

## What's included

- Original Prism Drive music generated with ElevenLabs, prepared for offline looping playback.
- Nine combat cues covering weapon fire, impacts, machine destruction, upgrades and reactor blasts, plus interface feedback.
- Continuous seeded sectors across three environment styles, airborne relays, moving gates and recurring Guardians.
- Four weapon families with five ranks, jump/glide traversal, animated hit/destruction feedback and layered pulses.
- Practice, remapping, Assist, Low Effects, volume/shake settings and working Quit/bank controls.

Gameplay and visual code retain the 1.1 behavior. The current update changes the background track; the full release includes the earlier game improvements. [Music previews and provenance](PRISM_DRIVE.md) · [Asset notices](../LICENSES.md).

## Grade and verification

**Independent observational grade: 8.4/10 as a small indie arcade demo.** The weighted review finds strong combat/traversal, presentation and reliability, with repeated encounters and missing uncoached play/listening evidence limiting the score. It does not establish AAA showcase readiness. Read the [complete review](../qa/release-1.2-review.md) for the rubric and limits.

- **591 checks in fourteen regression suites passed**, including 91 audio checks and a generation suite sampling 768 layouts. Nine offline generator safety tests passed separately.
- A 36-second native CoreAudio capture and live loop transport check passed; prepared audio decodes without clipping.
- The exported resource pack loads the 102.426-second track and all 21 cue names, starts a campaign and excludes the previous background track.
- The standalone app passed a bounded startup check. Universal architectures, original/extracted signatures, ZIP integrity and all 78 resource-pack members were verified.
- The final release package updates bundled notices and signing; its runtime resource pack is byte-identical to the tested feature build.

[Regression log](../qa/prism-tests.log) · [Audio review](../qa/prism-review.md) · [Final package report](../qa/release-1.2-package.json).

The previous 1.1 package completed three sectors, nine relays and one Guardian on M4 at 1280×800 with Full Effects. Its active render intervals were median 16.654 ms, p95 18.459 ms and p99 18.992 ms. Those remain **1.1 measurements**, not a new 1.2 benchmark. Current soundtrack taste, extended replay value and a full native 1.2 progression run remain unverified.

## Release files and tags

The [GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.2.0) includes the universal Mac ZIP, **Pulsebreak-1.2.0-SHA256SUMS.txt** and downloadable release notes. With the ZIP and checksum file in the same folder:

```sh
shasum -a 256 -c Pulsebreak-1.2.0-SHA256SUMS.txt
```

ZIP size: **61,929,764 bytes**. SHA-256:

```text
d8f7fefb874d4fa226cc60ccdf10b0e291ccd63b0ef48e37047175d98198c18c
```

The annotated **v1.2.0** tag identifies the release source on `main`. **v1.1.0** tags the preceding verified release revision, `251313f`; its notes and local package evidence remain historical. Future release changes receive a new version rather than moving a published tag. See the [build guide](MACOS_EXPORT.md) to reproduce an app from the checked-in source and assets.
