extends Node

# Sends a food photo to an OpenAI-compatible chat API and parses the macros.
# Nothing is written to disk: the photo and the reply live only in memory.

signal started
signal succeeded(result: Dictionary)
signal failed(message: String)
signal permission_denied(message: String)

const Texts = preload("res://scripts/texts.gd")
const AiSettings = preload("res://scripts/ai_settings.gd")

const MAX_SIDE := 1024
const JPEG_QUALITY := 0.85
const TIMEOUT_SECONDS := 60.0
const CAMERA_PLUGIN_NAME := "GodotGetImage"
const CAMERA_PERMISSION := "android.permission.CAMERA"

var _http: HTTPRequest
var _busy := false
var _camera_plugin: Object = null
var _waiting_camera_permission := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SECONDS
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	if Engine.has_singleton(CAMERA_PLUGIN_NAME):
		_camera_plugin = Engine.get_singleton(CAMERA_PLUGIN_NAME)
		_camera_plugin.connect("image_request_completed", _on_camera_image_completed)
		_camera_plugin.connect("error", _on_camera_error)
		_camera_plugin.connect("permission_not_granted_by_user", _on_camera_permission_denied)
	get_tree().on_request_permissions_result.connect(_on_request_permissions_result)


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


func take_photo() -> void:
	if _busy:
		return
	if OS.get_name() != "Android" or _camera_plugin == null:
		failed.emit(Texts.t("photo_camera_unsupported"))
		return
	if CAMERA_PERMISSION in OS.get_granted_permissions():
		_launch_camera()
		return
	_waiting_camera_permission = true
	if OS.request_permission("CAMERA"):
		_waiting_camera_permission = false
		_launch_camera()


func _launch_camera() -> void:
	if _camera_plugin == null:
		failed.emit(Texts.t("photo_camera_unsupported"))
		return
	_camera_plugin.setOptions({
		"image_width": MAX_SIDE,
		"image_height": MAX_SIDE,
		"keep_aspect": true,
		"auto_rotate_image": true,
		"image_format": "jpg",
		"image_quality": int(round(JPEG_QUALITY * 100.0)),
	})
	_camera_plugin.getCameraImage()


func _on_request_permissions_result(permission: String, granted: bool) -> void:
	if not _waiting_camera_permission:
		return
	if permission == CAMERA_PERMISSION or permission == "CAMERA" or permission.ends_with(".CAMERA"):
		_waiting_camera_permission = false
		if granted:
			_launch_camera()
		else:
			permission_denied.emit(Texts.t("photo_camera_denied"))


func _on_camera_image_completed(dict: Dictionary) -> void:
	if dict.is_empty():
		return
	var values := dict.values()
	if values.is_empty() or typeof(values[0]) != TYPE_PACKED_BYTE_ARRAY:
		failed.emit(Texts.t("photo_error_file"))
		return
	estimate_bytes(values[0])


func _on_camera_error(_err: String) -> void:
	failed.emit(Texts.t("photo_error_file"))


func _on_camera_permission_denied(_perm: String) -> void:
	_waiting_camera_permission = false
	permission_denied.emit(Texts.t("photo_camera_denied"))


func cancel() -> void:
	_waiting_camera_permission = false
	if _busy:
		_busy = false
		_http.cancel_request()


func _on_file_selected(status: bool, paths: PackedStringArray, _filter_index: int) -> void:
	if not status or paths.is_empty():
		return
	_estimate(paths[0])


func _estimate(path: String) -> void:
	estimate_bytes(FileAccess.get_file_as_bytes(path))


func estimate_bytes(raw_bytes: PackedByteArray) -> void:
	if _busy:
		return
	var settings := AiSettings.load_settings()
	if str(settings.api_key).is_empty():
		failed.emit(Texts.t("photo_no_key"))
		return
	if str(settings.model).is_empty():
		failed.emit(Texts.t("photo_no_model"))
		return

	var jpeg := prepare_jpeg(raw_bytes)
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
	var exif_orientation := 1
	if bytes.size() > 3 and bytes[0] == 0xFF and bytes[1] == 0xD8:
		exif_orientation = read_exif_orientation(bytes)
		error = image.load_jpg_from_buffer(bytes)
	elif bytes.size() > 4 and bytes[0] == 0x89 and bytes[1] == 0x50 and bytes[2] == 0x4E and bytes[3] == 0x47:
		error = image.load_png_from_buffer(bytes)
	elif bytes.size() > 12 and bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		error = image.load_webp_from_buffer(bytes)
	if error != OK:
		return PackedByteArray()

	_apply_exif_orientation(image, exif_orientation)

	var width := image.get_width()
	var height := image.get_height()
	var longest := maxi(width, height)
	if longest > MAX_SIDE:
		var scale := float(MAX_SIDE) / float(longest)
		image.resize(maxi(1, roundi(width * scale)), maxi(1, roundi(height * scale)), Image.INTERPOLATE_BILINEAR)
	image.convert(Image.FORMAT_RGB8)
	return image.save_jpg_to_buffer(JPEG_QUALITY)


static func read_exif_orientation(bytes: PackedByteArray) -> int:
	if bytes.size() < 4 or bytes[0] != 0xFF or bytes[1] != 0xD8:
		return 1
	var pos := 2
	var size := bytes.size()
	while pos + 4 <= size:
		if bytes[pos] != 0xFF:
			return 1
		while pos < size and bytes[pos] == 0xFF:
			pos += 1
		if pos >= size:
			return 1
		var marker := bytes[pos]
		pos += 1
		if marker == 0xDA or marker == 0xD9:
			return 1
		if marker == 0x00 or marker == 0x01 or (marker >= 0xD0 and marker <= 0xD7):
			continue
		if pos + 2 > size:
			return 1
		var seg_len := (int(bytes[pos]) << 8) | int(bytes[pos + 1])
		if seg_len < 2 or pos + seg_len > size:
			return 1
		if marker == 0xE1 and seg_len >= 16:
			if (
				bytes[pos + 2] == 0x45 and bytes[pos + 3] == 0x78
				and bytes[pos + 4] == 0x69 and bytes[pos + 5] == 0x66
				and bytes[pos + 6] == 0x00 and bytes[pos + 7] == 0x00
			):
				var tiff := pos + 8
				var tiff_end := pos + seg_len
				var b0 := bytes[tiff]
				var b1 := bytes[tiff + 1]
				var little := false
				if b0 == 0x49 and b1 == 0x49:
					little = true
				elif b0 == 0x4D and b1 == 0x4D:
					little = false
				else:
					pos += seg_len
					continue
				var ifd_offset := _read_u32(bytes, tiff + 4, little)
				var ifd := tiff + ifd_offset
				if ifd + 2 <= tiff_end:
					var count := _read_u16(bytes, ifd, little)
					for i in range(count):
						var entry := ifd + 2 + i * 12
						if entry + 12 > tiff_end:
							break
						var tag := _read_u16(bytes, entry, little)
						if tag == 0x0112:
							var orientation := _read_u16(bytes, entry + 8, little)
							if orientation >= 1 and orientation <= 8:
								return orientation
							return 1
		pos += seg_len
	return 1


static func _read_u16(bytes: PackedByteArray, offset: int, little: bool) -> int:
	if little:
		return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)
	return (int(bytes[offset]) << 8) | int(bytes[offset + 1])


static func _read_u32(bytes: PackedByteArray, offset: int, little: bool) -> int:
	if little:
		return (
			int(bytes[offset])
			| (int(bytes[offset + 1]) << 8)
			| (int(bytes[offset + 2]) << 16)
			| (int(bytes[offset + 3]) << 24)
		)
	return (
		(int(bytes[offset]) << 24)
		| (int(bytes[offset + 1]) << 16)
		| (int(bytes[offset + 2]) << 8)
		| int(bytes[offset + 3])
	)


static func _apply_exif_orientation(image: Image, orientation: int) -> void:
	match orientation:
		2:
			image.flip_x()
		3:
			image.rotate_180()
		4:
			image.flip_y()
		5:
			image.flip_x()
			image.rotate_90(COUNTERCLOCKWISE)
		6:
			image.rotate_90(CLOCKWISE)
		7:
			image.flip_x()
			image.rotate_90(CLOCKWISE)
		8:
			image.rotate_90(COUNTERCLOCKWISE)


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
