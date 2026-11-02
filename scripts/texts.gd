extends RefCounted

# Every user-facing string lives here. To add English later, add an EN dictionary
# and switch the lookup in t() based on TranslationServer.get_locale().

const EXERCISES = [
	{"id": "pullups", "name": "Подтягивания"},
	{"id": "abs", "name": "Пресс"},
	{"id": "pushups", "name": "Отжимания"},
	{"id": "muscle_up_1", "name": "Выход на 1"},
	{"id": "muscle_up_2", "name": "Выход на 2"},
	{"id": "squats", "name": "Приседания"},
	{"id": "expander", "name": "Эспандер"},
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
	"import_newer": "Файл создан более новой версией ReFitn. Обновите приложение",

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

	"today_reps_format": "Сегодня: %d",

	"theme_title": "Тема",
	"theme_dark": "Тёмная",
	"theme_light": "Светлая",
	"theme_system": "Как в системе",

	"reminder_title": "Напоминание",
	"reminder_enabled": "Ежедневное напоминание",
	"reminder_time_format": "Время: %02d:%02d",
	"notif_channel_name": "Отдых и напоминания",
	"notif_channel_desc": "Конец отдыха и ежедневное напоминание о серии",
	"notif_rest_title": "Отдых закончился",
	"notif_rest_text": "Пора к следующему подходу",
	"notif_daily_title": "Не потеряй серию",
	"notif_daily_text": "Серия: %d %s. Сегодня ещё можно засчитать",
	"notif_daily_start": "Начни серию сегодня",
	"notif_rationale": "Разрешите уведомления, чтобы сообщать о конце отдыха и напоминать о серии",
	"notif_denied_hint": "Уведомления запрещены. Включите их в настройках телефона",
	"notif_open_settings": "Открыть настройки",
	"notif_unsupported": "Уведомления работают только на Android",
	"notif_test_title": "Тест уведомлений",
	"notif_test_text": "Если вы это видите, уведомления работают",
	"notif_prompt_title": "Включить уведомления?",
	"notif_prompt_text": "ReFitn пришлёт уведомление, когда закончится отдых, и напомнит о серии. Без разрешения Android уведомления не показывает. Разрешить?",
	"notif_prompt_allow": "Разрешить",
	"notif_prompt_later": "Позже",
	"diag_title": "Диагностика уведомлений",
	"diag_permission": "Уведомления: %s",
	"diag_exact": "Точные будильники: %s",
	"diag_exact_hint": "без них уведомления могут прийти с задержкой на несколько минут",
	"diag_battery": "Ограничение батареи: %s",
	"diag_battery_on": "включено",
	"diag_battery_off": "отключено",
	"diag_battery_hint": "Если ограничение батареи включено, Android может задерживать уведомления. Отключите его кнопкой ниже или в Настройки → Приложения → ReFitn → Батарея → Без ограничений.",
	"diag_allowed": "разрешены",
	"diag_denied": "запрещены",
	"diag_request": "Запросить разрешение",
	"diag_request_exact": "Разрешить точные будильники",
	"diag_request_battery": "Отключить ограничение батареи",
	"diag_open_app": "Открыть настройки приложения",
	"diag_test": "Тестовое уведомление через 10 секунд",
	"diag_test_sent": "Уведомление придёт через 10 секунд. Можно свернуть приложение.",
	"diag_test_no_permission": "Сначала разрешите уведомления",
	"plan_full_body": "FULL BODY",
	"plan_upper": "UPPER BODY",
	"plan_legs": "LEGS",
	"day_full_body": "Full Body",
	"day_upper": "Upper",
	"day_legs": "Legs",
	"day_measure": "ЗАМЕРЫ",
	"plan_settings_title": "План и очки",
	"plan_label": "Активный план",
	"muscle_up_label": "«Выходы» в плане",
	"points_settings_title": "Очки за повторение",
	"goal_coefs_title": "Коэффициенты целей",
	"coef_smart": "Умная цель: множитель",
	"coef_raise": "Цель выполнена: рост цели",
	"coef_fail_threshold": "Провал: доля цели ниже",
	"coef_fail_multiplier": "После провала: цель, доля от старой",
	"today_card_sub": "%s · %s",
	"today_rest_notice": "Сегодня день отдыха",
	"measure_tag": "замер",
	"measure_target": "замер · цель %d (прошлый %d)",
	"measure_first": "замер · первый, без цели",
	"measure_result": "замер %d · прошлый %d (%s)",
	"measure_hint_target": "Замер: один подход. Цель %d повторений",
	"measure_hint_none": "Замер: один подход. Цели нет, это первый замер",
	"other_exercises": "Другие упражнения",
	"points_format": "Очки: %d из %d",
	"points_only": "Очки: %d",
	"goal_none": "Цель не задана",
	"goal_points_format": "Цель: %d очков",
	"goal_reps_format": "Цель: %d повт. · %s",
	"goal_button": "Цель",
	"rest_day_button": "День отдыха",
	"rest_confirm_title": "День отдыха",
	"rest_confirm_text": "Отметить сегодня как день отдыха? Серия не прервётся и не увеличится.",
	"rest_confirm_ok": "Отметить",
	"rest_block_today": "Сегодня уже есть тренировка",
	"rest_block_marked": "Сегодня уже отмечен день отдыха",
	"rest_block_yesterday": "Вчера был день отдыха. Сегодня тренируйтесь",
	"rest_block_need_workout": "После отдыха сделайте хотя бы один подход",
	"goal_title": "Цель на день",
	"goal_type_points": "Очки за день",
	"goal_type_reps": "Повторения упражнения",
	"goal_value_placeholder": "Значение (пусто = без цели)",
	"goal_smart": "Умная цель",
	"goal_smart_hint": "Умная цель по истории: %d",
	"goal_save": "Сохранить",
	"stats_points_format": "Очки за период: %d",
	"graph_points": "Очки по дням",
	"graph_measures": "Замеры по неделям (сумма повторений)",
	"summary_points": "Очки",
	"data_notice_title": "Данные",
	"data_broken_format": "Файл %s не читается. Он переименован в %s, данные не удалены.",

	"ai_title": "Распознавание по фото",
	"ai_key_label": "API-ключ",
	"ai_url_label": "Адрес API",
	"ai_model_label": "Модель",
	"ai_other_model_label": "Другая модель",
	"ai_other_model_option": "Другая модель (вручную)",
	"ai_other_model_placeholder": "Название модели вручную",
	"ai_model_search": "Поиск модели",
	"ai_load_models": "Загрузить список моделей",
	"ai_loading_models": "Загрузка списка моделей…",
	"ai_models_loaded": "Моделей загружено: %d",
	"ai_models_empty": "Список моделей пуст",
	"ai_vision_hint": "Нужна модель с поддержкой изображений, если ответ с ошибкой, выбери другую",
	"ai_check_button": "Проверить подключение",
	"ai_checking": "Проверка подключения…",
	"ai_check_ok": "Работает",
	"ai_check_bad_key": "Неверный ключ",
	"ai_check_no_network": "Нет сети",
	"ai_check_model_not_found": "Модель не найдена",
	"ai_check_rate_limit": "Лимит исчерпан",
	"ai_check_http_error": "Ошибка сервера: код %d",
	"ai_no_key": "Укажите API-ключ",
	"ai_no_model": "Выберите или введите модель",
	"ai_hint": "Нужна модель, которая умеет читать картинки. Ключ хранится только на этом устройстве.",
	"ai_show": "Показать",
	"ai_hide": "Скрыть",
	"ai_saved": "Настройки распознавания сохранены",
	"ai_bad_url": "Адрес должен начинаться с https:// или http://",
	"ai_save_failed": "Не удалось сохранить настройки",

	"photo_button": "По фото",
	"photo_take": "Сделать фото",
	"photo_gallery": "Из галереи",
	"photo_camera_denied": "Доступ к камере запрещён. Разрешите доступ к камере в настройках телефона",
	"photo_camera_unsupported": "Съёмка камерой работает только на Android",
	"photo_open_app_settings": "Открыть настройки",
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
