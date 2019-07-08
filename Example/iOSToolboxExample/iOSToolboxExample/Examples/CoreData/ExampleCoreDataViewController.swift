//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation
import UIKit

internal class ExampleCoreDataViewController: UIViewController {

    private var example: Example?

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
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleCoreDataViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleCoreDataViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "ExampleCoreDataViewController")
        exampleVC.example = example
        return exampleVC
    }

}
