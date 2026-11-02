extends RefCounted

# Weekly plans. Index 0 = Monday ... 6 = Sunday (measure day).
# "muscle_up" is replaced with the variant chosen in settings (Выход на 1 / Выход на 2).
# Repeated ids are separate items, e.g. two squats entries are two separate sessions.

const PLAN_IDS := ["full_body", "upper", "legs"]
const MEASURE_DAY := 6
const DAY_MEASURE := "measure"

const PLANS := {
	"full_body": [
		{"day": "full_body", "items": ["pullups", "pushups", "squats", "abs"]},
		{"day": "legs", "items": ["squats", "squats", "abs", "expander"]},
		{"day": "upper", "items": ["pullups", "pushups", "muscle_up", "expander"]},
		{"day": "full_body", "items": ["pullups", "pushups", "squats", "abs"]},
		{"day": "legs", "items": ["squats", "squats", "abs", "expander"]},
		{"day": "upper", "items": ["pullups", "pushups", "muscle_up", "expander"]},
		{"day": "measure", "items": ["pullups", "pushups", "squats", "abs", "muscle_up", "expander"]},
	],
	"upper": [
		{"day": "upper", "items": ["pullups", "pushups", "muscle_up", "expander"]},
		{"day": "upper", "items": ["pullups", "pushups", "muscle_up", "expander"]},
		{"day": "full_body", "items": ["pullups", "pushups", "abs", "expander"]},
		{"day": "upper", "items": ["pullups", "pushups", "muscle_up", "expander"]},
		{"day": "upper", "items": ["pullups", "pushups", "muscle_up", "expander"]},
		{"day": "full_body", "items": ["pullups", "pushups", "abs", "squats"]},
		{"day": "measure", "items": ["pullups", "pushups", "muscle_up", "abs", "expander"]},
	],
	"legs": [
		{"day": "legs", "items": ["squats", "squats", "abs", "expander"]},
		{"day": "full_body", "items": ["pullups", "pushups", "squats", "abs"]},
		{"day": "legs", "items": ["squats", "squats", "abs", "expander"]},
		{"day": "full_body", "items": ["pullups", "pushups", "squats", "expander"]},
		{"day": "legs", "items": ["squats", "squats", "abs", "expander"]},
		{"day": "full_body", "items": ["pullups", "pushups", "squats", "abs"]},
		{"day": "measure", "items": ["squats", "pullups", "pushups", "abs", "muscle_up", "expander"]},
	],
}


static func plan_name_key(plan_id: String) -> String:
	return "plan_" + plan_id


static func day_name_key(day: String) -> String:
	return "day_" + day


# day_number: local day number from Streak.day_number_from_unix. 1970-01-01 was a Thursday (index 3).
static func index_for_day_number(day_number: int) -> int:
	return posmod(day_number + 3, 7)


static func day_for(plan_id: String, index: int, muscle_up_id: String) -> Dictionary:
	var plan: Array = PLANS.get(plan_id, PLANS["full_body"])
	var entry: Dictionary = plan[clampi(index, 0, 6)]
	var items: Array = []
	for item in entry.items:
		items.append(muscle_up_id if str(item) == "muscle_up" else str(item))
	return {
		"day": str(entry.day),
		"measure": str(entry.day) == DAY_MEASURE,
		"items": items,
	}
