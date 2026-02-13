extends Node

signal stats_changed
signal time_changed
signal log_message(msg)

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
	modify_money(-1000)
	time.day += 1
	time.hour = 12
	hp = 50
	time_changed.emit()

func trigger_breakdown():
	log_message.emit("精神崩潰 (SAN 100)！強制休息...")
	san = 80
	stats_changed.emit()
