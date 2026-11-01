extends Node

# Sends a food photo to an OpenAI-compatible chat API and parses the macros.
# Nothing is written to disk: the photo and the reply live only in memory.

signal started
signal succeeded(result: Dictionary)
signal failed(message: String)

const Texts = preload("res://scripts/texts.gd")
const AiSettings = preload("res://scripts/ai_settings.gd")

const MAX_SIDE := 1024
const JPEG_QUALITY := 0.85
const TIMEOUT_SECONDS := 60.0

var _http: HTTPRequest
var _busy := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SECONDS
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)


func is_busy() -> bool:
	return _busy


func pick_photo() -> void:
	var filters := PackedStringArray(["*.jpg,*.jpeg,*.png,*.webp ; " + Texts.t("photo_filter")])
	var error := DisplayServer.file_dialog_show(
		Texts.t("photo_dialog_title"), "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filters, _on_file_selected
	)
	if error != OK:
		failed.emit(Texts.t("photo_error_picker"))


func cancel() -> void:
	if _busy:
		_busy = false
		_http.cancel_request()


func _on_file_selected(status: bool, paths: PackedStringArray, _filter_index: int) -> void:
	if not status or paths.is_empty():
		return
	_estimate(paths[0])


func _estimate(path: String) -> void:
	if _busy:
		return
	var settings := AiSettings.load_settings()
	if str(settings.api_key).is_empty():
		failed.emit(Texts.t("photo_no_key"))
		return
	if str(settings.model).is_empty():
		failed.emit(Texts.t("photo_no_model"))
		return

	var jpeg := prepare_jpeg(FileAccess.get_file_as_bytes(path))
	if jpeg.is_empty():
		failed.emit(Texts.t("photo_error_file"))
		return

	var body := {
		"model": settings.model,
		"messages": [{
			"role": "user",
			"content": [
				{"type": "text", "text": Texts.t("photo_prompt")},
				{"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + Marshalls.raw_to_base64(jpeg)}},
			],
		}],
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + str(settings.api_key),
	])
	var url := str(settings.base_url).rstrip("/") + "/chat/completions"
	var error := _http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		failed.emit(Texts.t("photo_error_network"))
		return
	_busy = true
	started.emit()


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, response: PackedByteArray) -> void:
	if not _busy:
		return
	_busy = false
	if result == HTTPRequest.RESULT_TIMEOUT:
		failed.emit(Texts.t("photo_error_timeout"))
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		failed.emit(Texts.t("photo_error_network"))
		return
	if code == 401 or code == 403:
		failed.emit(Texts.t("photo_error_auth"))
		return
	if code == 400 or code == 404 or code == 415 or code == 422:
		failed.emit(Texts.t("photo_error_model"))
		return
	if code < 200 or code >= 300:
		failed.emit(Texts.t("photo_error_http") % code)
		return

	var result_data := parse_food_json(_content_from_response(response))
	if result_data.is_empty():
		failed.emit(Texts.t("photo_error_parse"))
		return
	succeeded.emit(result_data)


static func prepare_jpeg(bytes: PackedByteArray) -> PackedByteArray:
	if bytes.is_empty():
		return PackedByteArray()
	var image := Image.new()
	var error := ERR_FILE_UNRECOGNIZED
	if bytes.size() > 3 and bytes[0] == 0xFF and bytes[1] == 0xD8:
		error = image.load_jpg_from_buffer(bytes)
	elif bytes.size() > 4 and bytes[0] == 0x89 and bytes[1] == 0x50 and bytes[2] == 0x4E and bytes[3] == 0x47:
		error = image.load_png_from_buffer(bytes)
	elif bytes.size() > 12 and bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		error = image.load_webp_from_buffer(bytes)
	if error != OK:
		return PackedByteArray()

	var width := image.get_width()
	var height := image.get_height()
	var longest := maxi(width, height)
	if longest > MAX_SIDE:
		var scale := float(MAX_SIDE) / float(longest)
		image.resize(maxi(1, roundi(width * scale)), maxi(1, roundi(height * scale)), Image.INTERPOLATE_BILINEAR)
	image.convert(Image.FORMAT_RGB8)
	return image.save_jpg_to_buffer(JPEG_QUALITY)


static func parse_food_json(text: String) -> Dictionary:
	var start := text.find("{")
	var finish := text.rfind("}")
	if start < 0 or finish <= start:
		return {}
	var data = JSON.parse_string(text.substr(start, finish - start + 1))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	for key in ["calories", "protein", "fat", "carbs"]:
		if not data.has(key):
			return {}
	return {
		"name": str(data.get("name", "")).strip_edges(),
		"calories": _to_int(data.get("calories")),
		"protein": _to_int(data.get("protein")),
		"fat": _to_int(data.get("fat")),
		"carbs": _to_int(data.get("carbs")),
	}


static func _to_int(value: Variant) -> int:
	return maxi(0, roundi(str(value).replace(",", ".").to_float()))


static func _content_from_response(response: PackedByteArray) -> String:
	var data = JSON.parse_string(response.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	var choices = data.get("choices", [])
	if typeof(choices) != TYPE_ARRAY or choices.is_empty() or typeof(choices[0]) != TYPE_DICTIONARY:
		return ""
	var message = choices[0].get("message", {})
	if typeof(message) != TYPE_DICTIONARY:
		return ""
	var content = message.get("content", "")
	return str(content) if typeof(content) == TYPE_STRING else ""
