import Foundation
import CoreData

class BaseEntity<CDType> where CDType: NSManagedObject {

    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }
}

extension NSPredicate {

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

extension PoliteCoreStorage {
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
