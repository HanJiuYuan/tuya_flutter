import 'tuya_camera_platform_interface.dart';

class TuyaCameraMethods {
  /// Get a list of cameras added to a home
  static Future<List<Map<String, dynamic>>> listCameras({required int homeId}) {
    return TuyaCameraPlatform.instance.listCameras(homeId: homeId);
  }

  /// Get the capabilities of a given camera device
  static Future<Map<String, dynamic>> getCameraCapabilities({
    required String deviceId,
  }) {
    return TuyaCameraPlatform.instance.getCameraCapabilities(
      deviceId: deviceId,
    );
  }

  /// Start live streaming of a given camera
  static Future<void> startLiveStream({required String deviceId}) {
    return TuyaCameraPlatform.instance.startLiveStream(deviceId: deviceId);
  }

  /// Stop live streaming of a given camera
  static Future<void> stopLiveStream({required String deviceId}) {
    return TuyaCameraPlatform.instance.stopLiveStream(deviceId: deviceId);
  }

  /// Get alerts of a given device
  static Future<List<Map<String, dynamic>>> getDeviceAlerts({
    required String deviceId,
    required int year,
    required int month,
  }) {
    return TuyaCameraPlatform.instance.getDeviceAlerts(
      deviceId: deviceId,
      year: year,
      month: month,
    );
  }

  /// Save the current video to a given path
  static Future<void> saveVideoToGallery({required String filePath}) {
    return TuyaCameraPlatform.instance.saveVideoToGallery(filePath: filePath);
  }

  /// Stop saving the video
  static Future<void> stopSaveVideoToGallery() {
    return TuyaCameraPlatform.instance.stopSaveVideoToGallery();
  }

  /// Configure a set of DP codes on a device
  static Future<bool> setDeviceDpConfigs({
    required String deviceId,
    required Map<String, dynamic> dps,
  }) {
    return TuyaCameraPlatform.instance.setDeviceDpConfigs(
      deviceId: deviceId,
      dps: dps,
    );
  }

  /// Get the current configurations of set of DP codes on a device
  static Future<List<Map<String, dynamic>>> getDeviceDpConfigs({
    required String deviceId,
  }) {
    return TuyaCameraPlatform.instance.getDeviceDpConfigs(deviceId: deviceId);
  }

  /// Kick off APNs / FCM registration on the native side
  static Future<void> registerPush({required int type, required bool isOpen}) {
    return TuyaCameraPlatform.instance.registerPush(type: type, isOpen: isOpen);
  }

  /// Get all messages
  static Future<List<Map<String, dynamic>>> getAllMessages() {
    return TuyaCameraPlatform.instance.getAllMessages();
  }

  /// 连接 P2P
  static Future<void> connectP2P({required String devId}) {
    return TuyaCameraPlatform.instance.connectP2P(devId: devId);
  }

  /// 断开 P2P 连接
  static Future<void> disconnectP2P() {
    return TuyaCameraPlatform.instance.disconnectP2P();
  }

  /// 开始预览（清晰度：2=标清，4=高清）
  static Future<void> startPreview({required int clarity}) {
    return TuyaCameraPlatform.instance.startPreview(clarity: clarity);
  }

  /// 停止预览
  static Future<void> stopPreview() {
    return TuyaCameraPlatform.instance.stopPreview();
  }

  /// 开始对讲
  static Future<void> startTalk() {
    print('开始对讲');
    return TuyaCameraPlatform.instance.startTalk();
  }

  /// 停止对讲
  static Future<void> stopTalk() {
    print('停止对讲');
    return TuyaCameraPlatform.instance.stopTalk();
  }

  /// 设置静音状态（0=不静音，1=静音）
  static Future<void> setMute({required int status}) {
    print('设置静音状态');
    return TuyaCameraPlatform.instance.setMute(status: status);
  }

  /// 截图当前视频画面，返回图片文件路径
  static Future<String?> snapshot({String? directory}) {
    return TuyaCameraPlatform.instance.snapshot(directory: directory);
  }

  /// 使用配置进行截图（旋转角度、目录、文件名、是否保存到相册），返回图片文件路径
  static Future<String?> snapshotWithConfig({
    String? directory,
    String? fileName,
    int rotateMode = 0,
    bool saveToAlbum = false,
  }) {
    return TuyaCameraPlatform.instance.snapshotWithConfig(
      directory: directory,
      fileName: fileName,
      rotateMode: rotateMode,
      saveToAlbum: saveToAlbum,
    );
  }

  /// 切换扬声器/听筒播放（true=扬声器，false=听筒）
  static Future<void> setLoudSpeakerStatus({required bool enable}) {
    return TuyaCameraPlatform.instance.setLoudSpeakerStatus(enable: enable);
  }
}
