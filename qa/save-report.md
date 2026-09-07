# Local save persistence verification

Implemented `scripts/save_store.gd` with static `load_data()`, `save_data(data)`, and `default_data()` methods. The normal destination is `user://settings.json`.

Validation starts from fresh defaults and imports only recognized fields. Volume and shake clamp to 0–1. Best score accepts finite integral numbers and clamps to 0–2,147,483,647 before conversion. Boolean fields require actual booleans. Wrong types, nonfinite numbers, missing files, malformed JSON, and non-object JSON recover safe defaults.

Bindings import known actions and supported keyboard codes only. Enter (including keypad Enter), Tab, Escape, 1, 2, 3, and F11 remain reserved. Invalid or conflicting remaps restore the affected defaults; repeated collision resolution handles cascades without losing unrelated valid remaps. Complete valid swaps remain supported. Defaults are independently allocated on each call.

Saving validates the data again, writes and flushes a sibling `.tmp` file, then renames it over the destination. Failed writes report `false`; the previous destination is never deleted first. This protects against partial writes but does not provide a backup history or coordinate concurrent game processes.

## Test evidence

Test-first run, before implementation: exit 1 with `FAIL: local save store is not implemented`.

Final command (from the project directory):

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pulsebreak-save-tests.log --script tests/save_test.gd
```

Godot `4.7.2.stable.official.ed1daf0bf`; exit 0:

```text
PASS: 68 save checks, 0 failures
```

Final output contained no script errors or warnings. Checks exercised real disk serialization and replacement, every setting and custom bindings, missing/corrupt/non-object data, strict numeric and boolean validation, huge values and in-memory NaN/infinity, reserved and invalid keys, partial and cascading collisions, valid swaps, unknown-field removal, independent defaults, unwritable destinations, and byte-for-byte preservation of a prior save when temporary output is blocked.

Tests override the destination before any load/save, use unique `res://qa/test-settings-<pid>-<ticks>.json` fixtures, and remove only those fixtures and their temporary directory. They never read or overwrite real user settings.
