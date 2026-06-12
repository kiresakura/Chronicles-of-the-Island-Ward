# 鎮島錄 Q4-A — i18n 清零守門（DELEGATION Q4「程式內中文字串清零」）。
# 掃 scripts/+autoload/ 的玩家可見中文字串字面值；豁免清單明文化（美術符號 token /
# dev 工具 / 原型）。新增玩家可見中文 → 本測試紅 → 走 CSV key。
extends "res://tests/test_case.gd"

const SCAN_DIRS: Array[String] = ["res://scripts", "res://autoload"]
## 豁免（檔級）：美術符號 token（儀法璽印字/神名縮寫字/建築 glyph）與 dev 工具
const EXEMPT_FILES: Array[String] = [
	"res://scripts/systems/ritual/RitualTags.gd",			# 拳符火鈴陣咒 — 璽印 glyph
	"res://scripts/ui/theme/CombatHudOverlay.gd",			# 媽觀爺 — 神位縮寫 token
	"res://scripts/ui/theme/CotiwUiTheme.gd",				# 金器稀奇基常 — 稀有度徽章 glyph
	"res://scripts/ui/menus/TempleScreen.gd",				# 殿虎籤市台鐘廟 — 建築 glyph（缺圖 fallback）
	"res://scripts/ui/menus/CharacterPortraitSlot.gd",		# 封 — 封印章 glyph
]
const EXEMPT_PATH_SUBSTR: Array[String] = ["prototypes", "UIComponentGallery", "dev/"]

func test_no_user_visible_chinese_literals_in_code() -> void:
	var offenders: Array[String] = []
	for dir_path: String in SCAN_DIRS:
		_scan_dir(dir_path, offenders)
	assert_eq(offenders.size(), 0,
		"程式內玩家可見中文字串應清零（走 CSV key）。違規：\n" + "\n".join(offenders))

func _scan_dir(dir_path: String, offenders: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = dir_path + "/" + entry
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_scan_dir(full, offenders)
		elif entry.ends_with(".gd"):
			_scan_file(full, offenders)
		entry = dir.get_next()
	dir.list_dir_end()

func _scan_file(path: String, offenders: Array[String]) -> void:
	if EXEMPT_FILES.has(path):
		return
	for sub: String in EXEMPT_PATH_SUBSTR:
		if path.contains(sub):
			return
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var line_no: int = 0
	var re := RegEx.create_from_string("\"[^\"]*[\\x{4e00}-\\x{9fff}][^\"]*\"")
	while not f.eof_reached():
		line_no += 1
		var line: String = f.get_line()
		var stripped: String = line.strip_edges()
		if stripped.begins_with("#"):
			continue
		# dev 輸出（log/print/警告/斷言）不屬玩家可見
		if line.contains("DebugLogger") or line.contains("print(") \
				or line.contains("push_warning") or line.contains("push_error") or line.contains("assert"):
			continue
		if re.search(line) != null:
			offenders.append("%s:%d" % [path, line_no])
