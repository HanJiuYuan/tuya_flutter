# Tuya Flutter Plugin - iOS and Android Integration Guide

This comprehensive guide will assist you in quickly setting up and utilizing the Tuya Flutter plugin within your Flutter-based iOS or Android application.

---
## 📑 Table of Contents

- [1. Provisioning](#1-provisioning)
    - [1.1 SDK Installation](#11-sdk-installation)
        - [1.1.1 iOS installation steps](#111-ios-installation-steps)
        - [1.1.2 Android installation steps](#112-android-installation-steps)
- [2. SDK Initialization](#2-sdk-initialization)
- [3. User Management](#3-user-management)
- [4. Home Management](#4-home-management)
- [5. Device Pairing](#5-device-pairing)
- [6. Device Control](#6-device-control)
- [7. Room Management](#7-room-management)
- [8. Lock Devices](#8-lock-devices)
- [9. Cameras and IPC](#9-cameras-and-ipc)
- [📬 Contact Us](#-contact-us)
- [📜 License](#-license)

---

## 1. Provisioning

### 1.1 SDK Installation

#### 1.1.1 iOS installation steps

1. **Download the Tuya SDK**: Visit your Tuya Platform Development page, download, and unzip the provided Tuya SDK package.

2. **Unzip Contents**: After extraction, you'll find a `Podfile` and a directory named `ios_core_sdk`.

3. **Copy SDK Files**: Place the entire `ios_core_sdk` directory into your Flutter project's `ios` directory.

4. **Update Podfile**: Modify your `Podfile` in the `ios` directory as follows:

```ruby
# source 'https://github.com/CocoaPods/Specs.git'
# Add Tuya sources below after the default line
source 'https://github.com/TuyaInc/TuyaPublicSpecs.git'
source 'https://github.com/tuya/tuya-pod-specs.git'

# Set the platform version as required by Tuya
platform :ios, '12.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# In your "target 'Runner' do" block, add the following line
pod 'ThingSmartCryption', :path => 'ios_core_sdk'

# Adjust your frameworks settings as below:
use_frameworks! :linkage => :static
#use_frameworks!
#use_modular_headers!
```

5. **Update pubspec.yaml**: Add the Tuya Flutter plugin to your `pubspec.yaml` under dev dependencies:

```yaml
dependencies:
  tuya_flutter_ha_sdk: latest_version
```

6. **Install Flutter Dependencies**:

Run either:
```shell
flutter pub get
```

or
```shell
flutter clean && flutter pub get
```

7. **Install or Update Pods**:

Navigate to your `ios` directory and execute:
```shell
pod install
```

#### Common Issues
- **Apple Silicon (arm64)**: Ensure compatibility by explicitly setting architecture if needed.


#### 1.1.2 Android Installation steps

1. **Add the following permissions to `AndroidManifest.xml` (Optional, as needed)**:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

2. **Update `build.gradle`**:

```groovy

dependencies {
  // Tuya Home SDK Core (ensure version matches your downloaded SDK, e.g., 6.2.2)
  implementation "com.thingclips.smart:thingsmart:6.2.2"

  // Tuya BizBundles BOM (aligns all BizBundles to version 6.2.16)
  implementation platform("com.thingclips.smart:thingsmart-BizBundlesBom:6.2.16")

  implementation 'com.thingclips.smart:thingsmart-ipcsdk:6.4.2'
  // Example BizBundle: Device Activator
  implementation "com.thingclips.smart:thingsmart-bizbundle-device_activator"

  implementation "com.thingclips.smart:thingsmart-lock-sdk:6.0.1"

  // SoLoader (required by Tuya SDK)
  implementation "com.facebook.soloader:soloader:0.10.4+"
}
```

3. **Add ProGuard Rules**:

Add the following rules to your `proguard-rules.pro` file:

```proguard
## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings

#fastJson
-keep class com.alibaba.fastjson.**{*;}
-dontwarn com.alibaba.fastjson.**

#mqtt
-keep class com.thingclips.smart.mqttclient.mqttv3.** { *; }
-dontwarn com.thingclips.smart.mqttclient.mqttv3.**

#OkHttp3
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

-keep class okio.** { *; }
-dontwarn okio.**

-keep class com.thingclips.**{*;}
-dontwarn com.thingclips.**

# Matter SDK
-keep class chip.** { *; }
-dontwarn chip.**
```

4. **Update AndroidManifest.xml**

```groovy
<application
android:name=".MainApplication"
```

5. **Add MainApplication.kt file**

In the same folder as MainActivity.kt add a new file MainApplication.kt and include the below code

```kotlin
package ******

import android.app.Application
        import com.facebook.drawee.backends.pipeline.Fresco

class MainApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    Fresco.initialize(this)
  }
}
```

6. **Update pubspec.yaml**: Add the Tuya Flutter plugin to your `pubspec.yaml` under dev dependencies:

```yaml
dependencies:
  tuya_flutter_ha_sdk: latest_version
```

7. **Install Flutter Dependencies**:

Run either:
```shell
flutter pub get
```

or
```shell
flutter clean && flutter pub get
```
### 2 SDK Initialization

1. **Create Tuya Configuration File**:

Create a Dart file (`tuya_config.dart`) to securely store your credentials:

```dart
class TuyaConfig {
  static const String androidAppKey = 'Your Android AppKey';
  static const String androidAppSecret = 'Your Android AppSecret';

  static const String iosAppKey = 'Your iOS AppKey';
  static const String iosAppSecret = 'Your iOS AppSecret';
}
```

2. **Initialize Tuya in Flutter**:

In your `main.dart` file:

```dart
import 'package:tuya_flutter_ha_sdk/tuya_flutter_ha_sdk.dart';
import 'path/to/tuya_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await TuyaFlutterHaSdk.tuyaSdkInit(
      androidKey: TuyaConfig.androidAppKey,
      androidSecret: TuyaConfig.androidAppSecret,
      iosKey: TuyaConfig.iosAppKey,
      iosSecret: TuyaConfig.iosAppSecret,
    );
    print('✅ Tuya SDK initialization succeeded');
  } catch (e, stack) {
    print('⛔ Tuya SDK initialization failed: $e');
    print(stack);
  }

  runApp(MyApp());
}
```

---

## 3. User Management

This section covers various methods of user management within the Tuya Flutter SDK.

### 3.2 Login/Register with UID

This method is ideal if you already have a user authentication system and prefer not to use Tuya's default registration and OTP flows. It automatically detects if a user is registered—if they are, it logs them in; if not, it registers them and then logs them in.

#### Sample Request

Here's how to implement this in your Flutter app:

**File:** `lib/login_reg_w_uid.dart`

```dart
final Map<String, dynamic> loginResult = await TuyaFlutterHaSdk.loginWithUid(
  countryCode: countryCode,
  uid: uid,
  password: password,
  createHome: createHome, //optional
);

print("✅ loginWithUid succeeded: $loginResult");
```

#### Example Successful Response

Below is an example response with masked sensitive values to illustrate structure:

```json
{
  "uid": {
    "timezoneId": "xxx/xxx",
    "attribute": xxx,
    "extras": {"developer": x, "enableLangDebug": x},
    "uid": "xxx",
    "regFrom": x,
    "sex": x,
    "ecode": "xxx",
    "snsNickname": "xxx",
    "domain": {
      "mobileMediaMqttUrl": "xxx",
      "mqttPort": xxx,
      "mqttsPskPort": xxx,
      "thingAppUrl": "xxx",
      "mobileMqttsUrl": "xxx",
      "gwApiUrl": "xxx",
      "mobileMqttUrl": "xxx",
      "mqttQuicUrl": "xxx",
      "mqttsPort": xxx,
      "mobileApiUrl": "xxx",
      "aispeechQuicUrl": "xxx",
      "deviceHttpsPskUrl": "xxx",
      "httpsPskPort": xxx,
      "regionCode": "xx",
      "gwMqttUrl": "xxx",
      "tuyaImagesUrl": "xxx",
      "httpsPort": xxx,
      "mobileQuicUrl": "xxx",
      "httpPort": xxx,
      "aispeechHttpsUrl": "xxx",
      "tuyaAppUrl": "xxx",
      "fusionUrl": "xxx",
      "thingImagesUrl": "xxx"
    }
  }
}
```

**Note:** The exact response structure may vary depending on your plugin support level.
**Note:** The SDK manages both the session access token and the refresh token.

#### Common Errors

- **Invalid Credentials:** Ensure the UID, country code, and password provided are correct.
- **Network Issues:** Check your internet connectivity and API endpoints.
- **Platform Exceptions:** Typically indicate issues with SDK integration or compatibility. Check logs for detailed error messages.

Always verify your SDK and plugin versions are compatible with Tuya's current API standards.

### 3.2 Check Login Status

This method checks whether a user session is currently active in the Tuya SDK. It returns a boolean indicating login state.

#### Sample Request

```dart
final bool isLoggedIn = await TuyaFlutterHaSdk.checkLogin();
print("Login status: $isLoggedIn");
```

#### Example Successful Response
```json
true
```

### 3.3 Get Current User Details

Retrieves all available properties of the currently logged-in user. If no user is logged in, this method throws a PlatformException with code "NO_USER".

#### Sample Request

```dart
try {
  final Map<String, dynamic> userInfo = await TuyaFlutterHaSdk.getCurrentUser();
  print("User Info: $userInfo");
} on PlatformException catch (e) {
  print("Error fetching user details: ${e.code} - ${e.message}");
}
```

#### Example Successful Response

```json
{
  "regionCode": "AZ",
  "userName": "54",
  "uid": "az1749154162012Vnfju",
  "phoneNumber": "",
  "email": "",
  "countryCode": "1",
  "tempUnit": 2,
  "timezoneId": "America/Chicago",
  "regFrom": 2,
  "headIconUrl": "",
  "snsNickname": ""
}
```

#### Common Errors

- **NO_USER:** PlatformException(code: "NO_USER", message: "No user is currently logged in", details: null)
- **PlatformException** CMay occur due to plugin integration issues. Inspect e.code and e.message for specifics.

#### 3.4 Logout

Logout the current user

#### Sample Request

```dart
try {
  await TuyaFlutterHaSdk.userLogout();
  print("RESPONSE userLogout -> success");
} on PlatformException catch (e) {
  print("ERROR userLogout PlatformException -> code=${e.code}, message=${e.message}");
} catch (e) {
  print("ERROR userLogout Unexpected -> $e");
}
```

#### 3.5 Delete Account

Delete a given user account

#### Sample Request

```dart
try {
      await TuyaFlutterHaSdk.deleteAccount();
      print("RESPONSE deleteAccount -> success");
    } on PlatformException catch (e) {
      print("ERROR deleteAccount PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("ERROR deleteAccount Unexpected -> $e");
    }
```

#### 3.6 Update TimeZone

Update timezone for the given user

```dart
try {
      await TuyaFlutterHaSdk.updateTimeZone(timeZoneId: _timeZoneId.text);
      print("RESPONSE updateTimeZone -> success");
    } on PlatformException catch (e) {
      print("ERROR updateTimeZone PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("ERROR updateTimeZone Unexpected -> $e");
    }
```

#### 3.7 Update Temp Unit

Update the temperature unit for the current user

```dart
try {
      await TuyaFlutterHaSdk.updateTempUnit(tempUnit: int.parse(_tempUnit.text));
      print("RESPONSE updateTempUnit -> success");
    } on PlatformException catch (e) {
      print("ERROR updateTempUnit PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("ERROR updateTempUnit Unexpected -> $e");
    }
```

#### 3.8 Update Nick Name

Update the nick name of the current user
```dart
try {
      await TuyaFlutterHaSdk.updateNickname(nickname: _nickName.text);
      print("RESPONSE updateNickname -> success");
    } on PlatformException catch (e) {
      print("ERROR updateNickname PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("ERROR updateNickname Unexpected -> $e");
    }
```

#### 3.9 Update Location

Update location of the current user

```dart
try {
      await TuyaFlutterHaSdk.updateLocation(latitude: lat,longitude: lng);
      print("RESPONSE updateLocation -> success");
    } on PlatformException catch (e) {
      print("ERROR updateLocation PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("ERROR updateLocation Unexpected -> $e");
    }
```


---

## 4. Home Management

This section covers home creation, update, listing, and deletion features provided by the Tuya Flutter SDK.

#### 4.1 Create Home

Create a new home for the current user

```dart
try {
      final homeId = await TuyaFlutterHaSdk.createHome(
        name: _name.text,
        geoName: _geoName.text,
        rooms: [_rooms.text],
        latitude: double.parse(_latitude.text),
        longitude: double.parse(_longitude.text),
      );
      print("← createHome SUCCESS: homeId=$homeId and rooms=${_rooms.text}");
    } on PlatformException catch (e) {
      print("ERROR createHome PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ createHome FAILED: $e");
    }
```

#### 4.2 Get List of homes

Get list of all homes for the current user

```dart
try {
      final homes = await TuyaFlutterHaSdk.getHomeList();
      print("RESPONSE getHomeList -> $homes");
    } on PlatformException catch (e) {
      print("ERROR getHomeList PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ getHomeList FAILED: $e");
    }
```

#### 4.3 Update Home

Update details of a selected home

```dart
try {
      await TuyaFlutterHaSdk.updateHomeInfo(
        homeId: int.parse(_homeId.text),
        homeName: _homeName.text,
        geoName: _geoNameNew.text,
        latitude: double.parse(_latitudeNew.text),
        longitude: double.parse(_longitudeNew.text),
      );
      print("RESPONSE updateHomeInfo -> success");
    } on PlatformException catch (e) {
      print("ERROR updateHomeInfo PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ updateHomeInfo FAILED: $e");
    }
```

#### 4.4 Delete home

Delete a selected home

```dart
try {
      await TuyaFlutterHaSdk.deleteHome(homeId: int.parse(_deleteHomeId.text));
      print("RESPONSE deleteHome -> success");
    } on PlatformException catch (e) {
      print("ERROR deleteHome PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ deleteHome FAILED: $e");
    }
```

#### 4.5 Home devices

Get a list of devices for a selected home

```dart
try {
      final devices = await TuyaFlutterHaSdk.getHomeDevices(homeId: int.parse(_devicesHomeId.text));
      print("RESPONSE getHomeDevices -> $devices");
      for (final d in devices) {
        print("Device: $d");
      }
    } on PlatformException catch (e) {
      print("ERROR getHomeDevices PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ getHomeDevices FAILED: $e");
    }
```

#### 4.6 Get SSID

Get the SSID of the connected network

```dart
try {
      final ssid = await TuyaFlutterHaSdk.getSSID();
      print("← getSSID SUCCESS: ssid=$ssid ");
    } on PlatformException catch (e) {
      print("ERROR getSSID PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ getSSID FAILED: $e");
    }
```

#### 4.7 Get Token

Get Token for the selected home

```dart
try {
     final token = await TuyaFlutterHaSdk.getToken(homeId: int.parse(_homeId.text));
     print("← getToken SUCCESS: ssid=$token ");
   } on PlatformException catch (e) {
     print("ERROR getToken PlatformException -> code=${e.code}, message=${e.message}");
   } catch (e) {
     print("⛔ getToken FAILED: $e");
   }
```

----

## 5. Device Pairing

This section covers device pairing and configuration features provided by the Tuya Flutter SDK.

#### 5.1 Start Wifi Config

Start the configuration of Wifi device

```dart
try {
     await TuyaFlutterHaSdk.startConfigWiFi(mode: _mode.text,ssid: _ssid.text,password: _password.text,token: _token.text);
     print("← startConfigWiFi SUCCESS ");
   } on PlatformException catch (e) {
     print("ERROR startConfigWiFi PlatformException -> code=${e.code}, message=${e.message}");
   } catch (e) {
     print("⛔ startConfigWiFi FAILED: $e");
   }
```

#### 5.2 Stop Wifi Config

Stop configuration of Wifi device

```dart
try {
     await TuyaFlutterHaSdk.stopConfigWiFi();
     print("← stopConfigWiFi SUCCESS");
   } on PlatformException catch (e) {
     print("ERROR stopConfigWiFi PlatformException -> code=${e.code}, message=${e.message}");
   } catch (e) {
     print("⛔ stopConfigWiFi FAILED: $e");
   }
```

#### 5.3 Device Wifi List

Connect to device and get Wifi List

```dart
try {
      await TuyaFlutterHaSdk.connectDeviceAndQueryWifiList();
      print("← connectDeviceAndQueryWifiList SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR connectDeviceAndQueryWifiList PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ connectDeviceAndQueryWifiList FAILED: $e");
    }
```

#### 5.4 Scan for devices

Scan and show details of all available devices

```dart
try {
      await TuyaFlutterHaSdk.discoverDeviceInfo();
      print("← discoverDeviceInfo SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR discoverDeviceInfo PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ discoverDeviceInfo FAILED: $e");
    }
```

#### 5.5 Pair BLE device

Pair a BLE device available through scan device

```dart
case TuyaPairingType.bleOnly:
    TuyaFlutterHaSdk.pairBleDevice(
        uuid: uuid,
        productId: pid,
        homeId: usedHomeId,
        address: address,
        flag: flag,
    );
  
```

#### 5.6 Pair Combo device

Pair a BLE device available through scan device

```dart
case TuyaPairingType.comboBleWifi:
  TuyaFlutterHaSdk.startComboPairing(
      uuid: uuid,
      productId: pid,
      homeId: usedHomeId,
      ssid: usedSsid,
      password: usedPassword,
      timeout: 120,
      address: address,
      flag: flag,
      token: token,
      deviceType: device['deviceType'] ?? 0,
  );
```

## 6 Device Control

This section covers the device control features provided by Tuya SDK

#### 6.1 Initialize Device

Intialize the given device

```dart
try {
      await TuyaFlutterHaSdk.initDevice(devId: _devId.text);
      print("← initDevice SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR initDevice PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ initDevice FAILED: $e");
    }
```

#### 6.2 Get device Info

Get details of the given device

```dart
try {
      final deviceDetails=await TuyaFlutterHaSdk.queryDeviceInfo(devId: _devId.text,dps: [_devDps.text]);
      print("← queryDeviceInfo SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR queryDeviceInfo PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ queryDeviceInfo FAILED: $e");
    }
```

#### 6.3 Rename Device

Change the name of the given device

```dart
try {
      await TuyaFlutterHaSdk.renameDevice(devId: _devId.text, name: _devNewName.text);
      print("← renameDevice SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR renameDevice PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ renameDevice FAILED: $e");
    }
```

#### 6.4 Remove device

Remove the device from the users device list

```dart
try {
      await TuyaFlutterHaSdk.removeDevice(devId: _devId.text);
      print("← removeDevice SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR removeDevice PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ removeDevice FAILED: $e");
    }
```

#### 6.5 Restore defaults

Restore the default settings of a device

```dart
try {
      await TuyaFlutterHaSdk.restoreFactoryDefaults(devId: _devId.text);
      print("← restoreFactoryDefaults SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR restoreFactoryDefaults PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ restoreFactoryDefaults FAILED: $e");
    }
```

#### 6.6 Query wifi strength

Get the wifi strength details

```dart
try {
      final strength=await TuyaFlutterHaSdk.queryDeviceWiFiStrength(devId: _devId.text);
      print("← queryDeviceWiFiStrength SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR queryDeviceWiFiStrength PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ queryDeviceWiFiStrength FAILED: $e");
    }
```

#### 6.7 Get subdevices

Get details of subdevices

```dart
try {
      final deviceList=await TuyaFlutterHaSdk.querySubDeviceList(devId: _devId.text);
      print("← querySubDeviceList SUCCESS: $deviceList");
    } on PlatformException catch (e) {
      print("ERROR querySubDeviceList PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ querySubDeviceList FAILED: $e");
    }
```

----

## 7 Room Management

This section covers the room related functionalities provided by Tuya SDK

#### 7.1 Get Rooms

Get a list of rooms for a given home

```dart
try {
      var roomList=await TuyaFlutterHaSdk.getRoomList(homeId: int.parse(_getRoomsHomeId.text));
      print("← getRoomList SUCCESS:rooms-$roomList");
    } on PlatformException catch (e) {
      print("ERROR getRoomList PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ getRoomList FAILED: $e");
  }
```

#### 7.2 Add Room

Add a room to a given home

```dart
try {
      await TuyaFlutterHaSdk.addRoom(homeId: int.parse(_addRoomHomeId.text), roomName: _addRoomRoomName.text);
      print("← addRoom SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR addRoom PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ addRoom FAILED: $e");
    }
```

#### 7.3 Remove room

Remove room from a given home

```dart
try {
      await TuyaFlutterHaSdk.removeRoom(homeId: int.parse(_remRoomHomeId.text), roomId: int.parse(_remRoomRoomId.text));
      print("← removeRoom SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR removeRoom PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ removeRoom FAILED: $e");
    }
```

#### 7.4 Sort Rooms

Sort rooms based on the given list

```dart
try {
      await TuyaFlutterHaSdk.sortRooms(homeId: int.parse(_sortRoomHomeId.text), roomIds: _sortRoomRoomIds.text.split(",").map(int.parse).toList());
      print("← sortRooms SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR sortRooms PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ sortRooms FAILED: $e");
    }
```

#### 7.5 Update Room Name

Update the name of the room

```dart
try {
      await TuyaFlutterHaSdk.updateRoomName(homeId: int.parse(_updateRoomHomeId.text), roomId: int.parse(_updateRoomRoomId.text),roomName: _updateRoomRoomName.text);
      print("← updateRoomName SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR updateRoomName PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ updateRoomName FAILED: $e");
    }
```

#### 7.6 Add device to room

Add a device to a given room

```dart
try {
      await TuyaFlutterHaSdk.addDeviceToRoom(homeId: int.parse(_addDevRoomHomeId.text), roomId: int.parse(_addDevRoomRoomId.text),devId: _addDevRoomDevId.text);
      print("← addDeviceToRoom SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR addDeviceToRoom PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ addDeviceToRoom FAILED: $e");
    }
```

#### 7.7 Remove device

Remove a given device from a room

```dart
try {
      await TuyaFlutterHaSdk.removeDeviceFromRoom(homeId: int.parse(_remDevRoomHomeId.text), roomId: int.parse(_remDevRoomRoomId.text),devId: _remDevRoomDevId.text);
      print("← removeDeviceFromRoom SUCCESS");
    } on PlatformException catch (e) {
      print("ERROR removeDeviceFromRoom PlatformException -> code=${e.code}, message=${e.message}");
    } catch (e) {
      print("⛔ removeDeviceFromRoom FAILED: $e");
    }
```

----

## 8. Lock devices

This section covers functionalities related to Lock devices provided by Tuya SDK

#### 8.1 Unlock BLE lock

Unlock a given BLE lock device

```dart
try {
      await TuyaFlutterHaSdk.unlockBLELock(devId: _selectedDeviceId!);
      print("← unlockBLELock.");
    } catch (e) {
      print("⛔ unlockBLELock error: $e");
    }
```

#### 8.2 Lock a BLE Lock

Lock a given BLE lock device

```dart
try {
      await TuyaFlutterHaSdk.lockBLELock(devId: _selectedDeviceId!);
      print("← lockBLELock.");
    } catch (e) {
      print("⛔ lockBLELock error: $e");
    }
```

#### 8.3 Unlock Wifi Lock

Reply to a unlock request on Wifi Lock

```dart
try {
      await TuyaFlutterHaSdk.replyRequestUnlock(devId: _selectedDeviceId!,open: true);
      print("← replyRequestUnlock.");
    } catch (e) {
      print("⛔ replyRequestUnlock error: $e");
    }
```

#### 8.4 Dynamic Password

Get dynamic password for a wifi lock

```dart
try {
      final password =
      await TuyaFlutterHaSdk.dynamicWifiLockPassword(devId: _selectedDeviceId!);
      print("← Dynamic password $password.");
    } catch (e) {
      print("⛔ dynamicWifiLockPassword error: $e");
    }
```

#### 8.5 Check Matter

Check if a given device is a matter device

```dart
try {
      final isMatter =
      await TuyaFlutterHaSdk.checkIsMatter(devId: _selectedDeviceId!);
      print("← Is Matter $isMatter.");
    } catch (e) {
      print("⛔ checkIsMatter error: $e");
    }
```

#### 8.6 Control Matter

Control a matter device through dps

```dart
try {
      await TuyaFlutterHaSdk.controlMatter(devId: _selectedDeviceId!,dps: {"$_dpsId":_dpsValue});
      print("← controlMatter.");
    } catch (e) {
      print("⛔ controlMatter error: $e");
    }
```

----

## 9 Cameras and IPC

This section provides information about cameras and IPC device functionalities provided by Tuya SDK

#### 9.1 List IPC devices

This function provides a list of IPC devices

```dart
try {
      final devices = await TuyaFlutterHaSdk.listCameras(homeId: _homeId);
      setState(() {
        _deviceList = devices;
      });
      print("← Found ${devices.length} devices.");
      for (var i = 0; i < devices.length; i++) {
        final d = devices[i];
        print("  #$i: ${d['name']} (${d['devId']})");
      }
    } on PlatformException catch (e) {
      print("⛔ getHomeDevices failed: ${e.message}");
    }
```

#### 9.2 Camera capabilities 

Get all the capabilities of a given IPC device

```dart
try {
      final caps = await TuyaFlutterHaSdk.getCameraCapabilities(
        deviceId: _selectedDeviceId!,
      );
      setState(() {
        _cameraCapabilities = caps == null
            ? {}
            : Map<String, dynamic>.from(caps);
      });
      print("← Capabilities:");
      _cameraCapabilities!.forEach((k, v) {
        print("   $k: $v");
      });
    } catch (e) {
      print("⛔ getCameraCapabilities error: $e");
    }
```

#### 9.3 Start Live Stream

Start live streaming of a selected device

```dart
child: Platform.isIOS?UiKitView(
        key: ValueKey('tuya_camera_view_${_selectedDeviceId!}'),
        viewType: 'tuya_camera_view',
        creationParams: {'deviceId': _selectedDeviceId},
        creationParamsCodec: const StandardMessageCodec(),
      ):AndroidView(viewType: 'tuya_camera_view',key:ValueKey('tuya_camera_view_${_selectedDeviceId!}') ,creationParams: {'deviceId': _selectedDeviceId},
        creationParamsCodec: const StandardMessageCodec(),),
```

```dart
try {
      await TuyaFlutterHaSdk.startLiveStream(deviceId: _selectedDeviceId!);
      setState(() {
        _showCameraView = true;
        print("🛠️ [Flutter] _showCameraView set true for $_selectedDeviceId");
      });
    } catch (e) {
      print("⛔ startLiveStream error: $e");
    }
```

#### 9.4 Stop Live Stream

Stop live streaming of the camera

```dart
try {
      await TuyaFlutterHaSdk.stopLiveStream(deviceId: _selectedDeviceId!);
      setState(() {
        _showCameraView = false;
        print("🛠️ [Flutter] _showCameraView set false for $_selectedDeviceId");
      });
    } catch (e) {
      print("⛔ stopLiveStream error: $e");
    }
```

#### 9.5 Get device alerts

Get the alerts for the given device

```dart
try {
      final alerts =
      await TuyaFlutterHaSdk.getDeviceAlerts(deviceId: _selectedDeviceId!,year: 2025,month: 06);
      print("← Found ${alerts.length} alerts.");
      for (var a in alerts) print("   $a");
    } catch (e) {
      print("⛔ getDeviceAlerts error: $e");
    }
```

#### 9.6 Save video to local file

This function allows to save the video to a local file

```dart
try {
        await TuyaFlutterHaSdk.saveVideoToGallery(filePath: filePath);
        print("← Saved to gallery. $filePath");
      } catch (e) {
        print("⛔ saveVideoToGallery error: $e");
      }
```

#### 9.7 Stop saving to local file

This function stops the saving of video to local file

```dart
try {
      await TuyaFlutterHaSdk.stopSaveVideoToGallery();
      print("← stopSaveVideoToGallery.");
    } catch (e) {
      print("⛔ stopSaveVideoToGallery error: $e");
    }
```

#### 9.8 Register for push notification

This function registers for getting push notification of alerts

```dart
try {
      await TuyaFlutterHaSdk.registerPush(type: 0,isOpen: true);
      print("← registerPush.");
    } catch (e) {
      print("⛔ registerPush error: $e");
    }
```

#### 9.9 Get all alerts

This function gets all the alert messages for a given user

```dart
try {
      final alerts =
      await TuyaFlutterHaSdk.getAllMessages();
      print("← Found ${alerts.length} alerts.");
      for (var a in alerts) print("   $a");
    } catch (e) {
      print("⛔ getAllMessages error: $e");
    }
```

#### 9.10 Get DP Configs

This function gets all the DP Configs available for a device

```dart
try {
      final alerts =
      await TuyaFlutterHaSdk.getDeviceDpConfigs(deviceId: _selectedDeviceId!);
      print("← Found ${alerts.length} getDeviceDpConfigs.");
      for (var a in alerts){
        print(a);
    } catch (e) {
      print("⛔ getDeviceDpConfigs error: $e");
    }
```

#### 9.11 Set DP Configs

This function allows to set DP Configs for a given device

```dart
try {
      await TuyaFlutterHaSdk.setDeviceDpConfigs(deviceId: _selectedDeviceId!,dps: {"$_dpsId":_dpsValue});
      print("setDeviceDpConfigs.");
    } catch (e) {
      print("⛔ setDeviceDpConfigs error: $e");
    }
```

---

## 📬 Contact Us

Designed and developed by **Omega Kwanga** for [KPMSG](https://kpmsg.com/).

- 📱 Request the **Example (Demo) App**: [Submit form here](https://kpmsg.com/tuya-sdk/)
- ✉️ [Email Support](mailto:support@kpmsg.com)

#### Connect with Omega
[![GitHub Profile](https://cdn-icons-png.flaticon.com/128/733/733553.png)](https://github.com/omegaballa4660)
[![LinkedIn Profile](https://cdn-icons-png.flaticon.com/128/3536/3536505.png)](https://linkedin.com/in/omegaballa)

---

## 📜 License

This project is licensed under the **MIT License** — you are free to use, modify, and distribute it with attribution.  
See the [LICENSE](LICENSE) file for full details. 

---

## 0.0.1
- Initial release
- User management (login, register, logout)
- Home/room/device management
- Camera & smart lock tests