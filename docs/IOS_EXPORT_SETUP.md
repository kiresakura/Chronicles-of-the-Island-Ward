# iOS Export 設定指引

> **狀態 2026-05-16**：Godot iOS export pipeline **通暢**，能產出完整 Xcode project；Xcode build 也 **SUCCEEDED**；但 Apple Silicon Mac 上 iOS Simulator 跑不起來（Godot 4.6.1 template 限制，見下方「已知限制」）。**真機部署是務實路線**。

## 已驗證通過

```bash
# 1. Godot templates（已安裝，~1.1GB）
ls ~/Library/Application\ Support/Godot/export_templates/4.6.1.stable/

# 2. export_presets.cfg 存在於 COTIW 根（local-only，.gitignore）
ls export_presets.cfg

# 3. 產出 Xcode project（已驗證 SUCCEEDED）
mkdir -p build/ios_sim
godot --headless --export-debug "iOS Simulator" build/ios_sim/cotiw

# 4. xcodebuild build app（已驗證 BUILD SUCCEEDED，產出 cotiw.app）
xcodebuild -project build/ios_sim/cotiw.xcodeproj -target cotiw \
  -configuration Debug -sdk iphonesimulator -arch x86_64 \
  build CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES EXCLUDED_ARCHS=arm64
```

產出位置：`build/ios_sim/build/Debug-iphonesimulator/cotiw.app`

## 已知限制：Apple Silicon Mac 無法跑 iOS Simulator

Godot 4.6.1 內建 `ios.zip` 的 `libgodot.ios.debug.xcframework/ios-arm64_x86_64-simulator/libgodot.a` 雖然路徑名暗示是 fat binary，**實際只含 x86_64 slice**（用 `lipo -info` 驗證）。

Apple Silicon Mac 上的 iOS 26.x simulator runtime 是 **arm64-only**：

```text
xcrun simctl boot SIM_ID --arch=x86_64
# → Error: Requested architecture (x86_64) is not one of the
#   devices supported architectures: (arm64)
```

x86_64 build 安裝到 arm64 simulator 失敗：

```text
This app needs to be updated by the developer to work on this version of iOS.
Failed to find matching arch for input file: ...cotiw.app/cotiw
```

可能的解法：

| 方案 | 評估 |
|---|---|
| 從原始碼自編 Godot 4.6.1 iOS template (含 arm64-simulator slice) | 半天工作，需 SCons + Vulkan SDK |
| 用 Intel Mac 跑 simulator（x86_64 native） | 不切實際 |
| 改用真機（Apple Silicon Mac → iPhone 真機 arm64-arm64） | ✅ **推薦** |
| 等 Godot 後續版本修 | 不知何時 |

## ✅ 推薦路線：真機部署

你有 Apple Developer Account（Team `B6A4N5Z3Q9`），可直接跑真機。

### 一次性設定

1. iPhone 用 USB 接 Mac
2. iPhone 上：Settings → Privacy & Security → Developer Mode → 開啟
3. Mac 上 Xcode → Window → Devices and Simulators → Devices 分頁 → 看到 iPhone 出現

### 部署

1. `open build/ios_sim/cotiw.xcodeproj`
2. 點上方 Target → **Signing & Capabilities** 分頁
3. 勾「Automatically manage signing」
4. Team 選 `(B6A4N5Z3Q9)` 對應的 Apple ID
5. 上方 destination 選你的 iPhone
6. `Cmd+R`

第一次跑會被 iOS 擋 "Untrusted Developer"，到 iPhone Settings → General → VPN & Device Management → 信任你的 Apple ID → 重跑。

### CLI 部署（若 Xcode UI 嫌麻煩）

```bash
# 接上 iPhone 並信任 Mac 後
DEVICE_ID=$(xcrun xctrace list devices 2>&1 | grep -E "iPhone.*\(.*\)" | head -1 | awk -F'[()]' '{print $4}')

xcodebuild -project build/ios_sim/cotiw.xcodeproj -target cotiw \
  -configuration Debug -sdk iphoneos -arch arm64 \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=B6A4N5Z3Q9 \
  build
```

## 我修的 5 個 export 障礙（紀錄給未來的我看）

| 錯誤 | 修法 |
|---|---|
| `Metal renderer require iOS 14+` | `application/min_ios_version=14.0` |
| `App Store Team ID not specified` | `application/app_store_team_id="B6A4N5Z3Q9"` |
| `configuration errors:`（空白訊息） | 3 個 `privacy/*_access_reasons=1` + `project.godot` 加 `import_etc2_astc=true` |
| `provisioning profile required` | `application/export_project_only=true` |
| `App is iPad-only but device is iPhone` | `application/targeted_device_family=2`（Universal） |

驗證跑通的指令：

```bash
godot --headless --export-debug "iOS Simulator" build/ios_sim/cotiw
# → SUCCESS

xcodebuild -project build/ios_sim/cotiw.xcodeproj -target cotiw \
  -configuration Debug -sdk iphonesimulator -arch x86_64 \
  build CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES EXCLUDED_ARCHS=arm64
# → BUILD SUCCEEDED
```

## 接下來

1. **真機跑通 STR 預設範例**（Sprint 0 驗收條件之一）→ 接 iPhone Cmd+R
2. **回到 Sprint 1 收尾**：寫 act_1、event_pool 等資料讓 run 可從新一局跑通一場山豬精戰鬥
3. **Android 部署**未測試（見下節）

## Android 部署

需要：

- Android Studio + Android SDK
- 在 Godot Editor Settings → Export → Android → 設 SDK path
- Debug keystore：

```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \
  -keystore debug.keystore -storepass android \
  -dname "CN=Android Debug,O=Android,C=US" -validity 9999 \
  -deststoretype pkcs12
```

## CI 整合

`.github/workflows/ci.yml` 預備 ios/android build job（目前 `if: false`）。啟用流程：

1. Apple 簽署 .p12 + provisioning profile → base64 → GH Secrets
2. Android keystore base64 → GH Secrets
3. `if: false` → `if: true`
