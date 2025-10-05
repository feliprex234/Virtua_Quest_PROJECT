extends CharacterBody2D

enum PlayerSate {
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	wall,
	hurt
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer
@onready var collision_hitbox: CollisionShape2D = $HitBox/CollisionShape2D
@onready var right_wall_detector: RayCast2D = $RightWallDetector
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var player_jump_sound: AudioStreamPlayer2D = $PlayerJumpSound
@onready var player_walk_sound: AudioStreamPlayer2D = $PlayerWalkSound
@onready var player_slide_sound: AudioStreamPlayer2D = $PlayerSlideSound

@export var max_speed =90
@export var acceleration = 400
@export var decceleration = 300 
@export var slide_decceleration = 100
@export var wall_acceleration = 40
@export var wall_force = 150
const JUMP_VELOCITY = -300

var jump_count = 0
@export var max_jump_count = 0
var direction = 0
var status: PlayerSate

func _ready() -> void:
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	

	
	match  status:
		PlayerSate.idle:
			idle_state(delta)
		PlayerSate.walk:
			walk_state(delta)
		PlayerSate.jump:
			jump_state(delta)
		PlayerSate.fall:
			fall_state(delta)
		PlayerSate.duck:
			duck_state(delta)
		PlayerSate.slide:
			slide_state(delta)
		PlayerSate.wall:
			wall_state(delta)
		PlayerSate.hurt:
			hurt_state(delta)

	move_and_slide()


func go_to_idle_state():
	status = PlayerSate.idle
	anim.play("idle")
	player_walk_sound.stop()
	
func go_to_walk_state():
	status = PlayerSate.walk
	anim.play("walk")
	
func go_to_jump_state():
	jump_count += 1
	status = PlayerSate.jump
	player_walk_sound.stop()
	player_jump_sound.play()
	anim.play("jump")
	velocity.y = JUMP_VELOCITY

func go_to_fall_state():
	status = PlayerSate.fall
	anim.play("Fall")

func go_to_duck_state():
	status = PlayerSate.duck
	anim.play("Duck")
	set_small_collide()

func exit_from_duck_state():
	set_large_collide()

func go_to_slide_state():
	status = PlayerSate.slide
	anim.play("slide")

func exit_from_slide_state(): 
	player_slide_sound.stop()
	set_large_collide()

func go_to_wall_state():
	status = PlayerSate.wall
	anim.play("wall")
	velocity = Vector2.ZERO

func go_to_hurt_state():
	if status == PlayerSate.hurt:
		return
	
	status = PlayerSate.hurt
	anim.play("hurt")
	velocity.x = 0
	set_large_collide()
	death_sound.play()
	reload_timer.start() 
	
	

func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("Duck"):
		go_to_duck_state()
		return
		
	if is_on_floor():
		jump_count = 0

func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if anim.frame != 30 && not player_walk_sound.playing:
		player_walk_sound.play()
	
	if velocity.x == 0:
		player_walk_sound.stop()
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump") && can_jump():
		player_walk_sound.stop()
		go_to_jump_state()
		return
		
	if not is_on_floor():
		jump_count+=1
		player_walk_sound.stop()
		go_to_fall_state()
		return
	if is_on_floor():
		jump_count = 0
		
	if Input.is_action_just_pressed("Duck"):
		player_walk_sound.stop()
		go_to_slide_state()
		return

func jump_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		
	if velocity.y > 0:
		go_to_fall_state()

		
func fall_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	if velocity.x == 0 && is_on_floor():
		go_to_idle_state()
	elif is_on_floor():
		go_to_walk_state()
		
	if (left_wall_detector.is_colliding() or right_wall_detector.is_colliding()) && is_on_wall():
		go_to_wall_state()
		return
		
func duck_state(delta):
	apply_gravity(delta)
	update_direction()
	if Input.is_action_just_released("Duck"):
		exit_from_duck_state() 
		go_to_idle_state()
		return
		
func slide_state(delta):
	apply_gravity(delta)
	set_small_collide()
	if anim.frame != 30  && not player_slide_sound.playing:
		player_slide_sound.play()
	velocity.x = move_toward(velocity.x,0, slide_decceleration * delta)
	
	
	if Input.is_action_just_released("Duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return
		
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state() 
		return

func wall_state(delta):
	
	velocity.y += wall_acceleration * delta
	
	if anim.frame != 30 && not player_slide_sound.playing:
		player_slide_sound.play()
	
	if left_wall_detector.is_colliding():
		anim.flip_h = false
		direction = 1
	elif right_wall_detector.is_colliding():
		anim.flip_h = true
		direction = -1
	else:
		player_slide_sound.stop()
		go_to_fall_state()
		return
	
	if is_on_floor():
		player_slide_sound.stop()
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		velocity.x = wall_force * direction
		player_slide_sound.stop()
		go_to_jump_state()
		return

func hurt_state(delta):
	apply_gravity(delta)

func move(delta):
	update_direction()
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decceleration * delta)
		
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
func update_direction():
	direction = Input.get_axis("move_left", "move_right")
	
	if direction<0:
		anim.flip_h = true
	elif direction  > 0:
		anim.flip_h = false
	
	
func can_jump() -> bool:
	return jump_count < max_jump_count

func set_small_collide():
	collision_shape_2d.shape.radius = 5
	collision_shape_2d.shape.height = 10
	collision_shape_2d.position.y = 3
	
	collision_hitbox.shape.size.y = 10
	collision_hitbox.position.y = 3

func set_large_collide():
	collision_shape_2d.shape.radius = 6
	collision_shape_2d.shape.height = 16
	collision_shape_2d.position.y = 0
	
	collision_hitbox.shape.size.y = 15
	collision_hitbox.position.y = 0.5

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()
		
func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_hurt_state()

func hit_enemy(area: Area2D):
	if velocity.y > 0:
		#inimigo morre
		area.get_parent().take_damage()
		go_to_jump_state()
		return
	else:
		#player morre
		go_to_hurt_state()
		return
	
func hit_lethal_area ():
	go_to_hurt_state()


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
