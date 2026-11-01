extends Node

const Texts = preload("res://scripts/texts.gd")
const Streak = preload("res://scripts/streak.gd")

const WORKOUTS_PATH := "user://workouts.json"
const SETTINGS_PATH := "user://settings.json"
const NUTRITION_PATH := "user://nutrition.json"
const DEFAULT_REPS := 10
const DEFAULT_REST_SECONDS := 120
const DEFAULT_REPS_STEP := 1
const DEFAULT_REST_STEP := 10
const SAVE_VERSION := 2

const DEFAULT_GOALS := {
	"calories": 2500,
	"protein": 150,
	"fat": 70,
	"carbs": 300,
	"water": 2000,
}

var workouts: Array = []
var settings: Dictionary = {}
var nutrition_entries: Array = []
var water_by_day: Dictionary = {}
var last_import_info: Dictionary = {}

# Transient values used to move between scenes.
var selected_exercise_id := "pullups"
var last_summary: Dictionary = {}


func _ready() -> void:
	load_all()
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
	if not FileAccess.file_exists(WORKOUTS_PATH):
		save_workouts()
	if not FileAccess.file_exists(NUTRITION_PATH):
		save_nutrition()


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
	load_nutrition()


func load_nutrition() -> void:
	nutrition_entries = []
	water_by_day = {}

	var data = _read_json(NUTRITION_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		return

	var raw_entries = data.get("entries", [])
	if typeof(raw_entries) == TYPE_ARRAY:
		for raw in raw_entries:
			var entry := _sanitize_food_entry(raw)
			if not entry.is_empty():
				nutrition_entries.append(entry)

	var raw_water = data.get("water", {})
	if typeof(raw_water) == TYPE_DICTIONARY:
		for key in raw_water:
			var day_key := str(key).strip_edges()
			var amount := maxi(0, int(raw_water[key]))
			if not day_key.is_empty() and amount > 0:
				water_by_day[day_key] = amount


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
		"goals": get_goals(),
		"steps": {
			"reps": get_reps_step(),
			"rest": get_rest_step(),
		},
		"sound_enabled": get_sound_enabled(),
		"vibration_enabled": get_vibration_enabled(),
	})


func save_workouts() -> void:
	_write_json(WORKOUTS_PATH, {
		"version": SAVE_VERSION,
		"workouts": workouts,
	})


func save_nutrition() -> void:
	_write_json(NUTRITION_PATH, {
		"version": SAVE_VERSION,
		"entries": nutrition_entries,
		"water": water_by_day,
	})


func get_reps_step() -> int:
	var steps = settings.get("steps", {})
	if typeof(steps) != TYPE_DICTIONARY:
		return DEFAULT_REPS_STEP
	return clampi(int(steps.get("reps", DEFAULT_REPS_STEP)), 1, 100)


func get_rest_step() -> int:
	var steps = settings.get("steps", {})
	if typeof(steps) != TYPE_DICTIONARY:
		return DEFAULT_REST_STEP
	return clampi(int(steps.get("rest", DEFAULT_REST_STEP)), 1, 600)


func set_steps(reps_step: int, rest_step: int) -> void:
	settings["steps"] = {
		"reps": clampi(reps_step, 1, 100),
		"rest": clampi(rest_step, 1, 600),
	}
	save_settings()


func get_sound_enabled() -> bool:
	return bool(settings.get("sound_enabled", true))


func get_vibration_enabled() -> bool:
	return bool(settings.get("vibration_enabled", true))


func set_feedback(sound_enabled: bool, vibration_enabled: bool) -> void:
	settings["sound_enabled"] = sound_enabled
	settings["vibration_enabled"] = vibration_enabled
	save_settings()


func get_goals() -> Dictionary:
	var result := DEFAULT_GOALS.duplicate()
	var stored = settings.get("goals", {})
	if typeof(stored) == TYPE_DICTIONARY:
		for key in DEFAULT_GOALS:
			result[key] = clampi(int(stored.get(key, DEFAULT_GOALS[key])), 0, 100000)
	return result


func save_goals(goals: Dictionary) -> void:
	var merged := get_goals()
	for key in DEFAULT_GOALS:
		if goals.has(key):
			merged[key] = clampi(int(goals[key]), 0, 100000)
	settings["goals"] = merged
	save_settings()


func get_water(day_key: String = "") -> int:
	if day_key.is_empty():
		day_key = Streak.day_key_from_unix(int(Time.get_unix_time_from_system()))
	return maxi(0, int(water_by_day.get(day_key, 0)))


func add_water(amount_ml: int, day_key: String = "") -> int:
	if day_key.is_empty():
		day_key = Streak.day_key_from_unix(int(Time.get_unix_time_from_system()))
	var total := maxi(0, get_water(day_key) + amount_ml)
	water_by_day[day_key] = total
	save_nutrition()
	return total


func set_water(amount_ml: int, day_key: String = "") -> int:
	if day_key.is_empty():
		day_key = Streak.day_key_from_unix(int(Time.get_unix_time_from_system()))
	var total := clampi(amount_ml, 0, 100000)
	if total == 0:
		water_by_day.erase(day_key)
	else:
		water_by_day[day_key] = total
	save_nutrition()
	return total


func add_food_entry(entry_name: String, calories: int, protein: int, fat: int, carbs: int, unix_time: int = 0) -> Dictionary:
	if unix_time <= 0:
		unix_time = int(Time.get_unix_time_from_system())
	var entry := {
		"id": _new_id(),
		"unix": unix_time,
		"date": Streak.day_key_from_unix(unix_time),
		"datetime": _iso_from_unix(unix_time),
		"name": entry_name.strip_edges(),
		"calories": clampi(calories, 0, 100000),
		"protein": clampi(protein, 0, 100000),
		"fat": clampi(fat, 0, 100000),
		"carbs": clampi(carbs, 0, 100000),
	}
	nutrition_entries.append(entry)
	save_nutrition()
	return entry


func delete_food_entry(entry_id: String) -> bool:
	for index in range(nutrition_entries.size()):
		var entry = nutrition_entries[index]
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == entry_id:
			nutrition_entries.remove_at(index)
			save_nutrition()
			return true
	return false


func get_food_entries_for_day(day_key: String) -> Array:
	var result := []
	for entry in nutrition_entries:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("date", "")) == day_key:
			result.append(entry)
	result.sort_custom(func(a, b): return int(a.get("unix", 0)) < int(b.get("unix", 0)))
	return result


func get_day_totals(day_key: String) -> Dictionary:
	var totals := {"calories": 0, "protein": 0, "fat": 0, "carbs": 0}
	for entry in get_food_entries_for_day(day_key):
		for key in totals:
			totals[key] = int(totals[key]) + int(entry.get(key, 0))
	totals["water"] = get_water(day_key)
	return totals


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
		"set_reps": [],
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
	var streak := Streak.calculate(workouts)
	return _write_json(path, {
		"app": "ReFitn",
		"version": SAVE_VERSION,
		"exported_at": _iso_from_unix(int(Time.get_unix_time_from_system())),
		"workouts": workouts,
		"nutrition": nutrition_entries,
		"water": water_by_day,
		"settings": {
			"exercises": settings.get("exercises", {}),
			"goals": get_goals(),
			"steps": {
				"reps": get_reps_step(),
				"rest": get_rest_step(),
			},
			"sound_enabled": get_sound_enabled(),
			"vibration_enabled": get_vibration_enabled(),
		},
		"streak_record": int(streak.get("record", 0)),
	})


func import_workouts(path: String) -> int:
	if not FileAccess.file_exists(path):
		return -1

	var data = _read_json(path)
	if data == null:
		return -1

	var imported_list = data
	var nutrition_list = []
	var water_data = {}
	var import_settings = {}
	if typeof(data) == TYPE_DICTIONARY:
		imported_list = data.get("workouts", [])
		nutrition_list = data.get("nutrition", [])
		water_data = data.get("water", {})
		import_settings = data.get("settings", {})
	if typeof(imported_list) != TYPE_ARRAY:
		imported_list = []
	if typeof(nutrition_list) != TYPE_ARRAY:
		nutrition_list = []
	if typeof(water_data) != TYPE_DICTIONARY:
		water_data = {}
	if typeof(import_settings) != TYPE_DICTIONARY:
		import_settings = {}

	if typeof(data) != TYPE_DICTIONARY and typeof(data) != TYPE_ARRAY:
		return -1

	last_import_info = {"workouts": 0, "nutrition": 0, "water": 0}

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
	last_import_info["workouts"] = added

	var existing_food_ids := {}
	for entry in nutrition_entries:
		if typeof(entry) == TYPE_DICTIONARY:
			existing_food_ids[str(entry.get("id", ""))] = true

	var added_food := 0
	for raw in nutrition_list:
		var entry := _sanitize_food_entry(raw)
		if entry.is_empty():
			continue
		var entry_id := str(entry.get("id", ""))
		if existing_food_ids.has(entry_id):
			continue
		nutrition_entries.append(entry)
		existing_food_ids[entry_id] = true
		added_food += 1

	var changed_water := 0
	for key in water_data:
		var day_key := str(key).strip_edges()
		var amount := maxi(0, int(water_data[key]))
		if day_key.is_empty() or amount <= 0:
			continue
		if amount > get_water(day_key):
			water_by_day[day_key] = amount
			changed_water += 1

	if added_food > 0 or changed_water > 0:
		save_nutrition()
	last_import_info["nutrition"] = added_food
	last_import_info["water"] = changed_water

	_import_settings(import_settings)

	return added


func _import_settings(import_settings: Dictionary) -> void:
	if import_settings.has("goals") and typeof(import_settings.goals) == TYPE_DICTIONARY:
		save_goals(import_settings.goals)
	if import_settings.has("steps") and typeof(import_settings.steps) == TYPE_DICTIONARY:
		set_steps(
			int(import_settings.steps.get("reps", get_reps_step())),
			int(import_settings.steps.get("rest", get_rest_step()))
		)
	if import_settings.has("sound_enabled") or import_settings.has("vibration_enabled"):
		set_feedback(
			bool(import_settings.get("sound_enabled", get_sound_enabled())),
			bool(import_settings.get("vibration_enabled", get_vibration_enabled()))
		)
	var imported_exercises = import_settings.get("exercises", {})
	if typeof(imported_exercises) == TYPE_DICTIONARY:
		for exercise in Texts.EXERCISES:
			var exercise_id := str(exercise.id)
			var item = imported_exercises.get(exercise_id, null)
			if typeof(item) != TYPE_DICTIONARY:
				continue
			if item.has("reps"):
				set_reps(exercise_id, int(item.reps))
			if item.has("rest"):
				set_rest(exercise_id, int(item.rest))


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
	var set_reps := []
	var raw_set_reps = source.get("set_reps", [])
	if typeof(raw_set_reps) == TYPE_ARRAY:
		for value in raw_set_reps:
			var set_value := int(value)
			if set_value > 0:
				set_reps.append(set_value)
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
		"set_reps": set_reps,
		"work_seconds": work_seconds,
		"rest_seconds": rest_seconds,
		"duration_seconds": duration_seconds,
		"finished": finished,
	}


func _sanitize_food_entry(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = raw

	var unix_time := int(source.get("unix", 0))
	if unix_time <= 0:
		unix_time = int(Time.get_unix_time_from_system())

	var entry_id := str(source.get("id", "")).strip_edges()
	if entry_id.is_empty():
		entry_id = _new_id()

	var day_key := str(source.get("date", "")).strip_edges()
	if day_key.is_empty():
		day_key = Streak.day_key_from_unix(unix_time)

	var datetime := str(source.get("datetime", ""))
	if datetime.is_empty():
		datetime = _iso_from_unix(unix_time)

	return {
		"id": entry_id,
		"unix": unix_time,
		"date": day_key,
		"datetime": datetime,
		"name": str(source.get("name", "")).strip_edges(),
		"calories": clampi(int(source.get("calories", 0)), 0, 100000),
		"protein": clampi(int(source.get("protein", 0)), 0, 100000),
		"fat": clampi(int(source.get("fat", 0)), 0, 100000),
		"carbs": clampi(int(source.get("carbs", 0)), 0, 100000),
	}


func _sanitize_settings(raw: Variant) -> Dictionary:
	var raw_dict: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	var source: Dictionary = {}
	var exercises_value = raw_dict.get("exercises", null)
	if typeof(exercises_value) == TYPE_DICTIONARY:
		source = exercises_value
	elif not raw_dict.has("version"):
		source = raw_dict

	var result := {
		"version": SAVE_VERSION,
		"exercises": {},
		"goals": DEFAULT_GOALS.duplicate(),
		"steps": {"reps": DEFAULT_REPS_STEP, "rest": DEFAULT_REST_STEP},
		"sound_enabled": true,
		"vibration_enabled": true,
	}
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

	var goals = raw_dict.get("goals", {})
	if typeof(goals) == TYPE_DICTIONARY:
		for key in DEFAULT_GOALS:
			result.goals[key] = clampi(int(goals.get(key, DEFAULT_GOALS[key])), 0, 100000)

	var steps = raw_dict.get("steps", {})
	if typeof(steps) == TYPE_DICTIONARY:
		result.steps["reps"] = clampi(int(steps.get("reps", DEFAULT_REPS_STEP)), 1, 100)
		result.steps["rest"] = clampi(int(steps.get("rest", DEFAULT_REST_STEP)), 1, 600)

	result.sound_enabled = bool(raw_dict.get("sound_enabled", true))
	result.vibration_enabled = bool(raw_dict.get("vibration_enabled", true))
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
