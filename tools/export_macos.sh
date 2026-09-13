#!/bin/bash
set -euo pipefail

fail() {
  printf 'Export error: %s\n' "$*" >&2
  exit 1
}

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--check" ) ]]; then
  printf 'Usage: bash tools/export_macos.sh [--check]\n' >&2
  exit 2
fi

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EDITOR="$PROJECT_DIR/.tools/Godot.app/Contents/MacOS/Godot"
TEMPLATES="$PROJECT_DIR/.tools/export/templates"
APP="$PROJECT_DIR/build/Pulsebreak.app"
BUILD_DIR="$PROJECT_DIR/build"

[[ "$(uname -s)" == "Darwin" ]] || fail "macOS is required for this export."
[[ -x "$EDITOR" ]] || fail "Missing local editor: $EDITOR"
[[ -f "$PROJECT_DIR/project.godot" ]] || fail "Missing project.godot."
[[ -f "$PROJECT_DIR/export_presets.cfg" ]] || fail "Missing export_presets.cfg."
[[ -f "$PROJECT_DIR/LICENSES.md" ]] || fail "Missing LICENSES.md."
[[ -f "$TEMPLATES/version.txt" && -s "$TEMPLATES/macos.zip" ]] || fail "Missing local macOS export templates."
for command in codesign unzip ditto shasum lipo; do
  command -v "$command" >/dev/null || fail "Missing packaging tool: $command"
done

EDITOR_VERSION="$("$EDITOR" --version)"
[[ "$EDITOR_VERSION" == 4.7.2.stable.* ]] || fail "Expected Godot 4.7.2 stable; found $EDITOR_VERSION."
TEMPLATE_VERSION="$(cat "$TEMPLATES/version.txt")"
[[ "$TEMPLATE_VERSION" == "4.7.2.stable" ]] || fail "Expected 4.7.2.stable templates; found $TEMPLATE_VERSION."
/usr/bin/unzip -tq "$TEMPLATES/macos.zip" >/dev/null || fail "The local macOS template archive is damaged."

printf 'Ready: Godot %s and matching macOS templates.\n' "$EDITOR_VERSION"
if [[ "${1:-}" == "--check" ]]; then
  exit 0
fi

mkdir -p "$PROJECT_DIR/build"
# Refresh imported assets before exporting; stale editor imports must not ship.
"$EDITOR" --headless --path "$PROJECT_DIR" --editor --import \
  --log-file "$BUILD_DIR/import.log"
"$EDITOR" --headless --path "$PROJECT_DIR" --log-file "$BUILD_DIR/export.log" \
  --export-release macOS "$APP"
[[ -x "$APP/Contents/MacOS/Pulsebreak" ]] || fail "Export did not produce the game executable."
[[ -s "$APP/Contents/Resources/Pulsebreak.pck" ]] || fail "Export did not produce the game resource pack."

# Add the engine notice before the final local ad-hoc signature.
cp "$PROJECT_DIR/LICENSES.md" "$APP/Contents/Resources/LICENSES.md"
/usr/bin/codesign --force --deep --sign - "$APP"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"

ARCHITECTURES="$(/usr/bin/lipo -archs "$APP/Contents/MacOS/Pulsebreak")"
[[ " $ARCHITECTURES " == *" arm64 "* && " $ARCHITECTURES " == *" x86_64 "* ]] || fail "Expected a universal Mac binary; found $ARCHITECTURES."
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
[[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid release version: $APP_VERSION"
PACKAGE_NAME="Pulsebreak-$APP_VERSION-macOS-universal.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$BUILD_DIR/$PACKAGE_NAME"
/usr/bin/unzip -tq "$BUILD_DIR/$PACKAGE_NAME" >/dev/null || fail "The release ZIP is damaged."
(
  cd "$BUILD_DIR"
  /usr/bin/shasum -a 256 "$PACKAGE_NAME" "Pulsebreak.app/Contents/Resources/Pulsebreak.pck" > SHA256SUMS.txt
)
printf 'Exported %s (%s), ad-hoc signature verified:\n%s\nPackaged:\n%s\n' \
  "$APP_VERSION" "$ARCHITECTURES" "$APP" "$BUILD_DIR/$PACKAGE_NAME"
printf 'Local build only: this app is not Apple notarized.\n'
