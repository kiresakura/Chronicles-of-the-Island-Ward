# iOS Export 設定指引

> **狀態 2026-05-16**：Godot iOS export pipeline 通暢，能產出完整 Xcode project（440MB）；剩下卡在 Xcode 26.5 的 iOS 26.5 simulator runtime 尚未下載（runtime 安裝 != Xcode 安裝）。

## 已驗證通過的步驟

```bash
# 1. 確認 Godot 4.6.1 templates 已安裝（已完成）
ls ~/Library/Application\ Support/Godot/export_templates/4.6.1.stable/

# 2. 確認 export_presets.cfg 存在於 COTIW 根（local-only，.gitignore）
ls export_presets.cfg

# 3. 產出 Xcode project（已驗證可跑）
mkdir -p build/ios_sim
godot --headless --export-debug "iOS Simulator" build/ios_sim/cotiw
```

成功後 `build/ios_sim/` 含：

```
cotiw.xcodeproj/        # Xcode 專案
cotiw                    # Godot app source dir
cotiw.pck                # Godot pack (含遊戲資料)
cotiw.xcframework        # Godot 引擎 binary
MoltenVK.xcframework     # Vulkan-to-Metal
PrivacyInfo.xcprivacy    # Apple 隱私清單
libgodot.visionos.*.xcframework  # visionOS 預留
```

## 最後一哩（剩你做的）

### A. 安裝 iOS 26.5 simulator runtime

CLI build 失敗訊息：

```text
error: No simulator runtime version from ["23C54", "23E244", "23E254a"]
       available to use with iphonesimulator SDK version 23F73
```

意思：Xcode 26.5 自帶 iOS 26.5 SDK（23F73），但你的 simulator 只到 26.4（23E244）。

**修法（在 Xcode UI 內）**：

1. 開啟 Xcode → **Settings** (`Cmd+,`) → **Components** 分頁
2. 找「iOS 26.5 Simulator」，點 **Get**
3. 等下載完（約 7-8 GB）

或 CLI（Xcode 16+）：

```bash
xcodebuild -downloadPlatform iOS
```

### B. 在 Xcode 內 build & run

1. 開啟 Xcode：`open build/ios_sim/cotiw.xcodeproj`
2. 上方 scheme 選器 → 選一個 iOS Simulator 目標（如 iPhone 17 Pro）
3. `Cmd+R` 跑

如果 scheme 不能跑 Simulator：

- Product → Scheme → Edit Scheme → Run → Destination：選 Simulator
- 或 Product → Scheme → Manage Schemes → 新建一個 Simulator scheme

### C. CLI build（替代 Xcode UI）

iOS 26.5 simulator runtime 裝完後：

```bash
cd build/ios_sim
xcodebuild -project cotiw.xcodeproj \
  -target cotiw \
  -configuration Debug \
  -sdk iphonesimulator \
  -arch arm64 \
  build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=YES

# 產出在 build/Debug-iphonesimulator/cotiw.app
# 安裝到 simulator：
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl install booted build/Debug-iphonesimulator/cotiw.app
xcrun simctl launch booted com.kiresakura.cotiw
```

## 真機部署（Apple Developer Account 已有 B6A4N5Z3Q9）

1. iPhone 用 USB 接 Mac
2. Xcode → Window → Devices and Simulators → 註冊裝置
3. 開啟 `build/ios_sim/cotiw.xcodeproj`
4. Target cotiw → Signing & Capabilities → 勾「Automatically manage signing」、Team 選 B6A4N5Z3Q9
5. 上方 destination 選你的 iPhone → `Cmd+R`

第一次跑會被 iOS 擋（Untrusted Developer），到 iPhone Settings → General → VPN & Device Management → 信任你的 Apple ID。

## 我修的 export 障礙列表（給未來的我看）

驗證過程踩的坑（已修）：

| 錯誤 | 修法 |
|---|---|
| `Metal renderer require iOS 14+` | `application/min_ios_version=14.0` |
| `App Store Team ID not specified` | `application/app_store_team_id="B6A4N5Z3Q9"` |
| `Cannot export... configuration errors:` (空白訊息) | 開三個 privacy access_reasons (`=1`) + 加 `rendering/textures/vram_compression/import_etc2_astc=true` 到 project.godot |
| `provisioning profile required` | `application/export_project_only=true`（只出 Xcode project，不 archive） |
| `Target folder does not exist` | `mkdir -p build/ios_sim` |
| `No simulator runtime version...23F73` | **需用戶在 Xcode → Settings → Components 下載 iOS 26.5 simulator** |

## Android 部署

未測試。需要：

- Android Studio + Android SDK
- 在 Godot Editor Settings → Export → Android → 設 SDK path
- Debug keystore（一鍵生成）：

```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \
  -keystore debug.keystore -storepass android \
  -dname "CN=Android Debug,O=Android,C=US" -validity 9999 \
  -deststoretype pkcs12
```

## CI 整合

`.github/workflows/ci.yml` 已預備 ios/android build job（目前 `if: false`）。啟用流程：

1. Apple 簽署證書匯出 .p12 + provisioning profile → base64 → GH Secrets `IOS_CERT_B64`, `IOS_PP_B64`
2. Android keystore base64 → GH Secrets `ANDROID_KEYSTORE_B64`
3. 在 workflow 內 `base64 -d` 還原
4. `if: false` → `if: true`

## 風險

Xcode 26.5 + Godot 4.6.1 + iOS 26.5 simulator runtime 是「最新組合」，等 simulator runtime 裝完後若仍有問題，可選：

- 降版 Xcode 至 26.4（從 [Apple Developer Downloads](https://developer.apple.com/download/all/?q=xcode)）
- 或留 Xcode 26.5 但只跑真機（不依賴 Simulator）
- 或 Godot 降至 4.4.1（與 PRD 原指定一致）
