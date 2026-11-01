extends RefCounted

# Photo recognition settings. Kept in their own file, outside Storage,
# so they are never included in statistics export or import.

const PATH := "user://ai_settings.json"
const DEFAULT_URL := "https://opencode.ai/zen/go/v1"


static func load_settings() -> Dictionary:
	var result := {"api_key": "", "base_url": DEFAULT_URL, "model": ""}
	if not FileAccess.file_exists(PATH):
		return result
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return result
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return result
	result.api_key = str(data.get("api_key", "")).strip_edges()
	var url := str(data.get("base_url", DEFAULT_URL)).strip_edges()
	result.base_url = url if not url.is_empty() else DEFAULT_URL
	result.model = str(data.get("model", "")).strip_edges()
	return result


static func save_settings(settings: Dictionary) -> Error:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(settings, "\t"))
	return OK
