//
//
//

import Foundation
import UIKit

internal class ExampleDraggableDetailsContentViewController: UIViewController {

    internal static func instantiate() -> ExampleDraggableDetailsContentViewController {
        let controller: ExampleDraggableDetailsContentViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDraggableDetailsContentViewControllerID")
        return controller
    }

}

internal class ExampleDraggableDetailsOverlayViewController: UIViewController {

    @IBOutlet private var sampleActionCountLabel: UILabel!

    private var contentViewController: ExampleDraggableDetailsContentViewController!
    private var overlayViewController: DraggableDetailsOverlayViewController!

    private var example: Example?
    private var sampleActionCount: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title
        sampleActionCountLabel.text = "\(sampleActionCount)"

        contentViewController = ExampleDraggableDetailsContentViewController.instantiate()
        overlayViewController = DraggableDetailsOverlayViewController(nestedController: contentViewController)
        self.addToContainerChildViewController(overlayViewController)
    }

    @IBAction private func sampleActionButtonDidPress() {
        sampleActionCount += 1
        sampleActionCountLabel.text = "\(sampleActionCount)"
    }

    @IBAction private func showOverlayButtonDidPress() {
        //TODO: 58: show
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleDraggableDetailsOverlayViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleDraggableDetailsOverlayViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDraggableDetailsOverlayViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
