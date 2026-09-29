class_name WinPanel
extends Control
## Окно победы со звёздами и конфетти.

signal next_pressed
signal retry_pressed

@onready var dim: Control = $Dim
@onready var card: Control = $Card
@onready var title: Label = $Card/Title
@onready var info: Label = $Card/Info
@onready var next_btn: Button = $Card/NextBtn
@onready var stars: Array = [$Card/Stars/S1, $Card/Stars/S2, $Card/Stars/S3]
@onready var caps: Array = [$Card/Cap1, $Card/Cap2, $Card/Cap3]
@onready var confetti: CPUParticles2D = $Confetti

const CAP_ON := Color(1.0, 0.86, 0.45)
const CAP_OFF := Color(0.5, 0.46, 0.66)


func _ready() -> void:
    visible = false
    next_btn.pressed.connect(func() -> void: next_pressed.emit())
    $Card/RetryBtn.pressed.connect(func() -> void: retry_pressed.emit())


func hide_panel() -> void:
    visible = false


## got — какие звёзды получены: [дом, вся роса, экономно].
func show_win(got: Array, dews: int, used: int, par: int, is_last: bool) -> void:
    visible = true
    title.text = "Лес пройден!" if is_last else "Светлячок дома!"
    info.text = "Роса %d/3  ·  Свет %d / %d" % [dews, used, par]
    for i in 3:
        var c: Label = caps[i]
        c.modulate = CAP_ON if got[i] else CAP_OFF
    next_btn.text = "В МЕНЮ" if is_last else "ДАЛЕЕ"
    dim.modulate.a = 0.0
    card.scale = Vector2.ONE * 0.5
    card.modulate.a = 0.0
    var tw: Tween = create_tween()
    tw.tween_property(dim, "modulate:a", 1.0, 0.25)
    tw.parallel().tween_property(card, "modulate:a", 1.0, 0.2)
    tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    for i in 3:
        var fill: Node2D = stars[i].get_node("Fill")
        fill.scale = Vector2.ZERO
    var n := 0
    for i in 3:
        if not got[i]:
            continue
        var fill: Node2D = stars[i].get_node("Fill")
        var pitch: float = 1.0 + 0.18 * n
        n += 1
        tw.tween_callback(func() -> void: Sfx.play("Star", pitch))
        tw.tween_property(fill, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    confetti.restart()
