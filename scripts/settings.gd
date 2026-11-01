extends Control

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const AiSettingsPanel = preload("res://scripts/ai_settings_panel.gd")

@onready var background: ColorRect = $Background
@onready var back_button: Button = $Margin/MainVBox/Header/BackButton
@onready var title_label: Label = $Margin/MainVBox/Header/Title
@onready var goals_title: Label = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsTitle
@onready var calories_label: Label = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/CaloriesLabel
@onready var calories_input: LineEdit = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/CaloriesInput
@onready var protein_label: Label = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/ProteinLabel
@onready var protein_input: LineEdit = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/ProteinInput
@onready var fat_label: Label = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/FatLabel
@onready var fat_input: LineEdit = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/FatInput
@onready var carbs_label: Label = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/CarbsLabel
@onready var carbs_input: LineEdit = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/CarbsInput
@onready var water_label: Label = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/WaterLabel
@onready var water_input: LineEdit = $Margin/MainVBox/Scroll/Content/GoalsPanel/Margin/VBox/GoalsGrid/WaterInput
@onready var steps_title: Label = $Margin/MainVBox/Scroll/Content/StepsPanel/Margin/VBox/StepsTitle
@onready var reps_step_label: Label = $Margin/MainVBox/Scroll/Content/StepsPanel/Margin/VBox/StepsGrid/RepsStepLabel
@onready var reps_step_input: LineEdit = $Margin/MainVBox/Scroll/Content/StepsPanel/Margin/VBox/StepsGrid/RepsStepInput
@onready var rest_step_label: Label = $Margin/MainVBox/Scroll/Content/StepsPanel/Margin/VBox/StepsGrid/RestStepLabel
@onready var rest_step_input: LineEdit = $Margin/MainVBox/Scroll/Content/StepsPanel/Margin/VBox/StepsGrid/RestStepInput
@onready var feedback_title: Label = $Margin/MainVBox/Scroll/Content/FeedbackPanel/Margin/VBox/FeedbackTitle
@onready var sound_check: CheckButton = $Margin/MainVBox/Scroll/Content/FeedbackPanel/Margin/VBox/SoundCheck
@onready var vibration_check: CheckButton = $Margin/MainVBox/Scroll/Content/FeedbackPanel/Margin/VBox/VibrationCheck
@onready var save_button: Button = $Margin/MainVBox/Scroll/Content/SaveButton
@onready var status_label: Label = $Margin/MainVBox/Status


func _ready() -> void:
	background.color = ThemeColors.BG
	back_button.text = Texts.t("back")
	title_label.text = Texts.t("settings_title")
	goals_title.text = Texts.t("settings_goals")
	calories_label.text = Texts.t("goal_calories")
	protein_label.text = Texts.t("goal_protein")
	fat_label.text = Texts.t("goal_fat")
	carbs_label.text = Texts.t("goal_carbs")
	water_label.text = Texts.t("goal_water")
	steps_title.text = Texts.t("settings_steps")
	reps_step_label.text = Texts.t("step_reps")
	rest_step_label.text = Texts.t("step_rest")
	feedback_title.text = Texts.t("settings_feedback")
	sound_check.text = Texts.t("sound_enabled")
	vibration_check.text = Texts.t("vibration_enabled")
	save_button.text = Texts.t("save")

	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	for input in [
		calories_input, protein_input, fat_input, carbs_input, water_input,
		reps_step_input, rest_step_input,
	]:
		input.text_changed.connect(_on_numeric_changed.bind(input))

	_load_values()
	var content := save_button.get_parent()
	var ai_panel := AiSettingsPanel.new()
	content.add_child(ai_panel)
	content.move_child(ai_panel, save_button.get_index())


func _load_values() -> void:
	var goals := Storage.get_goals()
	calories_input.text = str(int(goals.get("calories", 2500)))
	protein_input.text = str(int(goals.get("protein", 150)))
	fat_input.text = str(int(goals.get("fat", 70)))
	carbs_input.text = str(int(goals.get("carbs", 300)))
	water_input.text = str(int(goals.get("water", 2000)))
	reps_step_input.text = str(Storage.get_reps_step())
	rest_step_input.text = str(Storage.get_rest_step())
	sound_check.button_pressed = Storage.get_sound_enabled()
	vibration_check.button_pressed = Storage.get_vibration_enabled()


func _on_save_pressed() -> void:
	_save_values(true)


func _save_values(show_status: bool) -> void:
	Storage.save_goals({
		"calories": _number(calories_input),
		"protein": _number(protein_input),
		"fat": _number(fat_input),
		"carbs": _number(carbs_input),
		"water": _number(water_input),
	})
	Storage.set_steps(_number(reps_step_input), _number(rest_step_input))
	Storage.set_feedback(sound_check.button_pressed, vibration_check.button_pressed)
	if show_status:
		status_label.text = Texts.t("settings_saved")
		status_label.add_theme_color_override("font_color", ThemeColors.GREEN_BRIGHT)


func _on_numeric_changed(new_text: String, input: LineEdit) -> void:
	var filtered := ""
	for character in new_text:
		if character >= "0" and character <= "9":
			filtered += character
	if filtered != new_text:
		var caret := input.caret_column
		input.text = filtered
		input.caret_column = mini(caret, filtered.length())


func _number(input: LineEdit) -> int:
	return clampi(int(input.text), 0, 100000)


func _on_back_pressed() -> void:
	_save_values(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
