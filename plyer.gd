extends CharacterBody2D

@export var speed = 300       # How fast the player moves horizontally
@export var gravity = 900     # Gravity strength
var gravity_direction = 1     # 1 = down, -1 = up

func _physics_process(delta):
	# Constant horizontal velocity
	velocity.x = speed
	
	# Apply gravity in current direction
	velocity.y += gravity * gravity_direction * delta
	
	# Flip gravity when player presses "flip" (define in Input Map)
	if Input.is_action_just_pressed("flip"):
		gravity_direction *= -1
	
	#get the plyer to move
	move_and_slide()
	
	#Tjeks for collisions and tjeks if the collider is in the obstacle group
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		# Only die if the collider is valid AND in the obstacle group
		if collider and collider.is_in_group("obstacle"):
			die()




func die():
	queue_free()   # Removes player from the game
	print("Game Over!")
