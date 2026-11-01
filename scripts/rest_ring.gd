extends Control

const ThemeColors = preload("res://scripts/theme_colors.gd")

const LINE_WIDTH := 22.0
const WARNING_SECONDS := 10

var _fraction := 1.0
var _seconds_left := 0


func _ready() -> void:
	add_to_group("themed")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_progress(fraction: float, seconds_left: int) -> void:
	_fraction = clampf(fraction, 0.0, 1.0)
	_seconds_left = seconds_left
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - LINE_WIDTH
	if radius <= 0.0:
		return
	draw_arc(center, radius, 0.0, TAU, 128, ThemeColors.SURFACE_ALT, LINE_WIDTH, true)
	var color := ThemeColors.GREEN if _seconds_left <= WARNING_SECONDS else ThemeColors.GOLD
	if _fraction > 0.0:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * _fraction, 128, color, LINE_WIDTH, true)
