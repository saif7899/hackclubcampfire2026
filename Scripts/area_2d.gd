extends Area2D

@export var next_scene : String

@onready var anim = $AnimationPlayer

var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered:
		return
	if body is CharacterBody2D:
		triggered = true
		FadeAndSwitch()

func FadeAndSwitch():
	anim.play("fade")
	await anim.animation_finished
	get_tree().change_scene_to_file(next_scene)
