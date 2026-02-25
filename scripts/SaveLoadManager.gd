extends Node

const SAVE_DIR = "user://"
const SAVE_FILE_FORMAT = "savegame_%s.json"

func _ready():
	print("SaveLoadManager initialized.")

func get_save_path(slot_id: String) -> String:
	return SAVE_DIR + SAVE_FILE_FORMAT % slot_id

func save_game(slot_id: String):
	var data = GameState.get_save_data()
	var save_dict = {
		"timestamp": Time.get_unix_time_from_system(),
		"datetime": Time.get_datetime_string_from_system(false, true),
		"day": GameState.time.day,
		"money": GameState.money,
		"game_data": data
	}
	
	var file = FileAccess.open(get_save_path(slot_id), FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict, "\t")
		file.store_string(json_string)
		file.close()
		print("Game saved to slot: ", slot_id)
		GameState.log_message.emit("遊戲已存檔 (" + slot_id + ")")
	else:
		push_error("Failed to save game to slot: " + slot_id)

func load_game(slot_id: String) -> bool:
	var path = get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		GameState.log_message.emit("找不到存檔 (" + slot_id + ")")
		return false
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var save_dict = json.data
			if save_dict.has("game_data"):
				GameState.load_save_data(save_dict["game_data"])
				print("Game loaded from slot: ", slot_id)
				GameState.log_message.emit("遊戲已讀取 (" + slot_id + ")")
				return true
			push_error("Save file missing game_data.")
		else:
			push_error(
				"JSON Parse Error: ", json.get_error_message(), 
				" in ", json_string, " at line ", json.get_error_line()
			)
	return false

func delete_game(slot_id: String) -> bool:
	var path = get_save_path(slot_id)
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err == OK:
			print("Deleted save: ", slot_id)
			GameState.log_message.emit("存檔已刪除 (" + slot_id + ")")
			return true
		push_error("Failed to delete save slot: ", slot_id, " Error: ", err)
	return false

func get_save_info(slot_id: String) -> Dictionary:
	var path = get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return {"exists": false}
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var dict = json.data
			return {
				"exists": true,
				"datetime": dict.get("datetime", "Unknown time"),
				"day": dict.get("day", 0),
				"money": dict.get("money", 0)
			}
	return {"exists": false}
