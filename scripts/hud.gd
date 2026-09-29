class_name Hud
extends CanvasLayer
## Интерфейс во время игры.

signal menu_pressed
signal restart_pressed
signal hint_pressed

const DEW_OFF := Color(0.35, 0.4, 0.6, 0.55)

@onready var root: Control = $Root
@onready var level_label: Label = $Root/LevelLabel
@onready var ink_bar: ProgressBar = $Root/InkBar
@onready var time_label: Label = $Root/TimeLabel
@onready var hint: Label = $Root/Hint
@onready var toast: Label = $Root/Toast
@onready var dews: Array = [$Root/Dews/D1, $Root/Dews/D2, $Root/Dews/D3]
@onready var hint_btn: Button = $Root/HintBtn
@onready var par_mark: Node2D = $Root/ParMark
@onready var par_star: Node2D = $Root/ParMark/Star
@onready var frozen_label: Label = $Root/Frozen

const PAR_OFF := Color(0.5, 0.5, 0.65, 0.55)
const TIME_COLOR := Color.WHITE
const FROZEN_COLOR := Color(0.7, 1.05, 1.45)

var _par_ok := true
var _par_tw: Tween
var _frozen := 0.0

var _shown := 0
var _toast_tw: Tween
var _t := 0.0


func _ready() -> void:
    $Root/MenuBtn.pressed.connect(func() -> void: menu_pressed.emit())
    $Root/RestartBtn.pressed.connect(func() -> void: restart_pressed.emit())
    hint_btn.pressed.connect(func() -> void: hint_pressed.emit())
    hint_btn.visible = false
    toast.visible = false
    set_dews(0)


func _process(delta: float) -> void:
    _t += delta
    if hint.visible:
        hint.modulate.a = 0.75 + 0.25 * sin(_t * 3.0)
    if _par_ok and par_mark.visible:
        par_star.rotation = sin(_t * 2.0) * 0.15


func set_shown(on: bool) -> void:
    root.visible = on


func set_level(i: int) -> void:
    level_label.text = "УРОВЕНЬ %d" % (i + 1)
    level_label.pivot_offset = level_label.size * 0.5
    level_label.scale = Vector2.ONE * 1.3
    create_tween().tween_property(level_label, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## ratio — доля оставшегося света; par_ok — ещё укладываемся в норму (третья звезда).
func set_ink(ratio: float, par_ok: bool = true) -> void:
    ink_bar.value = clampf(ratio, 0.0, 1.0) * 100.0
    ink_bar.modulate = Color(1.0, 0.5, 0.5) if ratio < 0.2 else Color.WHITE
    if par_ok == _par_ok:
        return
    _par_ok = par_ok
    if _par_tw:
        _par_tw.kill()
    _par_tw = create_tween()
    if par_ok:
        par_star.scale = Vector2.ONE * 1.6
        _par_tw.tween_property(par_mark, "modulate", Color.WHITE, 0.15)
        _par_tw.parallel().tween_property(par_star, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    else:
        Sfx.play("Pop", 0.55)
        _par_tw.tween_property(par_star, "scale", Vector2.ONE * 1.5, 0.08)
        _par_tw.tween_property(par_star, "scale", Vector2.ONE * 0.8, 0.25)
        _par_tw.parallel().tween_property(par_mark, "modulate", PAR_OFF, 0.25)


## Метка нормы света на полоске (доля от запаса).
func set_par(par_ratio: float) -> void:
    par_mark.visible = par_ratio < 0.995
    par_mark.position = Vector2(
        ink_bar.position.x + ink_bar.size.x * (1.0 - clampf(par_ratio, 0.0, 1.0)),
        ink_bar.position.y + ink_bar.size.y * 0.5)
    _par_ok = true
    if _par_tw:
        _par_tw.kill()
    par_mark.modulate = Color.WHITE
    par_star.scale = Vector2.ONE


## 0 — время идёт, 1 — время остановлено.
func set_frozen(f: float) -> void:
    if is_equal_approx(f, _frozen):
        return
    _frozen = f
    time_label.modulate = TIME_COLOR.lerp(FROZEN_COLOR, f)
    frozen_label.visible = f > 0.02
    frozen_label.modulate.a = f * (0.75 + 0.25 * sin(_t * 5.0))


func set_time(t: float) -> void:
    time_label.text = "%.1f с" % t


func set_dews(n: int) -> void:
    for i in 3:
        var d: Node2D = dews[i]
        var on: bool = i < n
        d.modulate = Color.WHITE if on else DEW_OFF
        if on and i >= _shown:
            d.scale = Vector2.ONE * 1.7
            create_tween().tween_property(d, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _shown = n


func show_hint(text: String) -> void:
    hint.text = text
    hint.visible = text != ""


func hide_hint() -> void:
    hint.visible = false


func show_toast(text: String) -> void:
    toast.text = text
    toast.visible = true
    toast.pivot_offset = toast.size * 0.5
    toast.modulate.a = 0.0
    toast.scale = Vector2.ONE * 0.7
    if _toast_tw:
        _toast_tw.kill()
    _toast_tw = create_tween()
    _toast_tw.tween_property(toast, "modulate:a", 1.0, 0.15)
    _toast_tw.parallel().tween_property(toast, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _toast_tw.tween_interval(1.1)
    _toast_tw.tween_property(toast, "modulate:a", 0.0, 0.3)
    _toast_tw.tween_callback(toast.hide)


## Кнопка подсказки видна, только если у уровня есть маршрут и он ещё не открыт.
func set_hint_available(on: bool) -> void:
    hint_btn.visible = on
