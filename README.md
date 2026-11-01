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
- Всё хранится только на устройстве. Интернет нужен только для распознавания еды по фото (экран «Питание» → «По фото»): фото отправляется на адрес API, который вы укажете в настройках, с вашим ключом. Ключ не попадает в экспорт статистики.
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

На Linux путь задаётся в `Editor → Editor Settings → Export → Android`. Примеры путей для Linux:

- `Android Sdk Path` — путь к Android SDK, например `/home/USER/Android/Sdk`;
- `Java Sdk Path` — путь к JDK 17, например `/usr/lib/jvm/java-17-openjdk-amd64` (точный путь зависит от дистрибутива; узнать его можно командой `dirname $(dirname $(readlink -f $(which javac)))`);
- `Debug Keystore` — путь к debug-ключу, например `/home/USER/.android/debug.keystore`, с логином `androiddebugkey` и паролем `android`. Если поле пустое, Godot создаст ключ автоматически, если доступен `keytool` из JDK.

`USER` в примерах замените на своё имя пользователя.

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
- разрешения `VIBRATE` и `INTERNET` (для распознавания по фото);
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
- `user://settings.json` — повторения и отдых для каждого упражнения, цели, шаги, звук и вибрация;
- `user://nutrition.json` — записи питания и вода по дням.

Примерные пути:

- Android: приватная папка приложения `com.tatnab.refitn` (доступна через `user://`);
- Linux: `~/.local/share/godot/app_userdata/ReFitn/`.

На экране статистики есть кнопки `Экспорт` и `Импорт`. Экспорт сохраняет JSON-файл через файловый диалог, импорт объединяет тренировки по `id` и не удаляет существующие записи. На Android файловый диалог работает с доступными системными папками; если нужна гарантированная копия, сохраняйте бэкап в доступную папку через диалог.

Автоматический Android backup отключён (`user_data_backup/allow=false`), чтобы данные не уходили в облако. Для переноса используйте экспорт/импорт.

## Структура

```text
scenes/
  main_menu.tscn        # главный экран
  workout.tscn          # экран тренировки
  summary.tscn          # итоги тренировки
  stats.tscn            # статистика (вкладки)
  nutrition.tscn        # питание
  settings.tscn         # настройки
  number_input_dialog.tscn
scripts/
  texts.gd              # все пользовательские строки и названия упражнений
  theme_colors.gd       # палитра приложения
  storage.gd            # autoload Storage: JSON, настройки, питание, экспорт/импорт
  streak.gd             # серия дней и календарные расчёты по тренировкам
  main_menu.gd          # главный экран: выбор упражнения, серия
  workout.gd            # экран тренировки: подходы, отдых, таймер
  summary.gd            # итоги тренировки
  number_input_dialog.gd # диалог ввода числа
  nutrition.gd          # экран питания: записи за день и вода
  settings.gd           # настройки: цели, шаги +/−, звук и вибрация
  stats.gd              # статистика: вкладки, период, экспорт/импорт
  stats_overview.gd     # вкладка «Обзор»: серия, календарь, КБЖУ и вода
  stats_graphs.gd       # вкладка «Графики»: повторения, время, рекорд за подход
  stats_macros.gd       # вкладка «КБЖУ»: график калорий и средние
  calendar_view.gd      # отрисовка календаря месяца
  bar_chart.gd          # столбчатая диаграмма с линией цели
  macro_bar.gd          # полоса прогресса с подписью и целью
  flame_icon.gd         # иконка огонька серии
  gear_button.gd        # кнопка-шестерёнка
  ai_settings.gd        # ключ, адрес и модель для распознавания (ai_settings.json)
  ai_settings_panel.gd  # блок «Распознавание по фото» в настройках
  food_photo.gd         # фото → base64 → запрос к API → КБЖУ
  food_photo_dialog.gd  # окно загрузки, ошибок и проверки результата
resources/
  theme.tres            # тёмная тема, крупные контролы
export_presets.cfg      # Android APK, com.tatnab.refitn
project.godot
README.md
LICENSE
```

## Локализация

Все строки собраны в `scripts/texts.gd` в словаре `RU`. Для добавления английского достаточно добавить словарь `EN` и выбрать его в `t()`. Названия упражнений также находятся там.

## Лицензия

MIT. См. `LICENSE`.
