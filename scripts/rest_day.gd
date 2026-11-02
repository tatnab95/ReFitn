extends RefCounted

# Rest day rules: never two in a row, and after a rest day at least one set must be done.

const Streak = preload("res://scripts/streak.gd")


# Returns "" when a rest day can be marked today, otherwise a Texts key explaining why not.
static func block_reason(today: int) -> String:
	var rest := Storage.rest_day_numbers()
	if rest.has(today):
		return "rest_block_marked"
	if rest.has(today - 1):
		return "rest_block_yesterday"
	var trained := Streak.workout_day_numbers(Storage.workouts)
	if trained.has(today):
		return "rest_block_today"
	if not rest.is_empty():
		var last_rest := -1000000
		for number in rest.keys():
			last_rest = maxi(last_rest, int(number))
		var trained_after := false
		for number in trained.keys():
			if int(number) > last_rest:
				trained_after = true
				break
		if not trained_after:
			return "rest_block_need_workout"
	return ""
