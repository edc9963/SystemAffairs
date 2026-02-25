extends Node

signal stats_changed
signal time_changed
signal log_message(msg)
signal player_fainted

var skip_main_menu: bool = false

var hp: float = GameConstants.max_hp
var max_hp: float = GameConstants.max_hp
var san: float = 0.0
var max_san: float = GameConstants.max_san
var libido: float = 0.0
var max_libido: float = GameConstants.max_libido

var money: int = GameConstants.starting_savings

var attributes = {
	"comm": 10,
	"tech": 10,
	"res": 10,
	"charm": 10,
	"logic": 10
}

var time = {
	"day": 1,
	"hour": 7,
	"minute": 0,
	"weekday": 1 # 1=Mon, 7=Sun
}

var location = "home"
var is_breakpoint_active: bool = false
var project_progress = 0.0 # Deprecated, keep for compat if needed, or remove?
# Waterfall Progress
var prog_meeting = 0.0
var prog_spec = 0.0
var prog_test = 0.0

var characters = {
	"junior": {"name": "學妹", "affection": 10, "depravity": 0},
	"pm": {"name": "PM", "affection": 5, "depravity": 0},
	"peer": {"name": "隱藏千金", "affection": 0, "depravity": 0}
}

var inventory = {} # { item_id: quantity }
var item_db = {} # { item_id: { name, cost_stats, effect_stats, desc } }

func add_item(item_id: String, amount: int = 1):
	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	log_message.emit("獲得物品: " + get_item_name(item_id) + " x" + str(amount))
	stats_changed.emit()

func get_item_name(item_id):
	if item_db.has(item_id):
		return item_db[item_id].name
	return item_id

func use_item(item_id):
	if not inventory.has(item_id) or inventory[item_id] <= 0:
		return
	
	var item = item_db.get(item_id)
	if not item: return

	# Apply Effects
	if item.has("stats"):
		for stat in item.stats:
			if attributes.has(stat):
				attributes[stat] += item.stats[stat]
				log_message.emit(stat.capitalize() + " %+d" % item.stats[stat])
			elif stat == "money":
				modify_money(int(item.stats[stat]))
			else:
				modify_stat(stat, item.stats[stat])
	
	# Consume
	add_item(item_id, -1)
	log_message.emit("使用了 " + item.name)

func _ready():
	log_message.emit("系統啟動... V1.04 Online.")

func update_time(hours: int, minutes: int = 0):
	if is_breakpoint_active:
		return

	# Overtime Check (Simplified)
	if time.hour >= GameConstants.overtime_start:
		pass

	time.minute += minutes
	time.hour += hours
	
	if time.minute >= 60:
		time.hour += floor(time.minute / 60)
		time.minute = time.minute % 60
	
	if time.hour >= 24:
		time.day += 1
		time.weekday += 1
		if time.weekday > 7:
			time.weekday = 1
		time.hour = time.hour % 24
		daily_reset()
	
	time_changed.emit()

func daily_reset():
	modify_stat("libido", GameConstants.libido_daily_growth)
	
	if time.day == 30:
		modify_money(-GameConstants.fixed_cost_rent)
		log_message.emit("扣除房租 $" + str(GameConstants.fixed_cost_rent))
	
	log_message.emit("Day " + str(time.day) + " 開始。")
	
	var slm = get_node_or_null("/root/SaveLoadManager")
	if slm:
		slm.save_game("auto")

func modify_money(amount: int):
	money += amount
	stats_changed.emit()

func modify_stat(stat_name: String, value: float):
	match stat_name:
		"hp":
			hp = clamp(hp + value, 0, max_hp)
			if hp <= 0:
				trigger_faint()
		"san":
			san = clamp(san + value, 0, max_san)
			if san >= max_san:
				trigger_breakdown()
		"libido":
			libido = clamp(libido + value, 0, max_libido)
	
	stats_changed.emit()

func trigger_faint():
	log_message.emit("體力歸零！昏倒送醫...")
	player_fainted.emit()

func trigger_breakdown():
	log_message.emit("精神崩潰 (SAN 100)！強制休息...")
	san = 80
	stats_changed.emit()

func reset_to_default():
	hp = GameConstants.max_hp
	max_hp = GameConstants.max_hp
	san = 0.0
	max_san = GameConstants.max_san
	libido = 0.0
	max_libido = GameConstants.max_libido
	money = GameConstants.starting_savings
	
	attributes = {
		"comm": 10, "tech": 10, "res": 10, "charm": 10, "logic": 10
	}
	time = {
		"day": 1, "hour": 7, "minute": 0, "weekday": 1
	}
	location = "home"
	is_breakpoint_active = false
	project_progress = 0.0
	prog_meeting = 0.0
	prog_spec = 0.0
	prog_test = 0.0
	
	characters = {
		"junior": {"name": "學妹", "affection": 10, "depravity": 0},
		"pm": {"name": "PM", "affection": 5, "depravity": 0},
		"peer": {"name": "隱藏千金", "affection": 0, "depravity": 0}
	}
	inventory = {}
	
	stats_changed.emit()
	time_changed.emit()

func get_save_data() -> Dictionary:
	return {
		"hp": hp,
		"san": san,
		"libido": libido,
		"money": money,
		"attributes": attributes.duplicate(true),
		"time": time.duplicate(true),
		"location": location,
		"is_breakpoint_active": is_breakpoint_active,
		"prog_meeting": prog_meeting,
		"prog_spec": prog_spec,
		"prog_test": prog_test,
		"characters": characters.duplicate(true),
		"inventory": inventory.duplicate(true)
	}

func load_save_data(data: Dictionary):
	if data.has("hp"): hp = data["hp"]
	if data.has("san"): san = data["san"]
	if data.has("libido"): libido = data["libido"]
	if data.has("money"): money = data["money"]
	if data.has("attributes"): attributes = data["attributes"]
	if data.has("time"): time = data["time"]
	if data.has("location"): location = data["location"]
	if data.has("is_breakpoint_active"): is_breakpoint_active = data["is_breakpoint_active"]
	if data.has("prog_meeting"): prog_meeting = data["prog_meeting"]
	if data.has("prog_spec"): prog_spec = data["prog_spec"]
	if data.has("prog_test"): prog_test = data["prog_test"]
	if data.has("characters"): characters = data["characters"]
	if data.has("inventory"): inventory = data["inventory"]
	
	hp = clamp(hp, 0, max_hp)
	san = clamp(san, 0, max_san)
	libido = clamp(libido, 0, max_libido)
	
	stats_changed.emit()
	time_changed.emit()
