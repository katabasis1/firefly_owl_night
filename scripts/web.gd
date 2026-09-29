@tool
class_name Web
extends Node2D
## Паутина: внутри время идёт в rate раз быстрее, светлячок в ней вязнет.
## Линия короче, а мир успевает больше. Зато ждать здесь дешевле по свету.

@export var radius: float = 100.0:
    set(v):
        radius = v
        _apply()
@export var rate: float = 2.0

@onready var visual: Node2D = $Visual

var _t: float = 0.0


func _ready() -> void:
    _apply()


func _apply() -> void:
    if is_node_ready():
        visual.scale = Vector2.ONE * (radius / 100.0)


func contains(p: Vector2) -> bool:
    return p.distance_to(global_position) < radius


func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    _t += delta * WorldClock.scale
    visual.rotation = sin(_t * 0.8) * 0.03
