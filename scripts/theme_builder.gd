extends RefCounted

# Builds the app Theme from theme_colors.gd and applies it to the root window.
# Also holds the small global behaviours: press feedback, scene fade-in,
# minimum button height and safe-area insets.

const ThemeColors = preload("res://scripts/theme_colors.gd")

const RADIUS := 20
const PILL_RADIUS := 60
const BUTTON_MIN_HEIGHT := 120.0
const FADE_SECONDS := 0.15
const PRESS_SCALE := 0.97
const PRESS_SECONDS := 0.08
const REDRAW_GROUP := "themed"

static var _hooked := false


static func apply(root: Window) -> void:
	var dark := resolve_dark(Storage.get_theme_mode())
	ThemeColors.apply(dark)
	root.theme = build_theme()
	RenderingServer.set_default_clear_color(ThemeColors.BG)
	root.get_tree().call_group(REDRAW_GROUP, "queue_redraw")
	if not _hooked:
		_hooked = true
		root.get_tree().node_added.connect(_on_node_added)
	_walk_tree(root)


static func resolve_dark(mode: String) -> bool:
	match mode:
		"light":
			return false
		"system":
			return DisplayServer.is_dark_mode() if DisplayServer.is_dark_mode_supported() else true
	return true


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 32

	theme.set_stylebox("normal", "Button", _box(ThemeColors.BLUE))
	theme.set_stylebox("hover", "Button", _box(ThemeColors.BLUE_SOFT))
	theme.set_stylebox("pressed", "Button", _box(ThemeColors.BLUE_DEEP))
	theme.set_stylebox("disabled", "Button", _box(ThemeColors.SURFACE_DISABLED))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	_set_button_colors(theme, "Button", ThemeColors.TEXT, ThemeColors.TEXT, ThemeColors.TEXT)
	theme.set_color("font_disabled_color", "Button", ThemeColors.MUTED)
	theme.set_font_size("font_size", "Button", 40)

	_variation(theme, "PrimaryButton", {
		"normal": _box(ThemeColors.BLUE, ThemeColors.GOLD, 3),
		"hover": _box(ThemeColors.BLUE_SOFT, ThemeColors.GOLD, 3),
		"pressed": _box(ThemeColors.BLUE_DEEP, ThemeColors.GOLD, 3),
	})
	_variation(theme, "SuccessButton", {
		"normal": _box(ThemeColors.GREEN),
		"hover": _box(ThemeColors.GREEN_BRIGHT),
		"pressed": _box(ThemeColors.GREEN_DARK),
	}, ThemeColors.ON_GREEN)
	_variation(theme, "DangerButton", {
		"normal": _box(ThemeColors.TRANSPARENT, ThemeColors.ERROR, 3),
		"hover": _box(Color(ThemeColors.ERROR, 0.12), ThemeColors.ERROR, 3),
		"pressed": _box(Color(ThemeColors.ERROR, 0.25), ThemeColors.ERROR, 3),
	}, ThemeColors.ERROR)
	_variation(theme, "SecondaryButton", {
		"normal": _box(ThemeColors.SURFACE_ALT, ThemeColors.GRID, 2),
		"hover": _box(ThemeColors.SURFACE_HOVER, ThemeColors.GRID, 2),
		"pressed": _box(ThemeColors.SURFACE_PRESSED, ThemeColors.GRID, 2),
	})
	_variation(theme, "NutritionButton", {
		"normal": _box(ThemeColors.BLUE, ThemeColors.GREEN, 3),
		"hover": _box(ThemeColors.BLUE_SOFT, ThemeColors.GREEN, 3),
		"pressed": _box(ThemeColors.BLUE_DEEP, ThemeColors.GREEN, 3),
	})
	_variation(theme, "RoundButton", {
		"normal": _box(ThemeColors.BLUE, ThemeColors.GRID, 2, PILL_RADIUS),
		"hover": _box(ThemeColors.BLUE_SOFT, ThemeColors.GRID, 2, PILL_RADIUS),
		"pressed": _box(ThemeColors.BLUE_DEEP, ThemeColors.GRID, 2, PILL_RADIUS),
	})
	_variation(theme, "SegmentButton", {
		"normal": _box(ThemeColors.TRANSPARENT, ThemeColors.TRANSPARENT, 0, PILL_RADIUS),
		"hover": _box(ThemeColors.SURFACE_HOVER, ThemeColors.TRANSPARENT, 0, PILL_RADIUS),
		"pressed": _box(ThemeColors.BLUE, ThemeColors.GOLD, 2, PILL_RADIUS),
	})
	theme.set_color("font_color", "SegmentButton", ThemeColors.MUTED)
	theme.set_color("font_pressed_color", "SegmentButton", ThemeColors.TEXT)
	theme.set_color("font_hover_pressed_color", "SegmentButton", ThemeColors.TEXT)

	theme.set_stylebox("panel", "PanelContainer", _box(ThemeColors.SURFACE, ThemeColors.GRID, 1))

	theme.set_stylebox("normal", "LineEdit", _box(ThemeColors.SURFACE_ALT, ThemeColors.GRID, 2, 16))
	theme.set_stylebox("focus", "LineEdit", _box(ThemeColors.SURFACE_ALT, ThemeColors.GOLD, 2, 16))
	theme.set_stylebox("read_only", "LineEdit", _box(ThemeColors.SURFACE_DISABLED, ThemeColors.GRID, 2, 16))
	theme.set_color("font_color", "LineEdit", ThemeColors.TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color(ThemeColors.MUTED, 0.7))
	theme.set_color("caret_color", "LineEdit", ThemeColors.GOLD)
	theme.set_color("selection_color", "LineEdit", Color(ThemeColors.GREEN, 0.4))
	theme.set_font_size("font_size", "LineEdit", 36)

	theme.set_stylebox("background", "ProgressBar", _box(ThemeColors.SURFACE_ALT, ThemeColors.TRANSPARENT, 0, 12))
	theme.set_stylebox("fill", "ProgressBar", _box(ThemeColors.GREEN, ThemeColors.TRANSPARENT, 0, 12))

	for bar in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", bar, StyleBoxEmpty.new())
		theme.set_stylebox("grabber", bar, _box(ThemeColors.GRID, ThemeColors.TRANSPARENT, 0, 8))
		theme.set_stylebox("grabber_highlight", bar, _box(ThemeColors.MUTED, ThemeColors.TRANSPARENT, 0, 8))
		theme.set_stylebox("grabber_pressed", bar, _box(ThemeColors.GOLD, ThemeColors.TRANSPARENT, 0, 8))

	theme.set_color("font_color", "Label", ThemeColors.TEXT)
	theme.set_font_size("font_size", "Label", 32)
	theme.set_color("font_color", "CheckButton", ThemeColors.TEXT)
	theme.set_font_size("font_size", "CheckButton", 32)
	theme.set_stylebox("panel", "PopupMenu", _box(ThemeColors.SURFACE, ThemeColors.GRID, 2, 16))
	theme.set_stylebox("hover", "PopupMenu", _box(ThemeColors.SURFACE_HOVER, ThemeColors.TRANSPARENT, 0, 12))
	theme.set_color("font_color", "PopupMenu", ThemeColors.TEXT)
	theme.set_color("font_hover_color", "PopupMenu", ThemeColors.TEXT)
	theme.set_font_size("font_size", "PopupMenu", 28)
	return theme


static func _box(bg: Color, border: Color = ThemeColors.TRANSPARENT, border_width: int = 0, radius: int = RADIUS) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	if border_width > 0:
		box.set_border_width_all(border_width)
		box.border_color = border
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	return box


static func _variation(theme: Theme, name: String, styles: Dictionary, font_color: Color = ThemeColors.TEXT) -> void:
	theme.set_type_variation(name, "Button")
	for state in styles:
		theme.set_stylebox(state, name, styles[state])
	_set_button_colors(theme, name, font_color, font_color, font_color)


static func _set_button_colors(theme: Theme, type_name: String, normal: Color, hover: Color, pressed: Color) -> void:
	theme.set_color("font_color", type_name, normal)
	theme.set_color("font_hover_color", type_name, hover)
	theme.set_color("font_pressed_color", type_name, pressed)
	theme.set_color("font_focus_color", type_name, normal)


static func _on_node_added(node: Node) -> void:
	if node is Button:
		_setup_button.call_deferred(node)
	elif node is MarginContainer and node.name == "Margin":
		_apply_safe_area.call_deferred(node)
	elif node is Control and node.get_parent() == node.get_tree().root:
		_fade_in.call_deferred(node)
	if node is ScrollContainer:
		_setup_scroll.call_deferred(node)
	elif node is Control:
		_setup_scroll_child.call_deferred(node)


static func _walk_tree(node: Node) -> void:
	if node is Button:
		_setup_button.call_deferred(node)
	elif node is MarginContainer and node.name == "Margin":
		_apply_safe_area.call_deferred(node)
	if node is ScrollContainer:
		_setup_scroll.call_deferred(node)
	elif node is Control:
		_setup_scroll_child.call_deferred(node)
	for child in node.get_children():
		_walk_tree(child)


static func _setup_scroll(scroll: ScrollContainer) -> void:
	if not is_instance_valid(scroll) or scroll.has_meta("scroll_hooked"):
		return
	scroll.set_meta("scroll_hooked", true)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var watcher := _ScrollKeyboardWatcher.new(scroll)
	watcher.name = "_ScrollKeyboardWatcher"
	scroll.add_child(watcher)
	for child in scroll.get_children():
		_pass_mouse_in_scroll(child)


static func _setup_scroll_child(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			if control.mouse_filter == Control.MOUSE_FILTER_STOP:
				control.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		parent = parent.get_parent()


static func _pass_mouse_in_scroll(node: Node) -> void:
	if node is Control and not (node is ScrollBar):
		var c := node as Control
		if c.mouse_filter == Control.MOUSE_FILTER_STOP:
			c.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		_pass_mouse_in_scroll(child)


class _ScrollKeyboardWatcher extends Node:
	var _scroll: ScrollContainer
	var _spacer: Control
	var _last_kb_height := 0.0
	var _last_focused: Control = null
	var _pending_frames := 0

	func _init(scroll: ScrollContainer) -> void:
		_scroll = scroll

	func _process(_delta: float) -> void:
		if not is_instance_valid(_scroll) or not _scroll.is_visible_in_tree():
			return
		var content := _get_content()
		if content == null:
			return
		var kb_px := DisplayServer.virtual_keyboard_get_height() if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) else 0
		var kb_height := 0.0
		if kb_px > 0:
			var win_h := float(DisplayServer.window_get_size().y)
			var view_h := _scroll.get_viewport_rect().size.y
			kb_height = (float(kb_px) * view_h / win_h) if win_h > 0.0 else float(kb_px)

		var focused := _scroll.get_viewport().gui_get_focus_owner()
		var focused_in_scroll := focused != null and _scroll.is_ancestor_of(focused)

		var target_spacer := 0.0
		if kb_height > 0.0 and focused_in_scroll:
			var view_h := _scroll.get_viewport_rect().size.y
			var scroll_bottom := _scroll.get_global_rect().end.y
			var below_scroll := maxf(0.0, view_h - scroll_bottom)
			target_spacer = maxf(0.0, kb_height - below_scroll + 36.0)

		_ensure_spacer(content, target_spacer)

		if focused_in_scroll and (focused != _last_focused or not is_equal_approx(kb_height, _last_kb_height)):
			_pending_frames = 3
		_last_focused = focused if focused_in_scroll else null
		_last_kb_height = kb_height

		if _pending_frames > 0 and focused_in_scroll:
			_pending_frames -= 1
			_scroll_to_control(focused, kb_height)

	func _get_content() -> Control:
		for child in _scroll.get_children():
			if child is Control and not (child is ScrollBar):
				return child as Control
		return null

	func _ensure_spacer(content: Control, target_height: float) -> void:
		if target_height <= 0.0:
			if _spacer != null and is_instance_valid(_spacer):
				_spacer.visible = false
				_spacer.custom_minimum_size = Vector2.ZERO
			return
		if _spacer == null or not is_instance_valid(_spacer):
			_spacer = Control.new()
			_spacer.name = "_KeyboardSpacer"
			_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(_spacer)
		if _spacer.get_parent() == content and _spacer.get_index() != content.get_child_count() - 1:
			content.move_child(_spacer, content.get_child_count() - 1)
		_spacer.visible = true
		_spacer.custom_minimum_size = Vector2(0.0, target_height)

	func _scroll_to_control(focused: Control, kb_height: float) -> void:
		if not is_instance_valid(focused):
			return
		var view_h := _scroll.get_viewport_rect().size.y
		var scroll_rect := _scroll.get_global_rect()
		var visible_top := scroll_rect.position.y + 16.0
		var visible_bottom := scroll_rect.end.y - 16.0
		if kb_height > 0.0:
			visible_bottom = minf(visible_bottom, view_h - kb_height - 24.0)
		if visible_bottom <= visible_top:
			return
		var f_rect := focused.get_global_rect()
		if f_rect.end.y > visible_bottom:
			_scroll.scroll_vertical += int(ceil(f_rect.end.y - visible_bottom))
		elif f_rect.position.y < visible_top:
			_scroll.scroll_vertical = maxi(0, _scroll.scroll_vertical - int(ceil(visible_top - f_rect.position.y)))


static func _setup_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta("themed"):
		return
	button.set_meta("themed", true)
	if button.theme_type_variation != &"SegmentButton" and button.theme_type_variation != &"RoundButton" and not button.has_meta("compact"):
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, BUTTON_MIN_HEIGHT)
	button.pivot_offset = button.size * 0.5
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.button_down.connect(_press.bind(button, PRESS_SCALE))
	button.button_up.connect(_press.bind(button, 1.0))


static func _press(button: Button, target: float) -> void:
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(target, target), PRESS_SECONDS)


static func _apply_safe_area(margin: MarginContainer) -> void:
	if not is_instance_valid(margin) or margin.get_parent() == null or margin.get_parent().get_parent() != margin.get_tree().root:
		return
	var insets := safe_insets(margin)
	if insets == Vector4.ZERO:
		return
	margin.add_theme_constant_override("margin_left", margin.get_theme_constant("margin_left") + ceili(insets.x))
	margin.add_theme_constant_override("margin_top", margin.get_theme_constant("margin_top") + ceili(insets.y))
	margin.add_theme_constant_override("margin_right", margin.get_theme_constant("margin_right") + ceili(insets.z))
	margin.add_theme_constant_override("margin_bottom", margin.get_theme_constant("margin_bottom") + ceili(insets.w))


static func safe_insets(node: Node) -> Vector4:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var view := node.get_viewport().get_visible_rect().size
	var scale := view / window_size
	var left := safe.position.x * scale.x
	var top := safe.position.y * scale.y
	var right := (window_size.x - safe.end.x) * scale.x
	var bottom := (window_size.y - safe.end.y) * scale.y
	return Vector4(maxf(0.0, left), maxf(0.0, top), maxf(0.0, right), maxf(0.0, bottom))


static func _fade_in(node: Control) -> void:
	if not is_instance_valid(node):
		return
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, FADE_SECONDS)
