extends VBoxContainer

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const AiSettings = preload("res://scripts/ai_settings.gd")

const CUSTOM_META := "__custom__"
const TIMEOUT_SECONDS := 25.0

var _key_input: LineEdit
var _url_input: LineEdit
var _search_input: LineEdit
var _model_option: OptionButton
var _custom_model_input: LineEdit
var _vision_hint_label: Label
var _show_button: Button
var _load_models_button: Button
var _check_button: Button
var _status_label: Label
var _http: HTTPRequest
var _request_mode := ""
var _models: Array = []
var _has_vision_metadata := false
var _updating_ui := false


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SECONDS
	_http.request_completed.connect(_on_http_completed)
	add_child(_http)
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
	_key_input.virtual_keyboard_enabled = true
	_key_input.virtual_keyboard_show_on_focus = true
	_key_input.add_theme_font_size_override("font_size", 28)
	_show_button = Button.new()
	_show_button.text = Texts.t("ai_show")
	_show_button.custom_minimum_size = Vector2(170, 80)
	_show_button.set_meta("compact", true)
	_show_button.add_theme_font_size_override("font_size", 26)
	_show_button.pressed.connect(_on_toggle_secret)
	key_row.add_child(_key_input)
	key_row.add_child(_show_button)
	box.add_child(key_row)

	box.add_child(_label(Texts.t("ai_url_label"), 26, ThemeColors.MUTED))
	_url_input = LineEdit.new()
	_url_input.custom_minimum_size = Vector2(0, 80)
	_url_input.virtual_keyboard_enabled = true
	_url_input.virtual_keyboard_show_on_focus = true
	_url_input.add_theme_font_size_override("font_size", 28)
	box.add_child(_url_input)

	_load_models_button = Button.new()
	_load_models_button.text = Texts.t("ai_load_models")
	_load_models_button.custom_minimum_size = Vector2(0, 88)
	_load_models_button.theme_type_variation = &"SecondaryButton"
	_load_models_button.add_theme_font_size_override("font_size", 28)
	_load_models_button.pressed.connect(_on_load_models_pressed)
	box.add_child(_load_models_button)

	box.add_child(_label(Texts.t("ai_model_label"), 26, ThemeColors.MUTED))
	_search_input = LineEdit.new()
	_search_input.placeholder_text = Texts.t("ai_model_search")
	_search_input.custom_minimum_size = Vector2(0, 76)
	_search_input.virtual_keyboard_enabled = true
	_search_input.virtual_keyboard_show_on_focus = true
	_search_input.add_theme_font_size_override("font_size", 26)
	_search_input.text_changed.connect(_on_search_changed)
	box.add_child(_search_input)

	_model_option = OptionButton.new()
	_model_option.custom_minimum_size = Vector2(0, 88)
	_model_option.clip_text = true
	_model_option.add_theme_font_size_override("font_size", 28)
	_model_option.get_popup().max_size = Vector2i(0, 720)
	_model_option.item_selected.connect(_on_model_option_selected)
	box.add_child(_model_option)

	_vision_hint_label = _label(Texts.t("ai_vision_hint"), 24, ThemeColors.GOLD_SOFT)
	_vision_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vision_hint_label.visible = false
	box.add_child(_vision_hint_label)

	box.add_child(_label(Texts.t("ai_other_model_label"), 26, ThemeColors.MUTED))
	_custom_model_input = LineEdit.new()
	_custom_model_input.placeholder_text = Texts.t("ai_other_model_placeholder")
	_custom_model_input.custom_minimum_size = Vector2(0, 80)
	_custom_model_input.virtual_keyboard_enabled = true
	_custom_model_input.virtual_keyboard_show_on_focus = true
	_custom_model_input.add_theme_font_size_override("font_size", 28)
	_custom_model_input.text_changed.connect(_on_custom_model_changed)
	box.add_child(_custom_model_input)

	_check_button = Button.new()
	_check_button.text = Texts.t("ai_check_button")
	_check_button.custom_minimum_size = Vector2(0, 88)
	_check_button.theme_type_variation = &"SecondaryButton"
	_check_button.add_theme_font_size_override("font_size", 28)
	_check_button.pressed.connect(_on_check_pressed)
	box.add_child(_check_button)

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
	_updating_ui = true
	var settings := AiSettings.load_settings()
	var cache := AiSettings.load_models_cache()
	_key_input.text = str(settings.api_key)
	_url_input.text = str(settings.base_url)
	_models = cache.models
	_has_vision_metadata = bool(cache.has_vision_metadata)
	var saved_model := str(settings.model).strip_edges()
	_rebuild_model_options(saved_model)
	if not saved_model.is_empty() and saved_model not in _models:
		_custom_model_input.text = saved_model
	else:
		_custom_model_input.text = ""
	_updating_ui = false


func _rebuild_model_options(selected_model: String) -> void:
	_updating_ui = true
	_model_option.clear()
	var filter := _search_input.text.strip_edges().to_lower()
	_search_input.visible = not _models.is_empty()
	_vision_hint_label.visible = (not _models.is_empty()) and (not _has_vision_metadata)

	var matched_index := -1
	for m in _models:
		var model_id := str(m)
		if not filter.is_empty() and not model_id.to_lower().contains(filter):
			continue
		_model_option.add_item(model_id)
		var idx := _model_option.item_count - 1
		_model_option.set_item_metadata(idx, model_id)
		if model_id == selected_model:
			matched_index = idx

	_model_option.add_item(Texts.t("ai_other_model_option"))
	var custom_idx := _model_option.item_count - 1
	_model_option.set_item_metadata(custom_idx, CUSTOM_META)

	if matched_index >= 0:
		_model_option.select(matched_index)
	else:
		_model_option.select(custom_idx)
	_updating_ui = false


func _current_model() -> String:
	var custom := _custom_model_input.text.strip_edges()
	if not custom.is_empty():
		return custom
	var idx := _model_option.selected
	if idx >= 0 and idx < _model_option.item_count:
		var meta := str(_model_option.get_item_metadata(idx))
		if meta != CUSTOM_META:
			return meta
	return ""


func _on_search_changed(_new_text: String) -> void:
	var current := _current_model()
	_rebuild_model_options(current)


func _on_model_option_selected(index: int) -> void:
	if _updating_ui:
		return
	var meta := str(_model_option.get_item_metadata(index))
	_updating_ui = true
	if meta != CUSTOM_META:
		_custom_model_input.text = ""
	_updating_ui = false
	save_silent()


func _on_custom_model_changed(new_text: String) -> void:
	if _updating_ui:
		return
	var trimmed := new_text.strip_edges()
	_updating_ui = true
	if not trimmed.is_empty():
		for i in range(_model_option.item_count):
			if str(_model_option.get_item_metadata(i)) == CUSTOM_META:
				_model_option.select(i)
				break
	_updating_ui = false
	save_silent()


func _on_toggle_secret() -> void:
	_key_input.secret = not _key_input.secret
	_show_button.text = Texts.t("ai_show") if _key_input.secret else Texts.t("ai_hide")


func _validated_url() -> String:
	var url := _url_input.text.strip_edges()
	if url.is_empty():
		url = AiSettings.DEFAULT_URL
	if not (url.begins_with("https://") or url.begins_with("http://")):
		return ""
	return url


func _on_load_models_pressed() -> void:
	var url := _validated_url()
	if url.is_empty():
		_show_status(Texts.t("ai_bad_url"), true)
		return
	var key := _key_input.text.strip_edges()
	if key.is_empty():
		_show_status(Texts.t("ai_no_key"), true)
		return
	if not _request_mode.is_empty():
		_http.cancel_request()
		_request_mode = ""

	var headers := PackedStringArray([
		"Authorization: Bearer " + key,
	])
	var models_url := url.rstrip("/") + "/models"
	var err := _http.request(models_url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_show_status(Texts.t("ai_check_no_network"), true)
		return
	_request_mode = "models"
	_set_busy(true)
	_show_status(Texts.t("ai_loading_models"), false, true)


func _on_check_pressed() -> void:
	var url := _validated_url()
	if url.is_empty():
		_show_status(Texts.t("ai_bad_url"), true)
		return
	var key := _key_input.text.strip_edges()
	if key.is_empty():
		_show_status(Texts.t("ai_no_key"), true)
		return
	var model := _current_model()
	if model.is_empty():
		_show_status(Texts.t("ai_no_model"), true)
		return
	save_silent()
	if not _request_mode.is_empty():
		_http.cancel_request()
		_request_mode = ""

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + key,
	])
	var body := JSON.stringify({
		"model": model,
		"messages": [{"role": "user", "content": "Ответь одним словом: ок"}],
		"max_tokens": 8,
	})
	var chat_url := url.rstrip("/") + "/chat/completions"
	var err := _http.request(chat_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_show_status(Texts.t("ai_check_no_network"), true)
		return
	_request_mode = "check"
	_set_busy(true)
	_show_status(Texts.t("ai_checking"), false, true)


func _on_http_completed(result: int, code: int, _headers: PackedStringArray, response: PackedByteArray) -> void:
	var mode := _request_mode
	_request_mode = ""
	_set_busy(false)
	if mode.is_empty():
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_show_status(Texts.t("ai_check_no_network"), true)
		return
	if code == 401 or code == 403:
		_show_status(Texts.t("ai_check_bad_key"), true)
		return
	if code == 429 or code == 402:
		_show_status(Texts.t("ai_check_rate_limit"), true)
		return

	var body_text := response.get_string_from_utf8()
	if mode == "models":
		if code < 200 or code >= 300:
			_show_status(_classify_error(code, body_text), true)
			return
		var parsed := AiSettings.parse_models_response(body_text)
		_models = parsed.models
		_has_vision_metadata = bool(parsed.has_vision_metadata)
		var url := _validated_url()
		AiSettings.save_models_cache(_models, _has_vision_metadata, url)
		var current := _current_model()
		if current.is_empty() and not _models.is_empty():
			current = str(_models[0])
		_rebuild_model_options(current)
		save_silent()
		if _models.is_empty():
			_show_status(Texts.t("ai_models_empty"), true)
		else:
			_show_status(Texts.t("ai_models_loaded") % _models.size(), false)
	elif mode == "check":
		if code >= 200 and code < 300:
			_show_status(Texts.t("ai_check_ok"), false)
		else:
			_show_status(_classify_error(code, body_text), true)


func _classify_error(code: int, body_text: String) -> String:
	var lower := body_text.to_lower()
	if code == 401 or code == 403 or lower.contains("invalid_api_key") or lower.contains("unauthorized"):
		return Texts.t("ai_check_bad_key")
	if code == 429 or code == 402 or lower.contains("quota") or lower.contains("rate_limit") or lower.contains("rate limit") or lower.contains("insufficient"):
		return Texts.t("ai_check_rate_limit")
	if code == 404 or lower.contains("model_not_found") or lower.contains("does not exist") or lower.contains("not found") or lower.contains("unknown model"):
		return Texts.t("ai_check_model_not_found")
	if code == 400 or code == 422:
		if lower.contains("model"):
			return Texts.t("ai_check_model_not_found")
	return Texts.t("ai_check_http_error") % code


func _set_busy(busy: bool) -> void:
	_load_models_button.disabled = busy
	_check_button.disabled = busy


func save_silent() -> bool:
	var url := _validated_url()
	if url.is_empty():
		return false
	var error := AiSettings.save_settings({
		"api_key": _key_input.text.strip_edges(),
		"base_url": url,
		"model": _current_model(),
	})
	if error == OK:
		_url_input.text = url
		return true
	return false


func _on_save_pressed() -> void:
	var url := _validated_url()
	if url.is_empty():
		_show_status(Texts.t("ai_bad_url"), true)
		return
	if save_silent():
		_show_status(Texts.t("ai_saved"), false)
	else:
		_show_status(Texts.t("ai_save_failed"), true)


func _show_status(message: String, is_error: bool, is_neutral: bool = false) -> void:
	_status_label.text = message
	var color := ThemeColors.MUTED if is_neutral else (ThemeColors.ERROR if is_error else ThemeColors.GREEN_BRIGHT)
	_status_label.add_theme_color_override("font_color", color)
