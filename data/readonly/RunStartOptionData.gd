# read only data for generating run start options
# each object represents either a partial option(an upside/downside) which are randomly combined, or a full self contained option
extends SerializableData
class_name RunStartOptionData

@export var run_start_option_bb_code: String = ""	# rich text when displaying this option

enum RUN_START_OPTION_TYPES {
	PARTIAL_UPSIDE,	# represents good half of an option
	PARTIAL_DOWNSIDE,	# represents bad half of an option
	COMPLETE, # is a self contained option, used for unique choices
}
@export var run_start_option_type: int = RUN_START_OPTION_TYPES.COMPLETE

@export var run_start_option_actions: Array[Dictionary] = []	# the action data to use when selecting this option

# v0.3 神示供桌（RSO 重設計）：本選項的籤詩呈現（資料驅動，鐵律 1；預設空＝向後相容）。
# 籤運統一階梯：上上 / 上吉 / 中平 / 中下 / 下下。混合卡顯示 upside 的籤、完整卡顯示自身。
@export var option_qian_name: String = ""	# 籤名（短，如 招財 / 大醮顯赫）
@export var option_qian_verse: String = ""	# 四字籤詩（如 招財進寶）
@export var option_qian_grade: String = ""	# 籤運（上上/上吉/中平/中下/下下）
