//
//
//

import Foundation
import UIKit

// MARK: - Example Content

internal class ExampleDraggableDetailsContentViewController: UIViewController {

    internal static func instantiate() -> ExampleDraggableDetailsContentViewController {
        let controller: ExampleDraggableDetailsContentViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDraggableDetailsContentViewControllerID")
        return controller
    }

}

// MARK: - Example

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
        overlayViewController = DraggableDetailsOverlayViewController(nestedController: contentViewController, delegate: self)
        self.addToContainerChildViewController(overlayViewController)
        overlayViewController.hide(animated: false)
    }

    @IBAction private func sampleActionButtonDidPress() {
        sampleActionCount += 1
        sampleActionCountLabel.text = "\(sampleActionCount)"
    }

    @IBAction private func showOverlayButtonDidPress() {
        overlayViewController.show(initialAnchor: .middle(height: 400), animated: true)
    }

}

// MARK: - DraggableDetailsOverlayViewControllerDelegate

extension ExampleDraggableDetailsOverlayViewController: DraggableDetailsOverlayViewControllerDelegate {

    func draggableDetailsOverlayAnchors(_ overlay: DraggableDetailsOverlayViewController) -> [DraggableDetailsOverlayViewController.Anchor] {
        return [
            .top(offset: 40),
            .middle(height: 300),
            .middle(height: 100)
        ]
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
