extends Node2D


var velocity: Vector2 = Vector2.RIGHT
var speed: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	speed = randf_range(4.0, 16.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += velocity * delta * speed
