# Android Export 設定指引

> **狀態 2026-05-17**：Android export pipeline 通過。APK 產出成功（35MB signed debug）。剩下接手機 USB debug 安裝測試。

## 已驗證

```bash
godot --headless --export-debug "Android" build/android/cotiw.apk
# → SUCCESS, 35MB signed APK
```

## 一次性環境設定（已完成）

### 1. Android Studio + SDK

`~/Library/Android/sdk` 含 build-tools / platform-tools / platforms / NDK。

### 2. JDK

Android Studio 自帶 JDK 21（`/Applications/Android Studio.app/Contents/jbr/Contents/Home`），>JDK 17 OK。
系統 Java 8 不夠 Godot 4.6 Gradle build；用 Android Studio bundled。

### 3. Debug Keystore

```bash
JDK="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
KEYSTORE_DIR=~/Library/Application\ Support/Godot/keystores
mkdir -p "$KEYSTORE_DIR"
"$JDK/bin/keytool" -keyalg RSA -genkeypair -alias androiddebugkey \
  -keypass android -keystore "$KEYSTORE_DIR/debug.keystore" \
  -storepass android \
  -dname "CN=Android Debug,O=Android,C=US" \
  -validity 9999 -deststoretype pkcs12
```

### 4. Godot Editor Settings

`~/Library/Application Support/Godot/editor_settings-4.6.tres`：

```text
export/android/debug_keystore = "/Users/crimson/Library/Application Support/Godot/keystores/debug.keystore"
export/android/debug_keystore_pass = "android"
export/android/java_sdk_path = "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export/android/android_sdk_path = "/Users/crimson/Library/Android/sdk"
```

## Android Preset

寫在 `export_presets.cfg`（local-only，sample 在 `docs/export_presets_sample.cfg`）。

主要選項：

| 欄位 | 值 |
|---|---|
| name | `Android` |
| platform | `Android` |
| package/unique_name | `com.kiresakura.cotiw` |
| package/name | `鎮島錄` |
| architectures/arm64-v8a | `true` |
| screen/immersive_mode | `true` |
| version/code | `1` |
| version/name | `"0.1.0"` |

## 接 Android 手機部署流程

### 一次性手機設定

1. Android 手機 → Settings → About phone → 連點「Build number」7 下 → Developer options 啟用
2. Developer options → **USB debugging** 開啟
3. USB 接 Mac → 手機跳「Allow USB debugging from this computer?」→ Always allow
4. Mac 終端機跑：

```bash
adb devices
# 應看到：
# List of devices attached
# 1234567890ABCDEF    device
```

### 一鍵部署（推薦）

Godot Editor 內：

1. Project → Export → 選 Android preset → **One-click Deploy** 按鈕（手機接好會出現）
2. 直接 install + launch + log streaming

### CLI 部署（替代）

```bash
# 1. Build APK
godot --headless --export-debug "Android" build/android/cotiw.apk

# 2. Install to device
adb install -r build/android/cotiw.apk

# 3. Launch
adb shell am start -n com.kiresakura.cotiw/com.godot.game.GodotApp

# 4. Stream logs
adb logcat -s godot:V GodotApp:V
```

### scrcpy 鏡像螢幕（推薦給 dev）

```bash
brew install scrcpy   # 已裝
scrcpy --max-size 1080 --max-fps 60
```

接 Android 後跑 `scrcpy` 在 Mac 上看 / 操作手機螢幕，截圖 demo 用。

## 為什麼 Android 比 iOS 快

| 步驟 | iOS | Android |
|---|---|---|
| Godot export | ~30s | ~30s |
| Signing & Build | Xcode UI 手動 ~60s | 自動 jarsigner 內建 |
| Deploy to device | Xcode UI / lldb 安裝 ~60s | `adb install -r` ~10s |
| Log streaming | Xcode console / iproxy | `adb logcat` 即時 |
| **總計 per iterate** | **~3 分鐘** | **~50 秒** |

加上 Android 沒有 provisioning profile / code signing 等 Apple 行政流程。

## 已知限制

- 預設 architectures 只勾 `arm64-v8a`（現代 Android 手機）。要支援 emulator x86_64 或舊機 armeabi-v7a 自己改 preset。
- `gradle_build/use_gradle_build=false`：用 Godot 內建 apksigner，沒走完整 Gradle。如果未來要加 native plugin（IAP、Firebase 等）要切 gradle_build=true 並下 [Android Build Template](https://docs.godotengine.org/en/stable/tutorials/export/android_gradle_build.html)。

## CI 整合

`.github/workflows/ci.yml` 預備 Android build job（目前 `if: false`）。需要：

1. Debug keystore base64 → GH Secrets `ANDROID_KEYSTORE_B64`
2. 在 workflow 內 `base64 -d` 還原
3. `if: false` → `if: true`
