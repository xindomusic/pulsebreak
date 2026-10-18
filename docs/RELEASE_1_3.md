# Pulsebreak 1.3.0 — Reforge

**[Download for Mac](https://github.com/xindomusic/pulsebreak/releases/download/v1.3.0/Pulsebreak-1.3.0-macOS-universal.zip)** · [GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.3.0) · [Source tag](https://github.com/xindomusic/pulsebreak/tree/v1.3.0) · [Changelog](../CHANGELOG.md)

Pulsebreak is a native arena roguelite: dash through enemy fire to charge a reactor blast, jump and glide through moving gates, install upgrades and keep fighting through generated sectors. Version 1.3 is the **Reforge** redesign: a lifelike PBR/lighting pass, a single color-token system, much juicier combat feedback, and progression built for hours — upgrade marks, resonances, elite machines, salvage cores and a permanent Hangar.

## Play

Download and unzip **Pulsebreak-1.3.0-macOS-universal.zip**, move **Pulsebreak.app** to Applications, and choose **Begin Skybound**. The app contains Apple Silicon and Intel binaries and runs offline without Godot, an account or an API key. Keyboard controls: WASD/arrows move, Space dashes, E pulses, F jumps/holds to glide, Q switches weapons and Esc opens pause and Quit. Salvage cores earned on every run are spent in the **Hangar** on the title screen.

The app is ad-hoc signed and has not been Apple-notarized. See the [first-launch guide](GETTING_STARTED.md#play-the-download) for Apple's per-app opening instructions. Verification was performed on Apple M5 Max; Intel execution and clean installation on another Mac remain untested.

## What's new in 1.3

- **Lifelike pass:** per-surface PBR (clearcoat ceramic, titanium, copper, rubber), procedural roughness grain, sky ambient/reflections, ACES tonemapping with bloom, three-point lighting, contact shadows and pulsing reactor cores.
- **One color system:** `scripts/palette.gd` tokens shared by HUD, weapons and FX — mint player, amber harvest economy, coral threats. Sector three is now Tempest Core.
- **Combat feel:** hitstop, knockback, per-hit sparks, dash ghosts, floating damage numbers, a combo counter with score multiplier, camera punch, landing dust, and telegraphs that never lie (chargers commit; shooters lock aim halfway through their windup).
- **Deep progression:** nine reactor upgrades × three marks with scaled tradeoffs and family resonances; the Splitter enemy and its mites; elite affixes in deep sectors; salvage cores and the Hangar (six permanent perks × three ranks, plus repeatable Overcharge prestige cells).

[Reforge design record](REFORGE.md) · [Player guide](GAMEPLAY.md) · [Asset notices](../LICENSES.md).

## Grade and verification

**Final independent weighted grade: 7.4/10** (Model 7.0, UI color 8.0, Combat 7.5, Readability 7.0, Upgrade depth 8.0, Longevity 7.0) after five agent review rounds — up from this redesign's own 5.5 round-one average. The reviewers are explicit that 9/10 was not reached: procedural models still read as polished toys at the gameplay camera, and meta-progression completes in roughly two hours of wins. Read every round in the [review record](../qa/reforge-review.md).

- **632 checks in fifteen regression suites passed**, including the new 31-check Reforge suite and 768 generated layouts.
- The **exported app itself** completed a simulated Classic run (win, 284 kills) with zero script errors; a simulated Skybound run cleared four sectors from source.
- Universal architectures, ad-hoc signature (`codesign --verify --deep --strict`) and ZIP integrity verified by `tools/export_macos.sh`.
- Human hands-on fun, extended balance and Intel execution remain unverified; the QA driver is a policy bot, not a player.

[Package report](../qa/release-1.3-package.json) · [Testing guide](TESTING.md).

## Release files and tags

The [GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.3.0) includes the universal Mac ZIP and **Pulsebreak-1.3.0-SHA256SUMS.txt**. With both files in the same folder:

```sh
shasum -a 256 -c Pulsebreak-1.3.0-SHA256SUMS.txt
```

The annotated tag **v1.3.0** identifies the source revision. **v1.2.0** remains the preceding verified release.
