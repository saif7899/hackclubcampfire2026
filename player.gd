extends CharacterBody2D
enum States {base, digging, dashing, exiting}
var state: States = States.base
@onready var anim = $Sprite2D/AnimationPlayer

@export var walkSpeed = 100
@export var digSpeed = 230
@export var gravity = 200
var moveDirection = Vector2.RIGHT
var inputDir = Vector2.ZERO

@export var jumpHeight = -100

@export var dashSpeed = 400
@export var dashDuration = 0.1
var mouseDir = Vector2.ZERO
var airDashed = false
var dashCooldown = 0.5
var inDashCooldown = false
var speed = Vector2.ZERO

var inSand = false

func _physics_process(delta: float) -> void:
	mouseDir = (get_global_mouse_position() - global_position).normalized()
	$Sprite2D/Drill.look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("Dash"):
		Dash()
	if is_on_floor():
		airDashed = false
		if Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_up"):
			velocity.y = jumpHeight 
	
	if state == States.exiting:
		anim.play("Digging")
		rotation = lerp_angle(rotation,velocity.angle(),0.2)
	
	if state == States.base or state == States.exiting:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
			state = States.base
			rotation = lerp_angle(rotation,0,0.7)
	
	if state == States.base:
		if (Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_up")) and is_on_floor():
			velocity.y = jumpHeight 
		inputDir = Input.get_axis("ui_left", "ui_right")
		moveDirection = inputDir
		if inputDir != 0 and is_on_floor():
			anim.play("Walk")
		else:
			anim.play("RESET")
			
		if inputDir < 0:
			$Sprite2D.scale.x = -1
		elif inputDir > 0:
			$Sprite2D.scale.x = 1
		speed = Vector2(moveDirection * walkSpeed, velocity.y)
	elif state == States.digging:
		speed = velocity.lerp(mouseDir * digSpeed, 0.5)
		$Sprite2D.scale.x = 1
		anim.play("Digging")
		look_at(get_global_mouse_position())
	
	if state != States.dashing and state != States.exiting:
		velocity = velocity.lerp(speed, 0.3)
	else:
		$Sprite2D.scale.x = 1
	move_and_slide()

func Dash():
	if inDashCooldown or (airDashed and state != States.digging):
		return
	var stateBefore = state
	inDashCooldown = true
	if !inSand:
		if not is_on_floor():
			airDashed = true
	
	if state != States.digging: 
		set_collision_mask_value(3,false)
	
	state = States.dashing
	var dir = mouseDir
	anim.play("Digging")
	look_at(get_global_mouse_position())
	velocity = dir * dashSpeed
	
	await get_tree().create_timer(dashDuration).timeout
	
	set_collision_mask_value(3,true)
	
	velocity = lerp(velocity, Vector2.ZERO, 0.5)
	if state == States.dashing:
		if stateBefore == States.exiting:
			
			state = States.base
			rotation = 0
		else:
			if stateBefore == States.base:
				rotation = 0
			state = stateBefore
	await get_tree().create_timer(dashCooldown).timeout
	inDashCooldown = false


func _on_sand_body_entered(_body: Node2D) -> void:
	inSand = true
	if state == States.dashing:
		state = States.digging

#func _on_sand_body_exited(body: Node2D) -> void:
	#if state == States.digging:
		#state = States.base


func _on_sand_body_shape_exited(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	inSand = false
	state = States.exiting
