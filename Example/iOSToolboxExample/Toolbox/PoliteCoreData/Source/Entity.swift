import Foundation
import CoreData

class Entity<CDType> where CDType: NSManagedObject {

    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }
}

protocol ManagedEntity {

    associatedtype CDEntityType where CDEntityType: NSManagedObject

    var objectID: NSManagedObjectID {get}

    init(cdEntity: CDEntityType)
}
