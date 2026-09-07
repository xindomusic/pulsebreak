extends Node
## Original audio with two synchronized stems and twelve reusable cue voices.

const CUE_NAMES: Array[String] = ["dash", "absorb", "pulse", "shoot", "hit", "kill", "warning", "upgrade", "boss", "core", "victory", "defeat", "ready"]
const COOLDOWNS: Dictionary = {"shoot": 0.105, "absorb": 0.045, "kill": 0.080, "hit": 0.14, "warning": 0.42, "ready": 0.15}
const PRIORITIES: Dictionary = {"shoot": 0, "kill": 1, "absorb": 2, "dash": 3, "ready": 3, "core": 4, "warning": 5, "pulse": 6, "hit": 7, "upgrade": 8, "boss": 9, "victory": 10, "defeat": 10}
const CUE_LEVELS: Dictionary = {"shoot": -20.0, "kill": -14.0, "absorb": -12.0, "dash": -11.0, "ready": -15.0, "core": -10.0, "warning": -10.0, "pulse": -7.0, "hit": -8.0, "upgrade": -9.0, "boss": -8.0, "victory": -7.0, "defeat": -9.0}
const ABSORB_PITCHES: Array[float] = [1.0, 1.12246, 1.18921, 1.33484, 1.49831]

var _streams: Dictionary = {}
var _last_cue: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _pressure: AudioStreamPlayer
var _volume: float = 0.8
var _muted: bool = false
var _intensity: float = 0.0
var _smooth_intensity: float = 0.0
var _absorb_step: int = 0
var _last_absorb: float = -10.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue: String in CUE_NAMES:
		var path: String = "res://assets/audio/%s.wav" % cue
		if ResourceLoader.exists(path):
			_streams[cue] = load(path)
	for index: int in range(12):
		var voice := AudioStreamPlayer.new()
		voice.name = "CueVoice%d" % index
		voice.set_meta("priority", -1)
		voice.set_meta("started", 0.0)
		voice.set_meta("level", -12.0)
		add_child(voice)
		_voices.append(voice)
	_music = _make_music("music_foundry")
	_pressure = _make_music("music_pressure")
	_apply_music_levels()
	# Both play requests enter the audio server during this frame.
	_music.play()
	_pressure.play()


func _make_music(asset_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = asset_name
	var path: String = "res://assets/audio/%s.wav" % asset_name
	if ResourceLoader.exists(path):
		var stream: AudioStreamWAV = load(path) as AudioStreamWAV
		if stream != null:
			stream = stream.duplicate() as AudioStreamWAV
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
			player.stream = stream
	add_child(player)
	return player


func _process(delta: float) -> void:
	_smooth_intensity = lerpf(_smooth_intensity, _intensity, 1.0 - exp(-delta * 1.8))
	_apply_music_levels()


func _gain_db() -> float:
	return -80.0 if _muted or _volume <= 0.001 else linear_to_db(_volume)


func _apply_music_levels() -> void:
	if not is_instance_valid(_music):
		return
	var gain: float = _gain_db()
	_music.volume_db = clampf(-15.0 + _smooth_intensity * 2.0 + gain, -80.0, 0.0)
	_pressure.volume_db = clampf(lerpf(-34.0, -14.0, _smooth_intensity) + gain, -80.0, 0.0)


func play_cue(cue_name: String, strength: float = 1.0) -> void:
	if _muted or _volume <= 0.001 or not _streams.has(cue_name):
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var cooldown: float = float(COOLDOWNS.get(cue_name, 0.06))
	if now - float(_last_cue.get(cue_name, -100.0)) < cooldown:
		return
	var priority: int = int(PRIORITIES.get(cue_name, 3))
	var chosen: AudioStreamPlayer = null
	var oldest: float = INF
	# Three voices are reserved for essential feedback, so automatic fire
	# cannot consume the entire pool. Busy higher-priority cues are protected.
	var usable: int = 12 if priority >= 5 else 9
	for index: int in range(usable):
		var voice: AudioStreamPlayer = _voices[index]
		if not voice.playing:
			chosen = voice
			break
		var started: float = float(voice.get_meta("started"))
		if int(voice.get_meta("priority")) <= priority and started < oldest:
			oldest = started
			chosen = voice
	if chosen == null:
		return
	_last_cue[cue_name] = now
	chosen.stop()
	chosen.stream = _streams[cue_name]
	chosen.pitch_scale = 1.0
	if cue_name == "absorb":
		if now - _last_absorb > 0.55:
			_absorb_step = 0
		chosen.pitch_scale = ABSORB_PITCHES[_absorb_step % ABSORB_PITCHES.size()]
		_absorb_step += 1
		_last_absorb = now
	elif cue_name == "pulse":
		chosen.pitch_scale = lerpf(1.12, 0.85, clampf(strength, 0.0, 1.5) / 1.5)
	var level: float = float(CUE_LEVELS.get(cue_name, -12.0)) + linear_to_db(clampf(strength, 0.35, 1.3))
	chosen.set_meta("priority", priority)
	chosen.set_meta("started", now)
	chosen.set_meta("level", level)
	chosen.volume_db = level + _gain_db()
	chosen.play()


func set_intensity(amount: float) -> void:
	_intensity = clampf(amount, 0.0, 1.0)


func set_volume(amount: float) -> void:
	_volume = clampf(amount, 0.0, 1.0)
	_refresh_volume()


func set_muted(value: bool) -> void:
	_muted = value
	_refresh_volume()


func _refresh_volume() -> void:
	_apply_music_levels()
	for voice: AudioStreamPlayer in _voices:
		voice.volume_db = clampf(float(voice.get_meta("level")) + _gain_db(), -80.0, 0.0)


func _exit_tree() -> void:
	# Release playback references while the audio server is still available.
	# Looping streams otherwise remain active until engine teardown.
	for voice: AudioStreamPlayer in _voices:
		voice.stop()
		voice.stream = null
	for player: AudioStreamPlayer in [_music, _pressure]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	# Godot queues stop as FADE_OUT_TO_DELETION; the audio thread releases
	# its playback references on the following mix. Immediate engine exit
	# otherwise shuts the driver down before that mix can complete.
	OS.delay_usec(int(clampf(AudioServer.get_time_to_next_mix() + 0.04, 0.04, 0.10) * 1000000.0))
	_streams.clear()
	_voices.clear()
	_music = null
	_pressure = null
