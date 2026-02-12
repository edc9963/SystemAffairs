extends Control

# UI References
@onready var action_container = $HBoxContainer/Main/ActionGrid
@onready var log_label = $HBoxContainer/LogPanel/RichTextLabel
@onready var location_label = $HBoxContainer/Main/Header/LocationLabel
@onready var time_label = $HBoxContainer/Main/Header/TimeLabel
@onready var breakpoint_btn = $HBoxContainer/Main/Header/BreakpointBtn

# Stats References
@onready var money_label = $HBoxContainer/Sidebar/StatsContainer/MoneyLabel
@onready var hp_bar = $HBoxContainer/Sidebar/StatsContainer/HPBar
@onready var san_bar = $HBoxContainer/Sidebar/StatsContainer/SanBar
@onready var libido_bar = $HBoxContainer/Sidebar/StatsContainer/LibidoBar
@onready var project_bar = $HBoxContainer/Sidebar/ProjectBar
@onready var project_label = $HBoxContainer/Sidebar/ProjectLabel

@onready var attr_labels = {
	"comm": $HBoxContainer/Sidebar/AttrContainer/CommLabel,
	"tech": $HBoxContainer/Sidebar/AttrContainer/TechLabel,
	"charm": $HBoxContainer/Sidebar/AttrContainer/CharmLabel,
	"logic": $HBoxContainer/Sidebar/AttrContainer/LogicLabel,
	"res": $HBoxContainer/Sidebar/AttrContainer/ResLabel
}

# Affection References
@onready var aff_labels = {
	"junior": $HBoxContainer/Sidebar/AffectionContainer/JuniorLabel,
	"pm": $HBoxContainer/Sidebar/AffectionContainer/PMLabel,
	"peer": $HBoxContainer/Sidebar/AffectionContainer/PeerLabel
}

# Inventory References
@onready var backpack_btn = $HBoxContainer/Sidebar/BackpackBtn
@onready var inv_panel = $InventoryPanel
@onready var inv_grid = $InventoryPanel/VBox/Scroll/ItemGrid
@onready var inv_close_btn = $InventoryPanel/VBox/Header/CloseBtn

var actions_data = {}

func _ready():
	GameState.log_message.connect(_on_log_message)
	GameState.time_changed.connect(_update_ui)
	GameState.stats_changed.connect(_update_ui)
	
	setup_actions_from_csv()
	render_actions()
	_update_ui()
	
	if backpack_btn: backpack_btn.pressed.connect(_on_backpack_btn_pressed)
	if inv_close_btn: inv_close_btn.pressed.connect(_on_inventory_close_pressed)

func _on_log_message(msg):
	log_label.append_text("> " + msg + "\n")

func _update_ui():
	# Header
	time_label.text = "Day %d %02d:%02d" % [GameState.time.day, GameState.time.hour, GameState.time.minute]
	location_label.text = get_location_name(GameState.location)
	
	if GameState.is_breakpoint_active:
		breakpoint_btn.text = "RESUME TIME"
		modulate = Color(0.5, 0.5, 0.5)
	else:
		breakpoint_btn.text = "SYSTEM BREAKPOINT"
		modulate = Color(1, 1, 1)

	# Stats
	money_label.text = "Money: $%d" % GameState.money
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.hp
	
	san_bar.max_value = GameState.max_san
	san_bar.value = GameState.san
	
	libido_bar.max_value = GameState.max_libido
	libido_bar.value = GameState.libido
	
	project_bar.max_value = GameConstants.PROJECT_TARGET
	project_bar.value = GameState.project_progress
	project_label.text = "Project: %.1f%%" % ((GameState.project_progress / GameConstants.PROJECT_TARGET) * 100.0)

	# Attributes
	for key in attr_labels:
		var val = GameState.attributes.get(key, 0)
		attr_labels[key].text = "%s: %d" % [key.capitalize(), val]

	# Affection
	for key in aff_labels:
		if GameState.characters.has(key):
			var char_data = GameState.characters[key]
			aff_labels[key].text = "%s: %d" % [char_data.name, char_data.affection]

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
		"go_out_select": "外出 (Going Out)"
	}
	return map.get(loc_id, loc_id)

func render_actions():
	for child in action_container.get_children():
		child.queue_free()
	
	var current_list = []
	if GameState.is_breakpoint_active:
		current_list = actions_data.get("breakpoint", [])
	else:
		current_list = actions_data.get(GameState.location, [])
	
	for act in current_list:
		if act.has("condition") and not act.condition.call():
			continue
			
		var btn = Button.new()
		var cost_str = ""
		if act.cost.has("time"): cost_str += "%dm " % act.cost.time
		if act.cost.has("hp"): cost_str += "HP-%d " % act.cost.hp
		if act.cost.has("money"): cost_str += "$%d " % act.cost.money
		
		btn.text = "%s\n(%s)" % [act.label, cost_str]
		btn.custom_minimum_size = Vector2(120, 80)
		btn.pressed.connect(_on_action_pressed.bind(act))
		action_container.add_child(btn)

func _on_action_pressed(act):
	if act.cost.has("hp") and GameState.hp < act.cost.hp:
		GameState.log_message.emit("體力不足！")
		return
	if act.cost.has("money") and GameState.money < act.cost.money:
		GameState.log_message.emit("金錢不足！")
		return

	if act.cost.has("hp"): GameState.modify_stat("hp", -act.cost.hp)
	if act.cost.has("money"): GameState.modify_money(-act.cost.money)
	
	var san_cost = act.cost.get("san", 0)
	if act.cost.get("isWork", false) and GameState.time.hour >= GameConstants.OVERTIME_START:
		san_cost = max(san_cost, 10) * 2
		GameState.log_message.emit("加班！壓力加倍！")
	
	if san_cost != 0: GameState.modify_stat("san", san_cost)
	
	if act.cost.has("time"): GameState.update_time(0, act.cost.time)
	
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
	
	render_actions()

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

# --- Effect Functions ---
func _eff_spec():
	var progress = GameConstants.BASE_EFFICIENCY * 0.1
	GameState.project_progress += progress
	GameState.log_message.emit("專案進度 +%.0f" % progress)

func _eff_sleep():
	var current_hour = GameState.time.hour
	var sleep_hours = 0
	if current_hour < 7: sleep_hours = 7 - current_hour
	else: sleep_hours = (24 - current_hour) + 7
	
	var rec_pct = sleep_hours * GameConstants.HP_RECOVERY_SLEEP
	var rec_val = floor(GameState.max_hp * rec_pct)
	
	GameState.time.day += 1
	GameState.time.hour = 7
	GameState.time.minute = 0
	GameState.modify_stat("hp", rec_val)
	GameState.daily_reset()
	GameState.log_message.emit("睡眠結束，回復體力 " + str(rec_val))

func _eff_debug_bp():
	GameState.project_progress += GameConstants.BASE_EFFICIENCY * 5
	GameState.log_message.emit("時停趕工完成！")

func _npc_interact(char_id, aff_gain, stat_cost):
	if GameState.characters.has(char_id):
		GameState.characters[char_id].affection += aff_gain
		GameState.log_message.emit("與 %s 互動，好感度 +%d" % [GameState.characters[char_id].name, aff_gain])
	
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
		"go_out_select": [], "npc_select": []
	}
	
	var path = "res://act.csv"
	if not FileAccess.file_exists(path):
		print("act.csv not found at " + path)
		# Fallback to user:// just in case (for exported builds context)
		path = "user://GodotProject/act.csv"
		
	if not FileAccess.file_exists(path):
		print("act.csv not found at " + path)
		return
		
	print("Loading act.csv from: " + path)
	var file = FileAccess.open(path, FileAccess.READ)
	var headers = []
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2: continue
		
		# Detect Header
		if line[0] == "ID": 
			headers = line
			continue
		
		# Skip non-data
		if line[0] == "" or line[0].begins_with("早晨") or line[0] == "道具(消耗品) 效果":
			continue

		var act = parse_csv_row(line, headers)
		if act:
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
				# Force I-series (Consumables) to CVS
				if act.id.begins_with("I"):
					loc = "cvs"
					# Create CVS list if not exists (should be initialized though)
					if not actions_data.has("cvs"): actions_data["cvs"] = []
					# Avoid adding to original loc if it was different
					if actions_data.has(loc):
						pass 

				if loc in ["cvs", "mall", "dept", "meis"] and act.category == "Consumable": 
					pass
					
				# Special handling for Shop Items to go to Inventory
				# I series are Consumables. E, D series are items.
				# If it has a cost and stats, but is sold in a shop, it might be an item.
				# But wait, original code applied stats directly. 
				# New Logic: If it is I, E, D, C series?
				# C(CVS), E(Mall), D(Dept).
				if act.id.begins_with("C") or act.id.begins_with("E") or act.id.begins_with("D") or act.id.begins_with("I"):
					# It's an item!
					# Add to GameState.item_db
					# Stats are in act.delta_stats and act.delta_attrs
					var item_entry = {
						"name": act.label,
						"stats": act.delta_stats.duplicate(),
						"attrs": act.delta_attrs.duplicate()
					}
					# Merge attrs into stats for uniform handling in use_item? 
					# use_item logic needs updates to handle attributes too.
					for k in act.delta_attrs:
						item_entry.stats[k] = act.delta_attrs[k]
						
					GameState.item_db[act.id] = item_entry
					
					# Transform Action to "Buy"
					act.effect = func(): 
						GameState.add_item(act.id, 1)
					
					# Remove direct stat application from action (handled by effect -> add_item -> use_item)
					act.delta_stats = {}
					act.delta_attrs = {}
					# Cost remains (Money/Time)

				actions_data[loc].append(act)

	# Navigation Logic: "Go Out" Submenu
	# 1. Add "Go Out" button to Home
	add_nav_action("home", "open_go_out", "出門 (Go Out)", "go_out_select", 0)
	
	# 2. Add Destinations to "go_out_select"
	add_nav_action("go_out_select", "go_office", "上班 (Office)", "office", 30)
	add_nav_action("go_out_select", "go_bar", "酒吧 (Bar)", "bar", 30)
	add_nav_action("go_out_select", "go_gym", "健身房 (Gym)", "gym", 30)
	add_nav_action("go_out_select", "go_temple", "宮廟 (Temple)", "temple", 30)
	add_nav_action("go_out_select", "go_cvs", "便利超商 (CVS)", "cvs", 15)
	add_nav_action("go_out_select", "go_mall", "3C 商場 (Mall)", "mall", 30)
	add_nav_action("go_out_select", "go_dept", "百貨精品 (Dept)", "dept", 30)
	add_nav_action("go_out_select", "go_meis", "美姨豆漿 (Mei's)", "meis", 15)
	add_nav_action("go_out_select", "go_bear", "兼職外送 (Bear)", "bear", 15)
	
	# 3. Add Back button to "go_out_select"
	add_nav_action("go_out_select", "cancel_out", "返回 (Cancel)", "home", 0)

	# Office -> Home (Commute)
	add_nav_action("office", "go_home", "下班 (Home)", "home", 30, func(): return GameState.time.hour >= GameConstants.WORK_END_TIME)
	
	# Locations -> Go Out Select (Return to Map)
	add_nav_action("bar", "leave", "離開", "go_out_select", 15)
	add_nav_action("gym", "leave", "離開", "go_out_select", 15)
	add_nav_action("temple", "leave", "離開", "go_out_select", 15)
	add_nav_action("meis", "leave", "離開", "go_out_select", 15)
	add_nav_action("bear", "leave", "離開", "go_out_select", 15)
	add_nav_action("cvs", "leave", "離開", "go_out_select", 15)
	add_nav_action("mall", "leave", "離開", "go_out_select", 15)
	add_nav_action("dept", "leave", "離開", "go_out_select", 15)

	# Breakpoint debug
	actions_data["breakpoint"].append({
		"id": "bp_debug", "label": "Debug (趕工)", "cost": {"san": 30}, "effect": _eff_debug_bp
	})

	# NPC Selection Menu
	add_nav_action("npc_select", "chat_junior", "找學妹聊天\n(+好感度)", "npc_select", 15, null)
	actions_data["npc_select"].back().effect = func(): 
		_npc_interact("junior", 2, {"comm": 1, "san": -2})
	
	add_nav_action("npc_select", "chat_pm", "找 PM 聊天\n(+好感度)", "npc_select", 15, null)
	actions_data["npc_select"].back().effect = func(): 
		_npc_interact("pm", 2, {"comm": 1, "san": 5})

	add_nav_action("npc_select", "chat_peer", "找隱藏千金聊天\n(+好感度)", "npc_select", 15, null)
	actions_data["npc_select"].back().effect = func(): 
		_npc_interact("peer", 2, {"logic": 1})

	add_nav_action("npc_select", "return_office", "返回辦公室", "office", 0)

func parse_csv_row(line, _headers):
	# Headers structure based on observation (approx mapping by index if headers match)
	# ID, Category, Action Name, Duration_Min, HP, SAN, Libido, Money, Comm, Tech, Resilience, Charm, Logic
	
	var id = line[0]
	var cat = line[1]
	var act_name = line[2]
	var cost_time = line[3].to_int()
	
	# Stats (Negative = Cost, Positive = Gain?)
	# Logic: In perform_action, act.cost.hp is reduced. 
	# CSV: W01 HP = -15. Meaning Cost 15.
	# So if val < 0: cost = -val.
	# If val > 0: gain (effect).
	
	var hp_val = parse_val(line[4])
	var san_val = parse_val(line[5])
	var lib_val = parse_val(line[6])
	var money_val = parse_val(line[7])
	
	var cost = {}
	var delta_stats = {}
	
	# Time
	if cost_time > 0: cost["time"] = cost_time
	
	# HP
	if hp_val < 0: cost["hp"] = -hp_val # Cost 15
	elif hp_val > 0: delta_stats["hp"] = hp_val
	
	# Money
	if money_val < 0: cost["money"] = -money_val
	elif money_val > 0: delta_stats["money"] = money_val
	
	# SAN (Positive usually cost/stress)
	# W01 SAN=10 (Gain Stress). In perform_action: san_cost = act.cost.san. 
	# We treat positive SAN in CSV as 'Cost' (Stress Increase).
	# Negative SAN in CSV (e.g. -10) is Stress Relief.
	if san_val > 0: cost["san"] = san_val
	elif san_val < 0: delta_stats["san"] = san_val
	
	# Libido
	if lib_val != 0: delta_stats["libido"] = lib_val

	# Attributes
	# Comm(8), Tech(9), Res(10), Charm(11), Logic(12)
	var delta_attrs = {}
	if parse_val(line[8]) != 0: delta_attrs["comm"] = parse_val(line[8])
	if parse_val(line[9]) != 0: delta_attrs["tech"] = parse_val(line[9])
	if parse_val(line[10]) != 0: delta_attrs["res"] = parse_val(line[10])
	if parse_val(line[11]) != 0: delta_attrs["charm"] = parse_val(line[11])
	if parse_val(line[12]) != 0: delta_attrs["logic"] = parse_val(line[12])
	
	# Special Function Binding
	var effect_func = null
	if id == "W01": effect_func = _eff_spec
	elif id == "sleep": effect_func = _eff_sleep # A01/L07?
	# Map sleep ID if found
	if "WakeUp" == cat: 
		# Maybe A01 is strict Alarm? L07 is "Sleep"?
		pass

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
