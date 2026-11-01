extends Control

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")

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
	stats_button.text = Texts.t("statistics")
	settings_button.tooltip_text = Texts.t("settings_open")
	stats_button.pressed.connect(_on_stats_pressed)
	nutrition_button.pressed.connect(_on_nutrition_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_build_exercise_list()
	_refresh_streak()


func _refresh_streak() -> void:
	var info := Streak.calculate(Storage.workouts)
	var current := int(info.get("current", 0))
	var trained_today := bool(info.get("trained_today", false))
	streak_label.text = Texts.format_streak(current)
	streak_label.add_theme_color_override(
		"font_color",
		ThemeColors.GREEN_BRIGHT if trained_today else ThemeColors.MUTED
	)
	if trained_today:
		streak_flame.set_flame(ThemeColors.GREEN_BRIGHT, ThemeColors.TRANSPARENT, 0.0)
	else:
		streak_flame.set_flame(ThemeColors.MUTED, ThemeColors.GOLD, 3.0)


func _build_exercise_list() -> void:
	for child in exercise_list.get_children():
		child.queue_free()

	for exercise in Texts.EXERCISES:
		var button := Button.new()
		button.text = str(exercise.name)
		button.custom_minimum_size = Vector2(0, 130)
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 58)
		button.pressed.connect(_on_exercise_pressed.bind(str(exercise.id)))
		exercise_list.add_child(button)


func _on_exercise_pressed(exercise_id: String) -> void:
	Storage.selected_exercise_id = exercise_id
	get_tree().change_scene_to_file("res://scenes/workout.tscn")


func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stats.tscn")


func _on_nutrition_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nutrition.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
