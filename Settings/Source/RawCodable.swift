//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/**
 Add this protocol to your enum type to use its raw value for encoding in Settings for UserDefaults.
 - warning: RawValue of your enum **MUST** satisfy to the same constraints as T of SettingItem it is used in.
 */
public protocol RawCodable {
    func encode() -> Any?
    static func encodedType() -> Any.Type
    static func decode(_ rawValue: Any) -> Self?
}

extension RawCodable where Self: RawRepresentable {

    func encode() -> Any? {
        return rawValue
    }

    static func encodedType() -> Any.Type {
        return RawValue.self
    }

    static func decode(_ encodedValue: Any) -> Self? {
        if let realRawValue = encodedValue as? RawValue {
            return Self.init(rawValue: realRawValue)
        } else {
            return nil
        }
    }

}

extension Optional: RawCodable where Wrapped: RawCodable {

    public func encode() -> Any? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped.encode()
        }
    }

    public static func encodedType() -> Any.Type {
        return Wrapped.encodedType()
    }

    //swiftlint:disable syntactic_sugar
    public static func decode(_ rawValue: Any) -> Optional<Wrapped>? {
        return Wrapped.decode(rawValue)
    }
    //swiftlint:enable syntactic_sugar

}
