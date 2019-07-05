//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

final class SingleObjectFetchedResultController<CDEntityType, ResultType> where ResultType: ManagedEntity, ResultType.CDEntityType == CDEntityType {

    var willChange: ((_ controller: SingleObjectFetchedResultController<CDEntityType, ResultType>) -> Void)?
    var didChange: ((_ controller: SingleObjectFetchedResultController<CDEntityType, ResultType>) -> Void)?

    private(set) var result: ResultType?

    private let fetchedResultsController: FetchedResultsController<CDEntityType, ResultType>
    private let resultIndexPath: IndexPath = IndexPath(row: 0, section: 0)

    init(fetchedResultsController: NSFetchedResultsController<CDEntityType>) {
        self.fetchedResultsController = FetchedResultsController<CDEntityType, ResultType>(fetchedResultsController: fetchedResultsController)
        setup()
    }

    func performFetch() {
        willChange?(self)
        fetchedResultsController.performFetch()
        updateResult()
    }

    func performFetch(predicate: NSPredicate) {
        willChange?(self)
        fetchedResultsController.performFetch(predicate: predicate)
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
