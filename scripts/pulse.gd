extends Node2D
## Универсальная «пульсация» для декоративных узлов.

@export var amount: float = 0.08
@export var speed: float = 3.0
@export var bob: float = 0.0
@export var fade: float = 0.0

var _t := 0.0
var _base_scale: Vector2 = Vector2.ONE
var _base_y := 0.0
var _base_a := 1.0


func _ready() -> void:
    _base_scale = scale
    _base_y = position.y
    _base_a = modulate.a
    _t = randf() * TAU


func _process(delta: float) -> void:
    _t += delta * speed
    scale = _base_scale * (1.0 + amount * sin(_t))
    position.y = _base_y + bob * sin(_t * 0.5)
    if fade > 0.0:
        modulate.a = _base_a * (1.0 - fade * (0.5 + 0.5 * sin(_t)))
