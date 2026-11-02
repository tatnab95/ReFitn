extends RefCounted

# Sunday measure: one set per exercise, stored as workouts with type "measure".

const Streak = preload("res://scripts/streak.gd")


static func _is_measure(workout: Dictionary, exercise_id: String) -> bool:
	return str(workout.get("type", "normal")) == "measure" \
		and str(workout.get("exercise_id", "")) == exercise_id \
		and int(workout.get("sets", 0)) > 0


# Reps of the latest measure of this exercise before day_number, or -1 when there is none.
static func last_reps(exercise_id: String, before_day: int) -> int:
	var best_day := -1000000
	var best_reps := -1
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY or not _is_measure(workout, exercise_id):
			continue
		var started := int(workout.get("started_unix", 0))
		if started <= 0:
			continue
		var day := Streak.day_number_from_unix(started)
		if day >= before_day or day < best_day:
			continue
		best_day = day
		best_reps = int(workout.get("reps", 0))
	return best_reps


# Goal for the next measure: previous measure + 1. -1 means no goal (no previous measure).
static func target(exercise_id: String, today: int) -> int:
	var previous := last_reps(exercise_id, today)
	return previous + 1 if previous >= 0 else -1


static func done_today(exercise_id: String, today: int) -> bool:
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY or not _is_measure(workout, exercise_id):
			continue
		if Streak.day_number_from_unix(int(workout.get("started_unix", 0))) == today:
			return true
	return false
