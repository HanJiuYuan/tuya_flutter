import 'package:flutter/foundation.dart'; // for @visibleForTesting
import 'package:flutter/services.dart';
import 'tuya_flutter_ha_sdk_platform_interface.dart';

/// The MethodChannel implementation of [TuyaFlutterHaSdkPlatform].
class MethodChannelTuyaFlutterHaSdk extends TuyaFlutterHaSdkPlatform {
  /// The MethodChannel used to talk to the native side.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'tuya_flutter_ha_sdk',
  );

  // ──────────────────────────────────────────────────────────────────────────────
  // Core SDK
  // ──────────────────────────────────────────────────────────────────────────────

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  /// Perform native-side initialization of the Tuya SDK.
  /// [appKey] and [appSecret] must match the current platform.
  /// tuyaSdkInit function in the native code (Java/Swift) is called
  @override
  Future<void> tuyaSdkInit({
    required String appKey,
    required String appSecret,
    required bool isDebug,
  }) async {
    await methodChannel.invokeMethod<void>('tuyaSdkInit', <String, dynamic>{
      'appKey': appKey,
      'appSecret': appSecret,
      'isDebug': isDebug,
    });
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // User Management
  // ──────────────────────────────────────────────────────────────────────────────

  /// Login (or register) with UID.
  /// [countryCode],[uid],[password],[createHome] details are passed on to the native
  /// loginWithUid function on the native side is invoked
  @override
  Future<Map<String, dynamic>> loginWithUid({
    required String countryCode,
    required String uid,
    required String password,
    required bool createHome,
  }) async {
    final Map<dynamic, dynamic> result = await methodChannel
        .invokeMethod('loginWithUid', <String, dynamic>{
          'countryCode': countryCode,
          'uid': uid,
          'password': password,
          'createHome': createHome,
        });
    return Map<String, dynamic>.from(result);
  }

  /// Checks if any user is logged in currently.
  /// checkLogin function on the native side is invoked
  /// returns true if logged in and false if not logged in
  @override
  Future<bool> checkLogin() async {
    return await methodChannel.invokeMethod<bool>('checkLogin') ?? false;
  }

  /// Get the current user’s info. Throws if no user is logged in.
  /// getCurrentUser function on the native side is invoked
  /// returns a map with all the user details
  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    final Map<dynamic, dynamic> result = await methodChannel.invokeMethod(
      'getCurrentUser',
    );
    return Map<String, dynamic>.from(result);
  }

  /// Logs out the current logged in user
  /// userLogout function on the native side is invoked
  @override
  Future<void> userLogout() async {
    await methodChannel.invokeMethod<void>('userLogout');
  }

  /// Deletes the current user account.
  /// deleteAccount function on the native side is invoked
  @override
  Future<void> deleteAccount() async {
    await methodChannel.invokeMethod<void>('deleteAccount');
  }

  /// Updates the user’s time zone.
  /// [timeZoneId] is passed on to the native
  /// updateTimeZone function of the native is invoked
  @override
  Future<void> updateTimeZone({required String timeZoneId}) async {
    await methodChannel.invokeMethod<void>('updateTimeZone', <String, dynamic>{
      'timeZoneId': timeZoneId,
    });
  }

  /// Changes the user’s temperature unit preference.
  /// [tempUnit] is passed on to the native
  /// updateTempUnit function of the native is invoked
  @override
  Future<void> updateTempUnit({required int tempUnit}) async {
    await methodChannel.invokeMethod<void>('updateTempUnit', <String, dynamic>{
      'tempUnit': tempUnit,
    });
  }

  /// Updates the current user’s nickname.
  /// [nickname] is passed on to the native
  /// updateNickname function of the native is invoked
  @override
  Future<void> updateNickname({required String nickname}) async {
    await methodChannel.invokeMethod<void>('updateNickname', <String, dynamic>{
      'nickname': nickname,
    });
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Smart Home Management
  // ──────────────────────────────────────────────────────────────────────────────

  /// Creates a new home.
  /// [name],[geoName],[rooms],[latitude],[longitude] details are passed on to the native
  /// createHome function of the native is invoked
  /// Returns the new home ID.
  @override
  Future<int> createHome({
    required String name,
    String? geoName,
    List<String>? rooms,
    double? latitude,
    double? longitude,
  }) async {
    geoName ??= "";
    rooms ??= [];
    latitude ??= 0.0;
    longitude ??= 0.0;
    final int? result = await methodChannel
        .invokeMethod<int>('createHome', <String, dynamic>{
          'name': name,
          'geoName': geoName,
          'rooms': rooms,
          'latitude': latitude,
          'longitude': longitude,
        });
    return result ?? 0;
  }

  /// Retrieves a list of all homes.
  /// getHomeList function of the native is invoked
  /// returns the list of homes
  @override
  Future<List<Map<String, dynamic>>> getHomeList() async {
    final List<dynamic>? list = await methodChannel.invokeMethod<List<dynamic>>(
      'getHomeList',
    );
    return (list ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Updates home information.
  /// [homeId],[homeName],[geoName],[latitude],[longitude] details are passed on to the native
  /// updateHomeInfo function of native is invoked
  @override
  Future<void> updateHomeInfo({
    required int homeId,
    required String homeName,
    String? geoName,
    double? latitude,
    double? longitude,
  }) async {
    await methodChannel.invokeMethod<void>('updateHomeInfo', <String, dynamic>{
      'homeId': homeId,
      'homeName': homeName,
      if (geoName != null) 'geoName': geoName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  /// Deletes a home by ID.
  /// [homeId] is passed on to the native
  /// deleteHome function of native is invoked
  @override
  Future<void> deleteHome({required int homeId}) async {
    await methodChannel.invokeMethod<void>('deleteHome', <String, dynamic>{
      'homeId': homeId,
    });
  }

  /// Gets all devices for the given homeId.
  /// [homeId] is passed on to the native
  /// getHomeDevices function of native is invoked
  /// returns the list of devices
  @override
  Future<List<Map<String, dynamic>>> getHomeDevices({
    required int homeId,
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getHomeDevices',
      {'homeId': homeId},
    );
    return result?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ??
        [];
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Device-Pairing Helpers (Wi‑Fi)
  // ──────────────────────────────────────────────────────────────────────────────

  /// Retrieves the current Wi-Fi SSID
  /// getSSID function of the native is invoked
  /// returns the ssid
  @override
  Future<String?> getSSID() async {
    return await methodChannel.invokeMethod<String>('getSSID');
  }

  /// Updates the user’s location
  /// [latitude],[longitude] is passed on native
  /// updateLocation function on native is invokced
  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    await methodChannel.invokeMethod<void>('updateLocation', <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Retrieves a pairing token for the given homeId.
  /// [homeId] is passed on to native
  /// getToken function of the native is invoked
  /// token of the home is returned
  @override
  Future<String?> getToken({required int homeId}) async {
    return await methodChannel.invokeMethod<String>(
      'getToken',
      <String, dynamic>{'homeId': homeId},
    );
  }

  /// Starts EZ or AP Wi-Fi pairing.
  /// [mode],[ssid],[password],[token],[timeout] details are passed on to native
  /// startConfigWifi function of native is invoked
  @override
  Future<void> startConfigWiFi({
    required String mode,
    required String ssid,
    required String password,
    required String token,
    required int timeout,
  }) async {
    await methodChannel.invokeMethod<void>('startConfigWiFi', <String, dynamic>{
      'mode': mode,
      'ssid': ssid,
      'password': password,
      'token': token,
      'timeout': timeout,
    });
  }

  /// Stops any ongoing Wi-Fi pairing.
  /// stopConfigWifi function on native is invoked
  @override
  Future<void> stopConfigWiFi() async {
    await methodChannel.invokeMethod<void>('stopConfigWiFi');
  }

  /// Connects to device AP and queries Wi-Fi networks (AP+ flow).
  /// [timeout] data is passed on to native
  @override
  Future<void> connectDeviceAndQueryWifiList({required int timeout}) async {
    await methodChannel.invokeMethod<void>(
      'connectDeviceAndQueryWifiList',
      <String, dynamic>{'timeout': timeout},
    );
  }

  /// Completes AP+ pairing with SSID/password/token.
  /// [ssid],[password],[token],[timeout] details are passed on to native
  /// resumeAPPlus function in native is invoked
  @override
  Future<void> resumeAPPlus({
    required String ssid,
    required String password,
    required String token,
    required int timeout,
  }) async {
    await methodChannel.invokeMethod<void>('resumeAPPlus', <String, dynamic>{
      'ssid': ssid,
      'password': password,
      'token': token,
      'timeout': timeout,
    });
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // BLE Device Discovery & Pairing
  // ──────────────────────────────────────────────────────────────────────────────

  /// Scans for the first inactivated BLE device advertising Tuya packets.
  /// discoverDeviceInfo function in native is invoked
  /// Returns its raw JSON map, or null if none found.
  @override
  Future<Map<String, dynamic>?> discoverDeviceInfo() async {
    return await methodChannel.invokeMapMethod<String, dynamic>(
      'discoverDeviceInfo',
    );
  }

  /// Activate (pair) a pure-BLE device with the cloud.
  /// [uuid],[productId],[homeId],[deviceType],[address] details is passed on to native
  /// pairBleDevice function on native is invoked
  /// Returns a JSON map
  @override
  Future<Map<String, dynamic>?> pairBleDevice({
    required String uuid,
    required String productId,
    required int homeId,
    int? deviceType,
    String? address,
    int? flag,
    int? timeout,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'pairBleDevice',
      <String, dynamic>{
        'uuid': uuid,
        'productId': productId,
        'homeId': homeId,
        'deviceType': deviceType,
        'address': address,
        'flag': flag,
        'timeout': timeout,
      },
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  /// Start combo (BLE→Wi-Fi) pairing for a device.
  /// [uuid],[productId],[homeId],[ssid],[password],[timeout],[deviceType],[address],[token] details is passed on to native
  /// startComboPairing function of native is invoked
  /// returns a JSON map
  @override
  Future<Map<String, dynamic>?> startComboPairing({
    required String uuid,
    required String productId,
    required int homeId,
    required String ssid,
    required String password,
    int? timeout,
    int? deviceType,
    String? address,
    String? token,
    int? flag,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'startComboPairing',
      <String, dynamic>{
        'uuid': uuid,
        'productId': productId,
        'homeId': homeId,
        'ssid': ssid,
        'password': password,
        'timeout': timeout,
        'deviceType': deviceType,
        'address': address,
        'token': token,
        'flag': flag,
      },
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  /// Init the device
  /// [devId] is passed on to native
  /// initDevice function on native is invoked
  @override
  Future<void> initDevice({required String devId}) async {
    await methodChannel.invokeMethod<void>("initDevice", <String, dynamic>{
      'devId': devId,
    });
  }

  /// Query information about a device
  /// [devId],[dps] details are passed on to native
  /// queryDeviceInfo function of native is invoked
  @override
  Future<Map<String, dynamic>?> queryDeviceInfo({
    required String devId,
    List<String>? dps,
  }) async {
    final result = await methodChannel.invokeMethod(
      "queryDeviceInfo",
      <String, dynamic>{'devId': devId, 'dps': dps},
    );
    if (result == null) {
      return null;
    }
    // 确保类型转换正确：从 Map<Object?, Object?> 转换为 Map<String, dynamic>
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  /// Rename a specific device
  /// [devId],[name] details are passed on to native
  /// renameDevice function of native is invoked
  @override
  Future<void> renameDevice({
    required String devId,
    required String name,
  }) async {
    await methodChannel.invokeMethod<void>("renameDevice", <String, dynamic>{
      'devId': devId,
      'name': name,
    });
  }

  /// Remove a specific device
  /// [devId] is passed on to native
  /// removeDevice function of native is invoked
  @override
  Future<void> removeDevice({required String devId}) async {
    await methodChannel.invokeMethod<void>("removeDevice", <String, dynamic>{
      'devId': devId,
    });
  }

  /// Restore factory defaults for a specific device
  /// [devId] is passed on to native
  /// restoreFactoryDefaults function of native is invoked
  @override
  Future<void> restoreFactoryDefaults({required String devId}) async {
    await methodChannel.invokeMethod<void>(
      "restoreFactoryDefaults",
      <String, dynamic>{'devId': devId},
    );
  }

  /// Get the signal strength of a specific device
  /// [devId] is passed on to native
  /// queryDeviceWifiStrength function of native is invoked
  /// String is returned
  @override
  Future<String?> queryDeviceWiFiStrength({required String devId}) async {
    return await methodChannel.invokeMethod<String>(
      'queryDeviceWiFiStrength',
      <String, dynamic>{'devId': devId},
    );
  }

  /// Query details of any sub devices
  /// [devId] is passed on to native
  /// querySubDeviceList function of native is invoked
  /// returns a JSON map
  @override
  Future<Map<String, dynamic>?> querySubDeviceList({
    required String devId,
  }) async {
    return await methodChannel.invokeMethod<Map<String, dynamic>>(
      "querySubDeviceList",
      <String, dynamic>{'devId': devId},
    );
  }

  /// Add a given device to a room
  /// [homeId],[roomId],[devId] details are passed on to native
  /// addDeviceToRoom function of native is invoked
  @override
  Future<void> addDeviceToRoom({
    required int homeId,
    required int roomId,
    required String devId,
  }) async {
    await methodChannel.invokeMethod<void>("addDeviceToRoom", <String, dynamic>{
      'homeId': homeId,
      'roomId': roomId,
      'devId': devId,
    });
  }

  /// Add a group to a given room
  /// [homeId],[roomId],[groupId] details are passed on to native
  /// addGroupToRoom function of native is invoked
  @override
  Future<void> addGroupToRoom({
    required int homeId,
    required int roomId,
    required int groupId,
  }) async {
    await methodChannel.invokeMethod<void>("addGroupToRoom", <String, dynamic>{
      'homeId': homeId,
      'roomId': roomId,
      'groupId': groupId,
    });
  }

  /// Get rooms details for a home
  /// [homeId] is passed on to native
  /// getRoomList function of native is invoked
  /// returns JSON map
  @override
  Future<List<Map<String, dynamic>>?> getRoomList({required int homeId}) async {
    final List<dynamic>? list = await methodChannel
        .invokeMethod<List<dynamic>?>("getRoomList", <String, dynamic>{
          'homeId': homeId,
        });
    return list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
  }

  /// Add a room to a home
  /// [homeId],[roomName] details is passed on to native
  /// addRoom function of native is invoked
  @override
  Future<void> addRoom({required int homeId, required String roomName}) async {
    await methodChannel.invokeMethod<void>("addRoom", <String, dynamic>{
      'homeId': homeId,
      'roomName': roomName,
    });
  }

  /// Remove device from a given room
  /// [homeId],[roomId],[devId] details are passed on to native
  /// removeDeviceFromRoom function on native is invoked
  @override
  Future<void> removeDeviceFromRoom({
    required int homeId,
    required int roomId,
    required String devId,
  }) async {
    await methodChannel.invokeMethod<void>(
      "removeDeviceFromRoom",
      <String, dynamic>{'homeId': homeId, 'roomId': roomId, 'devId': devId},
    );
  }

  /// Remove a group from a given room
  /// [homeId],[roomId],[groupId] details are passed on to native
  /// removeGroupFromRoom function of native is invoked
  @override
  Future<void> removeGroupFromRoom({
    required int homeId,
    required int roomId,
    required int groupId,
  }) async {
    await methodChannel.invokeMethod<void>(
      "removeGroupFromRoom",
      <String, dynamic>{'homeId': homeId, 'roomId': roomId, 'groupId': groupId},
    );
  }

  /// Remove room from a home
  /// [homeId],[roomId] details are passed on to native
  /// removeRoom function of native is invoked
  @override
  Future<void> removeRoom({required int homeId, required int roomId}) async {
    await methodChannel.invokeMethod<void>("removeRoom", <String, dynamic>{
      'homeId': homeId,
      'roomId': roomId,
    });
  }

  /// Sort the order of rooms in a home
  /// [homeId],[roomIds] details are passed on to native
  /// sortRooms function of native is invoked
  @override
  Future<void> sortRooms({
    required int homeId,
    required List<int> roomIds,
  }) async {
    await methodChannel.invokeMethod<void>("sortRooms", <String, dynamic>{
      'homeId': homeId,
      'roomIds': roomIds,
    });
  }

  /// Update the name of a given room
  /// [homeId],[roomId],[roomName] details are passed on to native
  /// updateRoomName function of native is invoked
  @override
  Future<void> updateRoomName({
    required int homeId,
    required int roomId,
    required String roomName,
  }) async {
    await methodChannel.invokeMethod<void>("updateRoomName", <String, dynamic>{
      'homeId': homeId,
      'roomId': roomId,
      'roomName': roomName,
    });
  }

  /// Unlock a bluetooth lock device
  /// [devId] details is passed on to native
  /// unlockBLELock function of native is invoked
  @override
  Future<void> unlockBLELock({required String devId}) async {
    await methodChannel.invokeMethod("unlockBLELock", <String, dynamic>{
      'devId': devId,
    });
  }

  /// Lock a bluetooth lock device
  /// [devId] details is passed on to native
  /// lockBLELock function of native is invoked
  @override
  Future<void> lockBLELock({required String devId}) async {
    await methodChannel.invokeMethod("lockBLELock", <String, dynamic>{
      'devId': devId,
    });
  }

  /// Reply to a unlock request on wifi lock
  /// [devId],[open] details are passed on to native
  /// unlockWifiLock function of native is invoked
  @override
  Future<void> unlockWifiLock({
    required String devId,
    required bool open,
  }) async {
    await methodChannel.invokeMethod("unlockWifiLock", <String, dynamic>{
      'devId': devId,
      'allow': open,
    });
  }

  /// Get a dynamic password for opening a wifi lock
  /// [devId] details is passed on to native
  /// dynamicWifiLockPassword function of native is invoked
  @override
  Future<String> dynamicWifiLockPassword({required String devId}) async {
    String? result = await methodChannel.invokeMethod<String>(
      'dynamicWifiLockPassword',
      <String, dynamic>{'devId': devId},
    );
    return result ?? "";
  }

  /// Check if a device is matter device or not
  /// [devId] details is passed on to native
  /// checkIfMatter function of native is invoked
  @override
  Future<bool> checkIfMatter({required String devId}) async {
    bool result = await methodChannel.invokeMethod(
      "checkIfMatter",
      <String, dynamic>{'devId': devId},
    );
    return result;
  }

  /// Send dps configuration to control the wifi device
  /// [devId],[dps] details are passed on to native
  /// controlMatter function of native is invoked
  @override
  Future<void> controlMatter({
    required String devId,
    required Map<String, dynamic> dps,
  }) async {
    await methodChannel.invokeMethod("controlMatter", <String, dynamic>{
      'devId': devId,
      'dps': dps,
    });
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Backup Wi‑Fi Networks / Wi‑Fi Switching
  // ──────────────────────────────────────────────────────────────────────────────

  @override
  Future<bool> isSupportBackupNetwork({required String devId}) async {
    return await methodChannel.invokeMethod<bool>(
          'isSupportBackupNetwork',
          <String, dynamic>{'devId': devId},
        ) ??
        false;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentWifiInfo({
    required String devId,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'getCurrentWifiInfo',
      <String, dynamic>{'devId': devId},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> getBackupWifiList({
    required String devId,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'getBackupWifiList',
      <String, dynamic>{'devId': devId},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> setBackupWifiList({
    required String devId,
    required List<Map<String, dynamic>> backupWifiList,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'setBackupWifiList',
      <String, dynamic>{'devId': devId, 'backupWifiList': backupWifiList},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<String> getBackupWifiHash({
    required String devId,
    required String ssid,
    required String password,
  }) async {
    return await methodChannel.invokeMethod<String>(
          'getBackupWifiHash',
          <String, dynamic>{'devId': devId, 'ssid': ssid, 'password': password},
        ) ??
        '';
  }

  @override
  Future<void> wifiBackupOnDestroy({required String devId}) async {
    await methodChannel.invokeMethod<void>(
      'wifiBackupOnDestroy',
      <String, dynamic>{'devId': devId},
    );
  }

  @override
  Future<Map<String, dynamic>?> switchToNewWifi({
    required String devId,
    required String ssid,
    required String password,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'switchToNewWifi',
      <String, dynamic>{'devId': devId, 'ssid': ssid, 'password': password},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> switchToBackupWifi({
    required String devId,
    required String hash,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'switchToBackupWifi',
      <String, dynamic>{'devId': devId, 'hash': hash},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<void> wifiSwitchOnDestroy({required String devId}) async {
    await methodChannel.invokeMethod<void>(
      'wifiSwitchOnDestroy',
      <String, dynamic>{'devId': devId},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> checkFirmwareUpgrade({
    required String devId,
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'checkFirmwareUpgrade',
      <String, dynamic>{'devId': devId},
    );
    return (result ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getFirmwareUpgradingStatus({
    required String devId,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'getFirmwareUpgradingStatus',
      <String, dynamic>{'devId': devId},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> startFirmwareUpgrade({
    required String devId,
    required List<Map<String, dynamic>> firmwares,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'startFirmwareUpgrade',
      <String, dynamic>{'devId': devId, 'firmwares': firmwares},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<void> confirmWarningUpgradeTask({
    required String devId,
    required bool isContinue,
  }) async {
    await methodChannel.invokeMethod<void>(
      'confirmWarningUpgradeTask',
      <String, dynamic>{'devId': devId, 'isContinue': isContinue},
    );
  }

  @override
  Future<void> cancelFirmwareUpgrade({
    required String devId,
    int? otaType,
  }) async {
    await methodChannel.invokeMethod<void>(
      'cancelFirmwareUpgrade',
      <String, dynamic>{'devId': devId, 'otaType': otaType},
    );
  }

  @override
  Future<int?> getAutoUpgradeSwitchInfo({required String devId}) async {
    return await methodChannel.invokeMethod<int?>(
      'getAutoUpgradeSwitchInfo',
      <String, dynamic>{'devId': devId},
    );
  }

  @override
  Future<void> saveAutoUpgradeSwitchInfo({
    required String devId,
    required int switchValue,
  }) async {
    await methodChannel.invokeMethod<void>(
      'saveAutoUpgradeSwitchInfo',
      <String, dynamic>{'devId': devId, 'switchValue': switchValue},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> memberCheckFirmwareStatus({
    required String devId,
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'memberCheckFirmwareStatus',
      <String, dynamic>{'devId': devId},
    );
    return (result ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Share one or more devices to a user and overwrite previous shares for that user.
  @override
  Future<Map<String, dynamic>> addShare({
    required int homeId,
    required String countryCode,
    required String userAccount,
    required List<String> devIds,
    List<String>? meshIds,
    bool autoSharing = false,
  }) async {
    final result = await methodChannel
        .invokeMethod<Map<dynamic, dynamic>>('addShare', <String, dynamic>{
          'homeId': homeId,
          'countryCode': countryCode,
          'userAccount': userAccount,
          'devIds': devIds,
          'meshIds': meshIds ?? [],
          'autoSharing': autoSharing,
        });
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Share devices to a user by member ID (append to existing shares).
  @override
  Future<void> addShareWithMemberId({
    required int memberId,
    required List<String> devIds,
  }) async {
    await methodChannel.invokeMethod<void>(
      'addShareWithMemberId',
      <String, dynamic>{'memberId': memberId, 'devIds': devIds},
    );
  }

  /// Share devices to a user by homeId + account (append to existing shares).
  @override
  Future<Map<String, dynamic>> addShareWithHomeId({
    required int homeId,
    required String countryCode,
    required String userAccount,
    required List<String> devIds,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'addShareWithHomeId',
      <String, dynamic>{
        'homeId': homeId,
        'countryCode': countryCode,
        'userAccount': userAccount,
        'devIds': devIds,
      },
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Query the users to whom current user has shared devices under homeId.
  @override
  Future<List<Map<String, dynamic>>> queryUserShareList({
    required int homeId,
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'queryUserShareList',
      <String, dynamic>{'homeId': homeId},
    );
    return (result ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Query all users from whom current user has received shared devices.
  @override
  Future<List<Map<String, dynamic>>> queryShareReceivedUserList() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'queryShareReceivedUserList',
    );
    return (result ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Query share details sent by current user to member [memberId].
  @override
  Future<Map<String, dynamic>> getUserShareInfo({required int memberId}) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getUserShareInfo',
      <String, dynamic>{'memberId': memberId},
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Query share details received from member [memberId].
  @override
  Future<Map<String, dynamic>> getReceivedShareInfo({
    required int memberId,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getReceivedShareInfo',
      <String, dynamic>{'memberId': memberId},
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Query the list of users who have been shared device [devId].
  @override
  Future<List<Map<String, dynamic>>> queryDevShareUserList({
    required String devId,
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'queryDevShareUserList',
      <String, dynamic>{'devId': devId},
    );
    return (result ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> queryShareDevFromInfo({
    required String devId,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'queryShareDevFromInfo',
      <String, dynamic>{'devId': devId},
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Remove all share relationships with user [memberId] (as the initiator).
  @override
  Future<void> removeUserShare({required int memberId}) async {
    await methodChannel.invokeMethod<void>('removeUserShare', <String, dynamic>{
      'memberId': memberId,
    });
  }

  @override
  Future<void> removeReceivedUserShare({required int memberId}) async {
    await methodChannel.invokeMethod<void>(
      'removeReceivedUserShare',
      <String, dynamic>{'memberId': memberId},
    );
  }

  /// Remove device [devId] from the active share with user [memberId].
  @override
  Future<void> disableDevShare({
    required String devId,
    required int memberId,
  }) async {
    await methodChannel.invokeMethod<void>('disableDevShare', <String, dynamic>{
      'devId': devId,
      'memberId': memberId,
    });
  }

  @override
  Future<void> removeReceivedDevShare({required String devId}) async {
    await methodChannel.invokeMethod<void>(
      'removeReceivedDevShare',
      <String, dynamic>{'devId': devId},
    );
  }

  /// Rename the nickname/note for a user you have shared devices with.
  @override
  Future<void> renameShareNickname({
    required int memberId,
    required String name,
  }) async {
    await methodChannel.invokeMethod<void>(
      'renameShareNickname',
      <String, dynamic>{'memberId': memberId, 'name': name},
    );
  }

  /// Rename the nickname/note for a user who shared devices with you.
  @override
  Future<void> renameReceivedShareNickname({
    required int memberId,
    required String name,
  }) async {
    await methodChannel.invokeMethod<void>(
      'renameReceivedShareNickname',
      <String, dynamic>{'memberId': memberId, 'name': name},
    );
  }

  /// Send a device share invitation to [userAccount] (returns share ID).
  @override
  Future<int> inviteShare({
    required String devId,
    required String userAccount,
    required String countryCode,
  }) async {
    final result = await methodChannel.invokeMethod<int>(
      'inviteShare',
      <String, dynamic>{
        'devId': devId,
        'userAccount': userAccount,
        'countryCode': countryCode,
      },
    );
    return result ?? 0;
  }

  /// Confirm a share invitation by [shareId].
  @override
  Future<void> confirmShareInvite({required int shareId}) async {
    await methodChannel.invokeMethod<void>(
      'confirmShareInvite',
      <String, dynamic>{'shareId': shareId},
    );
  }

  /// Query the list of users who are sharing group [groupId].
  @override
  Future<List<Map<String, dynamic>>> queryGroupSharedUserList({
    required int groupId,
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'queryGroupSharedUserList',
      <String, dynamic>{'groupId': groupId},
    );
    return (result ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<void> addShareUserForGroup({
    required int homeId,
    required String countryCode,
    required String userAccount,
    required int groupId,
  }) async {
    await methodChannel
        .invokeMethod<void>('addShareUserForGroup', <String, dynamic>{
          'homeId': homeId,
          'countryCode': countryCode,
          'userAccount': userAccount,
          'groupId': groupId,
        });
  }

  @override
  Future<void> removeGroupShare({
    required int groupId,
    required int memberId,
  }) async {
    await methodChannel.invokeMethod<void>(
      'removeGroupShare',
      <String, dynamic>{'groupId': groupId, 'memberId': memberId},
    );
  }
}
