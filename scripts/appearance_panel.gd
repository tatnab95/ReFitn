extends VBoxContainer

signal palette_changed

const Texts = preload("res://scripts/texts.gd")
const ThemeBuilder = preload("res://scripts/theme_builder.gd")

const MODES := ["dark", "light", "system"]
const TITLES := ["theme_dark", "theme_light", "theme_system"]

var _option: OptionButton


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 20)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = Texts.t("theme_title")
	title.add_theme_font_size_override("font_size", 34)
	_option = OptionButton.new()
	_option.custom_minimum_size = Vector2(0, 88)
	_option.add_theme_font_size_override("font_size", 30)
	var supports_system := DisplayServer.is_dark_mode_supported()
	for index in range(MODES.size()):
		if MODES[index] == "system" and not supports_system:
			continue
		_option.add_item(Texts.t(TITLES[index]))
		_option.set_item_metadata(_option.item_count - 1, MODES[index])
	_option.select(_index_of(Storage.get_theme_mode()))
	_option.item_selected.connect(_on_selected)
	box.add_child(title)
	box.add_child(_option)
	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)


func _index_of(mode: String) -> int:
	for index in range(_option.item_count):
		if str(_option.get_item_metadata(index)) == mode:
			return index
	return 0


func _on_selected(index: int) -> void:
	Storage.set_theme_mode(str(_option.get_item_metadata(index)))
	ThemeBuilder.apply(get_tree().root)
	palette_changed.emit()
