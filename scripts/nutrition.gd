extends Control

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")

@onready var background: ColorRect = $Background
@onready var back_button: Button = $Margin/MainVBox/Header/BackButton
@onready var title_label: Label = $Margin/MainVBox/Header/Title
@onready var entry_title: Label = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/EntryTitle
@onready var name_input: LineEdit = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/NameInput
@onready var calories_label: Label = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/CaloriesLabel
@onready var calories_input: LineEdit = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/CaloriesInput
@onready var protein_label: Label = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/ProteinLabel
@onready var protein_input: LineEdit = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/ProteinInput
@onready var fat_label: Label = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/FatLabel
@onready var fat_input: LineEdit = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/FatInput
@onready var carbs_label: Label = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/CarbsLabel
@onready var carbs_input: LineEdit = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Fields/CarbsInput
@onready var hint_label: Label = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/Hint
@onready var add_button: Button = $Margin/MainVBox/Scroll/Content/EntryPanel/Margin/VBox/AddButton
@onready var today_title: Label = $Margin/MainVBox/Scroll/Content/TodayTitle
@onready var today_list: VBoxContainer = $Margin/MainVBox/Scroll/Content/TodayList
@onready var water_title: Label = $Margin/MainVBox/Scroll/Content/WaterPanel/Margin/VBox/WaterTitle
@onready var water_value: Label = $Margin/MainVBox/Scroll/Content/WaterPanel/Margin/VBox/WaterValue
@onready var water_250_button: Button = $Margin/MainVBox/Scroll/Content/WaterPanel/Margin/VBox/WaterButtons/Water250Button
@onready var water_500_button: Button = $Margin/MainVBox/Scroll/Content/WaterPanel/Margin/VBox/WaterButtons/Water500Button
@onready var manual_water_button: Button = $Margin/MainVBox/Scroll/Content/WaterPanel/Margin/VBox/ManualWaterButton
@onready var status_label: Label = $Margin/MainVBox/Status
@onready var number_dialog = $NumberInputDialog

var manual_water_mode := false


func _ready() -> void:
	background.color = ThemeColors.BG
	back_button.text = Texts.t("back")
	title_label.text = Texts.t("nutrition_title")
	entry_title.text = Texts.t("entry_form_title")
	name_input.placeholder_text = Texts.t("entry_name")
	calories_label.text = Texts.t("calories")
	protein_label.text = Texts.t("protein")
	fat_label.text = Texts.t("fat")
	carbs_label.text = Texts.t("carbs")
	hint_label.text = Texts.t("nutrition_hint")
	add_button.text = Texts.t("add_entry")
	today_title.text = Texts.t("today_title")
	water_title.text = Texts.t("water_title")
	water_250_button.text = Texts.t("add_250")
	water_500_button.text = Texts.t("add_500")
	manual_water_button.text = Texts.t("manual")
	name_input.text_submitted.connect(_on_name_submitted)

	back_button.pressed.connect(_on_back_pressed)
	add_button.pressed.connect(_on_add_pressed)
	water_250_button.pressed.connect(_on_add_water.bind(250))
	water_500_button.pressed.connect(_on_add_water.bind(500))
	manual_water_button.pressed.connect(_on_manual_water_pressed)
	number_dialog.submitted.connect(_on_water_submitted)

	for input in [calories_input, protein_input, fat_input, carbs_input]:
		input.text_changed.connect(_on_numeric_changed.bind(input))

	_refresh()


func _today_key() -> String:
	return Streak.day_key_from_unix(int(Time.get_unix_time_from_system()))


func _refresh() -> void:
	var day_key := _today_key()
	var totals := Storage.get_day_totals(day_key)
	today_title.text = Texts.t("today_summary_format") % int(totals.get("calories", 0))
	_build_today_list(day_key)

	var goal_water := int(Storage.get_goals().get("water", 2000))
	water_value.text = Texts.t("water_today_format") % [int(totals.get("water", 0)), goal_water]


func _build_today_list(day_key: String) -> void:
	for child in today_list.get_children():
		today_list.remove_child(child)
		child.queue_free()

	var entries := Storage.get_food_entries_for_day(day_key)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = Texts.t("nutrition_empty")
		empty.add_theme_font_size_override("font_size", 30)
		empty.add_theme_color_override("font_color", ThemeColors.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		today_list.add_child(empty)
		return

	for entry in entries:
		today_list.add_child(_make_entry_card(entry))


func _make_entry_card(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	var entry_name := str(entry.get("name", "")).strip_edges()
	if entry_name.is_empty():
		entry_name = Texts.t("unnamed_entry")
	var datetime := str(entry.get("datetime", ""))
	var time_part := datetime.substr(11, 5) if datetime.length() >= 16 else ""
	name_label.text = entry_name + (" · " + time_part if not time_part.is_empty() else "")
	name_label.add_theme_font_size_override("font_size", 34)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var macros_label := Label.new()
	macros_label.text = Texts.t("entry_macros_format") % [
		int(entry.get("calories", 0)),
		int(entry.get("protein", 0)),
		int(entry.get("fat", 0)),
		int(entry.get("carbs", 0)),
	]
	macros_label.add_theme_font_size_override("font_size", 26)
	macros_label.add_theme_color_override("font_color", ThemeColors.MUTED)

	var delete_button := Button.new()
	delete_button.text = Texts.t("delete")
	delete_button.custom_minimum_size = Vector2(130, 92)
	delete_button.add_theme_font_size_override("font_size", 26)
	delete_button.theme_type_variation = &"DangerButton"
	delete_button.pressed.connect(_on_delete_entry.bind(str(entry.get("id", ""))))

	info.add_child(name_label)
	info.add_child(macros_label)
	row.add_child(info)
	row.add_child(delete_button)
	margin.add_child(row)
	panel.add_child(margin)
	return panel


func _on_add_pressed() -> void:
	var entry_name := name_input.text.strip_edges()
	var calories := _number(calories_input)
	var protein := _number(protein_input)
	var fat := _number(fat_input)
	var carbs := _number(carbs_input)
	if entry_name.is_empty() and calories == 0 and protein == 0 and fat == 0 and carbs == 0:
		_show_status(Texts.t("invalid_values"), true)
		return

	Storage.add_food_entry(entry_name, calories, protein, fat, carbs)
	name_input.text = ""
	for input in [calories_input, protein_input, fat_input, carbs_input]:
		input.text = "0"
	_show_status(Texts.t("entry_added"), false)
	_refresh()


func _on_name_submitted(_text: String) -> void:
	_on_add_pressed()


func _on_delete_entry(entry_id: String) -> void:
	if Storage.delete_food_entry(entry_id):
		_show_status(Texts.t("entry_deleted"), false)
		_refresh()


func _on_add_water(amount_ml: int) -> void:
	Storage.add_water(amount_ml)
	_refresh()


func _on_manual_water_pressed() -> void:
	manual_water_mode = true
	number_dialog.open(Texts.t("dialog_water"), Storage.get_water(_today_key()), 0, 100000)


func _on_water_submitted(value: int) -> void:
	if not manual_water_mode:
		return
	manual_water_mode = false
	Storage.set_water(value, _today_key())
	_refresh()


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


func _show_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.add_theme_color_override(
		"font_color",
		ThemeColors.ERROR if is_error else ThemeColors.GREEN_BRIGHT
	)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
