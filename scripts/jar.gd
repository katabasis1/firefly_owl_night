class_name Jar
extends Node2D
## Банка — дом светлячка и цель уровня.

@export var radius: float = 64.0

@onready var ring: Node2D = $Ring
@onready var inner_glow: Node2D = $InnerGlow
@onready var glass: Node2D = $Glass
@onready var lid: Node2D = $Lid
@onready var burst: CPUParticles2D = $Burst
@onready var family: CPUParticles2D = $Family

var _t := 0.0
var _done := false


func _process(delta: float) -> void:
    _t += delta * WorldClock.scale
    if not _done:
        ring.scale = Vector2.ONE * (1.0 + 0.08 * sin(_t * 3.0))
        ring.modulate.a = 0.55 + 0.35 * sin(_t * 3.0)


func contains(p: Vector2) -> bool:
    return p.distance_to(global_position) < radius


func celebrate() -> void:
    _done = true
    burst.restart()
    family.speed_scale = 3.0
    var tw: Tween = create_tween().set_parallel(true)
    tw.tween_property(inner_glow, "modulate:a", 1.0, 0.3)
    tw.tween_property(inner_glow, "scale", inner_glow.scale * 1.7, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(ring, "scale", Vector2.ONE * 2.2, 0.5).set_ease(Tween.EASE_OUT)
    tw.tween_property(ring, "modulate:a", 0.0, 0.5)
    var lid_y: float = lid.position.y
    var jump: Tween = create_tween()
    jump.tween_property(lid, "position:y", lid_y - 34.0, 0.14).set_ease(Tween.EASE_OUT)
    jump.tween_property(lid, "position:y", lid_y, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
    var squash: Tween = create_tween()
    squash.tween_property(glass, "scale", Vector2(1.15, 0.88), 0.1)
    squash.tween_property(glass, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
