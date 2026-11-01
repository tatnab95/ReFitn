extends VBoxContainer

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const AiSettings = preload("res://scripts/ai_settings.gd")

var _key_input: LineEdit
var _url_input: LineEdit
var _model_input: LineEdit
var _show_button: Button
var _status_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build()
	_load_values()


func _build() -> void:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var title := _label(Texts.t("ai_title"), 34, ThemeColors.TEXT)
	box.add_child(title)

	box.add_child(_label(Texts.t("ai_key_label"), 26, ThemeColors.MUTED))
	var key_row := HBoxContainer.new()
	key_row.add_theme_constant_override("separation", 10)
	_key_input = LineEdit.new()
	_key_input.secret = true
	_key_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_key_input.custom_minimum_size = Vector2(0, 80)
	_key_input.add_theme_font_size_override("font_size", 28)
	_show_button = Button.new()
	_show_button.text = Texts.t("ai_show")
	_show_button.custom_minimum_size = Vector2(170, 80)
	_show_button.add_theme_font_size_override("font_size", 26)
	_show_button.pressed.connect(_on_toggle_secret)
	key_row.add_child(_key_input)
	key_row.add_child(_show_button)
	box.add_child(key_row)

	box.add_child(_label(Texts.t("ai_url_label"), 26, ThemeColors.MUTED))
	_url_input = LineEdit.new()
	_url_input.custom_minimum_size = Vector2(0, 80)
	_url_input.add_theme_font_size_override("font_size", 28)
	box.add_child(_url_input)

	box.add_child(_label(Texts.t("ai_model_label"), 26, ThemeColors.MUTED))
	_model_input = LineEdit.new()
	_model_input.custom_minimum_size = Vector2(0, 80)
	_model_input.add_theme_font_size_override("font_size", 28)
	box.add_child(_model_input)

	var hint := _label(Texts.t("ai_hint"), 24, ThemeColors.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

	var save_button := Button.new()
	save_button.text = Texts.t("save")
	save_button.custom_minimum_size = Vector2(0, 88)
	save_button.add_theme_font_size_override("font_size", 30)
	save_button.pressed.connect(_on_save_pressed)
	box.add_child(save_button)

	_status_label = _label("", 26, ThemeColors.GREEN_BRIGHT)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)

	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _load_values() -> void:
	var settings := AiSettings.load_settings()
	_key_input.text = str(settings.api_key)
	_url_input.text = str(settings.base_url)
	_model_input.text = str(settings.model)


func _on_toggle_secret() -> void:
	_key_input.secret = not _key_input.secret
	_show_button.text = Texts.t("ai_show") if _key_input.secret else Texts.t("ai_hide")


func _on_save_pressed() -> void:
	var url := _url_input.text.strip_edges()
	if url.is_empty():
		url = AiSettings.DEFAULT_URL
	if not (url.begins_with("https://") or url.begins_with("http://")):
		_show_status(Texts.t("ai_bad_url"), true)
		return
	var error := AiSettings.save_settings({
		"api_key": _key_input.text.strip_edges(),
		"base_url": url,
		"model": _model_input.text.strip_edges(),
	})
	if error == OK:
		_url_input.text = url
		_show_status(Texts.t("ai_saved"), false)
	else:
		_show_status(Texts.t("ai_save_failed"), true)


func _show_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", ThemeColors.ERROR if is_error else ThemeColors.GREEN_BRIGHT)
