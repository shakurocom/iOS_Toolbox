import Foundation
import CoreData

extension NSManagedObject {

    static func applyValue<Value, Root>(to root: Root, path: ReferenceWritableKeyPath<Root, Value?>, value: Value?) -> Bool where Value: Equatable {
        if root[keyPath: path] != value {
            root[keyPath: path] = value
            return true
        } else {
            return false
        }
    }

    static func applyValue<Value, Root>(to root: Root, path: ReferenceWritableKeyPath<Root, Value>, value: Value) -> Bool where Value: Equatable {
        if root[keyPath: path] != value {
            root[keyPath: path] = value
            return true
        } else {
            return false
        }
    }
}
