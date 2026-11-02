extends RefCounted

# Daily goal: points of the day, or reps of one exercise. Adapts once per finished day.
# Rest days and measure days are skipped by the adaptation.

const Streak = preload("res://scripts/streak.gd")
const Plans = preload("res://scripts/plans.gd")

const START_SUGGESTION := 30
const MAX_CATCHUP_DAYS := 60
const SMART_HISTORY_DAYS := 3
const SMART_SEARCH_DAYS := 120


static func today_number() -> int:
	return Streak.day_number_from_unix(int(Time.get_unix_time_from_system()))


static func is_skipped_day(day_number: int, rest: Dictionary) -> bool:
	return rest.has(day_number) or Plans.index_for_day_number(day_number) == Plans.MEASURE_DAY


# Points (type points) or reps of the goal exercise (type reps) done on the given day.
static func actual_for_day(day_number: int, goal: Dictionary) -> int:
	var total := 0
	var is_reps := str(goal.get("type", "points")) == "reps"
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY or int(workout.get("sets", 0)) <= 0:
			continue
		var started := int(workout.get("started_unix", 0))
		if started <= 0 or Streak.day_number_from_unix(started) != day_number:
			continue
		if is_reps:
			if str(workout.get("exercise_id", "")) == str(goal.get("exercise", "")):
				total += maxi(0, int(workout.get("reps", 0)))
		else:
			total += Storage.workout_points(workout)
	return total


# Average of the last days with training (not rest, not measure). Default when there is no history.
static func smart_value(goal_type: String, exercise_id: String) -> int:
	var sample := {"type": goal_type, "exercise": exercise_id}
	var rest := Storage.rest_day_numbers()
	var today := today_number()
	var values: Array = []
	var day := today - 1
	var searched := 0
	while values.size() < SMART_HISTORY_DAYS and searched < SMART_SEARCH_DAYS:
		if not is_skipped_day(day, rest):
			var actual := actual_for_day(day, sample)
			if actual > 0:
				values.append(actual)
		day -= 1
		searched += 1
	if values.is_empty():
		return START_SUGGESTION
	var sum := 0
	for value in values:
		sum += int(value)
	var average := float(sum) / float(values.size())
	var coefs := Storage.get_goal_settings()
	var by_multiplier := int(ceil(average * float(coefs.get("smart_multiplier", 1.05))))
	return maxi(by_multiplier, int(ceil(average)) + 1)


# Applies the adaptation for every finished day since the last evaluation.
static func evaluate_pending() -> void:
	var today := today_number()
	var last_key := Storage.get_goal_last_day()
	if last_key.is_empty():
		Storage.set_goal_last_day(Streak.day_key_from_number(today - 1))
		Storage.save_settings()
		return
	var last := Streak.day_number_from_key(last_key)
	if last >= today - 1:
		return

	var goal := Storage.get_daily_goal()
	var value := int(goal.get("value", 0))
	var coefs := Storage.get_goal_settings()
	var rest := Storage.rest_day_numbers()
	var first := maxi(last + 1, today - MAX_CATCHUP_DAYS)
	if value > 0:
		for day in range(first, today):
			if is_skipped_day(day, rest):
				continue
			var actual := actual_for_day(day, goal)
			if actual >= value:
				value = maxi(value + 1, int(ceil(value * float(coefs.get("raise_multiplier", 1.05)))))
			elif float(actual) < float(value) * float(coefs.get("fail_threshold", 0.7)):
				value = maxi(1, int(round(float(value) * float(coefs.get("fail_multiplier", 0.9)))))
		if value != int(goal.get("value", 0)):
			Storage.set_daily_goal(str(goal.get("type", "points")), str(goal.get("exercise", "pullups")), value)
	Storage.set_goal_last_day(Streak.day_key_from_number(today - 1))
	Storage.save_settings()
