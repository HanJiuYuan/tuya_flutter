#
# tuya_flutter_ha_sdk.podspec
#
Pod::Spec.new do |s|
  s.name             = 'tuya_flutter_ha_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for Tuya Home Automation (user + device management).'
  s.description      = <<-DESC
A Flutter plugin for Tuya Home Automation (user + device management).
This plugin exposes Tuya’s user‒ and device‒management SDKs via MethodChannels.
                       DESC
  s.homepage         = 'http://kpmsg.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'KPMSG' => 'support@kpmsg.com' }
  s.source           = { :path => '.' }

  # Source files for the plugin‐level Swift classes:
  s.source_files = 'Classes/**/*.{h,m,swift}', 'Classes/*.swift'
  s.public_header_files = 'Classes/**/*.h'

  # Flutter framework dependency (DO NOT REMOVE):
  s.dependency 'Flutter'

  # Minimum iOS version & Swift version:
  s.platform    = :ios, '12.0'
  s.swift_version = '5.0'

  # Ensure Flutter.framework integration and exclude simulator i386 slices:
  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                       => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # ----------------------------------------------------------------------------
  # Tuya “BizBundle” Pods (public CocoaPods repo)
  # ----------------------------------------------------------------------------
  s.dependency 'ThingSmartPanelBizBundle',          '~> 6.2.0'
  s.dependency 'ThingSmartCameraRNPanelBizBundle',  '~> 6.2.0'
  s.dependency 'ThingSmartHomeKit',                  '~> 6.2.0'
  s.dependency 'ThingSmartOTABizBundle',             '~> 6.2.0'
  s.dependency 'ThingAdvancedFunctionsBizBundle',    '~> 6.2.0'
  s.dependency 'ThingSmartLockKit',                  '~> 6.2.0'
  s.dependency 'ThingSmartCameraPanelBizBundle',     '~> 6.2.0'
  s.dependency 'ThingSmartCameraKit',                '~> 6.2.0'
  s.dependency 'ThingSmartCameraSettingBizBundle',   '~> 6.2.0'
  s.dependency 'ThingSmartActivatorExtraBizBundle',  '~> 6.2.0'
  s.dependency 'ThingSmartActivatorBizBundle',       '~> 6.2.0'
  s.dependency 'ThingSmartFamilyBizBundle',          '~> 6.2.0'
  s.dependency 'ThingSmartDeviceKit',                '~> 5.10.3'

  # ──────────────────────────────────────────────────────────────────────────────
  # NOTE: We have REMOVED the local Cryption dependency here.
  #       The example app will declare it in its Podfile.
  # ──────────────────────────────────────────────────────────────────────────────
end
