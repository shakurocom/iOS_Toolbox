//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

class ExampleEntity {

    let identifier: String
    let createdAt: Date
    let updatedAt: Date

    init(identifier: String, createdAt: Date, updatedAt: Date) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.identifier = identifier
    }

    init(entity: CDExampleEntity) {
        createdAt = Date(timeIntervalSince1970: entity.createdAt)
        updatedAt = Date(timeIntervalSince1970: entity.updatedAt)
        identifier = entity.identifier ?? UUID().uuidString
    }
}

final class ManagedExampleEntity: ExampleEntity, ManagedEntity {
    let objectID: NSManagedObjectID

    override init(entity: CDExampleEntity) {
        objectID = entity.objectID
        super.init(entity: entity)
    }
}
