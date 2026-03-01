extends Camera2D
var shake_strength = 0.0
var shake_decay = 10.0
var shake_speed = 50.0
var time = 0.0

func _physics_process(delta: float) -> void:
	time += delta * shake_speed

	offset.x = sin(time) * shake_strength
	offset.y = cos(time) * shake_strength

	shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)


func shake(amount,speed = shake_speed, decay = shake_decay):
	shake_strength += amount
	shake_speed = speed
	shake_decay = decay
