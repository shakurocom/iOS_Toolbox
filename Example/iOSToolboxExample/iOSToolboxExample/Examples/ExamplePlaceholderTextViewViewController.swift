//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

class ExamplePlaceholderTextViewViewController: UIViewController {

    @IBOutlet private var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var textView: PlaceholderTextView!

    private var example: Example?
    private var keyboardHandler: KeyboardHandler?

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        textView.text = nil
        textView.animateIntrinsicContentSize = true
        textView.contentSizeBased = true
        textView.maxLength = 9001
        textView.counterLabelFont = UIFont.systemFont(ofSize: 10)
        textView.counterLabelTextColor = UIColor.gray
        textView.placeholder = "Please enter many lines of text here"

        keyboardHandler = KeyboardHandler(enableCurveHack: false, heightDidChange: { (change: KeyboardHandler.KeyboardChange) in
            UIView.animate(
                withDuration: change.animationDuration,
                delay: 0.0,
                animations: {
                    UIView.setAnimationCurve(change.animationCurve)
                    self.contentViewBottomConstraint.constant = change.newHeight
                    self.view.layoutIfNeeded()
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExamplePlaceholderTextViewViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExamplePlaceholderTextViewViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExamplePlaceholderTextViewViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
