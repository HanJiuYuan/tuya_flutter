import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'tuya_camera_method_channel.dart';

abstract class TuyaCameraPlatform extends PlatformInterface {
  TuyaCameraPlatform() : super(token: _token);

  static final Object _token = Object();

  static TuyaCameraPlatform _instance = TuyaCameraMethodChannel();

  static TuyaCameraPlatform get instance => _instance;

  static set instance(TuyaCameraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Get a list of cameras added to a home
  Future<List<Map<String, dynamic>>> listCameras({required int homeId});

  /// Get the capabilities of a given camera device
  Future<Map<String, dynamic>> getCameraCapabilities({
    required String deviceId,
  });

  /// Start live streaming of a given camera
  Future<void> startLiveStream({required String deviceId});

  /// Stop live streaming of a given camera
  Future<void> stopLiveStream({required String deviceId});

  /// Get alerts of a given device
  Future<List<Map<String, dynamic>>> getDeviceAlerts({
    required String deviceId,
    required int year,
    required int month,
  });

  /// Save the current video to a given path
  Future<void> saveVideoToGallery({required String filePath});

  /// Stop saving the video
  Future<void> stopSaveVideoToGallery();

  /// Configure a set of DP codes on a device
  Future<bool> setDeviceDpConfigs({
    required String deviceId,
    required Map<String, dynamic> dps,
  });

  /// Get the current configurations of set of DP codes on a device
  Future<List<Map<String, dynamic>>> getDeviceDpConfigs({
    required String deviceId,
  });

  /// Kick off APNs / FCM registration on the native side
  Future<void> registerPush({required int type, required bool isOpen});

  /// Get all messages
  Future<List<Map<String, dynamic>>> getAllMessages();

  /// 连接 P2P
  Future<void> connectP2P({required String devId});

  /// 断开 P2P 连接
  Future<void> disconnectP2P();

  /// 开始预览（清晰度：2=标清，4=高清）
  Future<void> startPreview({required int clarity});

  /// 停止预览
  Future<void> stopPreview();

  /// 开始对讲
  Future<void> startTalk();

  /// 停止对讲
  Future<void> stopTalk();

  /// 设置静音状态（0=不静音，1=静音）
  Future<void> setMute({required int status});

  /// 截图当前视频画面，返回图片文件路径
  Future<String?> snapshot({String? directory});

  /// 使用配置进行截图（旋转角度、目录、文件名、是否保存到相册），返回图片文件路径
  Future<String?> snapshotWithConfig({
    String? directory,
    String? fileName,
    int rotateMode = 0,
    bool saveToAlbum = false,
  });

  /// 切换扬声器/听筒播放（true=扬声器，false=听筒）
  Future<void> setLoudSpeakerStatus({required bool enable});
}
