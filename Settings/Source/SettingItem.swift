//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/**
 Base protocol for items.
 Used by Settings to work with items as a collection.
 */
internal protocol SettingItemBase {

    var isResetable: Bool { get }
    var isChangeableInSettings: Bool { get }

    func reset()
    func updateFromUserDefaults()

}

/**
 Main class for setting items.
 */
public class SettingItem<T: Codable & Equatable>: SettingItemBase {

    public final let didChange: EventHandler<EventHandlerValueChange<T>> = EventHandler<EventHandlerValueChange<T>>()

    internal let isResetable: Bool
    internal let isChangeableInSettings: Bool

    private let key: String
    private let defaultValue: T
    private var currentValue: T {
        didSet {
            if oldValue != currentValue {
                didChange.invoke(EventHandlerValueChange(oldValue: oldValue, newValue: currentValue))
            }
        }
    }
    private let userDefaults: UserDefaults
    private let customEncode: (_ newValue: T) -> Any?
    private let customDecode: (_ encodedValue: Any) -> T?

    /**
     Constructor for setting item.

     - parameter key: string key, that is used to store value for this setting item in UserDefaults.
     Should be unique otherwise behavoir is not defined.

     - parameter defaultValue: default value for this item. Will be used, if nothing is found in UserDefaults.
     If your 

     - parameter resetable: if `true` this item will be set to it's default value and data will be removed from UserDefaults upon soft-reseting.
     See `Settings.Reset(hard: )`.
     Default value is `true`.

     - parameter changeableInSettings: if `true` this setting is assumed to be accessible through Settings.App (standard iOs application).
     This item will be updated each time your application is returning from background.
     See documentation for Settings.bundle for supported types.
     Default value is `false`.

     - parameter customEncode: block used for encoding a value. Default value is nil - use default encoding.

     - parameter customDecode: block used for decoding a value. Default value is nil - use default decoding.

     Default encoding/decoding for different types:

        - `Optional` will be unwrapped, so `nil` value will remove value from UserDefaults.
            - warning: default value for optional type must be `nil` - to avoid inconsistency.

        - `NSNumber`, `String`, `Data` and `Date` - used as is. They will  just passing these values into UserDefaults.

        - `NSNumberRepresentable` (all floats and ints) - encoded as NSNumber

        - For `RawRepresentable` that have base type you can define conformance to `RawCodable` (no code is needed).
            In this case raw value will be used for encoding/decoding.

        - all other types will be encoded/decoded as JSON though Codable protocol.
     */
    public init(key: String,
                defaultValue: T,
                resetable: Bool = true,
                changeableInSettings: Bool = false,
                customEncode: ((_ newValue: T) -> Any?)? = nil,
                customDecode: ((_ encodedValue: Any) -> T?)? = nil) {
        SettingItem.inconsistencyCheck(selfType: T.self, defaultValue: defaultValue)
        self.isResetable = resetable
        self.isChangeableInSettings = changeableInSettings
        self.key = key
        self.defaultValue = defaultValue
        self.currentValue = defaultValue
        self.customEncode = customEncode ?? SettingItem.encodeTyped
        self.customDecode = customDecode ?? SettingItem.decodeTyped
        self.userDefaults = UserDefaults.standard
    }

    public final var value: T {
        get {
            return currentValue
        }
        set {
            userDefaults.set(customEncode(newValue), forKey: key)
            userDefaults.synchronize()
            currentValue = newValue
        }
    }

    internal func reset() {
        userDefaults.removeObject(forKey: key)
        currentValue = defaultValue
    }

    internal func updateFromUserDefaults() {
        if let encodedValue = userDefaults.object(forKey: key),
            let decodedValue: T = customDecode(encodedValue) {
            currentValue = decodedValue
        } else {
            currentValue = defaultValue
        }
    }

    private static func encodeTyped(_ valueToEncode: T) -> Any? {
        // typed version is needed to support customEncode block
        return encode(valueToEncode)
    }
    private static func encode(_ valueToEncode: Any?) -> Any? {
        switch valueToEncode {

        case is String,
             is Data,
             is Date:
            // these types are saved as is
            return valueToEncode

        case let numberRepresentableValue as NSNumberRepresentable:
            // all floats and ints saved as NSNumber
            return numberRepresentableValue.nsnumber()

        case let rawCodableValue as RawCodable:
            // RawCodable are RawRepresentable types: raw value are encoded
            return encode(rawCodableValue.encode())

        case let optionalValue as OptionalProtocol where optionalValue.isNil():
            // nil value should be tested before next case, because next case will always succeed
            return nil

        case let codableValue as T:
            // default implementation. Will always succeed, because we work here with T
            return try? JSONEncoder().encode(codableValue)

        default:
            // just in case
            return nil
        }
    }

    private static func decodeTyped(_ encodedValue: Any) -> T? {
        // typed version is needed to support customDecode block
        return decode(encodedValue, outputType: T.self) as? T
    }

    private static func decode(_ encodedValue: Any, outputType: Any.Type) -> Any? {
        switch outputType {

        case is String.Type, is Optional<String>.Type,
             is Data.Type, is Optional<Data>.Type,
             is Date.Type, is Optional<Date>.Type:
            // these types are returned as is - they are PList-safe
            return encodedValue

        case let numberRepresentableType as NSNumberRepresentable.Type:
            // all floats and ints are saved as NSNumber
            if let realNumber = encodedValue as? NSNumber {
                return numberRepresentableType.init(nsnumber: realNumber)
            } else {
                return nil
            }

        case let rawCodableType as RawCodable.Type:
            // for RawCodable we need to know type of RawValue: recursive decode
            if let decodedValue = decode(encodedValue, outputType: rawCodableType.encodedType()) {
                return rawCodableType.decode(decodedValue)
            } else {
                return nil
            }

        default:
            // there is no preceeding check for nil (like in encode()) because nil are discarded in updateFromUserDefaults()
            if let encodedData = encodedValue as? Data {
                return try? JSONDecoder().decode(T.self, from: encodedData)
            } else {
                return nil
            }
        }
    }

    private static func inconsistencyCheck(selfType: Any.Type, defaultValue: T) {
        // see init() description for details
        if selfType is OptionalProtocol.Type, let optionalDefaultValue = defaultValue as? OptionalProtocol, !optionalDefaultValue.isNil() {
            fatalError("Error: defaultValue is non-nil for optional base type will lead to inconsistency during value restoring.")
        }
    }

}

/**
 Support protocol to test T (generic type) against nil.
 */
internal protocol OptionalProtocol {
    func isNil() -> Bool
}

extension Optional: OptionalProtocol {
    func isNil() -> Bool {
        switch self {
        case .none:
            return true
        case .some:
            return false
        }
    }
}
