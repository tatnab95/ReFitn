extends VBoxContainer

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")

const STEP_MINUTES := 15

var _toggle: CheckButton
var _time_label: Label
var _status_label: Label
var _settings_button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 20)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	box.add_child(_title(Texts.t("reminder_title")))
	_toggle = CheckButton.new()
	_toggle.text = Texts.t("reminder_enabled")
	_toggle.add_theme_font_size_override("font_size", 30)
	_toggle.button_pressed = Storage.get_reminder_enabled()
	_toggle.toggled.connect(_on_toggled)
	box.add_child(_toggle)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var minus := _step_button("−", -STEP_MINUTES)
	var plus := _step_button("+", STEP_MINUTES)
	_time_label = Label.new()
	_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 40)
	_time_label.add_theme_color_override("font_color", ThemeColors.GOLD)
	row.add_child(minus)
	row.add_child(_time_label)
	row.add_child(plus)
	box.add_child(row)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 26)
	_status_label.add_theme_color_override("font_color", ThemeColors.MUTED)
	box.add_child(_status_label)

	_settings_button = Button.new()
	_settings_button.text = Texts.t("notif_open_settings")
	_settings_button.custom_minimum_size = Vector2(0, 88)
	_settings_button.add_theme_font_size_override("font_size", 30)
	_settings_button.theme_type_variation = &"SecondaryButton"
	_settings_button.visible = false
	_settings_button.pressed.connect(Notifier.open_settings)
	box.add_child(_settings_button)

	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)

	Notifier.permission_granted.connect(_on_permission_granted)
	Notifier.permission_denied.connect(_on_permission_denied)
	_refresh_time()
	if OS.get_name() != "Android":
		_show_status(Texts.t("notif_unsupported"), false)


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 34)
	return label


func _step_button(text: String, delta: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 96)
	button.set_meta("compact", true)
	button.add_theme_font_size_override("font_size", 40)
	button.pressed.connect(_shift.bind(delta))
	return button


func _refresh_time() -> void:
	var minutes := Storage.get_reminder_minutes()
	_time_label.text = Texts.t("reminder_time_format") % [minutes / 60, minutes % 60]


func _shift(delta: int) -> void:
	var minutes := posmod(Storage.get_reminder_minutes() + delta, 1440)
	Storage.set_reminder(Storage.get_reminder_enabled(), minutes)
	_refresh_time()
	Notifier.refresh_daily()


func _on_toggled(enabled: bool) -> void:
	Storage.set_reminder(enabled, Storage.get_reminder_minutes())
	if enabled and not Notifier.has_permission():
		_show_status(Texts.t("notif_rationale"), false)
		Notifier.request_permission()
	Notifier.refresh_daily()


func _on_permission_granted() -> void:
	_settings_button.visible = false
	_show_status("", false)


func _on_permission_denied() -> void:
	_show_status(Texts.t("notif_denied_hint"), true)
	_settings_button.visible = true
	if _toggle.button_pressed and not Notifier.has_permission():
		Storage.set_reminder(false, Storage.get_reminder_minutes())
		_toggle.set_pressed_no_signal(false)


func _show_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", ThemeColors.ERROR if is_error else ThemeColors.MUTED)
