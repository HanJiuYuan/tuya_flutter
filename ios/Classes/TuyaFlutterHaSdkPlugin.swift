import Flutter
import UIKit
import ThingSmartHomeKit
import ThingSmartDeviceKit
import ThingModuleServices
import ThingSmartActivatorKit
import ThingSmartBLEKit  // BLE discovery
import ThingSmartLockKit
import ThingSmartBusinessExtensionKit

public class TuyaFlutterHaSdkPlugin: NSObject, FlutterPlugin {
    //–– Pairing SDK state & event sink
    private let pairingManager = BluetoothPairingManager()
    private var activator: ThingSmartActivator?
    private var pairingEventSink: FlutterEventSink?
    private var discoveryCallback: FlutterResult?
    private var device: ThingSmartDevice?

    private var wifiNetworkManager: ThingDeviceNetworkManager?
    private var wifiNetworkDevId: String?

    private func ensureWifiNetworkManager(_ devId: String) -> ThingDeviceNetworkManager {
        if wifiNetworkManager == nil || wifiNetworkDevId != devId {
            wifiNetworkManager = ThingDeviceNetworkManager(deviceId: devId)
            wifiNetworkDevId = devId
        }
        return wifiNetworkManager!
    }

    private func networkInfoToMap(_ info: ThingDeviceNetworkInfo) -> [String: Any] {
        return [
            "network": info.network.rawValue,
            "ssid": info.ssid,
            "signal": info.signal,
            "flags": info.flags,
            "ssidHash": info.ssidHash
        ]
    }

    private func backupWifiModelToMap(_ model: ThingSmartBackupWifiModel) -> [String: Any] {
        var map: [String: Any] = [:]
        map["ssid"] = model.ssid
        let hashStr = (model.value(forKey: "hashValue") as? String)
        ?? (model.value(forKey: "hash") as? String)
        ?? ""
        map["hash"] = hashStr
        return map
    }

   private func firmwareModelToMap(_ model: ThingSmartFirmwareUpgradeModel) -> [String: Any] {
    return [
        "desc": model.desc ?? "",
        "type": model.type,
        "typeDesc": model.typeDesc ?? "",
        "upgradeStatus": model.upgradeStatus.rawValue, 
        "version": model.version ?? "",
        "currentVersion": model.currentVersion ?? "",
        "devType": model.devType,
        "upgradeType": model.upgradeType,
        "url": model.url ?? "",
        "fileSize": model.fileSize ?? "",
        "md5": model.md5 ?? "",
        "controlType": model.controlType,
        "waitingDesc": model.waitingDesc ?? "",
        "upgradingDesc": model.upgradingDesc ?? "",
        "canUpgrade": model.canUpgrade,
        "remind": model.remind ?? "",
        "upgradeMode": model.upgradeMode.rawValue
    ]
    }
    private func deviceModelToMap(_ dev: ThingSmartDeviceModel) -> [String: Any] {
        return[
            "devId": dev.devId ?? "",
            "name": dev.name ?? "",
            "productId": dev.productId ?? "",
            "uuid": dev.uuid ?? "",
            "iconUrl": dev.iconUrl ?? "",
            "isOnline": dev.isOnline,             // 在线状态
            "isCloudOnline": dev.isCloudOnline,   // 云端在线状态
            "homeId": dev.homeId,                 // 家庭 ID
            "roomId": dev.roomId,                 // 房间 ID
            "bv": "\(dev.bv)",                    // 固件基线版本 (Base Version)
            "pv": "\(dev.pv)",                    // 协议版本 (Protocol Version)
            "verSw": dev.verSw ?? "",             // 软件版本号 (Software Version)
            "dps": dev.dps ?? [:]                 // 数据点状态点 (DPs)
        ]
    }
    private func firmwareStatusToMap(_ status: ThingSmartFirmwareUpgradeStatusModel) -> [String: Any] {
        var map: [String: Any] = [
            "upgradeStatus": status.upgradeStatus.rawValue,
            "statusText": status.statusText ?? "",
            "statusTitle": status.statusTitle ?? "",
            "progress": status.progress,
            "type": status.type,
            "upgradeMode": status.upgradeMode.rawValue
        ]
        if let err = status.error as NSError? {
            map["error"] = [
                "code": err.code,
                "message": err.localizedDescription,
                "domain": err.domain
            ]
        }
        return map
    }

    private func memberFirmwareInfoToMap(_ info: ThingSmartMemberCheckFirmwareInfo) -> [String: Any] {
        return [
            "type": info.type,
            "upgradeStatus": info.upgradeStatus,
            "version": info.version ?? "",
            "upgradeText": info.upgradeText ?? ""
        ]
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TuyaFlutterHaSdkPlugin()
        let methodChannel = FlutterMethodChannel(
            name: "tuya_flutter_ha_sdk",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        let eventChannel = FlutterEventChannel(
            name: "tuya_flutter_ha_sdk/pairingEvents",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
        TuyaCameraPlugin.register(with: registrar)
    }
    
    // MARK: –– BLE Discovery Helpers
    
    private func startBleDiscovery(result: @escaping FlutterResult) {
        discoveryCallback = result
        _stopConfiguring()
        ThingSmartBLEManager.sharedInstance().delegate = self
        ThingSmartBLEManager.sharedInstance().startListening(true)
    }
    
    private func _stopConfiguring() {
        ThingSmartBLEManager.sharedInstance().delegate = nil
        ThingSmartBLEManager.sharedInstance().stopListening(true)
        activator?.delegate = nil
        activator?.stopConfigWiFi()
    }
    
    // MARK: –– MethodCall Dispatcher
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            
            // ── Core SDK ───────────────────────────────────────────────────────────────
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "tuyaSdkInit":
            // start method of the Tuya SDK is called with appKey and appSecret for initializing the SDK
            guard
                let args = call.arguments as? [String: Any],
                let appKey = args["appKey"] as? String,
                let appSecret = args["appSecret"] as? String,
                let isDebug = args["isDebug"] as? Bool
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "appKey and appSecret are required",
                                    details: nil))
                return
            }
            ThingSmartSDK.sharedInstance().start(
                withAppKey: appKey,
                secretKey: appSecret
            )
            ThingSmartSDK.sharedInstance().debugMode = isDebug
            result(nil)
            
            // ── User Management ─────────────────────────────────────────────────────────
        case "loginWithUid":
            // loginOrRegister function of the Tuya SDK is called with the passed on data
            guard
                let args = call.arguments as? [String: Any],
                let countryCode = args["countryCode"] as? String,
                let uid         = args["uid"] as? String,
                let password    = args["password"] as? String,
                let createHome  = args["createHome"] as? Bool
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "countryCode, uid, password, createHome required",
                                    details: nil))
                return
            }
            ThingSmartUser.sharedInstance().loginOrRegister(
                withCountryCode: countryCode,
                uid: uid,
                password: password,
                createHome: createHome,
                success: { userId in result(["uid": userId]) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "LOGIN_FAILED", message: msg, details: nil))
                }
            )
            
        case "checkLogin":
            // return the value of isLogin of the user instance of Tuya SDK
            result(ThingSmartUser.sharedInstance().isLogin)
            
            
        case "getCurrentUser":
            // returns the user details available in the user instance of the Tuya SDK
            let user = ThingSmartUser.sharedInstance()
            guard user.isLogin else {
                result(FlutterError(code: "NO_USER",
                                    message: "No user is currently logged in",
                                    details: nil))
                return
            }
            result([
                "uid": String(user.uid),
                "userName": user.userName,
                "email": user.email ?? "",
                "phoneNumber": user.phoneNumber ?? "",
                "countryCode": user.countryCode ?? "",
                "regionCode": user.regionCode ?? "",
                "headIconUrl": user.headIconUrl ?? "",
                "tempUnit": String(user.tempUnit),
                "timezoneId": user.timezoneId ?? "",
                "snsNickname": user.nickname ?? "",
                "regFrom": String(user.regFrom.rawValue)
            ])
            
        case "userLogout":
            // loginOut function of the Tuya SDK is called
            ThingSmartUser.sharedInstance().loginOut({
                result(nil)
            }, failure: { error in
                let msg = error?.localizedDescription ?? "Unknown error"
                result(FlutterError(code: "LOGOUT_FAILED", message: msg, details: nil))
            })

        case "isSupportBackupNetwork":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            result(ThingDeviceNetworkManager.supportWifiBackupNetwork(devId))

        case "getCurrentWifiInfo":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            let mgr = ensureWifiNetworkManager(devId)
            mgr.getCurrentNetworkInfo { info in
                result(self.networkInfoToMap(info))
            } failure: { error in
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }

        case "getBackupWifiList":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            let mgr = ensureWifiNetworkManager(devId)
            mgr.getBackupWifiNetworks { models, max in
                let list = models.map { self.backupWifiModelToMap($0) }
                result(["list": list, "max": max])
            } failure: { error in
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }

        case "setBackupWifiList":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false,
                  let list = args["backupWifiList"] as? [[String: Any]] else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId and backupWifiList are required", details: nil))
                return
            }
            let mgr = ensureWifiNetworkManager(devId)
            let models: [ThingSmartBackupWifiModel] = list.compactMap { item in
                let ssid = item["ssid"] as? String
                let pwd = item["passwd"] as? String
                let hash = item["hash"] as? String
                if let ssid, let pwd, pwd.isEmpty == false {
                    return mgr.generateBackupWifiModel(withSSID: ssid, pwd: pwd)
                }
                if let ssid, let hash, hash.isEmpty == false {
                    let model = ThingSmartBackupWifiModel()
                    model.ssid = ssid
                    model.setValue(hash, forKey: "hashValue")
                    return model
                }
                return nil
            }
            mgr.updateBackupWifiNetworks(models) {
                result(["success": true])
            } failure: { error in
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }

        case "switchToNewWifi":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false,
                  let ssid = args["ssid"] as? String,
                  ssid.isEmpty == false,
                  let password = args["password"] as? String else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId, ssid, password are required", details: nil))
                return
            }
            let mgr = ensureWifiNetworkManager(devId)
            mgr.switchBackupWifiNetwork(withSSID: ssid, pwd: password) {
                result(["success": true])
            } failure: { error in
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }

        case "switchToBackupWifi":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false,
                  let hash = args["hash"] as? String,
                  hash.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId and hash are required", details: nil))
                return
            }
            let mgr = ensureWifiNetworkManager(devId)
            mgr.switchBackupWifiNetwork(withHash: hash) {
                result(["success": true])
            } failure: { error in
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }

        case "wifiBackupOnDestroy":
            result(nil)

        case "wifiSwitchOnDestroy":
            result(nil)

        case "checkFirmwareUpgrade":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.checkFirmwareUpgrade({ firmwares in
                let list = firmwares.map { self.firmwareModelToMap($0) }
                result(list)
            }, failure: { error in
                let nsError = error as NSError?
                result(FlutterError(
                    code: String(nsError?.code ?? -1),
                    message: nsError?.localizedDescription ?? "Unknown error",
                    details: nil
                ))
            })

        case "getFirmwareUpgradingStatus":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.getFirmwareUpgradingStatus({ status in
                result(self.firmwareStatusToMap(status))
            }, failure: { error in
                let nsError = error as NSError?
                result(FlutterError(
                    code: String(nsError?.code ?? -1),
                    message: nsError?.localizedDescription ?? "Unknown error",
                    details: nil
                ))
            })

        case "startFirmwareUpgrade":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            let requestFirmwares = args["firmwares"] as? [[String: Any]] ?? []
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.checkFirmwareUpgrade({ firmwares in
                let candidates: [ThingSmartFirmwareUpgradeModel]
                if requestFirmwares.isEmpty {
                    candidates = firmwares.filter { $0.upgradeStatus.rawValue == 1 }
                } else {
                    let targets = requestFirmwares.compactMap { item -> String? in
                        guard let type = item["type"] else { return nil }
                        let mode = item["upgradeMode"] ?? 0
                        return "\(type)-\(mode)"
                    }
                    candidates = firmwares.filter { model in
                        targets.contains("\(model.type)-\(model.upgradeMode.rawValue)")
                    }
                }
                if candidates.isEmpty {
                    result(FlutterError(code: "NO_UPGRADABLE_FIRMWARE", message: "No firmware can be upgraded", details: nil))
                    return
                }
                self.device = device
                self.device?.delegate = self
                device.startFirmwareUpgrade(candidates)
                result(["started": true, "count": candidates.count])
            }, failure: { error in
                let nsError = error as NSError?
                result(FlutterError(
                    code: String(nsError?.code ?? -1),
                    message: nsError?.localizedDescription ?? "Unknown error",
                    details: nil
                ))
            })

        case "confirmWarningUpgradeTask":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false,
                  let isContinue = args["isContinue"] as? Bool else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId and isContinue are required", details: nil))
                return
            }
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.confirmWarningUpgradeTask(isContinue)
            result(nil)

        case "cancelFirmwareUpgrade":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.cancelFirmwareUpgrade({
                result(nil)
            }, failure: { error in
                let nsError = error as NSError?
                result(FlutterError(
                    code: String(nsError?.code ?? -1),
                    message: nsError?.localizedDescription ?? "Unknown error",
                    details: nil
                ))
            })

        case "getAutoUpgradeSwitchInfo":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.getAutoUpgradeSwitchInfo(success: { status in
                result(status)
            }, failure: { error in
                let nsError = error as NSError?
                result(FlutterError(
                    code: String(nsError?.code ?? -1),
                    message: nsError?.localizedDescription ?? "Unknown error",
                    details: nil
                ))
            })

        case "saveAutoUpgradeSwitchInfo":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false,
                  let switchValue = args["switchValue"] as? Int else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId and switchValue are required", details: nil))
                return
            }
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.saveUpgradeInfo(withSwitchValue: switchValue, success: {
                result(nil)
            }, failure: { error in
                let nsError = error as NSError?
                result(FlutterError(
                    code: String(nsError?.code ?? -1),
                    message: nsError?.localizedDescription ?? "Unknown error",
                    details: nil
                ))
            })

        case "memberCheckFirmwareStatus":
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  devId.isEmpty == false else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId is required", details: nil))
                return
            }
            guard let device = ThingSmartDevice(deviceId: devId) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device instance is nil", details: nil))
                return
            }
            device.memberCheckFirmwareStatus({ infos in
                let list = infos.map { self.memberFirmwareInfoToMap($0) }
                result(list)
            }, failure: { error in
                let nsError = error as NSError?
                result(FlutterError(
                    code: String(nsError?.code ?? -1),
                    message: nsError?.localizedDescription ?? "Unknown error",
                    details: nil
                ))
            })
            
        case "deleteAccount":
            // cancelAccount function of the Tuya SDK is called
            ThingSmartUser.sharedInstance().cancelAccount({
                result(nil)
            }, failure: { error in
                let msg = error?.localizedDescription ?? "Unknown error"
                result(FlutterError(code: "DELETE_FAILED", message: msg, details: nil))
            })
            
            // ── User Preferences ────────────────────────────────────────────────────────
        case "updateTimeZone":
            // updateTimeZone function of the Tuya SDK is called
            guard
                let args = call.arguments as? [String: Any],
                let tz = args["timeZoneId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "timeZoneId is required",
                                    details: nil))
                return
            }
            ThingSmartUser.sharedInstance().updateTimeZone(
                withTimeZoneId: tz,
                success: { result(nil) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "UPDATE_TIMEZONE_FAILED", message: msg, details: nil))
                }
            )
            
        case "updateTempUnit":
            // updateTempUnit of Tuya SDK is called
            guard
                let args = call.arguments as? [String: Any],
                let unit = args["tempUnit"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "tempUnit is required",
                                    details: nil))
                return
            }
            ThingSmartUser.sharedInstance().updateTempUnit(
                withTempUnit: unit,
                success: { result(nil) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "UPDATE_TEMPUNIT_FAILED", message: msg, details: nil))
                }
            )
            
        case "updateNickname":
            // updateNickname of the Tuya SDK is called
            guard
                let args = call.arguments as? [String: Any],
                let nick = args["nickname"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "nickname is required",
                                    details: nil))
                return
            }
            ThingSmartUser.sharedInstance().updateNickname(
                nick,
                success: { result(nil) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "UPDATE_NICKNAME_FAILED", message: msg, details: nil))
                }
            )
            
            // ── Smart Home Management ───────────────────────────────────────────────────
        case "createHome":
            // addHome function of the Tuya SDK is called
            guard
                let args = call.arguments as? [String: Any],
                let name = args["name"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "name is required", details: nil))
                return
            }
            let geoName = args["geoName"] as? String ?? ""
            let lat     = args["latitude"] as? Double ?? 0.0
            let lon     = args["longitude"] as? Double ?? 0.0
            let rooms   = args["rooms"] as? [String] ?? []
            ThingSmartHomeManager().addHome(
                withName: name,
                geoName: geoName,
                rooms: rooms,
                latitude: lat,
                longitude: lon,
                success: { homeId in result(Int(homeId)) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "CREATE_HOME_FAILED", message: msg, details: nil))
                }
            )
            
        case "getHomeList":
            // getHomeList of Tuya SDK is called
            ThingSmartHomeManager().getHomeList(
                success: { list in
                    let homes = (list ?? []).compactMap { ($0 as? ThingSmartHomeModel)?.toJson() }
                    result(homes)
                },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "GET_HOME_LIST_FAILED", message: msg, details: nil))
                }
            )
            
        case "updateHomeInfo":
            // updateHomeInfo function of Tuya SDK is called
            guard
                let args = call.arguments as? [String: Any],
                let homeId   = args["homeId"] as? Int,
                let homeName = args["homeName"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId and homeName required", details: nil))
                return
            }
            let geoName = args["geoName"] as? String ?? ""
            let lat     = args["latitude"] as? Double ?? 0.0
            let lon     = args["longitude"] as? Double ?? 0.0
            ThingSmartHome(homeId: Int64(homeId))?.updateInfo(
                withName: homeName,
                geoName: geoName,
                latitude: lat,
                longitude: lon,
                success: { result(nil) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "UPDATE_HOME_FAILED", message: msg, details: nil))
                }
            )
            
        case "deleteHome":
            // dismiss function of the Tuya SDK is called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId required", details: nil))
                return
            }
            ThingSmartHome(homeId: Int64(homeId))?.dismiss(
                success: { result(nil) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(code: "DELETE_HOME_FAILED", message: msg, details: nil))
                }
            )
            
        case "getHomeDevices":
            guard let args = call.arguments as? [String: Any],
                  let homeId = args["homeId"] as? Int else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId required", details: nil))
                return
            }
            let home = ThingSmartHome(homeId: Int64(homeId))
            home?.getDataWithSuccess({ homeModel in
                let devices = home?.deviceList.map { self.deviceModelToMap($0) } ?? []
                result(devices)
            }, failure: { error in
                result(FlutterError(code: "GET_FAILED", message: error?.localizedDescription, details: nil))
            })
            
            // ── Device Pairing Methods ───────────────────────────────────────────────────
        case "discoverDeviceInfo":
            pairingManager.discoveryCallback = result
            pairingManager.startBleDiscovery()
            
            // ── Device Pairing Methods ───────────────────────────────────────────────────
        case "getSSID":
            // getSSID function of Tuya SDK is called
            ThingSmartActivator.getSSID(
                { ssid in result(ssid) },
                failure: { error in
                    let msg = error?.localizedDescription ?? "Unknown error"
                    result(FlutterError(
                        code: "\(error?._code ?? -1)",
                        message: msg,
                        details: nil
                    ))
                }
            )
            
        case "updateLocation":
            // updateLatitude function of Tuya SDK is called
            if let args = call.arguments as? [String: Any],
               let lat = args["latitude"] as? Double,
               let lon = args["longitude"] as? Double {
                ThingSmartSDK.sharedInstance().updateLatitude(lat, longitude: lon)
                result(nil)
            } else {
                result(FlutterError(
                    code: "MISSING_ARGS",
                    message: "latitude & longitude required",
                    details: nil
                ))
            }
            
        case "getToken":
            // getTokenWithHomeId function of Tuya SDK is called
            if let args = call.arguments as? [String: Any],
               let homeId = args["homeId"] as? Int {
                ThingSmartActivator.sharedInstance()?.getTokenWithHomeId(
                    Int64(homeId),
                    success: { token in result(token) },
                    failure: { error in
                        let msg = (error as NSError?)?.localizedDescription
                        ?? "Unknown error"
                        result(FlutterError(
                            code: "( (error as NSError?)?.code ?? -1 )",
                            message: msg,
                            details: nil
                        ))
                    }
                )
            } else {
                result(FlutterError(
                    code: "MISSING_ARGS",
                    message: "homeId required",
                    details: nil
                ))
            }
            
        case "startConfigWiFi":
            // startConfigWiFi function of Tuya SDK is called
            if let args = call.arguments as? [String: Any],
               let mode    = args["mode"]     as? String,
               let ssid    = args["ssid"]     as? String,
               let pwd     = args["password"] as? String,
               let token   = args["token"]    as? String,
               let timeout = args["timeout"]  as? Int {
                let m: ThingActivatorMode = (mode == "AP") ? .AP : .EZ
                print("🔵 [Tuya] startConfigWiFi called with:")
                print("     mode: \(mode) (-> \(m == .AP ? "AP" : "EZ"))")
                print("     ssid: \(ssid)")
                print("     password: \(pwd)")
                print("     token: \(token)")
                print("     timeout: \(timeout)")
                activator = ThingSmartActivator.sharedInstance()
                activator?.delegate = self
                activator?.startConfigWiFi(
                    m,
                    ssid: ssid,
                    password: pwd,
                    token: token,
                    timeout: TimeInterval(timeout)
                )
                result(nil)
            } else {
                print("⛔️ [Tuya] startConfigWiFi missing args: \(call.arguments ?? [:])")
                result(FlutterError(
                    code: "MISSING_ARGS",
                    message: "mode, ssid, password, token, timeout required",
                    details: nil
                ))
            }
            
        case "stopConfigWiFi":
            // stopConfigWiFi function of Tuya SDK called
            activator?.delegate = nil
            activator?.stopConfigWiFi()
            result(nil)
            
        case "connectDeviceAndQueryWifiList":
            //connectDeviceAndQueryWifiList function of Tuya SDK called
            let timeout = (call.arguments as? [String: Any])?["timeout"] as? Int ?? 120
            activator = ThingSmartActivator.sharedInstance()
            activator?.delegate = self
            activator?.connectDeviceAndQueryWifiList(withTimeout: TimeInterval(timeout))
            result(nil)
            
            // ── Pure-BLE pairing ─────────────────────────────────────────────────────────
        case "pairBleDevice":
            // activateBle function of Tuya SDK called
            guard let args = call.arguments as? [String: Any],
                  let uuid      = args["uuid"] as? String,
                  let productId = args["productId"] as? String,
                  let homeId    = args["homeId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "uuid, productId, homeId required",
                                    details: nil))
                return
            }
            pairingManager.activateBle(uuid: uuid,
                                       productId: productId,
                                       homeId: Int64(homeId))
            result(nil)
            
            // ── Combo (BLE→Wi-Fi) pairing ─────────────────────────────────────────────────
        case "startComboPairing":
            //startConfigCombo function of Tuya SDK called
            guard let args = call.arguments as? [String: Any],
                  let uuid      = args["uuid"] as? String,
                  let productId = args["productId"] as? String,
                  let homeId    = args["homeId"] as? Int,
                  let ssid      = args["ssid"] as? String,
                  let password  = args["password"] as? String,
                  let timeout   = args["timeout"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "uuid, productId, homeId, ssid, password, timeout required",
                                    details: nil))
                return
            }
            pairingManager.startConfigCombo(uuid: uuid,
                                            productId: productId,
                                            homeId: Int64(homeId),
                                            ssid: ssid,
                                            password: password,
                                            timeout: TimeInterval(timeout))
            result(nil)
        case "initDevice":
            // ThingSmartDevice initializing
            guard
                let args = call.arguments as? [String: Any],
                let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            device=ThingSmartDevice(deviceId: devId)
            if (device == nil) {
                print("device is nil")
                result(FlutterError(code: "Thing Smart device ",
                                    message: "device is nil",
                                    details: nil))
                return
            }
            device!.delegate = self
            result(nil)
        case "queryDeviceInfo":
            // 1. 获取参数
            guard let infoArgs = call.arguments as? [String: Any],
                  let idStr = infoArgs["devId"] as? String else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId req", details: nil))
                return
            }

            // 2. 明确初始化，直接传入 idStr
            // 使用带类型的完整初始化路径
            if let tempDeviceInstance = ThingSmartDevice(deviceId: idStr) {
                
                let m = tempDeviceInstance.deviceModel
                
                // 3. 判断 model 是否包含数据
                if m.devId != nil {
                    // 这里调用我们改好的 deviceModelToMap
                    let finalMap = self.deviceModelToMap(m)
                    
                    // 打印调试
                    let currentBv = finalMap["bv"] as? String ?? "N/A"
                    print("Successfully matched device: \(idStr), Version: \(currentBv)")
                    
                    result(finalMap)
                } else {
                    print("Model is empty for devId: \(idStr)")
                    result(nil)
                }
            } else {
                result(nil)
            }
        case "removeDevice":
            //remove function of Tuya SDK called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            device=ThingSmartDevice(deviceId: devId)
            if (device == nil) {
                print("device is nil")
                result(FlutterError(code: "Thing Smart device ",
                                    message: "device is nil",
                                    details: nil))
                return
            }
            device?.remove({
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "restoreFactoryDefaults":
            // resetFactory function of Tuya SDK called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            device=ThingSmartDevice(deviceId: devId)
            if (device == nil) {
                print("device is nil")
                result(FlutterError(code: "Thing Smart device ",
                                    message: "device is nil",
                                    details: nil))
                return
            }
            device?.resetFactory({
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "queryDeviceWiFiStrength":
            // getWifiSignalStrength function of Tuya SDK called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            device=ThingSmartDevice(deviceId: devId)
            if (device == nil) {
                print("device is nil")
                result(FlutterError(code: "Thing Smart device ",
                                    message: "device is nil",
                                    details: nil))
                return
            }
            self.device?.getWifiSignalStrength(success: {
                
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "querySubDeviceList":
            // getSubDeviceListFromCloud function of Tuya SDK is called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            device=ThingSmartDevice(deviceId: devId)
            if (device == nil) {
                print("device is nil")
                result(FlutterError(code: "Thing Smart device ",
                                    message: "device is nil",
                                    details: nil))
                return
            }
            device?.getSubDeviceListFromCloud(success: { (subDeviceList) in
                result(subDeviceList)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "getRoomList":
            // getDataWithSuccess function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int
                    
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId required", details: nil))
                return
            }
            let home = ThingSmartHome(homeId: Int64(homeId))
            home?.getDataWithSuccess({ homeModel in
                // Access devices using: home?.deviceList
                var rooms = [[String: Any]]()
                home?.roomList.forEach { roomModel in
                    rooms.append(["roomId": roomModel.roomId, "roomName": roomModel.name])
                }
                result(rooms)
            }, failure: { error in
                let msg = error?.localizedDescription ?? "Unknown error"
                result(FlutterError(code: "GET_ROOMS_FAILED", message: msg, details: nil))
            })
        case "addRoom":
            // addRoom function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int,
                let roomName=args["roomName"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId and roomName required", details: nil))
                return
            }
            ThingSmartHome(homeId: Int64(homeId))?.addRoom(withName: roomName, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "removeRoom":
            // removeRoom function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int,
                let roomId=args["roomId"] as? Int64
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId and roomId required", details: nil))
                return
            }
            ThingSmartHome(homeId: Int64(homeId))?.removeRoom(withRoomId: roomId, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "sortRooms":
            // sortRoomList function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int64,
                let roomIds=args["roomIds"] as? [Int64]
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId and roomId required", details: nil))
                return
            }
            var rooms = [ThingSmartRoomModel]()
            roomIds.forEach{ roomId in
                rooms.append(ThingSmartRoom(roomId: roomId, homeId: homeId).roomModel)
            }
            
            ThingSmartHome(homeId: Int64(homeId))?.sortRoomList(rooms, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
            
            
        case "updateRoomName":
            //updateName function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int64,
                let roomId=args["roomId"] as? Int64,
                let roomName=args["roomName"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId, roomId,roomName required", details: nil))
                return
            }
            ThingSmartRoom(roomId: roomId, homeId: homeId)?.updateName(roomName, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "addDeviceToRoom":
            // addDevice function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int64,
                let roomId=args["roomId"] as? Int64,
                let devId=args["devId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId, roomId,devId required", details: nil))
                return
            }
            print("addDeviceToRoom")
            ThingSmartRoom(roomId: roomId, homeId: homeId)?.addDevice(withDeviceId: devId, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "removeDeviceFromRoom":
            // removeDevice function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int64,
                let roomId=args["roomId"] as? Int64,
                let devId=args["devId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId, roomId,devId required", details: nil))
                return
            }
            ThingSmartRoom(roomId: roomId, homeId: homeId)?.removeDevice(withDeviceId: devId, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "addGroupToRoom":
            // addGroup function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int64,
                let roomId=args["roomId"] as? Int64,
                let groupId=args["groupId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId, roomId,groupId required", details: nil))
                return
            }
            
            ThingSmartRoom(roomId: roomId, homeId: homeId)?.addGroup(withGroupId: groupId, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "removeGroupFromRoom":
            // removeGroup function of Tuya SDK called
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int64,
                let roomId=args["roomId"] as? Int64,
                let groupId=args["groupId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId, roomId,groupId required", details: nil))
                return
            }
            ThingSmartRoom(roomId: roomId, homeId: homeId)?.removeGroup(withGroupId: groupId, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "unlockBLELock":
            //bleUnlock function of Tuya SDK called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            
            let bleLockDevice = ThingSmartBLELockDevice(deviceId: devId)
            bleLockDevice?.getCurrentMemberDetail(withDevId: devId, gid: (bleLockDevice?.deviceModel.homeId)!, success: { [self] dict in
                print("Current member detail: \(String(describing: dict))")
                var bleUnlock: String?
                if let bleUserStr=dict?["lockUserId"] as? String{
                    bleUnlock=bleUserStr
                    
                }else if let bleUserInt = dict?["lockUserId"] as? Int{
                    bleUnlock=String(bleUserInt)
                }
//                if(bleUnlock == nil){
//                    result(FlutterError(
//                        code: "NO_LOCK_MEMBER",
//                        message: "No member found",
//                        details: nil
//                    ))
//                    return
//                }
                bleLockDevice!.bleUnlock(bleUnlock!, success: {
                    print("Door is unlocked")
                    result(nil)
                }, failure: { (error) in
                    let msg = (error as NSError?)?.localizedDescription
                    ?? "Unknown error"
                    result(FlutterError(
                        code: "( (error as NSError?)?.code ?? -1 )",
                        message: msg,
                        details: nil
                    ))
                })
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
            
            
            
            
        case "lockBLELock":
            //bleManualLock function of Tuya SDK is called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            let lockDevice = ThingSmartBLELockDevice(deviceId: devId)
            lockDevice?.bleManualLock({
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
            
        case "unlockWifiLock":
            //replyRemoteUnlock function of Tuya SDK is called
            guard let args = call.arguments as? [String: Any],
                  let devId = args["devId"] as? String,
                  let allow = args["allow"] as? Bool
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId and allow required",
                                    details: nil))
                return
            }
            print("in unlockWifiLock")
            let lockDevice = ThingSmartLockDevice(deviceId: devId)
            lockDevice?.replyRemoteUnlock(allow, success: {
                result(nil)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
            
            
        case "dynamicWifiLockPassword":
            //getLockDynamicPassword function of Tuya SDK is called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            print("in dynamicWifiLockPassword")
            let lockDevice = ThingSmartLockDevice(deviceId: devId)
            lockDevice?.getLockDynamicPassword(success: { (pwd) in
                print("The result of requesting dynamic password \(pwd)")
                result(pwd)
            }, failure: { (error) in
                let msg = (error as NSError?)?.localizedDescription
                ?? "Unknown error"
                result(FlutterError(
                    code: "( (error as NSError?)?.code ?? -1 )",
                    message: msg,
                    details: nil
                ))
            })
        case "checkIfMatter":
            //isSupportMatter function of Tuya SDK is called
            guard let args = call.arguments as? [String: Any],
                  let devId      = args["devId"] as? String
                    
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId required",
                                    details: nil))
                return
            }
            device=ThingSmartDevice(deviceId: devId)
            if (device == nil) {
                print("device is nil")
                result(FlutterError(code: "Thing Smart device ",
                                    message: "device is nil",
                                    details: nil))
                return
            }
            let isSupport = device?.deviceModel.isSupportMatter() ?? false
            print("isSupportMatter \(isSupport)")
            result(isSupport)
        case "controlMatter":
            //publishDps function of Tuya SDK is called
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

        // Share one or more devices to a user and overwrite previous shares
        case "addShare":
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int,
                let countryCode = args["countryCode"] as? String,
                let userAccount = args["userAccount"] as? String,
                let devIds = args["devIds"] as? [String]
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "homeId, countryCode, userAccount, devIds required",
                                    details: nil))
                return
            }
            let meshIds = args["meshIds"] as? [String] ?? []
            let autoSharing = args["autoSharing"] as? Bool ?? false
            let shareBean = ThingShareIdBean()
            shareBean.devIds = devIds
            shareBean.meshIds = meshIds
            ThingHomeSdk.getDeviceShareInstance().addShare(
                Int64(homeId),
                countryCode: countryCode,
                userAccount: userAccount,
                bean: shareBean,
                autoSharing: autoSharing,
                success: { sharedUser in
                    result(self.sharedUserInfoBeanToMap(sharedUser))
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Share devices to a user by member ID (append)
        case "addShareWithMemberId":
            guard
                let args = call.arguments as? [String: Any],
                let memberId = args["memberId"] as? Int,
                let devIds = args["devIds"] as? [String]
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "memberId, devIds required",
                                    details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().addShare(
                withMemberId: Int64(memberId),
                devIds: devIds,
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Share devices to a user by homeId + account (append)
        case "addShareWithHomeId":
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int,
                let countryCode = args["countryCode"] as? String,
                let userAccount = args["userAccount"] as? String,
                let devIds = args["devIds"] as? [String]
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "homeId, countryCode, userAccount, devIds required",
                                    details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().addShare(
                withHomeId: Int64(homeId),
                countryCode: countryCode,
                userAccount: userAccount,
                devIds: devIds,
                success: { sharedUser in
                    result(self.sharedUserInfoBeanToMap(sharedUser))
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Query the list of users to whom current user has shared devices
        case "queryUserShareList":
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "homeId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().queryUserShareList(
                Int64(homeId),
                success: { list in
                    let mapped = (list ?? []).map { self.sharedUserInfoBeanToMap($0) }
                    result(mapped)
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Query all users from whom current user has received shared devices
        case "queryShareReceivedUserList":
            ThingHomeSdk.getDeviceShareInstance().queryShareReceivedUserList(
                success: { list in
                    let mapped = (list ?? []).map { self.sharedUserInfoBeanToMap($0) }
                    result(mapped)
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Query share details sent by current user to member
        case "getUserShareInfo":
            guard
                let args = call.arguments as? [String: Any],
                let memberId = args["memberId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "memberId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().getUserShareInfo(
                Int64(memberId),
                success: { detail in
                    result(self.shareSentUserDetailBeanToMap(detail))
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Query share details received from a specific member
        case "getReceivedShareInfo":
            guard
                let args = call.arguments as? [String: Any],
                let memberId = args["memberId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "memberId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().getReceivedShareInfo(
                Int64(memberId),
                success: { detail in
                    result(self.shareReceivedUserDetailBeanToMap(detail))
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Query the list of users who have been shared a specific device
        case "queryDevShareUserList":
            guard
                let args = call.arguments as? [String: Any],
                let devId = args["devId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().queryDevShareUserList(
                devId,
                success: { list in
                    let mapped = (list ?? []).map { self.sharedUserInfoBeanToMap($0) }
                    result(mapped)
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Query the source of a shared device (who shared it to current user)
        case "queryShareDevFromInfo":
            guard
                let args = call.arguments as? [String: Any],
                let devId = args["devId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().queryShareDevFromInfo(
                devId,
                success: { sharedUser in
                    result(self.sharedUserInfoBeanToMap(sharedUser))
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Remove all share relationships with a user (as initiator)
        case "removeUserShare":
            guard
                let args = call.arguments as? [String: Any],
                let memberId = args["memberId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "memberId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().removeUserShare(
                Int64(memberId),
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Remove all received share relationships with a user (as receiver)
        case "removeReceivedUserShare":
            guard
                let args = call.arguments as? [String: Any],
                let memberId = args["memberId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "memberId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().removeReceivedUserShare(
                Int64(memberId),
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Remove a specific device from active share with a user
        case "disableDevShare":
            guard
                let args = call.arguments as? [String: Any],
                let devId = args["devId"] as? String,
                let memberId = args["memberId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId, memberId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().disableDevShare(
                devId,
                memberId: Int64(memberId),
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Remove a received shared device
        case "removeReceivedDevShare":
            guard
                let args = call.arguments as? [String: Any],
                let devId = args["devId"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "devId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().removeReceivedDevShare(
                devId,
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Rename the nickname/note for a user you have shared devices with
        case "renameShareNickname":
            guard
                let args = call.arguments as? [String: Any],
                let memberId = args["memberId"] as? Int,
                let name = args["name"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "memberId, name required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().renameShareNickname(
                Int64(memberId),
                name: name,
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Rename the nickname/note for a user who shared devices with you
        case "renameReceivedShareNickname":
            guard
                let args = call.arguments as? [String: Any],
                let memberId = args["memberId"] as? Int,
                let name = args["name"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "memberId, name required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().renameReceivedShareNickname(
                Int64(memberId),
                name: name,
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Send a device share invitation (returns share ID)
        case "inviteShare":
            guard
                let args = call.arguments as? [String: Any],
                let devId = args["devId"] as? String,
                let userAccount = args["userAccount"] as? String,
                let countryCode = args["countryCode"] as? String
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "devId, userAccount, countryCode required",
                                    details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().inviteShare(
                devId,
                userAccount: userAccount,
                countryCode: countryCode,
                success: { shareId in
                    result(shareId)
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Confirm a share invitation by share ID
        case "confirmShareInvite":
            guard
                let args = call.arguments as? [String: Any],
                let shareId = args["shareId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "shareId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().confirmShareInviteShare(
                Int32(shareId),
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Query the list of users who are sharing a specific group
        case "queryGroupSharedUserList":
            guard
                let args = call.arguments as? [String: Any],
                let groupId = args["groupId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "groupId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().queryGroupSharedUserList(
                Int64(groupId),
                success: { list in
                    let mapped = (list ?? []).map { self.sharedUserInfoBeanToMap($0) }
                    result(mapped)
                },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Share a group with a user
        case "addShareUserForGroup":
            guard
                let args = call.arguments as? [String: Any],
                let homeId = args["homeId"] as? Int,
                let countryCode = args["countryCode"] as? String,
                let userAccount = args["userAccount"] as? String,
                let groupId = args["groupId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS",
                                    message: "homeId, countryCode, userAccount, groupId required",
                                    details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().addShareUser(
                forGroup: Int64(homeId),
                countryCode: countryCode,
                userAccount: userAccount,
                groupId: Int64(groupId),
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        // Remove a member from a group share
        case "removeGroupShare":
            guard
                let args = call.arguments as? [String: Any],
                let groupId = args["groupId"] as? Int,
                let memberId = args["memberId"] as? Int
            else {
                result(FlutterError(code: "MISSING_ARGS", message: "groupId, memberId required", details: nil))
                return
            }
            ThingHomeSdk.getDeviceShareInstance().removeGroupShare(
                Int64(groupId),
                memberId: Int64(memberId),
                success: { result(nil) },
                failure: { error in
                    let nsErr = error as NSError?
                    result(FlutterError(code: String(nsErr?.code ?? -1),
                                        message: nsErr?.localizedDescription ?? "Unknown error",
                                        details: nil))
                }
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: – Share Helper Methods

    private func sharedUserInfoBeanToMap(_ bean: ThingSharedUserInfoBean?) -> [String: Any] {
        guard let b = bean else { return [:] }
        return [
            "memberId": b.memberId,
            "headPic": b.headPic ?? "",
            "name": b.name ?? "",
            "remarkName": b.remarkName ?? "",
            "shareDevList": (b.shareDevList ?? []).map { dev -> [String: Any] in
                return ["devId": dev.devId ?? "", "name": dev.name ?? ""]
            }
        ]
    }

    private func shareSentUserDetailBeanToMap(_ bean: ThingShareSentUserDetailBean?) -> [String: Any] {
        guard let b = bean else { return [:] }
        var map: [String: Any] = [
            "memberId": b.memberId,
            "headPic": b.headPic ?? "",
            "name": b.name ?? "",
            "remarkName": b.remarkName ?? ""
        ]
        if let devList = b.devList {
            map["devList"] = devList.map { dev -> [String: Any] in
                return ["devId": dev.devId ?? "", "name": dev.name ?? ""]
            }
        }
        return map
    }

    private func shareReceivedUserDetailBeanToMap(_ bean: ThingShareReceivedUserDetailBean?) -> [String: Any] {
        guard let b = bean else { return [:] }
        var map: [String: Any] = [
            "memberId": b.memberId,
            "headPic": b.headPic ?? "",
            "name": b.name ?? "",
            "remarkName": b.remarkName ?? ""
        ]
        if let devList = b.devList {
            map["devList"] = devList.map { dev -> [String: Any] in
                return ["devId": dev.devId ?? "", "name": dev.name ?? ""]
            }
        }
        return map
    }
}

// MARK: — FlutterStreamHandler
extension TuyaFlutterHaSdkPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        pairingManager.pairingEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        pairingManager.pairingEventSink = nil
        return nil
    }
}

// MARK: — ThingSmartBLEManagerDelegate
extension TuyaFlutterHaSdkPlugin: ThingSmartBLEManagerDelegate {
    public func didDiscoveryDevice(withDeviceInfo deviceInfo: ThingBLEAdvModel) {
        ThingSmartBLEManager.sharedInstance().queryDeviceInfo(
            withUUID: deviceInfo.uuid,
            productId: deviceInfo.productId,
            success: { info in
                guard let cloudInfo = info as? [String: Any] else {
                    self.discoveryCallback?(FlutterError(code: "NO_INFO",
                                                         message: "No device info returned",
                                                         details: nil))
                    self._stopConfiguring()
                    return
                }
                var merged = cloudInfo
                merged["uuid"] = deviceInfo.uuid
                merged["productId"] = deviceInfo.productId
                merged["mac"] = deviceInfo.mac
                merged["bleType"] = deviceInfo.bleType.rawValue
                
                self.discoveryCallback?(merged)
                self._stopConfiguring()
            },
            failure: { error in
                let nsErr = error as NSError?
                self.discoveryCallback?(FlutterError(code: "\(nsErr?.code ?? -1)",
                                                     message: nsErr?.localizedDescription,
                                                     details: nil))
                self._stopConfiguring()
            }
        )
    }
}

// MARK: — ThingSmartActivatorDelegate
extension TuyaFlutterHaSdkPlugin: ThingSmartActivatorDelegate {
    public func activator(_ activator: ThingSmartActivator!,
                          didReceiveDevice deviceModel: ThingSmartDeviceModel?,
                          error: Error?) {
        if let error = error {
            let code = (error as NSError).code
            let message = error.localizedDescription
            pairingEventSink?(["event": "onPairingError",
                               "code": code,
                               "message": message])
        } else if let deviceModel = deviceModel {
            pairingEventSink?(["event": "onPairingSuccess",
                               "deviceId": deviceModel.devId ?? "",
                               "name": deviceModel.name ?? ""]) }
    }
    
    public func activator(_ activator: ThingSmartActivator!,
                          didPassWIFIToSecurityLevelDeviceWithUUID uuid: String!) {
        pairingEventSink?(["event": "onPassWiFiToSecurityDevice",
                           "uuid": uuid ?? ""]) }
    
    
}
extension TuyaFlutterHaSdkPlugin: ThingSmartDeviceDelegate {
    open func device(_ device: ThingSmartDevice, dpsUpdate dps: [AnyHashable: Any]) {
        print(" DPS Update \(dps)")
        self.pairingEventSink?(device.deviceModel.dps)
        
    }
    
    
    open func deviceRemoved(_ device: ThingSmartDevice) {
        print(" Device Removed")
    }
    
    open func deviceInfoUpdate(_ device: ThingSmartDevice) {
        print(" Device Info Update")
        self.pairingEventSink?(device.deviceModel.dps)
    }
    public func device(_ device: ThingSmartDevice!, signal: String!) {
        print(" signal : \(signal)")
        self.pairingEventSink?(signal)
    }

    public func device(_ device: ThingSmartDevice, otaUpdateStatusChanged statusModel: ThingSmartFirmwareUpgradeStatusModel) {
        self.pairingEventSink?([
            "event": "otaUpdateStatusChanged",
            "devId": device.deviceModel.devId ?? "",
            "status": firmwareStatusToMap(statusModel)
        ])
    }
}
