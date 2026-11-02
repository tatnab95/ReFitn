extends PanelContainer

# Compact player on the workout screen. Hidden when music is off or the list is empty.

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")

var _cover: TextureRect
var _cover_box: ColorRect
var _title: Label
var _progress: HSlider
var _controls: HBoxContainer
var _play: Button
var _toggle: Button
var _notice: Label
var _dragging := false
var _notice_timer: Timer


func _ready() -> void:
	add_theme_stylebox_override("panel", _panel_style())
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	_cover_box = ColorRect.new()
	_cover_box.color = ThemeColors.SURFACE_ALT
	_cover_box.custom_minimum_size = Vector2(96, 96)
	_cover = TextureRect.new()
	_cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_cover.custom_minimum_size = Vector2(96, 96)
	var cover_holder := Control.new()
	cover_holder.custom_minimum_size = Vector2(96, 96)
	cover_holder.add_child(_cover_box)
	cover_holder.add_child(_cover)
	_cover_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header.add_child(cover_holder)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 6)
	_title = Label.new()
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.add_theme_font_size_override("font_size", 30)
	_progress = HSlider.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.step = 0.1
	_progress.custom_minimum_size = Vector2(0, 40)
	_progress.drag_started.connect(func() -> void: _dragging = true)
	_progress.drag_ended.connect(_on_drag_ended)
	text_box.add_child(_title)
	text_box.add_child(_progress)
	header.add_child(text_box)

	_toggle = Button.new()
	_toggle.custom_minimum_size = Vector2(120, 84)
	_toggle.add_theme_font_size_override("font_size", 26)
	_toggle.theme_type_variation = &"SecondaryButton"
	_toggle.pressed.connect(_on_toggle_pressed)
	header.add_child(_toggle)
	box.add_child(header)

	_controls = HBoxContainer.new()
	_controls.add_theme_constant_override("separation", 12)
	_controls.add_child(_control_button(Texts.t("music_prev"), MusicPlayer.previous_track))
	_play = _control_button(Texts.t("music_play"), MusicPlayer.toggle_play)
	_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls.add_child(_play)
	_controls.add_child(_control_button(Texts.t("music_next"), MusicPlayer.next_track))
	box.add_child(_controls)

	_notice = Label.new()
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.add_theme_font_size_override("font_size", 24)
	_notice.add_theme_color_override("font_color", ThemeColors.ERROR)
	_notice.visible = false
	box.add_child(_notice)

	margin.add_child(box)
	add_child(margin)

	_notice_timer = Timer.new()
	_notice_timer.one_shot = true
	_notice_timer.timeout.connect(func() -> void: _notice.visible = false)
	add_child(_notice_timer)

	MusicPlayer.changed.connect(_refresh)
	MusicPlayer.notice.connect(_show_notice)
	_refresh()


func _process(_delta: float) -> void:
	if not visible or _dragging or not MusicPlayer.is_playing():
		return
	_progress.max_value = maxf(0.1, MusicPlayer.length())
	_progress.set_value_no_signal(MusicPlayer.position())


func _refresh() -> void:
	var show := MusicPlayer.enabled and not MusicPlayer.tracks.is_empty()
	visible = show
	if not show:
		return
	var track: Dictionary = MusicPlayer.current_track()
	if track.is_empty():
		track = MusicPlayer.tracks[0]
	var collapsed := MusicPlayer.widget_collapsed
	_title.text = str(track.get("title", ""))
	_cover.texture = MusicPlayer.cover_texture(track)
	_cover.visible = not collapsed
	_cover_box.visible = not collapsed
	_progress.visible = not collapsed
	_controls.visible = not collapsed
	_play.text = Texts.t("music_pause") if MusicPlayer.is_playing() else Texts.t("music_play")
	_toggle.text = Texts.t("music_expand") if collapsed else Texts.t("music_collapse")


func _on_drag_ended(_value_changed: bool) -> void:
	_dragging = false
	MusicPlayer.seek(_progress.value)


func _on_toggle_pressed() -> void:
	MusicPlayer.set_collapsed(not MusicPlayer.widget_collapsed)


func _show_notice(message: String) -> void:
	_notice.text = message
	_notice.visible = true
	_notice_timer.start(4.0)


func _control_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 84)
	button.add_theme_font_size_override("font_size", 30)
	button.theme_type_variation = &"SecondaryButton"
	button.pressed.connect(handler)
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColors.SURFACE
	style.border_color = ThemeColors.GRID
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	return style
