extends CharacterBody2D
enum States {base, digging, dashing}
var state: States = States.base
@onready var anim = $Sprite2D/AnimationPlayer

@export var walkSpeed = 100
@export var digSpeed = 150
@export var gravity = 160
var moveDirection = Vector2.RIGHT
var inputDir = Vector2.ZERO

@export var jumpHeight = -100

@export var dashSpeed = 100
@export var dashDuration = 0.1
var mouseDir = (get_global_mouse_position() - global_position).normalized()

func _physics_process(delta: float) -> void:
	$Sprite2D/Drill.look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("Dash"):
		Dash()
	
	if state == States.base:
		if not is_on_floor():
			velocity.y += gravity * delta
		inputDir = Input.get_axis("ui_left", "ui_right")
		moveDirection = inputDir
		if inputDir != 0 and is_on_floor():
			anim.play("Walk")
		else:
			anim.play("Idle")
			
		if inputDir < 0:
			$Sprite2D.scale.x = -1
		elif inputDir > 0:
			$Sprite2D.scale.x = 1
		velocity.x = moveDirection * walkSpeed

	elif state == States.digging:
		velocity = mouseDir * digSpeed


		if (Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_up")) and is_on_floor():
			velocity.y = jumpHeight 
	
	move_and_slide()

func Dash():
	set_collision_mask_value(3,false)
	state = States.dashing
	var dir = mouseDir
	velocity = dir * dashSpeed
	
	await get_tree().create_timer(dashDuration).timeout
	set_collision_mask_value(3,true)
	velocity = Vector2.ZERO
	if state != States.digging:
		state = States.base



func _on_sand_body_entered(body: Node2D) -> void:
	if state == States.dashing:
		state = States.digging

func _on_sand_body_exited(body: Node2D) -> void:
	if state == States.digging:
		state = States.base
