extends CharacterBody2D

enum SkeletonState {
	walk,
	attack,
	hurt
}

const SPINING_BONE = preload("uid://cwea5bgrquynp")

@onready var hit_box: Area2D = $HitBox
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_star_position: Node2D = $BoneStarPosition
@onready var player_detector_back: RayCast2D = $PlayerDetectorBack
@onready var skeleton_walk_sound: AudioStreamPlayer2D = $SkeletonWalkSound
@onready var skeleton_hurt_sound: AudioStreamPlayer2D = $SkeletonHurtSound
@onready var skeleton_throw_sound: AudioStreamPlayer2D = $SkeletonThrowSound

const SPEED = 20.0
const JUMP_VELOCITY = -400.0

var status: SkeletonState
var direction = 1
var can_throw = true

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.attack:
			attack_state(delta)
		SkeletonState.hurt:
			hurt_state(delta)

	move_and_slide()
	
func go_to_walk_state():
	status = SkeletonState.walk
	anim.play("Walk")
	
func go_to_attack_state():
	status = SkeletonState.attack
	anim.play("Attack")
	skeleton_walk_sound.stop()
	skeleton_throw_sound.play()

	velocity = Vector2.ZERO
	can_throw = true
	
func go_to_hurt_state():
	status = SkeletonState.hurt
	anim.play("hurt")
	skeleton_walk_sound.stop()
	skeleton_throw_sound.stop()
	skeleton_hurt_sound.play()
	hit_box.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO


func walk_state(_delta):
	
	if anim.frame == 3  or anim.frame == 4:
		velocity.x = SPEED * direction
		if not skeleton_walk_sound.playing: 
			skeleton_walk_sound.play()
	else:
		velocity.x = 0
	
	if wall_detector.is_colliding():
		invert_direction()
		
	if not ground_detector.is_colliding():
		invert_direction()

		
	if player_detector_back.is_colliding():
		invert_direction()
		
	if  player_detector.is_colliding():
		go_to_attack_state()
		

func attack_state(_delta):
	if anim.frame == 2 && can_throw:
		throw_bone()
		can_throw = false

func hurt_state(_delta):
	pass
	
func take_damage():
	go_to_hurt_state()

func throw_bone():
	var new_bone = SPINING_BONE.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_star_position.global_position
	new_bone.set_direction(self.direction)
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "Attack":
		go_to_walk_state()
		return
		
func invert_direction():
	direction *= -1
	scale.x *= -1
