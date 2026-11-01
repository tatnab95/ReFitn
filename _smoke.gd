extends Node

const Streak = preload("res://scripts/streak.gd")
const Texts = preload("res://scripts/texts.gd")


func _ready() -> void:
	var failures: Array[String] = []

	for path in ["user://workouts.json", "user://settings.json", "user://nutrition.json", "user://backup-test.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Storage.load_all()

	var now := int(Time.get_unix_time_from_system())

	# Streak: today + four previous days = 5.
	var fake := []
	for offset in range(5):
		fake.append({"started_unix": now - offset * 86400, "sets": 1})
	var info := Streak.calculate(fake, now)
	if int(info.current) != 5:
		failures.append("streak current expected 5 got %d" % int(info.current))
	if int(info.record) != 5:
		failures.append("streak record expected 5 got %d" % int(info.record))
	if not bool(info.trained_today):
		failures.append("streak should be trained today")

	var no_today := []
	for offset in range(1, 4):
		no_today.append({"started_unix": now - offset * 86400, "sets": 1})
	var pending := Streak.calculate(no_today, now)
	if int(pending.current) != 3:
		failures.append("pending streak expected 3 got %d" % int(pending.current))
	if bool(pending.trained_today):
		failures.append("pending streak should not be trained today")

	# Workout storage with per-set reps.
	var workout_ids := []
	for offset in range(3):
		var workout_id := Storage.begin_workout("pullups", now - offset * 86400)
		Storage.finish_workout(workout_id, {
			"sets": 3,
			"reps": 30,
			"set_reps": [10, 10, 10],
			"work_seconds": 120,
			"rest_seconds": 60,
			"duration_seconds": 180,
		})
		workout_ids.append(workout_id)
	if Storage.workouts.size() != 3:
		failures.append("expected 3 workouts")

	# Nutrition and water.
	var today_key := Streak.day_key_from_unix(now)
	var food_a := Storage.add_food_entry("Овсянка", 350, 12, 8, 55)
	Storage.add_food_entry("Курица", 450, 40, 15, 20)
	Storage.add_water(500)
	Storage.add_water(250)
	var totals := Storage.get_day_totals(today_key)
	if int(totals.calories) != 800:
		failures.append("calories expected 800 got %d" % int(totals.calories))
	if int(totals.protein) != 52:
		failures.append("protein expected 52 got %d" % int(totals.protein))
	if int(totals.water) != 750:
		failures.append("water expected 750 got %d" % int(totals.water))

	# Settings.
	Storage.save_goals({"calories": 2600, "protein": 160, "fat": 80, "carbs": 310, "water": 2200})
	Storage.set_steps(2, 15)
	Storage.set_feedback(false, true)
	Storage.load_all()
	if int(Storage.get_goals().calories) != 2600:
		failures.append("goals did not persist")
	if Storage.get_reps_step() != 2 or Storage.get_rest_step() != 15:
		failures.append("steps did not persist")
	if Storage.get_sound_enabled() or not Storage.get_vibration_enabled():
		failures.append("feedback did not persist")
	if Storage.nutrition_entries.size() != 2:
		failures.append("nutrition did not persist")
	if Storage.get_water(today_key) != 750:
		failures.append("water did not persist")

	# Export payload includes everything.
	var export_path := "user://backup-test.json"
	if Storage.export_workouts(export_path) != OK:
		failures.append("export failed")
	else:
		var file := FileAccess.open(export_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		for key in ["workouts", "nutrition", "water", "settings", "streak_record"]:
			if not data.has(key):
				failures.append("export missing " + key)

	# Mutate then import restores nutrition/water/goals.
	Storage.delete_food_entry(str(food_a.id))
	Storage.set_water(0)
	Storage.save_goals({"calories": 1, "protein": 1, "fat": 1, "carbs": 1, "water": 1})
	var added := Storage.import_workouts(export_path)
	if added != 0:
		failures.append("reimport should add 0 workouts, got %d" % added)
	if Storage.nutrition_entries.size() != 2:
		failures.append("import did not restore nutrition")
	if Storage.get_water(today_key) != 750:
		failures.append("import did not restore water")
	if int(Storage.get_goals().calories) != 2600:
		failures.append("import did not restore goals")
	if int(Storage.last_import_info.get("nutrition", 0)) != 1:
		failures.append("import info nutrition expected 1")

	# Texts/plural smoke.
	if Texts.format_streak(1).find("день") < 0:
		failures.append("streak plural 1")
	if Texts.format_streak(3).find("дня") < 0:
		failures.append("streak plural 3")
	if Texts.format_streak(5).find("дней") < 0:
		failures.append("streak plural 5")

	# Stats tabs with real data.
	var stats = load("res://scenes/stats.tscn").instantiate()
	add_child(stats)
	await process_frame
	await process_frame
	for tab in [1, 3, 0]:
		stats.tabs.current_tab = tab
		await process_frame
		await process_frame
	stats.queue_free()
	await process_frame

	if failures.is_empty():
		print("SMOKE OK")
		get_tree().quit(0)
	else:
		for failure in failures:
			printerr("SMOKE FAIL: " + failure)
		get_tree().quit(1)
