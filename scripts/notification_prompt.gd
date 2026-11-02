extends Node

# Explains and requests the notification permission on app start when it is off.
# Shown at most once per app run, so "Позже" does not nag on every screen.

const Texts = preload("res://scripts/texts.gd")

static var _shown := false

var _dialog: ConfirmationDialog


func _ready() -> void:
	if OS.get_name() != "Android" or _shown:
		return
	if Notifier.is_available():
		_check()
	else:
		Notifier.initialized.connect(_check, CONNECT_ONE_SHOT)


func _check() -> void:
	if _shown or Notifier.has_permission():
		return
	_shown = true
	_dialog = ConfirmationDialog.new()
	_dialog.title = Texts.t("notif_prompt_title")
	_dialog.dialog_text = Texts.t("notif_prompt_text")
	_dialog.ok_button_text = Texts.t("notif_prompt_allow")
	_dialog.cancel_button_text = Texts.t("notif_prompt_later")
	_dialog.confirmed.connect(Notifier.request_permission)
	add_child(_dialog)
	_dialog.popup_centered(Vector2i(900, 600))
