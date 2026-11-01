extends Button

const ThemeColors = preload("res://scripts/theme_colors.gd")

var _hovered := false
var _pressed := false


func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	button_down.connect(_on_down.bind(true))
	button_up.connect(_on_down.bind(false))
	resized.connect(queue_redraw)
	queue_redraw()


func _on_hover(value: bool) -> void:
	_hovered = value
	queue_redraw()


func _on_down(value: bool) -> void:
	_pressed = value
	queue_redraw()


func _draw() -> void:
	var color := ThemeColors.GOLD if _hovered or _pressed else ThemeColors.TEXT
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.27
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * radius * 0.92, center + direction * radius * 1.32, color, 9.0)
	draw_arc(center, radius, 0.0, TAU, 40, color, 9.0, true)
	draw_circle(center, radius * 0.36, ThemeColors.SURFACE)
	draw_arc(center, radius * 0.36, 0.0, TAU, 32, color, 4.0, true)
