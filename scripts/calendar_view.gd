extends Control

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")
const FlameIcon = preload("res://scripts/flame_icon.gd")

var year := 2026
var month := 1
var trained_days: Dictionary = {}
var today_number := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 470)
	queue_redraw()


func set_month(new_year: int, new_month: int, days: Dictionary, today: int) -> void:
	year = new_year
	month = new_month
	trained_days = days
	today_number = today
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var header_height := 38.0
	var rows := 6
	var cell_width := size.x / 7.0
	var cell_height := (size.y - header_height) / float(rows)
	var weekday_labels: Array = Texts.WEEKDAYS_SHORT

	for index in range(7):
		var label := str(weekday_labels[index])
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		var position := Vector2(
			cell_width * index + (cell_width - label_size.x) * 0.5,
			header_height - 10
		)
		draw_string(font, position, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ThemeColors.MUTED)

	var first_weekday := Streak.first_weekday_monday(year, month)
	var day_count := Streak.days_in_month(year, month)
	var month_first_number := Streak.days_from_civil(year, month, 1)

	for day in range(1, day_count + 1):
		var index := first_weekday + day - 1
		var column := index % 7
		var row := index / 7
		var cell := Rect2(
			Vector2(column * cell_width + 3, header_height + row * cell_height + 3),
			Vector2(cell_width - 6, cell_height - 6)
		)
		var day_number := month_first_number + day - 1
		var has_workout := trained_days.has(day_number)
		var is_today := day_number == today_number
		var is_past := day_number < today_number

		var fill := ThemeColors.BG_DEEP
		if has_workout:
			fill = ThemeColors.GREEN_DARK
		elif is_past:
			fill = ThemeColors.MISSED

		_draw_rounded_rect(cell, fill, 10)
		if is_today:
			_draw_rounded_outline(cell, ThemeColors.GOLD, 4, 10)

		if has_workout:
			var flame_rect := Rect2(
				Vector2(cell.position.x + cell.size.x * 0.5 - 15, cell.position.y + 8),
				Vector2(30, 34)
			)
			FlameIcon.draw_flame(self, flame_rect, ThemeColors.GOLD_SOFT, ThemeColors.BG_DEEP, 1.5)

		var number_color := ThemeColors.TEXT if (has_workout or is_today) else ThemeColors.MUTED
		var number_text := str(day)
		var number_size := font.get_string_size(number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		var number_position := Vector2(
			cell.position.x + (cell.size.x - number_size.x) * 0.5,
			cell.position.y + cell.size.y - 14
		)
		draw_string(font, number_position, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, number_color)


func _draw_rounded_rect(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	draw_style_box(style, rect)


func _draw_rounded_outline(rect: Rect2, color: Color, width: int, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColors.TRANSPARENT
	style.border_color = color
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	draw_style_box(style, rect)
