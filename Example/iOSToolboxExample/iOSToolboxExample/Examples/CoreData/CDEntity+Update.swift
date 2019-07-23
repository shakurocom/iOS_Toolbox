//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

// MARK: - CDExampleEntity

extension CDExampleEntity {
    func update(entity: ExampleEntity) -> Bool {
        guard isInserted || (entity.identifier == identifier) else {
            return false
        }
        var changed: Bool = false
        changed = apply(path: \.identifier, value: entity.identifier) || changed
        changed = apply(path: \.createdAt, value: entity.createdAt.timeIntervalSince1970) || changed
        changed = apply(path: \.updatedAt, value: entity.updatedAt.timeIntervalSince1970) || changed

        return changed
    }

    func apply<Value>(path: ReferenceWritableKeyPath<CDExampleEntity, Value?>, value: Value?) -> Bool where Value: Equatable {
        return NSManagedObject.applyValue(to: self, path: path, value: value)
    }

    func apply<Value>(path: ReferenceWritableKeyPath<CDExampleEntity, Value>, value: Value) -> Bool where Value: Equatable {
        return NSManagedObject.applyValue(to: self, path: path, value: value)
    }
}
