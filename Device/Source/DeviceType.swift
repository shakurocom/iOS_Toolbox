//
// original was created by Johannes Schickling on 7/20/15
// https://github.com/schickling/Device.swift/blob/master/Device/UIDeviceExtension.swift
//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit

/// Enum representing the different types of iOS devices available
public enum DeviceType: String, EnumProtocol {
    case iPhone2G

    case iPhone3G
    case iPhone3GS

    case iPhone4
    case iPhone4S

    case iPhone5
    case iPhone5C
    case iPhone5S

    case iPhone6
    case iPhone6Plus

    case iPhone6S
    case iPhone6SPlus

    case iPhoneSE

    case iPhone7
    case iPhone7Plus

    case iPhone8
    case iPhone8Plus

    case iPhoneX

    case iPodTouch1G
    case iPodTouch2G
    case iPodTouch3G
    case iPodTouch4G
    case iPodTouch5G
    case iPodTouch6G

    case iPad
    case iPad2
    case iPad3
    case iPad4
    case iPadMini
    case iPadMiniRetina
    case iPadMini3
    case iPadMini4

    case iPadAir
    case iPadAir2

    case iPadPro9Inch
    case iPadPro12Inch

    case simulator
    case notAvailable
}

public extension DeviceType {

    /**
     Returns the current device type
     */
    public static var current: DeviceType {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machine = systemInfo.machine
        let mirror = Mirror(reflecting: machine)
        var identifier = ""

        for child in mirror.children {
            if let value = child.value as? Int8, value != 0 {
                identifier.append(String(UnicodeScalar(UInt8(value))))
            }
        }
        return DeviceType(identifier: identifier)
    }

    /**
     Returns the current model.
     For real devices this property will return same result as `current`.
     For Simulator it will return simulated device model.
     This property is supposed to never return `DeviceType.simulator` value - use `current` if you need to detect simulator.
     */
    public static var model: DeviceType {
        var deviceType = DeviceType.current
        if deviceType == .simulator {
            deviceType = DeviceType(identifier: String(cString: getenv("SIMULATOR_MODEL_IDENTIFIER")))
        }
        return deviceType
    }

    /**
     Returns the display name of the device type
     */
    public var displayName: String {
        switch self {
        case .iPhone2G: return "iPhone 2G"
        case .iPhone3G: return "iPhone 3G"
        case .iPhone3GS: return "iPhone 3GS"
        case .iPhone4: return "iPhone 4"
        case .iPhone4S: return "iPhone 4S"
        case .iPhone5: return "iPhone 5"
        case .iPhone5C: return "iPhone 5C"
        case .iPhone5S: return "iPhone 5S"
        case .iPhone6Plus: return "iPhone 6 Plus"
        case .iPhone6: return "iPhone 6"
        case .iPhone6S: return "iPhone 6S"
        case .iPhone6SPlus: return "iPhone 6S Plus"
        case .iPhoneSE: return "iPhone SE"
        case .iPhone7: return "iPhone 7"
        case .iPhone7Plus: return "iPhone 7 Plus"
        case .iPhone8: return "iPhone 8"
        case .iPhone8Plus: return "iPhone 8 Plus"
        case .iPhoneX: return "iPhone X"
        case .iPodTouch1G: return "iPod Touch 1G"
        case .iPodTouch2G: return "iPod Touch 2G"
        case .iPodTouch3G: return "iPod Touch 3G"
        case .iPodTouch4G: return "iPod Touch 4G"
        case .iPodTouch5G: return "iPod Touch 5G"
        case .iPodTouch6G: return "iPod Touch 6G"
        case .iPad: return "iPad"
        case .iPad2: return "iPad 2"
        case .iPad3: return "iPad 3"
        case .iPad4: return "iPad 4"
        case .iPadMini: return "iPad Mini"
        case .iPadMiniRetina: return "iPad Mini Retina"
        case .iPadMini3: return "iPad Mini 3"
        case .iPadMini4: return "iPad Mini 4"
        case .iPadAir: return "iPad Air"
        case .iPadAir2: return "iPad Air 2"
        case .iPadPro9Inch: return "iPad Pro 9 Inch"
        case .iPadPro12Inch: return "iPad Pro 12 Inch"
        case .simulator: return "Simulator"
        case .notAvailable: return "Not Available"
        }
    }

    public var identifiers: [String] {
        switch self {
        case .notAvailable: return []
        case .simulator: return ["i386", "x86_64"]

        case .iPhone2G: return ["iPhone1,1"]
        case .iPhone3G: return ["iPhone1,2"]
        case .iPhone3GS: return ["iPhone2,1"]
        case .iPhone4: return ["iPhone3,1", "iPhone3,2", "iPhone3,3"]
        case .iPhone4S: return ["iPhone4,1"]
        case .iPhone5: return ["iPhone5,1", "iPhone5,2"]
        case .iPhone5C: return ["iPhone5,3", "iPhone5,4"]
        case .iPhone5S: return ["iPhone6,1", "iPhone6,2"]
        case .iPhone6: return ["iPhone7,2"]
        case .iPhone6Plus: return ["iPhone7,1"]
        case .iPhone6S: return ["iPhone8,1"]
        case .iPhone6SPlus: return ["iPhone8,2"]
        case .iPhoneSE: return ["iPhone8,4"]
        case .iPhone7: return ["iPhone9,1", "iPhone9,3"]
        case .iPhone7Plus: return ["iPhone9,2", "iPhone9,4"]
        case .iPhone8: return ["iPhone10,1", "iPhone10,4"]
        case .iPhone8Plus: return ["iPhone10,2", "iPhone10,5"]
        case .iPhoneX: return ["iPhone10,3", "iPhone10,6"]

        case .iPodTouch1G: return ["iPod1,1"]
        case .iPodTouch2G: return ["iPod2,1"]
        case .iPodTouch3G: return ["iPod3,1"]
        case .iPodTouch4G: return ["iPod4,1"]
        case .iPodTouch5G: return ["iPod5,1"]
        case .iPodTouch6G: return ["iPod7,1"]

        case .iPad: return ["iPad1,1", "iPad1,2"]
        case .iPad2: return ["iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4"]
        case .iPad3: return ["iPad3,1", "iPad3,2", "iPad3,3"]
        case .iPad4: return ["iPad3,4", "iPad3,5", "iPad3,6"]
        case .iPadMini: return ["iPad2,5", "iPad2,6", "iPad2,7"]
        case .iPadMiniRetina: return ["iPad4,4", "iPad4,5", "iPad4,6"]
        case .iPadMini3: return ["iPad4,7", "iPad4,8", "iPad4,9"]
        case .iPadMini4: return ["iPad5,1", "iPad5,2"]
        case .iPadAir: return ["iPad4,1", "iPad4,2", "iPad4,3"]
        case .iPadAir2: return ["iPad5,3", "iPad5,4"]
        case .iPadPro9Inch: return ["iPad6,3", "iPad6,4"]
        case .iPadPro12Inch: return ["iPad6,7", "iPad6,8"]
        }
    }

    /** Creates a device type
     - parameter identifier: The identifier of the device
     - returns: The device type based on the provided identifier
     */
    private init(identifier: String) {
        var value: DeviceType? = nil
        for device in DeviceType.all {
            for deviceId in device.identifiers {
                if identifier == deviceId {
                    value = device
                    break
                }
            }
        }
        if let nonNilValue = value {
            self = nonNilValue
        } else {
            self = .notAvailable
        }
    }
}

// MARK: - EnumProtocol

public protocol EnumProtocol: Hashable {

    /// - returns: All Enum Values
    static var all: [Self] { get }

}

public extension EnumProtocol {

    public static var all: [Self] {
        typealias Type = Self
        let cases = AnySequence({ () -> AnyIterator<Type> in
            var raw = 0
            return AnyIterator({
                let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: Type.self, capacity: 1) { $0.pointee } }
                let result: Self?
                if current.hashValue == raw {
                    raw += 1
                    result = current
                } else {
                    result = nil
                }
                return result
            })
        })
        return Array(cases)
    }
}
