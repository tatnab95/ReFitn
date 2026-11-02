extends RefCounted

# Streak and calendar helpers. Everything is derived from saved workouts;
# no extra copy of workout history is stored.

const SECONDS_PER_DAY := 86400


static func day_number_from_unix(unix_time: int) -> int:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var date := Time.get_datetime_dict_from_unix_time(unix_time + bias)
	return days_from_civil(int(date.year), int(date.month), int(date.day))


static func day_key_from_unix(unix_time: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var date := Time.get_datetime_dict_from_unix_time(unix_time + bias)
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]


static func day_key_from_number(day_number: int) -> String:
	var date := civil_from_days(day_number)
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]


static func month_title(year: int, month: int) -> String:
	return "%02d.%04d" % [month, year]


static func add_months(year: int, month: int, delta: int) -> Dictionary:
	var total := year * 12 + (month - 1) + delta
	var new_year := int(floor(float(total) / 12.0))
	var new_month := total - new_year * 12 + 1
	return {"year": new_year, "month": new_month}


static func days_in_month(year: int, month: int) -> int:
	var next := add_months(year, month, 1)
	return days_from_civil(int(next.year), int(next.month), 1) - days_from_civil(year, month, 1)


static func first_weekday_monday(year: int, month: int) -> int:
	return (days_from_civil(year, month, 1) + 3) % 7


static func workout_day_numbers(workouts: Array) -> Dictionary:
	var result := {}
	for workout in workouts:
		if typeof(workout) != TYPE_DICTIONARY:
			continue
		if int(workout.get("sets", 0)) <= 0:
			continue
		var started_unix := int(workout.get("started_unix", 0))
		if started_unix > 0:
			result[day_number_from_unix(started_unix)] = true
	return result


static func day_number_from_key(key: String) -> int:
	var parts := key.split("-")
	if parts.size() != 3:
		return 0
	return days_from_civil(int(parts[0]), int(parts[1]), int(parts[2]))


# rest: day numbers of rest days. A rest day neither adds to the streak nor breaks it.
static func calculate(workouts: Array, now_unix: int = 0, rest: Dictionary = {}) -> Dictionary:
	if now_unix <= 0:
		now_unix = int(Time.get_unix_time_from_system())

	var trained := workout_day_numbers(workouts)
	var today_number := day_number_from_unix(now_unix)
	var trained_today := trained.has(today_number)

	var cursor := today_number if trained_today else today_number - 1
	var current := 0
	while trained.has(cursor) or rest.has(cursor):
		if trained.has(cursor):
			current += 1
		cursor -= 1

	var sorted_numbers := []
	for number in trained.keys():
		sorted_numbers.append(int(number))
	sorted_numbers.sort()

	var record := 0
	var run := 0
	var previous := 0
	for number in sorted_numbers:
		if run > 0 and _bridged_by_rest(previous, number, rest):
			run += 1
		else:
			run = 1
		record = maxi(record, run)
		previous = number

	return {
		"current": current,
		"record": record,
		"trained_today": trained_today,
		"today_number": today_number,
		"days": trained,
	}


static func _bridged_by_rest(previous: int, number: int, rest: Dictionary) -> bool:
	for day in range(previous + 1, number):
		if not rest.has(day):
			return false
	return true


static func days_from_civil(year: int, month: int, day: int) -> int:
	var y := year
	if month <= 2:
		y -= 1
	var era := int(floor(float(y) / 400.0))
	var yoe := y - era * 400
	var shifted_month := month + (-3 if month > 2 else 9)
	var doy := int(floor(float(153 * shifted_month + 2) / 5.0)) + day - 1
	var doe := yoe * 365 + int(floor(float(yoe) / 4.0)) - int(floor(float(yoe) / 100.0)) + doy
	return era * 146097 + doe - 719468


static func civil_from_days(day_number: int) -> Dictionary:
	var z := day_number + 719468
	var era := int(floor(float(z) / 146097.0))
	var doe := z - era * 146097
	var yoe := int(floor(float(doe - int(floor(float(doe) / 1460.0)) + int(floor(float(doe) / 36524.0)) - int(floor(float(doe) / 146096.0))) / 365.0))
	var y := yoe + era * 400
	var doy := doe - (365 * yoe + int(floor(float(yoe) / 4.0)) - int(floor(float(yoe) / 100.0)))
	var mp := int(floor(float(5 * doy + 2) / 153.0))
	var day := doy - int(floor(float(153 * mp + 2) / 5.0)) + 1
	var month := mp + (3 if mp < 10 else -9)
	if month <= 2:
		y += 1
	return {"year": y, "month": month, "day": day}
