# Building a standalone Mac app

The project exports a universal `.app` containing arm64 and x86_64 code. Apple Silicon was tested; Intel hardware was not. Use **Godot 4.7.2 and matching 4.7.2 templates** to reproduce the recorded environment.

## Install the local prerequisites

Follow [Getting started](GETTING_STARTED.md) to place the editor at `.tools/Godot.app` and import the project. Then download the matching official template archive. It contains templates for multiple platforms and is a large download; only the Mac template and version file are extracted below.

```sh
mkdir -p .tools/export/templates
curl -fL --retry 3 \
  https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz \
  -o .tools/export_templates.tpz
unzip -j .tools/export_templates.tpz \
  templates/macos.zip templates/version.txt \
  -d .tools/export/templates
```

The required layout is:

```text
.tools/
  Godot.app/Contents/MacOS/Godot
  export/templates/
    macos.zip
    version.txt
```

These files are ignored by Git. The export script reads them locally and does not install or download dependencies.

## Check and export

Run from the repository root on macOS:

```sh
bash tools/export_macos.sh --check
bash tools/export_macos.sh
open build/Pulsebreak.app
```

The script checks the editor and template versions, checks the template archive, exports the `macOS` preset, copies `LICENSES.md` into the app's Resources directory, applies a local ad-hoc signature, and verifies it with `codesign --verify --deep --strict`.

The built app runs without Godot installed elsewhere. Re-exporting replaces the local build; commit source changes rather than the generated bundle. The initial `.app` is about 164 MB, mostly the universal engine binary.

## Configuration map

| Setting | Location / value |
|---|---|
| Export preset | `macOS` in [export_presets.cfg](../export_presets.cfg) |
| Output | `build/Pulsebreak.app` |
| Bundle identifier | `games.pulsebreak.local` |
| Game version in initial experiment | `1.0.0` |
| Templates | Local `.tools/export/templates/macos.zip` for both debug/release |
| Renderer | Mobile, Metal on the tested Mac |
| Texture compression | S3TC/BPTC and ETC2/ASTC enabled for the universal export |
| Signing | Local ad-hoc signature; no notarization |
| Exclusions | Tool downloads, generated builds, tests, QA artifacts, documentation, Git metadata |

## Verify a package

```sh
file build/Pulsebreak.app/Contents/MacOS/Pulsebreak
codesign --verify --deep --strict --verbose=2 build/Pulsebreak.app
shasum -a 256 build/Pulsebreak.app/Contents/Resources/Pulsebreak.pck
```

Architecture inspection proves the binary contains arm64; it is not a performance test. Signature verification proves bundle integrity under its local signature; it is not Apple notarization. Resource-pack hashes identify a particular exported game. Documentation-only commits do not necessarily require a new game export.

For a packaged headless playthrough and a graphical timing run, use the commands in [Testing](TESTING.md). A window opening successfully is only a launch check, not a complete gameplay test.

## Public distribution

This repository publishes source, assets, documentation, and selected screenshots. It does not publish a notarized installer or downloadable release of the original local app. Cloning the repository and building locally is the supported reproduction path.

If a future maintainer distributes a downloadable Mac app, follow the current official [Godot macOS export guidance](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html) for Developer ID signing and notarization. Those credentials and service steps are not part of this experiment. Preserve engine and asset notices in any package you are authorized to distribute.
