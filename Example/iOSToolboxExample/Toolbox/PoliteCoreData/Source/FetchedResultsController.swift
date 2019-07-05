//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

public final class FetchedResultsController<CDEntityType, ResultType>: NSObject where ResultType: ManagedEntity, ResultType.CDEntityType == CDEntityType {

    public enum ChangeType {
        case insert(indexPath: IndexPath)
        case delete(indexPath: IndexPath)
        case move(indexPath: IndexPath, newIndexPath: IndexPath)
        case update(indexPath: IndexPath)

        case insertSection(index: Int)
        case deleteSection(index: Int)
    }

    public var willChangeContent: ((_ controller: FetchedResultsController<CDEntityType, ResultType>) -> Void)?
    public var didChangeContent: ((_ controller: FetchedResultsController<CDEntityType, ResultType>) -> Void)?
    public var didChangeFetchedResults: ((_ controller: FetchedResultsController<CDEntityType, ResultType>, _ type: ChangeType) -> Void)?

    private let fetchedResultsController: NSFetchedResultsController<CDEntityType>
    private let delegateProxy = HiddenDelegateProxy<CDEntityType, ResultType>()

    public init(fetchedResultsController: NSFetchedResultsController<CDEntityType>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        delegateProxy.target = self
        fetchedResultsController.delegate = delegateProxy
    }

    public func setSortTerm(_ term: [(sortKey: String, ascending: Bool)], shouldPerformFetch: Bool) {
        guard !term.isEmpty else {
            assertionFailure("FetchedResultsController.setSortTerm SortTerm can't be empty!")
            return
        }
        var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor]()
        for sortKey in term {
            sortDescriptors.append(NSSortDescriptor(key: sortKey.sortKey, ascending: sortKey.ascending))
        }
        fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors
        if shouldPerformFetch {
            performFetch()
        }
    }

    public func performFetch() {
        _ = try? fetchedResultsController.performFetch()
    }

    public func performFetch(predicate: NSPredicate) {
        if let cacheName = fetchedResultsController.cacheName {
            NSFetchedResultsController<CDEntityType>.deleteCache(withName: cacheName)
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        performFetch()
    }

    public func totalNumberOfItems() -> Int {
        return fetchedResultsController.sections?.reduce(0, {$0 + $1.numberOfObjects}) ?? 0
    }

    public func numberOfItemsInSection(_ index: Int) -> Int {
        return fetchedResultsController.sections?[index].numberOfObjects ?? 0
    }

    public func numberOfSections() -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    public func itemAtIndexPath(_ indexPath: IndexPath) -> ResultType {
        return ResultType(cdEntity: fetchedResultsController.object(at: indexPath))
    }

    public func indexPath(entity: ResultType) -> IndexPath? {
        guard let object: CDEntityType = (try? fetchedResultsController.managedObjectContext.existingObject(with: entity.objectID)) as? CDEntityType else {
            return nil
        }
        return fetchedResultsController.indexPath(forObject: object)
    }

    public func itemWithURL(_ url: URL) -> ResultType? {
        guard let objectID = fetchedResultsController.managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
            let object: CDEntityType = (try? fetchedResultsController.managedObjectContext.existingObject(with: objectID)) as? CDEntityType else {
                return nil
        }
        return ResultType(cdEntity: object)
    }

    public func forEach(inSection section: Int, body: (IndexPath, ResultType) -> Bool) {
        let numberOfObjects = numberOfItemsInSection(section)
        for row in 0..<numberOfObjects {
            let path = IndexPath(row: row, section: section)
            let shouldContinue = body(path, itemAtIndexPath(path))
            if !shouldContinue {
                break
            }
        }
    }

}

// MARK: - Private NSFetchedResultsControllerDelegate

private final class HiddenDelegateProxy<CDEntityType, ResultType>: NSObject, NSFetchedResultsControllerDelegate where ResultType: ManagedEntity, ResultType.CDEntityType == CDEntityType {
    weak var target: FetchedResultsController<CDEntityType, ResultType>?

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        guard let actualTarget = target else {
            return
        }
        switch type {
        case .insert:
            if let actualPath: IndexPath = newIndexPath {
                actualTarget.didChangeFetchedResults?(actualTarget, .insert(indexPath: actualPath))
            }
        case .delete:
            if let actualPath: IndexPath = indexPath {
                actualTarget.didChangeFetchedResults?(actualTarget, .delete(indexPath: actualPath))
            }
        case .move:
            if let actualPath: IndexPath = indexPath,
                let actualNewIndexPath: IndexPath = newIndexPath {
                if actualPath != actualNewIndexPath {
                    actualTarget.didChangeFetchedResults?(actualTarget, .move(indexPath: actualPath, newIndexPath: actualNewIndexPath))
                } else {
                    actualTarget.didChangeFetchedResults?(actualTarget, .update(indexPath: actualNewIndexPath))
                }
            }
        case .update:
            if let actualPath: IndexPath = indexPath {
                actualTarget.didChangeFetchedResults?(actualTarget, .update(indexPath: actualPath))
            }
        @unknown default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        guard let actualTarget = target else {
            return
        }
        switch type {
        case .insert:
            actualTarget.didChangeFetchedResults?(actualTarget, .insertSection(index: sectionIndex))
        case .delete:
            actualTarget.didChangeFetchedResults?(actualTarget, .deleteSection(index: sectionIndex))
        default:
            break
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let actualTarget = target else {
            return
        }
        actualTarget.willChangeContent?(actualTarget)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let actualTarget = target else {
            return
        }
        actualTarget.didChangeContent?(actualTarget)
    }
}
