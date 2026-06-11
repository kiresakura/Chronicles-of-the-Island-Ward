# 鎮島錄 — 民俗 SFX / BGM 規格書（Q3 音訊全面 pass 用）
**狀態更新 2026-06-11**：BGM 四場景（主選單/地圖/戰鬥/Boss）已由 sunoapi.org（Suno V4）正式生成
→ `assets/audio/bgm/bgm_*.ogg`（OGG q3、loop=true、AudioManager 訊號中樞自動切換）。
SFX 仍為程序化佔位 — Suno 為歌曲式模型，one-shot 素材軌兩種 prompt 皆 GENERATE_AUDIO_FAILED；
正式 SFX 需 SFX 專用服務（首選 ElevenLabs sound-generation，見 QUESTIONS.md Q1-A）。

**原始狀態**：Q1 已落地程序化佔位（`assets/audio/sfx_placeholder/PLACEHOLDER_*.wav`）+ AudioManager（SFX/BGM bus、8 槽池）。
**本檔目的**：Q3 替換正式音源時的採購/生成規格；來源方案（AI 生成 / CC0 庫 / 外包）由憲龍依 QUESTIONS.md Q1-A 決議。

## 風格憲法
廟會打擊樂系：鑼、鈸、北管嗩吶短句、木魚、鞭炮、擲筊脆響。禁西式魔法 shimmer / 合成器 riser；「神聖感」用金屬泛音與空間殘響表達，不用聖歌。

## 戰鬥 SFX 清單（Q1 五顆 → 正式版規格）
| key | 演出 | 規格 | 參考 prompt（AI 生成用） |
|---|---|---|---|
| card_play | 出牌 | ≤120ms、紙質滑擦+輕拍桌 | paper talisman slap on wooden altar, short, dry |
| ward_break | 破煞 | ~250ms、陶瓷碎裂+低頻悶擊 | ceramic ward shattering + low thud, temple reverb |
| invoke | 降乩 | ~1.2s、大鑼單擊長衰減（cut-in 同步） | single large temple gong strike, long decay |
| fuhe | 合符 | ~450ms、紙燃「呼」+ 風鈴單音 | paper igniting whoosh + single wind chime ping |
| turn_end | 回合結束 | ≤150ms、木魚單擊 | single wooden fish (muyu) knock, dry |

## Q3 擴充清單（待製）
受擊（玩家/敵）、敵亡消散、抽牌、銀兩入袋、按鈕通用 tap、地圖移動腳步、節點抵達、勝利鑼鼓短句、敗北殘響、賜禮揭示、購買、歇腳入廟氛圍。

## BGM 分場景（Q3）
主選單（廟埕夜、慢板）、遶境地圖（行進鼓點）、一般戰（北管快板）、大醮 Boss（重鼓+嗩吶高亢）、勝利/敗北 stinger。Loop 點需無縫；行動裝置 OGG 96–128kbps。

## 技術約定
- 命名：`sfx_<key>.ogg` / `bgm_<scene>.ogg`；取代佔位時刪 `PLACEHOLDER_` 檔。
- 響度：SFX 峰值 -3dBFS、BGM 整體 -14 LUFS；bus 端不再補增益。
- 全部走 `AudioManager.play_sfx(key)` / 未來 `play_bgm(scene)`；程式內禁直接 new AudioStreamPlayer。
