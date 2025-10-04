extends CharacterBody2D

enum PlayerSate {
	idle,
	walk,
	jump,
	fall,
	duck,
	slide
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var max_speed =90
@export var acceleration = 400
@export var decceleration = 300 
@export var slide_decceleration = 100
const JUMP_VELOCITY = -300.0

var jump_count = 0
@export var max_jump_count = 0
var direction = 0
var status: PlayerSate

func _ready() -> void:
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
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

	move_and_slide()


func go_to_idle_state():
	status = PlayerSate.idle
	anim.play("idle")
	
func go_to_walk_state():
	status = PlayerSate.walk
	anim.play("walk")
	
func go_to_jump_state():
	jump_count += 1
	status = PlayerSate.jump
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
	pass

func idle_state(delta):
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
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
		
	if not is_on_floor():
		jump_count+=1
		go_to_fall_state()
		return
	if is_on_floor():
		jump_count = 0
		
	if Input.is_action_just_pressed("Duck"):
		go_to_slide_state()
		return

func jump_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		
	if velocity.y > 0:
		go_to_fall_state()

		
func fall_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	if velocity.x == 0 && is_on_floor():
		go_to_idle_state()
	elif is_on_floor():
		go_to_walk_state()
	return
		
func duck_state(_delta):
	update_direction()
	if Input.is_action_just_released("Duck"):
		exit_from_duck_state() 
		go_to_idle_state()
		return
		
func slide_state(delta):
	velocity.x = move_toward(velocity.x,0, slide_decceleration * delta)
	
	if Input.is_action_just_released("Duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return
		
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state() 
		return
		

func move(delta):
	update_direction()
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decceleration * delta)
		
		
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
	

func set_large_collide():
	collision_shape_2d.shape.radius = 6
	collision_shape_2d.shape.height = 16
	collision_shape_2d.position.y = 0
