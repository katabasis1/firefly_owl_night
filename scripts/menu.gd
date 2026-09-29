class_name MainMenu
extends CanvasLayer
## Главное меню: заголовок, кнопка «Играть», три страницы-главы по 10 уровней, звук.

signal level_chosen(index: int)

const CHAPTERS: Array = ["Глава 1. Ночной лес", "Глава 2. Болото", "Глава 3. Грибная поляна"]

@onready var root: Control = $Root
@onready var pages: Array[GridContainer] = [$Root/Pages/Page1 as GridContainer, $Root/Pages/Page2 as GridContainer, $Root/Pages/Page3 as GridContainer]
@onready var chapter_label: Label = $Root/ChapterLabel
@onready var prev_btn: Button = $Root/PrevBtn
@onready var next_btn: Button = $Root/NextBtn
@onready var title: Control = $Root/Title
@onready var play_btn: Button = $Root/PlayBtn
@onready var stars_label: Label = $Root/StarsLabel
@onready var sound_cross: CanvasItem = $Root/SoundBtn/Icon/Cross

var _t: float = 0.0
var _title_y: float = 0.0
var _page: int = 0


func _ready() -> void:
    _title_y = title.position.y
    play_btn.pressed.connect(func() -> void: level_chosen.emit(clampi(Progress.unlocked - 1, 0, Progress.LEVEL_COUNT - 1)))
    $Root/SoundBtn.pressed.connect(_toggle_sound)
    prev_btn.pressed.connect(func() -> void: _show_page(_page - 1, true))
    next_btn.pressed.connect(func() -> void: _show_page(_page + 1, true))
    for page: GridContainer in pages:
        for n: Node in page.get_children():
            var b: LevelButton = n as LevelButton
            b.level_chosen.connect(func(i: int) -> void: level_chosen.emit(i))
    _update_sound()


func _process(delta: float) -> void:
    if not root.visible:
        return
    _t += delta
    title.position.y = _title_y + sin(_t * 1.6) * 8.0
    title.rotation = sin(_t * 0.9) * 0.02
    play_btn.rotation = sin(_t * 3.0) * 0.025


func open() -> void:
    root.visible = true
    for page: GridContainer in pages:
        for n: Node in page.get_children():
            var b: LevelButton = n as LevelButton
            b.setup(b.level_index < Progress.unlocked, Progress.stars[b.level_index])
    stars_label.text = "%d / %d" % [Progress.total_stars(), Progress.LEVEL_COUNT * 3]
    root.modulate.a = 0.0
    var tw: Tween = create_tween()
    tw.tween_property(root, "modulate:a", 1.0, 0.35)
    # открываем главу, в которой находится последний открытый уровень
    _show_page(clampi((Progress.unlocked - 1) / 10, 0, pages.size() - 1), true)


func _show_page(p: int, animate: bool) -> void:
    _page = clampi(p, 0, pages.size() - 1)
    for k: int in pages.size():
        pages[k].visible = k == _page
    chapter_label.text = CHAPTERS[_page]
    prev_btn.disabled = _page == 0
    next_btn.disabled = _page == pages.size() - 1
    prev_btn.modulate.a = 0.35 if prev_btn.disabled else 1.0
    next_btn.modulate.a = 0.35 if next_btn.disabled else 1.0
    if not animate:
        return
    var i: int = 0
    for b: Node in pages[_page].get_children():
        var btn: Control = b as Control
        btn.scale = Vector2.ZERO
        var bt: Tween = create_tween()
        bt.tween_interval(0.1 + 0.035 * i)
        bt.tween_property(btn, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        i += 1


func close() -> void:
    var tw: Tween = create_tween()
    tw.tween_property(root, "modulate:a", 0.0, 0.25)
    tw.tween_callback(root.hide)


func _toggle_sound() -> void:
    Progress.sound_on = not Progress.sound_on
    Progress.save_data()
    Sfx.apply_sound()
    _update_sound()


func _update_sound() -> void:
    sound_cross.visible = not Progress.sound_on
