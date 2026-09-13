extends CanvasLayer
const Rules = preload("res://scripts/rules.gd")
signal action(name: String, value: Variant)
const INK := Color("08131e")
const CYAN := Color("76f7df")
const MUTED := Color("9eb5c5")
const WHITE := Color("edf6f7")
const AMBER := Color("ffb477")
var root: Control
var modal: Control
var hud: Control
var health_bar: ProgressBar
var energy_bar: ProgressBar
var health_text: Label
var energy_text: Label
var dash_text: Label
var time_text: Label
var score_text: Label
var status_text: Label
var hint: Label
var banner: Label
var boss_bar: ProgressBar
var boss_name: Label
var build_text: Label
var theme_ui: Theme
var regular: SystemFont
var heavy: SystemFont
var hint_time := 0.0
var banner_time := 0.0
var offers: Array = []
var key_names: Dictionary = {"left":"A","right":"D","up":"W","down":"S","dash":"Space","pulse":"E","jump":"F","weapon":"Q"}
var harvest_guide: Label
var flight_bar: ProgressBar
var flight_text: Label
var altitude_text: Label
var objective_text: Label
var weapon_text: Label
var weapon_detail: Label

func set_bindings(bindings: Dictionary) -> void:
	for id in bindings: key_names[id]=OS.get_keycode_string(int(bindings[id]))

func movement_keys() -> String:
	return "%s%s%s%s" % [key_names.up,key_names.left,key_names.down,key_names.right]

func _ready() -> void:
	layer = 10
	regular = SystemFont.new()
	regular.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue"])
	heavy = SystemFont.new()
	heavy.font_names = regular.font_names
	heavy.font_weight = 800
	theme_ui = Theme.new()
	theme_ui.default_font = regular
	theme_ui.default_font_size = 18
	theme_ui.set_color("font_color", "Label", WHITE)
	theme_ui.set_color("font_color", "Button", WHITE)
	theme_ui.set_color("font_hover_color", "Button", CYAN)
	theme_ui.set_color("font_focus_color", "Button", CYAN)
	theme_ui.set_stylebox("normal", "Button", panel(Color("152939"), Color("325266")))
	theme_ui.set_stylebox("hover", "Button", panel(Color("214454"), CYAN))
	theme_ui.set_stylebox("pressed", "Button", panel(Color("296556"), CYAN))
	theme_ui.set_stylebox("focus", "Button", panel(Color(0,0,0,0), CYAN, 2))
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_ui
	add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	build_hud()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)

func panel(fill: Color, border: Color = Color("294353"), width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(8)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s

func label_at(parent: Node, text: String, pos: Vector2, font_size: int = 18, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func text_line(text: String, size: int = 20, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func button(text: String, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 54
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		b.add_theme_stylebox_override("normal", panel(CYAN, CYAN))
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_hover_color", WHITE)
		b.add_theme_color_override("font_focus_color", INK)
	b.pressed.connect(callback)
	return b

func bar_at(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("1c303d")
	background.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	# Assign geometry after disabling percentage text; its default font minimum
	# would otherwise clamp the height and retain it after styles are updated.
	bar.size = size
	return bar

func build_hud() -> void:
	var top_shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0,Color(0.018,0.035,0.05,0.84))
	gradient.set_color(1,Color(0.018,0.035,0.05,0))
	var texture := GradientTexture2D.new()
	texture.gradient=gradient
	texture.fill_from=Vector2.ZERO
	texture.fill_to=Vector2(0,1)
	top_shade.texture=texture
	top_shade.size=Vector2(1440,195)
	top_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_shade)
	health_text = label_at(hud, "HULL  /  100", Vector2(35, 26), 17)
	health_bar = bar_at(hud, Vector2(35, 58), Vector2(238, 7), CYAN)
	status_text = label_at(hud, "SKYFORGE   /   SECTOR 07", Vector2(35, 82), 13, MUTED)
	time_text = label_at(hud, "00:00", Vector2(662, 20), 34)
	time_text.add_theme_font_override("font", heavy)
	score_text = label_at(hud, "000000  /  SCORE", Vector2(1180, 32), 18)
	label_at(hud, "ESC  PAUSE", Vector2(1260, 66), 13, MUTED)
	var reactor := Panel.new()
	reactor.position = Vector2(500, 785)
	reactor.size = Vector2(440, 91)
	reactor.add_theme_stylebox_override("panel", panel(Color(0.025,0.07,0.1,0.9)))
	reactor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(reactor)
	energy_text = label_at(reactor, "E  PULSE  /  0", Vector2(22, 12), 16, CYAN)
	energy_bar = bar_at(reactor, Vector2(22, 44), Vector2(250, 9), CYAN)
	dash_text = label_at(reactor, "SPACE  DASH\n●  ●", Vector2(302, 12), 16, WHITE)
	harvest_guide=label_at(reactor, "DASH THROUGH ORANGE SHOTS TO CHARGE", Vector2(22, 62), 10, MUTED)
	weapon_text=label_at(hud,"VECTOR CARBINE / I",Vector2(35,766),18,CYAN)
	weapon_detail=label_at(hud,"RAPID FIRE",Vector2(35,796),11,MUTED)
	build_text = label_at(hud, "", Vector2(35, 826), 11, MUTED)
	build_text.size = Vector2(400, 60)
	build_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint = label_at(hud, "", Vector2(360, 712), 20)
	hint.size = Vector2(720, 58)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner = label_at(hud, "", Vector2(310, 170), 28, CYAN)
	banner.size = Vector2(820, 100)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", heavy)
	boss_name = label_at(hud, "THE REACTOR GUARDIAN", Vector2(430, 92), 13, AMBER)
	boss_bar = bar_at(hud, Vector2(430, 120), Vector2(580, 8), AMBER)
	boss_bar.visible = false
	boss_name.visible = false
	objective_text = label_at(hud,"",Vector2(280,142),16,CYAN)
	objective_text.size = Vector2(880,52)
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position.y = 204
	var flight := Panel.new()
	flight.position = Vector2(983,785)
	flight.size = Vector2(305,91)
	flight.add_theme_stylebox_override("panel",panel(Color(0.025,0.07,0.1,0.9)))
	flight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flight)
	flight_text = label_at(flight,"F  JUMP / HOLD TO GLIDE",Vector2(18,12),14,CYAN)
	flight_bar = bar_at(flight,Vector2(18,44),Vector2(268,7),Color("b7d8ff"))
	altitude_text = label_at(flight,"WINGS READY",Vector2(18,62),11,MUTED)

func clear_modal() -> void:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.visible = true
	offers.clear()

func shade(alpha: float = 0.82) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.018,0.035,0.05,alpha)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(bg)

func column(pos: Vector2, width: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.position = pos
	box.size.x = width
	box.add_theme_constant_override("separation", 16)
	modal.add_child(box)
	return box

func show_title(best: int, practiced: bool) -> void:
	clear_modal()
	hud.visible = false
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.02,0.05,0.08,0.98))
	gradient.set_color(1, Color(0.02,0.05,0.08,0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2.ZERO
	tex.fill_to = Vector2(0.8,0)
	var veil := TextureRect.new()
	veil.texture = tex
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(veil)
	label_at(modal, "O V E R D R I V E     /     THE ENDLESS SKY HEIST", Vector2(65, 60), 13, CYAN)
	var title := label_at(modal, "PULSE\nBREAK", Vector2(58, 115), 104)
	title.add_theme_font_override("font", heavy)
	title.add_theme_constant_override("line_spacing", -25)
	label_at(modal, "STEAL THE STORM.", Vector2(65, 394), 25, CYAN)
	var desc := label_at(modal, "Leap the gates. Unfold your wings.\nBuild your arsenal. Break the next horizon.", Vector2(65, 442), 19, MUTED)
	desc.size.x = 490
	var box := column(Vector2(65, 515), 385)
	box.add_theme_constant_override("separation",10)
	var play := button("BEGIN SKYBOUND    →", func(): action.emit("campaign", false), true)
	box.add_child(play)
	box.add_child(button("PRACTICE THE HEIST", func(): action.emit("practice", true)))
	box.add_child(button("CLASSIC  /  SIX-MINUTE SURVIVAL", func(): action.emit("start", false)))
	var controls:=HBoxContainer.new()
	controls.add_theme_constant_override("separation",10)
	for item in [["SETTINGS","settings"],["QUIT GAME","quit"]]:
		var control:=button(item[0],func(): action.emit(item[1],null))
		control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		controls.add_child(control)
	box.add_child(controls)
	play.grab_focus()
	label_at(modal, "PERSONAL BEST  /  %06d" % best, Vector2(65, 786), 14, AMBER)
	label_at(modal, "%s  MOVE    %s  DASH    %s  PULSE    %s  JUMP / GLIDE" % [movement_keys(),key_names.dash.to_upper(),key_names.pulse.to_upper(),key_names.jump.to_upper()], Vector2(65, 846), 12, MUTED)
	label_at(modal, "03 SECTORS. THEN THE UNKNOWN.\nNEW ROUTES / EVOLVING WEAPONS", Vector2(945, 790), 14, CYAN)
	label_at(modal,"COURIER / MK.III\nVECTOR WING SYSTEM",Vector2(1020,91),14,CYAN)
	if not practiced:
		label_at(modal, "FIRST RUN? PRACTICE TEACHES HARVESTING. SKYBOUND TEACHES FLIGHT.", Vector2(65, 814), 10, MUTED)

func show_game() -> void:
	modal.visible = false
	hud.visible = true

func show_pause() -> void:
	clear_modal(); shade()
	var box := column(Vector2(500, 238), 440)
	box.add_child(text_line("TAKE A BREATH", 40, CYAN))
	box.add_child(text_line("The foundry can wait.", 19, MUTED))
	var resume_button := button("RESUME", func(): action.emit("resume", null), true)
	box.add_child(resume_button)
	box.add_child(button("SETTINGS", func(): action.emit("settings", null)))
	box.add_child(button("RESTART RUN", func(): action.emit("restart", null)))
	box.add_child(button("RETURN TO TITLE", func(): action.emit("title", null)))
	box.add_child(button("QUIT GAME", func(): action.emit("quit", null)))
	resume_button.grab_focus()

func show_practice_complete() -> void:
	clear_modal(); shade(0.9)
	var box := column(Vector2(455,240),530)
	box.add_child(text_line("READY FOR THE HEIST",38,CYAN))
	box.add_child(text_line("You have the core move: harvest, reposition, pulse.\nTake flight, build an arsenal, and dive into endless sectors.",21,MUTED))
	var start := button("BEGIN SKYBOUND    →",func():action.emit("campaign",false),true)
	box.add_child(start)
	box.add_child(button("PRACTICE AGAIN",func():action.emit("practice",true)))
	box.add_child(button("RETURN TO TITLE",func():action.emit("title",null)))
	start.grab_focus()

func show_settings(settings: Dictionary, bindings: Dictionary) -> void:
	clear_modal(); shade(0.94)
	var box := column(Vector2(370, 84), 700)
	box.add_theme_constant_override("separation", 10)
	box.add_child(text_line("MAKE IT YOURS", 38, CYAN))
	box.add_child(text_line("Settings save automatically.", 16, MUTED))
	for item in [["volume", "VOLUME"], ["shake", "SCREEN SHAKE"]]:
		var row := HBoxContainer.new()
		var label := text_line(item[1], 16)
		label.custom_minimum_size.x = 210
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0; slider.max_value = 1; slider.step = 0.05
		slider.value = settings.get(item[0], 0.6)
		slider.custom_minimum_size = Vector2(360,40)
		slider.value_changed.connect(func(value): action.emit("setting", {"key":item[0],"value":value}))
		row.add_child(slider)
		box.add_child(row)
	var assist := CheckButton.new()
	assist.text = "ASSIST  /  slower enemy attacks"
	assist.button_pressed = settings.get("assist", false)
	assist.toggled.connect(func(value): action.emit("setting", {"key":"assist","value":value}))
	box.add_child(assist)
	if settings.get("won",false):
		var overdrive:=CheckButton.new()
		overdrive.text="OVERDRIVE  /  tougher enemies + waves, next run"
		overdrive.button_pressed=settings.get("overdrive",false)
		overdrive.toggled.connect(func(value):action.emit("overdrive",value))
		box.add_child(overdrive)
	var low := CheckButton.new()
	low.text = "LOW EFFECTS  /  reduced particles and shadows"
	low.button_pressed = settings.get("low_effects", false)
	low.toggled.connect(func(value): action.emit("setting", {"key":"low_effects","value":value}))
	box.add_child(low)
	box.add_child(text_line("KEYBOARD  /  select an action, then press a key", 15, AMBER))
	var keys := GridContainer.new()
	keys.columns = 2
	keys.add_theme_constant_override("h_separation", 12)
	keys.add_theme_constant_override("v_separation", 8)
	for id in ["left","right","up","down","dash","pulse","jump","weapon"]:
		var key_name := OS.get_keycode_string(int(bindings[id]))
		var key_button := button(id.to_upper() + "   [" + key_name + "]", func(): action.emit("rebind", id))
		key_button.custom_minimum_size = Vector2(344,42)
		keys.add_child(key_button)
	box.add_child(keys)
	box.add_child(button("RESET CONTROLS", func(): action.emit("reset_controls", null)))
	var back := button("BACK", func(): action.emit("back", null), true)
	box.add_child(back)
	back.grab_focus()

func show_rebind(id: String) -> void:
	clear_modal(); shade(0.95)
	var box := column(Vector2(470, 290), 500)
	box.add_child(text_line("BIND " + id.to_upper(), 40, CYAN))
	box.add_child(text_line("Press a keyboard key.\nEsc cancels. Reserved menu keys cannot be assigned.", 22))

func show_upgrades(ids: Array) -> void:
	clear_modal(); shade(0.94)
	offers = ids.duplicate()
	label_at(modal, "REACTOR EVOLUTION", Vector2(485, 172), 34, CYAN)
	label_at(modal, "Choose an upgrade + repair 20 hull. Combat is paused.", Vector2(463, 223), 17, MUTED)
	for i in range(ids.size()):
		var id: String = ids[i]
		var data: Dictionary = Rules.UPGRADE_DATA[id]
		var card := PanelContainer.new()
		card.position = Vector2(176 + i * 368, 308)
		card.size = Vector2(352, 360)
		card.add_theme_stylebox_override("panel", panel(Color("122736"), Color("3a6471")))
		modal.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 18)
		card.add_child(box)
		box.add_child(text_line("0%d  /  %s" % [i+1,data.family], 13, AMBER))
		box.add_child(text_line(data.icon, 46, CYAN))
		box.add_child(text_line(data.name, 23))
		var desc := text_line(data.description, 17, MUTED)
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(desc)
		var choose := button("[%d]  INSTALL" % (i+1), func(): action.emit("upgrade", id), true)
		box.add_child(choose)
		if i == 0: choose.grab_focus()
	label_at(modal, "UPGRADES LAST FOR THIS RUN  /  EVERY CHOICE CHANGES YOUR PLAY", Vector2(403, 724), 12, MUTED)

func show_weapon_upgrades(ids: Array, data: Array) -> void:
	clear_modal(); shade(0.95)
	label_at(modal,"THE ARMORY",Vector2(558,115),40,CYAN)
	label_at(modal,"New hardware. New ways to break the storm.",Vector2(486,173),19,MUTED)
	for i in range(ids.size()):
		var id: String=ids[i]
		var item: Dictionary=data[i]
		var card:=PanelContainer.new()
		card.position=Vector2(176+i*368,252)
		card.size=Vector2(352,465)
		card.add_theme_stylebox_override("panel",panel(Color("102431"),item.color.darkened(0.35)))
		modal.add_child(card)
		var box:=VBoxContainer.new()
		box.add_theme_constant_override("separation",15)
		card.add_child(box)
		box.add_child(text_line("0%d  /  %s" % [i+1,item.family],12,item.color))
		var preview:=Control.new()
		preview.custom_minimum_size=Vector2(300,90)
		preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
		box.add_child(preview)
		weapon_blueprint(preview,id,item.color)
		box.add_child(text_line(item.name,25,WHITE))
		box.add_child(text_line(item.action,16,item.color))
		box.add_child(text_line(item.benefit,12,WHITE))
		var desc:=text_line(item.description,17,MUTED)
		desc.size_flags_vertical=Control.SIZE_EXPAND_FILL
		box.add_child(desc)
		var choose:=button("[%d]  EQUIP & EVOLVE" % (i+1),func():action.emit("weapon_upgrade",id),true)
		box.add_child(choose)
		if i==0: choose.grab_focus()
	label_at(modal,"KEEP EVERY UNLOCK  /  %s SWITCHES WEAPONS DURING COMBAT  /  RANKS III & V TRANSFORM YOUR GUN" % key_names.weapon.to_upper(),Vector2(265,768),12,MUTED)

func weapon_blueprint(parent: Control, id: String, color: Color) -> void:
	# Side elevation of each gun; four distinct silhouettes, matching the held mesh.
	var pieces: Array=[]
	match id:
		"kinetic": pieces=[Rect2(34,28,159,25),Rect2(183,31,69,13),Rect2(95,47,23,29),Rect2(33,33,23,35),Rect2(142,20,45,7)]
		"scatter": pieces=[Rect2(34,30,127,33),Rect2(150,29,93,12),Rect2(150,48,93,12),Rect2(46,56,26,22),Rect2(87,62,44,10)]
		"arc": pieces=[Rect2(45,30,94,28),Rect2(78,55,21,22),Rect2(134,25,25,39),Rect2(168,25,25,39),Rect2(199,25,25,39),Rect2(224,38,31,13)]
		"plasma": pieces=[Rect2(29,27,127,38),Rect2(152,16,87,14),Rect2(152,60,87,14),Rect2(150,37,112,15),Rect2(64,60,25,21)]
	for i in range(pieces.size()):
		var tile:=ColorRect.new()
		tile.position=pieces[i].position; tile.size=pieces[i].size
		tile.color=color if i>0 else color.darkened(0.5)
		tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		parent.add_child(tile)

func update_weapon(weapons) -> void:
	var profile: Dictionary=weapons.PROFILES[weapons.mode]
	weapon_text.text="%s  /  %s" % [profile.name,weapons.roman(weapons.tier())]
	weapon_text.add_theme_color_override("font_color",profile.color)
	weapon_detail.text="%s  ·  %s SWITCH  ·  +%d%% POWER" % [profile.role,key_names.weapon.to_upper(),roundi((weapons.damage_scale()-1)*100)]

func show_result(won: bool, data: Dictionary) -> void:
	clear_modal(); shade(0.93)
	hud.visible = false
	var box := column(Vector2(420,100),600)
	box.add_theme_constant_override("separation",10)
	box.add_child(text_line("RUN BANKED" if data.get("retired",false) else "REACTOR SECURED" if won else "SIGNAL LOST",42,CYAN if won or data.get("retired",false) else AMBER))
	box.add_child(text_line("The storm keeps moving. So will you.",20,MUTED))
	box.add_child(text_line("%06d" % data.score,64,WHITE))
	box.add_child(text_line("SCORE  /  BEST %06d" % data.best,14,AMBER))
	box.add_child(text_line("%d machines broken · %d shots stolen · %d pulses" % [data.kills,data.absorbed,data.pulses],17))
	box.add_child(text_line("TIME  %02d:%02d" % [int(data.time)/60,int(data.time)%60],16,MUTED))
	if data.get("campaign",false):
		box.add_child(text_line("SECTOR %02d · %d AIR RELAYS · %d GUARDIANS" % [data.sector,data.relays,data.get("guardians",0)],15,CYAN))
		box.add_child(text_line("ROUTE SEED  %s" % str(data.get("seed",0)),12,MUTED))
	box.add_child(text_line("%s  /  RANK %s" % [data.get("weapon","VECTOR CARBINE"),data.get("rank","I")],16,CYAN))
	if won: box.add_child(text_line("OVERDRIVE UNLOCKED  /  Enable it in Settings for a tougher heist.",13,CYAN))
	var names: PackedStringArray = []
	for id in data.upgrades: names.append(Rules.UPGRADE_DATA[id].name)
	box.add_child(text_line(" + ".join(names) if not names.is_empty() else "Your next weapon is waiting at the next checkpoint.",13,MUTED))
	var again := button("RUN IT BACK    →",func():action.emit("restart",null),true)
	box.add_child(again)
	box.add_child(button("RETURN TO TITLE",func():action.emit("title",null)))
	box.add_child(button("QUIT GAME",func():action.emit("quit",null)))
	again.grab_focus()

func show_sector_complete(index: int, sector_name: String, elapsed: float, relays: int, data: Dictionary = {}) -> void:
	clear_modal(); shade(0.92)
	hud.visible = false
	var box := column(Vector2(400,140),640)
	box.add_theme_constant_override("separation",16)
	box.add_child(text_line("SECTOR %02d / SECURED" % (index+1),15,CYAN))
	box.add_child(text_line(sector_name,46,WHITE))
	box.add_child(text_line("The next horizon is yours to take.",22,MUTED))
	box.add_child(text_line("%d AIR RELAYS · %d GUARDIANS · %02d:%02d" % [relays,data.get("guardians",0),int(elapsed)/60,int(elapsed)%60],16,AMBER))
	box.add_child(text_line("NEXT / %s\n%s · %s" % [data.get("next","THE NEXT HORIZON"),data.get("route","NEW ROUTE"),data.get("modifier","NEW HARDWARE")],20,CYAN))
	box.add_child(text_line("Keep your arsenal. Install a weapon upgrade. Continue as far as you can.",18,MUTED))
	var next := button("UPGRADE & DIVE DEEPER    →",func():action.emit("next_sector",null),true)
	box.add_child(next)
	box.add_child(button("BANK SCORE & END RUN",func():action.emit("bank",null)))
	box.add_child(button("QUIT GAME",func():action.emit("quit",null)))
	box.add_child(text_line("ROUTE SEED  %s  /  RESTART REPEATS THIS ROUTE" % str(data.get("seed",0)),12,MUTED))
	next.grab_focus()

func update_traversal(traversal) -> void:
	flight_bar.value = traversal.fuel*100.0
	flight_text.text = "%s  JUMP / HOLD TO GLIDE" % key_names.jump.to_upper()
	if traversal.gliding:
		altitude_text.text = "GLIDING  /  %.1f m  ·  RELEASE TO DROP" % traversal.height
	elif not traversal.grounded:
		altitude_text.text = "AIRBORNE  /  %.1f m  ·  %s" % [traversal.height,"WINGS EMPTY" if traversal.fuel<0.01 else "HOLD TO GLIDE"]
	else:
		altitude_text.text = "WINGS READY  /  JUMP OVER LOW SHOTS & GATES" if traversal.fuel>=0.99 else "RECHARGING WINGS  /  STAY ON THE DECK"

func show_hint(text: String, seconds: float = 4) -> void:
	hint.text = text
	hint_time = seconds
	hint.modulate.a = 1

func show_banner(title: String, subtitle: String) -> void:
	banner.text = title + "\n" + subtitle
	banner_time = 3.5
	banner.modulate.a = 1

func update_game(rules, run_time: float, boss_hp: float, boss_max: float, practice: bool) -> void:
	health_bar.value = rules.health
	health_text.text = "HULL  /  %03d" % ceili(rules.health)
	health_bar.get_theme_stylebox("fill").bg_color = CYAN if rules.health > 30 else Color("ff7467")
	energy_bar.value = rules.energy
	var charged: bool = rules.energy >= 85
	var pulse_color := Color("bd98ff") if charged else CYAN
	energy_bar.get_theme_stylebox("fill").bg_color = pulse_color
	energy_text.add_theme_color_override("font_color",pulse_color)
	energy_text.text = "%s  PULSE  /  %03d%s" % [key_names.pulse.to_upper(),int(rules.energy), "  OVERLOAD" if charged else "  READY" if rules.energy >= 30 else ""]
	dash_text.text = key_names.dash.to_upper()+"  DASH\n" + ("●  ●" if rules.dash_charges == 2 else "●  ○" if rules.dash_charges == 1 else "○  ○")
	time_text.text = "%02d:%02d" % [int(run_time)/60,int(run_time)%60]
	score_text.text = "%06d  /  SCORE" % rules.score
	status_text.text = "PRACTICE  /  LEARN THE HEIST" if practice else "SKYFORGE  /  THREAT %02d" % (1+int(run_time/60))
	boss_bar.visible = boss_max > 0
	boss_name.visible = boss_max > 0
	if boss_max > 0: boss_bar.value = boss_hp / boss_max * 100
	var names: PackedStringArray = []
	for id in rules.upgrades: names.append(Rules.UPGRADE_DATA[id].name)
	build_text.text = "  /  ".join(names) if not names.is_empty() else "EVOLVE YOUR WEAPON AT THE NEXT CHECKPOINT"

func _process(delta: float) -> void:
	if hint_time > 0:
		hint_time -= delta
		hint.modulate.a = clampf(hint_time,0,1)
	if banner_time > 0:
		banner_time -= delta
		banner.modulate.a = clampf(banner_time,0,1)
	# Canvas items scale together to a consistent 1440 x 900 design space.
	var viewport_size := get_viewport().get_visible_rect().size
	root.scale = Vector2(viewport_size.x / 1440.0, viewport_size.y / 900.0)
	root.size = Vector2(1440,900)
