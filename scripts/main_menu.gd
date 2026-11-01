extends Control

const Texts = preload("res://scripts/texts.gd")

@onready var title_label: Label = $Margin/MainVBox/Title
@onready var subtitle_label: Label = $Margin/MainVBox/Subtitle
@onready var section_label: Label = $Margin/MainVBox/Section
@onready var exercise_list: VBoxContainer = $Margin/MainVBox/ExerciseList
@onready var stats_button: Button = $Margin/MainVBox/StatsButton


func _ready() -> void:
	title_label.text = Texts.t("app_title")
	subtitle_label.text = Texts.t("app_subtitle")
	section_label.text = Texts.t("choose_exercise")
	stats_button.text = Texts.t("statistics")
	stats_button.pressed.connect(_on_stats_pressed)
	_build_exercise_list()


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
