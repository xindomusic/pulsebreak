#!/bin/sh
set -eu
PULSEBREAK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PULSEBREAK_ENGINE=${PULSEBREAK_GODOT:-"$PULSEBREAK_ROOT/.tools/Godot.app/Contents/MacOS/Godot"}
if [ ! -x "$PULSEBREAK_ENGINE" ]; then
  echo "Install Godot 4.7.2 as described in docs/GETTING_STARTED.md, or set PULSEBREAK_GODOT to its executable."
  exit 1
fi
exec "$PULSEBREAK_ENGINE" --path "$PULSEBREAK_ROOT"
