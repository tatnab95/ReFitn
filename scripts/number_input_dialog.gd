extends Control

signal submitted(value: int)

const Texts = preload("res://scripts/texts.gd")

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var input: LineEdit = $Center/Panel/Margin/VBox/Input
@onready var cancel_button: Button = $Center/Panel/Margin/VBox/Buttons/Cancel
@onready var ok_button: Button = $Center/Panel/Margin/VBox/Buttons/Ok

var min_value := 0
var max_value := 9999


func _ready() -> void:
	hide()
	cancel_button.text = Texts.t("cancel")
	ok_button.text = Texts.t("ok")
	cancel_button.pressed.connect(close)
	ok_button.pressed.connect(_submit)
	input.text_submitted.connect(_on_text_submitted)
	input.text_changed.connect(_on_text_changed)


func open(dialog_title: String, current: int, min_allowed: int, max_allowed: int) -> void:
	title_label.text = dialog_title
	min_value = min_allowed
	max_value = max_allowed
	input.text = str(clampi(current, min_value, max_value))
	show()
	input.grab_focus()
	input.select_all()


func close() -> void:
	hide()
	input.release_focus()


func _submit() -> void:
	var value := clampi(int(input.text), min_value, max_value)
	close()
	submitted.emit(value)


func _on_text_submitted(_text: String) -> void:
	_submit()


func _on_text_changed(new_text: String) -> void:
	var filtered := ""
	for character in new_text:
		if character >= "0" and character <= "9":
			filtered += character
	if filtered != new_text:
		var caret := input.caret_column
		input.text = filtered
		input.caret_column = mini(caret, filtered.length())
