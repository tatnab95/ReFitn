extends RefCounted

# Versioned JSON files in user://. Unreadable files are renamed to .broken, never overwritten.
# Backups are copied to user://backups before any migration (last KEEP_BACKUPS kept).

const Texts = preload("res://scripts/texts.gd")

const SCHEMA_VERSION := 1
const BACKUP_DIR := "user://backups"
const KEEP_BACKUPS := 5

static var problems: Array[String] = []


static func stamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%04d%02d%02d-%02d%02d%02d" % [
		int(now.year), int(now.month), int(now.day),
		int(now.hour), int(now.minute), int(now.second),
	]


static func needs_migration(data: Variant) -> bool:
	if typeof(data) == TYPE_ARRAY:
		return true
	if typeof(data) == TYPE_DICTIONARY:
		return int(data.get("schema_version", 0)) < SCHEMA_VERSION
	return false


# Returns {"ok": bool, "data": Variant}. Missing file is ok with data null.
static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": true, "data": null}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "data": null}
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY and typeof(data) != TYPE_ARRAY:
		var broken := _move_to_broken(path)
		problems.append(Texts.t("data_broken_format") % [path.get_file(), broken.get_file()])
		return {"ok": false, "data": null}
	return {"ok": true, "data": data}


static func backup(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
	var base := path.get_file().get_basename()
	var target := BACKUP_DIR.path_join("%s-%s.json" % [base, stamp()])
	var err := DirAccess.copy_absolute(
		ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(target)
	)
	if err != OK:
		return ""
	_prune(base)
	return target


static func _prune(base: String) -> void:
	var dir := DirAccess.open(BACKUP_DIR)
	if dir == null:
		return
	var names: Array = []
	for file_name in dir.get_files():
		if file_name.begins_with(base + "-") and file_name.ends_with(".json"):
			names.append(file_name)
	names.sort()
	while names.size() > KEEP_BACKUPS:
		dir.remove(str(names.pop_front()))


static func _move_to_broken(path: String) -> String:
	var target := path + ".broken"
	if FileAccess.file_exists(target):
		target = "%s.%s.broken" % [path, stamp()]
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(target)
	)
	return target if err == OK else path
