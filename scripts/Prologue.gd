extends Control

@onready var bg = $Background
@onready var speaker_label = $DialoguePanel/SpeakerLabel
@onready var text_label = $DialoguePanel/TextLabel
@onready var choices_container = $ChoicesContainer
@onready var color_rect_flash = $ColorRectFlash

var current_scene_index = 0
var current_dialogue_index = 0

# Dialogue Data Structure
# {
#   "bg_color": Color,
#   "dialogue": [
#     {"speaker": "Name", "text": "Content", "effect": "flash_red", "is_thought": true},
#     ...
#   ],
#   "choices": [
#     {"text": "Choice 1", "next_scene": 1},
#     ...
#   ]
# }

var scenes = [
	{ # Scene 0: 頻臨崩潰的邊緣
		"bg_color": Color(0.1, 0.1, 0.1), # Dark office
		"dialogue": [
			{"speaker": "系統提示", "text": "警告：體力 (HP) 剩餘 5%。壓力 (SAN) 達到 92%。若體力歸零將強制觸發【過勞昏倒】。", "system": true},
			{"speaker": "誠一", "text": "凌晨三點半。距離三十歲生日還有兩天。", "is_thought": true},
			{"speaker": "誠一", "text": "我叫誠一，在『鑫創系統整合』當了五年的全端工程師。", "is_thought": true},
			{"speaker": "誠一", "text": "這五年來，我的薪水漲幅跟爬行動物差不多，但髮際線退後的速度倒是突破了音障。", "is_thought": true},
			{"speaker": "", "text": "(畫面閃爍紅光，模擬暈眩感)", "effect": "flash_red"},
			{"speaker": "誠一", "text": "Legacy Code (歷史遺留代碼) 就像是一座隨時會爆發的活火山。而我，就是那個每天拿著膠帶試圖把火山口封起來的白痴。", "is_thought": true},
			{"speaker": "誠一", "text": "不行了……再這樣下去，專案還沒上線，我就先登出了。", "is_thought": true}
		],
		"choices": [
			{"text": "回家睡覺（扣除通勤費 $100，專案進度停滯）", "next_scene": "go_home_fail"},
			{"text": "去附近的「九天玄機廟」拜拜（消耗體力 2，或許能改運？）", "next_scene": 1}
		]
	},
	{ # Scene 1: 科學與玄學的交會
		"bg_color": Color(0.15, 0.1, 0.2), # Temple night
		"dialogue": [
			{"speaker": "誠一", "text": "（搖搖晃晃地走到供桌前，從塑膠袋裡拿出一包綠色乖乖）\n神明大人……不管你是管姻緣還是管財富的，拜託……"},
			{"speaker": "誠一", "text": "保佑明天客戶驗收時，那個不知名報錯不要跑出來……只要撐過明天就好……"},
			{"speaker": "廟公", "text": "哎，少年欸，這麼晚還來拜『碼農真君』啊？你臉色很差喔，要不要喝杯壓驚茶……"},
			{"speaker": "誠一", "text": "謝……謝謝，我放個乖乖就……"},
			{"speaker": "系統提示", "text": "體力 (HP) 歸零。", "system": true, "effect": "heartbeat"},
			{"speaker": "誠一", "text": "糟糕，視線變黑了……", "is_thought": true},
			{"speaker": "", "text": "(沉悶的撞擊聲 —— 男主倒在供桌前，頭撞到香爐)", "effect": "blackout"}
		],
		"choices": [] # Auto-advance to next scene
	},
	{ # Scene 2: 0與1的彼岸
		"bg_color": Color(0, 0.2, 0), # Matrix green
		"dialogue": [
			{"speaker": "誠一", "text": "這裡是……急診室？不對，哪家醫院的裝潢這麼像駭客任務？"},
			{"speaker": "碼農真君", "text": "唉，又 Crash（崩潰）了一個。現在的系統負載量真是越來越難搞了。"},
			{"speaker": "誠一", "text": "你……你是誰？新來的實習生嗎？"},
			{"speaker": "碼農真君", "text": "沒禮貌！吾乃『九天玄機碼農真君』，掌管這片土地上所有 Server 的穩定與 Bug 的渡化。你剛剛拿綠色乖乖賄賂我，我這不就來處理客訴了嗎？"},
			{"speaker": "誠一", "text": "神明？神明穿格子襯衫？等等，所以我死了嗎？過勞死？"},
			{"speaker": "碼農真君", "text": "死倒是沒死，只是你的『大腦記憶體』滿了，暫時當機進入了這個中介空間。\n我看了看你的Log（日誌）……三十歲，存款不到十萬，沒有女朋友，每天被PM跟客戶折磨。這人生簡直比寫得最爛的麵條代碼（Spaghetti Code）還要慘啊！"},
			{"speaker": "誠一", "text": "……連神明都要嘲笑我嗎？如果可以重構（Refactor）我的人生，我也不想這樣啊。"},
			{"speaker": "碼農真君", "text": "重構？好詞！吾最近正愁這『現實世界』的邏輯 Bug 太多，需要一個有經驗的底層工程師幫忙 Debug。\n看在你那包綠色乖乖的份上，我給你開個『後台權限』吧。"},
			{"speaker": "", "text": "(畫面閃爍金黃色與藍色交織的光芒)", "effect": "flash_gold_blue"},
			{"speaker": "碼農真君", "text": "我賜予你【中斷點（Breakpoint）】的權限。遇到過不去的坎，就按下去。記住，這世界沒有解不開的 Bug，只有不夠高的權限！\n快回去吧，你的肉體快被廟公叫救護車載走了！"}
		],
		"choices": []
	},
	{ # Scene 3: 中斷點，啟動
		"bg_color": Color(0.8, 0.8, 0.9), # Morning
		"dialogue": [
			{"speaker": "廟公", "text": "少年欸！少年欸！你醒啦？你昨晚在我這睡了一夜欸，還好沒事！"},
			{"speaker": "誠一", "text": "嘶……頭好痛。我昨晚……做了一個好扯的夢。"},
			{"speaker": "", "text": "（誠一站起身，拍拍身上的灰塵，手伸進口袋時，摸到了一個冰冷的硬物。）"},
			{"speaker": "誠一", "text": "這是什麼？\n（從口袋拿出一個帶有紅色圓點按鈕的隨身碟掛飾，上面刻著『Bug-Free』）"},
			{"speaker": "誠一", "text": "我原本有這個東西嗎？等等，快九點了！今天長官要指派新專案，遲到就死定了！", "is_thought": true},
			{"speaker": "", "text": "(男主急忙轉身，卻不小心撞到了一個路過的女學生/OL，手上的咖啡眼看就要潑到男主身上！)"},
			{"speaker": "誠一", "text": "啊！完蛋——\n（情急之下，誠一的手指下意識地按下了那個紅色按鈕）"},
			{"speaker": "", "text": "(高頻的電子滴答聲「滴——」\n以男主為圓心，一道藍色的波紋掃過全螢幕，世界瞬間變成灰階。)", "effect": "grayscale"},
			{"speaker": "誠一", "text": "……欸？咖啡……停在半空中了？路人也都不動了？\n（男主左右張望，用手指輕輕把停在半空中的熱咖啡推開，然後自己往旁邊走了一步。）"},
			{"speaker": "誠一", "text": "那個夢……難道是真的？我真的拿到了現實世界的系統權限？"},
			{"speaker": "系統提示", "text": "【能力覺醒：中斷點 (Breakpoint)】\n▶ 你可以在任何時候按下右上角的 [🔴 Debug] 按鈕暫停時間。\n▶ 在時停期間，你可以進行特殊互動。\n▶ 注意：每次啟動中斷點，將大量消耗你的 壓力 (SAN) 值。若 SAN 值達到 100，將觸發【精神崩潰】！", "system": true},
			{"speaker": "", "text": "(誠一再次按下按鈕，時間恢復流動，顏色恢復\n咖啡潑灑在原本誠一站立的空地上)", "effect": "restore_color"},
			{"speaker": "誠一", "text": "呵呵……哈哈哈！有了這個，什麼死亡專案、什麼難搞的PM……\n這一次，輪到我來 Hack 這個世界了！"}
		],
		"choices": [
			{"text": "進入遊戲 (Start Game)", "next_scene": "start_game"}
		]
	}
]

func _ready():
	load_scene(0)

func load_scene(index):
	current_scene_index = index
	current_dialogue_index = 0
	bg.color = scenes[index]["bg_color"]
	clear_choices()
	show_dialogue()

func show_dialogue():
	var scene = scenes[current_scene_index]
	var dialogues = scene["dialogue"]
	
	if current_dialogue_index < dialogues.size():
		var line_data = dialogues[current_dialogue_index]
		
		# Set Speaker
		if line_data["speaker"] == "":
			speaker_label.text = ""
			speaker_label.visible = false
		else:
			speaker_label.text = line_data["speaker"]
			speaker_label.visible = true
			
			if line_data.has("system") and line_data["system"]:
				speaker_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2)) # Red for system
			else:
				speaker_label.remove_theme_color_override("font_color")

		# Set Text
		var display_text = line_data["text"]
		if line_data.has("is_thought") and line_data["is_thought"]:
			text_label.text = "[i]" + display_text + "[/i]"
			text_label.add_theme_color_override("default_color", Color(0.7, 0.7, 1.0)) # Light blue for thoughts
		else:
			text_label.text = display_text
			text_label.remove_theme_color_override("default_color")
			
		# Handle Effects
		if line_data.has("effect"):
			trigger_effect(line_data["effect"])
			
	else:
		show_choices()

func trigger_effect(effect_name):
	match effect_name:
		"flash_red":
			flash_screen(Color(1, 0, 0, 0.5))
		"flash_gold_blue":
			flash_screen(Color(0.8, 0.8, 0.2, 0.5))
		"blackout":
			bg.color = Color.BLACK
		"grayscale":
			bg.material = CanvasItemMaterial.new()
			# Ideally a proper shader for grayscale, but setting modulate to gray for now
			bg.modulate = Color(0.5, 0.5, 0.5) 
		"restore_color":
			bg.modulate = Color(1, 1, 1)

func flash_screen(color: Color):
	color_rect_flash.color = color
	var tween = create_tween()
	tween.tween_property(color_rect_flash, "color:a", 0.0, 0.5)

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		var scene = scenes[current_scene_index]
		if current_dialogue_index < scene["dialogue"].size():
			current_dialogue_index += 1
			if current_dialogue_index < scene["dialogue"].size():
				show_dialogue()
			else:
				show_choices()
				
				# Auto-advance if no choices
				if scene["choices"].size() == 0:
					if current_scene_index < scenes.size() - 1:
						load_scene(current_scene_index + 1)
					else:
						start_main_game()

func show_choices():
	clear_choices()
	var choices = scenes[current_scene_index]["choices"]
	for choice in choices:
		var btn = Button.new()
		btn.text = choice["text"]
		btn.custom_minimum_size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_choice_made.bind(choice["next_scene"]))
		choices_container.add_child(btn)
		
	if choices.size() > 0:
		choices_container.visible = true

func clear_choices():
	choices_container.visible = false
	for child in choices_container.get_children():
		child.queue_free()

func _on_choice_made(next_scene):
	if str(next_scene) == "start_game":
		start_main_game()
	elif str(next_scene) == "go_home_fail":
		# Add a minor fail state dialogue if needed, or just force them to the temple
		scenes[0]["dialogue"].append({"speaker": "誠一", "text": "不行... 明天要交件了，我還是去拜拜求個心安吧。"})
		current_dialogue_index = scenes[0]["dialogue"].size() - 1
		show_dialogue()
	else:
		load_scene(next_scene)

func start_main_game():
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")
