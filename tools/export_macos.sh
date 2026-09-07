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

[[ "$(uname -s)" == "Darwin" ]] || fail "macOS is required for this export."
[[ -x "$EDITOR" ]] || fail "Missing local editor: $EDITOR"
[[ -f "$PROJECT_DIR/project.godot" ]] || fail "Missing project.godot."
[[ -f "$PROJECT_DIR/export_presets.cfg" ]] || fail "Missing export_presets.cfg."
[[ -f "$PROJECT_DIR/LICENSES.md" ]] || fail "Missing LICENSES.md."
[[ -f "$TEMPLATES/version.txt" && -s "$TEMPLATES/macos.zip" ]] || fail "Missing local macOS export templates."
[[ -x /usr/bin/codesign && -x /usr/bin/unzip ]] || fail "macOS codesign and unzip are required."

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
"$EDITOR" --headless --path "$PROJECT_DIR" --log-file /tmp/pulsebreak-export.log \
  --export-release macOS "$APP"
[[ -x "$APP/Contents/MacOS/Pulsebreak" ]] || fail "Export did not produce the game executable."

# Add the engine notice before the final local ad-hoc signature.
cp "$PROJECT_DIR/LICENSES.md" "$APP/Contents/Resources/LICENSES.md"
/usr/bin/codesign --force --deep --sign - "$APP"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
printf 'Exported and signature verified: %s\n' "$APP"
