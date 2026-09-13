# Getting started on a Mac

**Current release: [Pulsebreak 1.2.0](RELEASE_1_2.md).** Choose **Begin Skybound** for continuous generated levels, evolving weapons, jump/glide and moving gates. Prism Drive and all game effects are bundled for offline play.

## Play the download

1. Download **Pulsebreak-1.2.0-macOS-universal.zip** from the [GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.2.0).
2. Unzip it and move **Pulsebreak.app** to Applications.
3. Open the app and choose **Begin Skybound** or **Practice the Heist**.

The app is ad-hoc signed, without Apple notarization. If macOS blocks a trusted download from this repository, follow [Apple's instructions for opening an app from an unknown developer](https://support.apple.com/en-ca/guide/mac-help/mh40616/mac), including the per-app option in System Settings → Privacy & Security. The release also supplies **Pulsebreak-1.2.0-SHA256SUMS.txt**; with both files in the same folder, verify the ZIP using `shasum -a 256 -c Pulsebreak-1.2.0-SHA256SUMS.txt`.

The editor and Git instructions below are for working from source. The downloadable app requires neither.


## Requirements

- A Mac capable of running the standard Godot 4.7.2 editor. Release 1.1 was tested on Mac mini M4 / 16 GB / macOS 26.6.2. Earlier M1 Max / 32 GB results are historical; Intel execution and other configurations have not been certified by this project.
- Keyboard input for gameplay. Mouse input is supported in menus, but aiming is automatic and controller support is not implemented.
- Git is needed only to clone the source. Python 3 is optional and only needed to regenerate audio.

There is no runtime service, package registry, account, API key or model download. The checked-in WAV and Ogg files are ready to use. Python/audio tools and an ElevenLabs credential are unnecessary for playing or exporting the checked-in game.

## Option A: use the Godot project manager

1. Download the standard macOS editor from the [Godot 4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable). Use the universal macOS build, not the .NET edition.
2. Clone the project:

   ```sh
   git clone https://github.com/xindomusic/pulsebreak.git
   cd pulsebreak
   ```

3. Open Godot, choose **Import**, and select `project.godot` in the checkout.
4. Allow the first asset import to finish. Press **F5** to run the project.
5. Choose **Begin Skybound** for the continuous game, or **Practice the Heist** to learn dash harvesting and pulse attacks first.

Godot writes its generated import cache to `.godot/`, which Git ignores. Importing and running do not require export templates.

## Option B: reproduce the local editor layout

The project's command examples and export script use an editor inside `.tools/`. From the repository root:

```sh
mkdir -p .tools
curl -fL --retry 3 \
  https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_macos.universal.zip \
  -o .tools/godot-macos.zip
unzip -q .tools/godot-macos.zip -d .tools
.tools/Godot.app/Contents/MacOS/Godot --version
```

The version should begin with `4.7.2.stable`. These pinned official download links were checked during publication; the binaries are not committed to this repository.

Import once, then launch:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import \
  --log-file /tmp/pulsebreak-import.log
.tools/Godot.app/Contents/MacOS/Godot --path .
```

To edit rather than only run:

```sh
.tools/Godot.app/Contents/MacOS/Godot --editor --path .
```

If macOS asks to confirm opening the downloaded editor, use the normal macOS application-opening process. The project does not require disabling system protections.

## First run

Practice teaches movement, harvesting an orange projectile during a dash, and hitting a machine with a pulse. Missing a pulse does not advance the lesson. Practice keeps hull from falling below 35 and ends with a separate completion screen; **Begin the Full Run** starts a fresh normal run.

In Skybound, move with WASD/arrows, dash with Space, pulse with E, and jump/hold to glide with F. Q switches unlocked weapons. At checkpoints, continue to the next sector or bank your score. Esc opens pause and Quit Game; switching away from the game also pauses. See [Gameplay](GAMEPLAY.md) for the modes and [Mac export](MACOS_EXPORT.md) to build an app that runs without the editor.

## Local settings and progress

The game stores preferences and progression in `user://settings.json`, normally:

```text
~/Library/Application Support/Godot/app_userdata/Pulsebreak/settings.json
```

It stores volume, shake, Assist, Low Effects, keyboard bindings, practice completion, personal best, victory unlock, and the Overdrive preference. It does not save a run in progress. Settings changes save automatically; invalid or missing data falls back to usable defaults.

To test a fresh profile, close the game and move the settings file to a backup location using Finder. Restore that backup when finished. Automated QA mode skips game-progress writes; the save and integration suites use isolated fixtures.

## Troubleshooting

| Symptom | Check |
|---|---|
| `.tools/.../Godot` is missing | A fresh clone excludes the editor. Follow Option A or Option B above. |
| Audio/resource import errors on the first headless run | Complete the editor import step before running the test scripts. |
| Export fails looking for templates | Install the matching templates using [Mac export](MACOS_EXPORT.md). They are not required to play in the editor. |
| A gameplay key appears not to work | Check Settings → Keyboard and the current HUD labels; menu keys are reserved. |
| The game pauses when changing apps | Intended behavior. Return to the window and resume. |
| The game runs slowly on a different Mac | Try Low Effects and lower screen shake; record hardware, window size, and settings before comparing against the published benchmark. |
| A downloaded standalone build is blocked by macOS | The experiment's local app is ad-hoc signed, not a notarized public release. Building locally through Godot is the documented path. |

For a reproducible bug, follow the report format in [Contributing](../CONTRIBUTING.md).
