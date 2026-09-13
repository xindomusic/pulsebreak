# Building a standalone Mac app

The **1.2.0 release** exports a universal `.app` containing arm64 and x86_64 code, a versioned ZIP and checksums. Release 1.1 was tested on Mac mini M4 / 16 GB; those performance measurements describe that build. Intel hardware was not tested. Use **Godot 4.7.2 and matching 4.7.2 templates** to reproduce the recorded environment. See [Prism Drive notes](PRISM_DRIVE.md) and [package evidence](../qa/release-1.2-package.json).

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

The script checks editor/template versions and archive integrity, refreshes asset imports, exports the `macOS` preset, copies `LICENSES.md` into Resources, applies a local ad-hoc signature, and verifies it with `codesign --verify --deep --strict`. It checks both architectures, creates **build/Pulsebreak-1.2.0-macOS-universal.zip**, verifies the ZIP and writes **build/SHA256SUMS.txt** for the archive and PCK.

The built app runs without Godot installed elsewhere or any API key. Re-exporting replaces the local build; commit source changes rather than the generated bundle. Exact 1.2.0 sizes and checksums are in the [package report](../qa/release-1.2-package.json). The previous 1.1.0 archive is preserved separately, with its [original evidence](../qa/release-package.json). Most uncompressed app size is the universal engine binary.

## Configuration map

| Setting | Location / value |
|---|---|
| Export preset | `macOS` in [export_presets.cfg](../export_presets.cfg) |
| Output | `build/Pulsebreak.app` |
| Bundle identifier | `games.pulsebreak.local` |
| Current game version | `1.2.0` |
| Archive / checksums | `build/Pulsebreak-1.2.0-macOS-universal.zip` / `build/SHA256SUMS.txt` |
| Templates | Local `.tools/export/templates/macos.zip` for both debug/release |
| Renderer | Mobile, Metal on the tested Mac |
| Texture compression | S3TC/BPTC and ETC2/ASTC enabled for the universal export |
| Signing | Local ad-hoc signature; no notarization |
| Exclusions | Tool downloads, builds, tests, QA, docs, Git metadata and superseded root-level audio |

## Verify a package

```sh
file build/Pulsebreak.app/Contents/MacOS/Pulsebreak
codesign --verify --deep --strict --verbose=2 build/Pulsebreak.app
shasum -a 256 build/Pulsebreak.app/Contents/Resources/Pulsebreak.pck
```

Architecture inspection proves the binary contains arm64; it is not a performance test. Signature verification proves bundle integrity under its local signature; it is not Apple notarization. Resource-pack hashes identify a particular exported game. Documentation-only commits do not necessarily require a new game export.

For a packaged headless playthrough and a graphical timing run, use the commands in [Testing](TESTING.md). A window opening successfully is only a launch check, not a complete gameplay test.

## Public distribution

The [v1.2.0 GitHub release](https://github.com/xindomusic/pulsebreak/releases/tag/v1.2.0) distributes the universal Mac ZIP, SHA-256 checksum file and release notes. The annotated tag identifies the source revision. The app is ad-hoc signed, without Apple notarization; see [first-launch guidance](GETTING_STARTED.md#play-the-download).

Developer ID signing and notarization require the publisher's Apple credentials and are not configured for this build. Preserve engine and asset notices when redistributing the package. The [final package report](../qa/release-1.2-package.json) records the distributed archive; earlier package reports identify earlier local artifacts.
