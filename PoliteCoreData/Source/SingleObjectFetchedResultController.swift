//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import CoreData

/// Wrapper on NSFetchedResultsController, provides easy way to observe single entity.
/// See: [FetchedResultsController](x-source-tag://FetchedResultsController) for more info
/// - Tag: SingleObjectFetchedResultController
public final class SingleObjectFetchedResultController<EntityType, ResultType: ManagedEntity> where ResultType.EntityType == EntityType {

    public var willChange: ((_ controller: SingleObjectFetchedResultController<EntityType, ResultType>) -> Void)?
    public var didChange: ((_ controller: SingleObjectFetchedResultController<EntityType, ResultType>) -> Void)?

    private(set) var result: ResultType?
    private let fetchedResultsController: FetchedResultsController<EntityType, ResultType>
    private let resultIndexPath: IndexPath = IndexPath(row: 0, section: 0)

    public init(fetchedResultsController: NSFetchedResultsController<EntityType>) {
        self.fetchedResultsController = FetchedResultsController<EntityType, ResultType>(fetchedResultsController: fetchedResultsController)
        setup()
    }

    public func performFetch() throws {
        willChange?(self)
        try fetchedResultsController.performFetch()
        updateResult()
    }

    public func performFetch(predicate: NSPredicate) throws {
        willChange?(self)
        try fetchedResultsController.performFetch(predicate: predicate)
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
