extends VBoxContainer

# Settings block: active plan, muscle-up variant, points per rep and goal coefficients.
# Values are saved together with the rest of the settings (save_silent, called by settings.gd).

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Plans = preload("res://scripts/plans.gd")

const COEF_KEYS := ["smart_multiplier", "raise_multiplier", "fail_threshold", "fail_multiplier"]
const COEF_TEXTS := {
	"smart_multiplier": "coef_smart",
	"raise_multiplier": "coef_raise",
	"fail_threshold": "coef_fail_threshold",
	"fail_multiplier": "coef_fail_multiplier",
}

var _plan_option: OptionButton
var _muscle_up_option: OptionButton
var _points_inputs := {}
var _coef_inputs := {}


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 20)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	box.add_child(_title(Texts.t("plan_settings_title")))

	_plan_option = _option()
	for plan_id in Plans.PLAN_IDS:
		_plan_option.add_item(Texts.t(Plans.plan_name_key(plan_id)))
	box.add_child(_row(Texts.t("plan_label"), _plan_option))

	_muscle_up_option = _option()
	_muscle_up_option.add_item(Texts.exercise_name("muscle_up_1"), 0)
	_muscle_up_option.add_item(Texts.exercise_name("muscle_up_2"), 1)
	box.add_child(_row(Texts.t("muscle_up_label"), _muscle_up_option))

	box.add_child(_title(Texts.t("points_settings_title"), 30))
	for exercise in Texts.EXERCISES:
		var input := _line_edit()
		_points_inputs[str(exercise.id)] = input
		box.add_child(_row(str(exercise.name), input))

	box.add_child(_title(Texts.t("goal_coefs_title"), 30))
	for key in COEF_KEYS:
		var input := _line_edit()
		input.placeholder_text = "1.05"
		_coef_inputs[key] = input
		box.add_child(_row(Texts.t(COEF_TEXTS[key]), input))

	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)
	_load_values()


func _load_values() -> void:
	_plan_option.select(maxi(0, Plans.PLAN_IDS.find(Storage.get_plan_id())))
	_muscle_up_option.select(1 if Storage.get_muscle_up_variant() == "muscle_up_2" else 0)
	var table := Storage.get_points_table()
	for exercise_id in _points_inputs:
		_points_inputs[exercise_id].text = str(int(table.get(exercise_id, 1)))
	var coefs := Storage.get_goal_settings()
	for key in COEF_KEYS:
		_coef_inputs[key].text = "%.2f" % float(coefs.get(key, 1.0))


func save_silent() -> void:
	Storage.set_plan_id(Plans.PLAN_IDS[_plan_option.selected])
	Storage.set_muscle_up_variant("muscle_up_2" if _muscle_up_option.selected == 1 else "muscle_up_1")
	var table := {}
	for exercise_id in _points_inputs:
		table[exercise_id] = int(_points_inputs[exercise_id].text)
	Storage.set_points_table(table)
	var coefs := {}
	for key in COEF_KEYS:
		coefs[key] = _to_float(_coef_inputs[key].text, Storage.get_goal_settings().get(key, 1.0))
	Storage.set_goal_settings(coefs)


func _to_float(text: String, fallback: Variant) -> float:
	var clean := text.strip_edges().replace(",", ".")
	return float(clean) if clean.is_valid_float() else float(fallback)


func _title(text: String, font_size: int = 34) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _row(caption: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = caption
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", ThemeColors.MUTED)
	row.add_child(label)
	control.custom_minimum_size = Vector2(260, 84)
	control.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(control)
	return row


func _option() -> OptionButton:
	var option := OptionButton.new()
	option.add_theme_font_size_override("font_size", 28)
	return option


func _line_edit() -> LineEdit:
	var input := LineEdit.new()
	input.add_theme_font_size_override("font_size", 30)
	input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	return input
