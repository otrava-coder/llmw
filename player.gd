extends CharacterBody2D

const SPEED = 200.0

@onready var dialog_system = get_node("/root/World/kimi")

func _ready():
	var vp = get_viewport_rect().size
	position = Vector2(vp.x / 2, vp.y * 0.35)

func _physics_process(_delta):
	if dialog_system.dialog_active:
		velocity = Vector2.ZERO
		return
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	velocity = direction.normalized() * SPEED
	move_and_slide()
