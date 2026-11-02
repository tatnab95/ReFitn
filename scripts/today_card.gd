extends PanelContainer

# Main screen card: today's plan day, done marks, points toward the daily goal, goal and rest day buttons.

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")
const Plans = preload("res://scripts/plans.gd")
const Goals = preload("res://scripts/goals.gd")
const Measure = preload("res://scripts/measure.gd")
const RestDay = preload("res://scripts/rest_day.gd")
const GoalDialog = preload("res://scripts/goal_dialog.gd")

var _title: Label
var _subtitle: Label
var _items_box: VBoxContainer
var _points_label: Label
var _points_bar: ProgressBar
var _goal_label: Label
var _goal_button: Button
var _rest_notice: Label
var _rest_button: Button
var _rest_hint: Label
var _rest_dialog: ConfirmationDialog
var _goal_dialog


func _ready() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 22)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	_title = _label(Texts.t("today_title"), 44, ThemeColors.TEXT)
	_subtitle = _label("", 28, ThemeColors.MUTED)
	box.add_child(_title)
	box.add_child(_subtitle)

	_rest_notice = _label(Texts.t("today_rest_notice"), 30, ThemeColors.REST)
	box.add_child(_rest_notice)

	_items_box = VBoxContainer.new()
	_items_box.add_theme_constant_override("separation", 10)
	box.add_child(_items_box)

	_points_label = _label("", 34, ThemeColors.GOLD)
	box.add_child(_points_label)
	_points_bar = ProgressBar.new()
	_points_bar.custom_minimum_size = Vector2(0, 40)
	_points_bar.show_percentage = false
	box.add_child(_points_bar)

	_goal_label = _label("", 28, ThemeColors.MUTED)
	box.add_child(_goal_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_goal_button = _button(Texts.t("goal_button"), "SecondaryButton")
	_goal_button.pressed.connect(_on_goal_pressed)
	row.add_child(_goal_button)
	_rest_button = _button(Texts.t("rest_day_button"), "SecondaryButton")
	_rest_button.pressed.connect(_on_rest_pressed)
	row.add_child(_rest_button)

	_rest_hint = _label("", 24, ThemeColors.MUTED)
	_rest_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_rest_hint)

	margin.add_child(box)
	add_child(margin)

	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_goal_dialog = GoalDialog.new()
	_goal_dialog.saved.connect(refresh)
	layer.add_child(_goal_dialog)

	_rest_dialog = ConfirmationDialog.new()
	_rest_dialog.title = Texts.t("rest_confirm_title")
	_rest_dialog.dialog_text = Texts.t("rest_confirm_text")
	_rest_dialog.ok_button_text = Texts.t("rest_confirm_ok")
	_rest_dialog.cancel_button_text = Texts.t("cancel")
	_rest_dialog.confirmed.connect(_on_rest_confirmed)
	add_child(_rest_dialog)

	Goals.evaluate_pending()
	refresh()


func refresh() -> void:
	var now := int(Time.get_unix_time_from_system())
	var today := Streak.day_number_from_unix(now)
	var index := Plans.index_for_day_number(today)
	var plan_id := Storage.get_plan_id()
	var day := Plans.day_for(plan_id, index, Storage.get_muscle_up_variant())
	var is_measure: bool = day.measure

	_subtitle.text = Texts.t("today_card_sub") % [
		Texts.t(Plans.plan_name_key(plan_id)), Texts.t(Plans.day_name_key(str(day.day)))
	]
	_title.text = "%s · %s" % [Texts.t("today_title"), Texts.WEEKDAYS_SHORT[index]]

	var is_rest := Storage.has_rest_day(Streak.day_key_from_number(today))
	_rest_notice.visible = is_rest
	_items_box.visible = not is_rest
	_rebuild_items(day, today, is_measure)

	var goal := Storage.get_daily_goal()
	var goal_value := int(goal.get("value", 0))
	var progress := Goals.actual_for_day(today, goal)
	var is_reps := str(goal.get("type", "points")) == "reps"
	if is_reps:
		_points_label.text = "%s: %d / %d" % [Texts.exercise_name(str(goal.exercise)), progress, goal_value]
	elif goal_value > 0:
		_points_label.text = Texts.t("points_format") % [progress, goal_value]
	else:
		_points_label.text = Texts.t("points_only") % progress
	_points_bar.max_value = maxf(1.0, float(goal_value))
	_points_bar.value = minf(float(progress), _points_bar.max_value) if goal_value > 0 else 0.0
	_points_bar.visible = goal_value > 0

	if goal_value <= 0:
		_goal_label.text = Texts.t("goal_none")
	elif is_reps:
		_goal_label.text = Texts.t("goal_reps_format") % [goal_value, Texts.exercise_name(str(goal.exercise))]
	else:
		_goal_label.text = Texts.t("goal_points_format") % goal_value

	var reason := "" if is_rest else RestDay.block_reason(today)
	_rest_button.disabled = is_rest or not reason.is_empty()
	_rest_hint.text = "" if reason.is_empty() or is_rest else Texts.t(reason)
	_rest_button.visible = not is_rest


func _rebuild_items(day: Dictionary, today: int, is_measure: bool) -> void:
	for child in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()

	var seen := {}
	var workout_type := "measure" if is_measure else "normal"
	for item in day.items:
		var exercise_id := str(item)
		var occurrence := int(seen.get(exercise_id, 0))
		seen[exercise_id] = occurrence + 1
		var done := _sessions_today(exercise_id, today, workout_type) > occurrence
		_items_box.add_child(_item_button(exercise_id, today, is_measure, done))


func _item_button(exercise_id: String, today: int, is_measure: bool, done: bool) -> Button:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 110)
	button.add_theme_font_size_override("font_size", 40)
	var mark := "✓ " if done else "○ "
	var text := mark + Texts.exercise_name(exercise_id)
	if is_measure:
		var previous := Measure.last_reps(exercise_id, today)
		if done:
			var measured := _reps_today(exercise_id, today, "measure")
			var diff := measured - previous if previous >= 0 else 0
			var diff_text := "+%d" % diff if diff > 0 else str(diff)
			text += "  " + (Texts.t("measure_result") % [measured, previous, diff_text] if previous >= 0 else Texts.t("measure_tag"))
		else:
			var target := previous + 1 if previous >= 0 else -1
			text += "  " + (Texts.t("measure_target") % [target, previous] if target > 0 else Texts.t("measure_first"))
		button.disabled = done
	button.text = text
	if done:
		button.add_theme_color_override("font_color", ThemeColors.GREEN_BRIGHT)
		button.add_theme_color_override("font_disabled_color", ThemeColors.GREEN_BRIGHT)
	button.pressed.connect(_on_item_pressed.bind(exercise_id, is_measure))
	return button


func _sessions_today(exercise_id: String, today: int, workout_type: String) -> int:
	var count := 0
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY:
			continue
		if str(workout.get("exercise_id", "")) != exercise_id or int(workout.get("sets", 0)) <= 0:
			continue
		if str(workout.get("type", "normal")) != workout_type:
			continue
		if Streak.day_number_from_unix(int(workout.get("started_unix", 0))) == today:
			count += 1
	return count


func _reps_today(exercise_id: String, today: int, workout_type: String) -> int:
	var total := 0
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY:
			continue
		if str(workout.get("exercise_id", "")) != exercise_id or str(workout.get("type", "")) != workout_type:
			continue
		if Streak.day_number_from_unix(int(workout.get("started_unix", 0))) == today:
			total = maxi(total, int(workout.get("reps", 0)))
	return total


func _on_item_pressed(exercise_id: String, is_measure: bool) -> void:
	Storage.selected_exercise_id = exercise_id
	Storage.pending_measure = is_measure
	get_tree().change_scene_to_file("res://scenes/workout.tscn")


func _on_goal_pressed() -> void:
	_goal_dialog.open()


func _on_rest_pressed() -> void:
	_rest_dialog.popup_centered(Vector2i(900, 500))


func _on_rest_confirmed() -> void:
	Storage.add_rest_day(Streak.day_key_from_unix(int(Time.get_unix_time_from_system())))
	Notifier.refresh_daily()
	refresh()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, variation: String) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = StringName(variation)
	button.custom_minimum_size = Vector2(0, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 32)
	return button
