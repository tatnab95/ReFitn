extends Control

const Texts = preload("res://scripts/texts.gd")
const SegmentBar = preload("res://scripts/segment_bar.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")

enum Period { DAY, WEEK, MONTH }

@onready var background: ColorRect = $Background
@onready var back_button: Button = $Margin/MainVBox/Header/BackButton
@onready var title_label: Label = $Margin/MainVBox/Header/Title
@onready var tabs: TabContainer = $Margin/MainVBox/Tabs
@onready var overview_content = $Margin/MainVBox/Tabs/Overview/OverviewContent
@onready var graphs_content = $Margin/MainVBox/Tabs/Graphs/GraphsContent
@onready var macros_content = $Margin/MainVBox/Tabs/Macros/MacrosContent
@onready var day_button: Button = $Margin/MainVBox/Tabs/Summary/SummaryContent/PeriodRow/DayButton
@onready var week_button: Button = $Margin/MainVBox/Tabs/Summary/SummaryContent/PeriodRow/WeekButton
@onready var month_button: Button = $Margin/MainVBox/Tabs/Summary/SummaryContent/PeriodRow/MonthButton
@onready var exercise_stats: VBoxContainer = $Margin/MainVBox/Tabs/Summary/SummaryContent/ExerciseStats
@onready var recent_title: Label = $Margin/MainVBox/Tabs/Summary/SummaryContent/RecentTitle
@onready var recent_list: VBoxContainer = $Margin/MainVBox/Tabs/Summary/SummaryContent/RecentList
@onready var export_button: Button = $Margin/MainVBox/BottomRow/ExportButton
@onready var import_button: Button = $Margin/MainVBox/BottomRow/ImportButton
@onready var status_label: Label = $Margin/MainVBox/Status
@onready var export_dialog: FileDialog = $ExportDialog
@onready var import_dialog: FileDialog = $ImportDialog

var period := Period.DAY


func _ready() -> void:
	background.color = ThemeColors.BG
	back_button.text = Texts.t("back")
	title_label.text = Texts.t("stats_title")
	tabs.set_tab_title(0, Texts.t("tab_overview"))
	tabs.set_tab_title(1, Texts.t("tab_graphs"))
	tabs.set_tab_title(2, Texts.t("tab_summary"))
	tabs.set_tab_title(3, Texts.t("tab_macros"))
	day_button.text = Texts.t("period_day")
	week_button.text = Texts.t("period_week")
	month_button.text = Texts.t("period_month")
	recent_title.text = Texts.t("recent_title")
	export_button.text = Texts.t("export")
	import_button.text = Texts.t("import")
	export_button.theme_type_variation = &"SecondaryButton"
	import_button.theme_type_variation = &"SecondaryButton"
	var segments := SegmentBar.new()
	tabs.get_parent().add_child(segments)
	tabs.get_parent().move_child(segments, tabs.get_index())
	segments.setup(tabs, [Texts.t("tab_overview"), Texts.t("tab_graphs"), Texts.t("tab_summary"), Texts.t("tab_macros")])

	back_button.pressed.connect(_on_back_pressed)
	day_button.pressed.connect(_set_period.bind(Period.DAY))
	week_button.pressed.connect(_set_period.bind(Period.WEEK))
	month_button.pressed.connect(_set_period.bind(Period.MONTH))
	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)
	tabs.tab_changed.connect(_on_tab_changed)

	_configure_dialogs()
	_set_period(Period.DAY)
	_refresh_extra_tabs()


func _refresh_extra_tabs() -> void:
	overview_content.refresh()
	graphs_content.refresh()
	macros_content.refresh()


func _on_tab_changed(index: int) -> void:
	match index:
		0:
			overview_content.refresh()
		1:
			graphs_content.refresh()
		3:
			macros_content.refresh()


func _configure_dialogs() -> void:
	export_dialog.title = Texts.t("export_dialog")
	import_dialog.title = Texts.t("import_dialog")
	export_dialog.current_dir = OS.get_user_data_dir()
	import_dialog.current_dir = OS.get_user_data_dir()
	export_dialog.current_file = Texts.t("backup_name") % _backup_stamp()
	export_dialog.use_native_dialog = OS.has_feature("desktop")
	import_dialog.use_native_dialog = OS.has_feature("desktop")
	export_dialog.file_selected.connect(_on_export_selected)
	import_dialog.file_selected.connect(_on_import_selected)


func _backup_stamp() -> String:
	return Time.get_datetime_string_from_system().replace("T", "_").replace(":", "-")


func _set_period(new_period: int) -> void:
	period = new_period
	_style_period_button(day_button, period == Period.DAY)
	_style_period_button(week_button, period == Period.WEEK)
	_style_period_button(month_button, period == Period.MONTH)
	_refresh()


func _style_period_button(button: Button, active: bool) -> void:
	button.button_pressed = active
	if active:
		button.theme_type_variation = &"PrimaryButton"
	else:
		button.theme_type_variation = &""


func _refresh() -> void:
	for child in exercise_stats.get_children():
		exercise_stats.remove_child(child)
		child.queue_free()
	for child in recent_list.get_children():
		recent_list.remove_child(child)
		child.queue_free()

	var start_unix := _period_start_unix()
	var totals := {}
	for exercise in Texts.EXERCISES:
		totals[str(exercise.id)] = {"sets": 0, "reps": 0, "seconds": 0}

	var period_has_data := false
	var points_total := 0
	for workout in Storage.workouts:
		if typeof(workout) != TYPE_DICTIONARY:
			continue
		var started_unix := int(workout.get("started_unix", 0))
		if started_unix <= 0 or started_unix < start_unix:
			continue

		var exercise_id := str(workout.get("exercise_id", ""))
		if not totals.has(exercise_id):
			totals[exercise_id] = {"sets": 0, "reps": 0, "seconds": 0}

		var total: Dictionary = totals[exercise_id]
		var sets := maxi(0, int(workout.get("sets", 0)))
		var reps := maxi(0, int(workout.get("reps", 0)))
		var seconds := maxi(0, int(workout.get("duration_seconds", 0)))
		total["sets"] = int(total["sets"]) + sets
		total["reps"] = int(total["reps"]) + reps
		total["seconds"] = int(total["seconds"]) + seconds
		totals[exercise_id] = total
		points_total += Storage.workout_points(workout)

		if sets > 0 or reps > 0 or seconds > 0:
			period_has_data = true

	var points_label := _make_muted_label(Texts.t("stats_points_format") % points_total, 36)
	points_label.add_theme_color_override("font_color", ThemeColors.GOLD)
	exercise_stats.add_child(points_label)

	if not period_has_data:
		var empty_label := _make_muted_label(Texts.t("stats_empty_period"), 32)
		exercise_stats.add_child(empty_label)

	for exercise in Texts.EXERCISES:
		var exercise_id := str(exercise.id)
		var total: Dictionary = totals[exercise_id]
		exercise_stats.add_child(_make_exercise_card(
			str(exercise.name),
			int(total["sets"]),
			int(total["reps"]),
			int(total["seconds"])
		))

	_build_recent_list()


func _period_start_unix() -> int:
	var now := Time.get_datetime_dict_from_system()
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var year := int(now.year)
	var month := int(now.month)
	var day := int(now.day)

	match period:
		Period.WEEK:
			var days_back := (int(now.weekday) + 6) % 7
			return _local_midnight_unix(year, month, day, bias) - days_back * 86400
		Period.MONTH:
			day = 1
		_:
			pass

	return _local_midnight_unix(year, month, day, bias)


func _local_midnight_unix(year: int, month: int, day: int, bias: int) -> int:
	return int(Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0,
	})) - bias


func _make_exercise_card(exercise_name: String, sets: int, reps: int, seconds: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 18)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var top_row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = exercise_name
	name_label.add_theme_font_size_override("font_size", 40)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var time_label := Label.new()
	time_label.text = Texts.t("stats_time_format") % Texts.format_time(seconds)
	time_label.add_theme_font_size_override("font_size", 30)
	time_label.add_theme_color_override("font_color", ThemeColors.MUTED)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var numbers_label := Label.new()
	numbers_label.text = Texts.t("stats_exercise_format") % [sets, reps]
	numbers_label.add_theme_font_size_override("font_size", 34)
	numbers_label.add_theme_color_override("font_color", ThemeColors.MUTED)

	top_row.add_child(name_label)
	top_row.add_child(time_label)
	box.add_child(top_row)
	box.add_child(numbers_label)
	margin.add_child(box)
	panel.add_child(margin)
	return panel


func _build_recent_list() -> void:
	var sorted := Storage.workouts.duplicate()
	sorted.sort_custom(func(a, b): return int(a.get("started_unix", 0)) > int(b.get("started_unix", 0)))

	var shown := 0
	for workout in sorted:
		if shown >= 10:
			break
		if typeof(workout) != TYPE_DICTIONARY:
			continue
		recent_list.add_child(_make_recent_card(workout))
		shown += 1

	if shown == 0:
		recent_list.add_child(_make_muted_label(Texts.t("recent_empty"), 32))


func _make_recent_card(workout: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 16)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var top_row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = Texts.exercise_name(str(workout.get("exercise_id", "")))
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var duration_label := Label.new()
	duration_label.text = Texts.format_time(int(workout.get("duration_seconds", 0)))
	duration_label.add_theme_font_size_override("font_size", 30)
	duration_label.add_theme_color_override("font_color", ThemeColors.MUTED)

	var bottom_row := HBoxContainer.new()
	var date_label := Label.new()
	date_label.text = Texts.format_datetime(int(workout.get("started_unix", 0)))
	date_label.add_theme_font_size_override("font_size", 26)
	date_label.add_theme_color_override("font_color", ThemeColors.MUTED)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var numbers_label := Label.new()
	numbers_label.text = Texts.t("stats_exercise_format") % [
		int(workout.get("sets", 0)), int(workout.get("reps", 0))
	]
	numbers_label.add_theme_font_size_override("font_size", 26)
	numbers_label.add_theme_color_override("font_color", ThemeColors.MUTED)

	top_row.add_child(name_label)
	top_row.add_child(duration_label)
	bottom_row.add_child(date_label)
	bottom_row.add_child(numbers_label)
	box.add_child(top_row)
	box.add_child(bottom_row)
	margin.add_child(box)
	panel.add_child(margin)
	return panel


func _make_muted_label(label_text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ThemeColors.MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _on_export_pressed() -> void:
	export_dialog.current_file = Texts.t("backup_name") % _backup_stamp()
	export_dialog.popup_centered_ratio(0.9)


func _on_import_pressed() -> void:
	import_dialog.popup_centered_ratio(0.9)


func _on_export_selected(path: String) -> void:
	if path.get_extension().is_empty():
		path += ".json"
	var error := Storage.export_workouts(path)
	if error == OK:
		_show_status(Texts.t("export_saved") % path, false)
	else:
		_show_status(Texts.t("export_failed"), true)


func _on_import_selected(path: String) -> void:
	var added := Storage.import_workouts(path)
	if added < 0:
		var message := Texts.t("import_newer") if Storage.last_import_error == "newer_version" else Texts.t("import_failed")
		_show_status(message, true)
		return
	_show_status(Texts.t("import_ok") % [
		added, int(Storage.last_import_info.get("nutrition", 0))
	], false)
	_refresh()
	_refresh_extra_tabs()


func _show_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", ThemeColors.ERROR if is_error else ThemeColors.GREEN_BRIGHT)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
