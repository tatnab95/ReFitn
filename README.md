# ReFitn

Открытое Android-приложение для тренировок с таймером отдыха. Написано на Godot 4 / GDScript, весь интерфейс — обычные `Control`-ноды, без сторонних плагинов и сетевых запросов.

## Возможности

- Выбор упражнения: подтягивания, пресс, отжимания, выход на 1, выход на 2.
- Экран тренировки:
  - повторения и время отдыха настраиваются отдельно для каждого упражнения;
  - крупные кнопки `+` / `−` и ввод с цифровой клавиатуры;
  - отдых с большим обратным отсчётом и кнопкой «Пропустить отдых»;
  - звук и вибрация после отдыха;
  - каждые 5 подходов — предложение продолжить или завершить;
  - «Завершить» доступно в любой момент.
- Экран итогов: подходы, повторения, общее время, время подходов и отдыха.
- Статистика за день / неделю / месяц и список последних тренировок.
- Экспорт и импорт статистики в JSON.
- Всё хранится только на устройстве. Приложение не использует интернет.
- Экран не гаснет во время тренировки (`DisplayServer.screen_set_keep_on`).
- Таймер отдыха считается по `Time.get_ticks_msec()`, а не по `delta`, поэтому переживает сворачивание приложения.
- Данные сохраняются после каждого подхода.

## Требования

- [Godot 4.7+](https://godotengine.org/) (обычная версия, не .NET).
- Export templates для Godot 4.7.
- Для сборки APK: Android SDK (build-tools + platform-tools) и JDK 17.
- Для установки на телефон: `adb` или файловый менеджер.

## Запуск в редакторе

1. Открыть `project.godot` в Godot.
2. Нажать `F5`.

Проект настроен на портретную ориентацию, базу 1080×1920, stretch mode `canvas_items`, aspect `expand`. На десктопе окно открывается 540×960 для удобства.

## Сборка APK

### 1. Установить export templates

В Godot: `Editor → Manage Export Templates → Download and Install`.  
Либо скачать шаблоны с сайта Godot и положить в стандартную папку экспортных шаблонов.

### 2. Настроить Android SDK

В `Editor → Editor Settings → Export → Android` указать:

- `Android Sdk Path` — путь к Android SDK;
- `Java Sdk Path` — путь к JDK 17;
- debug keystore можно оставить пустым: Godot создаст его автоматически, если доступен `keytool`.

Для release-сборки понадобится собственный keystore:

```bash
keytool -genkey -v -keystore refitn-release.keystore -alias refitn \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keystore и пароли **не коммитить**. В Export-диалоге их можно указать вручную; в `export_presets.cfg` поля оставлены пустыми.

### 3. Экспорт

В `Project → Export` уже есть пресет **Android**:

- package: `com.tatnab.refitn`;
- имя: `ReFitn`;
- архитектура: `arm64-v8a`;
- портретная ориентация;
- разрешение `VIBRATE`, без `INTERNET`;
- путь: `build/refitn.apk`.

Нажать `Export Project` (для теста подойдёт debug APK, он подписывается debug-ключом).

Из командной строки:

```bash
# один раз — импорт ресурсов и проверка проекта
godot --headless --path . --editor --quit

# debug APK
godot --headless --path . --export-debug "Android" build/refitn.apk

# release APK (нужен настроенный release keystore)
godot --headless --path . --export-release "Android" build/refitn.apk
```

Установка:

```bash
adb install -r build/refitn.apk
```

Если Godot не находит шаблоны или Android SDK, он покажет точную ошибку в панели `Output` — чаще всего это несовпадение версии шаблонов или неверный путь к JDK.

## Данные

Всё лежит в `user://`:

- `user://workouts.json` — тренировки;
- `user://settings.json` — повторения и отдых для каждого упражнения.

Примерные пути:

- Android: приватная папка приложения `com.tatnab.refitn` (доступна через `user://`);
- Windows: `%APPDATA%\Godot\app_userdata\ReFitn\`;
- Linux: `~/.local/share/godot/app_userdata/ReFitn/`.

На экране статистики есть кнопки `Экспорт` и `Импорт`. Экспорт сохраняет JSON-файл через файловый диалог, импорт объединяет тренировки по `id` и не удаляет существующие записи. На Android файловый диалог работает с доступными системными папками; если нужна гарантированная копия, сохраняйте бэкап в доступную папку через диалог.

Автоматический Android backup отключён (`user_data_backup/allow=false`), чтобы данные не уходили в облако. Для переноса используйте экспорт/импорт.

## Структура

```text
scenes/
  main_menu.tscn
  workout.tscn
  summary.tscn
  stats.tscn
  number_input_dialog.tscn
scripts/
  texts.gd          # все пользовательские строки
  storage.gd        # autoload Storage: JSON, настройки, экспорт/импорт
  main_menu.gd
  workout.gd
  summary.gd
  stats.gd
  number_input_dialog.gd
resources/
  theme.tres        # тёмная тема, крупные контролы
export_presets.cfg  # Android APK, com.tatnab.refitn
project.godot
README.md
LICENSE
```

## Локализация

Все строки собраны в `scripts/texts.gd` в словаре `RU`. Для добавления английского достаточно добавить словарь `EN` и выбрать его в `t()`. Названия упражнений также находятся там.

## Лицензия

MIT. См. `LICENSE`.
