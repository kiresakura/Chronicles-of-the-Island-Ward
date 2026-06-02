# 鎮島錄 UI / UX 嚴格設計審查 — 2026-05-26

> 專案：`/Users/crimson/Developer/COTIW`  
> 角色：UI 設計師 / 美術總監視角  
> 基準：Godot 4.6.1、Landscape 1200×700、Temple Neon Pixel 方向  
> 結論：方向正確，但目前仍有「加法式皮膚化」與「核心互動未完全產品化」的問題。美感已開始成形；系統性還不夠。

---

## 1. 客觀基線

### 專案狀態
- 引擎：Godot `4.6.1.stable.official.14d19694e`
- 主場景：`res://scenes/Root.tscn`
- 視窗基準：`1200×700`
- Stretch：`canvas_items + expand`
- 方向：`landscape`
- Autoload 已含 `Responsive.gd`，可作為安全區與裝置分類真相來源。

### 目前檔案規模
- `scenes`: 34 files
- `scripts`: 450 files
- `assets`: 792 files
- `docs`: 53 files
- `tests`: 16 files
- `data`: 72 files
- GDScript：274
- `.tscn`：35
- PNG：522
- SVG：113

### 測試基線
執行：

```bash
godot --headless res://tests/TestRunner.tscn
```

結果：`37 / 37 PASS`。

這點很好。至少這不是一堆憑感覺堆出來的 UI 垃圾場；它有基本回歸保護。

### Git 工作區
目前工作區已有未提交變更：

```text
M docs/AUDIT_2026-05-18.md
M scripts/ui/fx/PixelFX.gd
M scripts/ui/menus/MainMenu.gd
M scripts/ui/theme/CotiwUiTheme.gd
M scripts/ui/theme/PixelSkin.gd
M tests/README.md
M tests/unit/test_data_validation.gd
?? qa_gate1.log
?? qa_root.log
```

因此後續重構前必須先釐清這批變更是已驗收成果、實驗殘留，還是中斷工作。不要在髒工作區上盲目大改。那是把畫布丟到泥地裡再說自己在做肌理。

---

## 2. 目前優點

### 2.1 風格方向已經定得夠準
`docs/design/COTIW_UI_UX_ART_DIRECTION.md` 明確定義：

> Q 版廟會像素 × 夜市霓光 × 神壇金漆

這是對的。不是暗黑西幻，不是日式妖怪拼貼，不是 STS 換皮。這個專案真正能賣的第一眼辨識就是「台灣宮廟 + 手機卡牌」。

### 2.2 Token 化已開始落地
`CotiwUiTheme.gd` 已具備：
- `design_tokens.json` 載入
- 主要色彩 token
- 卡牌 rarity frame mapping
- map node icon mapping
- panel asset mapping
- primary / secondary button style
- focus style
- tooltip / panel style

這是正確骨架。接下來應該擴張它，而不是每個 scene 又偷寫一套 style override。

### 2.3 背景與氣氛層已經有生命
`PixelSkin.gd` + `PixelFX.gd` 是加分項：
- 主選單煙火
- 戰鬥餘燼
- 選角香煙
- 地圖薄霧
- 啟動星點
- 呼吸 shader / Ken Burns

靜態背景開始會呼吸，這比死板 mockup 好很多。

### 2.4 測試覆蓋 UI token 與資產存在性
`test_ui_theme.gd` 已驗證 semantic tokens、panel assets、mobile safe path 等。這很珍貴。UI 系統一旦 token 化，就必須被測。否則設計系統只是文檔裡的屍體。

---

## 3. 主要問題

### P0 — 戰鬥 HUD 仍像「後貼上去的裝飾」，不是玩家認知的主系統

目前 `CombatHudOverlay.gd` 採 additive CanvasLayer：
- top-left 三神明 badge
- left-bottom 八卦 energy ring
- 固定座標：`Vector2(16, 92)`、`Vector2(20, 460)`
- energy 顯示目前硬碼為 `3`
- affinity value 硬碼為 `62 / 30 / 12`

問題不是它醜。問題更嚴重：它現在像一張貼紙，不像真正綁定遊戲狀態的 HUD。

#### 必改
1. Energy ring 必須接實際 energy，不可硬碼。
2. 神明 affinity badge 必須接真實資料，至少先有 mock provider 介面。
3. 位置不可硬碼在邏輯畫布，需走 `Responsive.safe_rect` 或 safe-fit container。
4. HUD 要建立資訊優先級：HP / Block / Energy / Intent / Deity affinity 的視覺權重不能互相搶。
5. 八卦 ring 現在是方形 ColorRect + 十字，概念太粗。應改為真正圓形 / 八卦 / 符印構圖，並且在中心只放核心數字。

---

### P0 — 觸控優先仍未完全貫穿

文檔寫「最小點擊區 88×88」，`MapLocation.gd` 也固定 88×88，這很好。但其他畫面仍有風險：

- 新局選角 gallery 以透明 Button 覆蓋立繪，點擊區大但缺少明確按下回饋。
- Reward button 固定 `320×112`，但沒有明顯稀有度 / 已選 / 按下動態層級。
- Shop button 價格顏色能反映買不起，但整張商品卡的 disabled/affordance 還不夠強。
- hover / focus style 有，但手機玩家主要看到的是 pressed / selected / disabled / long-press。

#### 必改
1. 所有主要互動元件建立四態：normal / pressed / selected / disabled。
2. 觸控回饋要有微縮放、亮度、音效 hook、粒子或符紙光一種以上。
3. 長按卡牌 / 商品 / reward 必須有 detail overlay；不能依賴 hover。
4. 地圖節點不只 flash，可增加「可前往節點」的連線流光，玩家一眼知道下一步。

---

### P0 — Responsive 有 autoload，但沒有被足夠使用

`autoload/Responsive.gd` 是好東西：
- `screen_rect`
- `safe_rect`
- `screen_class`
- `fit_scale()`
- `changed` signal

但目前多數 UI 仍是固定座標、固定尺寸、固定畫布比例思維。這對手機橫向遊戲是危險的。不同 Android 比例、iPhone 動態島、iPad 4:3 都會讓固定座標開始流血。

#### 必改
1. 建立共用 `SafeFitContainer` 或 `ResponsiveLayout.gd`。
2. 所有 HUD 邊緣元素只錨定 `Responsive.safe_rect`。
3. 1200×700 只作設計基準，不應成為到處硬碼的詛咒。
4. 加測：模擬 16:9、19.5:9、4:3 三種 viewport，驗證關鍵節點落在 safe rect 內。

---

### P1 — 視覺語言有三套並存，還沒融合

目前專案同時存在：
1. STR 原始 UI 結構
2. COTIW token / panel / icon 系統
3. PixelSkin / PixelFX 背景氣氛層

這三套現在是「疊」在一起，不是完全「長」在一起。疊可以快速變美，但容易造成：
- 某些畫面很華麗，某些畫面還是 prototype。
- overlay 背景很有味道，前景按鈕像另一個遊戲。
- panel texture、StyleBoxFlat、ColorRect 填色混用，材質邏輯不統一。

#### 必改
1. 建立 `CotiwUiTheme` 的 component API：`style_reward_button()`、`style_shop_button()`、`style_hud_badge()`、`style_map_node()`。
2. Scene 內禁止散落魔法色彩與字級。全部回收進 token 或 theme API。
3. 統一 panel 語言：哪些用 SVG panel texture，哪些用 StyleBoxFlat，規則要寫死。
4. 建立「UI 元件圖鑑」測試場景，集中展示 button、panel、badge、tooltip、reward、shop item、map node。

---

### P1 — NewRunMenu 角色 gallery 概念好，但實作還像暫接

`NewRunMenu.gd` 用程式建立四角色 gallery：乩童、鸞女、道士、家將。這能快速迭代，但它目前有問題：

- 所有 layout 在 `_apply_portrait_gallery()` 中以 viewport 即時計算，缺少 resize 後重排。
- locked 角色只有灰階與「（鎖）」文字，缺少可愛的鎖定期待感。
- highlight 是半透明金色 ColorRect，太粗。選中狀態應該像神壇燈光照到角色，而不是 Excel 儲存格被選取。
- 選角資訊欄與立繪 gallery 的視覺關係需要更明確：選誰、得到什麼、如何開始。

#### 建議
1. gallery 抽成 `CharacterGallery.gd` / scene。
2. 每張角色卡使用同一個 `CharacterPortraitSlot` component。
3. 選中狀態：金色底座發光 + 香煙上升 + 名牌亮起。
4. locked 狀態：符紙封印 / 紅線 / 神像剪影，而不是單純灰掉。
5. 加入 selected character 的核心玩法 tag，例如「近戰爆發」「請神」「符咒防禦」。

---

### P1 — 地圖節點已換 icon，但路徑敘事還不夠

`MapLocation.gd` 已使用 `CotiwUiTheme.get_map_node_path()`，節點 88×88，current/reachable 用金 / 青色區分。這是正確方向。

但地圖是 roguelike card battler 的節奏骨架，不是 icon 清單。玩家需要一眼理解：
- 我在哪
- 能去哪
- 哪條路危險
- 哪條路回報高
- boss 壓迫在哪

目前只看到單點狀態，還缺「路徑作為故事」的視覺層。

#### 建議
1. 加入節點連線：未走暗線、可走青藍流光、已走金紅餘燼。
2. boss 方向增加遠景壓迫，比如虎爺 / 山霧 / 廟門陰影。
3. reachable node 的 flash 不要只是閃，要有「香火引路」方向感。
4. 地圖節點 label 「戰 / 菁 / 王 / 事」可保留，但應以 icon 為主，文字為輔。

---

### P1 — Reward / Shop 缺少商業手遊的「得到感」

Reward 和 Shop 是玩家 dopamine 的節點。現在已換 panel texture，但互動回報仍太平。

#### Reward 必須更像獎勵
- 金錢：元寶 / 香火錢視覺要跳出來。
- 卡牌：稀有度邊框、卡圖亮度、選中後吸入牌組的動畫。
- 遺物：應有小神龕展示感，而不是一個按鈕列表。

#### Shop 必須更像廟口攤位
目前 NPC quote 很好，是加分。可是商品區應該有：
- 攤位招牌
- 商品分類明確：卡 / 遺物 / 消耗品
- 買不起不只是價格橘色，而是整張商品「香火不足」封條 / 半透明暗化
- 購買成功要有銅錢聲 / 金紙光 / 商品售罄標記

---

### P2 — PixelFX 美，但需要效能與可控性

`PixelFX.gd` 很有野心，也確實讓畫面活起來。但目前 CPUParticles2D、shader、Ken Burns、煙火 manager 都在 code 中動態建立。手機上要小心。

#### 建議
1. 加入低效能模式：關閉 Ken Burns、降低粒子 amount、關閉煙火。
2. 加入設定項：`fx_quality = low / medium / high`。
3. 所有 particle amount 依 screen class / device class 調整。
4. 測試 Android 實機發熱與 FPS；不要只在 Mac 上看覺得美。

---

## 4. 優先級改造清單

### 立即做（P0，會直接影響可玩性 / 手機體驗）
1. **Combat HUD 真資料接線**：energy、deity affinity、HP / block 視覺層級整理。
2. **Responsive safe area 套用到 HUD / overlay / CTA**：避免瀏海與手勢區。
3. **互動四態規範**：normal / pressed / selected / disabled，全主要按鈕一致。
4. **Reward / Shop 可點性與回饋強化**：買不起、選中、購買成功、領取成功都要清楚。
5. **建立 UI Showcase 場景**：集中驗收元件，不要每次進遊戲才找。

### 第二波做（P1，建立質感與一致性）
1. **抽共用元件**：HUD badge、resource pill、portrait slot、reward tile、shop tile、map node wrapper。
2. **地圖路徑敘事**：連線、可走方向、已走痕跡、boss 壓迫。
3. **NewRunMenu component 化**：gallery 不要長期留在一個函式裡。
4. **Tooltip / detail overlay mobile-first**：長按、放大、行高、可讀性。
5. **統一面板材質規則**：SVG texture vs StyleBoxFlat 使用邊界明確化。

### 第三波做（P2，加分但不可先於 P0）
1. **FX quality setting**：低效能模式。
2. **音效 hook**：按鈕、購買、領獎、可走節點。
3. **微動畫庫**：符紙飄落、香火粒子、金箔閃、八卦轉動。
4. **新手引導視覺**：第一次戰鬥/地圖/獎勵提示。
5. **實機 QA checklist**：iPhone / Android / iPad 三比例。

---

## 5. 建議重構路線

### Step 1 — 不碰玩法，只建立 UI 基礎設施
- 新增 `scripts/ui/layout/SafeFitContainer.gd`
- 新增 `scripts/ui/components/`：
  - `HudBadge.gd`
  - `ResourcePill.gd`
  - `RewardTile.gd`
  - `ShopTile.gd`
  - `CharacterPortraitSlot.gd`
- 新增 `scenes/dev/UiShowcase.tscn`

### Step 2 — 戰鬥 HUD 先成為真正產品 UI
- Energy ring 接真資料
- Deity badges 接資料 source
- HP / block / intent / energy 排版重審
- 觸控與視覺權重驗收

### Step 3 — Reward / Shop dopamine polish
- 領獎動畫
- 購買動畫
- disabled / sold out 狀態
- 稀有度 / 分類視覺

### Step 4 — 地圖路徑與選角畫面
- Map path line
- CharacterGallery component
- locked character 的封印/期待感

### Step 5 — 實機效能與安全區驗收
- 16:9 / 19.5:9 / 4:3
- Android FPS / 發熱
- iPhone safe area
- iPad layout

---

## 6. 嚴格結論

鎮島錄現在不是「沒有美術方向」的問題。方向已經有了，而且是對的。

真正的問題是：

> 目前的美，很多還是貼上去的；它還沒有全部變成系統。

背景會呼吸，煙火會炸，廟會色彩也開始出來了。但戰鬥 HUD、Reward、Shop、Map、選角這些玩家真正每天碰的核心操作，還沒有完全達到商業手機遊戲該有的可讀性、回饋、狀態一致性。

下一步不要再盲目加素材。素材已經夠多了。再加下去只是把廟會變成雜貨堆。

下一步應該做的是：

1. **把 token 變成元件。**
2. **把元件變成一致互動。**
3. **把一致互動接上真資料。**
4. **把每個核心流程做出得到感與前進感。**

美不是煙火。煙火只是煙火。  
真正的美，是玩家不需要思考就知道自己在哪、能做什麼、做了之後世界如何回應他。

這專案有資格變美。現在它需要的是紀律。