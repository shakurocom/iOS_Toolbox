//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

public protocol ManagedEntity {

    associatedtype CDEntityType where CDEntityType: NSManagedObject

    var objectID: NSManagedObjectID {get}

    init(cdEntity: CDEntityType)
}
