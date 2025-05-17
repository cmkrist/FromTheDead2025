extends NPC
class_name Cop

const cop_texture = preload("res://assets/textures/policeman.png")
const bullet_scene = preload("res://scenes/Objects/bullet.tscn")
var is_aggro = false
var target: Node2D
var range = 40
var shooting_range = 150  # Maximum distance to shoot
var can_shoot = true
var shoot_cooldown_time = 1.5  # Seconds between shots
var bullet_speed = 300

func _ready() -> void:
	$Icon.hide()
	# Set default character sprite if none is set
	if $Sprite2D.texture == null:
		var keys = Characters.keys()
		set_sprite(Characters[keys[randi_range(0, keys.size() - 1)]])
	# Set initial Goal
	if Goal:
		$NavigationAgent2D.target_position = Goal.global_position
	# Connect timer timeout signal
	$ShotCooldown.timeout.connect(_on_shoot_cooldown_timeout)

func _physics_process(delta: float) -> void:
	if is_aggro:
		aggro_logic(delta)
	if !$NavigationAgent2D.is_target_reached():
		velocity = to_local($NavigationAgent2D.get_next_path_position()).normalized() * SPEED * delta
	else:
		get_new_target()
	set_state()
	update_sprite()
	move_and_slide()
	
func aggro_logic(delta):
	# Run towards the target
	if target:
		var distance_to_target = global_position.distance_to(target.global_position)
		
		# If target is in shooting range, try to shoot
		if distance_to_target <= shooting_range:
			# If target is out of melee range, stop to shoot
			if distance_to_target > range:
				$NavigationAgent2D.target_position = global_position
				if can_shoot:
					shoot_at_target()
			else:
				# If target is in melee range, continue with melee behavior
				$NavigationAgent2D.target_position = global_position
				if !$AudioStreamPlayer2D.playing:
					$AudioStreamPlayer2D.play()
		else:
			# If target is out of range, move towards it
			$NavigationAgent2D.target_position = target.global_position
	else:
		get_new_target()
	
func get_new_target():
	# Get all goals in level, then select one at random
	var goals = get_tree().get_nodes_in_group("goals")
	if goals.size() > 0:
		var random_goal = goals[randi_range(0, goals.size() - 1)]
		$NavigationAgent2D.target_position = random_goal.global_position
		Goal = random_goal
		$NavigationAgent2D.target_position = Goal.global_position
	else:
		# If no goals are available, set a random position
		var random_position = Vector2(randi_range(0, 1000), randi_range(0, 1000))
		$NavigationAgent2D.target_position = random_position
		Goal = null
		
func set_state():
	previous_state = current_state
	if velocity == Vector2.ZERO:
		current_state = STATE.IDLE
	elif abs(velocity.x) > abs(velocity.y):
		# Moving l/r
		if velocity.x > 0:
			current_state = STATE.WALK_RIGHT
		else:
			current_state = STATE.WALK_LEFT
	else:
		# Moving u/d
		if velocity.y > 0:
			current_state = STATE.WALK_DOWN
		else:
			current_state = STATE.WALK_UP

func update_sprite() -> void:
	match current_state:
		STATE.IDLE:
			$AnimationPlayer.stop()
			match previous_state:
				STATE.WALK_LEFT:
					$Sprite2D.frame = 0
				STATE.WALK_RIGHT:
					$Sprite2D.frame = 3
				STATE.WALK_UP:
					$Sprite2D.frame = 2
				STATE.WALK_DOWN:
					$Sprite2D.frame = 1
				_:
					$Sprite2D.frame = 0
		STATE.WALK_LEFT:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_left"):
				$AnimationPlayer.play("human_animations/walk_left")
		STATE.WALK_RIGHT:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_right"):
				$AnimationPlayer.play("human_animations/walk_right")
		STATE.WALK_UP:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_up"):
				$AnimationPlayer.play("human_animations/walk_up")
		STATE.WALK_DOWN:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_down"):
				$AnimationPlayer.play("human_animations/walk_down")

func set_sprite(res_location):
	$Sprite2D.texture = load(res_location)
	$Sprite2D.frame = 1
	
func attack(player):
	is_aggro = true
	target = player
	$Icon.show()

func shoot_at_target():
	if target and can_shoot:
		# Visual feedback for shooting
		var muzzle_flash = create_muzzle_flash()
		add_child(muzzle_flash)
		
		# Create bullet
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		# Set bullet direction and position
		var direction = (target.global_position - global_position).normalized()
		bullet.global_position = global_position
		bullet.direction = direction
		
		# Play shooting sound if available
		if has_node("ShootSound") and !$ShootSound.playing:
			$ShootSound.play()
		
		# Set cooldown
		can_shoot = false
		$ShotCooldown.start(shoot_cooldown_time)

func _on_shoot_cooldown_timeout():
	can_shoot = true

func create_muzzle_flash():
	var flash = Node2D.new()
	flash.name = "MuzzleFlash"
	
	# Set up the muzzle flash to automate itself
	flash.set_script(GDScript.new())
	flash.script.source_code = """
extends Node2D

var lifetime = 0.2
var timer = 0.0
var size = 10.0

func _process(delta):
	timer += delta
	if timer >= lifetime:
		queue_free()
	queue_redraw()

func _draw():
	var alpha = 1.0 - (timer / lifetime)
	draw_circle(Vector2.ZERO, size * alpha, Color(1, 0.8, 0.2, alpha))
"""
	
	# Position the muzzle flash slightly ahead of the cop
	var direction = Vector2.RIGHT
	if target:
		direction = (target.global_position - global_position).normalized()
	
	flash.position = direction * 20  # 20 pixels ahead in the direction of the target
	
	return flash
