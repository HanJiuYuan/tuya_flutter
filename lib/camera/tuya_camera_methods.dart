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

  /// 设置实时预览清晰度（2=标清，4=高清）
  static Future<void> setDefinition({required int definition}) {
    return TuyaCameraPlatform.instance.setDefinition(definition: definition);
  }

  /// 获取当前实时预览清晰度
  static Future<int> getDefinition() {
    return TuyaCameraPlatform.instance.getDefinition();
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

  /// 查询某年某月有录像的日期列表
  static Future<List<int>> queryRecordDaysByMonth({
    required String deviceId,
    required int year,
    required int month,
  }) {
    return TuyaCameraPlatform.instance.queryRecordDaysByMonth(
      deviceId: deviceId,
      year: year,
      month: month,
    );
  }

  /// 查询某天的视频片段时间信息
  static Future<List<Map<String, dynamic>>> queryRecordTimeSliceByDay({
    required String deviceId,
    required int year,
    required int month,
    required int day,
  }) {
    return TuyaCameraPlatform.instance.queryRecordTimeSliceByDay(
      deviceId: deviceId,
      year: year,
      month: month,
      day: day,
    );
  }

  /// 开始回放
  static Future<void> startPlayback({
    required String deviceId,
    required int startTime,
    required int endTime,
    required int playTime,
  }) {
    return TuyaCameraPlatform.instance.startPlayback(
      deviceId: deviceId,
      startTime: startTime,
      endTime: endTime,
      playTime: playTime,
    );
  }

  /// 停止回放
  static Future<void> stopPlayback({required String deviceId}) {
    return TuyaCameraPlatform.instance.stopPlayback(deviceId: deviceId);
  }

  /// 获取摄像头报警消息列表（含附件图片/视频）
  static Future<List<Map<String, dynamic>>> getCameraMessages({
    required String deviceId,
    int offset = 0,
    int limit = 20,
    List<String>? msgCodes,
  }) {
    return TuyaCameraPlatform.instance.getCameraMessages(
      deviceId: deviceId,
      offset: offset,
      limit: limit,
      msgCodes: msgCodes,
    );
  }

  /// 创建视频消息播放器并创建云设备
  static Future<void> createCloudVideoPlayer({required String deviceId}) {
    return TuyaCameraPlatform.instance.createCloudVideoPlayer(
      deviceId: deviceId,
    );
  }

  /// 播放报警消息中的云视频
  static Future<void> playCloudVideo({
    required String videoUrl,
    required int startTime,
    required String encryptKey,
  }) {
    return TuyaCameraPlatform.instance.playCloudVideo(
      videoUrl: videoUrl,
      startTime: startTime,
      encryptKey: encryptKey,
    );
  }

  /// 暂停云视频播放
  static Future<void> pauseCloudVideo() {
    return TuyaCameraPlatform.instance.pauseCloudVideo();
  }

  /// 恢复云视频播放
  static Future<void> resumeCloudVideo() {
    return TuyaCameraPlatform.instance.resumeCloudVideo();
  }

  /// 停止云视频播放
  static Future<void> stopCloudVideo() {
    return TuyaCameraPlatform.instance.stopCloudVideo();
  }

  /// 销毁云视频播放器
  static Future<void> destroyCloudVideo() {
    return TuyaCameraPlatform.instance.destroyCloudVideo();
  }

  /// 设置云视频静音
  static Future<void> setCloudVideoMute({required int mute}) {
    return TuyaCameraPlatform.instance.setCloudVideoMute(mute: mute);
  }

  /// 准备多目分屏直播，返回分割能力和分割协议信息
  static Future<Map<String, dynamic>> prepareMultiLiveStream({
    required String devId,
    int widthPixels = 0,
  }) {
    return TuyaCameraPlatform.instance.prepareMultiLiveStream(
      devId: devId,
      widthPixels: widthPixels,
    );
  }

  /// 绑定分屏渲染视图与镜头索引关系
  static Future<void> registerVideoViewIndexPairs({
    required String devId,
    required List<Map<String, dynamic>> pairs,
  }) {
    return TuyaCameraPlatform.instance.registerVideoViewIndexPairs(
      devId: devId,
      pairs: pairs,
    );
  }
}
