//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import UIKit

class ExampleContainerViewController: ContainerViewController, ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleContainerViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "ExampleContainerViewController")
        exampleVC.example = example
        return exampleVC
    }

    @IBOutlet private var segmentedcontrol: UISegmentedControl!

    private var example: Example?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = example?.title
    }

    override func willPresentViewController(_ controller: UIViewController, animated: Bool) {
    }

    override func didPresentViewController(_ controller: UIViewController, animated: Bool) {
        guard let actualController = currentViewController else {
            return
        }
        segmentedcontrol.tintColor = actualController.view.backgroundColor
    }

    @IBAction private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard sender.selectedSegmentIndex != UISegmentedControl.noSegment else {
            return
        }
        let nextController = UIViewController()
        nextController.view.backgroundColor = UIColor.random()
        let transition: TransitionStyle
        switch sender.selectedSegmentIndex {
        case 0:
            transition = .push
        case 1:
            transition = .pop
        case 2:
            transition = .fade
        case 3:
            transition = .custom(animator: ExampleAnimator())
        default:
            fatalError("Unknown UISegmentedControl index")
        }
        present(nextController, style: transition, animated: true)
    }

}

private struct ExampleAnimator: ContainerViewControllerTransitionAnimator {

    func animate(fromView: UIView?, toView: UIView, contentView: UIView, didFinish: @escaping () -> Void) {
        guard let actualFrom =  fromView else {
            didFinish()
            return
        }
        toView.transform = CGAffineTransform(translationX: 0, y: -toView.bounds.size.height)
        UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: {
            actualFrom.transform = CGAffineTransform(translationX: 0, y: actualFrom.bounds.size.height)
            toView.transform = CGAffineTransform.identity
        }, completion: { (_) in
            didFinish()
        })
    }
}
