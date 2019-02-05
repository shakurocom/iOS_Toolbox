//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

class ExampleKeyboardHandlerViewController: UIViewController {

    @IBOutlet private var contentView: UIView!
    @IBOutlet private var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var textField: UITextField!
    @IBOutlet private var resignResponderButton: UIButton!

    private var example: Example?
    private var keyboardHandler: KeyboardHandler?

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        keyboardHandler = KeyboardHandler(enableCurveHack: false, heightDidChange: { [weak self] (change: KeyboardHandler.KeyboardChange) in
            guard let strongSelf = self else {
                return
            }
            UIView.animate(
                withDuration: change.animationDuration,
                delay: 0.0,
                animations: {
                    UIView.setAnimationCurve(change.animationCurve)
                    strongSelf.contentViewBottomConstraint.constant = change.newHeight
                    strongSelf.view.layoutIfNeeded()
            },
                completion: nil)
        })
    }

    // MARK: - Events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardHandler?.isActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardHandler?.isActive = false
    }

    // MARK: - Interface callbacks

    @IBAction private func resignResponderButtonTapped() {
        textField.resignFirstResponder()
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleKeyboardHandlerViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleKeyboardHandlerViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleKeyboardHandlerViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
