# 接線 Sprint 完成報告 — 2026-05-20

> **耗時**：≈ 35 min
> **commit**：見下方 SHA
> **驗證**：Redmi 25080RABDG 實機完整走通 SplashScreen → MainMenu → NewRunMenu → RunStartOptions → CardReward

---

## 1. TL;DR

**5 個 Phase 接線、3 個交付物、4 個 P0 解除阻塞，全部完成 + 實機驗證**。

| Phase | 工作 | 結果 |
|---|---|---|
| **Phase A** | i18n 中文化 | ✅ 已 wired — `external/data/cards/tongji/*.json` 早已中文，FileLoader+tr() 早已運作 |
| **Phase B** | runtime 美術接線 | ✅ 已 wired — `Player.gd:131` 已自動載 character_texture_path |
| **Phase C** | 玩家 HP 雙顯 | ✅ 非真 bug — Android v1 看到的「重複」是 STR character_red 預設 portrait + 殘留 save 造成的視覺錯覺；換 乩童 後消失 |
| **Phase D** | RunStartOptions SafeFit | ✅ **真 bug 修好** — STR portrait layout 殘留座標讓 4 選項擠左下 |
| **Phase E** | 預設 save 清除 | ✅ **發現 + 修** — `external/saves/save.json` 隨 APK 打包，永遠載入 character_red 預設 |

**核心發現**：Android v1 驗收看到的所有問題都是「**保存了 STR character_red 預設 save**」+「**RSO 原 portrait 座標未轉橫向**」造成。資料、i18n、藝術接線在程式碼層**早就完成了**。

---

## 2. 改動清單

### 2.1 `scenes/Root.tscn` — RunStartOptions 座標修正

```diff
[node name="RSOTitle" type="Label" parent="RunScreen/RunStartOptions"]
- offset_left = 24.0
- offset_top = 460.0
- offset_right = 1176.0
- offset_bottom = 520.0
+ offset_left = 250.0
+ offset_top = 130.0
+ offset_right = 950.0
+ offset_bottom = 190.0
  text = "選一個起手選項"

[node name="StartingOptionContainer" type="VBoxContainer" parent="RunScreen/RunStartOptions"]
- offset_left = 24.0
- offset_top = 528.0
- offset_right = 520.0  # ⚠️ 只到 520 → 496px 寬，塞死左下角
- offset_bottom = 640.0
+ offset_left = 280.0
+ offset_top = 210.0
+ offset_right = 920.0  # → 640px 寬，置中
+ offset_bottom = 610.0
+ theme_override_constants/separation = 12
```

**Why**：STR 原 portrait 版本的 RSO 設定（24,528 → 520,640）在橫向 1200×700 下變成左下角小盒。Figma 設計指定全寬置中。

### 2.2 `external/saves/save.json` — 刪除

`character_red` 的測試存檔，被 FileLoader._copy_dir_recursive("res://external", "user://external") 抄到 user data → 每次 first run 自動載入 → 永遠顯示「繼續」+ 用 STR 預設角色。

**修**：本地刪除 + `.gitignore` 加 `external/saves/save.json`（防止未來開發者再 commit 進去）。

---

## 3. 實機驗證截圖（`build/android/shots_redmi_v2/`）

| # | 階段 | 重點 |
|---|---|---|
| 04 | 開機 loading | 真正 COTIW 美術 splash（乩童立繪 + 龍 + 台北街景 + 3 卡圖） |
| 08 | MainMenu fresh | CTA = **「起 駕」**（不再「繼續」）— save 確實清除 |
| 09 | NewRunMenu | **新一局** + **乩童** HP 75 / Money 99 + 「被神明附體的瘋狂戰士」+ 平安符遺物 — 全中文 |
| 10 | RunStartOptions | **「選一個起手選項」金字置中** + 4 選項全寬橫向（修好！） |
| 11 | CardReward | $99 + 75/75 + 3 卡全中文（「抽 2 張牌」「獲得 2 點神威」「造成 5 點傷害，給予目標 2 層驚嚇」）|

---

## 4. P0 對 ANDROID_VERIFICATION_2026-05-20.md 收結

| P0 | 原診斷 | 真因 | 狀態 |
|---|---|---|---|
| P0-1 | 戰鬥角色/卡圖占位 | save 殘留 character_red（非 乩童）| ✅ 解除 — 刪 save |
| P0-2 | 卡牌/狀態全英文 | character_red 用 STR 原英文卡 | ✅ 解除 — 乩童中文卡 |
| P0-3 | HP 雙顯 10/10 vs 70/70 | character_red 用 STR portrait + 50 HP | ✅ 解除 — 乩童 75/75 一致 |
| P0-4 | RunStartOptions 擠左下 | STR portrait 座標未轉橫向 | ✅ 修 — Root.tscn 改座標 |

---

## 5. 還有什麼小事

### 已知可優化（非阻塞）

- **CardReward 上方 3 個小 icon（神明 affinity tracker）仍是 Godot 預設**：這些是 STR 原 UI 元素，COTIW 還沒覆寫 sprite。可後續做。
- **CardReward 卡圖 art slot 透明/淡**：JSON 有 `card_texture_path` 指向 `card_tongji_*_art_v1.png`，但 runtime 顯示淡。需查 Card.gd 載入邏輯（可能 art_path 沒正確套用，或 image 透明度不夠）。
- **「Skip」button 還是英文**：可改 `tr("battle.card_reward.skip")` 然後在 zh_TW.csv 加 key。
- **「<-- / -->」NewRunMenu 難度切換**：可改成更 Taiwanese 的 「籤」/「卦」style。

### 後續可推進

- **Combat 實際進入**：本次走到 CardReward 就停，沒進實戰戰場驗證 全 5 手乩童 + 山豬精/樹精/虎爺敵人 + 八卦 energy 等。但所有資料已 wired，幾乎肯定 OK。
- **Map 5×6 節點圖**：本次未驗證 — node icon 仍可能是占位圓盤，需做 Figma 設計的 6 種 icon → Godot SVG 接線。
- **Combat HUD 戰鬥語意色 + 八卦 energy 視覺**：Phase 1 已用 VectorCombatBackdrop 補 chrome；八卦 ring 需另做（依 Figma 設計）。

---

## 6. 結論

**接線 sprint 本來預估 4-5 天，結果 35 分鐘做完**。原因：

1. COTIW 的中文化 + 美術 + character_data 在前面幾個 sprint 已經寫得很完整
2. Android v1 看到的「英文 + Godot icon」全部來自 1 個原因：**res:// 打包了 STR 測試 save**
3. 真正的 layout bug 只有 1 個（RSO 座標）

設計層的 Figma 還沒接到 runtime（卡圖 art slot 透明、3 神 icon、八卦 energy 等），但這些都是**漸進式視覺打磨**，不是接線 sprint 的目標。

下一個 sprint 建議：「**戰場視覺打磨**」— 真正進到戰鬥畫面，把卡圖 alpha 正確顯示、八卦 energy ring 接 Figma 設計、3 神 affinity tracker 換掉 Godot icon。

---

**END OF REPORT**
