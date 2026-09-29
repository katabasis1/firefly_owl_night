@tool
class_name Thorns
extends Node2D
## Колючий куст-ловушка. Касание — провал.

@export var radius: float = 50.0:
    set(v):
        radius = v
        if is_node_ready():
            _apply()

@onready var visual: Node2D = $Visual
@onready var glow: Node2D = $Glow

var _t := 0.0


func _ready() -> void:
    _apply()
    _t = randf() * 10.0


func _apply() -> void:
    visual.scale = Vector2.ONE * (radius / 50.0)
    glow.scale = Vector2.ONE * (radius / 50.0) * 1.4


func hits(p: Vector2) -> bool:
    return p.distance_to(global_position) < radius * 0.85


func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    _t += delta * WorldClock.scale
    visual.rotation = sin(_t * 1.3) * 0.05
    glow.modulate.a = 0.5 + 0.25 * sin(_t * 2.0)


func alert() -> void:
    var tw: Tween = create_tween()
    var s: Vector2 = visual.scale
    tw.tween_property(visual, "scale", s * 1.2, 0.08)
    tw.tween_property(visual, "scale", s, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
