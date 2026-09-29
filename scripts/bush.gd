@tool
class_name Bush
extends Node2D
## Куст-укрытие: внутри него совы светлячка не видят.

@export var radius: float = 90.0:
    set(v):
        radius = v
        if is_node_ready():
            _apply()

@onready var visual: Node2D = $Visual
@onready var leaves: CPUParticles2D = $Leaves

var _tw: Tween


func _ready() -> void:
    _apply()


func _apply() -> void:
    visual.scale = Vector2.ONE * (radius / 90.0)


func contains(p: Vector2) -> bool:
    return p.distance_to(global_position) < radius


## Прячет ли укрытие точку p в момент t. Кувшинки переопределяют (тонут по таймеру).
func hides(p: Vector2, _t: float) -> bool:
    return contains(p)


## Для укрытий, зависящих от времени (кувшинки). У куста ничего не меняется.
func set_time(_t: float) -> void:
    pass


func rustle() -> void:
    leaves.restart()
    if _tw:
        _tw.kill()
    var s: Vector2 = Vector2.ONE * (radius / 90.0)
    _tw = create_tween()
    _tw.tween_property(visual, "scale", s * Vector2(1.12, 0.9), 0.08)
    _tw.tween_property(visual, "scale", s, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
