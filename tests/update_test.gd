extends SceneTree
## Self-update pure logic: version compare, release parsing, checksum lookup.
## The network and bundle-swap paths are exercised manually on packaged builds.

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	var Updater = load("res://scripts/updater.gd")
	check(Updater.parse_version("v1.4.0") == [1, 4, 0], "v-prefixed tag parses to a version triple")
	check(Updater.parse_version("1.3") == [1, 3, 0], "short versions pad with zeros")
	check(Updater.parse_version("").is_empty() and Updater.parse_version("v1.x.0").is_empty() and Updater.parse_version("nightly").is_empty(), "malformed versions parse to nothing")
	check(Updater.is_newer("1.4.0", "1.3.2") and Updater.is_newer("v2.0.0", "1.9.9"), "higher remote versions count as updates")
	check(not Updater.is_newer("1.3.2", "1.3.2") and not Updater.is_newer("1.3.1", "1.3.2") and not Updater.is_newer("junk", "1.3.2"), "equal, older and malformed remotes are never updates")

	var payload := '{"tag_name":"v1.4.0","html_url":"https://example.invalid/r","assets":[{"name":"Pulsebreak-1.4.0-macOS-universal.zip","browser_download_url":"https://example.invalid/z.zip"},{"name":"Pulsebreak-1.4.0-SHA256SUMS.txt","browser_download_url":"https://example.invalid/s.txt"},{"name":"notes.txt","browser_download_url":"https://example.invalid/n"}]}'
	var info: Dictionary = Updater.release_info(payload)
	check(info.get("version") == "1.4.0" and info.get("zip_name") == "Pulsebreak-1.4.0-macOS-universal.zip" and str(info.get("sums_url")).ends_with("s.txt"), "latest-release JSON yields version, app zip and checksum asset")
	check(Updater.release_info("{}").is_empty() and Updater.release_info("not json").is_empty(), "missing tag or assets yield no update offer")
	check(Updater.release_info('{"tag_name":"v9.9.9","assets":[]}').is_empty(), "a release without downloadable assets is not offered")

	var sums := "aaa111  Pulsebreak.app/Contents/Resources/Pulsebreak.pck\n493B2D  Pulsebreak-1.4.0-macOS-universal.zip\n"
	check(Updater.expected_sha256(sums, "Pulsebreak-1.4.0-macOS-universal.zip") == "493b2d", "checksum lookup finds and lowercases the zip hash")
	check(Updater.expected_sha256(sums, "missing.zip").is_empty(), "unknown files have no expected checksum")

	var fixture := "user://update-test-fixture.bin"
	var file := FileAccess.open(fixture, FileAccess.WRITE)
	file.store_string("abc")
	file.close()
	check(Updater.sha256_of_file(fixture) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "file hashing matches the known SHA-256 of the fixture bytes")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))

	check(Updater.app_bundle_path("/Applications/Pulsebreak.app/Contents/MacOS/Pulsebreak") == "/Applications/Pulsebreak.app", "packaged executable path resolves to its bundle")
	check(Updater.app_bundle_path("/usr/local/bin/godot").is_empty(), "non-bundle executables refuse self-replacement")

	print("%s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
