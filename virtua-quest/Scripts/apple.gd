extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collection_sound: AudioStreamPlayer2D = $CollectionSound

func _on_body_entered(_body: Node2D) -> void:
	anim.play("Collected")
	if not collection_sound.playing: 
		collection_sound.play()

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "Collected":
		queue_free()
