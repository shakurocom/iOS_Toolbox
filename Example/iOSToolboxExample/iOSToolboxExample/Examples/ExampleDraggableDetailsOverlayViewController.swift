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

    private var shouldPreventScrolling: Bool = false
    private var currentContentScrollOffsetTop: CGPoint = .zero
    private var currentContentScrollOffsetBottom: CGPoint = .zero

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

// MARK: UIScrollViewDelegate

extension ExampleDraggableDetailsContentViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldPreventScrolling {
            if scrollView === topTableView {
                scrollView.contentOffset = currentContentScrollOffsetTop
            } else if scrollView === bottomTableView {
                scrollView.contentOffset = currentContentScrollOffsetBottom
            }
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if shouldPreventScrolling {
            if scrollView === topTableView {
                targetContentOffset.pointee = currentContentScrollOffsetTop
            } else if scrollView === bottomTableView {
                targetContentOffset.pointee = currentContentScrollOffsetBottom
            }
        }
    }

}

// MARK: DraggableDetailsOverlayNestedInterface

extension ExampleDraggableDetailsContentViewController: DraggableDetailsOverlayNestedInterface {

    func draggableDetailsOverlay(_ overlay: DraggableDetailsOverlayViewController, requirePreventOfScroll: Bool) {
        shouldPreventScrolling = requirePreventOfScroll
        topTableView.showsVerticalScrollIndicator = !requirePreventOfScroll
        bottomTableView.showsVerticalScrollIndicator = !requirePreventOfScroll
        if requirePreventOfScroll {
            currentContentScrollOffsetTop = topTableView.contentOffset
            currentContentScrollOffsetBottom = bottomTableView.contentOffset
        }
    }

    func draggableDetailsOverlayContentScrollViews(_ overlay: DraggableDetailsOverlayViewController) -> [UIScrollView] {
        return [topTableView, bottomTableView]
    }

}

// MARK: - Example

internal class ExampleDraggableDetailsOverlayViewController: UIViewController {

    @IBOutlet private var contentScrollView: UIScrollView!

    @IBOutlet private var shadowSwitch: UISwitch!
    @IBOutlet private var shadowColorButton: UIButton!

    @IBOutlet private var draggableContainerBackgroundColorButton: UIButton!
    @IBOutlet private var draggableContainerTopCornersRadiusSlider: UISlider!

    private var contentViewController: ExampleDraggableDetailsContentViewController!
    private var overlayViewController: DraggableDetailsOverlayViewController!
    private var keyboardHandler: KeyboardHandler?

    private var example: Example?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title
        contentScrollView.delegate = self

        contentViewController = ExampleDraggableDetailsContentViewController.instantiate()
        contentViewController.delegate = self
        overlayViewController = DraggableDetailsOverlayViewController(nestedController: contentViewController, delegate: self)
        self.addChildViewController(overlayViewController, notifyAboutAppearanceTransition: false)
        overlayViewController.show(initialAnchor: .middle(height: 400), animated: false)

        overlayViewController.isShadowEnabled = shadowSwitch.isOn

        shadowColorButton.setTitleColor(overlayViewController.shadowBackgroundColor, for: .normal)
        shadowColorButton.setTitleShadowColor(UIColor.black, for: .normal)

        draggableContainerBackgroundColorButton.setTitleShadowColor(UIColor.black, for: .normal)
        draggableContainerBackgroundColorButton.setTitleColor(overlayViewController.draggableContainerBackgroundColor, for: .normal)
        draggableContainerTopCornersRadiusSlider.value = Float(overlayViewController.draggableContainerTopCornersRadius)

        keyboardHandler = KeyboardHandler(enableCurveHack: false, heightDidChange: { [weak self] (change: KeyboardHandler.KeyboardChange) in
            guard let strongSelf = self else {
                return
            }
            UIView.animate(
                withDuration: change.animationDuration,
                delay: 0.0,
                animations: {
                    UIView.setAnimationCurve(change.animationCurve)
                    strongSelf.contentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: change.newHeight, right: 0)
                    strongSelf.view.layoutIfNeeded()
            },
                completion: nil)
        })
        keyboardHandler?.isActive = true
    }

    @IBAction private func showOverlayButtonDidPress() {
        view.endEditing(true)
        overlayViewController.show(initialAnchor: .middle(height: 400), animated: true)
    }

    @IBAction private func switchValueChanged(_ sender: UISwitch) {
        switch sender {
        case shadowSwitch:
            overlayViewController.isShadowEnabled = shadowSwitch.isOn
        default:
            break
        }
    }

     @IBAction private func sliderValueChanged(_ sender: UISlider) {
        switch sender {
        case draggableContainerTopCornersRadiusSlider:
            overlayViewController.draggableContainerTopCornersRadius = CGFloat(sender.value)
        default:
            break
        }
    }

    @IBAction private func changeShadowColor(_ sender: UIButton) {
        let range: ClosedRange<CGFloat> = 0...1
        overlayViewController.shadowBackgroundColor = UIColor(red: CGFloat.random(in: range),
                                                              green: CGFloat.random(in: range),
                                                              blue: CGFloat.random(in: range),
                                                              alpha: 0.5)
        shadowColorButton.setTitleColor(overlayViewController.shadowBackgroundColor.withAlphaComponent(1.0), for: .normal)
    }

    @IBAction private func draggableContainerBackgroundColorButtonPressed(_ sender: UIButton) {
        let range: ClosedRange<CGFloat> = 0...1
        overlayViewController.draggableContainerBackgroundColor = UIColor(red: CGFloat.random(in: range),
                                                              green: CGFloat.random(in: range),
                                                              blue: CGFloat.random(in: range),
                                                              alpha: 1.0)
        draggableContainerBackgroundColorButton.setTitleColor(overlayViewController.draggableContainerBackgroundColor, for: .normal)
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

    func draggableDetailsOverlayTopInset(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat {
        return 0
    }

    func draggableDetailsOverlayMaxHeight(_ overlay: DraggableDetailsOverlayViewController) -> CGFloat? {
        return nil
    }

    func draggableDetailsOverlayDidDrag(_ overlay: DraggableDetailsOverlayViewController) {
        print("did drag")
    }

    func draggableDetailsOverlayDidEndDragging(_ overlay: DraggableDetailsOverlayViewController) {
        print("did end dragging")
    }

    func draggableDetailsOverlayDidChangeIsVisible(_ overlay: DraggableDetailsOverlayViewController) {
        print("did change is visible: \(overlay.isVisible)")
    }

    func draggableDetailsOverlayDidUpdatedLayout(_ overlay: DraggableDetailsOverlayViewController) {
        print("did update layout")
    }

}

// MARK: UITextFieldDelegate

extension ExampleDraggableDetailsOverlayViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(false)
        return false
    }

//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if textField === topInsetTextField {
//            textField.text = "\(topInset())"
//            overlayViewController.updateLayout(animated: true)
//        } else if textField === maxHeightTextField {
//            if let value = maxHeight() {
//                textField.text = "\(value)"
//            } else {
//                textField.text = nil
//            }
//            overlayViewController.updateLayout(animated: true)
//        }
//    }

}

// MARK: UIScrollViewDelegate

extension ExampleDraggableDetailsOverlayViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === contentScrollView {
            view.endEditing(false)
        }
    }

}

// MARK: Private

private extension ExampleDraggableDetailsOverlayViewController {

//    private func topInset() -> Int {
//        return Int(topInsetTextField.text ?? "0") ?? 0
//    }
//
//    private func maxHeight() -> Int? {
//        guard let text = maxHeightTextField.text else {
//            return nil
//        }
//        return Int(text)
//    }

}

// MARK: ExampleViewControllerProtocol

extension ExampleDraggableDetailsOverlayViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleDraggableDetailsOverlayViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDraggableDetailsOverlayViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
