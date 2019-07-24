//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

public extension NSPredicate {


    /// Helper method for building predicates based on entity identifier, and additional predicate if needed
    ///
    /// - Parameters:
    ///   - identifier: The identifier of entity, an object that adopts [PredicateConvertible](x-source-tag://PredicateConvertible)
    ///   - identifierKey: The String key used to construct correct NSPredicate
    ///   - format: The format string for additional predicate
    ///   - argumentArray: The arguments for additional predicate
    /// - Returns: The compound predicate "(identifierKey = identifier) AND (additional predicate format)"
    class func objectWithIDPredicate(_ identifier: PredicateConvertible,
                                     identifierKey: String = "identifier",
                                     andPredicateFormat format: String? = nil,
                                     argumentArray: [Any]? = nil) -> NSPredicate {
        var rootPredicate = NSPredicate(format: "\(identifierKey) = \(identifier.getPredicateFormat())", identifier.getPredicateValue())
        if let andPredicateFormat = format {
            rootPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [rootPredicate, NSPredicate(format: andPredicateFormat, argumentArray: argumentArray)])
        }
        return rootPredicate
    }

}

public extension PoliteCoreStorage {
    func findFirstByIdOrCreate<T: NSManagedObject>(_ entityType: T.Type,
                                                   identifier: PredicateConvertible,
                                                   inContext context: NSManagedObjectContext,
                                                   andPredicateFormat format: String? = nil,
                                                   argumentArray: [Any]? = nil) -> T {
        return findFirstOrCreate(entityType, withPredicate: NSPredicate.objectWithIDPredicate(identifier, andPredicateFormat: format, argumentArray: argumentArray), inContext: context)
    }
    func findFirstById<T: NSManagedObject>(_ entityType: T.Type,
                                           identifier: PredicateConvertible,
                                           inContext context: NSManagedObjectContext,
                                           andPredicateFormat format: String? = nil,
                                           argumentArray: [Any]? = nil) -> T? {
        return findFirst(entityType, withPredicate: NSPredicate.objectWithIDPredicate(identifier, andPredicateFormat: format, argumentArray: argumentArray), inContext: context)
    }
}
