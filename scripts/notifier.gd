extends Node

# Local notifications: rest-end alerts and the daily streak reminder.
# Uses the NotificationScheduler Android plugin (addons/NotificationSchedulerPlugin).
# Everything here is a no-op on other platforms.

const Texts = preload("res://scripts/texts.gd")
const Streak = preload("res://scripts/streak.gd")

const CHANNEL_ID := "refitn_main"
const ICON_NAME := "ic_refitn_notification"
const REST_ID := 1001
const DAILY_ID := 1002
const TEST_ID := 1003
const DAY_SECONDS := 86400

signal initialized
signal permission_granted
signal permission_denied

var _scheduler
var _initialized := false


func _ready() -> void:
	if OS.get_name() != "Android":
		return
	_scheduler = NotificationScheduler.new()
	add_child(_scheduler)
	_scheduler.initialization_completed.connect(_on_initialized)
	_scheduler.post_notifications_permission_granted.connect(_on_permission_granted)
	_scheduler.post_notifications_permission_denied.connect(_on_permission_denied)
	_scheduler.initialize()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		refresh_daily()


func is_available() -> bool:
	return _scheduler != null and _initialized


func has_permission() -> bool:
	return is_available() and _scheduler.has_post_notifications_permission()


func request_permission() -> void:
	if is_available():
		_scheduler.request_post_notifications_permission()
	else:
		permission_denied.emit()


func open_settings() -> void:
	if is_available():
		_scheduler.open_app_info_settings()


func has_exact_alarm_permission() -> bool:
	return is_available() and _scheduler.has_schedule_exact_alarm_permission()


func request_exact_alarm_permission() -> void:
	if is_available():
		_scheduler.request_schedule_exact_alarm_permission()


func has_battery_exemption() -> bool:
	return is_available() and _scheduler.has_battery_optimizations_permission()


func request_battery_exemption() -> void:
	if is_available():
		_scheduler.request_battery_optimizations_permission()


func schedule_test(seconds: int) -> bool:
	if not has_permission():
		return false
	var data := NotificationData.new()
	data.set_id(TEST_ID).set_channel_id(CHANNEL_ID)
	data.set_title(Texts.t("notif_test_title")).set_content(Texts.t("notif_test_text"))
	data.set_small_icon_name(ICON_NAME).set_delay(seconds)
	_scheduler.schedule(data)
	return true


func schedule_rest(seconds: int) -> void:
	cancel_rest()
	if seconds <= 0 or not has_permission():
		return
	var data := NotificationData.new()
	data.set_id(REST_ID).set_channel_id(CHANNEL_ID)
	data.set_title(Texts.t("notif_rest_title")).set_content(Texts.t("notif_rest_text"))
	data.set_small_icon_name(ICON_NAME).set_delay(seconds)
	_scheduler.schedule(data)


func cancel_rest() -> void:
	if is_available():
		_scheduler.cancel(REST_ID)


func refresh_daily() -> void:
	if not is_available():
		return
	_scheduler.cancel(DAILY_ID)
	if not Storage.get_reminder_enabled() or not has_permission():
		return
	var now := Time.get_datetime_dict_from_system()
	var now_seconds := int(now.hour) * 3600 + int(now.minute) * 60 + int(now.second)
	var delay := Storage.get_reminder_minutes() * 60 - now_seconds
	var streak := Streak.calculate(Storage.workouts, 0, Storage.rest_day_numbers())
	if delay <= 0 or bool(streak.get("trained_today", false)):
		delay += DAY_SECONDS
	var current := int(streak.get("current", 0))
	var content := Texts.t("notif_daily_text") % [current, Texts.day_word(current)] if current > 0 else Texts.t("notif_daily_start")
	var data := NotificationData.new()
	data.set_id(DAILY_ID).set_channel_id(CHANNEL_ID)
	data.set_title(Texts.t("notif_daily_title")).set_content(content)
	data.set_small_icon_name(ICON_NAME).set_delay(delay).set_interval(DAY_SECONDS)
	_scheduler.schedule(data)


func _on_initialized() -> void:
	_initialized = true
	var channel := NotificationChannel.new()
	channel.set_id(CHANNEL_ID).set_name(Texts.t("notif_channel_name"))
	channel.set_description(Texts.t("notif_channel_desc"))
	channel.set_importance(NotificationChannel.Importance.HIGH)
	_scheduler.create_notification_channel(channel)
	refresh_daily()
	initialized.emit()


func _on_permission_granted(_permission_name: String) -> void:
	permission_granted.emit()
	refresh_daily()


func _on_permission_denied(_permission_name: String) -> void:
	permission_denied.emit()
