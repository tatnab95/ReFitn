extends Control

const ThemeColors = preload("res://scripts/theme_colors.gd")

var label_text := ""
var value := 0.0
var target := 0.0
var unit := ""
var bar_color: Color = ThemeColors.GREEN


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 72)
	resized.connect(queue_redraw)


func set_values(new_label: String, new_value: float, new_target: float, new_unit: String, color: Color) -> void:
	label_text = new_label
	value = new_value
	target = new_target
	unit = new_unit
	bar_color = color
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var value_color := ThemeColors.GOLD if target > 0.0 and value >= target else ThemeColors.TEXT
	draw_string(font, Vector2(0, 24), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ThemeColors.TEXT)

	var value_text := "%d" % int(round(value))
	if target > 0.0:
		value_text += " / %d" % int(round(target))
	if not unit.is_empty():
		value_text += " " + unit
	var value_size := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_string(
		font,
		Vector2(size.x - value_size.x, 24),
		value_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		22,
		value_color
	)

	var track := Rect2(0, 40, size.x, 18)
	_draw_rounded(track, ThemeColors.SURFACE_ALT, 9)
	var ratio := 0.0
	if target > 0.0:
		ratio = clampf(value / target, 0.0, 1.0)
	elif value > 0.0:
		ratio = 1.0
	if ratio > 0.0:
		var fill := Rect2(track.position, Vector2(track.size.x * ratio, track.size.y))
		_draw_rounded(fill, bar_color, 9)


func _draw_rounded(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	draw_style_box(style, rect)
