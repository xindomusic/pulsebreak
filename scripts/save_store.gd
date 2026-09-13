extends RefCounted
## Validated local preferences. Bad or absent files always permit a fresh run.

static var save_path := "user://settings.json"

static func default_data() -> Dictionary:
	return {
		"volume": 0.65, "shake": 0.45, "assist": false,
		"low_effects": false, "best": 0, "practiced": false,
		"won": false, "overdrive": false,
		"bindings": {"left": KEY_A, "right": KEY_D, "up": KEY_W,
			"down": KEY_S, "dash": KEY_SPACE, "pulse": KEY_E, "jump": KEY_F, "weapon": KEY_Q}
	}

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return default_data()
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return default_data()
	var contents := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(contents) != OK or not parser.data is Dictionary:
		return default_data()
	return _validated(parser.data)

static func save_data(data: Dictionary) -> bool:
	# Write beside the destination so rename stays on the same filesystem.
	# Never remove the previous save before the replacement is ready.
	var temporary := save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_validated(data), "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	var temporary_absolute := ProjectSettings.globalize_path(temporary)
	if write_error != OK:
		DirAccess.remove_absolute(temporary_absolute)
		return false
	var result := DirAccess.rename_absolute(temporary_absolute, ProjectSettings.globalize_path(save_path))
	if result != OK:
		DirAccess.remove_absolute(temporary_absolute)
	return result == OK

static func _finite_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _validated(raw: Dictionary) -> Dictionary:
	var clean := default_data()
	for name in ["volume", "shake"]:
		var value: Variant = raw.get(name)
		if _finite_number(value):
			clean[name] = clampf(float(value), 0.0, 1.0)
	for name in ["assist", "low_effects", "practiced", "won", "overdrive"]:
		if raw.get(name) is bool:
			clean[name] = raw[name]
	var best: Variant = raw.get("best")
	if _finite_number(best) and floor(float(best)) == float(best):
		clean.best = int(clampf(float(best), 0.0, 2147483647.0))
	if raw.get("bindings") is Dictionary:
		clean.bindings = _bindings(raw.bindings, clean.bindings)
	return clean

static func _valid_key(value: Variant) -> bool:
	if not _finite_number(value) or float(value) != floor(float(value)):
		return false
	# Restrict to actual keyboard codes before any float-to-int conversion.
	if float(value) < 0.0 or float(value) > 2147483647.0:
		return false
	var key := int(value)
	if key in [KEY_ENTER, KEY_KP_ENTER, KEY_TAB, KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_F11]:
		return false
	# Godot letter keycodes are uppercase; arbitrary Unicode isn't a physical key.
	if key >= KEY_SPACE and key <= KEY_QUOTELEFT:
		return true
	if key >= KEY_F1 and key <= KEY_F12:
		return true
	return key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SHIFT, KEY_CTRL,
		KEY_ALT, KEY_META, KEY_CAPSLOCK, KEY_BACKSPACE, KEY_INSERT, KEY_DELETE,
		KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN, KEY_KP_0, KEY_KP_1,
		KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7,
		KEY_KP_8, KEY_KP_9, KEY_KP_ADD, KEY_KP_SUBTRACT, KEY_KP_MULTIPLY,
		KEY_KP_DIVIDE, KEY_KP_PERIOD]

static func _bindings(raw: Dictionary, defaults: Dictionary) -> Dictionary:
	var clean := defaults.duplicate()
	for action in defaults:
		if _valid_key(raw.get(action)):
			clean[action] = int(raw[action])
	# Six-action saves predate jump; seven-action saves predate weapon switching.
	# Allocate only missing actions after reading the old keys. This preserves a
	# valid F/Q assignment instead of treating a new default as a user collision.
	var additions: Array[String] = []
	for action in ["jump","weapon"]:
		if not raw.has(action): additions.append(action)
	var occupied: Array = []
	for action in clean:
		if action not in additions: occupied.append(clean[action])
	for action in additions:
		for candidate in [defaults[action],KEY_J,KEY_R,KEY_T,KEY_G,KEY_H,KEY_K,KEY_L]:
			if candidate not in occupied:
				clean[action] = candidate
				occupied.append(candidate)
				break
	# Resolve collisions as a set, preserving complete swaps. Restoring a default
	# can expose another collision, so repeat until no custom key needs repair.
	var changed := true
	while changed:
		changed = false
		var counts := {}
		for key in clean.values():
			counts[key] = counts.get(key, 0) + 1
		for action in clean:
			if counts[clean[action]] > 1 and clean[action] != defaults[action]:
				clean[action] = defaults[action]
				changed = true
	return clean
