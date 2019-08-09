//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

/// Protocol for custom entities.  Use it to keep connection with original NSManagedObject via NSManagedObjectID.
/// - Used by [FetchedResultsController](x-source-tag://FetchedResultsController)
public protocol ManagedEntity {

    associatedtype EntityType where EntityType: NSManagedObject

    var objectID: NSManagedObjectID {get}

    init(entity: EntityType)

}
