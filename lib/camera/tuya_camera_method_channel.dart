import 'package:flutter/services.dart';
import 'tuya_camera_platform_interface.dart';

class TuyaCameraMethodChannel extends TuyaCameraPlatform {
  static const MethodChannel _channel = MethodChannel(
    'tuya_flutter_ha_sdk/camera',
  );

  /// Get a list of cameras added to a home
  /// [homeId] details is passed on to native
  /// listCamera function of native is invoked
  @override
  Future<List<Map<String, dynamic>>> listCameras({required int homeId}) async {
    final List<dynamic> result = await _channel.invokeMethod('listCameras', {
      'homeId': homeId,
    });
    return result.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Get the capabilities of a given camera device
  /// [deviceId] details is passed on to native
  /// getCameraCapabilities function of native is invoked
  @override
  Future<Map<String, dynamic>> getCameraCapabilities({
    required String deviceId,
  }) async {
    print("before calling capabilities");
    final Map result = await _channel.invokeMethod('getCameraCapabilities', {
      'deviceId': deviceId,
    });
    print("after calling capabilities");
    return Map<String, dynamic>.from(result);
  }

  /// Start live streaming of a given camera
  /// [deviceId] details is passed on to native
  /// startLiveStream function of native is invoked
  @override
  Future<void> startLiveStream({required String deviceId}) async {
    await _channel.invokeMethod('startLiveStream', {'deviceId': deviceId});
  }

  /// Stop live streaming of a given camera
  /// [deviceId] details is passed on to native
  /// stopLiveStream function of native is invoked
  @override
  Future<void> stopLiveStream({required String deviceId}) async {
    await _channel.invokeMethod('stopLiveStream', {'deviceId': deviceId});
  }

  /// Get alerts of a given device
  /// [deviceId], [year], [month] details are passed to native
  /// getDeviceAlerts function of native is invoked
  @override
  Future<List<Map<String, dynamic>>> getDeviceAlerts({
    required String deviceId,
    required int year,
    required int month,
  }) async {
    final List<dynamic> result = await _channel.invokeMethod(
      'getDeviceAlerts',
      {'deviceId': deviceId, 'year': year, 'month': month},
    );
    return result.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Save the current video to a given path
  /// [filePath] details is passed on to native
  /// saveVideoToGallery function of native is invoked
  @override
  Future<void> saveVideoToGallery({required String filePath}) async {
    await _channel.invokeMethod('saveVideoToGallery', {'filePath': filePath});
  }

  /// Stop saving the video
  /// stopSaveVideoToGallery function of native is invoked
  @override
  Future<void> stopSaveVideoToGallery() async {
    await _channel.invokeMethod('stopSaveVideoToGallery');
  }

  /// Configure a set of DP codes on a device
  /// [deviceId],[dps] details is passed on to native
  /// setDeviceDpConfigs function of native is invoked
  @override
  Future<bool> setDeviceDpConfigs({
    required String deviceId,
    required Map<String, dynamic> dps,
  }) async {
    // 专门打印 DP 235 的插件侧设置值，便于与原生/设备返回值对比
    if (dps.containsKey('235')) {
      print('235插件设置结果:${dps['235']}');
    }
    return await _channel.invokeMethod<bool>('setDeviceDpConfigs', {
          'deviceId': deviceId,
          'dps': dps,
        }) ??
        false;
  }

  /// Get the current configurations of set of DP codes on a device
  /// [deviceId] details is passed on to native
  /// getDeviceDpConfigs function of native is invoked
  @override
  Future<List<Map<String, dynamic>>> getDeviceDpConfigs({
    required String deviceId,
  }) async {
    final List<dynamic> result = await _channel.invokeMethod(
      'getDeviceDpConfigs',
      {'deviceId': deviceId},
    );
    return result.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Kick off APNs / FCM registration on the native side
  /// [type],[isOpen] details are passed on to native
  /// registerPush function of native is invoked
  @override
  Future<void> registerPush({required int type, required bool isOpen}) {
    return _channel.invokeMethod('registerPush', {
      'type': type,
      'isOpen': isOpen,
    });
  }

  /// Get all messages
  /// getAllMessages function of native is invoked
  @override
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final List<dynamic> result = await _channel.invokeMethod("getAllMessages");
    return result.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// 连接 P2P
  /// [devId] 设备ID
  /// connectP2P function of native is invoked
  @override
  Future<void> connectP2P({required String devId}) async {
    await _channel.invokeMethod('connectP2P', {'devId': devId});
  }

  /// 断开 P2P 连接
  /// disconnectP2P function of native is invoked
  @override
  Future<void> disconnectP2P() async {
    await _channel.invokeMethod('disconnectP2P');
  }

  /// 开始预览
  /// [clarity] 清晰度：2=标清，4=高清
  /// startPreview function of native is invoked
  @override
  Future<void> startPreview({required int clarity}) async {
    await _channel.invokeMethod('startPreview', {'clarity': clarity});
  }

  /// 停止预览
  /// stopPreview function of native is invoked
  @override
  Future<void> stopPreview() async {
    await _channel.invokeMethod('stopPreview');
  }

  /// 开始对讲
  /// startTalk function of native is invoked
  @override
  Future<void> startTalk() async {
    await _channel.invokeMethod('startTalk');
  }

  /// 停止对讲
  /// stopTalk function of native is invoked
  @override
  Future<void> stopTalk() async {
    await _channel.invokeMethod('stopTalk');
  }

  /// 设置静音状态（0=不静音，1=静音）
  /// setMute function of native is invoked
  @override
  Future<void> setMute({required int status}) async {
    await _channel.invokeMethod('setMute', {'status': status});
  }

  /// 截图当前视频画面，返回图片文件路径
  /// snapshot function of native is invoked
  @override
  Future<String?> snapshot({String? directory}) async {
    final result = await _channel.invokeMethod<String>('snapshot', {
      'directory': directory,
    });
    return result;
  }

  /// 使用配置进行截图（旋转角度、目录、文件名、是否保存到相册），返回图片文件路径
  /// snapshotWithConfig function of native is invoked
  @override
  Future<String?> snapshotWithConfig({
    String? directory,
    String? fileName,
    int rotateMode = 0,
    bool saveToAlbum = false,
  }) async {
    final result = await _channel.invokeMethod<String>('snapshotWithConfig', {
      'directory': directory,
      'fileName': fileName,
      'rotateMode': rotateMode,
      'saveToAlbum': saveToAlbum,
    });
    return result;
  }

  /// 切换扬声器/听筒播放（true=扬声器，false=听筒）
  /// setLoudSpeakerStatus function of native is invoked
  @override
  Future<void> setLoudSpeakerStatus({required bool enable}) async {
    await _channel.invokeMethod('setLoudSpeakerStatus', {'enable': enable});
  }
}
