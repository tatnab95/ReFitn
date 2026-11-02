extends RefCounted

# Photo recognition settings and cached model list. Kept in their own files,
# outside Storage, so they are never included in statistics export or import.

const DataSafety = preload("res://scripts/data_safety.gd")

const PATH := "user://ai_settings.json"
const MODELS_CACHE_PATH := "user://ai_models_cache.json"
const DEFAULT_URL := "https://opencode.ai/zen/go/v1"


static func load_settings() -> Dictionary:
	var result := {"api_key": "", "base_url": DEFAULT_URL, "model": ""}
	var loaded: Dictionary = DataSafety.read_json(PATH)
	if not bool(loaded.get("ok", false)) or typeof(loaded.get("data")) != TYPE_DICTIONARY:
		return result
	var data: Dictionary = loaded.get("data")
	result.api_key = str(data.get("api_key", "")).strip_edges()
	var url := str(data.get("base_url", DEFAULT_URL)).strip_edges()
	result.base_url = url if not url.is_empty() else DEFAULT_URL
	result.model = str(data.get("model", "")).strip_edges()
	if DataSafety.needs_migration(data):
		DataSafety.backup(PATH)
		save_settings(result)
	return result


static func save_settings(settings: Dictionary) -> Error:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var data := settings.duplicate()
	data["schema_version"] = DataSafety.SCHEMA_VERSION
	file.store_string(JSON.stringify(data, "\t"))
	return OK


static func load_models_cache() -> Dictionary:
	var result := {"models": [], "has_vision_metadata": false, "base_url": DEFAULT_URL}
	if not FileAccess.file_exists(MODELS_CACHE_PATH):
		return result
	var file := FileAccess.open(MODELS_CACHE_PATH, FileAccess.READ)
	if file == null:
		return result
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return result
	var raw_models = data.get("models", [])
	var models: Array = []
	if typeof(raw_models) == TYPE_ARRAY:
		for m in raw_models:
			var s := str(m).strip_edges()
			if not s.is_empty() and s not in models:
				models.append(s)
	result.models = models
	result.has_vision_metadata = bool(data.get("has_vision_metadata", false))
	result.base_url = str(data.get("base_url", DEFAULT_URL)).strip_edges()
	return result


static func save_models_cache(models: Array, has_vision_metadata: bool, base_url: String) -> Error:
	var file := FileAccess.open(MODELS_CACHE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({
		"schema_version": DataSafety.SCHEMA_VERSION,
		"models": models,
		"has_vision_metadata": has_vision_metadata,
		"base_url": base_url,
	}, "\t"))
	return OK


static func parse_models_response(json_text: String) -> Dictionary:
	var data = JSON.parse_string(json_text)
	var items: Array = []
	if typeof(data) == TYPE_DICTIONARY:
		if typeof(data.get("data")) == TYPE_ARRAY:
			items = data.get("data")
		elif typeof(data.get("models")) == TYPE_ARRAY:
			items = data.get("models")
	elif typeof(data) == TYPE_ARRAY:
		items = data

	var all_models: Array = []
	var vision_models: Array = []
	var has_vision_metadata := false

	for item in items:
		if typeof(item) == TYPE_STRING:
			var id_str := str(item).strip_edges()
			if not id_str.is_empty() and id_str not in all_models:
				all_models.append(id_str)
		elif typeof(item) == TYPE_DICTIONARY:
			var id_str := str(item.get("id", item.get("name", ""))).strip_edges()
			if id_str.is_empty():
				continue
			if id_str not in all_models:
				all_models.append(id_str)
			var v := _check_item_vision(item)
			if v >= 0:
				has_vision_metadata = true
				if v == 1 and id_str not in vision_models:
					vision_models.append(id_str)

	var chosen := vision_models if has_vision_metadata else all_models
	return {
		"models": chosen,
		"has_vision_metadata": has_vision_metadata,
	}


static func _check_item_vision(item: Dictionary) -> int:
	if item.has("input_modalities") and typeof(item["input_modalities"]) == TYPE_ARRAY:
		return 1 if _array_has_image(item["input_modalities"]) else 0
	if item.has("modalities"):
		var mod = item["modalities"]
		if typeof(mod) == TYPE_ARRAY:
			return 1 if _array_has_image(mod) else 0
		if typeof(mod) == TYPE_DICTIONARY and typeof(mod.get("input")) == TYPE_ARRAY:
			return 1 if _array_has_image(mod.get("input")) else 0
	if item.has("architecture") and typeof(item["architecture"]) == TYPE_DICTIONARY:
		var arch: Dictionary = item["architecture"]
		if arch.has("input_modalities") and typeof(arch["input_modalities"]) == TYPE_ARRAY:
			return 1 if _array_has_image(arch["input_modalities"]) else 0
		if arch.has("modality") and typeof(arch["modality"]) == TYPE_STRING:
			var mod_str := str(arch["modality"]).to_lower()
			var input_part := mod_str.split("->")[0] if mod_str.contains("->") else mod_str
			return 1 if (
				input_part.contains("image") or input_part.contains("vision") or input_part.contains("multimodal")
			) else 0
	if item.has("capabilities") and typeof(item["capabilities"]) == TYPE_DICTIONARY:
		var cap: Dictionary = item["capabilities"]
		for k in ["vision", "image", "images", "multimodal", "image_input"]:
			if cap.has(k) and typeof(cap[k]) == TYPE_BOOL:
				return 1 if bool(cap[k]) else 0
		if cap.has("input") and typeof(cap["input"]) == TYPE_DICTIONARY:
			var cap_in: Dictionary = cap["input"]
			for k in ["image", "vision"]:
				if cap_in.has(k) and typeof(cap_in[k]) == TYPE_BOOL:
					return 1 if bool(cap_in[k]) else 0
		if cap.has("modalities") and typeof(cap["modalities"]) == TYPE_ARRAY:
			return 1 if _array_has_image(cap["modalities"]) else 0
	for k in ["vision", "supports_vision", "supports_image_input", "image_input", "multimodal"]:
		if item.has(k) and typeof(item[k]) == TYPE_BOOL:
			return 1 if bool(item[k]) else 0
	return -1


static func _array_has_image(arr: Array) -> bool:
	for entry in arr:
		var s := str(entry).to_lower()
		if s == "image" or s == "images" or s == "vision" or s == "multimodal":
			return true
	return false
