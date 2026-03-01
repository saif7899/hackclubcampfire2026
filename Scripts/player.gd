extends CharacterBody2D
enum States {base, digging, dashing, exiting}
var state: States = States.exiting
@onready var anim = $Sprite2D/AnimationPlayer

var moveDirection = Vector2.RIGHT
var inputDir = Vector2.ZERO

@export var walkSpeed = 130
@export var digSpeed = 230
@export var gravity = 200


@export var jumpHeight = -100

@export var dashSpeed = 400
@export var dashDuration = 0.15
var airDashed = true
var dashCooldown = 0.5
var inDashCooldown = false

var speed = Vector2.ZERO
var mouseDir = Vector2.ZERO

var inSand = false
var wasInSand = false

@onready var drill_particles = $DrillParticles
@onready var drill_mat : ParticleProcessMaterial = drill_particles.process_material

func _physics_process(delta: float) -> void:
	for area in $Area2D.get_overlapping_areas():
		if area.get_collision_layer_value(4):
			get_tree().reload_current_scene()
	var tilemap = $"../TileMapLayer"
	var cell = tilemap.local_to_map(tilemap.to_local(global_position))
	var tile_data = tilemap.get_cell_tile_data(cell)
	if tile_data and tile_data.get_custom_data("isSand"):
		inSand = true
		state = States.digging
	else:
		inSand = false
		if wasInSand and !inSand:
			$Camera2D.shake(5)
			state = States.exiting
	wasInSand = inSand
	
	if state == States.digging or state == States.dashing:
		set_collision_mask_value(3,false)
	else:
		set_collision_mask_value(3,true)
	
	mouseDir = (get_global_mouse_position() - global_position).normalized()
	
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
		if is_on_floor() and !inSand:
			velocity.y = 0
			state = States.base
			rotation = lerp_angle(rotation,0,0.9)
	
	if state == States.base:
		$Sprite2D/Drill.look_at(get_global_mouse_position())
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
	if state == States.digging:
		speed = velocity.lerp(mouseDir * digSpeed, 0.5)
		drill_particles.emitting = true
		if velocity.length() > 0.1:
			var dir = -velocity.normalized()
			drill_mat.direction = Vector3(dir.x, dir.y, 0.0)
		$Sprite2D.scale.x = 1
		anim.play("Digging")
		$Camera2D.shake(0.05)
		rotation = lerp_angle(rotation,(get_global_mouse_position() - global_position).angle(),0.3)
	else:
		$DrillParticles.emitting = false
	
	if state != States.dashing and state != States.exiting:
		velocity = velocity.lerp(speed, 0.6)
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
	
	state = States.dashing
	var dir = mouseDir
	anim.play("Digging")
	look_at(get_global_mouse_position())
	velocity = dir * dashSpeed
	
	await get_tree().create_timer(dashDuration).timeout
	
	if dir.y < -0.7:
		velocity.y *= 0.5
	if inSand:
		if stateBefore == States.digging:
			$Camera2D.shake(3)
		else:
			$Camera2D.shake(6)
	velocity = lerp(velocity, Vector2.ZERO, 0.5)
	if state == States.dashing:
		if inSand:
			state = States.digging
		else:
			if stateBefore == States.digging:
				state = States.exiting
			else:
				state = States.base
				rotation = lerp_angle(rotation,0,0.9)

	
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
