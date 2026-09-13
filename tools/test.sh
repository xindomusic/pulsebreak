#!/bin/sh
set -eu
PULSEBREAK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PULSEBREAK_ENGINE=${PULSEBREAK_GODOT:-"$PULSEBREAK_ROOT/.tools/Godot.app/Contents/MacOS/Godot"}
PULSEBREAK_LOGS=$(mktemp -d /tmp/pulsebreak-tests.XXXXXX)
for suite in rules save integration traversal altitude_integration campaign generation weapons endless combat_fx audio native_controls_check; do
  case "$suite" in native_controls_check) script="$suite.gd";; *) script="${suite}_test.gd";; esac
  output="$PULSEBREAK_LOGS/$suite.log"
  if ! "$PULSEBREAK_ENGINE" --headless --path "$PULSEBREAK_ROOT" --quit-after 6000 --log-file "$output" --script "tests/$script"; then
    echo "Failed: $suite. Logs: $PULSEBREAK_LOGS"
    exit 1
  fi
  if grep -Eq 'SCRIPT ERROR|Parse Error|FAIL:' "$output"; then
    echo "Godot reported a script failure in $suite. Logs: $PULSEBREAK_LOGS"
    exit 1
  fi
  if ! grep -q 'checks, 0 failures' "$output"; then
    echo "Suite did not report successful completion: $suite. Logs: $PULSEBREAK_LOGS"
    exit 1
  fi
done
echo "All twelve suites passed. Logs: $PULSEBREAK_LOGS"
