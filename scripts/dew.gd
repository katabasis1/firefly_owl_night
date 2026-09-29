class_name Dew
extends Node2D
## Капля росы — собираемый бонус (звёзды за уровень).

@export var radius: float = 40.0

@onready var visual: Node2D = $Visual
@onready var glow: Node2D = $Glow
@onready var burst: CPUParticles2D = $Burst
@onready var plus: Label = $Plus

var previewed := false
var taken := false
var _t := 0.0
var _tw: Tween


func _ready() -> void:
    _t = randf() * TAU
    plus.visible = false


func _process(delta: float) -> void:
    _t += delta * WorldClock.scale
    if not taken:
        visual.position.y = sin(_t * 2.5) * 5.0
        visual.rotation = sin(_t * 1.7) * 0.08
        glow.modulate.a = 0.7 + 0.3 * sin(_t * 3.0)


func contains(p: Vector2) -> bool:
    return not taken and p.distance_to(global_position) < radius


func _new_tween() -> Tween:
    if _tw:
        _tw.kill()
    _tw = create_tween()
    return _tw


## Подсветка «будущего» сбора во время рисования.
func set_preview(on: bool) -> void:
    if previewed == on:
        return
    previewed = on
    var tw: Tween = _new_tween()
    if on:
        tw.tween_property(visual, "scale", Vector2.ONE * 1.4, 0.1)
        tw.tween_property(visual, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(visual, "modulate", Color(1.3, 1.3, 1.5, 0.5), 0.2)
    else:
        tw.tween_property(visual, "modulate", Color.WHITE, 0.2)


func collect() -> void:
    taken = true
    burst.restart()
    plus.visible = true
    plus.modulate.a = 1.0
    plus.position = Vector2(-40, -70)
    var tw: Tween = _new_tween().set_parallel(true)
    tw.tween_property(visual, "scale", Vector2.ONE * 1.9, 0.25).set_trans(Tween.TRANS_BACK)
    tw.tween_property(visual, "modulate:a", 0.0, 0.25)
    tw.tween_property(glow, "modulate:a", 0.0, 0.3)
    tw.tween_property(plus, "position:y", -130.0, 0.8).set_ease(Tween.EASE_OUT)
    tw.tween_property(plus, "modulate:a", 0.0, 0.5).set_delay(0.3)


func reset() -> void:
    if _tw:
        _tw.kill()
    taken = false
    previewed = false
    visual.scale = Vector2.ONE
    visual.modulate = Color.WHITE
    glow.modulate.a = 1.0
    plus.visible = false
