import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'tuya_flutter_ha_sdk_method_channel.dart';

abstract class TuyaFlutterHaSdkPlatform extends PlatformInterface {
  /// Constructs a TuyaFlutterHaSdkPlatform.
  TuyaFlutterHaSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static TuyaFlutterHaSdkPlatform _instance = MethodChannelTuyaFlutterHaSdk();

  /// The default instance of [TuyaFlutterHaSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelTuyaFlutterHaSdk].
  static TuyaFlutterHaSdkPlatform get instance => _instance;

  /// Platform-specific plugins should register themselves by calling this setter.
  static set instance(TuyaFlutterHaSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Core SDK
  // ──────────────────────────────────────────────────────────────────────────────

  /// Returns the platform version, e.g. "iOS 18.5" or "Android 12".
  Future<String?> getPlatformVersion();

  /// Perform native-side initialization of the Tuya SDK.
  /// [appKey] and [appSecret] must match the current platform.
  Future<void> tuyaSdkInit({required String appKey, required String appSecret, required bool isDebug});

  // ──────────────────────────────────────────────────────────────────────────────
  // User Management
  // ──────────────────────────────────────────────────────────────────────────────

  /// Login (or register) with UID.
  /// [countryCode],[uid],[password],[createHome] details are passed on to the native
  Future<Map<String, dynamic>> loginWithUid({required String countryCode, required String uid, required String password, required bool createHome});

  /// Checks if any user is logged in currently.
  /// returns true if logged in and false if not logged in
  Future<bool> checkLogin();

  /// Get the current user’s info. Throws if no user is logged in.
  /// returns a map with all the user details
  Future<Map<String, dynamic>> getCurrentUser();

  /// Logs out the current user.
  Future<void> userLogout();

  /// Deletes the current user account.
  Future<void> deleteAccount();

  /// Updates the user’s time zone.
  /// [timeZoneId] is passed on to the native
  Future<void> updateTimeZone({required String timeZoneId});

  /// Changes the user’s temperature unit preference.
  /// [tempUnit] is passed on to the native
  Future<void> updateTempUnit({required int tempUnit});

  /// Updates the current user’s nickname.
  /// [nickname] is passed on to the native
  Future<void> updateNickname({required String nickname});

  // ──────────────────────────────────────────────────────────────────────────────
  // Smart Home Management
  // ──────────────────────────────────────────────────────────────────────────────

  /// Creates a new home.
  /// [name],[geoName],[rooms],[latitude],[longitude] details are passed on to the native
  /// Returns the new home ID.
  Future<int> createHome({required String name, String? geoName, List<String>? rooms, double? latitude, double? longitude});

  /// Retrieves a list of all homes.
  Future<List<Map<String, dynamic>>> getHomeList();

  /// Updates home information.
  /// [homeId],[homeName],[geoName],[latitude],[longitude] details are passed on to the native
  Future<void> updateHomeInfo({required int homeId, required String homeName, String? geoName, double? latitude, double? longitude});

  /// Deletes a home by ID.
  Future<void> deleteHome({required int homeId});

  /// Gets all devices for the given homeId.
  Future<List<Map<String, dynamic>>> getHomeDevices({required int homeId});

  // ──────────────────────────────────────────────────────────────────────────────
  // Device-Pairing Helpers
  // ──────────────────────────────────────────────────────────────────────────────

  /// Retrieves the current Wi-Fi SSID.
  Future<String?> getSSID();

  /// Updates the user’s location (latitude, longitude).
  Future<void> updateLocation({required double latitude, required double longitude});

  /// Retrieves a pairing token for the given homeId.
  Future<String?> getToken({required int homeId});

  /// Starts EZ or AP Wi-Fi pairing.
  Future<void> startConfigWiFi({required String mode, required String ssid, required String password, required String token, required int timeout});

  /// Stops any ongoing Wi-Fi pairing.
  Future<void> stopConfigWiFi();

  /// Connects to device AP and queries Wi-Fi networks (AP+ flow).
  Future<void> connectDeviceAndQueryWifiList({required int timeout});

  /// Completes AP+ pairing with SSID/password/token.
  Future<void> resumeAPPlus({required String ssid, required String password, required String token, required int timeout});

  // ──────────────────────────────────────────────────────────────────────────────
  // BLE Device Discovery & Pairing
  // ──────────────────────────────────────────────────────────────────────────────

  /// Scans for the first inactivated BLE device advertising Tuya packets.
  /// Returns its raw JSON map, or null if none found.
  Future<Map<String, dynamic>?> discoverDeviceInfo();

  /// Activate (pair) a pure-BLE device with the cloud.
  Future<Map<String, dynamic>?> pairBleDevice({
    required String uuid,
    required String productId,
    required int homeId,
    int? deviceType,
    String? address,
    int? flag,
    int? timeout
  });

  /// Start combo (BLE→Wi-Fi) pairing for a device.
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
    int? flag
  });

  /// Init the device
  Future<void> initDevice({required String devId});

  /// Query information about a device
  Future<Map<String, dynamic>?> queryDeviceInfo({required String devId, List<String>? dps});

  /// Rename a specific device
  Future<void> renameDevice({required String devId, required String name});

  /// Remove a specific device
  Future<void> removeDevice({required String devId});

  /// Restore factory defaults for a specific device
  Future<void> restoreFactoryDefaults({required String devId});

  /// Get the signal strength of a specific device
  Future<String?> queryDeviceWiFiStrength({required String devId});

  /// Query details of any sub devices
  Future<Map<String, dynamic>?> querySubDeviceList({required String devId});

  /// Get rooms details for a home
  Future<List<Map<String, dynamic>>?> getRoomList({required int homeId});

  /// Add a room to a home
  Future<void> addRoom({required int homeId, required String roomName});

  /// Remove room from a home
  Future<void> removeRoom({required int homeId, required int roomId});

  /// Sort the order of rooms in a home
  Future<void> sortRooms({required int homeId, required List<int> roomIds});

  /// Update the name of a given room
  Future<void> updateRoomName({required int homeId, required int roomId, required String roomName});

  /// Add a given device to a room
  Future<void> addDeviceToRoom({required int homeId, required int roomId, required String devId});

  /// Remove device from a given room
  Future<void> removeDeviceFromRoom({required int homeId, required int roomId, required String devId});

  /// Add a group to a given room
  Future<void> addGroupToRoom({required int homeId, required int roomId, required int groupId});

  /// Remove a group from a given room
  Future<void> removeGroupFromRoom({required int homeId, required int roomId, required int groupId});

  /// Unlock a bluetooth lock device
  Future<void> unlockBLELock({required String devId});

  /// Lock a bluetooth lock device
  Future<void> lockBLELock({required String devId});

  /// Reply to a unlock request on wifi lock
  Future<void> unlockWifiLock({required String devId,required bool open});

  /// Get a dynamic password for opening a wifi lock
  Future<String> dynamicWifiLockPassword({required String devId});

  /// Check if a device is matter device or not
  Future<bool> checkIfMatter({required String devId});

  /// Send dps configuration to control the wifi device
  Future<void> controlMatter({required String devId,required Map<String,dynamic> dps});
}
