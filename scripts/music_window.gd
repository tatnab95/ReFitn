extends Control

# Full-screen music window opened from settings: tracks, cover, order, mode, volume, on/off.

const Texts = preload("res://scripts/texts.gd")
const ThemeColors = preload("res://scripts/theme_colors.gd")
const THUMB := Vector2(96, 96)

var _enable_check: CheckButton
var _volume_slider: HSlider
var _mode_option: OptionButton
var _list: VBoxContainer
var _empty_label: Label
var _notice: Label
var _confirm: ConfirmationDialog
var _delete_id := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var background := ColorRect.new()
	background.color = ThemeColors.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36 if side == "left" or side == "right" else 48)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var header := HBoxContainer.new()
	var title := _label(Texts.t("music_title"), 44, ThemeColors.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _button(Texts.t("music_close"), "SecondaryButton")
	close.custom_minimum_size = Vector2(200, 88)
	close.pressed.connect(hide)
	header.add_child(close)
	box.add_child(header)

	_enable_check = CheckButton.new()
	_enable_check.text = Texts.t("music_enabled")
	_enable_check.add_theme_font_size_override("font_size", 30)
	_enable_check.toggled.connect(func(value: bool) -> void: MusicPlayer.set_enabled(value))
	box.add_child(_enable_check)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 14)
	volume_row.add_child(_label(Texts.t("music_volume"), 30, ThemeColors.MUTED))
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.custom_minimum_size = Vector2(0, 50)
	_volume_slider.value_changed.connect(func(value: float) -> void: MusicPlayer.set_volume(value))
	volume_row.add_child(_volume_slider)
	box.add_child(volume_row)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 14)
	mode_row.add_child(_label(Texts.t("music_mode"), 30, ThemeColors.MUTED))
	_mode_option = OptionButton.new()
	_mode_option.add_theme_font_size_override("font_size", 28)
	_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode_option.add_item(Texts.t("music_mode_all"), 0)
	_mode_option.add_item(Texts.t("music_mode_one"), 1)
	_mode_option.add_item(Texts.t("music_mode_random"), 2)
	_mode_option.item_selected.connect(func(index: int) -> void: MusicPlayer.set_mode(MusicPlayer.MODES[index]))
	mode_row.add_child(_mode_option)
	box.add_child(mode_row)

	var add := _button(Texts.t("music_add"), "SuccessButton")
	add.pressed.connect(_pick_audio)
	box.add_child(add)

	box.add_child(_label(Texts.t("music_rename_hint"), 24, ThemeColors.MUTED))
	_notice = _label("", 26, ThemeColors.ERROR)
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.visible = false
	box.add_child(_notice)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)
	_empty_label = _label(Texts.t("music_empty"), 30, ThemeColors.MUTED)
	box.add_child(_empty_label)

	_confirm = ConfirmationDialog.new()
	_confirm.title = Texts.t("music_delete")
	_confirm.ok_button_text = Texts.t("music_delete")
	_confirm.cancel_button_text = Texts.t("music_close")
	_confirm.confirmed.connect(_on_delete_confirmed)
	add_child(_confirm)

	MusicPlayer.changed.connect(_refresh)
	MusicPlayer.notice.connect(func(message: String) -> void: _show_notice(message, true))
	visible = false


func open() -> void:
	show()
	_sync_controls()
	_refresh()


func _sync_controls() -> void:
	_enable_check.set_pressed_no_signal(MusicPlayer.enabled)
	_volume_slider.set_value_no_signal(MusicPlayer.volume)
	_mode_option.select(maxi(0, MusicPlayer.MODES.find(MusicPlayer.mode)))


func _refresh() -> void:
	if not visible:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for track in MusicPlayer.tracks:
		_list.add_child(_track_row(track))
	_empty_label.visible = MusicPlayer.tracks.is_empty()


func _track_row(track: Dictionary) -> Control:
	var track_id := str(track.id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_thumbnail(MusicPlayer.cover_texture(track)))

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	var name_edit := LineEdit.new()
	name_edit.text = str(track.title)
	name_edit.add_theme_font_size_override("font_size", 30)
	name_edit.text_submitted.connect(func(text: String) -> void: MusicPlayer.rename_track(track_id, text))
	name_edit.focus_exited.connect(func() -> void: MusicPlayer.rename_track(track_id, name_edit.text))
	box.add_child(name_edit)

	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 8)
	var is_current := track_id == MusicPlayer.current_id and MusicPlayer.is_playing()
	buttons.add_child(_small_button(Texts.t("music_pause") if is_current else Texts.t("music_play"), func() -> void: _on_play_pressed(track_id)))
	buttons.add_child(_small_button(Texts.t("music_up"), func() -> void: MusicPlayer.move_track(track_id, -1)))
	buttons.add_child(_small_button(Texts.t("music_down"), func() -> void: MusicPlayer.move_track(track_id, 1)))
	buttons.add_child(_small_button(Texts.t("music_add_cover"), func() -> void: _pick_cover(track_id)))
	buttons.add_child(_small_button(Texts.t("music_delete"), func() -> void: _ask_delete(track_id), ThemeColors.ERROR))
	box.add_child(buttons)

	row.add_child(box)
	return row


func _thumbnail(texture: Texture2D) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = THUMB
	var background := ColorRect.new()
	background.color = ThemeColors.SURFACE_ALT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(background)
	if texture != null:
		var picture := TextureRect.new()
		picture.texture = texture
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(picture)
	return holder


func _on_play_pressed(track_id: String) -> void:
	if track_id == MusicPlayer.current_id:
		MusicPlayer.toggle_play()
	else:
		MusicPlayer.play_track(track_id)


func _ask_delete(track_id: String) -> void:
	_delete_id = track_id
	_confirm.dialog_text = Texts.t("music_delete") + ": " + str(MusicPlayer.track_by_id(track_id).get("title", "")) + "?"
	_confirm.popup_centered(Vector2i(900, 500))


func _on_delete_confirmed() -> void:
	MusicPlayer.remove_track(_delete_id)
	_delete_id = ""


func _pick_audio() -> void:
	_pick_files(Texts.t("music_add"), "*.mp3,*.ogg,*.wav;" + Texts.t("music_audio_filter"), _on_audio_picked)


func _pick_cover(track_id: String) -> void:
	_pick_files(Texts.t("music_add_cover"), "*.png,*.jpg,*.jpeg;" + Texts.t("music_image_filter"), _on_cover_picked.bind(track_id))


func _pick_files(title: String, filter: String, handler: Callable) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		_show_notice(Texts.t("music_no_picker"), true)
		return
	var error := DisplayServer.file_dialog_show(
		title, "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILES, PackedStringArray([filter]), handler
	)
	if error != OK:
		_show_notice(Texts.t("music_no_picker"), true)


func _on_audio_picked(status: bool, paths: PackedStringArray, _filter: int) -> void:
	if not status or paths.is_empty():
		return
	var errors := PackedStringArray()
	var added := 0
	for path in paths:
		var message := MusicPlayer.import_audio(path)
		if message.is_empty():
			added += 1
		else:
			errors.append(message)
	var text := Texts.t("music_added") % added
	if not errors.is_empty():
		text += "\n" + "\n".join(errors)
	_show_notice(text, not errors.is_empty())


func _on_cover_picked(status: bool, paths: PackedStringArray, _filter: int, track_id: String) -> void:
	if not status or paths.is_empty():
		return
	var message := MusicPlayer.set_cover(track_id, paths[0])
	_show_notice(message if not message.is_empty() else Texts.t("music_cover_saved"), not message.is_empty())


func _show_notice(message: String, is_error: bool) -> void:
	_notice.text = message
	_notice.add_theme_color_override("font_color", ThemeColors.ERROR if is_error else ThemeColors.GREEN_BRIGHT)
	_notice.visible = not message.is_empty()


func _small_button(text: String, handler: Callable, color: Color = Color(0, 0, 0, 0)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 72)
	button.add_theme_font_size_override("font_size", 26)
	button.theme_type_variation = &"SecondaryButton"
	if color.a > 0.0:
		button.add_theme_color_override("font_color", color)
	button.pressed.connect(handler)
	return button


func _button(text: String, variation: String) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = StringName(variation)
	button.custom_minimum_size = Vector2(0, 88)
	button.add_theme_font_size_override("font_size", 30)
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
