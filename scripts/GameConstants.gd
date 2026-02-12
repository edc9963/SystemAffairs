extends Node

# Time & Cycle
var total_days = 30
var work_start_time = 9
var work_end_time = 18
var overtime_start = 19
var hp_recovery_sleep = 0.125 # 12.5%

# Stats Limits
var max_hp = 100
var max_san = 100
var san_warning = 80
var max_libido = 100
var libido_penalty = 80
var libido_sage = 20
var libido_daily_growth = 15

# Economy
var base_salary = 45000
var starting_savings = 50000
var fixed_cost_rent = 12000
var credit_limit_ratio = 1.5
var bonus_per_point = 10

# Project
var project_target = 100000
var min_pass = 60000
var base_efficiency = 1000 # pts/hr

func _ready():
	load_base_states()

func load_base_states():
	var path = "res://data/BaseStates.csv"
	if not FileAccess.file_exists(path):
		path = "user://GodotProject/data/BaseStates.csv"
	
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
		"TOTAL_DAYS": total_days = val
		"WORK_START_TIME": work_start_time = _parse_time(val_str)
		"WORK_END_TIME": work_end_time = _parse_time(val_str)
		"OVERTIME_START": overtime_start = _parse_time(val_str)
		"HP_RECOVERY_SLEEP": hp_recovery_sleep = val # Handled above
		"MAX_HP": max_hp = val
		"MAX_SAN": max_san = val
		"SAN_WARNING": san_warning = val
		"MAX_LIBIDO": max_libido = val
		"LIBIDO_PENALTY_THRESHOLD": libido_penalty = val
		"LIBIDO_SAGE_THRESHOLD": libido_sage = val
		"LIBIDO_DAILY_GROWTH": libido_daily_growth = val
		"BASE_SALARY": base_salary = val
		"STARTING_SAVINGS": starting_savings = val
		"FIXED_COST_RENT": fixed_cost_rent = val
		"CREDIT_LIMIT_MULTIPLIER": credit_limit_ratio = val
		"BONUS_PER_POINT": bonus_per_point = val
		"PROJECT_TARGET_POINTS": project_target = val
		"MIN_PASS_POINTS": min_pass = val
		"BASE_WORK_EFFICIENCY": base_efficiency = val

func _parse_time(str_val):
	# Handle "9:00" -> 9
	if ":" in str_val:
		var parts = str_val.split(":")
		return parts[0].to_int()
	return str_val.to_int()

func line_content(_key):
	return "" # Placeholder
