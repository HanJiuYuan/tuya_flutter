# tuya_flutter_ha_sdk

`tuya_flutter_ha_sdk` 是一个 Flutter 插件，用于在 **iOS / Android** 上集成涂鸦（Tuya / ThingClips）Home SDK，提供：

- **用户**（登录/登出/用户信息）
- **家庭/房间**（Home / Room 管理）
- **设备配网与管理**（Wi-Fi 配网、BLE/Combo 配对、设备信息/改名/移除等）
- **摄像头（IPC）**（设备列表、能力查询、预览/直播、告警消息、保存到相册等）
- **智能门锁**（蓝牙锁/ Wi-Fi 锁部分能力）
- **Matter**（能力检测与控制）

本仓库是 **插件源码**，不是完整 Demo App（如需 Demo 可联系维护方）。

---

## 目录

- [1. 环境要求](#1-环境要求)
- [2. 安装（Flutter）](#2-安装flutter)
- [3. 平台侧接入](#3-平台侧接入)
  - [3.1 iOS](#31-ios)
  - [3.2 Android](#32-android)
- [4. 初始化（必须）](#4-初始化必须)
- [5. 快速开始（最小调用链）](#5-快速开始最小调用链)
- [6. 能力索引（按模块）](#6-能力索引按模块)
  - [6.1 用户](#61-用户)
  - [6.2 家庭/房间](#62-家庭房间)
  - [6.3 配网/配对](#63-配网配对)
  - [6.4 设备](#64-设备)
  - [6.5 门锁 / Matter](#65-门锁--matter)
  - [6.6 摄像头（IPC）](#66-摄像头ipc)
- [7. 常见问题（FAQ）](#7-常见问题faq)
- [8. 联系方式](#8-联系方式)

---

## 1. 环境要求

- **Flutter**: `>=3.3.0`
- **Dart**: `^3.7.2`
- **iOS**: `>=12.0`

---

## 2. 安装（Flutter）

在你的 App 项目 `pubspec.yaml` 中添加依赖（按你的发布方式选择其一）：

```yaml
dependencies:
  tuya_flutter_ha_sdk: ^0.0.1
```

然后执行：

```bash
flutter pub get
```

---

## 3. 平台侧接入

该插件是对 Tuya/ThingClips 原生 SDK 的封装，**iOS 需要放置 Tuya iOS SDK 文件，Android 需要配置对应依赖与初始化**。

### 3.1 iOS

1. 从 Tuya IoT 平台下载 iOS SDK 包并解压，你会得到：

- `Podfile`
- `ios_core_sdk` 目录

2. 将 `ios_core_sdk` 整个目录复制到你 App 的 `ios/` 目录下。

3. 修改你 App 的 `ios/Podfile`（关键点如下）：

```ruby
source 'https://github.com/TuyaInc/TuyaPublicSpecs.git'
source 'https://github.com/tuya/tuya-pod-specs.git'

platform :ios, '12.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

target 'Runner' do
  pod 'ThingSmartCryption', :path => 'ios_core_sdk'

  use_frameworks! :linkage => :static
end
```

4. 安装 Pods：

```bash
pod install
```

### 3.2 Android

1. `AndroidManifest.xml` 权限（按需开启，通常配网/蓝牙相关需要）：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

2. App 的 `build.gradle` 添加 Tuya/ThingClips 依赖（**版本以你实际接入的 SDK 为准**，下方只是示例占位）：

```groovy
dependencies {
  implementation "com.thingclips.smart:thingsmart:6.2.2"
  implementation platform("com.thingclips.smart:thingsmart-BizBundlesBom:6.2.16")

  implementation "com.thingclips.smart:thingsmart-bizbundle-device_activator"
  implementation "com.thingclips.smart:thingsmart-ipcsdk:6.4.2"
  implementation "com.thingclips.smart:thingsmart-lock-sdk:6.0.1"

  implementation "com.facebook.soloader:soloader:0.10.4+"
}
```

3. 混淆（`proguard-rules.pro`）建议保留规则（按你项目实际情况调整）：

```proguard
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-keep class com.alibaba.fastjson.**{*;}
-dontwarn com.alibaba.fastjson.**

-keep class com.thingclips.smart.mqttclient.mqttv3.** { *; }
-dontwarn com.thingclips.smart.mqttclient.mqttv3.**

-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

-keep class okio.** { *; }
-dontwarn okio.**

-keep class com.thingclips.**{*;}
-dontwarn com.thingclips.**

-keep class chip.** { *; }
-dontwarn chip.**
```

4. Fresco 初始化（IPC/图片相关常见依赖）：

- 在 `AndroidManifest.xml` 的 `<application>` 中指定 `android:name=".MainApplication"`
- 新增 `MainApplication.kt`（与 `MainActivity` 同包名目录）：

```kotlin
import android.app.Application
import com.facebook.drawee.backends.pipeline.Fresco

class MainApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    Fresco.initialize(this)
  }
}
```

---

## 4. 初始化（必须）

在调用任何 Tuya API 前，你必须先初始化 SDK：

```dart
import 'package:tuya_flutter_ha_sdk/tuya_flutter_ha_sdk.dart';

Future<void> initTuya() async {
  await TuyaFlutterHaSdk.tuyaSdkInit(
    androidKey: 'Your Android AppKey',
    androidSecret: 'Your Android AppSecret',
    iosKey: 'Your iOS AppKey',
    iosSecret: 'Your iOS AppSecret',
    isDebug: false,
  );
}
```

---

## 5. 快速开始（最小调用链）

一个最常见的“从 0 到控制设备/查看摄像头”的流程如下：

1. `TuyaFlutterHaSdk.tuyaSdkInit(...)`
2. `TuyaFlutterHaSdk.loginWithUid(...)`（或你项目支持的其他登录方式）
3. `TuyaFlutterHaSdk.getHomeList()` / `TuyaFlutterHaSdk.createHome(...)`
4. 选择 home 后：

- 配网：`TuyaFlutterHaSdk.getToken(homeId: ...)` + `TuyaFlutterHaSdk.startConfigWiFi(...)`
- 设备列表：`TuyaFlutterHaSdk.getHomeDevices(homeId: ...)`
- 摄像头：`TuyaFlutterHaSdk.listCameras(homeId: ...)`

---

## 6. 能力索引（按模块）

说明：插件对外主要入口为 `TuyaFlutterHaSdk`（多数为 `static` 方法）。以下仅列出常用能力，详细参数以源码定义为准。

### 6.1 用户

- `loginWithUid(countryCode, uid, password, createHome)`
- `checkLogin()`
- `getCurrentUser()`
- `userLogout()`
- `deleteAccount()`
- `updateTimeZone(timeZoneId)`
- `updateTempUnit(tempUnit)`
- `updateNickname(nickname)`
- `updateLocation(latitude, longitude)`

### 6.2 家庭/房间

- `createHome(name, geoName, rooms, latitude, longitude)`
- `getHomeList()`
- `updateHomeInfo(homeId, homeName, geoName, latitude, longitude)`
- `deleteHome(homeId)`
- `getHomeDevices(homeId)`
- `getRoomList(homeId)`
- `addRoom(homeId, roomName)`
- `removeRoom(homeId, roomId)`
- `sortRooms(homeId, roomIds)`
- `updateRoomName(homeId, roomId, roomName)`
- `addDeviceToRoom(homeId, roomId, devId)`
- `removeDeviceFromRoom(homeId, roomId, devId)`

### 6.3 配网/配对

- `getSSID()`
- `getToken(homeId)`
- `startConfigWiFi(mode, ssid, password, token)`
- `stopConfigWiFi()`
- `connectDeviceAndQueryWifiList()`
- `discoverDeviceInfo()`
- `pairBleDevice(uuid, productId, homeId, address, flag)`
- `startComboPairing(uuid, productId, homeId, ssid, password, timeout, address, flag, token, deviceType)`

### 6.4 设备

- `initDevice(devId)`
- `queryDeviceInfo(devId, dps)`
- `renameDevice(devId, name)`
- `removeDevice(devId)`
- `restoreFactoryDefaults(devId)`
- `queryDeviceWiFiStrength(devId)`
- `querySubDeviceList(devId)`

### 6.5 门锁 / Matter

- `unlockBLELock(devId)`
- `lockBLELock(devId)`
- `replyRequestUnlock(devId, open)`
- `dynamicWifiLockPassword(devId)`
- `checkIsMatter(devId)`
- `controlMatter(devId, dps)`

### 6.6 摄像头（IPC）

- `listCameras(homeId)`
- `getCameraCapabilities(deviceId)`
- `startLiveStream(deviceId)`
- `stopLiveStream(deviceId)`
- `getDeviceAlerts(deviceId, year, month)`
- `getAllMessages()`
- `registerPush(type, isOpen)`
- `saveVideoToGallery(filePath)`
- `stopSaveVideoToGallery()`
- `getDeviceDpConfigs(deviceId)`
- `setDeviceDpConfigs(deviceId, dps)`

摄像头预览渲染使用平台 View（`viewType: 'tuya_camera_view'`）：

```dart
// iOS
UiKitView(
  viewType: 'tuya_camera_view',
  creationParams: {'deviceId': deviceId},
  creationParamsCodec: const StandardMessageCodec(),
)

// Android
AndroidView(
  viewType: 'tuya_camera_view',
  creationParams: {'deviceId': deviceId},
  creationParamsCodec: const StandardMessageCodec(),
)
```

#### Android 多目分屏直播（ThingMultiCameraView）

1. **构建平台视图参数**（开启多屏能力并可选地传入视图宽度用于分割协议计算）

   ```dart
   final params = TuyaFlutterHaSdk.buildCameraViewCreationParams(
     deviceId: devId,
     enableMultiLive: true,
     cameraViewWidthPixels: MediaQuery.of(context).size.width.toInt(),
   );

   AndroidView(
     viewType: 'tuya_camera_view',
     creationParams: params,
     creationParamsCodec: const StandardMessageCodec(),
   );
   ```

2. **准备多屏直播并获取分割协议信息**

   ```dart
   final splitInfo = await TuyaFlutterHaSdk.prepareMultiLiveStream(
     devId: devId,
     widthPixels: params['cameraViewWidthPixels'] ?? 0,
   );

   if (splitInfo['support'] != true) {
     // 设备不支持分割，走普通单画面逻辑
     return;
   }
   ```

3. **根据 split_info.index 绑定渲染视图与镜头 ID**

   ```dart
   final pairs = TuyaFlutterHaSdk.buildSplitIndexPairs([0, 1, 2]);
   await TuyaFlutterHaSdk.registerVideoViewIndexPairs(
     devId: devId,
     pairs: pairs,
   );
   ```

4. **后续直播流程** 同单画面：调用 `startPreview` / `stopPreview` / `connectP2P` 等接口即可，SDK 会在底层自动完成分屏渲染。

> 注意：若 `support=true` 但 `multiViewPrepared=false`，说明当前 SDK 版本缺少 `ThingMultiCameraView`，此时保持单画面回退逻辑即可。

#### iOS 多目分屏直播（ThingSmartCameraType）

1. **创建平台视图 & ThingSmartCameraType 对象**（仍使用 `UiKitView`）：

   ```dart
   UiKitView(
     viewType: 'tuya_camera_view',
     creationParams: TuyaFlutterHaSdk.buildCameraViewCreationParams(
       deviceId: devId,
       enableMultiLive: true, // iOS 侧会根据该标记提前创建多目能力
     ),
     creationParamsCodec: const StandardMessageCodec(),
   );
   ```

   iOS 原生会在 `TuyaCameraPlatformView` 初始化时：

   - 通过 `ThingSmartCameraFactory.cameraWithP2PType:deviceId:delegate:` 创建 `ThingSmartCameraType`
   - 读取 `camera.advancedConfig.isSupportedVideoSplitting`
   - 如果支持，保持 `ThingSmartVideoViewIndexPair` 注册所需状态

2. **准备多屏直播 / 检测能力**

   ```dart
   final info = await TuyaFlutterHaSdk.prepareMultiLiveStream(devId: devId);
   if (info['support'] != true) {
     // 回退单画面
     return;
   }
   ```

   iOS 侧会在原生内部：

   - 检查 `advancedConfig.isSupportedVideoSplitting`
   - 若支持则调用 `connectWithMode:.auto` + `startPreviewWithDefinition:`（默认当前清晰度）
   - 返回 `support / connected / multiViewPrepared` 等标志

3. **绑定渲染视图与镜头 ID**

   ```dart
   final pairs = TuyaFlutterHaSdk.buildSplitIndexPairs([0, 1, 2]);
   await TuyaFlutterHaSdk.registerVideoViewIndexPairs(
     devId: devId,
     pairs: pairs,
   );
   ```

   对应原生调用 `ThingSmartCameraType` 的 `registerVideoViewIndexPairs:`，若 SDK 缺少该类将自动退回 map 形式。

4. **直播生命周期**

   - `connectWithMode:` ➜ `ThingSmartCameraDelegate.cameraDidConnected:`
   - `startPreviewWithDefinition:` ➜ `cameraDidBeginPreview:`
   - `stopPreview` ➜ `cameraDidStopPreview:`
   - `disConnect` ➜ `cameraDisconnected:specificErrorCode:`

   Flutter 侧维持原有 API（`connectP2P` / `startPreview` / `stopPreview` / `disconnectP2P`），iOS 原生内部会桥接到上述接口。

> 若 `isSupportedVideoSplitting` 为 `false`，请确认该设备产品已正确下发分割协议。否则 iOS 侧将保持单画面逻辑，`registerVideoViewIndexPairs` 会返回 `NOT_SUPPORTED`。

---

## 7. 常见问题（FAQ）

### 7.1 初始化失败/平台异常

- 确认 `TuyaFlutterHaSdk.tuyaSdkInit(...)` 在 `runApp()` 之前执行。
- 确认 AppKey / AppSecret 与平台（iOS/Android）匹配，且不包含空格。

### 7.2 iOS CocoaPods / 编译问题

- 确认已添加 Tuya 的 pods source。
- 确认 `ios_core_sdk` 路径正确且已被提交/放置到你的 App 项目中。

### 7.3 Android 找不到类 / 运行时崩溃

- 检查 `build.gradle` 依赖版本是否与 Tuya SDK 版本一致。
- 开启混淆时，确认 ProGuard 规则保留了 `com.thingclips` 等关键包。

### 7.4 Android 12+ 配网失败

- 确保 `AndroidManifest.xml` 中已添加 `BLUETOOTH_SCAN` 和 `BLUETOOTH_CONNECT` 权限。

### 7.5 Android 12+ 摄像头预览失败

- 由于涂鸦并未添加前台权限，导致 Android 摄像头预览失败。


---

## 8. 联系方式

- Email: 656213779@qq.com

---
