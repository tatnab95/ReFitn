extends Node

const Texts = preload("res://scripts/texts.gd")

const WORKOUTS_PATH := "user://workouts.json"
const SETTINGS_PATH := "user://settings.json"
const DEFAULT_REPS := 10
const DEFAULT_REST_SECONDS := 120
const SAVE_VERSION := 1

var workouts: Array = []
var settings: Dictionary = {}

# Transient values used to move between scenes.
var selected_exercise_id := "pullups"
var last_summary: Dictionary = {}


func _ready() -> void:
	load_all()
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
	if not FileAccess.file_exists(WORKOUTS_PATH):
		save_workouts()


func load_all() -> void:
	workouts = []

	var workouts_data = _read_json(WORKOUTS_PATH)
	var workouts_list = workouts_data
	if typeof(workouts_data) == TYPE_DICTIONARY:
		workouts_list = workouts_data.get("workouts", [])
	if typeof(workouts_list) == TYPE_ARRAY:
		for raw in workouts_list:
			var workout := _sanitize_workout(raw)
			if not workout.is_empty():
				workouts.append(workout)

	settings = _sanitize_settings(_read_json(SETTINGS_PATH))


func get_reps(exercise_id: String) -> int:
	var exercises = settings.get("exercises", {})
	if typeof(exercises) != TYPE_DICTIONARY:
		return DEFAULT_REPS
	var item = exercises.get(exercise_id, {})
	if typeof(item) != TYPE_DICTIONARY:
		return DEFAULT_REPS
	return clampi(int(item.get("reps", DEFAULT_REPS)), 1, 999)


func get_rest(exercise_id: String) -> int:
	var exercises = settings.get("exercises", {})
	if typeof(exercises) != TYPE_DICTIONARY:
		return DEFAULT_REST_SECONDS
	var item = exercises.get(exercise_id, {})
	if typeof(item) != TYPE_DICTIONARY:
		return DEFAULT_REST_SECONDS
	return clampi(int(item.get("rest", DEFAULT_REST_SECONDS)), 0, 3600)


func set_reps(exercise_id: String, reps: int) -> void:
	_update_exercise_setting(exercise_id, "reps", clampi(reps, 1, 999))


func set_rest(exercise_id: String, rest_seconds: int) -> void:
	_update_exercise_setting(exercise_id, "rest", clampi(rest_seconds, 0, 3600))


func _update_exercise_setting(exercise_id: String, key: String, value: int) -> void:
	var exercises = settings.get("exercises", {})
	if typeof(exercises) != TYPE_DICTIONARY:
		exercises = {}
	var item = exercises.get(exercise_id, {})
	if typeof(item) != TYPE_DICTIONARY:
		item = {}
	item[key] = value
	exercises[exercise_id] = item
	settings["exercises"] = exercises
	save_settings()


func save_settings() -> void:
	_write_json(SETTINGS_PATH, {
		"version": SAVE_VERSION,
		"exercises": settings.get("exercises", {}),
	})


func save_workouts() -> void:
	_write_json(WORKOUTS_PATH, {
		"version": SAVE_VERSION,
		"workouts": workouts,
	})


func begin_workout(exercise_id: String, started_unix: int) -> String:
	var workout_id := _new_id()
	workouts.append({
		"id": workout_id,
		"exercise_id": exercise_id,
		"started_at": _iso_from_unix(started_unix),
		"started_unix": started_unix,
		"finished_at": "",
		"finished_unix": 0,
		"sets": 0,
		"reps": 0,
		"work_seconds": 0,
		"rest_seconds": 0,
		"duration_seconds": 0,
		"finished": false,
	})
	save_workouts()
	return workout_id


func update_workout(workout_id: String, patch: Dictionary) -> void:
	for index in range(workouts.size()):
		var workout = workouts[index]
		if typeof(workout) != TYPE_DICTIONARY:
			continue
		if str(workout.get("id", "")) != workout_id:
			continue
		for key in patch:
			workout[key] = patch[key]
		workouts[index] = workout
		save_workouts()
		return


func finish_workout(workout_id: String, patch: Dictionary) -> void:
	if workout_id.is_empty():
		return
	var now := int(Time.get_unix_time_from_system())
	var full := patch.duplicate()

	var work_seconds := maxi(0, int(full.get("work_seconds", 0)))
	var rest_seconds := maxi(0, int(full.get("rest_seconds", 0)))
	full["work_seconds"] = work_seconds
	full["rest_seconds"] = rest_seconds
	full["duration_seconds"] = work_seconds + rest_seconds
	full["finished"] = true
	full["finished_unix"] = now
	full["finished_at"] = _iso_from_unix(now)
	update_workout(workout_id, full)


func export_workouts(path: String) -> Error:
	if path.get_extension().is_empty():
		path += ".json"
	return _write_json(path, {
		"app": "ReFitn",
		"version": SAVE_VERSION,
		"exported_at": _iso_from_unix(int(Time.get_unix_time_from_system())),
		"workouts": workouts,
	})


func import_workouts(path: String) -> int:
	if not FileAccess.file_exists(path):
		return -1

	var data = _read_json(path)
	if data == null:
		return -1

	var imported_list = data
	if typeof(data) == TYPE_DICTIONARY:
		imported_list = data.get("workouts", null)
	if typeof(imported_list) != TYPE_ARRAY:
		return -1

	var existing_ids := {}
	for workout in workouts:
		if typeof(workout) == TYPE_DICTIONARY:
			existing_ids[str(workout.get("id", ""))] = true

	var added := 0
	for raw in imported_list:
		var workout := _sanitize_workout(raw)
		if workout.is_empty():
			continue
		var workout_id := str(workout.get("id", ""))
		if existing_ids.has(workout_id):
			continue
		workouts.append(workout)
		existing_ids[workout_id] = true
		added += 1

	if added > 0:
		save_workouts()
	return added


func _sanitize_workout(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}

	var source: Dictionary = raw
	var exercise_id := str(source.get("exercise_id", "")).strip_edges()
	if exercise_id.is_empty():
		exercise_id = "pullups"

	var workout_id := str(source.get("id", "")).strip_edges()
	if workout_id.is_empty():
		workout_id = _new_id()

	var started_unix := int(source.get("started_unix", 0))
	if started_unix <= 0:
		started_unix = int(Time.get_unix_time_from_system())

	var sets := maxi(0, int(source.get("sets", 0)))
	var reps := maxi(0, int(source.get("reps", 0)))
	var work_seconds := maxi(0, int(source.get("work_seconds", 0)))
	var rest_seconds := maxi(0, int(source.get("rest_seconds", 0)))
	var duration_seconds := int(source.get("duration_seconds", -1))
	if duration_seconds < 0:
		duration_seconds = work_seconds + rest_seconds
	else:
		duration_seconds = maxi(duration_seconds, work_seconds + rest_seconds)

	var started_at := str(source.get("started_at", ""))
	if started_at.is_empty():
		started_at = _iso_from_unix(started_unix)

	var finished := bool(source.get("finished", false))
	var finished_unix := int(source.get("finished_unix", 0))
	var finished_at := str(source.get("finished_at", ""))
	if finished and finished_at.is_empty() and finished_unix > 0:
		finished_at = _iso_from_unix(finished_unix)

	return {
		"id": workout_id,
		"exercise_id": exercise_id,
		"started_at": started_at,
		"started_unix": started_unix,
		"finished_at": finished_at,
		"finished_unix": finished_unix,
		"sets": sets,
		"reps": reps,
		"work_seconds": work_seconds,
		"rest_seconds": rest_seconds,
		"duration_seconds": duration_seconds,
		"finished": finished,
	}


func _sanitize_settings(raw: Variant) -> Dictionary:
	var source: Dictionary = {}
	if typeof(raw) == TYPE_DICTIONARY:
		var exercises = raw.get("exercises", raw)
		if typeof(exercises) == TYPE_DICTIONARY:
			source = exercises

	var result := {"version": SAVE_VERSION, "exercises": {}}
	for exercise in Texts.EXERCISES:
		var exercise_id := str(exercise.id)
		var item = source.get(exercise_id, {})
		var reps := DEFAULT_REPS
		var rest := DEFAULT_REST_SECONDS
		if typeof(item) == TYPE_DICTIONARY:
			reps = int(item.get("reps", DEFAULT_REPS))
			rest = int(item.get("rest", DEFAULT_REST_SECONDS))
		result.exercises[exercise_id] = {
			"reps": clampi(reps, 1, 999),
			"rest": clampi(rest, 0, 3600),
		}
	return result


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)


func _write_json(path: String, data: Variant) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("ReFitn: cannot write " + path)
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return OK


func _iso_from_unix(unix_time: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var date := Time.get_datetime_dict_from_unix_time(unix_time + bias)
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		int(date.year), int(date.month), int(date.day),
		int(date.hour), int(date.minute), int(date.second)
	]


func _new_id() -> String:
	return "%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
