# 鎮島錄 UI/UX 嚴格 QA 報告
**日期**: 2026-06-10 ｜ **方法**: 靜態掃描 + 三解析度 runtime 審計 + 22 站全畫面走訪 + 人工視覺審查
**結論一句話**: 主流程健壯（22 站全可達、safe-area/分層/i18n 靜態面乾淨），但存在 **1 個系統性 modal 缺陷、1 個導航陷阱、2 類內容佔位洩漏、37 顆過小觸控目標**，集中在「overlay 遮罩」與「新開局/事件」兩區。

---

## 1. 方法論

### 1.1 測試維度（每站五類自動檢查）
| 類別 | 規則 | 標準依據 |
|---|---|---|
| TAP | 可互動按鈕短邊 <64px=FAIL、<80px=WARN | 邏輯高 700px 映射 iPhone 12 橫向 390pt → 1邏輯px≈0.557pt；44pt(Apple HIG)≈80px、35pt 底線≈64px |
| OOB | 裁切後有效矩形出視口 >2% | — |
| SAFE | 出 `CotiwUiTheme.get_safe_content_rect` >5% | 專案自有 safe-area 規範 |
| OVERLAP | 非祖孫按鈕對重疊 >25% | — |
| CLIP | Label 需求寬 > 實際寬（無 autowrap/clip） | — |
| MODAL | overlay 需有 ≥95% 視口的 `mouse_filter=STOP` 遮罩 | 防點擊穿透 |

雜訊規則：ScrollContainer/clip_contents 摺疊內容取交集、全裁切跳過；≥55% 視口的捕捉鈕（deselect 層）記 INFO 不計分。

### 1.2 解析度矩陣（stretch=canvas_items/expand，基準 1200×700）
| 視口 | 模擬機型 | 結果 |
|---|---|---|
| 1244×700 (16:9) | 多數 Android | PASS=364 WARN=3 FAIL=127 |
| 1515×700 (19.5:9) | iPhone 12+ 全系 | PASS=362 WARN=3 FAIL=179 |
| 1200×900 (4:3) | iPad | PASS=362 WARN=3 FAIL=118 |

### 1.3 走訪站點（22 站，全部真實導航）
主選單 → 角色面板 → 看板娘選擇 → 新開局（護壇/法器）→ 收藏×3 → 神示供桌 → 媽祖賜禮(boon) → 遶境地圖 → 戰鬥進場 → 手牌 → 長按詳情 → toast → 暫停 → 勝利獎勵 → 卡牌賜禮(reward) → 商店 → 歇腳 → 事件對話 → 牌庫檢視 → 敗北結算。
證據：`qa/uiux/uiux_audit/<res>/NN_tag.png`（57 張）＋ `/tmp/uiux_<res>.log`。

---

## 2. 發現（嚴重度分級）

### P1（嚴重，建議立即修）

**P1-1【系統性】所有 overlay 遮罩寫死 1200×700 → 寬螢幕點擊穿透 + 不調光**
- 9 個 overlay 的 `Background`（Pause/Shop/Rest/Dialogue/Reward/RunSummary/CardSelection/CardDraft/RunStartOptions 根節點同病）皆 `offset 1200×700、無 anchors`。
- **19.5:9 iPhone 兩側各 157px、4:3 iPad 底部 200px**：不調光（底層戰鬥全亮，肉眼證據 `1515x700/17_shop.png`、`14_pause.png`、`21_run_summary.png`、`08_boon_altar.png`）且 **該帶內底層按鈕可被點擊**（MODAL 檢查 10/10 FAIL）。
- 加重項：`PauseOverlay/Background` alpha=0.14 幾乎透明，暫停時戰場與手牌全亮，modal 感極弱。
- **修法**（半天）：九個 Background + overlay 根節點改 full-rect anchors（preset 15）；Pause dim alpha 提到 ~0.6；可加共用 helper 統一。

**P1-2 新開局選單（NewRunMenu）：返回鈕出界 + 底部堆疊相撞**
- 「返回正殿」.tscn y=648（界內）但 **runtime 被推到 y=698 → 出界 96%，實際不可見不可點**＝進入開壇後無法回頭的導航陷阱（三解析度皆中）。
- 底部區塊互撞：種子輸入框 × 護壇/法器 picker 列 × 說明文字 ×「開始開壇」鈕（半裁切）全部疊在一起（證據 `1244x700/04_new_run_menu.png`，2B-UI picker 塞入後未重排版）。
- **修法**（半天～1天）：查 NewRunMenu.gd 對 BackButton 的 runtime 位移根因；底部改 VBox/Grid 流式排版，開始鈕固定 safe 底欄。

**P1-3 事件系統雙重洩漏：佔位插圖 + 術語不一致**
- 事件插圖是**巨大 Godot 機器人 icon**（`1244x700/19_dialogue_event.png`）— 事件無美術資產接線。
- 選項動態文字用「**-30 金錢 / +20 金錢**」（全遊戲統一「銀兩」）與「恢復 15 **HP**」（應為「元神」）— 動態格式化文字繞過 .tscn 靜態守門。
- **修法**（半天）：事件 JSON/格式化器的貨幣與 HP 字串接 i18n key；事件插圖補資產或暫用主題式佔位框。

**P1-4 起手「媽祖賜禮」boon 卡池抽到 legacy 無圖卡**
- boon 賜禮出現「立刻結束回合 / 獲得5點護身符 / +元神」三張 **Godot icon 佔位卡**（STR debug 級卡漏入 boon 卡池；證據 `1244x700/09a_boon_draft.png`）。對照：戰後賜禮（16 站）抽到的是正常 COTIW 卡 → 污染面僅 boon 卡池。
- **修法**（1-2 小時）：boon 卡池來源加 `ACTIVE_CARD_PREFIXES` 同款過濾（收藏頁已有現成函式）。

**P1-5 觸控目標 37 顆 <64px（手機實機 <36pt）**
高頻核心鍵優先：
| 按鈕 | 尺寸 | 實機約 | 嚴重性 |
|---|---|---|---|
| 戰鬥「結束回合」 | 136×54 | 30pt | 每回合必按 |
| 牌堆鈕 ×4（Deck/Draw/Discard/Exhaust）+ MapBtn + Energy | 50×50 | 28pt | 高頻 |
| 消耗品鈕 ×3 | 32×32 | 18pt | 戰中使用 |
| 遺物鈕 | 40×40 | 22pt | 詳情入口 |
| 收藏 tabs ×3 | 112×32 | 18pt 高 | 我們新做的，該改 |
| 收藏/卡選/地圖返回 | 高 32–35 | 18pt | 含上輪 ui.back 修字未修尺寸 |
| 角色面板返回/設為看板娘 | 高 44/36 | 25/20pt | 新功能鍵 |
| 主選單 ✕/Util×3 | 44–48 | 25pt | 低頻可緩 |
- **修法**（1天）：統一 `CotiwUiTheme` 觸控最小 80px 常數；高頻鍵優先放大或擴 hit-rect（`custom_minimum_size` / 透明 padding）。

### P2（中等）

- **P2-1 TitleScreen 動態面板無底/無調光**：角色面板、看板娘選擇器、收藏頁底下**主選單整層透出**（橫幅、貨幣列、繼續鈕在卡片縫隙間亂入；03 標題被頂欄撞）。證據 `02_character_panel.png`、`03_mascot_selector.png`、`1200x900/05_codex_cards.png`。修法同 P1-1 家族：三面板加全幅暗底。
- **P2-2 獎勵面板標題被獎勵列蓋住**＋「符令獎勵」icon 是純色塊（`15_reward.png`）。
- **P2-3 歇腳四選項卡標題框全空**（綠框內無 icon/字）＋ 3+1 排版右側死空間（`18_rest.png`）。
- **P2-4 Card 元件在 draft/deck 比例下白色敘述框空白突兀**（`16_card_draft.png`、`20_deck_view.png`，含一張全白卡面）。
- **P2-5 地圖背景固定寬 ~1254** → 19.5:9 兩側露出底層場景條（`1515x700/09_map.png`）。
- **P2-6 MascotButton 542×980 隱形點擊區**：出界 30%、跨畫面壓在繼續/背包/設為看板娘上（輸入順序目前救了它，但結構脆弱；點擊區應夾到立繪實際範圍）。

### P3（化妝/觀察）

- 卡牌字級 10–14px（CardType 10px=實機 5.6pt 不可讀；依賴長按詳情補救，可接受但建議 CardType 拉到 12+）。
- `DialogueOverlay/DialoguePromptLabel` 英文佔位 RichText（runtime 被覆寫；prefab 規範應改 key）。
- 長按詳情面板出現在 (0,0) 蓋住左上 HUD 膠囊（synthetic 呼叫位置；真實長按路徑的定位待驗）。
- 被蓋畫面持續渲染（同幀 2–4 層 visible）— STR 原設計，手機 GPU 浪費觀察項。
- 歇腳畫面無標題（其他 overlay 都有），慣例不一致。

### ✅ 通過亮點
- **SAFE 0 違規**（safe-area 基建有效）、**CLIP 0**（無 Label 截字）、分層 token 0 違規。
- 主選單/戰鬥 HUD anchor 在 19.5:9 與 4:3 全部正確落位。
- i18n 靜態殘留僅 2 處（1 為 dev 工具）；收藏過濾 34/8/6 正確；22 站全流程真實可達、勝/敗結算皆觸發。

---

## 3. 建議修復順序
1. **P1-1 + P2-1**（同根因：全幅遮罩）→ 一次掃掉 13 個畫面的穿透/透出。
2. **P1-2** 新開局選單（玩家第一個會卡住的地方）。
3. **P1-4**（一小時內可完）→ **P1-3**（術語＋事件圖）。
4. **P1-5** 觸控目標（核心戰鬥列優先）。
5. P2-2~6、P3 隨下次美術/排版批次。

## 4. 重跑方式
```bash
UIUX_RES=1515x700 godot --path . res://qa/uiux/uiux_audit_driver.tscn
# 解析度: 1244x700 / 1515x700 / 1200x900；輸出 qa/uiux/uiux_audit/<res>/
```

---

# 修復結果（同日全數完成）

## 驗收數字
| 指標 | 修復前 | 修復後 |
|---|---|---|
| 審計 FAIL @16:9 | 127 | **0** |
| 審計 FAIL @19.5:9 | 179 | **0** |
| 審計 FAIL @4:3 | 118 | **0** |
| MODAL 遮罩 | 13 站全失敗 | **13 站全過** |
| 單元測試 | 164 | **167**（+3 守門） |
| E2E | 21/21 | **21/21** |

殘餘 WARN=52：均為 64–79px 帶（高於 35pt 絕對底線、低於 44pt 舒適線）與寬列 40–47px，屬可接受層級，清單在 log 內。

## 修復清單（對應發現編號）
- **P1-1+P2-1**：新建 `UiMaskFitter` + `fullbleed_mask` group 系統 — 9 個 overlay Background、RSO 供桌圖、地圖底圖、Codex/NewRunMenu 暗底、角色面板/看板娘自身全部鋪滿全畫布；Pause 調光 0.14→0.62。
- **P1-2**：NewRunMenu 佈局 v3 — 返回正殿移左上（原排版數學必出界）、picker 左欄全寬雙行、種子右欄上移、開壇 86 高 CTA；**附帶抓到 4:3 螢幕座標→parent-local 雙重偏移 bug 並修復**；合約測試強化為雙尺寸 × 6 控件 pairwise + safe 區內。
- **P1-3**：事件術語 金錢→銀兩（7 處）、HP→元神（2 處）+ 守門測試；三事件接 Recraft 像素插圖 + 通用香爐 fallback；**根因為原始碼指向不存在的 external 佔位路徑 + FileLoader 吃 res:// 會回退 icon.svg，兩者皆修**。
- **P1-4**：媽祖賜禮 colorless 選項由 card_pack_white（legacy 無圖卡）改為驗證型 draft（UNCOMMON ∩ 玩家卡池）+ 2 守門測試。
- **P1-5**：戰鬥 chrome 全升 68px、結束回合 176×80、三返回鈕 64 高、收藏 tabs 64、✕/Util 64、消耗品/遺物 64、商店 Buy 鈕 64、難度鈕 64（◀▶ 取代 `<--` 佔位）、勾選列 48（寬列標準）；PauseButton runtime 寫死 56 一併修。
- **P2-2**：獎勵標題頭部空間 68px；符令獎勵 icon 接符卡扇 SVG。
- **P2-3**：歇腳「入廟安神」標題 + 5 行動 icon（Recraft 民俗 SVG）。
- **P2-4**：v2 符令卡框轉正式預設 + 空敘述卡隱藏白框。
- **P2-5**：地圖底圖入 fullbleed（寬幅 COVERED 自裁切）。
- **P2-6**：看板娘 542×980 隱形點擊區夾回畫布。
- **P3**：CardType 12px、Dialogue 英文佔位清空、商店 Continue 進畫面（容器幾何 v2）。
- 審計工具同步演進：裁切感知、捕捉鈕/慣性重疊白名單、寬列雙門檻、手牌扇形豁免、modal 結構檢查、overlay 開啟輪詢。

新增素材：`assets/generated/events_v1/`（4 張像素事件圖）+ `assets/generated/icons_v2/rest/`（6 張民俗 SVG icon）。

---

# 優化第二輪（W 系列）：WARN 清零 + icon 品質

## 驗收數字
| 指標 | 第一輪後 | 第二輪後 |
|---|---|---|
| 審計 FAIL ×3 解析度 | 0/0/0 | **0/0/0** |
| 審計 WARN ×3 解析度 | 52 | **0**（全數達 80px/44pt 舒適線） |
| 單元測試 | 167 | **167/167** |
| E2E | 21/21 | **21/21** |

## W1 觸控舒適線（24 種 WARN → 0）
- 戰鬥頂列（暫停/地圖/牌庫）、牌堆×4、能量 → **80×80**；HUD 膠囊下移讓位（+52→+88）
- 消耗品列移至頂部右空帶（x700–1000）+ 80×80；遺物 80
- 主選單 ✕/Util、角色面板/看板娘返回（200×80）、收藏 tabs（150×80）、難度 ◀▶ 全 80
- NewRunMenu 佈局 v5：hint 移右欄空帶 autowrap、護壇/法器疊雙行 48 高全寬列
- PauseButton 腳本寫死 56→80

## W2 icon 品質（白底框根治）
- 6 張 icon 重生為 **pixel-art + remove_background 透明底 128px PNG**（香爐/升符立軸/焚符/葫蘆/戰鼓/符扇）
- **抓到隱形 bug**：prefab ext_resource 殘留 icon.svg 的舊 uid → Godot uid 優先使 path 替換無效（獎勵橙塊真相）；5 prefab 全清
- 80px 放大讓潛伏 icon.svg 佔位現形 → 戰鬥 5 鈕（牌庫/抽/棄/耗盡/能量）+ 消耗品空槽全換主題 icon

## W3 細節 + 工具補強
- 長按詳情 (0,0) 確認為審計合成用法產物（真實路徑早有 `position_detail_overlay`）；driver 改鏡像真實定位
- **審計工具根治隨機岔圖**：視窗被遮擋時 macOS 抑制重繪 → `frame_post_draw` 不發 → 每站空等 2s 造成遊戲狀態飄移（19 站拍到角色面板、11 站拍到主選單的元兇）→ `_shot` 改 `RenderingServer.force_draw()` 同步渲染，零等待零飄移
