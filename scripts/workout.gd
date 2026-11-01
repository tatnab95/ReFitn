extends Control

const Texts = preload("res://scripts/texts.gd")

enum Phase { APPROACH, REST }

@onready var title_label: Label = $Margin/MainVBox/Header/HeaderInfo/Title
@onready var status_label: Label = $Margin/MainVBox/Header/HeaderInfo/Status
@onready var finish_button: Button = $Margin/MainVBox/Header/FinishButton

@onready var approach_view: VBoxContainer = $Margin/MainVBox/ApproachView
@onready var reps_caption: Label = $Margin/MainVBox/ApproachView/RepsCaption
@onready var reps_minus: Button = $Margin/MainVBox/ApproachView/RepsRow/RepsMinus
@onready var reps_value: Button = $Margin/MainVBox/ApproachView/RepsRow/RepsValue
@onready var reps_plus: Button = $Margin/MainVBox/ApproachView/RepsRow/RepsPlus
@onready var rest_caption: Label = $Margin/MainVBox/ApproachView/RestCaption
@onready var rest_minus: Button = $Margin/MainVBox/ApproachView/RestRow/RestMinus
@onready var rest_value: Button = $Margin/MainVBox/ApproachView/RestRow/RestValue
@onready var rest_plus: Button = $Margin/MainVBox/ApproachView/RestRow/RestPlus
@onready var hint_label: Label = $Margin/MainVBox/ApproachView/Hint
@onready var set_done_button: Button = $Margin/MainVBox/ApproachView/SetDoneButton

@onready var rest_view: VBoxContainer = $Margin/MainVBox/RestView
@onready var rest_title: Label = $Margin/MainVBox/RestView/RestTitle
@onready var countdown_label: Label = $Margin/MainVBox/RestView/Countdown
@onready var next_set_label: Label = $Margin/MainVBox/RestView/NextSetLabel
@onready var skip_rest_button: Button = $Margin/MainVBox/RestView/SkipRestButton

@onready var prompt_overlay: Control = $PromptOverlay
@onready var prompt_title: Label = $PromptOverlay/Center/PromptPanel/PromptMargin/PromptVBox/PromptTitle
@onready var prompt_body: Label = $PromptOverlay/Center/PromptPanel/PromptMargin/PromptVBox/PromptBody
@onready var more_five_button: Button = $PromptOverlay/Center/PromptPanel/PromptMargin/PromptVBox/MoreFiveButton
@onready var more_n_input: LineEdit = $PromptOverlay/Center/PromptPanel/PromptMargin/PromptVBox/MoreNRow/MoreNInput
@onready var more_n_button: Button = $PromptOverlay/Center/PromptPanel/PromptMargin/PromptVBox/MoreNRow/MoreNButton
@onready var prompt_finish_button: Button = $PromptOverlay/Center/PromptPanel/PromptMargin/PromptVBox/PromptFinishButton

@onready var number_dialog = $NumberInputDialog
@onready var beep_player: AudioStreamPlayer = $BeepPlayer

var exercise_id := "pullups"
var reps := 10
var rest_seconds := 120
var reps_step := 1
var rest_step := 10

var phase := Phase.APPROACH
var sets_done := 0
var total_reps := 0
var set_reps: Array = []
var work_ms := 0
var rest_ms := 0
var next_prompt_at := 5

var workout_started_unix := 0
var workout_id := ""
var session_finished := false

var phase_started_ms := 0
var rest_started_ms := 0
var rest_end_ms := 0
var last_countdown := -1

var editing_field := ""


func _ready() -> void:
	exercise_id = Storage.selected_exercise_id
	if not Texts.has_exercise(exercise_id):
		exercise_id = "pullups"
		Storage.selected_exercise_id = exercise_id

	reps = Storage.get_reps(exercise_id)
	rest_seconds = Storage.get_rest(exercise_id)
	reps_step = Storage.get_reps_step()
	rest_step = Storage.get_rest_step()
	workout_started_unix = int(Time.get_unix_time_from_system())
	phase_started_ms = Time.get_ticks_msec()

	title_label.text = Texts.exercise_name(exercise_id)
	_apply_texts()
	_connect_signals()
	_update_labels()
	_show_approach()

	beep_player.stream = _make_beep_stream()
	DisplayServer.screen_set_keep_on(true)
	set_process(false)


func _apply_texts() -> void:
	finish_button.text = Texts.t("finish")
	reps_minus.text = "−"
	reps_plus.text = "+"
	rest_minus.text = "−"
	rest_plus.text = "+"
	reps_caption.text = Texts.t("reps_caption")
	rest_caption.text = Texts.t("rest_caption")
	hint_label.text = Texts.t("rest_hint")
	set_done_button.text = Texts.t("set_done")
	rest_title.text = Texts.t("rest_caption")
	skip_rest_button.text = Texts.t("skip_rest")
	more_five_button.text = Texts.t("more_five")
	prompt_body.text = Texts.t("prompt_body")
	prompt_finish_button.text = Texts.t("finish")
	more_n_input.placeholder_text = Texts.t("more_n_placeholder")


func _connect_signals() -> void:
	reps_minus.pressed.connect(_change_reps.bind(-1))
	reps_plus.pressed.connect(_change_reps.bind(1))
	reps_value.pressed.connect(_open_number_input.bind("reps"))
	rest_minus.pressed.connect(_change_rest.bind(-1))
	rest_plus.pressed.connect(_change_rest.bind(1))
	rest_value.pressed.connect(_open_number_input.bind("rest"))
	set_done_button.pressed.connect(_on_set_done)
	skip_rest_button.pressed.connect(_on_skip_rest)
	finish_button.pressed.connect(_on_finish_pressed)
	more_five_button.pressed.connect(_on_more_five)
	more_n_button.pressed.connect(_on_more_n)
	prompt_finish_button.pressed.connect(_on_prompt_finish)
	more_n_input.text_changed.connect(_on_more_n_changed)
	more_n_input.text_submitted.connect(_on_more_n_submitted)
	number_dialog.submitted.connect(_on_number_submitted)


func _change_reps(delta: int) -> void:
	if phase != Phase.APPROACH:
		return
	reps = clampi(reps + delta * reps_step, 1, 999)
	Storage.set_reps(exercise_id, reps)
	_update_labels()


func _change_rest(delta: int) -> void:
	if phase != Phase.APPROACH:
		return
	rest_seconds = clampi(rest_seconds + delta * rest_step, 0, 3600)
	Storage.set_rest(exercise_id, rest_seconds)
	_update_labels()


func _open_number_input(field: String) -> void:
	if phase != Phase.APPROACH:
		return
	editing_field = field
	match field:
		"reps":
			number_dialog.open(Texts.t("dialog_reps"), reps, 1, 999)
		"rest":
			number_dialog.open(Texts.t("dialog_rest"), rest_seconds, 0, 3600)


func _on_number_submitted(value: int) -> void:
	if editing_field == "reps":
		reps = clampi(value, 1, 999)
		Storage.set_reps(exercise_id, reps)
	elif editing_field == "rest":
		rest_seconds = clampi(value, 0, 3600)
		Storage.set_rest(exercise_id, rest_seconds)
	editing_field = ""
	_update_labels()


func _update_labels() -> void:
	reps_value.text = str(reps)
	rest_value.text = Texts.format_time(rest_seconds)
	status_label.text = Texts.t("status_sets_reps") % [sets_done, total_reps]


func _on_set_done() -> void:
	if phase != Phase.APPROACH or session_finished:
		return

	var now := Time.get_ticks_msec()
	work_ms += maxi(0, now - phase_started_ms)
	sets_done += 1
	total_reps += reps
	set_reps.append(reps)

	_ensure_workout_started()
	_save_progress()
	_update_labels()

	if rest_seconds <= 0:
		phase = Phase.REST
		rest_started_ms = now
		rest_end_ms = now
		_finish_rest()
		return

	phase = Phase.REST
	rest_started_ms = now
	rest_end_ms = now + rest_seconds * 1000
	next_set_label.text = Texts.t("next_set") % reps
	last_countdown = -1
	approach_view.visible = false
	rest_view.visible = true
	_update_countdown()
	set_process(true)


func _process(_delta: float) -> void:
	if phase != Phase.REST:
		return

	var remaining := rest_end_ms - Time.get_ticks_msec()
	if remaining <= 0:
		_finish_rest()
		return

	var seconds_left := int(ceil(remaining / 1000.0))
	if seconds_left != last_countdown:
		last_countdown = seconds_left
		countdown_label.text = Texts.format_time(seconds_left)


func _update_countdown() -> void:
	var remaining := maxi(0, rest_end_ms - Time.get_ticks_msec())
	var seconds_left := int(ceil(remaining / 1000.0))
	last_countdown = seconds_left
	countdown_label.text = Texts.format_time(seconds_left)


func _finish_rest() -> void:
	if phase != Phase.REST:
		return

	var now := Time.get_ticks_msec()
	rest_ms += maxi(0, now - rest_started_ms)
	set_process(false)
	phase = Phase.APPROACH
	phase_started_ms = now
	_show_approach()
	_save_progress()
	_play_alert()
	_maybe_show_prompt()


func _on_skip_rest() -> void:
	if phase != Phase.REST:
		return

	var now := Time.get_ticks_msec()
	rest_ms += maxi(0, now - rest_started_ms)
	set_process(false)
	phase = Phase.APPROACH
	phase_started_ms = now
	_show_approach()
	_save_progress()
	_maybe_show_prompt()


func _show_approach() -> void:
	approach_view.visible = true
	rest_view.visible = false
	_update_labels()


func _maybe_show_prompt() -> void:
	if not session_finished and sets_done >= next_prompt_at:
		_show_prompt()


func _show_prompt() -> void:
	prompt_title.text = Texts.t("prompt_title") % sets_done
	more_n_input.text = "5"
	_update_more_n_button()
	prompt_overlay.visible = true


func _update_more_n_button() -> void:
	var count := int(more_n_input.text)
	if count < 1:
		more_n_button.text = Texts.t("more_n")
		more_n_button.disabled = true
	else:
		more_n_button.text = Texts.t("more_n_button") % count
		more_n_button.disabled = false


func _on_more_n_changed(new_text: String) -> void:
	var filtered := ""
	for character in new_text:
		if character >= "0" and character <= "9":
			filtered += character
	if filtered != new_text:
		var caret := more_n_input.caret_column
		more_n_input.text = filtered
		more_n_input.caret_column = mini(caret, filtered.length())
	_update_more_n_button()


func _on_more_n_submitted(_text: String) -> void:
	_on_more_n()


func _on_more_five() -> void:
	next_prompt_at = sets_done + 5
	prompt_overlay.visible = false


func _on_more_n() -> void:
	var count := int(more_n_input.text)
	if count < 1:
		return
	next_prompt_at = sets_done + count
	prompt_overlay.visible = false


func _on_prompt_finish() -> void:
	prompt_overlay.visible = false
	_on_finish_pressed()


func _on_finish_pressed() -> void:
	if session_finished:
		return
	session_finished = true

	var now := Time.get_ticks_msec()
	if phase == Phase.REST:
		rest_ms += maxi(0, now - rest_started_ms)
		set_process(false)
	else:
		work_ms += maxi(0, now - phase_started_ms)

	var work_seconds := int(round(work_ms / 1000.0))
	var rest_seconds_total := int(round(rest_ms / 1000.0))

	var summary := {
		"exercise_id": exercise_id,
		"exercise_name": Texts.exercise_name(exercise_id),
		"sets": sets_done,
		"reps": total_reps,
		"work_seconds": work_seconds,
		"rest_seconds": rest_seconds_total,
		"total_seconds": work_seconds + rest_seconds_total,
		"started_unix": workout_started_unix,
	}

	if not workout_id.is_empty():
		Storage.finish_workout(workout_id, {
			"sets": sets_done,
			"reps": total_reps,
			"set_reps": set_reps,
			"work_seconds": work_seconds,
			"rest_seconds": rest_seconds_total,
			"duration_seconds": work_seconds + rest_seconds_total,
		})

	Storage.last_summary = summary
	get_tree().change_scene_to_file("res://scenes/summary.tscn")


func _ensure_workout_started() -> void:
	if workout_id.is_empty():
		workout_id = Storage.begin_workout(exercise_id, workout_started_unix)


func _save_progress() -> void:
	if workout_id.is_empty():
		return
	var work_seconds := int(round(work_ms / 1000.0))
	var rest_seconds_total := int(round(rest_ms / 1000.0))
	Storage.update_workout(workout_id, {
		"sets": sets_done,
		"reps": total_reps,
		"set_reps": set_reps,
		"work_seconds": work_seconds,
		"rest_seconds": rest_seconds_total,
		"duration_seconds": work_seconds + rest_seconds_total,
	})


func _play_alert() -> void:
	if Storage.get_sound_enabled():
		beep_player.play()
	if Storage.get_vibration_enabled():
		Input.vibrate_handheld(400)


func _make_beep_stream() -> AudioStreamWAV:
	var sample_rate := 44100
	var duration := 0.35
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var progress := float(index) / float(sample_count)
		var attack := minf(1.0, progress * 25.0)
		var envelope := attack * pow(1.0 - progress, 2.0)
		var sample := int(sin(TAU * 880.0 * time) * envelope * 0.35 * 32767.0)
		data.encode_s16(index * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and phase == Phase.REST:
		_process(0.0)


func _exit_tree() -> void:
	set_process(false)
	DisplayServer.screen_set_keep_on(false)
