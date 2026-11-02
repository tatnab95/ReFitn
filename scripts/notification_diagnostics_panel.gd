extends VBoxContainer

# Settings block: shows why notifications may not arrive and offers quick fixes.

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")

var _permission_label: Label
var _exact_label: Label
var _battery_label: Label
var _status_label: Label
var _request_button: Button
var _exact_button: Button
var _battery_button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 20)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	box.add_child(_title(Texts.t("diag_title")))
	_permission_label = _line()
	_exact_label = _line()
	_battery_label = _line()
	box.add_child(_permission_label)
	box.add_child(_exact_label)
	box.add_child(_battery_label)

	var hint := _line()
	hint.text = Texts.t("diag_battery_hint")
	hint.add_theme_color_override("font_color", ThemeColors.MUTED)
	box.add_child(hint)

	_request_button = _action(Texts.t("diag_request"), _on_request_pressed)
	_exact_button = _action(Texts.t("diag_request_exact"), _on_exact_pressed)
	_battery_button = _action(Texts.t("diag_request_battery"), _on_battery_pressed)
	box.add_child(_request_button)
	box.add_child(_exact_button)
	box.add_child(_battery_button)
	box.add_child(_action(Texts.t("diag_open_app"), Notifier.open_settings))
	box.add_child(_action(Texts.t("diag_test"), _on_test_pressed))

	_status_label = _line()
	_status_label.add_theme_color_override("font_color", ThemeColors.MUTED)
	box.add_child(_status_label)

	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)

	Notifier.permission_granted.connect(_refresh)
	Notifier.permission_denied.connect(_refresh)
	Notifier.initialized.connect(_refresh)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_refresh()


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 34)
	return label


func _line() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 26)
	return label


func _action(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 88)
	button.add_theme_font_size_override("font_size", 30)
	button.theme_type_variation = &"SecondaryButton"
	button.pressed.connect(handler)
	return button


func _refresh() -> void:
	if OS.get_name() != "Android":
		_permission_label.text = Texts.t("notif_unsupported")
		_exact_label.text = ""
		_battery_label.text = ""
		for button in [_request_button, _exact_button, _battery_button]:
			button.visible = false
		return

	var granted := Notifier.has_permission()
	_permission_label.text = Texts.t("diag_permission") % (
		Texts.t("diag_allowed") if granted else Texts.t("diag_denied")
	)
	_permission_label.add_theme_color_override("font_color", ThemeColors.GREEN_BRIGHT if granted else ThemeColors.ERROR)
	_request_button.visible = not granted

	var exact := Notifier.has_exact_alarm_permission()
	_exact_label.text = Texts.t("diag_exact") % (
		Texts.t("diag_allowed") if exact else Texts.t("diag_denied")
	) + ("" if exact else " · " + Texts.t("diag_exact_hint"))
	_exact_label.add_theme_color_override("font_color", ThemeColors.MUTED if exact else ThemeColors.GOLD)
	_exact_button.visible = not exact

	var exempt := Notifier.has_battery_exemption()
	_battery_label.text = Texts.t("diag_battery") % (
		Texts.t("diag_battery_off") if exempt else Texts.t("diag_battery_on")
	)
	_battery_label.add_theme_color_override("font_color", ThemeColors.MUTED if exempt else ThemeColors.GOLD)
	_battery_button.visible = not exempt


func _on_request_pressed() -> void:
	Notifier.request_permission()


func _on_exact_pressed() -> void:
	Notifier.request_exact_alarm_permission()


func _on_battery_pressed() -> void:
	Notifier.request_battery_exemption()


func _on_test_pressed() -> void:
	if Notifier.schedule_test(10):
		_show_status(Texts.t("diag_test_sent"), ThemeColors.GREEN_BRIGHT)
	else:
		_show_status(Texts.t("diag_test_no_permission"), ThemeColors.ERROR)


func _show_status(message: String, color: Color) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)
