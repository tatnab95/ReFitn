extends Control

# Daily goal editor: points or reps of one exercise, typed value or "Умная цель".

signal saved

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Goals = preload("res://scripts/goals.gd")

var _type_option: OptionButton
var _exercise_option: OptionButton
var _value_input: LineEdit
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = ThemeColors.DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	box.add_child(_label(Texts.t("goal_title"), 40, ThemeColors.TEXT))

	_type_option = OptionButton.new()
	_type_option.add_item(Texts.t("goal_type_points"), 0)
	_type_option.add_item(Texts.t("goal_type_reps"), 1)
	_type_option.add_theme_font_size_override("font_size", 30)
	_type_option.item_selected.connect(_on_type_selected)
	box.add_child(_type_option)

	_exercise_option = OptionButton.new()
	_exercise_option.add_theme_font_size_override("font_size", 30)
	for exercise in Texts.EXERCISES:
		_exercise_option.add_item(str(exercise.name))
	_exercise_option.item_selected.connect(_on_exercise_selected)
	box.add_child(_exercise_option)

	_value_input = LineEdit.new()
	_value_input.placeholder_text = Texts.t("goal_value_placeholder")
	_value_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_value_input.add_theme_font_size_override("font_size", 36)
	_value_input.custom_minimum_size = Vector2(0, 96)
	_value_input.text_changed.connect(_on_value_changed)
	box.add_child(_value_input)

	_hint = _label("", 26, ThemeColors.MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint)

	var smart := Button.new()
	smart.text = Texts.t("goal_smart")
	smart.theme_type_variation = &"SecondaryButton"
	smart.custom_minimum_size = Vector2(0, 88)
	smart.add_theme_font_size_override("font_size", 30)
	smart.pressed.connect(_on_smart_pressed)
	box.add_child(smart)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var cancel := Button.new()
	cancel.text = Texts.t("cancel")
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size = Vector2(0, 88)
	cancel.add_theme_font_size_override("font_size", 30)
	cancel.pressed.connect(hide)
	row.add_child(cancel)
	var save := Button.new()
	save.text = Texts.t("goal_save")
	save.theme_type_variation = &"SuccessButton"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size = Vector2(0, 88)
	save.add_theme_font_size_override("font_size", 30)
	save.pressed.connect(_on_save_pressed)
	row.add_child(save)

	visible = false


func open() -> void:
	var goal := Storage.get_daily_goal()
	var is_reps := str(goal.get("type", "points")) == "reps"
	_type_option.select(1 if is_reps else 0)
	_exercise_option.select(_exercise_index(str(goal.get("exercise", "pullups"))))
	var value := int(goal.get("value", 0))
	_value_input.text = str(value) if value > 0 else ""
	_refresh_controls()
	show()


func _exercise_index(exercise_id: String) -> int:
	for index in range(Texts.EXERCISES.size()):
		if str(Texts.EXERCISES[index].id) == exercise_id:
			return index
	return 0


func _current_type() -> String:
	return "reps" if _type_option.selected == 1 else "points"


func _current_exercise() -> String:
	return str(Texts.EXERCISES[_exercise_option.selected].id)


func _refresh_controls() -> void:
	_exercise_option.disabled = _type_option.selected == 0
	_hint.text = Texts.t("goal_smart_hint") % Goals.smart_value(_current_type(), _current_exercise())


func _on_type_selected(_index: int) -> void:
	_refresh_controls()


func _on_exercise_selected(_index: int) -> void:
	_refresh_controls()


func _on_value_changed(new_text: String) -> void:
	var filtered := ""
	for character in new_text:
		if character >= "0" and character <= "9":
			filtered += character
	if filtered != new_text:
		var caret := _value_input.caret_column
		_value_input.text = filtered
		_value_input.caret_column = mini(caret, filtered.length())


func _on_smart_pressed() -> void:
	_apply(Goals.smart_value(_current_type(), _current_exercise()))


func _on_save_pressed() -> void:
	_apply(clampi(int(_value_input.text), 0, 100000))


func _apply(value: int) -> void:
	Storage.set_daily_goal(_current_type(), _current_exercise(), value)
	hide()
	saved.emit()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
