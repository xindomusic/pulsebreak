extends SceneTree

var checks := 0
var failures := 0
var store
var fixture := ""

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func write_fixture(value: String) -> void:
	var file := FileAccess.open(fixture, FileAccess.WRITE)
	check(file != null, "fixture can be written")
	if file:
		file.store_string(value)
		file.close()

func unique_bindings(data: Dictionary) -> bool:
	var seen := {}
	for key in data.bindings.values():
		if seen.has(key):
			return false
		seen[key] = true
	return seen.size() == 7

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/save_store.gd"):
		push_error("FAIL: local save store is not implemented")
		quit(1)
		return
	store = load("res://scripts/save_store.gd")
	fixture = "res://qa/test-settings-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	store.save_path = fixture
	check(not FileAccess.file_exists(fixture), "isolated fixture starts absent")
	var data: Dictionary = store.load_data()
	check(data.best == 0 and data.volume == 0.65 and data.bindings.left == KEY_A, "missing save permits new run with defaults")
	data.bindings.left = KEY_J
	check(store.default_data().bindings.left == KEY_A, "defaults are independent dictionaries")
	data.volume = 0.3
	data.shake = 0.8
	data.assist = true
	data.low_effects = true
	data.practiced = true
	data.won = true
	data.overdrive = true
	data.best = 19420
	check(store.save_data(data), "settings save succeeds")
	var restored: Dictionary = store.load_data()
	check(restored == data, "all settings and custom bindings survive disk roundtrip")
	check(not FileAccess.file_exists(fixture + ".tmp"), "successful save leaves no temporary file")
	data.best = 24000
	check(store.save_data(data) and store.load_data().best == 24000, "atomic replacement updates existing high score")
	for content in ["{broken", "[]", "null", "42", "\"settings\"", ""]:
		write_fixture(content)
		check(store.load_data() == store.default_data(), "invalid JSON/root recovers defaults: " + content)
	write_fixture('{"volume":-3,"shake":4,"best":-50,"assist":"true","low_effects":1,"practiced":null,"unknown":"discard"}')
	restored = store.load_data()
	check(restored.volume == 0.0 and restored.shake == 1.0 and restored.best == 0, "out-of-range settings clamp safely")
	check(not restored.assist and not restored.low_effects and not restored.practiced, "booleans are strictly typed")
	check(not restored.has("unknown"), "unknown properties are discarded")
	write_fixture('{"volume":"0.2","shake":false,"best":12.5,"bindings":[]}')
	check(store.load_data() == store.default_data(), "wrong numeric and binding types use defaults")
	write_fixture('{"best":1e100,"volume":1e100,"shake":-1e100}')
	restored = store.load_data()
	check(restored.best == 2147483647 and restored.volume == 1.0 and restored.shake == 0.0, "huge JSON values clamp before integer conversion")
	data = store.default_data()
	data.volume = NAN
	data.shake = INF
	data.best = INF
	data.unknown = "discard"
	check(store.save_data(data), "nonfinite in-memory settings can be saved safely")
	check(store.load_data() == store.default_data(), "save validates nonfinite values and unknown properties")
	for invalid in [0, -1, 999999, 1.5, "A", true, KEY_ENTER, KEY_TAB, KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_F11]:
		write_fixture(JSON.stringify({"bindings": {"left": invalid}}))
		restored = store.load_data()
		check(restored.bindings.left == KEY_A and unique_bindings(restored), "invalid or reserved binding restores usable defaults: " + str(invalid))
	write_fixture(JSON.stringify({"bindings": {"left": KEY_D, "right": "broken", "pulse": KEY_Q, "unknown": KEY_M}}))
	restored = store.load_data()
	check(restored.bindings.left == KEY_A and restored.bindings.right == KEY_D and restored.bindings.pulse == KEY_Q, "partial binding collision restores defaults and preserves independent custom key")
	check(restored.bindings.size() == 7 and unique_bindings(restored), "unknown bindings cannot add actions or duplicate keys")
	write_fixture(JSON.stringify({"bindings": {"left": KEY_J, "right": KEY_J, "up": KEY_D}}))
	restored = store.load_data()
	check(unique_bindings(restored) and restored.bindings.left == KEY_A and restored.bindings.right == KEY_D and restored.bindings.up == KEY_W, "cascading duplicate fallback remains playable")
	write_fixture(JSON.stringify({"bindings": {"left": KEY_D, "right": KEY_A}}))
	restored = store.load_data()
	check(restored.bindings.left == KEY_D and restored.bindings.right == KEY_A, "complete valid key swaps survive")
	write_fixture(JSON.stringify({"bindings": {"pulse": KEY_F}}))
	restored = store.load_data()
	check(unique_bindings(restored) and restored.bindings.jump == KEY_J and restored.bindings.pulse == KEY_F, "legacy F binding survives with an unused jump fallback")
	data = store.default_data()
	data.bindings.jump = KEY_J
	check(store.save_data(data) and store.load_data().bindings.jump == KEY_J, "new jump binding survives roundtrip")
	var bytes_before := FileAccess.get_file_as_bytes(fixture)
	var blocked_temporary := ProjectSettings.globalize_path(fixture + ".tmp")
	check(DirAccess.make_dir_absolute(blocked_temporary) == OK, "temporary output can be blocked by isolated test directory")
	check(not store.save_data(store.default_data()), "blocked temporary write reports failure")
	check(FileAccess.get_file_as_bytes(fixture) == bytes_before, "failed atomic write preserves previous save byte for byte")
	DirAccess.remove_absolute(blocked_temporary)
	store.save_path = fixture + "/missing/settings.json"
	check(not store.save_data(store.default_data()), "unwritable destination reports failure without throwing")
	check(FileAccess.get_file_as_bytes(fixture) == bytes_before, "failed save preserves existing file")
	store.save_path = fixture
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))
	check(not FileAccess.file_exists(fixture), "test fixture is removed")
	print("%s: %d save checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
