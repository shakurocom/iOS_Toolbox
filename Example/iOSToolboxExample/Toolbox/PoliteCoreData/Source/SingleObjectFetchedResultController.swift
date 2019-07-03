//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

final class SingleObjectFetchedResultController<CDEntityType, ResultType> where ResultType: Entity<CDEntityType> & ManagedEntity, ResultType.CDEntityType == CDEntityType {

    var willChange: ((_ controller: SingleObjectFetchedResultController<CDEntityType, ResultType>) -> Void)?
    var didChange: ((_ controller: SingleObjectFetchedResultController<CDEntityType, ResultType>) -> Void)?

    let resultIndexPath: IndexPath
    private(set) var result: ResultType?

    private let fetchedResultsController: FetchedResultsController<CDEntityType, ResultType>

    init(fetchedResultsController: NSFetchedResultsController<CDEntityType>,
         resultIndexPath: IndexPath = IndexPath(row: 0, section: 0)) {
        self.resultIndexPath = resultIndexPath
        self.fetchedResultsController = FetchedResultsController<CDEntityType, ResultType>(fetchedResultsController: fetchedResultsController)
        setup()
    }

    func performFetch() {
        willChange?(self)
        fetchedResultsController.performFetch()
        updateResult()
    }

    func performFetch(predicate: NSPredicate, deleteCache: Bool) {
        willChange?(self)
        fetchedResultsController.performFetch(predicate: predicate, deleteCache: deleteCache)
        updateResult()
    }
}

// MARK: - Private

private extension SingleObjectFetchedResultController {

    func setup() {
        fetchedResultsController.willChangeContent = {[weak self] (_) in
            guard let actualSelf = self else {
                return
            }
            actualSelf.willChange?(actualSelf)
        }
        fetchedResultsController.didChangeContent = {[weak self] (controller) in
            guard let actualSelf = self else {
                return
            }
            actualSelf.updateResult()
        }
    }

    func updateResult() {
        defer {
            didChange?(self)
        }

        guard fetchedResultsController.numberOfSections() > resultIndexPath.section,
            fetchedResultsController.numberOfItemsInSection(resultIndexPath.section) > resultIndexPath.row else {
                result = nil
                return
        }
        result = fetchedResultsController.itemAtIndexPath(resultIndexPath)
    }
}
