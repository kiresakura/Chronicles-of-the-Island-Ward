extends PrototypeData
class_name NewRunCopyBudgetData

# 鎮島錄 — 新一局／開壇設定畫面「文案長度預算」（鐵律 1：杜絕正文截斷的源頭）。
#
# 為何存在：開壇畫面的英雄面板/平安符/標籤有固定可視寬高。若 JSON/CSV 文案
# 超過版面能無截斷顯示的上限，runtime 會被切字。本資料把「各文案的最大長度」
# 變成可驗收的數字，並由 test_new_run_copy_schema 在 CI 強制——超長即 fail，
# 從源頭擋下截斷，而非事後目視抓漏。
#
# schema 樣本：external/data/ui/new_run_copy_budget.json
# 載入/查詢：scripts/systems/ritual/RitualCopyBudget.gd（靜態，沿 FortuneSticks 慣例）
# 數字依英雄面板實際可視區換算（見 RitualCopyBudget 註記），調版面時兩處同步。

## 角色「一句定位」（tagline，英雄面板姓名下單行，不換行）
@export var max_tagline: int = 18
## 角色描述（character_description / locked_copy，英雄面板正文，可換行多行）
@export var max_description: int = 60
## 平安符（起手法器）說明（英雄面板法器列正文，可換行）
@export var max_artifact_description: int = 64
## 單一特性標籤字數（標籤膠囊不換行）
@export var max_tag_length: int = 6
## 特性標籤數量（目標設計：3 個）
@export var max_tag_count: int = 3
## build_hint（開局指引一行，autowrap）
@export var max_build_hint: int = 44
