extends Area2D

var direction = Vector2.RIGHT
var speed = 300
var damage = 10
var lifetime = 2.0
var timer = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += direction * speed * delta
	timer += delta
	if timer >= lifetime:
		queue_free()
	
func _on_body_entered(body):
	if body.has_method("_take_damage") and body is not Cop:
		body._take_damage(damage)
		queue_free()
