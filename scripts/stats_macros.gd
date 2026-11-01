extends VBoxContainer

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")
const BarChart = preload("res://scripts/bar_chart.gd")

var _built := false
var _mode_days := 7
var _toggle_7: Button
var _toggle_30: Button
var _chart
var _average_calories: Label
var _average_macros: Label


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

	var today := Streak.day_number_from_unix(int(Time.get_unix_time_from_system()))
	var start := today - _mode_days + 1
	var labels := []
	var calories_values := []
	var total_calories := 0
	var total_protein := 0
	var total_fat := 0
	var total_carbs := 0
	var total_water := 0

	for day in range(start, today + 1):
		var civil := Streak.civil_from_days(day)
		var day_key := "%04d-%02d-%02d" % [int(civil.year), int(civil.month), int(civil.day)]
		labels.append("%02d.%02d" % [int(civil.day), int(civil.month)])
		var totals := Storage.get_day_totals(day_key)
		calories_values.append(int(totals.get("calories", 0)))
		total_calories += int(totals.get("calories", 0))
		total_protein += int(totals.get("protein", 0))
		total_fat += int(totals.get("fat", 0))
		total_carbs += int(totals.get("carbs", 0))
		total_water += int(totals.get("water", 0))

	var goals := Storage.get_goals()
	var goal_calories := int(goals.get("calories", 2500))
	_chart.set_data(calories_values, labels, float(goal_calories))

	var days := maxi(1, _mode_days)
	_average_calories.text = Texts.t("average_calories") % int(round(float(total_calories) / days))
	_average_macros.text = Texts.t("average_macros") % [
		int(round(float(total_protein) / days)),
		int(round(float(total_fat) / days)),
		int(round(float(total_carbs) / days)),
		int(round(float(total_water) / days)),
	]


func _build() -> void:
	if _built:
		return
	_built = true

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	_toggle_7 = Button.new()
	_toggle_7.text = Texts.t("last_7_days")
	_toggle_7.custom_minimum_size = Vector2(0, 86)
	_toggle_7.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toggle_7.add_theme_font_size_override("font_size", 30)
	_toggle_7.toggle_mode = true
	_toggle_7.pressed.connect(_set_mode.bind(7))
	_toggle_30 = Button.new()
	_toggle_30.text = Texts.t("last_30_days")
	_toggle_30.custom_minimum_size = Vector2(0, 86)
	_toggle_30.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toggle_30.add_theme_font_size_override("font_size", 30)
	_toggle_30.toggle_mode = true
	_toggle_30.pressed.connect(_set_mode.bind(30))
	controls.add_child(_toggle_7)
	controls.add_child(_toggle_30)
	add_child(controls)

	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = Texts.t("graph_calories")
	title.add_theme_font_size_override("font_size", 34)
	_chart = BarChart.new()
	_chart.custom_minimum_size = Vector2(0, 350)
	box.add_child(title)
	box.add_child(_chart)
	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)

	var averages_panel := PanelContainer.new()
	var averages_margin := MarginContainer.new()
	averages_margin.add_theme_constant_override("margin_left", 24)
	averages_margin.add_theme_constant_override("margin_top", 18)
	averages_margin.add_theme_constant_override("margin_right", 24)
	averages_margin.add_theme_constant_override("margin_bottom", 18)
	var averages_box := VBoxContainer.new()
	averages_box.add_theme_constant_override("separation", 6)
	_average_calories = Label.new()
	_average_calories.add_theme_font_size_override("font_size", 34)
	_average_calories.add_theme_color_override("font_color", ThemeColors.GOLD)
	_average_macros = Label.new()
	_average_macros.add_theme_font_size_override("font_size", 26)
	_average_macros.add_theme_color_override("font_color", ThemeColors.MUTED)
	_average_macros.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	averages_box.add_child(_average_calories)
	averages_box.add_child(_average_macros)
	averages_margin.add_child(averages_box)
	averages_panel.add_child(averages_margin)
	add_child(averages_panel)


func _set_mode(days: int) -> void:
	_mode_days = days
	refresh()
