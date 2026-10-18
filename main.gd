extends Control

const SAVE_PATH = "user://progress.json"
var day := 1
var talks := 0
var constructive := 0
var thought_started := false
var panel: VBoxContainer
var heading: Label
var prose: Label
var choices: VBoxContainer

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("111027")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	# Temporary geometric skyline; replace with original illustrated backgrounds.
	for i in range(16):
		var building := ColorRect.new()
		building.position = Vector2(i * 84, 140 + (i * 73) % 170)
		building.size = Vector2(76, 580)
		building.color = Color(0.07 + (i % 3) * 0.015, 0.055, 0.15)
		add_child(building)
		for floor_index in range(7):
			var light := ColorRect.new()
			light.position = building.position + Vector2(18, 22 + floor_index * 48)
			light.size = Vector2(12, 18)
			light.color = Color("775476") if (i + floor_index) % 3 == 0 else Color("29203e")
			add_child(light)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 56)
	add_child(margin)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 22)
	margin.add_child(panel)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", Color("e0b6d9"))
	panel.add_child(heading)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(space)
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.025, 0.085, 0.97)
	style.border_color = Color("806489")
	style.set_border_width_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	box.add_theme_stylebox_override("panel", style)
	panel.add_child(box)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	box.add_child(content)
	prose = Label.new()
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prose.add_theme_font_size_override("font_size", 23)
	content.add_child(prose)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	content.add_child(choices)
	menu()

func screen(title: String, body: String) -> void:
	heading.text = title
	prose.text = body
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()

func option(caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 21)
	button.pressed.connect(action)
	choices.add_child(button)
	if choices.get_child_count() == 1:
		button.grab_focus()

func menu() -> void:
	screen("ЦИФРОВАЯ РЕАЛЬНОСТЬ", "Девять дней. Одна комната. Голос, который трудно выключить.\nРанний прототип · управление мышью или стрелками и Enter")
	if FileAccess.file_exists(SAVE_PATH):
		option("Продолжить", load_progress)
	option("Новая игра", func():
		day = 1
		talks = 0
		constructive = 0
		thought_started = false
		morning())
	option("Выход", func(): get_tree().quit())

func morning() -> void:
	save_progress()
	screen("ДЕНЬ %d · 07:12" % day, "Будильник. Потолок. Свет за шторами.\nТы проверяешь телефон, хотя заранее знаешь: ничего срочного.")
	option("Встать и пойти на занятия", school)
	option("Сохранить и выйти в меню", menu)

func school() -> void:
	screen("ДЕНЬ %d · КОРИДОР" % day, "В коридоре всё как обычно. Одни и те же лица, одни и те же разговоры.\nКто-то придерживает тебе дверь. Ты тихо говоришь спасибо и проходишь мимо.")
	option("Вернуться домой", night)

func night() -> void:
	screen("НОЧЬ %d · 23:48" % day, "Монитор освещает комнату. За окном ещё горят чужие окна.\nЧем займёшься сегодня?")
	option("Играть", func(): routine("Ещё одна партия. Потом ещё одна. Когда ты смотришь на часы, уже светает."))
	option("Смотреть сериал", func(): routine("Серия заканчивается. Следующая начинается сама. Сегодня можно ничего не решать."))
	option("Спать", func(): routine("Ты выключаешь экран. В темноте мысли становятся громче, но постепенно приходит сон."))
	if day >= 4 and (day < 9 or thought_started):
		option("Подумать о жизни", reflection)

func routine(body: String) -> void:
	screen("НОЧЬ %d" % day, body)
	option("Дальше", advance)

func reflection() -> void:
	thought_started = true
	screen("ВНУТРЕННИЙ ГОЛОС", "Ты снова здесь.\nМы прячемся или отдыхаем? И как ты поймёшь разницу?")
	option("Попробую завтра сделать один маленький шаг.", func(): answer(true))
	option("Мне нужен отдых. Но я могу написать кому-нибудь.", func(): answer(true))
	option("Здесь хотя бы всё под контролем. Оставь меня.", func(): answer(false))

func answer(helpful: bool) -> void:
	talks += 1
	if helpful:
		constructive += 1
	screen("ВНУТРЕННИЙ ГОЛОС", "Не нужно менять всю жизнь за одну ночь. Давай начнём с одного шага." if helpful else "Хорошо. Сегодня останемся здесь. За окном постепенно гаснут огни.")
	option("Закончить день", advance)

func advance() -> void:
	if day >= 9:
		final_choice()
	else:
		day += 1
		morning()

func can_leave() -> bool:
	return talks > 0 and float(constructive) / float(talks) >= 0.6

func final_choice() -> void:
	screen("НОЧЬ 9 · ПЕРЕД РАССВЕТОМ", "За дверью слышны шаги. Город просыпается.\nТы можешь решить, каким будет следующее утро.")
	if can_leave():
		option("Выйти в мир", func(): ending(true))
	option("Остаться дома", func(): ending(false))

func ending(outside: bool) -> void:
	screen("ПЕРВЫЙ ШАГ" if outside else "ЗНАКОМЫЙ СВЕТ", "Ты открываешь дверь. Воздух прохладный. Ты пока не знаешь, что сказать людям. Но сегодня ты здесь.\n\nКонец прототипа демо." if outside else "Экран снова загорается. Здесь всё знакомо. За окном начинается новый день.\n\nКонец прототипа демо.")
	option("В главное меню", menu)

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"day": day, "talks": talks, "constructive": constructive, "thought_started": thought_started}))

func load_progress() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		menu()
		return
	day = clampi(int(data.get("day", 1)), 1, 9)
	talks = maxi(0, int(data.get("talks", 0)))
	constructive = clampi(int(data.get("constructive", 0)), 0, talks)
	thought_started = bool(data.get("thought_started", false))
	morning()
