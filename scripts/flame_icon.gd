extends Control

const ThemeColors = preload("res://scripts/theme_colors.gd")

@export var fill_color: Color = ThemeColors.GOLD
@export var outline_color: Color = ThemeColors.TRANSPARENT
@export var outline_width: float = 0.0
@export var inner_color: Color = ThemeColors.TRANSPARENT


func _ready() -> void:
	add_to_group("themed")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_flame(fill: Color, outline: Color, width: float = 0.0) -> void:
	fill_color = fill
	outline_color = outline
	outline_width = width
	queue_redraw()


func _draw() -> void:
	draw_flame(self, Rect2(Vector2.ZERO, size), fill_color, outline_color, outline_width, inner_color)


static func draw_flame(canvas: CanvasItem, rect: Rect2, fill: Color, outline: Color = ThemeColors.TRANSPARENT, width: float = 0.0, inner: Color = ThemeColors.TRANSPARENT) -> void:
	var points := flame_points(rect)
	canvas.draw_colored_polygon(points, fill)
	if width > 0.0 and outline.a > 0.0:
		var closed := points.duplicate()
		closed.append(points[0])
		canvas.draw_polyline(closed, outline, width, true)
	if inner.a > 0.0:
		var inner_rect := Rect2(
			rect.position + rect.size * Vector2(0.31, 0.30),
			rect.size * Vector2(0.38, 0.52)
		)
		canvas.draw_colored_polygon(flame_points(inner_rect), inner)


static func flame_points(rect: Rect2) -> PackedVector2Array:
	var normalized := [
		Vector2(0.50, 0.02), Vector2(0.62, 0.16), Vector2(0.68, 0.32),
		Vector2(0.80, 0.42), Vector2(0.84, 0.62), Vector2(0.76, 0.78),
		Vector2(0.62, 0.91), Vector2(0.50, 1.00), Vector2(0.36, 0.93),
		Vector2(0.22, 0.78), Vector2(0.16, 0.60), Vector2(0.22, 0.40),
		Vector2(0.34, 0.28), Vector2(0.40, 0.43), Vector2(0.44, 0.24),
		Vector2(0.39, 0.12),
	]
	var points := PackedVector2Array()
	for point in normalized:
		points.append(rect.position + point * rect.size)
	return points
