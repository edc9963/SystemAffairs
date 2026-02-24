extends Control

# UI References
@onready var action_container = $VBoxMain/TopHBox/MainArea/Margin2/ActionGrid
@onready var log_label = $VBoxMain/LogPanel/Margin/VBox/RichTextLabel
@onready var location_label = $VBoxMain/TopHBox/MainArea/Margin/Header/LocationLabel
@onready var time_label = $VBoxMain/TopHBox/Sidebar/Margin/VBox/TimeLabel
@onready var breakpoint_btn = $VBoxMain/TopHBox/MainArea/Margin/Header/BreakpointBtn
@onready var log_panel = $VBoxMain/LogPanel
@onready var bg_rect = $BG
var log_timer: Timer

# Background Images
var bg_images = {
	"home_morning": preload("res://background/home_morning.png"),
	"home_night": preload("res://background/home_night.png"),
	"office_morning": preload("res://background/office_morning.png"),
	"office_night": preload("res://background/office_night.png"),
	"bar": preload("res://background/bar.png"),
	"cvs_morning": preload("res://background/convenience_store_morning.png"),
	"cvs_night": preload("res://background/convenience_store_morning_night.png"),
	"gym_morning": preload("res://background/gym_morning.png"),
	"gym_night": preload("res://background/gym_night.png"),
	"temple_morning": preload("res://background/temple_morning.png"),
	"temple_night": preload("res://background/temple_night.png")
}

# Stats References
@onready var money_label = $VBoxMain/TopHBox/Sidebar/Margin/VBox/StatsContainer/MoneyLabel
@onready var hp_bar = $VBoxMain/TopHBox/Sidebar/Margin/VBox/StatsContainer/HPBar
@onready var san_bar = $VBoxMain/TopHBox/Sidebar/Margin/VBox/StatsContainer/SanBar
@onready var libido_bar = $VBoxMain/TopHBox/Sidebar/Margin/VBox/StatsContainer/LibidoBar
@onready var project_bar = $VBoxMain/TopHBox/MainArea/Margin/Header/HBoxContainer/ProjectBar
@onready var project_label = $VBoxMain/TopHBox/MainArea/Margin/Header/HBoxContainer/ProjectLabel

@onready var attr_labels = {
	"comm": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AttrContainer/CommLabel,
	"tech": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AttrContainer/TechLabel,
	"charm": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AttrContainer/CharmLabel,
	"logic": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AttrContainer/LogicLabel,
	"res": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AttrContainer/ResLabel
}

# Affection References
@onready var aff_labels = {
	"junior": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AffectionContainer/JuniorLabel,
	"pm": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AffectionContainer/PMLabel,
	"peer": $VBoxMain/TopHBox/Sidebar/Margin/VBox/AffectionContainer/PeerLabel
}

# Inventory References
@onready var backpack_btn = $VBoxMain/TopHBox/MainArea/Margin/Header/BackpackBtn
@onready var inv_panel = $InventoryPanel
@onready var inv_grid = $InventoryPanel/VBox/Scroll/ItemGrid
@onready var inv_close_btn = $InventoryPanel/VBox/Header/CloseBtn

# Character Panel References
@onready var character_btn = $VBoxMain/TopHBox/MainArea/Margin/Header/CharacterBtn
@onready var char_panel = $CharacterPanel
@onready var char_close_btn = $CharacterPanel/Margin/VBox/Header/CloseBtn
@onready var popup_aff_labels = {
	"junior": $CharacterPanel/Margin/VBox/Grid/CharJunior/VBox/AffLabel,
	"pm": $CharacterPanel/Margin/VBox/Grid/CharPM/VBox/AffLabel,
	"peer": $CharacterPanel/Margin/VBox/Grid/CharPeer/VBox/AffLabel
}

@onready var sleep_panel = $SleepPanel
@onready var sleep_spin = $SleepPanel/VBox/SpinBox
@onready var sleep_confirm = $SleepPanel/VBox/HBox/ConfirmBtn
@onready var sleep_cancel = $SleepPanel/VBox/HBox/CancelBtn

var actions_data = {}
var project_action_defs = {}

func _ready():
	GameState.log_message.connect(_on_log_message)
	GameState.time_changed.connect(_update_ui)
	GameState.stats_changed.connect(_update_ui)
	
	log_panel.visible = false
	log_timer = Timer.new()
	log_timer.one_shot = true
	log_timer.wait_time = 4.0
	log_timer.timeout.connect(_hide_log)
	add_child(log_timer)
	
	setup_actions_from_csv()
	render_actions()
	_update_ui()
	
	if backpack_btn: backpack_btn.pressed.connect(_on_backpack_btn_pressed)
	if inv_close_btn: inv_close_btn.pressed.connect(_on_inventory_close_pressed)

	if character_btn: character_btn.pressed.connect(_on_character_btn_pressed)
	if char_close_btn: char_close_btn.pressed.connect(_on_char_close_pressed)

	if sleep_confirm: sleep_confirm.pressed.connect(_on_sleep_confirm_pressed)
	if sleep_cancel: sleep_cancel.pressed.connect(_on_sleep_cancel_pressed)

func _on_character_btn_pressed():
	if char_panel.visible:
		char_panel.visible = false
	else:
		_update_ui()
		char_panel.visible = true

func _on_char_close_pressed():
	char_panel.visible = false

func _hide_log():
	log_panel.visible = false

func _on_log_message(msg):
	log_label.append_text("> " + msg + "\n")
	log_panel.visible = true
	log_timer.start()

func _update_ui():
	# Header
	var t = GameState.time
	var day_str = "Day %d" % t.day
	var time_str = "%02d:%02d" % [t.hour, t.minute]
	var wkd_str = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][t.weekday - 1]
	time_label.text = "%s\n%s (%s)" % [day_str, time_str, wkd_str]
	location_label.text = get_location_name(GameState.location)
	
	# Breakpoint System Style override
	if GameState.is_breakpoint_active:
		breakpoint_btn.text = "RESUME TIME"
		modulate = Color(0.5, 0.5, 0.5)
	else:
		breakpoint_btn.text = "SYSTEM BREAKPOINT"
		modulate = Color(1, 1, 1)

	_update_background()

	# Stats
	money_label.text = "Money: $%d" % GameState.money
	
	var stats = $VBoxMain/TopHBox/Sidebar/Margin/VBox/StatsContainer
	
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.hp
	var hp_pct = (GameState.hp/GameState.max_hp)*100
	stats.get_node("HPLabel").text = "HP: %.0f/%.0f (%.0f%%)" % [
		GameState.hp, GameState.max_hp, hp_pct]
	
	san_bar.max_value = GameState.max_san
	san_bar.value = GameState.san
	var san_pct = (GameState.san/GameState.max_san)*100
	stats.get_node("SanLabel").text = "SAN: %.0f/%.0f (%.0f%%)" % [
		GameState.san, GameState.max_san, san_pct]
	
	libido_bar.max_value = GameState.max_libido
	libido_bar.value = GameState.libido
	var lib_pct = (GameState.libido/GameState.max_libido)*100
	stats.get_node("LibidoLabel").text = "Libido: %.0f/%.0f (%.0f%%)" % [
		GameState.libido, GameState.max_libido, lib_pct]
	
	# Waterfall Project Progress
	var target_per_stage = GameConstants.project_target / 3.0
	var total_prog = (GameState.prog_meeting + GameState.prog_spec + GameState.prog_test)
	var total_pct = (total_prog / GameConstants.project_target) * 100.0
	
	project_bar.max_value = GameConstants.project_target
	project_bar.value = total_prog
	
	# Determine Stage Text
	var stage_text = "Idle"
	if GameState.prog_meeting < target_per_stage: stage_text = "Meeting"
	elif GameState.prog_spec < target_per_stage: stage_text = "Spec"
	elif GameState.prog_test < target_per_stage: stage_text = "Testing"
	else: stage_text = "Done"
	
	project_label.text = "Project: [%s] %.1f%%" % [stage_text, total_pct]

	# Attributes
	for key in attr_labels:
		# The original code had a dummy "hp_text" in attr_labels, which is no longer needed
		# as HPLabel is directly referenced. Removing the skip.
		var val = GameState.attributes.get(key, 0)
		attr_labels[key].text = "%s: %d" % [key.capitalize(), val]

	# Affection
	for key in aff_labels:
		if GameState.characters.has(key):
			var char_data = GameState.characters[key]
			aff_labels[key].text = "%s: %d" % [char_data.name, char_data.affection]
			
	if popup_aff_labels != null:
		for key in popup_aff_labels:
			if GameState.characters.has(key):
				var char_data = GameState.characters[key]
				var aff = char_data.affection
				popup_aff_labels[key].text = "[center][color=#ff99cc]好感度:[/color] %d[/center]" % aff

	# Backpack
	var item_count = 0
	for k in GameState.inventory:
		item_count += GameState.inventory[k]
	if backpack_btn: backpack_btn.text = "背包 (%d)" % item_count

func get_location_name(loc_id):
	var map = {
		"office": "辦公室 (Office)",
		"home": "家 (Home)",
		"bar": "酒吧 (Bar)",
		"gym": "健身房 (Gym)",
		"temple": "宮廟 (Temple)",
		"meis": "美姨豆漿 (Mei's)",
		"bear": "兼職外送 (Bear)",
		"cvs": "便利超商 (CVS)",
		"mall": "電子商場 (3C Mall)",
		"dept": "百貨精品 (Dept. Store)",
		"go_out_select": "外出 (Going Out)",
		"wakeup_mode": "早晨 (Morning)",
		"project_board": "專案看板 (Board)"
	}
	return map.get(loc_id, loc_id)

func render_actions():
	for child in action_container.get_children():
		child.queue_free()
	
	# Breakpoint Logic: Show Location Actions + Debug
	var current_list = []
	if actions_data.has(GameState.location):
		current_list = actions_data[GameState.location].duplicate()
	
	if GameState.is_breakpoint_active:
		# Append Debug/Exit actions to current list
		var bp_list = actions_data.get("breakpoint", [])
		for act in bp_list:
			current_list.append(act)
	
	for act in current_list:
		if act.has("condition") and not act.condition.call():
			continue
			
		var btn = Button.new()
		var cost_str = ""
		if act.cost.has("time"): cost_str += "%dm " % act.cost.time
		if act.cost.has("hp"): cost_str += "HP-%d " % act.cost.hp
		if act.cost.has("money"): cost_str += "$%d " % act.cost.money
		
		# In Breakpoint, time cost is SAN cost
		if GameState.is_breakpoint_active and act.cost.has("time"):
			cost_str += "(BP:San-%d)" % act.cost.time
		
		if cost_str != "":
			btn.text = "%s\n(%s)" % [act.label, cost_str]
		else:
			btn.text = "%s" % act.label
			
		btn.custom_minimum_size = Vector2(120, 80)
		btn.pressed.connect(_on_action_pressed.bind(act))
		action_container.add_child(btn)

func _on_action_pressed(act):
	# --- Breakpoint Logic (Time Stop) ---
	if GameState.is_breakpoint_active:
		# 1. Check Costs (Money/HP still apply?)
		# User said: "All actions normal, change Cost Time = Cost San"
		if act.cost.has("hp") and GameState.hp < act.cost.hp:
			GameState.log_message.emit("體力不足！")
			return
		if act.cost.has("money") and GameState.money < act.cost.money:
			GameState.log_message.emit("金錢不足！")
			return
			
		# 2. Apply Costs (HP/Money)
		if act.cost.has("hp"): GameState.modify_stat("hp", -act.cost.hp)
		if act.cost.has("money"): GameState.modify_money(-act.cost.money)
		
		# 3. Handle Time -> Sanity
		var time_cost = act.cost.get("time", 0)
		if time_cost > 0:
			GameState.modify_stat("san", time_cost) # Increase Stress
			GameState.log_message.emit("時停行動... 累積壓力 %d" % time_cost)
		
		# 4. Check Sanity Overflow
		if GameState.san >= GameState.max_san:
			GameState.is_breakpoint_active = false
			GameState.log_message.emit("壓力爆表！強制解除時間暫停！")
			_update_ui()
			
		# 5. Apply Effects (Normal logic without time update)
		_apply_action_effects(act)
		render_actions()
		return

	# --- Normal Logic ---
	if act.cost.has("hp") and GameState.hp < act.cost.hp:
		GameState.log_message.emit("體力不足！")
		return
	if act.cost.has("money") and GameState.money < act.cost.money:
		GameState.log_message.emit("金錢不足！")
		return

	if act.cost.has("hp"): GameState.modify_stat("hp", -act.cost.hp)
	if act.cost.has("money"): GameState.modify_money(-act.cost.money)
	
	var san_cost = act.cost.get("san", 0)
	if act.cost.get("isWork", false) and GameState.time.hour >= GameConstants.overtime_start:
		san_cost = max(san_cost, 10) * 2
		GameState.log_message.emit("加班！壓力加倍！")
	
	if san_cost != 0: GameState.modify_stat("san", san_cost)
	
	if act.cost.has("time"): GameState.update_time(0, act.cost.time)
	
	_apply_action_effects(act)
	render_actions()

func _apply_action_effects(act):
	# Generic Stat/Attr Effects from CSV (deltas)
	if act.has("delta_stats"):
		for stat in act.delta_stats:
			if stat == "hp" or stat == "san" or stat == "libido": 
				GameState.modify_stat(stat, act.delta_stats[stat])
	
	if act.has("delta_attrs"):
		for attr in act.delta_attrs:
			if not GameState.attributes.has(attr): GameState.attributes[attr] = 0
			GameState.attributes[attr] += act.delta_attrs[attr]
			GameState.log_message.emit("%s %+d" % [attr.capitalize(), act.delta_attrs[attr]])

	# Special Logic Effect
	if act.get("effect"):
		act.effect.call()


func _on_breakpoint_toggle():
	GameState.is_breakpoint_active = not GameState.is_breakpoint_active
	GameState.log_message.emit("System Breakpoint: " + str(GameState.is_breakpoint_active))
	render_actions()
	_update_ui()

func change_location(new_loc):
	GameState.location = new_loc
	GameState.log_message.emit("移動至 " + get_location_name(new_loc))
	render_actions()
	_update_ui()
	_update_background()

func _update_background():
	var loc = GameState.location
	var hour = GameState.time.hour
	var is_night = hour >= 18 or hour < 6
	
	if loc == "home" or loc == "wakeup_mode":
		if is_night: bg_rect.texture = bg_images["home_night"]
		else: bg_rect.texture = bg_images["home_morning"]
	elif loc == "office" or loc == "project_board":
		if is_night: bg_rect.texture = bg_images["office_night"]
		else: bg_rect.texture = bg_images["office_morning"]
	elif loc == "bar":
		bg_rect.texture = bg_images["bar"]
	elif loc == "cvs":
		if is_night: bg_rect.texture = bg_images["cvs_night"]
		else: bg_rect.texture = bg_images["cvs_morning"]
	elif loc == "gym":
		if is_night: bg_rect.texture = bg_images["gym_night"]
		else: bg_rect.texture = bg_images["gym_morning"]
	elif loc == "temple":
		if is_night: bg_rect.texture = bg_images["temple_night"]
		else: bg_rect.texture = bg_images["temple_morning"]
	else:
		# Fallback to a default if missing
		bg_rect.texture = bg_images["office_morning"]


# --- Effect Functions ---
func _eff_spec():
	var progress = GameConstants.base_efficiency * 0.1
	GameState.project_progress += progress
	GameState.log_message.emit("專案進度 +%.0f" % progress)

func _eff_sleep():
	sleep_panel.visible = true
	# Set default next wake up time based on current? 
	# For now just let user pick.

func _on_sleep_confirm_pressed():
	sleep_panel.visible = false
	var target_hour = int(sleep_spin.value)
	
	var current_hour = GameState.time.hour
	var sleep_hours = 0
	if target_hour > current_hour:
		sleep_hours = target_hour - current_hour
	else:
		sleep_hours = (24 - current_hour) + target_hour
		
	var rec_pct = sleep_hours * GameConstants.hp_recovery_sleep
	var rec_val = floor(GameState.max_hp * rec_pct)
	
	# Advance time
	GameState.time.day += 1
	GameState.time.weekday += 1
	if GameState.time.weekday > 7: GameState.time.weekday = 1
	
	GameState.time.hour = target_hour
	GameState.time.minute = 0
	
	GameState.modify_stat("hp", rec_val)
	GameState.daily_reset()
	GameState.log_message.emit("睡眠結束 (共 %d 小時)，回復體力 %d" % [sleep_hours, rec_val])
	
	enter_wakeup_mode()

func _on_sleep_cancel_pressed():
	sleep_panel.visible = false

func enter_wakeup_mode():
	GameState.location = "wakeup_mode"
	
	actions_data["wakeup_mode"] = []
	
	actions_data["wakeup_mode"].append({
		"id": "stay_in_bed",
		"label": "賴床 (Stay in Bed)",
		"cost": {"time": 30},
		"effect": func(): _eff_stay_in_bed()
	})
	
	actions_data["wakeup_mode"].append({
		"id": "get_up",
		"label": "起床 (Get Up)",
		"cost": {},
		"effect": func(): change_location("home")
	})
	
	change_location("wakeup_mode")

func _eff_stay_in_bed():
	# Stay in bed effect: Recover 5 HP, 5 SAN, Cost 30m (handled by cost)
	GameState.modify_stat("hp", 5)
	GameState.modify_stat("san", -5) # Reduce stress
	GameState.log_message.emit("賴床... 真舒服 (HP+5, Stress-5)")
	# Re-render to update time
	render_actions()



func _eff_debug_bp():
	GameState.project_progress += GameConstants.base_efficiency * 5
	GameState.log_message.emit("時停趕工完成！")

func _npc_interact(char_id, aff_gain, stat_cost):
	if GameState.characters.has(char_id):
		GameState.characters[char_id].affection += aff_gain
		GameState.log_message.emit("與 %s 互動，好感度 +%d" % [
			GameState.characters[char_id].name, aff_gain])
	
	for stat in stat_cost:
		GameState.modify_stat(stat, stat_cost[stat])
	render_actions()
	_update_ui()

# --- CSV Loading ---
func setup_actions_from_csv():
	actions_data = {
		"office": [], "home": [], "bar": [], "gym": [], 
		"temple": [], "meis": [], "bear": [], "breakpoint": [],
		"cvs": [], "mall": [], "dept": [],
		"go_out_select": [], "npc_select": [], "wakeup_mode": [],
		"npc_interaction": []
	}
	
	var path = "res://data/act.csv"
	if not FileAccess.file_exists(path):
		print("act.csv not found at " + path)
		# Fallback for exported builds
		path = "user://GodotProject/data/act.csv"
		
	if not FileAccess.file_exists(path):
		print("act.csv not found at " + path)
		return
		
	print("Loading act.csv from: " + path)
	var file = FileAccess.open(path, FileAccess.READ)
	var headers = []
	
	var social_actions = {}
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2: continue
		
		# Detect Header
		if line[0] == "ID": 
			headers = line
			continue
		
		# Skip Separator/Header Lines
		if line[0].length() > 6 or line[1] == "":
			continue

		var act = parse_csv_row(line, headers)
		if act:
			# Project Actions Consolidation
			if act.id == "W01": # Spec -> Work Entry
				project_action_defs["spec"] = act.duplicate()
				act.label = "工作 (Project)"
				# act will continue to be added to office as entry point
			elif act.id == "W02": # Debug
				project_action_defs["debug"] = act
				continue # Skip adding to office list
			elif act.id == "W03": # Meeting
				project_action_defs["meeting"] = act
				continue # Skip adding to office list

			# Cache Social/Date/Sex actions
			if act.id.begins_with("S") or act.id.begins_with("R"):
				social_actions[act.id] = act
				continue

			var cat_map = {
				"Work": "office", "Slack": "office", 
				"Home": "home", "Bar": "bar", "Gym": "gym", 
				"Temple": "temple", "Mei's": "meis", "Bear": "bear",
				"Social": "office", 
				"WakeUp": "home", "Survival": "home"
			}
			# Manual overrides or mapping based on ID prefix
			var loc = "office"
			if act.id.begins_with("L"): loc = "home"
			elif act.id.begins_with("A"): loc = "home"
			elif act.id.begins_with("B") and not act.id.begins_with("BB"): loc = "bar"
			elif act.id.begins_with("G"): loc = "gym"
			elif act.id.begins_with("T"): loc = "temple"
			elif act.id.begins_with("M"): loc = "meis"
			elif act.id.begins_with("BB"): loc = "bear"
			elif act.id.begins_with("C"): loc = "cvs"
			elif act.id.begins_with("E"): loc = "mall"
			elif act.id.begins_with("D"): loc = "dept"
			elif act.id == "W05": # NPC Interaction
				act.effect = func(): change_location("npc_select")
				# Don't add to list yet, handled below
			elif cat_map.has(act.category): loc = cat_map[act.category]
			
			if actions_data.has(loc):
				# Check if Shop Item
				if act.id.begins_with("I"):
					loc = "cvs"
					if not actions_data.has("cvs"): actions_data["cvs"] = []

				if loc in ["cvs", "mall", "dept", "meis"] and act.category == "Consumable": 
					pass
					
				# Shop Items Logic
				if act.id.begins_with("C") or act.id.begins_with("E") or \
				act.id.begins_with("D") or act.id.begins_with("I"):
					var item_entry = {
						"name": act.label,
						"stats": act.delta_stats.duplicate(),
						"attrs": act.delta_attrs.duplicate()
					}
					for k in act.delta_attrs:
						item_entry.stats[k] = act.delta_attrs[k]
						
					GameState.item_db[act.id] = item_entry
					
					act.effect = func(): 
						GameState.add_item(act.id, 1)
					
					act.delta_stats = {}
					act.delta_attrs = {}

				actions_data[loc].append(act)

	# --- Navigation Logic ---
	
	# 1. Home -> Go Out
	add_nav_action("home", "open_go_out", "出門 (Go Out)", "go_out_select", 0)
	
	# 2. Map (Go Out Select)
	add_nav_action("go_out_select", "go_office", "上班 (Office)", "office", 30)
	add_nav_action("go_out_select", "go_bar", "酒吧 (Bar)", "bar", 30)
	add_nav_action("go_out_select", "go_gym", "健身房 (Gym)", "gym", 30)
	add_nav_action("go_out_select", "go_temple", "宮廟 (Temple)", "temple", 30)
	add_nav_action("go_out_select", "go_cvs", "便利超商 (CVS)", "cvs", 15)
	add_nav_action("go_out_select", "go_mall", "3C 商場 (Mall)", "mall", 30)
	add_nav_action("go_out_select", "go_dept", "百貨精品 (Dept)", "dept", 30)
	add_nav_action("go_out_select", "go_meis", "美姨豆漿 (Mei's)", "meis", 15)
	add_nav_action("go_out_select", "go_bear", "兼職外送 (Bear)", "bear", 15)
	
	# Map -> Home (Cost 30m)
	add_nav_action("go_out_select", "cancel_out", "回家 (Home)", "home", 30)

	# 3. Office -> Map (Off Work - Condition Fixed?)
	# Re-added check logic
	add_nav_action("office", "go_home", "下班 (Off Work)", "go_out_select", 0, 
		func(): return GameState.time.hour >= GameConstants.work_end_time)
	
	# Locations -> Go Out Select (Return to Map)
	for lid in ["bar", "gym", "temple", "meis", "bear", "cvs", "mall", "dept"]:
		add_nav_action(lid, "leave", "離開", "go_out_select", 15)

	# Breakpoint (Debug)
	actions_data["breakpoint"] = []
	actions_data["breakpoint"].append({
		"id": "bp_debug", 
		"label": "Debug (趕工)", 
		"cost": {"san": 30}, 
		"effect": _eff_debug_bp
	})

	# --- NPC Selection Menu ---
	# Level 1: Select Character
	add_npc_select_entry("junior", "學妹 (Junior)")
	add_npc_select_entry("pm", "PM (Project Manager)")
	add_npc_select_entry("peer", "隱藏千金 (Rich Girl)")
	
	add_nav_action("npc_select", "return_office", "返回辦公室", "office", 0)
	
	# Helper to build dynamic menus
	_build_social_menus(social_actions)

func parse_csv_row(line, _headers):
	# Headers structure based on observation (approx mapping by index if headers match)
	# ID, Category, Action Name, Duration_Min, HP, SAN, Libido, Money, 
	# Comm, Tech, Resilience, Charm, Logic
	
	var id = line[0]
	var cat = line[1]
	# Cost Map: HP, SAN, Libido, Money
	var cost = {}
	var act_name = line[2]
	var cost_time = parse_val(line[3])
	
	# ... (Stats parsing) ...
	var hp_val = parse_val(line[4])
	var san_val = parse_val(line[5])
	var lib_val = parse_val(line[6])
	var money_val = parse_val(line[7])
	
	var delta_stats = {}
	
	# Time
	if cost_time > 0: cost["time"] = cost_time
	
	# HP
	if hp_val < 0: cost["hp"] = -hp_val 
	elif hp_val > 0: delta_stats["hp"] = hp_val
	
	# Money
	if money_val < 0: cost["money"] = -money_val
	elif money_val > 0: delta_stats["money"] = money_val
	
	# SAN
	if san_val > 0: cost["san"] = san_val
	elif san_val < 0: delta_stats["san"] = san_val
	
	# Libido
	if lib_val != 0: delta_stats["libido"] = lib_val

	# Attributes
	var delta_attrs = {}
	if parse_val(line[8]) != 0: delta_attrs["comm"] = parse_val(line[8])
	if parse_val(line[9]) != 0: delta_attrs["tech"] = parse_val(line[9])
	if parse_val(line[10]) != 0: delta_attrs["res"] = parse_val(line[10])
	if parse_val(line[11]) != 0: delta_attrs["charm"] = parse_val(line[11])
	if parse_val(line[12]) != 0: delta_attrs["logic"] = parse_val(line[12])
	
	# Special Function Binding
	var effect_func = null
	if id == "W01": effect_func = _open_project_board
	elif id == "L07": effect_func = _eff_sleep 
	# Gym Max HP Effect
	elif id == "G01" or id == "G02":
		effect_func = func():
			GameState.max_hp += 10
			GameState.log_message.emit("體力上限提升！")

	return {
		"id": id,
		"label": act_name,
		"category": cat,
		"cost": cost,
		"delta_stats": delta_stats,
		"delta_attrs": delta_attrs,
		"effect": effect_func,
		"isWork": (cat == "Work")
	}

func parse_val(str_val):
	if str_val == null: return 0
	str_val = str_val.replace("%", "").strip_edges()
	if str_val == "": return 0
	return str_val.to_int()

func add_nav_action(loc_list, id, label, target, time, cond=null):
	if not actions_data.has(loc_list): actions_data[loc_list] = []
	var act = {
		"id": id, "label": label, 
		"cost": {"time": time}, 
		"effect": func(): change_location(target)
	}
	if cond: act["condition"] = cond
	if cond: act["condition"] = cond
	actions_data[loc_list].append(act)

# --- Inventory UI ---
func _on_backpack_btn_pressed():
	if inv_panel.visible:
		inv_panel.visible = false
	else:
		render_inventory()
		inv_panel.visible = true

func _on_inventory_close_pressed():
	inv_panel.visible = false

func render_inventory():
	for c in inv_grid.get_children():
		c.queue_free()
		
	for item_id in GameState.inventory:
		var qty = GameState.inventory[item_id]
		var item_name = GameState.get_item_name(item_id)
		
		var btn = Button.new()
		btn.text = "%s\nx%d" % [item_name, qty]
		btn.custom_minimum_size = Vector2(80, 80)
		btn.pressed.connect(_on_use_item.bind(item_id))
		inv_grid.add_child(btn)

func _on_use_item(item_id):
	GameState.use_item(item_id)
	render_inventory()
	_update_ui()

# --- Social Menu Helpers ---
var social_actions_ref = {}

func _build_social_menus(social_actions):
	self.social_actions_ref = social_actions

func add_npc_select_entry(char_id, label):
	var act = {
		"id": "sel_" + char_id,
		"label": label,
		"cost": {},
		"effect": func(): _open_char_interaction(char_id)
	}
	actions_data["npc_select"].append(act)

func _open_char_interaction(char_id):
	GameState.location = "npc_interaction"
	actions_data["npc_interaction"] = [] # Clear previous
	
	var char_name = GameState.characters[char_id].name
	var affection = GameState.characters[char_id].affection
	
	GameState.log_message.emit("想對 %s 做什麼呢? (好感: %d)" % [char_name, affection])
	
	# 1. Chat (S01) - Always available
	if social_actions_ref.has("S01"):
		var base = social_actions_ref["S01"]
		var act = base.duplicate()
		act.label = "純聊天 (Chat)"
		act.effect = func(): 
			_npc_interact(char_id, 2, {"comm": 1, "san": -2})
		actions_data["npc_interaction"].append(act)
		
	# 2. Treat Dinner (S02) - Affection >= 20
	if affection >= 20 and social_actions_ref.has("S02"):
		var base = social_actions_ref["S02"]
		var act = base.duplicate()
		act.label = "請客吃飯 (Dinner)"
		act.effect = func():
			_npc_interact(char_id, 10, {}) # +10 Affection
			GameState.log_message.emit("吃了一頓大餐！")
		actions_data["npc_interaction"].append(act)
		
	# 3. Take Home (R02) - Affection >= 100
	if affection >= 100 and social_actions_ref.has("R02"):
		var base = social_actions_ref["R02"]
		var act = base.duplicate()
		act.label = "帶回家 (Take Home)"
		act.effect = func():
			_npc_interact(char_id, 50, {}) 
			GameState.log_message.emit("...度過了一個美好的夜晚。")
			change_location("home") # Go home after?
		actions_data["npc_interaction"].append(act)

	# Return Button
	add_nav_action("npc_interaction", "back_npc", "返回 (Back)", "npc_select", 0)
	
	change_location("npc_interaction")

# --- Project Board Logic (Waterfall) ---
func _open_project_board():
	GameState.location = "project_board"
	actions_data["project_board"] = []
	
	# Targets
	var target_per_stage = GameConstants.project_target / 3.0 # Approx 33k each
	
	# 1. Meeting (W03)
	if project_action_defs.has("meeting"):
		var base = project_action_defs["meeting"]
		var act = base.duplicate()
		var meet_pct = (GameState.prog_meeting / target_per_stage) * 100.0
		
		# Update Label with Progress
		act.label = "%s\n%.1f%%" % [base.label, meet_pct]
		
		# Effect: Work on Meeting
		act.effect = func(): _do_project_work("meeting", target_per_stage)
		
		# Add to list
		actions_data["project_board"].append(act)
	
	# 2. Spec (W01) - Cap at Meeting %
	if project_action_defs.has("spec"):
		var base = project_action_defs["spec"]
		var act = base.duplicate()
		var spec_pct = (GameState.prog_spec / target_per_stage) * 100.0
		var meet_pct = (GameState.prog_meeting / target_per_stage) * 100.0
		
		act.label = "%s\n%.1f%% (Max: %.1f%%)" % [base.label, spec_pct, meet_pct]
		act.effect = func(): _do_project_work("spec", target_per_stage, meet_pct)
		
		actions_data["project_board"].append(act)
	
	# 3. Debug (W02) - Cap at Spec %
	if project_action_defs.has("debug"):
		var base = project_action_defs["debug"]
		var act = base.duplicate()
		var test_pct = (GameState.prog_test / target_per_stage) * 100.0
		var spec_pct = (GameState.prog_spec / target_per_stage) * 100.0
		
		act.label = "%s\n%.1f%% (Max: %.1f%%)" % [base.label, test_pct, spec_pct]
		act.effect = func(): _do_project_work("test", target_per_stage, spec_pct)
		
		actions_data["project_board"].append(act)

	# Back
	add_nav_action("project_board", "back_office", "返回辦公室", "office", 0)
	
	change_location("project_board")

func _do_project_work(type, target, cap_pct = 100.0):
	var progress = GameConstants.base_efficiency # 1000
	var current_val = 0.0
	
	if type == "meeting": current_val = GameState.prog_meeting
	elif type == "spec": current_val = GameState.prog_spec
	elif type == "test": current_val = GameState.prog_test
	
	var current_pct = (current_val / target) * 100.0
	
	if current_pct >= cap_pct and cap_pct < 100.0:
		GameState.log_message.emit("前置工作未完成，無法繼續推進！")
		return
	if current_pct >= 100.0:
		GameState.log_message.emit("此階段已完成！")
		return

	# Apply Progress
	if type == "meeting": GameState.prog_meeting += progress
	elif type == "spec": GameState.prog_spec += progress
	elif type == "test": GameState.prog_test += progress
	
	GameState.log_message.emit("專案進度推進... (+%.0f)" % progress)
	_open_project_board() # Refresh UI
	_update_ui()
