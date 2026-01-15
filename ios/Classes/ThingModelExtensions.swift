// ios/Classes/ThingModelExtension.swift

import ThingSmartHomeKit

extension ThingSmartHomeModel {
  func toJson() -> [String: Any] {
    return [
      "homeId": homeId,
      "name": name ?? "",
      "geoName": geoName ?? "",
      "latitude": latitude,
      "longitude": longitude,
      "backgroundUrl": backgroundUrl ?? "",
      "role": role.rawValue,
      "dealStatus": dealStatus.rawValue,
      "managementStatus": managementStatus,
      "nickName": nickName ?? ""
    ]
  }
}
