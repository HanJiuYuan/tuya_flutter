//
//  TuyaCameraPlugin.swift
//

import Flutter
import UIKit
import ThingSmartHomeKit          // homes
import ThingSmartDeviceKit        // devices & DP
import ThingSmartCameraKit        // IPC preview & alerts
import ThingSmartCameraBase

// ──────────────────────────────────────────────────────────────────────────────
// MARK: – Main plugin
// ──────────────────────────────────────────────────────────────────────────────
public class TuyaCameraPlugin: NSObject, FlutterPlugin {
    
    private var eventSink: FlutterEventSink?    // push → Dart
    var tuyaCameraViewFactory:TuyaCameraViewFactory?
    
    // ────────── register with Flutter
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = TuyaCameraPlugin()
        
        
        // ① method-channel
        let mChannel = FlutterMethodChannel(
            name: "tuya_flutter_ha_sdk/camera",
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: mChannel)
        
        // ② event-channel
        let eChannel = FlutterEventChannel(
            name: "tuya_flutter_ha_sdk/notifications",
            binaryMessenger: registrar.messenger())
        eChannel.setStreamHandler(instance)
        
        // ③ platform view (live preview)
        instance.tuyaCameraViewFactory = TuyaCameraViewFactory()
        
        // Add callback for definition changes
        instance.tuyaCameraViewFactory?.definitionChangedCallback = { def in
            mChannel.invokeMethod("definitionChanged", arguments: ["definition": def])
        }
        
        registrar.register(instance.tuyaCameraViewFactory!, withId: "tuya_camera_view")
        
        // ④ native → Dart push bridge
        NotificationCenter.default.addObserver(
            forName: Notification.Name("TuyaCameraAlarmReceived"),
            object: nil,
            queue: .main
        ) { note in
            guard
                let payload = note.object as? [AnyHashable: Any],
                let sink    = instance.eventSink
            else { return }
            
            var map = [String: Any]()
            payload.forEach { if let k = $0.key as? String { map[k] = $0.value } }
            sink(map)
        }
        
        // ⑤ APNs device-token → Tuya SDK  (non-optional sharedInstance)
        NotificationCenter.default.addObserver(
            forName: Notification.Name("TuyaDeviceTokenReceived"),
            object: nil,
            queue: .main
        ) { note in
            if let token = note.object as? Data {
                ThingSmartSDK.sharedInstance().setDeviceToken(token, withError: nil)
            }
        }
    }
    
    // ────────── handle Dart calls
    public func handle(_ call: FlutterMethodCall,
                       result: @escaping FlutterResult) {

        switch call.method {
            
            // ───────────────────────── listCameras
        case "listCameras":
            //getDetailWithSuccess function of Tuya SDK is called
            guard
                let args   = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"homeId required", details:nil))
            }
            
            let home = ThingSmartHome(homeId: Int64(homeId))
            home?.getDetailWithSuccess({ _ in                    // ← updated selector
                let cams = home?.deviceList.compactMap { dev -> [String:Any]? in
                    guard dev.isIPCDevice() else { return nil }
                    return [
                        "devId"    : dev.devId     ?? "",
                        "name"     : dev.name      ?? "",
                        "iconUrl"  : dev.iconUrl   ?? "",
                        "productId": dev.productId ?? "",
                        "uuid"     : dev.uuid      ?? ""
                    ]
                } ?? []
                result(cams)
                
            }, failure: { err in
                result(FlutterError(code:"CAMERA_LIST_FAILED",
                                    message: err?.localizedDescription ?? "error",
                                    details:nil))
            })
            
            // ────────────── getCameraCapabilities
        case "getCameraCapabilities":
            // deviceModel data returned if isIPCDevice is true
            guard
                let args     = call.arguments as? [String: Any],
                let deviceId = args["deviceId"] as? String
                    
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"deviceId required", details:nil))
            }
            guard
                let device   = ThingSmartDevice(deviceId: deviceId)
            else {
                return result(FlutterError(code:"DEVICE_ERROR",
                                           message:"Not able to initialize device", details:nil))
            }
            let m = device.deviceModel
            guard m.isIPCDevice() else { return result([:]) }
            
            result([
                "isCamera"     : true,
                "p2pType"      : m.p2pType(),
                "uuid"         : m.uuid      ?? "",
                "productId"    : m.productId ?? "",
                "deviceName"   : m.name      ?? "",
                "isOnline"     : m.isOnline,
                "isCloudOnline": m.isCloudOnline
            ])
            
            // live-preview stubs
        case "startLiveStream":
            //startCamera function of the Platform view is called
            guard
                let args     = call.arguments as? [String: Any],
                let deviceId = args["deviceId"] as? String
                    
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"deviceId required", details:nil))
            }
            guard
                let device   = ThingSmartDevice(deviceId: deviceId)
            else {
                return result(FlutterError(code:"DEVICE_ERROR",
                                           message:"Not able to initialize device", details:nil))
            }
            let m = device.deviceModel
            guard m.isIPCDevice() else {
                return result(FlutterError(code:"DEVICE_ERROR",
                                           message:"Not an IPC device", details:nil))
            }
            guard m.isOnline else {
                return result(FlutterError(code:"DEVICE_ERROR",
                                           message:"Decice not online", details:nil))
            }
            
            result(nil)
            self.tuyaCameraViewFactory!.startCamera()
            
            
        case "stopLiveStream":
            //stopCamera function of the Platform view is called
            guard
                let args     = call.arguments as? [String: Any],
                let deviceId = args["deviceId"] as? String
                    
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"deviceId required", details:nil))
            }
            guard
                let device   = ThingSmartDevice(deviceId: deviceId)
            else {
                return result(FlutterError(code:"DEVICE_ERROR",
                                           message:"Not able to initialize device", details:nil))
            }
            let m = device.deviceModel
            guard m.isIPCDevice() else {
                return result(FlutterError(code:"DEVICE_ERROR",
                                           message:"Not an IPC device", details:nil))
            }
            guard m.isOnline else {
                return result(FlutterError(code:"DEVICE_ERROR",
                                           message:"Decice not online", details:nil))
            }
            self.tuyaCameraViewFactory!.stopCamera()
            result(nil)
            
            // ────────────── single-way talk & mute
        case "startTalk":
            self.tuyaCameraViewFactory?.startTalk()
            result(nil)
            
        case "stopTalk":
            self.tuyaCameraViewFactory?.stopTalk()
            result(nil)
            
        case "setMute":
            guard
                let args   = call.arguments as? [String: Any],
                let status = args["status"] as? Int
            else {
                return result(FlutterError(code: "MISSING_ARGS",
                                           message: "status required",
                                           details: nil))
            }
            self.tuyaCameraViewFactory?.setMute(status: status)
            result(nil)
            
        case "saveVideoToGallery":
            //startLocalRecording function of Platform view is called
            guard
                let args     = call.arguments as? [String: Any],
                let filePath = args["filePath"] as? String
                    
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"localPath required", details:nil))
            }
            self.tuyaCameraViewFactory!.startLocalRecording(filePath: filePath)
            result(nil)
        case "stopSaveVideoToGallery":
            //stopLocalRecording function of Platform view is called
            self.tuyaCameraViewFactory!.stopLocalRecording()
            result(nil)
            // ───────────────────────── getDeviceAlerts
        case "getDeviceAlerts":
            //messages function of Tuya SDK is called
            guard
                let args     = call.arguments as? [String: Any],
                let deviceId = args["deviceId"] as? String,
                let mgr      = ThingSmartCameraMessage(deviceId: deviceId,
                                                       timeZone: TimeZone.current)
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"deviceId required", details:nil))
            }
            
            mgr.messages(
                withMessageCodes: nil,
                offset: 0,
                limit: 200,
                startTime: 0,
                endTime: Int(Date().timeIntervalSince1970),
                success: { list in
                    guard let models = list as? [ThingSmartCameraMessageModel] else {
                        return result(FlutterError(code:"PARSE_ERROR",
                                                   message:"unexpected list", details:nil))
                    }
                    result(models.map {
                        [
                            "msgId"       : $0.msgId       ?? "",
                            "msgCode"     : $0.msgCode     ?? "",
                            "msgTitle"    : $0.msgTitle    ?? "",
                            "msgContent"  : $0.msgContent  ?? "",
                            "attachPic"   : $0.attachPic   ?? "",
                            "attachVideos": ($0.attachVideos as? [String]) ?? [],
                            "time"        : $0.time
                        ]
                    })
                },
                failure: { err in
                    result(FlutterError(code:"GET_ALERTS_FAILED",
                                        message: err?.localizedDescription ?? "error",
                                        details:nil))
                })
            
            // ───────────────────────── setDeviceDpConfigs
        case "setDeviceDpConfigs":
            // publishDps function of Tuya SDK called
            guard
                let args     = call.arguments as? [String: Any],
                let deviceId = args["deviceId"] as? String,
                let dps      = args["dps"]      as? [AnyHashable: Any],
                let device   = ThingSmartDevice(deviceId: deviceId)
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"deviceId & dps required",
                                           details:nil))
            }
            print("dps")
            print(dps)
            
            device.publishDps(dps,
                              success: { result(true) },
                              failure: { err in
                print(err)
                result(FlutterError(code:"DP_CONFIG_FAILED",
                                    message: err?.localizedDescription ?? "error",
                                    details:nil))
            })
            
            // ───────────────────────── getDeviceDpConfigs
        case "getDeviceDpConfigs":
            //dps property of device in Tuya SDK is used
            guard
                let args     = call.arguments as? [String : Any],
                let deviceId = args["deviceId"] as? String,
                let device   = ThingSmartDevice(deviceId: deviceId)
            else {
                return result(
                    FlutterError(code: "MISSING_ARGS",
                                 message: "deviceId required",
                                 details: nil))
            }
            
            // 1. full DP-schema description for the product
            let schemas = device.deviceModel.schemaArray as? [ThingSmartSchemaModel] ?? []
            
            // 2. the *current* DP values – keyed by **dpId string** ("101", "102", …)
            let current = device.deviceModel.dps as? [String : Any] ?? [:]
            // 3. build the list for Dart, looking-up by dpId string, not by code
            let list = schemas.map { s -> [String : Any] in
                let code  = s.code ?? ""
                let name  = s.name ?? code

                // dpId in ThingSmartSchemaModel can be NSNumber or String (bridged via ObjC).
                // We normalize it to a plain String like "103" so that it matches
                // the keys in device.deviceModel.dps (printed as [AnyHashable("103"): 1]).
                let dpIdKey: String
                if let idStr = s.dpId as? String {
                    dpIdKey = idStr
                } else if let idNum = s.dpId as? NSNumber {
                    dpIdKey = idNum.stringValue
                } else {
                    dpIdKey = String(describing: s.dpId)
                }

                let value = current[dpIdKey] ?? NSNull()
                let type  = s.type.description ?? ""
                // Lightweight debug to help trace DP mapping during development
                print("[Tuya][getDeviceDpConfigs] dpId=\(dpIdKey), code=\(code), value=\(String(describing: value))")
                return [
                    "dpId":  dpIdKey,
                    "code":  code,
                    "name":  name,
                    "type":  type,
                    "value": value
                ]
            }
            
            result(list)

            // ────────────── snapshot (iOS video frame capture)
        case "setDefinition":
            guard
                let args = call.arguments as? [String: Any],
                let definition = args["definition"] as? Int
            else {
                return result(FlutterError(code: "MISSING_ARGS", message: "definition required", details: nil))
            }
            self.tuyaCameraViewFactory?.setDefinition(definition)
            result(nil)
            
        case "getDefinition":
            self.tuyaCameraViewFactory?.getDefinition()
            result(nil)
            
        case "snapshot":
            // 截图当前正在预览的视频画面
            // 由 TuyaCameraPlatformView 使用 ThingSmartCameraType 的 snapShootSavedAtPath 实现
            tuyaCameraViewFactory?.snapshot(result: result)
            
        case "registerPush":
            //Different push functions called in Tuya SDK
            guard
                let args     = call.arguments as? [String: Any],
                let openType = args["type"] as? Int,
                let enable = args["isOpen"] as? Bool
            else {
                return result(FlutterError(code:"MISSING_ARGS",
                                           message:"deviceId required", details:nil))
            }
            switch(openType){
            case 0:
                ThingSmartSDK.sharedInstance().setDevicePushStatusWithStauts(enable, success: {
                    result(nil)
                }, failure: { err in
                    result(FlutterError(code:"ENABLE_PUSH_FAILED",
                                        message: err?.localizedDescription ?? "error",
                                        details:nil))
                })
            case 1:
                ThingSmartSDK.sharedInstance().setFamilyPushStatusWithStauts(enable, success: {
                    result(nil)
                }, failure: { err in
                    result(FlutterError(code:"ENABLE_PUSH_FAILED",
                                        message: err?.localizedDescription ?? "error",
                                        details:nil))
                    
                })
            case 2:
                ThingSmartSDK.sharedInstance().setNoticePushStatusWithStauts(enable, success: {
                    result(nil)
                }, failure: { err in
                    result(FlutterError(code:"ENABLE_PUSH_FAILED",
                                        message: err?.localizedDescription ?? "error",
                                        details:nil))
                    
                })
            case 3:
                ThingSmartSDK.sharedInstance().setMarketingPushStatusWithStauts(enable, success: {
                    result(nil)
                }, failure: { err in
                    result(FlutterError(code:"ENABLE_PUSH_FAILED",
                                        message: err?.localizedDescription ?? "error",
                                        details:nil))
                    
                })
                
            default:
                result(nil)
            }
            
            
            
            
        case "getAllMessages":
            //fetchList function of Tuya SDK called
            let requestModel = ThingSmartMessageListRequestModel()
            requestModel.msgType = .alarm
            requestModel.limit = 15
            requestModel.offset = 0
            
            let message = ThingSmartMessage()
            message.fetchList(with: requestModel) { list in
                guard let models = list as? [ThingSmartMessageListModel] else {
                    return result(FlutterError(code:"PARSE_ERROR",
                                               message:"unexpected list", details:nil))
                }
                result(models.map {
                    [
                        "msgId"       : $0.msgId       ?? "",
                        "msgCode"     : $0.msgCode     ?? "",
                        //"msgTitle"    : $0.msgTitle    ?? "",
                        "msgContent"  : $0.msgContent  ?? "",
                        //"attachPic"   : $0.attachPic   ?? "",
                        //"attachVideos": ($0.attachVideos as? [String]) ?? [],
                        "time"        : $0.time
                    ]
                })
            } failure: { err in
                result(FlutterError(code:"GET_ALL_MESSAGES_FAILED",
                                    message: err?.localizedDescription ?? "error",
                                    details:nil))
                
            }
            
        default: result("Check your method name")
            //default: result(FlutterMethodNotImplemented)
        }
    }
}

// ───────────────────────── EventChannel handler
extension TuyaCameraPlugin: FlutterStreamHandler {
    public func onListen(withArguments _: Any?,
                         eventSink sink: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = sink
        return nil
    }
    public func onCancel(withArguments _: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// ───────────────────────── Native preview view (unchanged)
class TuyaCameraViewFactory: NSObject, FlutterPlatformViewFactory {
    private var tuyaCameraPlatformView: TuyaCameraPlatformView?
    var definitionChangedCallback: ((Int) -> Void)?
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
    func create(withFrame frame: CGRect,
                viewIdentifier _: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        let devId = (args as? [String:Any])?["deviceId"] as? String ?? ""
        let platformView=TuyaCameraPlatformView(frame: frame, deviceId: devId)
        platformView.definitionChangedCallback = self.definitionChangedCallback
        tuyaCameraPlatformView=platformView
        return platformView
    }
    func startCamera(){
        if(tuyaCameraPlatformView != nil){
            tuyaCameraPlatformView!.startCamera()
        }
    }
    func stopCamera(){
        if(tuyaCameraPlatformView != nil){
            tuyaCameraPlatformView!.stopCamera()
        }
    }
    func startLocalRecording(filePath: String){
        if(tuyaCameraPlatformView != nil){
            tuyaCameraPlatformView!.startLocalRecording(filePath: filePath)
        }
    }
    func stopLocalRecording(){
        if(tuyaCameraPlatformView != nil){
            tuyaCameraPlatformView!.stopLocalRecording()
        }
    }
    
    // 清晰度控制
    func setDefinition(_ definition: Int) {
        tuyaCameraPlatformView?.setDefinition(definition)
    }
    func getDefinition() {
        tuyaCameraPlatformView?.getDefinition()
    }
    
    // 对讲 & 静音控制
    func startTalk() {
        tuyaCameraPlatformView?.startTalk()
    }
    func stopTalk() {
        tuyaCameraPlatformView?.stopTalk()
    }
    func setMute(status: Int) {
        tuyaCameraPlatformView?.setMute(status)
    }
    
    // 截图：转发到具体的 PlatformView 实现
    func snapshot(result: @escaping FlutterResult) {
        guard let view = tuyaCameraPlatformView else {
            result(FlutterError(code: "NO_CAMERA_VIEW",
                                message: "TuyaCameraPlatformView is nil",
                                details: nil))
            return
        }
        view.snapshot(result: result)
    }
}

class TuyaCameraPlatformView:
    NSObject, FlutterPlatformView, ThingSmartCameraDelegate {
    
    private let container = UIView()
    private var camera   : ThingSmartCameraType!
    private var sdkView  : UIView?
    private var isMuted  : Bool = false
    var definitionChangedCallback: ((Int) -> Void)?
    
    override init() {}
    
    init(frame: CGRect, deviceId: String) {
        print("platformView init")
        super.init()
        container.frame = frame
        
        guard
            !deviceId.isEmpty,
            let device = ThingSmartDevice(deviceId: deviceId),
            device.deviceModel.isIPCDevice(),
            let cam = ThingSmartCameraFactory.camera(
                withP2PType: NSNumber(value: device.deviceModel.p2pType()),
                deviceId   : deviceId,
                delegate   : self)
        else {
            container.backgroundColor = .black
            return
        }
        print(device.deviceModel.p2pType())
        camera = cam
        if let v = cam.videoView() {
            v.frame = container.bounds
            v.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            v.scaleToFill = true
            v.alpha = 0
            container.addSubview(v)
            sdkView = v
        } else {
            container.backgroundColor = .black
        }
        camera.enableMute(false, for: .preview)
        camera.connect?(with: .auto)
        camera.startPreview()
    }
    
    func view() -> UIView { container }
    deinit { camera.stopPreview(); camera.disConnect() }
    
    func cameraDidConnected(_ camera: ThingSmartCameraType!) {
        print("cameraDidConnected")
        camera.startPreview() }
    func cameraDidBeginPreview(_ camera: ThingSmartCameraType!) {
        print("cameraDidBeginPreview")
        DispatchQueue.main.async { UIView.animate(withDuration:0.3){ self.sdkView?.alpha = 1 } }
    }
    func cameraDidStopPreview(_ camera: ThingSmartCameraType!) {
        DispatchQueue.main.async { UIView.animate(withDuration:0.2){ self.sdkView?.alpha = 0 } }
    }
    func cameraDidDisconnected(_ camera: ThingSmartCameraType!, specificErrorCode _: Int) {}
    func camera(_ camera: ThingSmartCameraType!,
                didOccurredErrorAtStep stepError: ThingCameraErrorCode,
                specificErrorCode specificError: Int,extErrorCodeInfo: ThingSmartCameraExtErrorCodeInfo!) {
        print("camera error")
        print(extErrorCodeInfo.debugDescription ?? "No info")
        print(specificError)
        print(stepError)
    }
    func startCamera(){
        if(camera != nil){
            camera.connect?(with: .auto)
            camera.startPreview()
        }
    }
    func stopCamera(){
        // 主动停止预览并断开 P2P 连接，避免只 stopPreview 导致底层会话悬挂，
        // 出现多次调用后摄像头 SDK 报 -23 流冲突错误。
        camera.stopPreview()
        camera.disConnect()
    }
    func startLocalRecording(filePath:String){
        camera.startRecord!(withFilePath: filePath)
    }
    func stopLocalRecording(){
        camera.stopRecord()
    }
    
    // 单向对讲控制
    func startTalk() {
        camera.startTalk()
        if !isMuted {
            camera.enableMute(true, for: .preview)
        }
    }
    func stopTalk() {
        camera.stopTalk()
    }
    func setMute(_ status: Int) {
        let mute = (status == 1) // 1=静音,0=取消静音
        camera.enableMute(mute, for: .preview)
        isMuted = mute
    }
    
    func setDefinition(_ definition: Int) {
        // 尝试使用 rawValue 转换，如果失败默认使用 standard (0 or whatever)
        let def = ThingSmartCameraDefinition(rawValue: UInt(definition)) ?? .standard
        camera.setDefinition(def)
    }

    func getDefinition() {
        camera.getDefinition()
    }
    
    // ThingSmartCameraDelegate
    func camera(_ camera: ThingSmartCameraType!, definitionChanged definition: ThingSmartCameraDefinition) {
        print("definitionChanged: \(definition.rawValue)")
        definitionChangedCallback?(Int(definition.rawValue))
    }

    /// 使用 Tuya 相机 SDK 进行截图，将图片保存到 Documents/tuya_tmp_snapshots 目录
    /// 并将生成的绝对路径通过 FlutterResult 返回给 Dart
    func snapshot(result: @escaping FlutterResult) {
        guard camera != nil else {
            result(FlutterError(code: "NO_CAMERA",
                                message: "camera is nil",
                                details: nil))
            return
        }

        // 仅在预览开始后截图更合理，这里简单依赖当前相机状态即可
        // 如果你有额外的 previewing/playbacking 状态，可以在这里加判断

        do {
            // Documents 目录下创建临时截图目录
            let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                              .userDomainMask,
                                                              true).first ?? NSTemporaryDirectory()
            let snapshotDir = (docsDir as NSString).appendingPathComponent("tuya_tmp_snapshots")
            let dirUrl = URL(fileURLWithPath: snapshotDir)
            if !FileManager.default.fileExists(atPath: snapshotDir) {
                try FileManager.default.createDirectory(at: dirUrl,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }

            // 以时间戳命名文件
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "snapshot_\(timestamp).jpg"
            let filePath = (snapshotDir as NSString).appendingPathComponent(fileName)

            // 使用 Tuya SDK 截图并保存到指定路径（Swift 已将 API 重命名为 snapShootSaved(atPath:thumbnilPath:)）
            if let _ = camera.snapShootSaved?(atPath: filePath, thumbnilPath: nil) {
                // 截图成功，返回绝对路径给 Flutter
                result(filePath)
            } else {
                result(FlutterError(code: "SNAPSHOT_FAILED",
                                    message: "snapShootSavedAtPath returned nil",
                                    details: nil))
            }
        } catch {
            result(FlutterError(code: "SNAPSHOT_IO_ERROR",
                                message: error.localizedDescription,
                                details: nil))
        }
    }
}
