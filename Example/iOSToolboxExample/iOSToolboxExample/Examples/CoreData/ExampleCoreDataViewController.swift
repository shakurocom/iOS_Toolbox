//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import UIKit

internal class ExampleCoreDataViewController: UIViewController, ExampleViewControllerProtocol {

    typealias ChangeType = FetchedResultsController<CDExampleEntity, ManagedExampleEntity>.ChangeType

    @IBOutlet private var contentTableView: UITableView!

    private var example: Example?

    private var exampleFetchedResultController: FetchedResultsController<CDExampleEntity, ManagedExampleEntity>!
    private var changes: [ChangeType] = []

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

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleCoreDataViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "ExampleCoreDataViewController")
        exampleVC.example = example
        let controller = exampleVC.storage.mainQueueFetchedResultsController(CDExampleEntity.self, sortTerm: [(sortKey: "updatedAt", ascending: false)]) { (request) in
            // change fetchRequest properties here
            debugPrint(request)
        }
        exampleVC.exampleFetchedResultController = FetchedResultsController<CDExampleEntity, ManagedExampleEntity>(fetchedResultsController: controller)
        return exampleVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = example?.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))

        exampleFetchedResultController.willChangeContent = { (_) in }

        exampleFetchedResultController.didChangeFetchedResults = {[weak self] (controller, changeType) in
            guard let actualSelf = self else {
                return
            }
            actualSelf.changes.append(changeType)
        }
        exampleFetchedResultController.didChangeContent = {[weak self] (controller) in
            guard let actualSelf = self else {
                return
            }
            actualSelf.applyChanges()
        }
        exampleFetchedResultController.performFetch()
        contentTableView.reloadData()
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

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (_, path) in
            self?.deleteItem(at: path)
        }
        return [action]
    }
}

// MARK: - Private

private extension ExampleCoreDataViewController {
    @objc func addButtonPressed() {
        let coreStorage = storage

        coreStorage.saveWithBlock({ (context) in
            let notManagedEntity = ExampleEntity(identifier: UUID().uuidString, createdAt: Date(), updatedAt: Date())
            let newEntity = coreStorage.findFirstByIdOrCreate(CDExampleEntity.self, identifier: notManagedEntity.identifier, inContext: context)
            _ = newEntity.update(entity: notManagedEntity)
        }, completion: { (error) in
            if let actualError = error {
                assertionFailure("\(actualError)")
            }
        })
    }

    func deleteItem(at indexPath: IndexPath) {
        let coreStorage = storage
        let item = exampleFetchedResultController.itemAtIndexPath(indexPath)
        coreStorage.saveWithBlock({ (context) in
            if let entity = coreStorage.findFirstById(CDExampleEntity.self, identifier: item.identifier, inContext: context) {
                context.delete(entity)
            }
        }, completion: { (error) in
            if let actualError = error {
                assertionFailure("\(actualError)")
            }
        })
    }

    func applyChanges() {
        if view.window == nil {
            contentTableView.reloadData()
        } else {
            contentTableView.beginUpdates()
            changes.forEach { (value) in
                switch value {
                case .insert(let indexPath):
                    contentTableView.insertRows(at: [indexPath], with: .fade)
                case .delete(let indexPath):
                    contentTableView.deleteRows(at: [indexPath], with: .fade)
                case .move(let indexPath, let newIndexPath):
                    contentTableView.deleteRows(at: [indexPath], with: .fade)
                    contentTableView.insertRows(at: [newIndexPath], with: .fade)
                case .update(let indexPath):
                    contentTableView.reloadRows(at: [indexPath], with: .fade)
                case .insertSection(let index):
                    contentTableView.insertSections(IndexSet(integer: index), with: .fade)
                case .deleteSection(let index):
                    contentTableView.deleteSections(IndexSet(integer: index), with: .fade)
                }
            }
            contentTableView.endUpdates()
        }
        changes.removeAll()
    }
}
