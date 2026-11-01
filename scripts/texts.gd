extends RefCounted

# Every user-facing string lives here. To add English later, add an EN dictionary
# and switch the lookup in t() based on TranslationServer.get_locale().

const EXERCISES = [
	{"id": "pullups", "name": "Подтягивания"},
	{"id": "abs", "name": "Пресс"},
	{"id": "pushups", "name": "Отжимания"},
	{"id": "muscle_up_1", "name": "Выход на 1"},
	{"id": "muscle_up_2", "name": "Выход на 2"},
]

const WEEKDAYS_SHORT = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
const MONTHS = [
	"Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
	"Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь",
]

const RU = {
	"app_title": "ReFitn",
	"app_subtitle": "Тренировки с таймером отдыха",
	"choose_exercise": "Выбери упражнение",
	"statistics": "Статистика",
	"nutrition": "Питание",
	"settings": "Настройки",
	"streak_format": "%d %s подряд",
	"streak_record_format": "Рекорд: %d %s",
	"streak_done": "Сегодня засчитано",
	"streak_pending": "Сегодня ещё можно засчитать",
	"settings_open": "Настройки",

	"back": "Назад",
	"finish": "Завершить",
	"done": "Готово",
	"cancel": "Отмена",
	"ok": "ОК",

	"reps_caption": "ПОВТОРЕНИЯ",
	"rest_caption": "ОТДЫХ",
	"rest_hint": "Нажми на значение, чтобы ввести вручную",
	"set_done": "Сделал подход",
	"skip_rest": "Пропустить отдых",
	"status_sets_reps": "Подходов: %d · Повторений: %d",
	"next_set": "Следующий подход: %d повторений",

	"prompt_title": "Пройдено %d подходов",
	"prompt_body": "Продолжаем тренировку?",
	"more_five": "Ещё 5 подходов",
	"more_n": "Ещё N подходов",
	"more_n_placeholder": "N",
	"more_n_button": "Ещё %d подходов",

	"dialog_reps": "Повторения",
	"dialog_rest": "Отдых, секунды",
	"dialog_more_sets": "Сколько ещё подходов?",

	"summary_title": "Тренировка завершена",
	"summary_sets": "Подходов",
	"summary_reps": "Всего повторений",
	"summary_total": "Общее время",
	"summary_work": "Время подходов",
	"summary_rest": "Время отдыха",

	"stats_title": "Статистика",
	"tab_overview": "Обзор",
	"tab_graphs": "Графики",
	"tab_summary": "Итоги",
	"tab_macros": "КБЖУ",
	"period_day": "День",
	"period_week": "Неделя",
	"period_month": "Месяц",
	"stats_exercise_format": "%d подх. · %d повт.",
	"stats_time_format": "Время: %s",
	"stats_empty_period": "За этот период тренировок нет",
	"recent_title": "Последние тренировки",
	"recent_empty": "Тренировок пока нет",
	"recent_format": "%s · %d подх. · %d повт.",
	"export": "Экспорт",
	"import": "Импорт",
	"export_dialog": "Экспорт данных",
	"import_dialog": "Импорт данных",
	"backup_name": "refitn-backup-%s.json",
	"export_saved": "Данные сохранены: %s",
	"export_failed": "Не удалось сохранить файл",
	"import_ok": "Тренировок: %d, питания: %d",
	"import_failed": "Не удалось прочитать файл",

	"today_title": "Сегодня",
	"today_summary_format": "Сегодня · %d ккал",
	"no_data": "Нет данных",
	"calories": "Калории",
	"protein": "Белки",
	"fat": "Жиры",
	"carbs": "Углеводы",
	"water": "Вода",
	"kcal": "ккал",
	"grams": "г",
	"ml": "мл",
	"month_title_format": "%s %d",
	"month_prev": "←",
	"month_next": "→",
	"last_7_days": "7 дней",
	"last_30_days": "30 дней",
	"all_exercises": "Все",
	"graph_reps": "Повторения по дням",
	"graph_time": "Время тренировок по дням",
	"graph_record": "Рекорд повторений за подход",
	"graph_calories": "Калории по дням",
	"average_calories": "В среднем: %d ккал/день",
	"average_macros": "Белки %d · Жиры %d · Углеводы %d · Вода %d мл",
	"goal_format": "Цель: %d",
	"goal_water_format": "Цель: %d мл",

	"nutrition_title": "Питание",
	"add_entry": "Добавить запись",
	"entry_form_title": "Новая запись",
	"entry_name": "Название (необязательно)",
	"entry_name_placeholder": "Название",
	"time_separator": " · ",
	"nutrition_empty": "Записей за сегодня пока нет",
	"entry_macros_format": "%d ккал · Б %d · Ж %d · У %d",
	"delete": "Удалить",
	"unnamed_entry": "Без названия",
	"water_title": "Вода",
	"water_today_format": "Выпито: %d мл из %d мл",
	"add_250": "+250 мл",
	"add_500": "+500 мл",
	"manual": "Ввести вручную",
	"dialog_water": "Вода, мл",
	"entry_added": "Запись добавлена",
	"entry_deleted": "Запись удалена",
	"nutrition_hint": "Название можно не заполнять",
	"invalid_values": "Проверь значения",

	"settings_title": "Настройки",
	"settings_goals": "Цели на день",
	"goal_calories": "Калории, ккал",
	"goal_protein": "Белки, г",
	"goal_fat": "Жиры, г",
	"goal_carbs": "Углеводы, г",
	"goal_water": "Вода, мл",
	"settings_steps": "Шаги кнопок + / −",
	"step_reps": "Повторения, шт.",
	"step_rest": "Отдых, сек.",
	"settings_feedback": "Звук и вибрация",
	"sound_enabled": "Звук",
	"vibration_enabled": "Вибрация",
	"save": "Сохранить",
	"settings_saved": "Настройки сохранены",
	"enter_number": "Введите число",

	"ai_title": "Распознавание по фото",
	"ai_key_label": "API-ключ",
	"ai_url_label": "Адрес API",
	"ai_model_label": "Модель",
	"ai_hint": "Нужна модель, которая умеет читать картинки. Ключ хранится только на этом устройстве.",
	"ai_show": "Показать",
	"ai_hide": "Скрыть",
	"ai_saved": "Настройки распознавания сохранены",
	"ai_bad_url": "Адрес должен начинаться с https:// или http://",
	"ai_save_failed": "Не удалось сохранить настройки",

	"photo_button": "По фото",
	"photo_dialog_title": "Выберите фото еды",
	"photo_filter": "Изображения",
	"photo_no_key": "Для распознавания по фото укажите API-ключ в настройках",
	"photo_no_model": "Для распознавания по фото укажите модель в настройках",
	"photo_open_settings": "В настройки",
	"photo_close": "Закрыть",
	"photo_loading": "Распознаю блюдо…",
	"photo_review_title": "Результат распознавания",
	"photo_review_note": "Оценка примерная, проверь значения",
	"photo_add": "Добавить",
	"photo_error_picker": "Не удалось открыть выбор фото",
	"photo_error_file": "Не удалось прочитать фото",
	"photo_error_network": "Нет соединения с сервером. Проверьте интернет",
	"photo_error_timeout": "Сервер не ответил за 60 секунд",
	"photo_error_auth": "Неверный API-ключ или нет доступа (ошибка 401/403)",
	"photo_error_model": "Модель не поддерживает картинки или отклонила запрос. Выберите другую модель",
	"photo_error_http": "Ошибка сервера: код %d",
	"photo_error_parse": "Не удалось разобрать ответ модели. Попробуйте ещё раз",
	"photo_prompt": "Оцени еду на фото. Верни ТОЛЬКО JSON без текста вокруг: {\"name\": строка, \"calories\": число, \"protein\": число, \"fat\": число, \"carbs\": число}. Значения на всю порцию на фото, числа целые.",
}

static func t(key: String) -> String:
	return RU.get(key, key)


static func month_name(month: int) -> String:
	return str(MONTHS[clampi(month, 1, 12) - 1])


static func day_word(count: int) -> String:
	var mod100 := count % 100
	var mod10 := count % 10
	if mod100 >= 11 and mod100 <= 14:
		return "дней"
	if mod10 == 1:
		return "день"
	if mod10 >= 2 and mod10 <= 4:
		return "дня"
	return "дней"


static func format_streak(count: int) -> String:
	return t("streak_format") % [count, day_word(count)]


static func format_streak_record(count: int) -> String:
	return t("streak_record_format") % [count, day_word(count)]

static func has_exercise(id: String) -> bool:
	for exercise in EXERCISES:
		if exercise.id == id:
			return true
	return false

static func exercise_name(id: String) -> String:
	for exercise in EXERCISES:
		if exercise.id == id:
			return exercise.name
	return id

static func format_time(total_seconds: int) -> String:
	var total := maxi(0, total_seconds)
	var hours := int(total / 3600)
	var minutes := int((total % 3600) / 60)
	var seconds := total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds]
	return "%d:%02d" % [minutes, seconds]

static func format_datetime(unix_time: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var date := Time.get_datetime_dict_from_unix_time(unix_time + bias)
	return "%02d.%02d.%04d %02d:%02d" % [
		int(date.day), int(date.month), int(date.year), int(date.hour), int(date.minute)
	]
