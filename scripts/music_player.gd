extends Node

# Background music (autoload MusicPlayer). Tracks are copied into user://music, so the
# original file (possibly a content:// URI on Android) is not needed after import.
# Lives in the autoload, so playback continues across scenes.

signal changed
signal notice(message: String)

const Texts = preload("res://scripts/texts.gd")
const DataSafety = preload("res://scripts/data_safety.gd")

const STATE_PATH := "user://music.json"
const MUSIC_DIR := "user://music"
const COVERS_DIR := "user://music/covers"
const COVER_MAX := 256
const EXTENSIONS := ["mp3", "ogg", "wav"]
const MODE_ALL := "all"
const MODE_ONE := "one"
const MODE_RANDOM := "random"
const MODES := [MODE_ALL, MODE_ONE, MODE_RANDOM]
const DUCK_DB := -16.0

var tracks: Array = []
var enabled := true
var mode := MODE_ALL
var volume := 0.8
var widget_collapsed := false
var current_id := ""
var paused := false

var _player: AudioStreamPlayer
var _tween: Tween
var _covers := {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COVERS_DIR))
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_on_finished)
	_load()
	_player.volume_db = _db()


func _load() -> void:
	var loaded: Dictionary = DataSafety.read_json(STATE_PATH)
	var data = loaded.get("data")
	if typeof(data) != TYPE_DICTIONARY:
		return
	if DataSafety.needs_migration(data):
		DataSafety.backup(STATE_PATH)
	enabled = bool(data.get("enabled", true))
	var raw_mode := str(data.get("mode", MODE_ALL))
	mode = raw_mode if raw_mode in MODES else MODE_ALL
	volume = clampf(float(data.get("volume", 0.8)), 0.0, 1.0)
	widget_collapsed = bool(data.get("widget_collapsed", false))
	var raw_tracks = data.get("tracks", [])
	tracks = []
	if typeof(raw_tracks) == TYPE_ARRAY:
		for item in raw_tracks:
			if typeof(item) == TYPE_DICTIONARY and not str(item.get("id", "")).is_empty():
				tracks.append({
					"id": str(item.id),
					"title": str(item.get("title", "")),
					"file": str(item.get("file", "")),
					"cover": str(item.get("cover", "")),
				})
	if DataSafety.needs_migration(data):
		save()


func save() -> void:
	var file := FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if file == null:
		notice.emit(Texts.t("music_save_error") % STATE_PATH.get_file())
		return
	file.store_string(JSON.stringify({
		"schema_version": DataSafety.SCHEMA_VERSION,
		"enabled": enabled,
		"mode": mode,
		"volume": volume,
		"widget_collapsed": widget_collapsed,
		"tracks": tracks,
	}, "\t"))
	file.close()


# ---------- library ----------

func import_audio(source_path: String) -> String:
	var name := display_name(source_path)
	var ext := name.get_extension().to_lower()
	if not EXTENSIONS.has(ext):
		ext = ""
	var bytes := FileAccess.get_file_as_bytes(source_path)
	if bytes.is_empty():
		return Texts.t("music_read_error") % name
	if ext.is_empty():
		ext = sniff_ext(bytes)
	if ext.is_empty():
		return Texts.t("music_bad_format") % name
	if decode(bytes, ext) == null:
		return Texts.t("music_read_error") % name
	var id := _new_id()
	var file_path := "%s/%s.%s" % [MUSIC_DIR, id, ext]
	var out := FileAccess.open(file_path, FileAccess.WRITE)
	if out == null:
		return Texts.t("music_save_error") % name
	out.store_buffer(bytes)
	out.close()
	var title := name.get_basename() if EXTENSIONS.has(name.get_extension().to_lower()) else Texts.t("music_track_number") % (tracks.size() + 1)
	tracks.append({"id": id, "title": title, "file": file_path, "cover": ""})
	save()
	changed.emit()
	return ""


func set_cover(track_id: String, source_path: String) -> String:
	var index := _index_of(track_id)
	if index < 0:
		return ""
	var bytes := FileAccess.get_file_as_bytes(source_path)
	var image := Image.new()
	var error: Error = ERR_FILE_UNRECOGNIZED
	if bytes.size() > 3 and bytes[0] == 0x89:
		error = image.load_png_from_buffer(bytes)
	elif bytes.size() > 2 and bytes[0] == 0xFF and bytes[1] == 0xD8:
		error = image.load_jpg_from_buffer(bytes)
	if error != OK or image.is_empty():
		return Texts.t("music_cover_bad")
	var largest := maxi(image.get_width(), image.get_height())
	if largest > COVER_MAX:
		var scale := float(COVER_MAX) / float(largest)
		image.resize(int(image.get_width() * scale), int(image.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var cover_path := "%s/%s.png" % [COVERS_DIR, track_id]
	if image.save_png(cover_path) != OK:
		return Texts.t("music_save_error") % cover_path.get_file()
	tracks[index].cover = cover_path
	_covers.erase(track_id)
	save()
	changed.emit()
	return ""


func rename_track(track_id: String, title: String) -> void:
	var index := _index_of(track_id)
	var clean := title.strip_edges()
	if index < 0 or clean.is_empty() or clean == str(tracks[index].title):
		return
	tracks[index].title = clean
	save()
	changed.emit()


func move_track(track_id: String, delta: int) -> void:
	var index := _index_of(track_id)
	var target := index + delta
	if index < 0 or target < 0 or target >= tracks.size():
		return
	var moved = tracks[index]
	tracks[index] = tracks[target]
	tracks[target] = moved
	save()
	changed.emit()


func remove_track(track_id: String) -> void:
	var index := _index_of(track_id)
	if index < 0:
		return
	var track: Dictionary = tracks[index]
	if track_id == current_id:
		stop()
		current_id = ""
	for path in [str(track.file), str(track.cover)]:
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	tracks.remove_at(index)
	_covers.erase(track_id)
	save()
	changed.emit()


func track_by_id(track_id: String) -> Dictionary:
	var index := _index_of(track_id)
	return tracks[index] if index >= 0 else {}


func current_track() -> Dictionary:
	return track_by_id(current_id)


func cover_texture(track: Dictionary) -> Texture2D:
	var track_id := str(track.get("id", ""))
	if track_id.is_empty():
		return null
	if _covers.has(track_id):
		return _covers[track_id]
	var path := str(track.get("cover", ""))
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	_covers[track_id] = texture
	return texture


# ---------- settings ----------

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop()
	save()
	changed.emit()


func set_mode(value: String) -> void:
	mode = value if value in MODES else MODE_ALL
	save()
	changed.emit()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	if _tween == null or not _tween.is_running():
		_player.volume_db = _db()
	save()


func set_collapsed(value: bool) -> void:
	widget_collapsed = value
	save()
	changed.emit()


# ---------- playback ----------

func is_playing() -> bool:
	return _player.playing and not paused


func position() -> float:
	return _player.get_playback_position() if _player.playing else 0.0


func length() -> float:
	return _player.stream.get_length() if _player.stream != null else 0.0


func play_track(track_id: String) -> void:
	var index := _index_of(track_id)
	if index >= 0 and enabled:
		_play_index(index, 0.0)


func toggle_play() -> void:
	if not enabled or tracks.is_empty():
		return
	if _player.playing:
		paused = not paused
		_player.stream_paused = paused
		changed.emit()
		return
	var index := _index_of(current_id)
	_play_index(maxi(index, 0), 0.0)


func stop() -> void:
	_player.stop()
	paused = false
	changed.emit()


func next_track() -> void:
	_step(1)


func previous_track() -> void:
	_step(-1)


func seek(seconds: float) -> void:
	if _player.stream == null:
		return
	var target := clampf(seconds, 0.0, maxf(0.0, length() - 0.05))
	if _player.playing:
		_player.seek(target)
	else:
		_player.play(target)
		_player.stream_paused = paused
	changed.emit()


func duck(seconds: float = 1.5) -> void:
	if not _player.playing:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", DUCK_DB, 0.15)
	_tween.tween_interval(seconds)
	_tween.tween_property(_player, "volume_db", _db(), 0.4)


func _step(direction: int) -> void:
	if tracks.is_empty():
		return
	var index := _index_of(current_id)
	if mode == MODE_RANDOM and tracks.size() > 1:
		var pick := index
		while pick == index:
			pick = randi() % tracks.size()
		index = pick
	else:
		index = posmod(index + direction, tracks.size())
	_play_index(index, 0.0)


func _on_finished() -> void:
	paused = false
	if not enabled or tracks.is_empty():
		changed.emit()
		return
	if mode == MODE_ONE:
		_play_index(maxi(_index_of(current_id), 0), 0.0)
	else:
		_step(1)


func _play_index(start_index: int, from_seconds: float) -> void:
	var index := clampi(start_index, 0, tracks.size() - 1) if not tracks.is_empty() else -1
	for attempt in range(tracks.size()):
		if index < 0:
			break
		var track: Dictionary = tracks[index]
		var stream := _load_stream(track)
		if stream != null:
			_player.stream = stream
			_player.volume_db = _db()
			_player.play(from_seconds)
			paused = false
			current_id = str(track.id)
			changed.emit()
			return
		notice.emit(Texts.t("music_skipped") % str(track.title))
		index = (index + 1) % tracks.size()
	_player.stop()
	changed.emit()


func _load_stream(track: Dictionary) -> AudioStream:
	var path := str(track.get("file", ""))
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	return decode(bytes, path.get_extension().to_lower())


# ---------- helpers ----------

static func decode(bytes: PackedByteArray, ext: String) -> AudioStream:
	match ext:
		"mp3":
			return AudioStreamMP3.load_from_buffer(bytes)
		"ogg":
			return AudioStreamOggVorbis.load_from_buffer(bytes)
		"wav":
			return AudioStreamWAV.load_from_buffer(bytes)
	return null


static func sniff_ext(bytes: PackedByteArray) -> String:
	if bytes.size() < 4:
		return ""
	var head := bytes.slice(0, 4).get_string_from_ascii()
	if head.begins_with("OggS"):
		return "ogg"
	if head == "RIFF":
		return "wav"
	if head.begins_with("ID3") or (bytes[0] == 0xFF and (bytes[1] & 0xE0) == 0xE0):
		return "mp3"
	return ""


static func display_name(path: String) -> String:
	var decoded := path.uri_decode() if path.begins_with("content://") else path
	var name := decoded.get_file()
	if name.contains(":"):
		name = name.get_slice(":", name.get_slice_count(":") - 1)
	return name if not name.is_empty() else "track"


func _index_of(track_id: String) -> int:
	for index in range(tracks.size()):
		if str(tracks[index].id) == track_id:
			return index
	return -1


func _db() -> float:
	return -80.0 if volume <= 0.001 else linear_to_db(volume)


func _new_id() -> String:
	return "%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
