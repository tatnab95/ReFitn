extends Control

# Overlay for photo recognition: loading state, error message, and a review
# form. Nothing is added to the diary until the user presses "Добавить".

signal entry_confirmed(entry: Dictionary)

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const AiSettings = preload("res://scripts/ai_settings.gd")
const FoodPhoto = preload("res://scripts/food_photo.gd")

const SETTINGS_SCENE := "res://scenes/settings.tscn"

var _photo: FoodPhoto
var _loading_box: VBoxContainer
var _message_box: VBoxContainer
var _review_box: VBoxContainer
var _message_label: Label
var _settings_button: Button
var _bar: ProgressBar
var _bar_tween: Tween
var _name_input: LineEdit
var _number_inputs := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_photo = FoodPhoto.new()
	add_child(_photo)
	_photo.started.connect(_on_started)
	_photo.succeeded.connect(_on_succeeded)
	_photo.failed.connect(_on_failed)
	_build()


func open_photo() -> void:
	if _photo.is_busy():
		return
	var settings := AiSettings.load_settings()
	if str(settings.api_key).is_empty():
		_show_message(Texts.t("photo_no_key"), true)
		return
	if str(settings.model).is_empty():
		_show_message(Texts.t("photo_no_model"), true)
		return
	_photo.pick_photo()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = ThemeColors.DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	margin.add_child(stack)

	_loading_box = _make_box(stack)
	_loading_box.add_child(_label(Texts.t("photo_loading"), 36, ThemeColors.TEXT))
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 28)
	_bar.max_value = 100.0
	_loading_box.add_child(_bar)
	_loading_box.add_child(_action_button(Texts.t("cancel"), _on_cancel_pressed, false))

	_message_box = _make_box(stack)
	_message_label = _label("", 30, ThemeColors.ERROR)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_box.add_child(_message_label)
	_settings_button = _action_button(Texts.t("photo_open_settings"), _on_settings_pressed, true)
	_message_box.add_child(_settings_button)
	_message_box.add_child(_action_button(Texts.t("photo_close"), close, false))

	_review_box = _make_box(stack)
	_review_box.add_child(_label(Texts.t("photo_review_title"), 36, ThemeColors.TEXT))
	var note := _label(Texts.t("photo_review_note"), 26, ThemeColors.GOLD_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_review_box.add_child(note)
	_name_input = LineEdit.new()
	_name_input.placeholder_text = Texts.t("entry_name_placeholder")
	_name_input.custom_minimum_size = Vector2(0, 90)
	_name_input.add_theme_font_size_override("font_size", 32)
	_review_box.add_child(_name_input)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	_review_box.add_child(grid)
	for key in ["calories", "protein", "fat", "carbs"]:
		grid.add_child(_label(Texts.t(key), 30, ThemeColors.MUTED))
		var input := LineEdit.new()
		input.custom_minimum_size = Vector2(0, 80)
		input.add_theme_font_size_override("font_size", 30)
		input.text_changed.connect(_on_numeric_changed.bind(input))
		grid.add_child(input)
		_number_inputs[key] = input
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	var cancel := _action_button(Texts.t("cancel"), close, false)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var add := _action_button(Texts.t("photo_add"), _on_add_pressed, true)
	add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.theme_type_variation = &"PrimaryButton"
	buttons.add_child(cancel)
	buttons.add_child(add)
	_review_box.add_child(buttons)


func _make_box(parent: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.visible = false
	parent.add_child(box)
	return box


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _action_button(text: String, handler: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 88)
	button.add_theme_font_size_override("font_size", 30)
	if primary:
		button.theme_type_variation = &"PrimaryButton"
	button.pressed.connect(handler)
	return button


func _show_box(box: Control) -> void:
	visible = true
	for child in [_loading_box, _message_box, _review_box]:
		child.visible = child == box


func _show_message(text: String, to_settings: bool) -> void:
	_stop_bar()
	_message_label.text = text
	_settings_button.visible = to_settings
	_show_box(_message_box)


func _on_started() -> void:
	_show_box(_loading_box)
	_stop_bar()
	_bar.value = 0.0
	_bar_tween = create_tween().set_loops()
	_bar_tween.tween_property(_bar, "value", 100.0, 1.2)
	_bar_tween.tween_property(_bar, "value", 0.0, 0.0)


func _on_succeeded(result: Dictionary) -> void:
	_stop_bar()
	_name_input.text = str(result.get("name", ""))
	for key in _number_inputs:
		_number_inputs[key].text = str(int(result.get(key, 0)))
	_show_box(_review_box)


func _on_failed(message: String) -> void:
	_show_message(message, false)


func _on_add_pressed() -> void:
	var entry_name := _name_input.text.strip_edges()
	if entry_name.is_empty():
		entry_name = Texts.t("unnamed_entry")
	var entry := {"name": entry_name}
	for key in _number_inputs:
		entry[key] = clampi(int(_number_inputs[key].text), 0, 100000)
	entry_confirmed.emit(entry)
	close()


func _on_cancel_pressed() -> void:
	_photo.cancel()
	close()


func _on_settings_pressed() -> void:
	close()
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func close() -> void:
	_stop_bar()
	if _photo.is_busy():
		_photo.cancel()
	visible = false


func _stop_bar() -> void:
	if _bar_tween != null and _bar_tween.is_valid():
		_bar_tween.kill()
	_bar_tween = null


func _on_numeric_changed(new_text: String, input: LineEdit) -> void:
	var filtered := ""
	for character in new_text:
		if character >= "0" and character <= "9":
			filtered += character
	if filtered != new_text:
		var caret := input.caret_column
		input.text = filtered
		input.caret_column = mini(caret, filtered.length())
