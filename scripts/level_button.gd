class_name LevelButton
extends JuicyButton
## Кнопка выбора уровня (все 30 кнопок размещены в сцене меню вручную, по 10 на главу).

signal level_chosen(index: int)

const GOLD := Color(1.0, 0.84, 0.3)
const DIM := Color(0.3, 0.26, 0.45)

@export var level_index: int = 0


func _ready() -> void:
    super()
    pressed.connect(func() -> void: level_chosen.emit(level_index))


func setup(is_unlocked: bool, star_count: int) -> void:
    disabled = not is_unlocked
    $Num.text = str(level_index + 1)
    $Num.visible = is_unlocked
    $Lock.visible = not is_unlocked
    $Stars.visible = is_unlocked
    for i in 3:
        var s: CanvasItem = get_node("Stars/S%d" % (i + 1)) as CanvasItem
        s.modulate = GOLD if i < star_count else DIM
