extends Node

# Time & Cycle
var TOTAL_DAYS = 30
var WORK_START_TIME = 9
var WORK_END_TIME = 18
var OVERTIME_START = 19
var HP_RECOVERY_SLEEP = 0.125 # 12.5%

# Stats Limits
var MAX_HP = 100
var MAX_SAN = 100
var SAN_WARNING = 80
var MAX_LIBIDO = 100
var LIBIDO_PENALTY = 80
var LIBIDO_SAGE = 20
var LIBIDO_DAILY_GROWTH = 15

# Economy
var BASE_SALARY = 45000
var STARTING_SAVINGS = 50000
var FIXED_COST_RENT = 12000
var CREDIT_LIMIT_RATIO = 1.5
var BONUS_PER_POINT = 10

# Project
var PROJECT_TARGET = 100000
var MIN_PASS = 60000
var BASE_EFFICIENCY = 1000 # pts/hr

func _ready():
	load_base_states()

func load_base_states():
	var path = "res://BaseStates.csv"
	if not FileAccess.file_exists(path):
		path = "user://GodotProject/BaseStates.csv"
	
	if not FileAccess.file_exists(path):
		print("BaseStates.csv not found!")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2: continue
		
		var key = line[0].strip_edges()
		var val_str = line[1].replace(",", "").replace("\"", "").strip_edges()
		
		# Skip headers or comments
		if key == "" or key.begins_with("變數") or key.begins_with("時間"):
			continue
			
		_set_config_value(key, val_str)

func _set_config_value(key, val_str):
	var val = 0.0
	if "." in val_str or "%" in val_str:
		val_str = val_str.replace("%", "")
		val = val_str.to_float()
		if "%" in line_content(key): # Heuristic if original had %, divide by 100? 
			# Actually CSV value is "12.50%", so to_float makes it 12.5. 
			# Logic needs 0.125.
			if key == "HP_RECOVERY_SLEEP": val /= 100.0
	else:
		val = val_str.to_int()

	match key:
		"TOTAL_DAYS": TOTAL_DAYS = val
		"WORK_START_TIME": WORK_START_TIME = _parse_time(val_str)
		"WORK_END_TIME": WORK_END_TIME = _parse_time(val_str)
		"OVERTIME_START": OVERTIME_START = _parse_time(val_str)
		"HP_RECOVERY_SLEEP": HP_RECOVERY_SLEEP = val # Handled above
		"MAX_HP": MAX_HP = val
		"MAX_SAN": MAX_SAN = val
		"SAN_WARNING": SAN_WARNING = val
		"MAX_LIBIDO": MAX_LIBIDO = val
		"LIBIDO_PENALTY_THRESHOLD": LIBIDO_PENALTY = val
		"LIBIDO_SAGE_THRESHOLD": LIBIDO_SAGE = val
		"LIBIDO_DAILY_GROWTH": LIBIDO_DAILY_GROWTH = val
		"BASE_SALARY": BASE_SALARY = val
		"STARTING_SAVINGS": STARTING_SAVINGS = val
		"FIXED_COST_RENT": FIXED_COST_RENT = val
		"CREDIT_LIMIT_MULTIPLIER": CREDIT_LIMIT_RATIO = val
		"BONUS_PER_POINT": BONUS_PER_POINT = val
		"PROJECT_TARGET_POINTS": PROJECT_TARGET = val
		"MIN_PASS_POINTS": MIN_PASS = val
		"BASE_WORK_EFFICIENCY": BASE_EFFICIENCY = val

func _parse_time(str_val):
	# Handle "9:00" -> 9
	if ":" in str_val:
		var parts = str_val.split(":")
		return parts[0].to_int()
	return str_val.to_int()

func line_content(_key):
	return "" # Placeholder
