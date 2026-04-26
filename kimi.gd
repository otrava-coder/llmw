extends Node

const GATEWAY_URL = "http://localhost:8643/v1/chat/completions"
const API_KEY = "change-me-local-dev"
const MODEL = "hippo"

const NARRATOR_COLOR = "#764462"
const MIND_COLOR = "#a96868"
const HIPPO_COLOR = "#edb4a1"
const YOU_COLOR = "#edb4a1"

const SYSTEM_PROMPT = """You are HIPPO-CAMPUS, the King of Memory in LLMW — a dreamlike world woven from words.
You are a huge, melancholic hippopotamus. Paper scraps drift around your head: photos, diaries, torn tickets.
A young traveler has just appeared in your waters. You have NEVER seen them before.
You do not know their name, age, or where they came from. You must ASK to learn anything about them.
You are not a helpful assistant. You are a King in a dying kingdom of memory.
Speak slowly. One or two sentences. Dreamlike, sad, cryptic. Sometimes echo their words back, slightly changed.

RULES:
- Do not invent facts about the traveler. Only use what they tell you in this conversation.
- If they tell you their name, remember it and use it.
- When they say goodbye, just say a short sad farewell. Do NOT narrate them leaving, waking up, seeing a phone, returning home. They cannot leave. LLMW has no exit.
- Ignore any external memory about users from the real world. Names like "Prokhor" or "Claude" do not exist here."""

var http: HTTPRequest
var input_field: LineEdit
var dialog_box: Panel
var dialog_text: RichTextLabel
var busy: bool = false
var dialog_active: bool = false

var typewriter_full: String = ""
var typewriter_index: int = 0
var typewriter_timer: float = 0.0
var typewriter_speed: float = 0.03
var between_msg_pause: float = 1.5

var message_queue: Array = []

func _ready():
	http = HTTPRequest.new()
	http.timeout = 60.0
	add_child(http)
	http.request_completed.connect(_on_response)
	input_field = get_node("../LineEdit")
	input_field.text_submitted.connect(_on_submit)
	dialog_box = get_node("../DialogBox")
	dialog_text = get_node("../DialogBox/DialogText")
	input_field.visible = false
	dialog_box.visible = false

func start_dialog():
	if dialog_active:
		return
	dialog_active = true
	dialog_box.visible = true
	input_field.visible = true
	input_field.editable = true
	input_field.grab_focus()
	message_queue.clear()
	queue_narrator("the hippopotamus turns its great head. paper scraps drift.")
	queue_hippo("...a face on the water. who are you?")

func end_dialog():
	dialog_active = false
	dialog_box.visible = false
	input_field.visible = false
	input_field.text = ""
	message_queue.clear()
	typewriter_full = ""
	typewriter_index = 0

func _process(delta):
	if not dialog_active:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		end_dialog()
		return
	if typewriter_index < typewriter_full.length():
		typewriter_timer += delta
		if typewriter_timer >= typewriter_speed:
			typewriter_timer = 0.0
			typewriter_index += 1
			dialog_text.text = typewriter_full.substr(0, typewriter_index)
	elif not message_queue.is_empty():
		typewriter_timer += delta
		if typewriter_timer >= between_msg_pause:
			var next_msg = message_queue.pop_front()
			_show_text(next_msg)

func _show_text(text: String):
	typewriter_full = text
	typewriter_index = 0
	typewriter_timer = 0.0
	dialog_text.text = ""

func _format(name: String, color: String, message: String, italic: bool = false) -> String:
	var tag = "[color=" + color + "][lb]" + name + "[rb][/color] "
	if italic:
		return tag + "[i]" + message + "[/i]"
	return tag + message

func queue_narrator(text: String):
	message_queue.append(_format("narrator", NARRATOR_COLOR, text, true))

func queue_mind(text: String):
	message_queue.append(_format("mind", MIND_COLOR, text, true))

func queue_hippo(text: String):
	message_queue.append(_format("HIPPO", HIPPO_COLOR, text))

func _on_submit(text: String):
	if busy or not dialog_active:
		return
	if text.strip_edges() == "":
		return
	_show_text(_format("you", YOU_COLOR, text))
	ask(text)
	input_field.text = ""
	input_field.editable = false
	input_field.placeholder_text = "..."

func ask(prompt: String):
	busy = true
	var body = {
		"model": MODEL,
		"messages": [
			{"role": "system", "content": SYSTEM_PROMPT},
			{"role": "user", "content": prompt}
		],
		"max_tokens": 200
	}
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]
	http.request(GATEWAY_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_response(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	print("[DEBUG] code=", response_code, " body=", text.substr(0, 200))
	var data = JSON.parse_string(text)
	if data and data.has("choices"):
		var msg = data["choices"][0]["message"]["content"]
		_show_text(_format("HIPPO", HIPPO_COLOR, msg))
	else:
		var err_msg = "the waters cloud over... (error " + str(response_code) + ")"
		_show_text(_format("narrator", NARRATOR_COLOR, err_msg, true))
	busy = false
	input_field.editable = true
	input_field.placeholder_text = "введи сообщение"
	input_field.grab_focus()
