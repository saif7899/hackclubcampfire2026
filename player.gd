extends CharacterBody2D
enum States {base, digging}
var state: States = States.base

@export var walkSpeed = 100
@export var digSpeed = 150
@export var gravity = 160
var moveDirection = Vector2.RIGHT
var inputDir = Vector2.ZERO

@export var jumpHeight = -100

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if state == States.base:
		inputDir = Input.get_axis("ui_left", "ui_right")
		moveDirection = inputDir
		if inputDir < 0:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false

		if (Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_up")) and is_on_floor():
			velocity.y = jumpHeight 
	
	velocity.x = moveDirection * walkSpeed
	move_and_slide()
