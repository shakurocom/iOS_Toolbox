//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

final class FetchedResultsController<CDEntityType, ResultType>: NSObject, NSFetchedResultsControllerDelegate where ResultType: ManagedEntity, ResultType.CDEntityType == CDEntityType {

    enum ChangeType {
        case insert(indexPath: IndexPath)
        case delete(indexPath: IndexPath)
        case move(indexPath: IndexPath, newIndexPath: IndexPath)
        case update(indexPath: IndexPath)

        case insertSection(index: Int)
        case deleteSection(index: Int)
    }

    var willChangeContent: ((_ controller: FetchedResultsController<CDEntityType, ResultType>) -> Void)?
    var didChangeContent: ((_ controller: FetchedResultsController<CDEntityType, ResultType>) -> Void)?
    var didChangeFetchedResults: ((_ controller: FetchedResultsController<CDEntityType, ResultType>, _ type: ChangeType) -> Void)?

    private let fetchedResultsController: NSFetchedResultsController<CDEntityType>

    init(fetchedResultsController: NSFetchedResultsController<CDEntityType>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        fetchedResultsController.delegate = self
    }

    func setSortTerm(_ term: [(sortKey: String, ascending: Bool)], shouldPerformFetch: Bool) {
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

    func performFetch() {
        _ = try? fetchedResultsController.performFetch()
    }

    func performFetch(predicate: NSPredicate, deleteCache: Bool) {
        if deleteCache, let cacheName = fetchedResultsController.cacheName {
            NSFetchedResultsController<CDEntityType>.deleteCache(withName: cacheName)
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        performFetch()
    }

    func totalNumberOfItems() -> Int {
        return fetchedResultsController.sections?.reduce(0, {$0 + $1.numberOfObjects}) ?? 0
    }

    func numberOfItemsInSection(_ index: Int) -> Int {
        return fetchedResultsController.sections?[index].numberOfObjects ?? 0
    }

    func numberOfSections() -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> ResultType {
        return ResultType(cdEntity: fetchedResultsController.object(at: indexPath))
    }

    func indexPath(entity: ResultType) -> IndexPath? {
        guard let object: CDEntityType = (try? fetchedResultsController.managedObjectContext.existingObject(with: entity.objectID)) as? CDEntityType else {
            return nil
        }
        return fetchedResultsController.indexPath(forObject: object)
    }

    func itemWithURL(_ url: URL) -> ResultType? {
        guard let objectID = fetchedResultsController.managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
            let object: CDEntityType = (try? fetchedResultsController.managedObjectContext.existingObject(with: objectID)) as? CDEntityType else {
                return nil
        }
        return ResultType(cdEntity: object)
    }

    func forEach(inSection section: Int, body: (IndexPath, ResultType) -> Bool) {
        let numberOfObjects = numberOfItemsInSection(section)
        for row in 0..<numberOfObjects {
            let path = IndexPath(row: row, section: section)
            let shouldContinue = body(path, itemAtIndexPath(path))
            if !shouldContinue {
                break
            }
        }
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let actualPath: IndexPath = newIndexPath {
                didChangeFetchedResults?(self, .insert(indexPath: actualPath))
            }
        case .delete:
            if let actualPath: IndexPath = indexPath {
                didChangeFetchedResults?(self, .delete(indexPath: actualPath))
            }
        case .move:
            if let actualPath: IndexPath = indexPath,
                let actualNewIndexPath: IndexPath = newIndexPath {
                if actualPath != actualNewIndexPath {
                    didChangeFetchedResults?(self, .move(indexPath: actualPath, newIndexPath: actualNewIndexPath))
                } else {
                    didChangeFetchedResults?(self, .update(indexPath: actualNewIndexPath))
                }
            }
        case .update:
            if let actualPath: IndexPath = indexPath {
                didChangeFetchedResults?(self, .update(indexPath: actualPath))
            }
        @unknown default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            didChangeFetchedResults?(self, .insertSection(index: sectionIndex))
        case .delete:
            didChangeFetchedResults?(self, .deleteSection(index: sectionIndex))
        default:
            break
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        willChangeContent?(self)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        didChangeContent?(self)
    }
}
