//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

extension CDExampleEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDExampleEntity> {
        return NSFetchRequest<CDExampleEntity>(entityName: "CDExampleEntity")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var createdAt: TimeInterval
    @NSManaged public var updatedAt: TimeInterval

}
