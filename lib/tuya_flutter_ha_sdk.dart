import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'camera/tuya_camera_methods.dart';
import 'models/user_model.dart';
import 'tuya_flutter_ha_sdk_platform_interface.dart';

class TuyaFlutterHaSdk {
  /// Returns the platform version, as before.
  Future<String?> getPlatformVersion() {
    return TuyaFlutterHaSdkPlatform.instance.getPlatformVersion();
  }

  /// Initializes the Tuya Home SDK with the provided app key and app secret.
  ///
  /// The [androidKey] is used to authenticate the Tuya Home SDK on android device.
  /// The [androidSecret] is used to authenticate the Tuya Home SDK on android device.
  /// The [iosKey] is used to authenticate the Tuya Home SDK on iOS device.
  /// The [iosSecret] is used to authenticate the Tuya Home SDK on iOS device.
  ///
  /// Example Usage:
  /// ```dart
  /// await tuyaSdkInit('your_android_app_key', 'your_android_app_secret','your_ios_app_key', 'your_ios_app_secret');
  /// ```
  ///
  /// Throws an [AssertionError] if the [androidKey] is empty or contains whitespace characters.
  /// Throws an [AssertionError] if the [androidSecret] is empty or contains whitespace characters.
  /// Throws an [AssertionError] if the [iosKey] is empty or contains whitespace characters.
  /// Throws an [AssertionError] if the [iosSecret] is empty or contains whitespace characters.
  /// Throws [PlatformException] on failure.
  ///
  /// Call this once before using any Tuya APIs.
  static Future<void> tuyaSdkInit({
    required String androidKey,
    required String androidSecret,
    required String iosKey,
    required String iosSecret,
    bool isDebug = false,
  }) {
    if (Platform.isAndroid) {
      if (androidKey.isEmpty || androidKey.contains(" ")) {
        throw PlatformException(
          code: "INVALID_PARAMETER",
          message: "AppKey can't be empty or contains whitespaces",
        );
      }
      if (androidSecret.isEmpty || androidSecret.contains(" ")) {
        throw PlatformException(
          code: "INVALID_PARAMETER",
          message: "AppSecret can't be empty or contains whitespaces",
        );
      }
      return TuyaFlutterHaSdkPlatform.instance.tuyaSdkInit(
        appKey: androidKey,
        appSecret: androidSecret,
        isDebug: isDebug,
      );
    } else if (Platform.isIOS) {
      if (iosKey.isEmpty || iosKey.contains(" ")) {
        throw PlatformException(
          code: "INVALID_PARAMETER",
          message: "AppKey can't be empty or contains whitespaces",
        );
      }
      if (iosSecret.isEmpty || iosSecret.contains(" ")) {
        throw PlatformException(
          code: "INVALID_PARAMETER",
          message: "AppSecret can't be empty or contains whitespaces",
        );
      }
      return TuyaFlutterHaSdkPlatform.instance.tuyaSdkInit(
        appKey: iosKey,
        appSecret: iosSecret,
        isDebug: isDebug,
      );
    } else {
      throw UnsupportedError('Tuya SDK is only supported on Android and iOS');
    }
  }

  /// Login or register a user with the provided username, country code, and password.
  ///
  /// The [uid] parameter is the username of the user.
  /// The [countryCode] parameter is the country code of the user's phone number.
  /// The [password] parameter is the password of the user.
  /// The [createHome] parameter is the optional for creating a new home.
  ///
  /// If the login is successful, the uid is returned.
  /// If an error occurs during the login process, the error is thrown as platform exception.
  ///
  /// Throws an [AssertionError] if the [countryCode], [username], or [password] is empty.
  ///
  /// Example usage:
  /// ```dart
  /// Map<String,dynamic> success = await loginWithUid(uid: 'john', countryCode: '+1', password: 'password123');
  /// print(success);
  /// ```
  ///
  /// Throws [PlatformException] on failure.
  static Future<Map<String, dynamic>> loginWithUid({
    required String countryCode,
    required String uid,
    required String password,
    bool createHome = true,
  }) {
    if (countryCode.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "countryCode cannot be empty",
      );
    }
    if (uid.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "uid cannot be empty",
      );
    }
    if (password.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "password cannot be empty",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.loginWithUid(
      countryCode: countryCode,
      uid: uid,
      password: password,
      createHome: createHome,
    );
  }

  /// Checks if any user is logged in currently.
  /// returns true if logged in and false if not logged in
  /// Example usage:
  /// ```dart
  /// bool loggedIn = await checkLogin();
  /// ```
  /// Throws [PlatformException] on failure.
  static Future<bool> checkLogin() {
    return TuyaFlutterHaSdkPlatform.instance.checkLogin();
  }

  /// Retrieves the user information from the Tuya Home SDK.
  ///
  /// This method makes an asynchronous call to the `getCurrentUser` method of the `methodChannel` to retrieve the user information.
  /// It returns a `Future` that resolves to a `ThingSmartUserModel` object representing the user information.
  /// If the call is successful, the user information is parsed from the response using the `ThingSmartUserModel.fromJson` method.
  ///
  /// Returns:
  /// - A `Future` that resolves to a `ThingSmartUserModel` object representing the user information.
  ///   Returns `null` if an error occurs during the call.
  ///
  /// Example usage:
  /// ```dart
  /// ThingSmartUserModel? userInfo = await getCurrentUser();
  /// if (userInfo != null) {
  ///   // Use the user information
  /// } else {
  ///   // Handle the error
  /// }
  /// ```
  ///
  /// Throws [PlatformException] if no user is logged in.
  static Future<ThingSmartUserModel> getCurrentUser() async {
    var res = await TuyaFlutterHaSdkPlatform.instance.getCurrentUser();
    print(res);
    return ThingSmartUserModel.fromJson(res.cast<String, dynamic>());
  }

  /// Logs out the currently logged‐in user.
  /// Example usage:
  /// ```dart
  ///  await userLogout();
  /// ```
  /// Throws [PlatformException] on failure.
  static Future<void> userLogout() {
    return TuyaFlutterHaSdkPlatform.instance.userLogout();
  }

  /// Deletes (deactivates) the current user account.
  /// Example usage:
  /// ```dart
  ///  await deleteAccount();
  /// ```
  /// Throws [PlatformException] on failure.
  static Future<void> deleteAccount() {
    return TuyaFlutterHaSdkPlatform.instance.deleteAccount();
  }

  /// Updates the user’s time zone ID (e.g. "Asia/Shanghai").
  ///
  /// The [timeZoneId] is time zone id like UTC, CST, GMT etc.
  ///
  /// Throws:
  /// - [PlatformException] if an error occurs during the update process.
  ///
  /// Example usage:
  /// ```dart
  /// await updateTimeZone(timeZoneId: "UTC");
  /// ```
  static Future<void> updateTimeZone({required String timeZoneId}) {
    if (timeZoneId.isEmpty || timeZoneId.contains(" ")) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "Time Zone ID can't be empty or contains whitespaces",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.updateTimeZone(
      timeZoneId: timeZoneId,
    );
  }

  /// Changes the user’s preferred temperature unit.
  ///
  /// The [tempUnit] is the temperature unit (1 = °C, 2 = °F).
  ///
  /// Throws:
  /// - [PlatformException] if an error occurs during the update process.
  ///
  /// Example usage:
  /// ```dart
  /// await updateTempUnit(tempUnit: 1);
  /// ```
  static Future<void> updateTempUnit({required int tempUnit}) {
    if (tempUnit != 1 && tempUnit != 2) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "Temp Unit should be either 1 (°C) or 2 (°F)",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.updateTempUnit(tempUnit: tempUnit);
  }

  /// Updates the current user’s nickname.
  ///
  /// The [nickname] is new nickname to be used.
  ///
  /// Throws:
  /// - [PlatformException] if an error occurs during the update process.
  ///
  /// Example usage:
  /// ```dart
  /// await updateNickname(nickname: "Johnny");
  /// ```
  static Future<void> updateNickname({required String nickname}) {
    if (nickname.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "nickname cannot be empty",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.updateNickname(nickname: nickname);
  }

  /// Creates a new home.
  ///
  /// Example Usage:
  /// ```dart
  ///
  /// String name = "My Home";
  /// String geoName = "My Geo";
  /// List<String> rooms = ["Living Room", "Bedroom"];
  /// Double latitude = 37.7749;
  /// Double longitude = -122.4194;
  ///
  /// var result = await tuyaSdk.createHome(
  ///   name: name,
  ///   geoName: geoName,
  ///   rooms: rooms,
  ///   latitude: latitude,
  ///   longitude: longitude,
  /// );
  /// print(result);
  /// ```
  ///
  /// Inputs:
  /// - `name` (String): The name of the home to be added.
  /// - `geoName` (String): The geographical name of the home.
  /// - `rooms` (List<String>): The list of rooms in the home.
  /// - `latitude` (Double): The latitude coordinate of the home's location.
  /// - `longitude` (Double): The longitude coordinate of the home's location.
  ///
  /// Outputs:
  /// - int which is the home id.
  ///
  /// Throws [PlatformException] on failure.
  static Future<int> createHome({
    required String name,
    String? geoName,
    List<String>? rooms,
    double? latitude,
    double? longitude,
  }) {
    if (name.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "name cannot be empty",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.createHome(
      name: name,
      geoName: geoName,
      rooms: rooms,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Retrieves the list of all homes associated with the user.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// List<Map<String,dynamic>>> homes = await getHomeList();
  /// homes.forEach((home) {
  ///   print(home.name);
  /// });
  /// ```
  ///
  /// Note: This method should be called after initializing the TuyaHomeSdkFlutter instance and logging in the user.
  ///
  /// Throws [PlatformException] on failure.
  static Future<List<Map<String, dynamic>>> getHomeList() {
    return TuyaFlutterHaSdkPlatform.instance.getHomeList();
  }

  /// Updates existing home information.
  ///
  /// - [homeId]: The ID of the home to update.
  /// - [homeName]: The new name of the home.
  /// - [geoName]: The new geo name of the home.
  /// - [latitude]: The new latitude of the home. Defaults to 0.0.
  /// - [longitude]: The new longitude of the home. Defaults to 0.0.
  ///
  /// Example usage:
  /// ```dart
  /// int homeId = 123456
  /// String name = "My Home";
  /// String geoName = "My Geo";
  /// Double latitude = 37.7749;
  /// Double longitude = -122.4194;
  ///
  /// await tuyaSdk.updateHomeInfo(
  ///   homeId: homeId,
  ///   name: name,
  ///   geoName: geoName,
  ///   latitude: latitude,
  ///   longitude: longitude,
  /// );
  ///
  /// ```
  /// Throws [PlatformException] on failure.
  static Future<void> updateHomeInfo({
    required int homeId,
    required String homeName,
    String? geoName,
    double? latitude,
    double? longitude,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (homeName.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeName cannot be empty",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.updateHomeInfo(
      homeId: homeId,
      homeName: homeName,
      geoName: geoName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Deletes a home by the specified [homeId].
  ///
  /// Example usage:
  /// ```dart
  /// await deleteHome(homeId: 123);
  /// ```
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> deleteHome({required int homeId}) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.deleteHome(homeId: homeId);
  }

  /// Get devices for a certain home id.
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String,dynamic>>> devices = await getHomeDevices(homeId: 123);
  /// ```
  ///
  /// Inputs:
  /// - `homeId`: The ID of the home for which to retrieve the devices.
  ///
  /// Returns a map with details of the devices
  /// Throws [PlatformException] on failure.
  static Future<List<Map<String, dynamic>>> getHomeDevices({
    required int homeId,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.getHomeDevices(homeId: homeId);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Device-Pairing API (EZ, AP, AP+)
  // ──────────────────────────────────────────────────────────────────────────────

  /// Stream of low-level pairing events (onPairingSuccess, onPairingError, etc.).
  static const EventChannel _pairingEventChannel = EventChannel(
    'tuya_flutter_ha_sdk/pairingEvents',
  );
  static Stream<Map<String, dynamic>> pairingEvents = _pairingEventChannel
      .receiveBroadcastStream()
      .cast<Map<dynamic, dynamic>>()
      .map((e) => Map<String, dynamic>.from(e));

  /// Get the current Wi-Fi SSID.
  ///
  ///
  /// Example Usage:
  /// ```dart
  /// String token = await getSSID();
  /// ```
  /// Returns a ssid of the connected wifi
  /// Throws [PlatformException] on failure.
  static Future<String?> getSSID() {
    return TuyaFlutterHaSdkPlatform.instance.getSSID();
  }

  /// Update the user’s location for pairing (latitude, longitude).
  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) {
    return TuyaFlutterHaSdkPlatform.instance.updateLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Retrieve a pairing token for the given homeId.
  ///
  /// Example Usage:
  /// ```dart
  /// String token = await getToken(homeId: 123);
  /// ```
  ///
  /// Inputs:
  /// - `homeId`: The ID of the home for which to retrieve the token.
  ///
  /// Returns a token of the home
  /// Throws [PlatformException] on failure.
  static Future<String?> getToken({required int homeId}) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.getToken(homeId: homeId);
  }

  /// Start EZ or AP Wi-Fi pairing.
  ///
  /// Example Usage:
  /// ```dart
  /// await startConfigWiFi(mode: "EZ", ssid:"1234", password:"abcd",token:"abcde");
  /// ```
  ///
  /// Inputs:
  /// - `mode`: EZ or AP.
  /// - 'ssid': Wifi id
  /// - 'password': Wifi password
  /// - 'token': token of the home
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> startConfigWiFi({
    required String mode,
    required String ssid,
    required String password,
    required String token,
    int timeout = 100,
  }) {
    if (mode != "EZ" && mode != "AP") {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "mode should be EZ or AP",
      );
    }
    if (ssid.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "ssid cannot be empty",
      );
    }

    if (token.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "password cannot be empty",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.startConfigWiFi(
      mode: mode,
      ssid: ssid,
      password: password,
      token: token,
      timeout: timeout,
    );
  }

  /// Stop any ongoing Wi-Fi pairing.
  ///
  /// Example Usage:
  /// ```dart
  /// await stopConfigWiFi();
  /// ```
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> stopConfigWiFi() {
    return TuyaFlutterHaSdkPlatform.instance.stopConfigWiFi();
  }

  /// Connect to device AP and query its discovered Wi-Fi networks (AP+ flow).
  ///
  /// Example Usage:
  /// ```dart
  /// await connectDeviceAndQueryWifiList();
  /// ```
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> connectDeviceAndQueryWifiList({int timeout = 120}) {
    return TuyaFlutterHaSdkPlatform.instance.connectDeviceAndQueryWifiList(
      timeout: timeout,
    );
  }

  /// Complete AP+ pairing by resuming with SSID/password/token.
  ///
  /// Example Usage:
  /// ```dart
  /// await resumeAPPlus(ssid:"1234", password:"abcd",token:"abcde");
  /// ```
  ///
  /// Inputs:
  /// - 'ssid': Wifi id
  /// - 'password': Wifi password
  /// - 'token': token of the home
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> resumeAPPlus({
    required String ssid,
    required String password,
    required String token,
    int timeout = 120,
  }) {
    return TuyaFlutterHaSdkPlatform.instance.resumeAPPlus(
      ssid: ssid,
      password: password,
      token: token,
      timeout: timeout,
    );
  }

  /// Scans for the first inactivated BLE device advertising Tuya packets.
  ///
  /// Example Usage:
  /// ```dart
  /// Map<String,dynamic>> deviceInfo = await discoverDeviceInfo();
  /// ```
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<Map<String, dynamic>?> discoverDeviceInfo() {
    return TuyaFlutterHaSdkPlatform.instance.discoverDeviceInfo();
  }

  /// Activate (pair) a pure-BLE device with the cloud.
  ///
  /// Example Usage:
  /// ```dart
  /// Map<String,dynamic>> deviceInfo = await pairBleDevice(uuid:"abcd",productId:"xyz",homeId:124,deviceType:300,address:"D4:A3...");
  /// ```
  ///
  /// Inputs:
  /// - 'uuid': uuid of the device
  /// - 'productId': productId for the device
  /// - 'homeId': homeId of the home
  /// Additional fields required for Android only
  /// - 'deviceType': device type of the device
  /// - 'address': IP address of the device
  /// - 'flag': device flag
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<Map<String, dynamic>?> pairBleDevice({
    required String uuid,
    required String productId,
    required int homeId,
    int? deviceType,
    String? address,
    int? flag,
    int? timeout,
  }) {
    if (uuid.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "uuid should be specified",
      );
    }
    if (productId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "productId should be specified",
      );
    }
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.pairBleDevice(
      uuid: uuid,
      productId: productId,
      homeId: homeId,
      deviceType: deviceType,
      address: address,
      flag: flag,
      timeout: timeout,
    );
  }

  /// Start combo (BLE→Wi-Fi) pairing for a device.
  ///
  /// Example Usage:
  /// ```dart
  /// Map<String,dynamic>> deviceInfo = await startComboPairing(uuid:"abcd",productId:"xyz",homeId:124,ssid:"myinternet",password:"internetpassword",deviceType:300,address:"D4:A3...",token:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'uuid': uuid of the device
  /// - 'productId': productId for the device
  /// - 'homeId': homeId of the home
  /// - 'ssid': Wifi ssid
  /// - 'password': Wifi password
  /// - 'timeout' : timeout for pairing activity
  /// Addition field required only for Android
  /// - 'deviceType': device type of the device
  /// - 'address': IP address of the device
  /// - 'token': token for the home
  /// - 'flag': device flag
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<Map<String, dynamic>?> startComboPairing({
    required String uuid,
    required String productId,
    required int homeId,
    required String ssid,
    required String password,
    int? deviceType,
    String? address,
    String? token,
    int? timeout,
    int? flag,
  }) {
    if (uuid.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "uuid should be specified",
      );
    }
    if (productId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "productId should be specified",
      );
    }
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (ssid.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "ssid should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.startComboPairing(
      uuid: uuid,
      productId: productId,
      homeId: homeId,
      ssid: ssid,
      password: password,
      deviceType: deviceType,
      address: address,
      token: token,
      timeout: timeout,
      flag: flag,
    );
  }

  /// Init the device
  ///
  /// Example Usage:
  /// ```dart
  /// await initDevice(devId:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> initDevice({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.initDevice(devId: devId);
  }

  /// Query information about a device
  ///
  /// Example Usage:
  /// ```dart
  /// Map<String,dynamic>> deviceInfo = await queryDeviceInfo(devId:"abcd",dps:[100,25,600]);
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  /// - 'dps': data points for which info is required
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<Map<String, dynamic>?> queryDeviceInfo({
    required String devId,
    List<String>? dps,
  }) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.queryDeviceInfo(
      devId: devId,
      dps: dps,
    );
  }

  /// Rename a specific device
  ///
  /// Example Usage:
  /// ```dart
  /// await renameDevice(devId:"abcd",name:"newName");
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  /// - 'name': new name for the device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> renameDevice({
    required String devId,
    required String name,
  }) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    if (name.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "name should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.renameDevice(
      devId: devId,
      name: name,
    );
  }

  /// Remove a specific device
  ///
  /// Example Usage:
  /// ```dart
  /// await removeDevice(devId:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> removeDevice({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.removeDevice(devId: devId);
  }

  /// Restore factory defaults for a specific device
  ///
  /// Example Usage:
  /// ```dart
  /// await restoreFactoryDefaults(devId:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> restoreFactoryDefaults({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.restoreFactoryDefaults(
      devId: devId,
    );
  }

  /// Get the signal strength of a specific device
  ///
  /// Example Usage:
  /// ```dart
  /// String strength = await queryDeviceWiFiStrength(devId:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  ///
  /// Returns the strength of the wifi signal
  ///
  /// Throws [PlatformException] on failure.
  static Future<String?> queryDeviceWiFiStrength({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.queryDeviceWiFiStrength(
      devId: devId,
    );
  }

  /// Query details of any sub devices
  ///
  /// Example Usage:
  /// ```dart
  /// Map<String,dynamic>> deviceInfo = await querySubDeviceList(devId:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<Map<String, dynamic>?> querySubDeviceList({
    required String devId,
  }) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.querySubDeviceList(devId: devId);
  }

  /// Get rooms details for a home
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String,dynamic>> rooms = await getRoomList(homeId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<List<Map<String, dynamic>>?> getRoomList({
    required int homeId,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.getRoomList(homeId: homeId);
  }

  /// Add a room to a home
  ///
  /// Example Usage:
  /// ```dart
  /// await addRoom(homeId:1234,roomName:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomName': name of the new room
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> addRoom({required int homeId, required String roomName}) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomName.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomName should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.addRoom(
      homeId: homeId,
      roomName: roomName,
    );
  }

  /// Remove room from a home
  ///
  /// Example Usage:
  /// ```dart
  /// await removeRoom(homeId:1234,roomId:5678);
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomId': roomId for a given room
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> removeRoom({required int homeId, required int roomId}) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.removeRoom(
      homeId: homeId,
      roomId: roomId,
    );
  }

  /// Sort the order of rooms in a home
  ///
  /// Example Usage:
  /// ```dart
  /// await sortRooms(homeId:1234,roomIds:[5678,895]);
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomIds': list of roomIds in the order to sort
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> sortRooms({
    required int homeId,
    required List<int> roomIds,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomIds.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomIds should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.sortRooms(
      homeId: homeId,
      roomIds: roomIds,
    );
  }

  /// Update the name of a given room
  ///
  /// Example Usage:
  /// ```dart
  /// await updateRoomName(homeId:1234,roomId:5678,roomName:"newName");
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomId': roomId for a given room
  /// - 'roomName': new name of the room
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> updateRoomName({
    required int homeId,
    required int roomId,
    required String roomName,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomId should be specified",
      );
    }
    if (roomName.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomName should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.updateRoomName(
      homeId: homeId,
      roomId: roomId,
      roomName: roomName,
    );
  }

  /// Add a given device to a room
  ///
  /// Example Usage:
  /// ```dart
  /// await addDeviceToRoom(homeId:1234,roomId:5678,devId:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomId': roomId for a given room
  /// - 'devId': devId of the given device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> addDeviceToRoom({
    required int homeId,
    required int roomId,
    required String devId,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomId should be specified",
      );
    }
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.addDeviceToRoom(
      homeId: homeId,
      roomId: roomId,
      devId: devId,
    );
  }

  /// Remove device from a given room
  ///
  /// Example Usage:
  /// ```dart
  /// await removeDeviceFromRoom(homeId:1234,roomId:5678,devId:"abcd");
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomId': roomId for a given room
  /// - 'devId': devId of the given device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> removeDeviceFromRoom({
    required int homeId,
    required int roomId,
    required String devId,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomId should be specified",
      );
    }
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.removeDeviceFromRoom(
      homeId: homeId,
      roomId: roomId,
      devId: devId,
    );
  }

  /// Add a group to a given room
  ///
  /// Example Usage:
  /// ```dart
  /// await addGroupToRoom(homeId:1234,roomId:5678,groupId:9056);
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomId': roomId for a given room
  /// - 'groupId': groupId of a given group
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> addGroupToRoom({
    required int homeId,
    required int roomId,
    required int groupId,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomId should be specified",
      );
    }
    if (groupId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "groupId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.addGroupToRoom(
      homeId: homeId,
      roomId: roomId,
      groupId: groupId,
    );
  }

  /// Remove a group from a given room
  ///
  /// Example Usage:
  /// ```dart
  /// await removeGroupFromRoom(homeId:1234,roomId:5678,groupId:9056);
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  /// - 'roomId': roomId for a given room
  /// - 'groupId': groupId of a given group
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> removeGroupFromRoom({
    required int homeId,
    required int roomId,
    required int groupId,
  }) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    if (roomId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "roomId should be specified",
      );
    }
    if (groupId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "groupId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.removeGroupFromRoom(
      homeId: homeId,
      roomId: roomId,
      groupId: groupId,
    );
  }

  /// Get a list of cameras added to a home
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String,dynamic>> cameras = await listCameras(homeId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'homeId': homeId for a home
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<List<Map<String, dynamic>>> listCameras({required int homeId}) {
    if (homeId == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "homeId should be specified",
      );
    }
    return TuyaCameraMethods.listCameras(homeId: homeId);
  }

  /// Get the capabilities of a given camera device
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String,dynamic>> capabilities = await getCameraCapabilities(deviceId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a camera
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<Map<String, dynamic>> getCameraCapabilities({
    required String deviceId,
  }) {
    if (deviceId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaCameraMethods.getCameraCapabilities(deviceId: deviceId);
  }

  /// Start live streaming of a given camera
  ///
  /// Example Usage:
  /// ```dart
  /// await startLiveStream(deviceId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a camera
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> startLiveStream({required String deviceId}) {
    if (deviceId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaCameraMethods.startLiveStream(deviceId: deviceId);
  }

  /// Stop live streaming of a given camera
  ///
  /// Example Usage:
  /// ```dart
  /// await stopLiveStream(deviceId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a camera
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> stopLiveStream({required String deviceId}) {
    if (deviceId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaCameraMethods.stopLiveStream(deviceId: deviceId);
  }

  /// 连接 P2P
  ///
  /// Example Usage:
  /// ```dart
  /// await connectP2P(devId: "abc123");
  /// ```
  ///
  /// Inputs:
  /// - 'devId': devId of the device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> connectP2P({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaCameraMethods.connectP2P(devId: devId);
  }

  /// 断开 P2P 连接
  ///
  /// Example Usage:
  /// ```dart
  /// await disconnectP2P();
  /// ```
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> disconnectP2P() {
    return TuyaCameraMethods.disconnectP2P();
  }

  /// 开始预览
  ///
  /// Example Usage:
  /// ```dart
  /// await startPreview(clarity: 2); // 2=标清，4=高清
  /// ```
  ///
  /// Inputs:
  /// - 'clarity': 清晰度，2=标清，4=高清
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> startPreview({required int clarity}) {
    return TuyaCameraMethods.startPreview(clarity: clarity);
  }

  /// 停止预览
  ///
  /// Example Usage:
  /// ```dart
  /// await stopPreview();
  /// ```
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> stopPreview() {
    return TuyaCameraMethods.stopPreview();
  }

  /// 开始对讲
  ///
  /// Example Usage:
  /// ```dart
  /// await startTalk();
  /// ```
  static Future<void> startTalk() {
    return TuyaCameraMethods.startTalk();
  }

  /// 停止对讲
  ///
  /// Example Usage:
  /// ```dart
  /// await stopTalk();
  /// ```
  static Future<void> stopTalk() {
    return TuyaCameraMethods.stopTalk();
  }

  /// 设置静音状态
  ///
  /// [status]: 0 = 不静音，1 = 静音
  ///
  /// Example Usage:
  /// ```dart
  /// await setMute(status: 1); // 静音
  /// ```
  static Future<void> setMute({required int status}) {
    return TuyaCameraMethods.setMute(status: status);
  }

  /// Get alerts of a given device
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String,dynamic>> alerts = await getDeviceAlerts(deviceId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a camera
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<List<Map<String, dynamic>>> getDeviceAlerts({
    required String deviceId,
    required int year,
    required int month,
  }) {
    if (deviceId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    if (year == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "year should be specified",
      );
    }
    if (month == 0) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "month should be specified",
      );
    }
    return TuyaCameraMethods.getDeviceAlerts(
      deviceId: deviceId,
      year: year,
      month: month,
    );
  }

  /// Save the current video to a given path
  ///
  /// Example Usage:
  /// ```dart
  /// await saveVideoToGallery(filePath:/pathToStore/live.mp4);
  /// ```
  ///
  /// Inputs:
  /// - 'filePath': details of mp4 file to save the video
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> saveVideoToGallery({required String filePath}) {
    if (filePath.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "filePath should be specified",
      );
    }
    return TuyaCameraMethods.saveVideoToGallery(filePath: filePath);
  }

  /// Stop saving the video
  ///
  /// Example Usage:
  /// ```dart
  /// await stopSaveVideoToGallery();
  /// ```
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> stopSaveVideoToGallery() {
    return TuyaCameraMethods.stopSaveVideoToGallery();
  }

  /// Configure a set of DP codes on a device
  ///
  /// Example Usage:
  /// ```dart
  /// bool configured = await setDeviceDpConfigs(deviceId:1234,dps:{"100":true});
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a camera
  /// - 'dps': a map with dpId and the new value
  ///
  /// Returns true if the configuration is set.
  ///
  /// Throws [PlatformException] on failure.
  static Future<bool> setDeviceDpConfigs({
    required String deviceId,
    required Map<String, dynamic> dps,
  }) {
    if (deviceId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    if (dps.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "dps should be specified",
      );
    }
    return TuyaCameraMethods.setDeviceDpConfigs(deviceId: deviceId, dps: dps);
  }

  /// Get the current configurations of set of DP codes on a device
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String,dynamic>> dps = await getDeviceDpConfigs(deviceId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a camera
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<List<Map<String, dynamic>>> getDeviceDpConfigs({
    required String deviceId,
  }) {
    if (deviceId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaCameraMethods.getDeviceDpConfigs(deviceId: deviceId);
  }

  /// Kick off APNs / FCM registration on the native side
  ///
  /// Example Usage:
  /// ```dart
  /// await registerPush(type:0,isOpen:true);
  /// ```
  ///
  /// Inputs:
  /// - 'type': type of message
  /// 0: Alert
  /// 1: Home message
  /// 2: Notice message
  /// 4: Marketing message
  /// - 'isOpen': boolean indicating register/unregister
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> registerPush({required int type, required bool isOpen}) {
    return TuyaCameraMethods.registerPush(type: type, isOpen: isOpen);
  }

  /// Get all messages
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String,dynamic>> messages = await getAllMessages();
  /// ```
  ///
  /// Returns its raw JSON map, or null if none found.
  ///
  /// Throws [PlatformException] on failure.
  static Future<List<Map<String, dynamic>>> getAllMessages() {
    return TuyaCameraMethods.getAllMessages();
  }

  /// Unlock a bluetooth lock device
  ///
  /// Example Usage:
  /// ```dart
  /// await unlockBLELock(devId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'devId': deviceId of the bluetooth device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> unlockBLELock({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.unlockBLELock(devId: devId);
  }

  /// Lock a bluetooth lock device
  ///
  /// Example Usage:
  /// ```dart
  /// await lockBLELock(devId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'devId': deviceId of the bluetooth device
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> lockBLELock({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.lockBLELock(devId: devId);
  }

  /// Reply to a unlock request on wifi lock
  ///
  /// Example Usage:
  /// ```dart
  /// await replyRequestUnlock(devId:1234,open:true);
  /// ```
  ///
  /// Inputs:
  /// - 'devId': deviceId of the wifi device
  /// - 'open': boolean indicating open or not to open
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> replyRequestUnlock({
    required String devId,
    required bool open,
  }) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.unlockWifiLock(
      devId: devId,
      open: open,
    );
  }

  /// Get a dynamic password for opening a wifi lock
  ///
  /// Example Usage:
  /// ```dart
  /// String password = await dynamicWifiLockPassword(deviceId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a wifi device
  ///
  /// Returns a string with the dynamic password.
  ///
  /// Throws [PlatformException] on failure.
  static Future<String> dynamicWifiLockPassword({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.dynamicWifiLockPassword(
      devId: devId,
    );
  }

  /// Check if a device is matter device or not
  ///
  /// Example Usage:
  /// ```dart
  /// bool isMatter = await checkIsMatter(deviceId:1234);
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a wifi device
  ///
  /// Returns a bool indicating whether matter or not.
  ///
  /// Throws [PlatformException] on failure.
  static Future<bool> checkIsMatter({required String devId}) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.checkIfMatter(devId: devId);
  }

  /// Send dps configuration to control the wifi device
  ///
  /// Example Usage:
  /// ```dart
  ///  await controlMatter(deviceId:1234,dps:{"100":true});
  /// ```
  ///
  /// Inputs:
  /// - 'deviceId': deviceId of a wifi device
  /// - 'dps': a map with dpId and the new value
  ///
  /// Returns true if the configuration is set.
  ///
  /// Throws [PlatformException] on failure.
  static Future<void> controlMatter({
    required String devId,
    required Map<String, dynamic> dps,
  }) {
    if (devId.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "devId should be specified",
      );
    }
    if (dps.isEmpty) {
      throw PlatformException(
        code: "INVALID_PARAMETER",
        message: "dps should be specified",
      );
    }
    return TuyaFlutterHaSdkPlatform.instance.controlMatter(
      devId: devId,
      dps: dps,
    );
  }
}
