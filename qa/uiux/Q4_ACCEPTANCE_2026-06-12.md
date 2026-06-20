# Q4 驗收包 — 上架就緒技術輪（2026-06-12）

範圍：Q4-A〜E 完成；Q4-F 真機矩陣 🔴 等 QUESTIONS Q4-D 設備清單。
本包先以「模擬器口徑」回答 Q4-G 四問，真機列待 F 解鎖後同表補填。

## 交付清單

| 項 | 內容 | Commit | 狀態 |
|---|---|---|---|
| Q4-A | i18n 清零：246 key × 四語 CSV、零殘留 gate 測試 | （前輪） | ✅ |
| 修復 | 實機回報：開機 BGM 起點 + iOS 靜音鍵（Playback）+ 幽靈 ✕ | ae559d7 | ✅ |
| Q4-B | 進度檔 AES-256 加密 + 舊明文無縫遷移 + 毀損安全 | a8b59eb | ✅ |
| Q4-C | IAP 管線：平台抽象/沙盒假層/資料驅動商品表/紅線白名單 | 2404f19 | ✅ |
| Q4-D | 雲端存檔：iCloud KV 語意 + LWW 對帳 + save 上雲鉤 | 3b3d889 | ✅ |
| Q4-E | 效能 pass：死資產歸檔 + 靶向 VRAM 壓縮 + 量測探針 | 56a08dc | ✅ |
| 基建 | iOS sim 建置打通（自編 arm64-sim libgodot，模板已修補） | — | ✅ |

## Q4-E 量測（M4 Pro 桌面口徑；qa/perf 探針）

| 指標 | 前 | 後 | Δ |
|---|---|---|---|
| pck 體積 | 268.7 MB | **202.5 MB** | -25% |
| 主選單紋理記憶體 | 542 MB | **247.7 MB** | -54% |
| video mem | 559 MB | 264 MB | -53% |
| draw calls（主選單） | 87 | 87 | 持平（健康） |
| boot→可互動 | ~1.2s | **0.97s** | 略快 |

關鍵取捨：全面 VRAM 壓縮會讓 pck 反漲 +127MB（像素風 PNG 磁碟壓縮率遠勝
固定 bpp 紋理塊）→ 靶向僅壓 76 檔常駐集（.tscn/preload/const ≥700px）。
S3TC/ETC2 視覺抽查（主選單放大）無塊狀痕。死資產 160MB 入 art_archive/
（.gdignore + git mv 保歷史；逐目錄零引用驗證，動態拼接目錄全保留）。

## Q4-G 四問（模擬器口徑）

1. **裝得起來？** ✅ iPhone 17 Pro sim（iOS 26.2）build_run_sim 14s 裝起。
   ⚠️ 地雷已除：Godot 4.6.1〜4.6.3 官方模板 sim 庫缺 arm64（#118161）—
   已自編並修補本機模板；換機開發需重做（見 cotiw_ios_sim_build 備忘）。
2. **玩得動？** ✅ E2E 21/21（含戰鬥輪迴）；主選單 60fps、截圖完好。
3. **買得了（沙盒）？** ✅ FakeIAPProvider 全管線 unit 7/7（授與/防重複/
   拒付零授與/restore 冪等/紅線拒斥）。真機 StoreKit 沙盒待 Q4-F。
4. **續得了檔？** ✅ 加密 round-trip + 舊檔遷移實證（本輪 profile.json
   明文→GDEC 自動轉換）+ 雲端 LWW 對帳 6 測全綠。

## 八基準自評（DELEGATION §4）

| # | 基準 | 評 | 註 |
|---|---|---|---|
| Q-1 | 鐵律遵循 | 5/5 | 數值/商品全在 JSON；fork-first；佔位 SFX 仍明顯醜 |
| Q-2 | 情緒峰值 | N/A | 本輪純技術；演出零變動（audit 0F 佐證） |
| Q-3 | 手機可用性 | 5/5 | 記憶體 -54% 直接降老機 jetsam；觸控/版面 audit 全綠 |
| Q-4 | 美術一致性 | 4/5 | 壓縮抽查無痕；保守扣 1 待真機目視 |
| Q-5 | 文案語感 | 5/5 | 新字串全走 key（i18n gate 鎖死） |
| Q-6 | 測試紀律 | 5/5 | 244 unit / 21 E2E / audit 0F×2；log 契約乾淨 |
| Q-7 | 效能預算 | 4/5 | pck 202MB 仍高於 150MB 理想線（BGM/大圖下一刀在 Q3-C 正式音源 + 卡圖降採樣，留待美術定稿後） |
| Q-8 | 可回退性 | 5/5 | 歸檔可逆（git mv）；加密向下相容明文；雲端 unavailable 即單機 |

## 🔴 待憲龍（QUESTIONS）

- Q3-A ElevenLabs key → Q3-C SFX 正式音源（規格表備妥，當日可換）
- Q4-A IAP 結構定案 → 汰換 4 件測試佔位商品
- Q4-D 真機設備清單 + TestFlight 帳號 → Q4-F（Team ID B6A4N5Z3Q9 已備）
- Q3-F 合符經濟（建議維持免費 — 模擬數據已報）
