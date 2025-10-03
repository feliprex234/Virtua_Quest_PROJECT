extends CharacterBody2D

enum PlayerSate {
	idle,
	walk,
	jump,
	duck
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


const SPEED = 80.0
const JUMP_VELOCITY = -300.0

var direction = 0
var status: PlayerSate

func _ready() -> void:
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match  status:
		PlayerSate.idle:
			idle_state()
		PlayerSate.walk:
			walk_state()
		PlayerSate.jump:
			jump_state()
		PlayerSate.duck:
			duck_state()
			
	move_and_slide()


func go_to_idle_state():
	status = PlayerSate.idle
	anim.play("idle")
	
func go_to_walk_state():
	status = PlayerSate.walk
	anim.play("walk")
	
func go_to_jump_state():
	status = PlayerSate.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	
func go_to_duck_state():
	status = PlayerSate.duck
	anim.play("Duck")
	collision_shape_2d.shape.radius = 5
	collision_shape_2d.shape.height = 10
	collision_shape_2d.position.y = 3
	

func exit_from_duck_state():
	collision_shape_2d.shape.radius = 6
	collision_shape_2d.shape.height = 16
	collision_shape_2d.position.y = 0

func idle_state():
	move()
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("Duck"):
		go_to_duck_state()
		return

func walk_state():
	move()
	if velocity.x == 0:
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

func jump_state():
	move()
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
		
func duck_state():
	update_direction()
	if Input.is_action_just_released("Duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return

func move():
	update_direction()
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		
func update_direction():
	direction = Input.get_axis("move_left", "move_right")
	
	if direction<0:
		anim.flip_h = true
	elif direction  > 0:
		anim.flip_h = false
	

		
