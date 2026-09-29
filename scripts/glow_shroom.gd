@tool
class_name GlowShroom
extends Node2D
## Светогриб: по таймеру вспыхивает. Пока горит, любая неспящая сова
## видит светлячка в его свете, даже в кусте.

const WARN: float = 0.5

@export var radius: float = 150.0:
    set(v):
        radius = v
        _apply()
@export var period: float = 3.0
@export var lit: float = 1.2      ## сколько секунд гриб светится
@export var offset: float = 0.0

@onready var light: Node2D = $Light
@onready var ring: Node2D = $Ring
@onready var cap: Node2D = $Cap

var _t: float = 0.0


func _ready() -> void:
    _apply()
    set_time(0.0)


func _apply() -> void:
    if not is_node_ready():
        return
    ring.scale = Vector2.ONE * (radius / 100.0)
    if Engine.is_editor_hint():
        light.visible = true
        light.scale = Vector2.ONE * (radius / 100.0)
        light.modulate.a = 0.35


func is_lit(t: float) -> bool:
    return fposmod(t + offset, period) < lit


func lights(p: Vector2, t: float) -> bool:
    return is_lit(t) and p.distance_to(global_position) < radius


func set_time(t: float) -> void:
    if not is_node_ready():
        return
    var u: float = fposmod(t + offset, period)
    var on: bool = u < lit
    var k: float = 0.0
    if on:
        k = minf(minf(u / 0.12, 1.0), minf((lit - u) / 0.2, 1.0))
    light.visible = on
    light.scale = Vector2.ONE * (radius / 100.0) * lerpf(0.85, 1.0, k)
    light.modulate.a = k
    var warn: float = 0.0
    if not on:
        warn = clampf(1.0 - (period - u) / WARN, 0.0, 1.0)
    ring.visible = warn > 0.0 or Engine.is_editor_hint()
    ring.modulate.a = warn if not Engine.is_editor_hint() else 0.4
    cap.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.6, 1.5, 1.2), maxf(k, warn * 0.5))


func alert() -> void:
    var tw: Tween = create_tween()
    tw.tween_property(cap, "scale", Vector2(1.3, 1.3), 0.08)
    tw.tween_property(cap, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    _t += delta * WorldClock.scale
    cap.rotation = sin(_t * 1.7) * 0.04
