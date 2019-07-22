//
//
//

import Foundation
import UIKit

// MARK: - Example Content

internal protocol ExampleDraggableDetailsContentViewControllerDelegate: class {
    func contentDidPressCloseButton()
}

internal class ExampleDraggableDetailsContentViewController: UIViewController {

    internal weak var delegate: ExampleDraggableDetailsContentViewControllerDelegate?

    @IBOutlet private var topTableView: UITableView!
    @IBOutlet private var bottomTableView: UITableView!

    internal static func instantiate() -> ExampleDraggableDetailsContentViewController {
        let controller: ExampleDraggableDetailsContentViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDraggableDetailsContentViewControllerID")
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        topTableView.delegate = self
        topTableView.dataSource = self
        bottomTableView.delegate = self
        bottomTableView.dataSource = self
    }

    @IBAction private func closeOverlayButtondidPress() {
        delegate?.contentDidPressCloseButton()
    }

}

// MARK: UITableViewDataSource, UITableViewDelegate

extension ExampleDraggableDetailsContentViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "kExampleDraggableDetailsContentCellID", for: indexPath)
        cell.textLabel?.text = (tableView === topTableView ? "top" : "bottom") + " #\(indexPath.row)"
        return cell
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
        contentViewController.delegate = self
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

// MARK: ExampleDraggableDetailsContentViewControllerDelegate

extension ExampleDraggableDetailsOverlayViewController: ExampleDraggableDetailsContentViewControllerDelegate {
    func contentDidPressCloseButton() {
        overlayViewController.hide(animated: true)
    }
}

// MARK: DraggableDetailsOverlayViewControllerDelegate

extension ExampleDraggableDetailsOverlayViewController: DraggableDetailsOverlayViewControllerDelegate {

    func draggableDetailsOverlayAnchors(_ overlay: DraggableDetailsOverlayViewController) -> [DraggableDetailsOverlayViewController.Anchor] {
        return [
            .top(offset: 40),
            .middle(height: 300),
            .middle(height: 100)
        ]
    }

}

// MARK: ExampleViewControllerProtocol

extension ExampleDraggableDetailsOverlayViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleDraggableDetailsOverlayViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDraggableDetailsOverlayViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
