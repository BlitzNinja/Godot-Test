extends CharacterBody2D


@export var walk_speed = 150.0
@export var run_speed = 300.0
@export_range(0, 1) var decceleration = 0.1
@export_range(0, 1) var acceleration = 0.1

@export var jump_force = -400.0
@export_range(0, 1) var deccelerate_on_jump_release = 0.5

@export var dash_speed = 1000.0
@export var dash_max_distance = 300.0
@export var dash_curve : Curve
@export var dash_cooldown = 1.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack1hitbox = $AttackArea2D/attack1hitbox
@onready var attack_area = $AttackArea2D


var is_dashing = false
var dash_start_position = 0
var dash_direction = 0
var dash_timer = 0
var jumpcheck = false
var isattacking = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
		velocity.y = jump_force
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= deccelerate_on_jump_release
	
	#jump animation
	if not is_on_floor() and not is_dashing and not isattacking:
		animated_sprite.play("jump")
		jumpcheck = true
	
	#landing animation
	if is_on_floor() and jumpcheck == true and not is_dashing and not isattacking:
		animated_sprite.play("land")
		jumpcheck = false
		
	var islanding = animated_sprite.animation == "land" and animated_sprite.is_playing()
		
	var speed
	if Input.is_action_pressed("run"):
		speed = run_speed
	else:
		speed = walk_speed
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
		if is_on_floor() and not islanding and not is_dashing and not isattacking:
			if Input.is_action_pressed("run"):
				animated_sprite.play("run")
			else:
				animated_sprite.play("walk")
			
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * decceleration)
		if is_on_floor() and not islanding and not is_dashing and not isattacking:
			animated_sprite.play("Idle")
	
	# Flip sprite direction and hitbox direction
	if direction < 0:
		animated_sprite.flip_h = true
		attack_area.scale.x = -1
	elif direction > 0:
		animated_sprite.flip_h = false
		attack_area.scale.x = 1
	
	# Dash Activation
	if Input.is_action_pressed("dash") and direction and not is_dashing and dash_timer <= 0:
		is_dashing = true
		dash_start_position = position.x
		dash_direction = direction
		dash_timer = dash_cooldown
		animated_sprite.play("dash")
	# Performs actual Dash
	if is_dashing:
		var current_distance = abs(position.x - dash_start_position)
		if current_distance >= dash_max_distance or is_on_wall():
			is_dashing = false
		else:
			velocity.x = dash_direction * dash_speed * dash_curve.sample(current_distance / dash_max_distance)
			velocity.y = 0
	# Reduces the dash timer
	if dash_timer > 0:
		dash_timer -= delta
	
	
	# Attack Animations
	if Input.is_action_just_pressed("attack1"):
		animated_sprite.play("attack1")
		isattacking = true
	if isattacking and animated_sprite.animation == "attack1" and not animated_sprite.is_playing():
		isattacking = false
	if Input.is_action_just_pressed("attack4"):
		animated_sprite.play("attack4")
		isattacking = true
	if isattacking and animated_sprite.animation == "attack4" and not animated_sprite.is_playing():
		isattacking = false
	# Attack Hitboxes
	if isattacking and animated_sprite.animation == "attack1":
		if animated_sprite.frame >=1 and animated_sprite.frame <= 3:
			attack1hitbox.set_deferred("disabled",false)
		else:
			attack1hitbox.set_deferred("disabled",true)
		
	move_and_slide()
