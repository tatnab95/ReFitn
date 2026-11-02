extends Control

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")
const TodayCard = preload("res://scripts/today_card.gd")
const DataNotice = preload("res://scripts/data_notice.gd")
const NotificationPrompt = preload("res://scripts/notification_prompt.gd")

@onready var title_label: Label = $Margin/MainVBox/Title
@onready var subtitle_label: Label = $Margin/MainVBox/Subtitle
@onready var section_label: Label = $Margin/MainVBox/Section
@onready var exercise_list: VBoxContainer = $Margin/MainVBox/ExerciseList
@onready var nutrition_button: Button = $Margin/MainVBox/NutritionButton
@onready var stats_button: Button = $Margin/MainVBox/StatsButton
@onready var streak_flame = $Margin/MainVBox/TopRow/StreakFlame
@onready var streak_label: Label = $Margin/MainVBox/TopRow/StreakLabel
@onready var settings_button: Button = $Margin/MainVBox/TopRow/SettingsButton


func _ready() -> void:
	title_label.text = Texts.t("app_title")
	subtitle_label.text = Texts.t("app_subtitle")
	section_label.text = Texts.t("choose_exercise")
	nutrition_button.text = Texts.t("nutrition")
	nutrition_button.theme_type_variation = &"NutritionButton"
	stats_button.text = Texts.t("statistics")
	settings_button.tooltip_text = Texts.t("settings_open")
	stats_button.pressed.connect(_on_stats_pressed)
	nutrition_button.pressed.connect(_on_nutrition_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_wrap_in_scroll()
	_add_today_card()
	_build_exercise_list()
	_refresh_streak()
	Notifier.refresh_daily()
	add_child(DataNotice.new())
	add_child(NotificationPrompt.new())


func _add_today_card() -> void:
	var parent := section_label.get_parent()
	var card := TodayCard.new()
	parent.add_child(card)
	parent.move_child(card, section_label.get_index())
	var others := Button.new()
	others.text = Texts.t("other_exercises")
	others.theme_type_variation = &"SecondaryButton"
	others.custom_minimum_size = Vector2(0, 100)
	others.add_theme_font_size_override("font_size", 40)
	parent.add_child(others)
	parent.move_child(others, section_label.get_index())
	section_label.visible = false
	exercise_list.visible = false
	others.pressed.connect(_toggle_exercise_list)


func _toggle_exercise_list() -> void:
	var show_list := not exercise_list.visible
	section_label.visible = show_list
	exercise_list.visible = show_list


func _wrap_in_scroll() -> void:
	var margin := $Margin as MarginContainer
	var content := $Margin/MainVBox as VBoxContainer
	margin.remove_child(content)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)


func _refresh_streak() -> void:
	var info := Streak.calculate(Storage.workouts, 0, Storage.rest_day_numbers())
	var current := int(info.get("current", 0))
	var trained_today := bool(info.get("trained_today", false))
	streak_label.text = Texts.format_streak(current)
	streak_label.add_theme_color_override(
		"font_color",
		ThemeColors.GREEN_BRIGHT if trained_today else ThemeColors.GOLD
	)
	if trained_today:
		streak_flame.set_flame(ThemeColors.GREEN_BRIGHT, ThemeColors.TRANSPARENT, 0.0)
	else:
		streak_flame.set_flame(ThemeColors.GOLD, ThemeColors.TRANSPARENT, 0.0)


func _build_exercise_list() -> void:
	for child in exercise_list.get_children():
		child.queue_free()

	var today := Streak.day_number_from_unix(int(Time.get_unix_time_from_system()))
	for exercise in Texts.EXERCISES:
		var button := Button.new()
		button.text = str(exercise.name)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 130)
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 52)
		button.pressed.connect(_on_exercise_pressed.bind(str(exercise.id)))
		button.add_child(_today_label(_reps_today(str(exercise.id), today)))
		exercise_list.add_child(button)


func _today_label(reps: int) -> Label:
	var label := Label.new()
	label.text = Texts.t("today_reps_format") % reps
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -320
	label.offset_right = -28
	label.offset_top = -30
	label.offset_bottom = 30
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", ThemeColors.GOLD)
	return label


func _reps_today(exercise_id: String, today: int) -> int:
	var total := 0
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY or str(workout.get("exercise_id", "")) != exercise_id:
			continue
		var started := int(workout.get("started_unix", 0))
		if started > 0 and Streak.day_number_from_unix(started) == today:
			total += maxi(0, int(workout.get("reps", 0)))
	return total


func _on_exercise_pressed(exercise_id: String) -> void:
	Storage.selected_exercise_id = exercise_id
	get_tree().change_scene_to_file("res://scenes/workout.tscn")


func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stats.tscn")


func _on_nutrition_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nutrition.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
