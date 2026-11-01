extends PanelContainer

# Segmented pill switch that drives an existing TabContainer.
# The tab strip itself is hidden; the tab contents and tab_changed logic stay as they were.

const SEGMENT_HEIGHT := 84
const FONT_SIZE := 30

var _tabs: TabContainer
var _buttons: Array[Button] = []


func setup(tabs: TabContainer, titles: Array) -> void:
	_tabs = tabs
	tabs.tabs_visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var group := ButtonGroup.new()
	for index in range(titles.size()):
		var button := Button.new()
		button.text = titles[index]
		button.toggle_mode = true
		button.button_group = group
		button.theme_type_variation = &"SegmentButton"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, SEGMENT_HEIGHT)
		button.set_meta("compact", true)
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.pressed.connect(_on_pressed.bind(index))
		row.add_child(button)
		_buttons.append(button)
	tabs.tab_changed.connect(_sync)
	_sync(tabs.current_tab)


func _on_pressed(index: int) -> void:
	_tabs.current_tab = index


func _sync(index: int) -> void:
	for i in range(_buttons.size()):
		_buttons[i].button_pressed = i == index
