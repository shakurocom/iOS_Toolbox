//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

public extension NSManagedObject {

    /// Sets optional value by path if it doesn't match the old one.
    /// See also: [Apply non optional value](x-source-tag://applyValue)
    ///
    /// - Parameters:
    ///   - root: A Root of key path
    ///   - path: A path to apply value
    ///   - value: A value to apply
    /// - Returns: Bool value, indicating if value applied or there is no changes
     /// - Tag: applyValueOptional
    static func applyValue<Value: Equatable, Root>(to root: Root, path: ReferenceWritableKeyPath<Root, Value?>, value: Value?) -> Bool {
        if root[keyPath: path] != value {
            root[keyPath: path] = value
            return true
        } else {
            return false
        }
    }

    /// Sets value by path if it doesn't match the old one.
    /// See also: [Apply optional value](x-source-tag://applyValueOptional)
    ///
    /// - Parameters:
    ///   - root: A Root of key path
    ///   - path: A path to apply value
    ///   - value: A value to apply
    /// - Returns: A Bool value, indicating if value applied or there is no changes
    /// - Tag: applyValue
    static func applyValue<Value: Equatable, Root>(to root: Root, path: ReferenceWritableKeyPath<Root, Value>, value: Value) -> Bool {
        if root[keyPath: path] != value {
            root[keyPath: path] = value
            return true
        } else {
            return false
        }
    }
}
