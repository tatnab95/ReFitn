extends VBoxContainer

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")
const BarChart = preload("res://scripts/bar_chart.gd")
const StatsMeasures = preload("res://scripts/stats_measures.gd")

var _built := false
var _mode_days := 7
var _exercise_index := 0
var _toggle_7: Button
var _toggle_30: Button
var _exercise_option: OptionButton
var _reps_chart
var _time_chart
var _record_chart
var _points_chart
var _measures


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	_build()
	refresh()


func refresh() -> void:
	if not _built:
		return

	_toggle_7.button_pressed = _mode_days == 7
	_toggle_30.button_pressed = _mode_days == 30
	_toggle_7.theme_type_variation = &"PrimaryButton" if _mode_days == 7 else &""
	_toggle_30.theme_type_variation = &"PrimaryButton" if _mode_days == 30 else &""

	var selected_exercise := ""
	if _exercise_index > 0 and _exercise_index <= Texts.EXERCISES.size():
		selected_exercise = str(Texts.EXERCISES[_exercise_index - 1].id)

	var today := Streak.day_number_from_unix(int(Time.get_unix_time_from_system()))
	var start := today - _mode_days + 1
	var labels := []
	var reps_values := []
	var time_values := []
	var record_values := []
	var points_values := []
	for day in range(start, today + 1):
		var civil := Streak.civil_from_days(day)
		labels.append("%02d.%02d" % [int(civil.day), int(civil.month)])
		reps_values.append(0)
		time_values.append(0)
		record_values.append(0)
		points_values.append(0)

	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY:
			continue
		if int(workout.get("sets", 0)) <= 0:
			continue
		var exercise_id := str(workout.get("exercise_id", ""))
		if not selected_exercise.is_empty() and exercise_id != selected_exercise:
			continue
		var started_unix := int(workout.get("started_unix", 0))
		if started_unix <= 0:
			continue
		var day_number := Streak.day_number_from_unix(started_unix)
		var index := day_number - start
		if index < 0 or index >= _mode_days:
			continue

		reps_values[index] = int(reps_values[index]) + maxi(0, int(workout.get("reps", 0)))
		time_values[index] = int(time_values[index]) + maxi(0, int(workout.get("duration_seconds", 0)))
		var workout_record := _workout_record(workout)
		record_values[index] = maxi(int(record_values[index]), workout_record)
		points_values[index] = int(points_values[index]) + Storage.workout_points(workout)

	_reps_chart.set_data(reps_values, labels)
	_time_chart.set_data(time_values, labels)
	_record_chart.set_data(record_values, labels)
	_points_chart.set_data(points_values, labels)
	_measures.refresh()


func _workout_record(workout: Dictionary) -> int:
	var raw_set_reps = workout.get("set_reps", [])
	var best := 0
	if typeof(raw_set_reps) == TYPE_ARRAY:
		for value in raw_set_reps:
			best = maxi(best, int(value))
	if best > 0:
		return best
	var sets := maxi(0, int(workout.get("sets", 0)))
	if sets <= 0:
		return 0
	return int(round(float(int(workout.get("reps", 0))) / float(sets)))


func _build() -> void:
	if _built:
		return
	_built = true

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	_toggle_7 = Button.new()
	_toggle_7.text = Texts.t("last_7_days")
	_toggle_7.custom_minimum_size = Vector2(180, 86)
	_toggle_7.add_theme_font_size_override("font_size", 30)
	_toggle_7.toggle_mode = true
	_toggle_7.pressed.connect(_set_mode.bind(7))
	_toggle_30 = Button.new()
	_toggle_30.text = Texts.t("last_30_days")
	_toggle_30.custom_minimum_size = Vector2(180, 86)
	_toggle_30.add_theme_font_size_override("font_size", 30)
	_toggle_30.toggle_mode = true
	_toggle_30.pressed.connect(_set_mode.bind(30))
	_exercise_option = OptionButton.new()
	_exercise_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exercise_option.custom_minimum_size = Vector2(0, 86)
	_exercise_option.add_theme_font_size_override("font_size", 28)
	_exercise_option.add_item(Texts.t("all_exercises"), 0)
	for index in range(Texts.EXERCISES.size()):
		_exercise_option.add_item(str(Texts.EXERCISES[index].name), index + 1)
	_exercise_option.item_selected.connect(_on_exercise_selected)
	controls.add_child(_toggle_7)
	controls.add_child(_toggle_30)
	controls.add_child(_exercise_option)
	add_child(controls)

	_reps_chart = _add_chart(Texts.t("graph_reps"), false)
	_time_chart = _add_chart(Texts.t("graph_time"), true)
	_record_chart = _add_chart(Texts.t("graph_record"), false)
	_points_chart = _add_chart(Texts.t("graph_points"), false)
	_measures = StatsMeasures.new()
	add_child(_measures)


func _add_chart(title: String, time_mode: bool):
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 34)
	var chart = BarChart.new()
	chart.custom_minimum_size = Vector2(0, 330)
	chart.value_mode = "time" if time_mode else "number"
	box.add_child(label)
	box.add_child(chart)
	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)
	return chart


func _set_mode(days: int) -> void:
	_mode_days = days
	refresh()


func _on_exercise_selected(index: int) -> void:
	_exercise_index = index
	refresh()
