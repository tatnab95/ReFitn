extends VBoxContainer

# Weekly chart of Sunday measures: total reps of all measured exercises per week (last 12 weeks).

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")
const Plans = preload("res://scripts/plans.gd")
const BarChart = preload("res://scripts/bar_chart.gd")

const WEEKS_SHOWN := 12

var _chart


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = Texts.t("graph_measures")
	label.add_theme_font_size_override("font_size", 34)
	_chart = BarChart.new()
	_chart.custom_minimum_size = Vector2(0, 330)
	box.add_child(label)
	box.add_child(_chart)
	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)
	refresh()


func refresh() -> void:
	if _chart == null:
		return
	var weekly := {}
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY or str(workout.get("type", "")) != "measure":
			continue
		if int(workout.get("sets", 0)) <= 0:
			continue
		var day := Streak.day_number_from_unix(int(workout.get("started_unix", 0)))
		var monday := day - Plans.index_for_day_number(day)
		weekly[monday] = int(weekly.get(monday, 0)) + maxi(0, int(workout.get("reps", 0)))

	var current_monday := Streak.day_number_from_unix(int(Time.get_unix_time_from_system()))
	current_monday -= Plans.index_for_day_number(current_monday)
	var first_monday := current_monday - (WEEKS_SHOWN - 1) * 7
	if not weekly.is_empty():
		var earliest: int = weekly.keys().min()
		first_monday = maxi(first_monday, earliest)

	var values: Array = []
	var labels: Array = []
	var monday := first_monday
	while monday <= current_monday:
		values.append(int(weekly.get(monday, 0)))
		var civil := Streak.civil_from_days(monday)
		labels.append("%02d.%02d" % [int(civil.day), int(civil.month)])
		monday += 7
	_chart.set_data(values, labels)
