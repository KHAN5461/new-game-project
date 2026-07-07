extends Control
class_name ShopMenu

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Premium blur/darken background
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.85) # Deep premium navy/black
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Main container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 500)
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	
	# Premium Glassmorphism Style
	var style = StyleBoxTexture.new()
	style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Banners/Carved_9Slides.png")
	style.texture_margin_left = 24
	style.texture_margin_top = 24
	style.texture_margin_right = 24
	style.texture_margin_bottom = 24
	style.modulate_color = Color(1.0, 1.0, 1.0, 0.95)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	# Premium Title
	var title = Label.new()
	title.text = "UPGRADES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0.8, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 4)
	vbox.add_child(title)
	
	# Gold Label
	var gold_label = Label.new()
	if Global:
		gold_label.text = "✦ Total Gold: " + str(Global.total_gold) + " ✦"
	else:
		gold_label.text = "✦ Total Gold: 0 ✦"
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 28)
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0.2))
	vbox.add_child(gold_label)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_vbox)
	
	# Helper to style buttons
	var style_btn = func(btn: Button, txt: String, color: Color):
		btn.text = txt
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(550, 75)
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		
		var normal = StyleBoxTexture.new()
		normal.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides.png")
		normal.texture_margin_left = 20
		normal.texture_margin_top = 20
		normal.texture_margin_right = 20
		normal.texture_margin_bottom = 20
		normal.modulate_color = color.lightened(0.5) # Tint it lightly
		btn.add_theme_stylebox_override("normal", normal)
		
		var hover = StyleBoxTexture.new()
		hover.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Hover_9Slides.png")
		hover.texture_margin_left = 20
		hover.texture_margin_top = 20
		hover.texture_margin_right = 20
		hover.texture_margin_bottom = 20
		hover.modulate_color = color.lightened(0.8)
		btn.add_theme_stylebox_override("hover", hover)
		
		var pressed = StyleBoxTexture.new()
		pressed.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides_Pressed.png")
		pressed.texture_margin_left = 20
		pressed.texture_margin_top = 20
		pressed.texture_margin_right = 20
		pressed.texture_margin_bottom = 20
		pressed.modulate_color = color.lightened(0.5)
		btn.add_theme_stylebox_override("pressed", pressed)
		

	
	var health_btn = Button.new()
	style_btn.call(health_btn, "Max Health +5 (Cost: 10 Gold)", Color(1.0, 0.3, 0.3))
	health_btn.pressed.connect(func():
		if Global and Global.total_gold >= 10:
			Global.total_gold -= 10
			Global.max_health += 5
			Global.save_game()
			gold_label.text = "✦ Total Gold: " + str(Global.total_gold) + " ✦"
			health_btn.text = "Max Health +5 (Purchased!)"
			
			# Flash green
			var t = create_tween()
			health_btn.modulate = Color(0.5, 1.0, 0.5)
			t.tween_property(health_btn, "modulate", Color(1,1,1), 0.5)
	)
	btn_vbox.add_child(health_btn)
	
	var api_btn = Button.new()
	style_btn.call(api_btn, "Unlock shield_block() API (Cost: 25 Gold)", Color(0.3, 0.8, 1.0))
	api_btn.pressed.connect(func():
		if Global and Global.total_gold >= 25:
			Global.total_gold -= 25
			if not "shield_block" in Global.unlocked_spells:
				Global.unlocked_spells.append("shield_block")
			Global.save_game()
			gold_label.text = "✦ Total Gold: " + str(Global.total_gold) + " ✦"
			api_btn.text = "API Unlocked!"
			
			# Flash green
			var t = create_tween()
			api_btn.modulate = Color(0.5, 1.0, 0.5)
			t.tween_property(api_btn, "modulate", Color(1,1,1), 0.5)
	)
	btn_vbox.add_child(api_btn)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var close_btn = Button.new()
	style_btn.call(close_btn, "CLOSE", Color(0.5, 0.5, 0.5))
	close_btn.custom_minimum_size = Vector2(250, 60)
	close_btn.pressed.connect(func(): queue_free())
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(close_btn)
	vbox.add_child(hbox)
	
	modulate.a = 1.0
	panel.scale = Vector2(1, 1)
