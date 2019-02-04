//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class ExampleDeviceTypeViewController: UIViewController {

    @IBOutlet private var deviceTypeLabel: UILabel!
    @IBOutlet private var deviceDisplayNameLabel: UILabel!

    private var example: Example?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        deviceTypeLabel.text = "\(DeviceType.current)"
        deviceDisplayNameLabel.text = DeviceType.current.displayName
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleDeviceTypeViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleDeviceTypeViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDeviceTypeViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
