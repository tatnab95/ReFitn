extends VBoxContainer

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const Streak = preload("res://scripts/streak.gd")
const FlameIcon = preload("res://scripts/flame_icon.gd")
const CalendarView = preload("res://scripts/calendar_view.gd")
const MacroBar = preload("res://scripts/macro_bar.gd")

var _built := false
var _calendar
var _month_label: Label
var _streak_label: Label
var _record_label: Label
var _streak_status: Label
var _streak_flame
var _today_title: Label
var _bars := {}
var _view_year := 0
var _view_month := 0


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	_build()
	var now := Time.get_datetime_dict_from_system()
	_view_year = int(now.year)
	_view_month = int(now.month)
	refresh()


func refresh() -> void:
	if not _built:
		return
	var info := Streak.calculate(Storage.workouts)
	var current := int(info.get("current", 0))
	var record := int(info.get("record", 0))
	var trained_today := bool(info.get("trained_today", false))

	_streak_label.text = Texts.format_streak(current)
	_record_label.text = Texts.format_streak_record(record)
	_streak_status.text = Texts.t("streak_done") if trained_today else Texts.t("streak_pending")
	_streak_status.add_theme_color_override(
		"font_color",
		ThemeColors.GREEN_BRIGHT if trained_today else ThemeColors.MUTED
	)
	if trained_today:
		_streak_flame.set_flame(ThemeColors.GREEN_BRIGHT, ThemeColors.TRANSPARENT, 0.0)
	else:
		_streak_flame.set_flame(ThemeColors.MUTED, ThemeColors.GOLD, 4.0)

	_calendar.set_month(
		_view_year,
		_view_month,
		Streak.workout_day_numbers(Storage.workouts),
		int(info.get("today_number", 0))
	)
	_month_label.text = Texts.t("month_title_format") % [
		Texts.month_name(_view_month), _view_year
	]

	var today_key := Streak.day_key_from_unix(int(Time.get_unix_time_from_system()))
	var totals := Storage.get_day_totals(today_key)
	var goals := Storage.get_goals()
	_today_title.text = Texts.t("today_summary_format") % int(totals.get("calories", 0))
	_bars.calories.set_values(
		Texts.t("calories"), int(totals.get("calories", 0)),
		int(goals.get("calories", 2500)), Texts.t("kcal"), ThemeColors.GOLD
	)
	_bars.protein.set_values(
		Texts.t("protein"), int(totals.get("protein", 0)),
		int(goals.get("protein", 150)), Texts.t("grams"), ThemeColors.BLUE
	)
	_bars.fat.set_values(
		Texts.t("fat"), int(totals.get("fat", 0)),
		int(goals.get("fat", 70)), Texts.t("grams"), ThemeColors.GOLD_SOFT
	)
	_bars.carbs.set_values(
		Texts.t("carbs"), int(totals.get("carbs", 0)),
		int(goals.get("carbs", 300)), Texts.t("grams"), ThemeColors.GREEN
	)
	_bars.water.set_values(
		Texts.t("water"), int(totals.get("water", 0)),
		int(goals.get("water", 2000)), Texts.t("ml"), ThemeColors.BLUE_SOFT
	)


func _build() -> void:
	if _built:
		return
	_built = true

	var streak_panel := PanelContainer.new()
	var streak_margin := _make_margin(28, 22, 28, 22)
	var streak_row := HBoxContainer.new()
	streak_row.add_theme_constant_override("separation", 18)
	_streak_flame = FlameIcon.new()
	_streak_flame.custom_minimum_size = Vector2(92, 112)

	var streak_text := VBoxContainer.new()
	streak_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_text.add_theme_constant_override("separation", 2)
	_streak_label = Label.new()
	_streak_label.add_theme_font_size_override("font_size", 56)
	_record_label = Label.new()
	_record_label.add_theme_font_size_override("font_size", 32)
	_record_label.add_theme_color_override("font_color", ThemeColors.GOLD)
	_streak_status = Label.new()
	_streak_status.add_theme_font_size_override("font_size", 26)
	streak_text.add_child(_streak_label)
	streak_text.add_child(_record_label)
	streak_text.add_child(_streak_status)
	streak_row.add_child(_streak_flame)
	streak_row.add_child(streak_text)
	streak_margin.add_child(streak_row)
	streak_panel.add_child(streak_margin)
	add_child(streak_panel)

	var calendar_panel := PanelContainer.new()
	var calendar_margin := _make_margin(20, 18, 20, 18)
	var calendar_box := VBoxContainer.new()
	calendar_box.add_theme_constant_override("separation", 8)

	var calendar_header := HBoxContainer.new()
	calendar_header.add_theme_constant_override("separation", 10)
	var prev_button := Button.new()
	prev_button.text = Texts.t("month_prev")
	prev_button.custom_minimum_size = Vector2(96, 88)
	prev_button.add_theme_font_size_override("font_size", 52)
	prev_button.pressed.connect(_on_prev_month)
	_month_label = Label.new()
	_month_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_month_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_month_label.add_theme_font_size_override("font_size", 38)
	var next_button := Button.new()
	next_button.text = Texts.t("month_next")
	next_button.custom_minimum_size = Vector2(96, 88)
	next_button.add_theme_font_size_override("font_size", 52)
	next_button.pressed.connect(_on_next_month)
	calendar_header.add_child(prev_button)
	calendar_header.add_child(_month_label)
	calendar_header.add_child(next_button)

	_calendar = CalendarView.new()
	_calendar.custom_minimum_size = Vector2(0, 470)
	calendar_box.add_child(calendar_header)
	calendar_box.add_child(_calendar)
	calendar_margin.add_child(calendar_box)
	calendar_panel.add_child(calendar_margin)
	add_child(calendar_panel)

	var today_panel := PanelContainer.new()
	var today_margin := _make_margin(28, 20, 28, 20)
	var today_box := VBoxContainer.new()
	today_box.add_theme_constant_override("separation", 8)
	_today_title = Label.new()
	_today_title.add_theme_font_size_override("font_size", 40)
	today_box.add_child(_today_title)
	for key in ["calories", "protein", "fat", "carbs", "water"]:
		var bar = MacroBar.new()
		today_box.add_child(bar)
		_bars[key] = bar
	today_margin.add_child(today_box)
	today_panel.add_child(today_margin)
	add_child(today_panel)


func _make_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _on_prev_month() -> void:
	var shifted := Streak.add_months(_view_year, _view_month, -1)
	_view_year = int(shifted.year)
	_view_month = int(shifted.month)
	refresh()


func _on_next_month() -> void:
	var shifted := Streak.add_months(_view_year, _view_month, 1)
	_view_year = int(shifted.year)
	_view_month = int(shifted.month)
	refresh()
