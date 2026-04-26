extends Node2D

@onready var zone: Area2D = $Zone
@onready var prompt: Label = $Prompt
@onready var dialog = get_node("/root/World/kimi")

var player_in_zone: bool = false

func _ready():
	prompt.visible = false
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "player":
		player_in_zone = true

func _on_body_exited(body):
	if body.name == "player":
		player_in_zone = false

func _process(_delta):
	prompt.visible = player_in_zone and not dialog.dialog_active
	if player_in_zone and not dialog.dialog_active and Input.is_action_just_pressed("talk"):
		dialog.start_dialog()
