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
    /// - Tag: objectWithIDPredicate
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

    /// Finds first entity that matches identifier and additional predicate, or creates new one if no entity found
    ///
    /// - Parameters:
    ///   - entityType: A type of entity to find
    ///   - identifier: The identifier of entity, an object that adopts [PredicateConvertible](x-source-tag://PredicateConvertible)
    ///   - context: NSManagedObjectContext where entity should be find
    ///   - format: Format for additional predicate. See [objectWithIDPredicate](x-source-tag://PredicateConvertible)
    ///   - argumentArray: Array of arguments for additional predicate. See [objectWithIDPredicate](x-source-tag://PredicateConvertible)
    /// - Returns: First found or created entity, never returns nil
    /// - Tag: findFirstByIdOrCreate
    func findFirstByIdOrCreate<T: NSManagedObject>(_ entityType: T.Type,
                                                   identifier: PredicateConvertible,
                                                   inContext context: NSManagedObjectContext,
                                                   andPredicateFormat format: String? = nil,
                                                   argumentArray: [Any]? = nil) -> T {
        return findFirstOrCreate(entityType, withPredicate: NSPredicate.objectWithIDPredicate(identifier, andPredicateFormat: format, argumentArray: argumentArray), inContext: context)
    }


    /// Finds first entity that matches identifier and additional predicate
    /// See also [findFirstByIdOrCreate](x-source-tag://PredicateConvertible) for more info
    /// - Parameters:
    ///   - entityType: A type of entity to find
    ///   - identifier: The identifier of entity, an object that adopts [PredicateConvertible](x-source-tag://PredicateConvertible)
    ///   - context: NSManagedObjectContext where entity should be find
    ///   - format: Format for additional predicate. See [objectWithIDPredicate](x-source-tag://PredicateConvertible)
    ///   - argumentArray: Array of arguments for additional predicate. See [objectWithIDPredicate](x-source-tag://PredicateConvertible)
    /// - Returns: First found entity or nil.
    func findFirstById<T: NSManagedObject>(_ entityType: T.Type,
                                           identifier: PredicateConvertible,
                                           inContext context: NSManagedObjectContext,
                                           andPredicateFormat format: String? = nil,
                                           argumentArray: [Any]? = nil) -> T? {
        return findFirst(entityType, withPredicate: NSPredicate.objectWithIDPredicate(identifier, andPredicateFormat: format, argumentArray: argumentArray), inContext: context)
    }
}
