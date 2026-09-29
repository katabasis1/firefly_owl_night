class_name Firefly
extends Node2D
## Светлячок-герой: только визуал и анимации, движение задаёт main.gd.

@onready var visual: Node2D = $Visual
@onready var wing_l: Node2D = $Visual/WingL
@onready var wing_r: Node2D = $Visual/WingR
@onready var glow: Node2D = $Glow
@onready var trail: CPUParticles2D = $Trail

var flying := false
var _t := 0.0
var _tw: Tween


func _process(delta: float) -> void:
    _t += delta
    var flap: float = sin(_t * (42.0 if flying else 16.0))
    wing_l.rotation = -0.3 + flap * 0.45
    wing_r.rotation = 0.3 - flap * 0.45
    var pulse: float = 0.5 + 0.5 * sin(_t * 3.2)
    glow.scale = Vector2.ONE * (1.45 + 0.25 * pulse)
    if not flying:
        visual.position.y = sin(_t * 2.2) * 4.0
        visual.rotation = lerpf(visual.rotation, 0.0, 0.1)


func _new_tween() -> Tween:
    if _tw:
        _tw.kill()
    _tw = create_tween()
    return _tw


func set_flying(on: bool) -> void:
    flying = on
    trail.emitting = on


func set_hidden(on: bool) -> void:
    var tw: Tween = create_tween()
    tw.tween_property(self, "modulate:a", 0.45 if on else 1.0, 0.15)


func face(dir: Vector2) -> void:
    if dir.length_squared() > 0.001:
        visual.rotation = lerpf(visual.rotation, clampf(dir.normalized().x * 0.45, -0.45, 0.45), 0.2)


func reset_visual() -> void:
    if _tw:
        _tw.kill()
    set_flying(false)
    visible = true
    modulate = Color.WHITE
    scale = Vector2.ONE
    rotation = 0.0
    visual.rotation = 0.0


func pop_in() -> void:
    scale = Vector2.ZERO
    var tw: Tween = _new_tween()
    tw.tween_interval(0.25)
    tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func wiggle() -> void:
    var tw: Tween = _new_tween()
    scale = Vector2.ONE
    tw.tween_property(self, "scale", Vector2(1.35, 0.8), 0.08)
    tw.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func caught() -> void:
    var tw: Tween = _new_tween()
    tw.tween_property(self, "modulate", Color(1.0, 0.3, 0.35), 0.08)
    tw.tween_property(self, "scale", Vector2(1.5, 0.6), 0.1)
    tw.tween_property(self, "scale", Vector2.ONE * 0.8, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    tw.tween_property(self, "modulate:a", 0.35, 0.4)


func celebrate(target: Vector2) -> void:
    var tw: Tween = _new_tween().set_parallel(true)
    tw.tween_property(self, "position", target, 0.35).set_trans(Tween.TRANS_SINE)
    tw.tween_property(self, "scale", Vector2.ONE * 0.55, 0.35)
    tw.tween_property(self, "rotation", TAU, 0.5).set_ease(Tween.EASE_OUT)
