import Foundation
import Flutter
import ThingSmartActivatorKit      // Wi-Fi provisioning
import ThingSmartBLEKit            // BLE discovery & operations
import ThingSmartDeviceKit         // Device model
import ThingModuleServices         // Delegate protocols

public class BluetoothPairingManager: NSObject {
    // MARK: –– Dependencies
    private let bleManager = ThingSmartBLEManager.sharedInstance()
    private let wifiActivator = ThingSmartBLEWifiActivator.sharedInstance()
    private let activator = ThingSmartActivator.sharedInstance()

    // Callbacks back to Flutter
    public var discoveryCallback: FlutterResult?
    public var pairingEventSink: FlutterEventSink?

    // Cache for discovered BLE advertisement models
    private var discoveredDevices: [String: ThingBLEAdvModel] = [:]

    public override init() {
        super.init()
        bleManager.delegate = self
        // 当前 SDK 版本的 ThingSmartBLEWifiActivator 没有公开 delegate 属性，
        // 因此这里不能直接设置 wifiActivator 的 delegate。
    }

    // MARK: –– BLE Discovery
    public func startBleDiscovery() {
        discoveredDevices.removeAll()
        bleManager.startListening(true)
    }

    // MARK: –– Pure-BLE Activation
    public func activateBle(uuid: String, productId: String, homeId: Int64) {
        guard let adv = pendingAdvModel(uuid: uuid, productId: productId) else {
            pairingEventSink?([
                "event": "onPairingError",
                "message": "Device not found"
            ])
            return
        }
        bleManager.activeBLE(
            adv,
            homeId: homeId,
            success: { deviceModel in
                self.pairingEventSink?([
                    "event": "onPairingSuccess",
                    "deviceId": deviceModel.devId ?? "",
                    "name": deviceModel.name ?? ""
                ])
            },
            failure: {
                self.pairingEventSink?([
                    "event": "onPairingError",
                    "message": "BLE activation failed"
                ])
            }
        )
    }

    // MARK: –– Combo (BLE→Wi-Fi) Provisioning
    public func startConfigCombo(
        uuid: String,
        productId: String,
        homeId: Int64,
        ssid: String,
        password: String,
        timeout: TimeInterval
    ) {
        wifiActivator.startConfigBLEWifiDevice(
            withUUID: uuid,
            homeId: homeId,
            productId: productId,
            ssid: ssid,
            password: password,
            timeout: timeout,
            success: {
                self.pairingEventSink?([
                    "event": "onConfigSent"
                ])
            },
            failure: {
                self.pairingEventSink?([
                    "event": "onConfigError",
                    "message": "Combo pairing failed"
                ])
            }
        )
    }

    // MARK: –– Helpers
    private func cache(_ deviceInfo: ThingBLEAdvModel) {
        let key = "\(deviceInfo.uuid)_\(deviceInfo.productId)"
        discoveredDevices[key] = deviceInfo
    }

    private func pendingAdvModel(uuid: String, productId: String) -> ThingBLEAdvModel? {
        let key = "\(uuid)_\(productId)"
        return discoveredDevices[key]
    }
}

// MARK: - Cloud Activation for Combo Devices

extension BluetoothPairingManager {
    public func activateDeviceWifiInCloud(
        deviceId: String,
        ssid: String,
        password: String,
        timeout: TimeInterval = 100
    ) {
        bleManager.activeDualDeviceWifiChannel(
            deviceId,
            ssid: ssid,
            password: password,
            timeout: timeout,
            success: { deviceModel in
                self.pairingEventSink?([
                    "event": "onCloudActivationSuccess",
                    "deviceId": deviceModel.devId ?? "",
                    "name": deviceModel.name ?? ""
                ])
            },
            failure: { error in
                if let nsError = error as NSError? {
                    self.pairingEventSink?([
                        "event": "onCloudActivationError",
                        "code": nsError.code,
                        "message": nsError.localizedDescription
                    ])
                } else if let error = error {
                    self.pairingEventSink?([
                        "event": "onCloudActivationError",
                        "message": error.localizedDescription
                    ])
                } else {
                    self.pairingEventSink?([
                        "event": "onCloudActivationError",
                        "message": "Unknown error"
                    ])
                }
            }
        )
    }

    public func scanDeviceWifiNetworks(uuid: String) {
        wifiActivator.connectAndQueryWifiList(
            withUUID: uuid,
            success: {
                self.pairingEventSink?([
                    "event": "onWifiScanStarted"
                ])
            },
            failure: { error in
                self.pairingEventSink?([
                    "event": "onWifiScanError",
                    "message": error?.localizedDescription ?? "Unknown error"
                ])
            }
        )
    }

    public func startOptimizedPairing(
        uuid: String,
        token: String,
        ssid: String,
        password: String,
        timeout: TimeInterval = 120
    ) {
        wifiActivator.pairDevice(
            withUUID: uuid,
            token: token,
            ssid: ssid,
            pwd: password,
            timeout: Int(timeout)
        )
    }

    public func restartPairingWithNewWifi(
        uuid: String,
        token: String,
        ssid: String,
        password: String
    ) {
        let configModel = ThingBLEWifiConfigModel()
        configModel.uuid = uuid
        configModel.token = token
        configModel.ssid = ssid
        configModel.password = password

        wifiActivator.resumeConfigBLEWifiDevice(
            with: .setWifi,
            configModel: configModel
        )
    }
}

// MARK: - ThingSmartBLEManagerDelegate
extension BluetoothPairingManager: ThingSmartBLEManagerDelegate {
    public func didDiscoveryDevice(withDeviceInfo deviceInfo: ThingBLEAdvModel) {
        cache(deviceInfo)
        bleManager.queryDeviceInfo(
            withUUID: deviceInfo.uuid,
            productId: deviceInfo.productId,
            success: { info in
                var result = (info as? [String: Any]) ?? [:]
                result["uuid"] = deviceInfo.uuid
                result["productId"] = deviceInfo.productId
                result["mac"] = deviceInfo.mac
                result["bleType"] = deviceInfo.bleType.rawValue
                result["bleProtocolV"] = deviceInfo.bleProtocolV
                result["support5G"] = deviceInfo.isSupport5G
                result["name"] = result["name"]
                result["isProuductKey"] = result["isProuductKey"]
                result["icon"] = result["icon"]
                result["isSupportMultiUserShare"] = result["isSupportMultiUserShare"]
                // Add all available fields (name, icon, version, isActive, etc)
                result["isActive"] = deviceInfo.isActive
                // Print for debugging
                print("Device discovered: \(deviceInfo.uuid ?? "") - icon: \(result["icon"] ?? "none") - name: \(result["name"] ?? "none") - isProuductKey: \(result["isProuductKey"] ?? "none") - isSupportMultiUserShare: \(result["isSupportMultiUserShare"] ?? "none") - bleProtocolV: \(result["bleProtocolV"] ?? "none") - productId: \(deviceInfo.productId ?? "") - mac: \(deviceInfo.mac ?? "none")")
                self.discoveryCallback?(result)
            },
            failure: { _ in
                self.discoveryCallback?(FlutterError(
                    code: "BLE_QUERY_FAILED",
                    message: "Failed to query BLE device info",
                    details: nil
                ))
            }
        )
    }

    public func bluetoothDidUpdateState(_ isPoweredOn: Bool) {
        // Optional: forward Bluetooth state to Flutter if needed
    }
}

// MARK: - ThingSmartBLEWifiActivatorDelegate
extension BluetoothPairingManager: ThingSmartBLEWifiActivatorDelegate {
    public func bleWifiActivator(
        _ activator: ThingSmartBLEWifiActivator!,
        didScanWifiList wifiList: [Any]!,
        uuid: String!,
        error: Error?
    ) {
        if let error = error {
            pairingEventSink?([
                "event": "onWifiScanError",
                "message": error.localizedDescription
            ])
        } else {
            let networks = (wifiList as? [[String: Any]])?.map { network in
                return [
                    "ssid": network["ssid"] as? String ?? "",
                    "rssi": network["rssi"] as? Int ?? 0,
                    "security": network["security"] as? String ?? ""
                ]
            } ?? []

            pairingEventSink?([
                "event": "onWifiListReceived",
                "networks": networks,
                "uuid": uuid ?? ""
            ])
        }
    }

    public func bleWifiActivator(
        _ activator: ThingSmartBLEWifiActivator!,
        notConfigStateWithError error: Error!
    ) {
        pairingEventSink?([
            "event": "onDeviceNotReady",
            "message": error.localizedDescription
        ])
    }

    public func bleWifiActivator(
        _ activator: ThingSmartBLEWifiActivator!,
        didReceiveBLEWifiConfigDevice deviceModel: ThingSmartDeviceModel?,
        error: Error?
    ) {
        if let error = error {
            pairingEventSink?([
                "event": "onPairingError",
                "message": error.localizedDescription
            ])
        } else if let deviceModel = deviceModel {
            pairingEventSink?([
                "event": "onPairingSuccess",
                "deviceId": deviceModel.devId ?? "",
                "name": deviceModel.name ?? ""
            ])
        }
    }
}
