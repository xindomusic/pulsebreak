# Pulsebreak

**Steal the storm. Break the machine.** A native 3D arena roguelite for Mac, built with Godot 4.7.2 and tested on Apple Silicon.

## Play

Open **`build/Pulsebreak.app`** in Finder, or run this from the project folder:

```sh
open build/Pulsebreak.app
```

The app runs without the editor. This is an ad-hoc signed local build, not a notarized public release.

Start with **Practice the Heist** to learn movement, harvesting, and pulses, then choose **Begin the Full Run**. Survive six minutes of waves and defeat the Reactor Guardian. Automatic fire handles nearby enemies; dash through orange shots to steal energy, then spend at least 30 energy on a pulse. More charge makes a stronger blast. Ground hazards still hurt during a dash.

Choose one of three upgrades at each minute from one through five. Combat pauses for each choice, and every installation repairs **20 hull**, up to 100. Nine upgrades support different builds. Win once to unlock **Overdrive** in Settings: tougher enemies and faster waves.

## Controls

| Key | Action |
|---|---|
| WASD / arrows | Move |
| Space | Dash in your movement direction, or the last direction while stationary |
| E | Release a pulse |
| 1 / 2 / 3 | Install an offered upgrade |
| Esc | Pause/resume; back from settings; cancel remapping |
| Tab / Shift+Tab | Move menu focus |
| Enter | Activate the focused menu control |
| Left / right | Adjust a focused settings slider |
| F11 | Toggle fullscreen |

Gameplay is keyboard-only; no mouse aiming or controller support. Settings includes keyboard remapping, volume, screen shake, Assist (slower attacks), and Low Effects. Menu keys stay reserved when remapping.

Switching to another app pauses live combat. Overdrive changes take effect on the next run.

Settings, bindings, practice completion, personal best, and the victory/Overdrive state save locally in Godot's `user://settings.json`—normally `~/Library/Application Support/Godot/app_userdata/Pulsebreak/settings.json` on this Mac. Invalid or missing saves fall back to usable defaults. There is no account or cloud save.

## Run, test, and export

Run these commands from the project folder. The supplied local editor and export templates must remain in `.tools/`; the export script does not download or install anything.

```sh
# Run the editable project, or open it in the editor.
.tools/Godot.app/Contents/MacOS/Godot --path .
.tools/Godot.app/Contents/MacOS/Godot --editor --path .

# Check the local export prerequisites without rebuilding.
bash tools/export_macos.sh --check

# Rebuild build/Pulsebreak.app and verify its ad-hoc signature.
bash tools/export_macos.sh

# Run the engineering checks.
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pulsebreak-rules.log --script tests/rules_test.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pulsebreak-save.log --script tests/save_test.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pulsebreak-integration.log --script tests/integration_test.gd
```

The [final independent review](qa/review-round-3.md) scores the game **8.2/10 observationally**, after three review/fix cycles. [Verification evidence](qa/README.md) distinguishes native rendering, simulated playthroughs, staged screenshots, and direct input checks. All 131 engineering checks pass. The requested score above 9/10 was not established; extended human play, alternate-build balance, and audible mix assessment remain open. See also [save checks](qa/save-report.md), [audio checks](qa/audio-report.md), and the original [design](DESIGN.md).

Project asset origins and engine notices are in [LICENSES.md](LICENSES.md).
