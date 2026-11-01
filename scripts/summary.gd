extends Control

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")

@onready var title_label: Label = $Margin/MainVBox/Title
@onready var exercise_label: Label = $Margin/MainVBox/Exercise
@onready var sets_caption: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/SetsCaption
@onready var sets_value: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/SetsValue
@onready var reps_caption: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/RepsCaption
@onready var reps_value: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/RepsValue
@onready var total_caption: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/TotalRow/Caption
@onready var total_value: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/TotalRow/Value
@onready var work_caption: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/WorkRow/Caption
@onready var work_value: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/WorkRow/Value
@onready var rest_caption: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/RestRow/Caption
@onready var rest_value: Label = $Margin/MainVBox/SummaryPanel/Margin/VBox/RestRow/Value
@onready var done_button: Button = $Margin/MainVBox/DoneButton


func _ready() -> void:
	title_label.text = Texts.t("summary_title")
	sets_caption.text = Texts.t("summary_sets")
	reps_caption.text = Texts.t("summary_reps")
	total_caption.text = Texts.t("summary_total")
	work_caption.text = Texts.t("summary_work")
	rest_caption.text = Texts.t("summary_rest")
	done_button.text = Texts.t("done")
	done_button.pressed.connect(_on_done_pressed)
	done_button.theme_type_variation = &"SuccessButton"
	for value_label in [sets_value, reps_value, total_value, work_value, rest_value]:
		value_label.add_theme_color_override("font_color", ThemeColors.GOLD)

	var data: Dictionary = Storage.last_summary
	var sets := int(data.get("sets", 0))
	var reps := int(data.get("reps", 0))
	var work_seconds := int(data.get("work_seconds", 0))
	var rest_seconds := int(data.get("rest_seconds", 0))
	var total_seconds := int(data.get("total_seconds", work_seconds + rest_seconds))

	exercise_label.text = str(data.get("exercise_name", ""))
	sets_value.text = str(sets)
	reps_value.text = str(reps)
	total_value.text = Texts.format_time(total_seconds)
	work_value.text = Texts.format_time(work_seconds)
	rest_value.text = Texts.format_time(rest_seconds)


func _on_done_pressed() -> void:
	Storage.last_summary = {}
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
