你是第二視角 UI/UX QA reviewer。請只閱讀與分析，不要修改任何檔案。

專案：/Users/crimson/Developer/COTIW
任務：針對 COTIW 手機遊戲 UI/UX 進行嚴謹第二視角審查，目標是找出會讓玩家覺得像「殺戮尖塔換皮」或手機體驗不順的問題。

請重點檢查：
1. 啟動 / splash / main menu flow
2. new run / character selection / loadout
3. combat HUD / 手牌 / 觸控 / 長按合符
4. map / reward / shop overlays
5. overlay lifecycle、CanvasLayer、visibility、safe area、固定座標風險
6. Android/mobile 16:9、20:9、平板、notch/safe area、觸控尺寸、可讀性
7. 是否強化「儀式編排型 roguelike 卡牌手遊」而非 STS clone

已知測試結果：
- Godot 4.6.1 headless import 成功。
- TestRunner：138 / 139 通過；唯一失敗 test_data_validation.gd::test_cotiw_character_roster_matches_expected，因角色表預期 2 但實際 4，出現 character_daoshi / character_jiajiang。
- Root/Gate1Prototype/UIComponentGallery headless smoke exit 0。
- Android export-debug 成功，APK 簽署成功。
- adb install/launch 因 emulator ADB closed 失敗；截圖顯示 emulator 正在其他遊戲畫面，不是 COTIW。

請輸出繁體中文 Markdown，格式：
# Claude 第二視角 UI/UX QA
## 摘要
## Critical/Major/Minor 缺陷清單
每個缺陷包含：嚴重度、位置、證據、玩家影響、建議修正、建議驗收測試。
## 產品差異化建議
## 優先修正順序
