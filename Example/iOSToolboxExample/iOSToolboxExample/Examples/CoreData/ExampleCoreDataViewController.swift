//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import UIKit

internal class ExampleCoreDataViewController: UIViewController {

    @IBOutlet private var contentTableView: UITableView!

    private var example: Example?

    private var exampleFetchedResultController: FetchedResultsController<CDExampleEntity, ManagedExampleEntity>!

    private enum Constant {
        static let cellReuseIdentifier: String = "UITableViewCell"
    }

    private var storage: PoliteCoreStorage = {
        do {
            return try PoliteCoreStorage.setupStack(configuration: PoliteCoreStorage.Configuration(modelName: "CoreDataExample"), removeDBOnSetupFailed: true)
        } catch let error {
            fatalError("\(error)")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = example?.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
        exampleFetchedResultController.willChangeContent = {[weak self] (_) in
            guard let actualSelf = self else {
                return
            }
           // actualSelf.output?.interactorWillChangeContent(actualSelf)
        }

        exampleFetchedResultController.didChangeFetchedResults = {[weak self] (controller, changeType) in
            guard let actualSelf = self else {
                return
            }
           // actualSelf.changes.append(changeType)
        }
        exampleFetchedResultController.didChangeContent = {[weak self] (controller) in
            guard let actualSelf = self else {
                return
            }
            actualSelf.contentTableView.reloadData()
//            let oldCount: Int = actualSelf.totalNumberOfItems
//            actualSelf.totalNumberOfItems = controller.totalNumberOfItems()
//            actualSelf.output?.interactorDidChangeContent(actualSelf,
//                                                          oldTotalCount: oldCount,
//                                                          newTotalCount: actualSelf.totalNumberOfItems,
//                                                          changes: actualSelf.changes)
           // actualSelf.changes.removeAll()
        }
        exampleFetchedResultController.performFetch()
        contentTableView.reloadData()
    }

    @objc private func addButtonPressed() {
        let coreStorage = storage

        coreStorage.saveWithBlock({ (context) in
            let totalCount = coreStorage.countForEntity(CDExampleEntity.self, inContext: context)
            let notManagedEntity = ExampleEntity(identifier: "\(totalCount + 1)", createdAt: Date(), updatedAt: Date())
            let newEntity = coreStorage.findFirstByIdOrCreate(CDExampleEntity.self, identifier: notManagedEntity.identifier, inContext: context)
            newEntity.update(entity: notManagedEntity)
        }, completion: { (error) in
            debugPrint(error)
        })
    }
}

// MARK: - ExampleViewControllerProtocol

extension ExampleCoreDataViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleCoreDataViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "ExampleCoreDataViewController")
        exampleVC.example = example
        let controller = exampleVC.storage.mainQueueFetchedResultsController(CDExampleEntity.self, sortTerm: [(sortKey: "updatedAt", ascending: true)]) { (request) in
            // change ferchRequest properties here
            debugPrint(request)
        }
        exampleVC.exampleFetchedResultController = FetchedResultsController<CDExampleEntity, ManagedExampleEntity>(fetchedResultsController: controller)
        return exampleVC
    }

}

extension ExampleCoreDataViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exampleFetchedResultController.numberOfItemsInSection(section)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return exampleFetchedResultController.numberOfSections()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.cellReuseIdentifier)!
        let item = exampleFetchedResultController.itemAtIndexPath(indexPath)
        cell.textLabel?.text = item.identifier
        cell.detailTextLabel?.text = "createdAt: \(item.createdAt); updatedAt: \(item.updatedAt)"
        return cell
    }
}
