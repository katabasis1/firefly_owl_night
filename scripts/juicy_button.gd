class_name JuicyButton
extends Button
## Кнопка с «сочной» анимацией нажатия/наведения и звуком клика.

var _tw: Tween


func _ready() -> void:
    focus_mode = Control.FOCUS_NONE
    pivot_offset = size * 0.5
    resized.connect(func() -> void: pivot_offset = size * 0.5)
    button_down.connect(_on_down)
    button_up.connect(_on_up)
    mouse_entered.connect(_on_hover.bind(true))
    mouse_exited.connect(_on_hover.bind(false))


func _anim(target: Vector2, time: float) -> void:
    if _tw:
        _tw.kill()
    _tw = create_tween()
    _tw.tween_property(self, "scale", target, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_down() -> void:
    if disabled:
        return
    _anim(Vector2(0.88, 0.88), 0.08)
    Sfx.play("Click", randf_range(0.95, 1.1))


func _on_up() -> void:
    _anim(Vector2.ONE, 0.3)


func _on_hover(on: bool) -> void:
    if disabled:
        return
    _anim(Vector2.ONE * (1.06 if on else 1.0), 0.18)
