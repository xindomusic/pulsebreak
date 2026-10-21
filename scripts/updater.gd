extends Node
## Self-update against GitHub Releases.
##
## Pure helpers (version compare, release parsing, checksum lookup) are static
## and unit-tested. The node flow is: check_latest -> download_update (verifies
## SHA-256 against the release sums asset) -> install_update, which only runs
## inside a packaged macOS .app: a detached shell script waits for this
## process to exit, swaps the bundle with the verified download, and
## relaunches. Any failure before the swap leaves the installed app untouched.

signal update_available(info: Dictionary)
signal up_to_date
signal check_failed(reason: String)
signal download_progress(fraction: float)
signal download_ready(zip_path: String)
signal download_failed(reason: String)

const REPO := "xindomusic/pulsebreak"
const API_LATEST := "https://api.github.com/repos/xindomusic/pulsebreak/releases/latest"
const UPDATE_DIR := "user://update"

var local_version := "0.0.0"
var _request: HTTPRequest
var _pending: Dictionary = {}
var _sums_text := ""
var _phase := ""

static func parse_version(text: String) -> Array:
	var cleaned := text.strip_edges().trim_prefix("v").trim_prefix("V")
	var parts := cleaned.split(".")
	if parts.is_empty() or parts.size() > 4:
		return []
	var out: Array = []
	for part in parts:
		if part.is_empty() or not part.is_valid_int():
			return []
		out.append(int(part))
	while out.size() < 3:
		out.append(0)
	return out

static func is_newer(remote: String, local: String) -> bool:
	var r := parse_version(remote)
	var l := parse_version(local)
	if r.is_empty() or l.is_empty():
		return false
	for i in range(3):
		if int(r[i]) != int(l[i]):
			return int(r[i]) > int(l[i])
	return false

static func release_info(json_text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(json_text) != OK or not parser.data is Dictionary:
		return {}
	var tag := str(parser.data.get("tag_name", ""))
	if parse_version(tag).is_empty():
		return {}
	var info := {"tag": tag, "version": tag.trim_prefix("v"), "zip_url": "", "zip_name": "", "sums_url": "", "notes_url": str(parser.data.get("html_url", ""))}
	for asset in parser.data.get("assets", []):
		if not asset is Dictionary:
			continue
		var name := str(asset.get("name", ""))
		if name.begins_with("Pulsebreak-") and name.ends_with("-macOS-universal.zip"):
			info.zip_url = str(asset.get("browser_download_url", ""))
			info.zip_name = name
		elif name.ends_with("SHA256SUMS.txt"):
			info.sums_url = str(asset.get("browser_download_url", ""))
	if str(info.zip_url).is_empty() or str(info.sums_url).is_empty():
		return {}
	return info

static func expected_sha256(sums_text: String, file_name: String) -> String:
	for line in sums_text.split("\n"):
		var parts := line.strip_edges().split(" ", false)
		if parts.size() >= 2 and parts[parts.size() - 1] == file_name:
			return parts[0].to_lower()
	return ""

static func sha256_of_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	while not file.eof_reached():
		ctx.update(file.get_buffer(65536))
	file.close()
	return ctx.finish().hex_encode()

static func app_bundle_path(executable: String) -> String:
	# .../Pulsebreak.app/Contents/MacOS/Pulsebreak -> .../Pulsebreak.app
	if not executable.contains(".app/Contents/MacOS/"):
		return ""
	return executable.split(".app/Contents/MacOS/")[0] + ".app"

func _ensure_request() -> void:
	if _request:
		return
	_request = HTTPRequest.new()
	_request.timeout = 20.0
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)

func check_latest() -> void:
	_ensure_request()
	_phase = "check"
	var headers := ["User-Agent: Pulsebreak/" + local_version, "Accept: application/vnd.github+json"]
	if _request.request(API_LATEST, headers) != OK:
		check_failed.emit("request")

func download_update(info: Dictionary) -> void:
	_ensure_request()
	_pending = info.duplicate()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UPDATE_DIR))
	_phase = "sums"
	if _request.request(str(info.sums_url), ["User-Agent: Pulsebreak/" + local_version]) != OK:
		download_failed.emit("request")

func _process(_delta: float) -> void:
	if _phase == "zip" and _request and _request.get_http_client_status() == HTTPClient.STATUS_BODY:
		var total := _request.get_body_size()
		if total > 0:
			download_progress.emit(clampf(float(_request.get_downloaded_bytes()) / float(total), 0.0, 1.0))

func _on_request_completed(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _phase == "check":
		_phase = ""
		if code != 200:
			check_failed.emit("http %d" % code)
			return
		var info := release_info(body.get_string_from_utf8())
		if info.is_empty():
			check_failed.emit("parse")
		elif is_newer(str(info.version), local_version):
			update_available.emit(info)
		else:
			up_to_date.emit()
	elif _phase == "sums":
		if code != 200:
			_phase = ""
			download_failed.emit("http %d" % code)
			return
		_sums_text = body.get_string_from_utf8()
		_phase = "zip"
		_request.download_file = UPDATE_DIR + "/" + str(_pending.zip_name)
		if _request.request(str(_pending.zip_url), ["User-Agent: Pulsebreak/" + local_version]) != OK:
			_phase = ""
			download_failed.emit("request")
	elif _phase == "zip":
		_phase = ""
		_request.download_file = ""
		if code != 200:
			download_failed.emit("http %d" % code)
			return
		var zip_path := UPDATE_DIR + "/" + str(_pending.zip_name)
		var want := expected_sha256(_sums_text, str(_pending.zip_name))
		if want.is_empty() or sha256_of_file(zip_path) != want:
			download_failed.emit("checksum")
			return
		download_progress.emit(1.0)
		download_ready.emit(zip_path)

func install_update(zip_path: String) -> String:
	# Returns "" on success (the caller should quit immediately), else a reason.
	if OS.has_feature("editor"):
		return "dev build"
	var bundle := app_bundle_path(OS.get_executable_path())
	if bundle.is_empty():
		return "not a packaged app"
	var dir := ProjectSettings.globalize_path(UPDATE_DIR)
	var zip_abs := ProjectSettings.globalize_path(zip_path)
	var staging := dir + "/staging"
	var script_path := dir + "/install.sh"
	var script := "#!/bin/sh\nset -e\n"
	script += "while kill -0 %d 2>/dev/null; do sleep 0.3; done\n" % OS.get_process_id()
	script += "rm -rf \"%s\" \"%s.old\"\n" % [staging, bundle]
	script += "mkdir -p \"%s\"\n" % staging
	script += "ditto -x -k \"%s\" \"%s\"\n" % [zip_abs, staging]
	script += "mv \"%s\" \"%s.old\"\n" % [bundle, bundle]
	script += "if ! mv \"%s/Pulsebreak.app\" \"%s\"; then mv \"%s.old\" \"%s\"; exit 1; fi\n" % [staging, bundle, bundle, bundle]
	script += "rm -rf \"%s.old\" \"%s\"\n" % [bundle, staging]
	script += "open \"%s\"\n" % bundle
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return "cannot write installer"
	file.store_string(script)
	file.close()
	OS.execute("chmod", ["+x", script_path])
	if OS.create_process("/bin/sh", [script_path]) < 0:
		return "cannot start installer"
	return ""
