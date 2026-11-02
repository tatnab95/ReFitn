extends VBoxContainer

# Single settings entry "Музыка". Opens the music window (scripts/music_window.gd).

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const MusicWindow = preload("res://scripts/music_window.gd")

var _count: Label
var _window


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side == "left" or side == "right" else 20)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	var button := Button.new()
	button.text = Texts.t("music_title")
	button.custom_minimum_size = Vector2(0, 100)
	button.theme_type_variation = &"SecondaryButton"
	button.add_theme_font_size_override("font_size", 36)
	button.pressed.connect(_on_pressed)
	box.add_child(button)

	_count = Label.new()
	_count.add_theme_font_size_override("font_size", 26)
	_count.add_theme_color_override("font_color", ThemeColors.MUTED)
	box.add_child(_count)

	margin.add_child(box)
	panel.add_child(margin)
	add_child(panel)

	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_window = MusicWindow.new()
	layer.add_child(_window)
	MusicPlayer.changed.connect(_refresh_count)
	_refresh_count()


func _refresh_count() -> void:
	_count.text = Texts.t("music_entry_count") % MusicPlayer.tracks.size()


func _on_pressed() -> void:
	_window.open()
