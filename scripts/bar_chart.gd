extends Control

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")

@export_enum("number", "time") var value_mode := "number"
@export var bar_color: Color = ThemeColors.GREEN
@export var goal_color: Color = ThemeColors.MUTED

var values: Array = []
var labels: Array = []
var goal_value := 0.0


func _ready() -> void:
	add_to_group("themed")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 350)
	resized.connect(queue_redraw)


func set_data(new_values: Array, new_labels: Array, goal: float = 0.0) -> void:
	values = new_values
	labels = new_labels
	goal_value = goal
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var left := 82.0
	var right := 14.0
	var top := 18.0
	var bottom := 46.0
	var plot := Rect2(left, top, maxf(10.0, size.x - left - right), maxf(10.0, size.y - top - bottom))
	var count := values.size()
	if count == 0:
		draw_string(font, Vector2(left, top + 30), Texts.t("no_data"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ThemeColors.MUTED)
		return

	var maximum := 0.0
	for value in values:
		maximum = maxf(maximum, float(value))
	maximum = maxf(maximum, goal_value)
	var step := _nice_step(maxf(maximum, 1.0) * 1.12 / 4.0)
	var axis_top := step * 4.0

	for index in range(5):
		var y := plot.position.y + plot.size.y * index / 4.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.position.x + plot.size.x, y), ThemeColors.GRID_FAINT, 1.0)
		var grid_text := _format_value(step * (4 - index))
		var text_size := font.get_string_size(grid_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(font, Vector2(plot.position.x - text_size.x - 10, y + 6), grid_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ThemeColors.MUTED)

	var slot := plot.size.x / float(count)
	var bar_width := maxf(4.0, slot * (0.66 if count <= 7 else 0.72))
	var label_step := 1 if count <= 7 else 5

	for index in range(count):
		var value := float(values[index])
		var bar_height := plot.size.y * (value / axis_top)
		var x := plot.position.x + slot * index + (slot - bar_width) * 0.5
		var rect := Rect2(x, plot.position.y + plot.size.y - bar_height, bar_width, bar_height)
		var color := ThemeColors.GOLD if index == count - 1 else bar_color
		if bar_height > 0.5:
			var style := StyleBoxFlat.new()
			style.bg_color = color
			style.set_corner_radius_all(0)
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			draw_style_box(style, rect)
		if count <= 7 and value > 0.0:
			var value_text := _format_value(value)
			var value_size := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			draw_string(font, Vector2(rect.position.x + (rect.size.x - value_size.x) * 0.5, rect.position.y - 6), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ThemeColors.GOLD)
		if index % label_step == 0 and index < labels.size():
			var label := str(labels[index])
			var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			draw_string(font, Vector2(plot.position.x + slot * index + (slot - label_size.x) * 0.5, plot.position.y + plot.size.y + 28), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ThemeColors.MUTED)

	if goal_value > 0.0:
		var goal_y := plot.position.y + plot.size.y - plot.size.y * (goal_value / axis_top)
		draw_dashed_line(Vector2(plot.position.x, goal_y), Vector2(plot.position.x + plot.size.x, goal_y), goal_color, 3.0, 8.0)


static func _nice_step(raw: float) -> float:
	var exponent := floorf(log(raw) / log(10.0))
	var base := pow(10.0, exponent)
	var fraction := raw / base
	var nice := 10.0
	for candidate in [1.0, 2.0, 5.0, 10.0]:
		if fraction <= candidate:
			nice = candidate
			break
	return nice * base


func _format_value(value: float) -> String:
	if value_mode == "time":
		return Texts.format_time(int(round(value)))
	return str(int(round(value)))
