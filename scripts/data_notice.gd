extends Node

# Shows a message once when a user:// file could not be read and was renamed to .broken.

const Texts = preload("res://scripts/texts.gd")
const DataSafety = preload("res://scripts/data_safety.gd")


func _ready() -> void:
	if DataSafety.problems.is_empty():
		return
	var dialog := AcceptDialog.new()
	dialog.title = Texts.t("data_notice_title")
	dialog.dialog_text = "\n".join(DataSafety.problems)
	dialog.ok_button_text = Texts.t("ok")
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(900, 500))
	DataSafety.problems.clear()
