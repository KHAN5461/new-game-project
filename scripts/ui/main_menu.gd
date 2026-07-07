extends Control

@onready var play_btn: Button = $VBoxContainer/PlayBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn
@onready var settings_btn: Button = $VBoxContainer/SettingsBtn

@onready var title_banner = $TitleBanner

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	
	var vbox = $VBoxContainer
	var shop_btn = Button.new()
	shop_btn.name = "ShopBtn"
	shop_btn.text = "UPGRADES SHOP"
	shop_btn.pressed.connect(_on_shop_pressed)
	vbox.add_child(shop_btn)
	vbox.move_child(shop_btn, settings_btn.get_index())
	
	var rts_btn = Button.new()
	rts_btn.name = "RTSBtn"
	rts_btn.text = "RTS MODE"
	rts_btn.pressed.connect(_on_rts_pressed)
	vbox.add_child(rts_btn)
	vbox.move_child(rts_btn, shop_btn.get_index() + 1)
	
	if title_banner:
		title_banner.pivot_offset = title_banner.size / 2.0
		
	var buttons = [play_btn, shop_btn, rts_btn, settings_btn, quit_btn]
	for btn in buttons:
		if not btn: continue
		
		btn.custom_minimum_size = Vector2(350, 80)
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		btn.add_theme_font_size_override("font_size", 28)
		
		var style = StyleBoxTexture.new()
		style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides.png")
		style.texture_margin_left = 20
		style.texture_margin_top = 20
		style.texture_margin_right = 20
		style.texture_margin_bottom = 20
		
		var hover = StyleBoxTexture.new()
		hover.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Hover_9Slides.png")
		hover.texture_margin_left = 20
		hover.texture_margin_top = 20
		hover.texture_margin_right = 20
		hover.texture_margin_bottom = 20
		
		var pressed = StyleBoxTexture.new()
		pressed.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides_Pressed.png")
		pressed.texture_margin_left = 20
		pressed.texture_margin_top = 20
		pressed.texture_margin_right = 20
		pressed.texture_margin_bottom = 20
		
		if btn == quit_btn:
			style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Red_9Slides.png")
			hover.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Red_9Slides.png") # Re-using red for hover
			hover.modulate_color = Color(1.2, 1.2, 1.2)
			pressed.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Red_9Slides_Pressed.png")
			
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_exit.bind(btn))

func _on_btn_hover(btn: Button) -> void:
	if AudioManager: AudioManager.play_type() # Simple blip sound

func _on_btn_exit(btn: Button) -> void:
	pass

var bg_scroll: float = 0.0

func _process(delta: float) -> void:
	var bg = get_node_or_null("Background")
	if bg:
		bg_scroll -= 30.0 * delta
		if bg_scroll <= -128.0:
			bg_scroll += 128.0
		bg.position = Vector2(bg_scroll, bg_scroll)
		bg.size = get_viewport_rect().size + Vector2(128, 128)

func _on_play_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/level_select.tscn")

func _on_rts_pressed() -> void:
	SceneTransition.change_scene("res://scenes/core/game_manager_old.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

var settings_menu_instance
func _on_settings_pressed() -> void:
	if not settings_menu_instance:
		var sm_scene = load("res://scenes/ui/settings_menu.tscn")
		if sm_scene:
			settings_menu_instance = sm_scene.instantiate()
			add_child(settings_menu_instance)
	else:
		settings_menu_instance.show()

var shop_menu_instance
func _on_shop_pressed() -> void:
	if not shop_menu_instance:
		shop_menu_instance = load("res://scripts/ui/shop_menu.gd").new()
		add_child(shop_menu_instance)
	else:
		shop_menu_instance.show()
