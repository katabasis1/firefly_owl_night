class_name LosePanel
extends Control
## Окно проигрыша.

signal retry_pressed

@onready var dim: Control = $Dim
@onready var card: Control = $Card
@onready var reason: Label = $Card/Reason
@onready var eyes: Node2D = $Card/Eyes


func _ready() -> void:
    visible = false
    $Card/RetryBtn.pressed.connect(func() -> void: retry_pressed.emit())


func hide_panel() -> void:
    visible = false


func show_lose(text: String) -> void:
    visible = true
    reason.text = text
    dim.modulate.a = 0.0
    card.scale = Vector2.ONE * 0.5
    card.modulate.a = 0.0
    eyes.scale = Vector2(1.0, 0.05)
    var tw: Tween = create_tween()
    tw.tween_property(dim, "modulate:a", 1.0, 0.25)
    tw.parallel().tween_property(card, "modulate:a", 1.0, 0.2)
    tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(eyes, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
