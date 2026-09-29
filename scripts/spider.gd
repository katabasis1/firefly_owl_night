@tool
class_name Spider
extends Node2D
## Паук, качающийся на паутинке. Позиция — функция времени t.

@export var amplitude: float = 110.0:
    set(v):
        amplitude = v
        _refresh()
@export var period: float = 2.4
@export_range(0.0, 1.0) var phase: float = 0.0:
    set(v):
        phase = v
        _refresh()
## true — качается влево-вправо, false — вверх-вниз.
@export var horizontal: bool = true
@export var radius: float = 36.0
@export var thread_length: float = 300.0:
    set(v):
        thread_length = v
        _refresh()

@onready var body: Node2D = $Body
@onready var thread: Line2D = $Thread
@onready var legs: Node2D = $Body/Legs
@onready var eye_glow: Node2D = $Body/EyeGlow

var _t := 0.0


func _ready() -> void:
    _t = randf() * 10.0
    set_time(0.0)


func _refresh() -> void:
    if is_node_ready():
        set_time(0.0)


func offset_at(t: float) -> Vector2:
    var s: float = amplitude * sin(TAU * (t / period + phase)) if period > 0.0 else 0.0
    return Vector2(s, 0.0) if horizontal else Vector2(0.0, s)


func hits(p: Vector2, t: float) -> bool:
    return p.distance_to(global_position + offset_at(t)) < radius


func set_time(t: float) -> void:
    var off: Vector2 = offset_at(t)
    body.position = off
    thread.points = PackedVector2Array([Vector2(0.0, -thread_length), off + Vector2(0, -14)])
    body.rotation = -atan2(off.x, thread_length) if horizontal else 0.0


func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    _t += delta * WorldClock.scale
    legs.scale.y = 1.0 + 0.1 * sin(_t * 10.0)
    eye_glow.modulate.a = 0.6 + 0.4 * sin(_t * 4.0)


func alert() -> void:
    var tw: Tween = create_tween()
    tw.tween_property(body, "scale", Vector2.ONE * 1.35, 0.12).set_trans(Tween.TRANS_BACK)
    tw.tween_property(body, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
