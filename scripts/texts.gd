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

const RU = {
	"app_title": "ReFitn",
	"app_subtitle": "Тренировки с таймером отдыха",
	"choose_exercise": "Выбери упражнение",
	"statistics": "Статистика",

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
	"export_dialog": "Экспорт статистики",
	"import_dialog": "Импорт статистики",
	"backup_name": "refitn-backup-%s.json",
	"export_saved": "Статистика сохранена: %s",
	"export_failed": "Не удалось сохранить файл",
	"import_ok": "Добавлено тренировок: %d",
	"import_failed": "Не удалось прочитать файл",
}

static func t(key: String) -> String:
	return RU.get(key, key)

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
