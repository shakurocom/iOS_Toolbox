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

    init(cdEntity: CDExampleEntity) {
        createdAt = Date(timeIntervalSince1970: cdEntity.createdAt)
        updatedAt = Date(timeIntervalSince1970: cdEntity.updatedAt)
        identifier = cdEntity.identifier ?? UUID().uuidString
    }
}

final class ManagedExampleEntity: ExampleEntity, ManagedEntity {
    let objectID: NSManagedObjectID

    override init(cdEntity: CDExampleEntity) {
        objectID = cdEntity.objectID
        super.init(cdEntity: cdEntity)
    }
}
