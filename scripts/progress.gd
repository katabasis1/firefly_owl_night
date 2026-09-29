extends Node
## Автозагрузка «Progress»: прогресс игрока (открытые уровни, звёзды, звук).
## Сохраняется в user:// — позже можно заменить на облачные сохранения Яндекс SDK.

const PATH := "user://save.cfg"
const LEVEL_COUNT := 30

var stars: Array[int] = []
var unlocked: int = 1
var sound_on: bool = true


func _ready() -> void:
    stars.resize(LEVEL_COUNT)
    stars.fill(0)
    load_data()


func load_data() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    if cfg.load(PATH) != OK:
        return
    unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, LEVEL_COUNT)
    sound_on = bool(cfg.get_value("progress", "sound", true))
    var saved: Array = cfg.get_value("progress", "stars", [])
    for i in mini(saved.size(), LEVEL_COUNT):
        stars[i] = int(saved[i])


func save_data() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    cfg.set_value("progress", "unlocked", unlocked)
    cfg.set_value("progress", "sound", sound_on)
    cfg.set_value("progress", "stars", Array(stars))
    cfg.save(PATH)


func complete(level: int, got: int) -> void:
    stars[level] = maxi(stars[level], got)
    unlocked = clampi(maxi(unlocked, level + 2), 1, LEVEL_COUNT)
    save_data()


func total_stars() -> int:
    var s := 0
    for v in stars:
        s += v
    return s
