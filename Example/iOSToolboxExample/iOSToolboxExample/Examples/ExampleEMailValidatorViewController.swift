//
//
//

import Foundation
import UIKit

internal class ExampleEMailValidatorViewController: UIViewController {

    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var validationResultLabel: UILabel!

    private var example: Example?
    private let emailValidator = EMailValidator()

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title
        validationResultLabel.text = ""
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        emailTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    // MARK: - Interface callbacks

    @IBAction private func checkButtonTapped() {
        guard let email = emailTextField.text else {
            validationResultLabel.text = ""
            return
        }
        if let validEmail = emailValidator.validate(email: email, shouldTrim: true) {
            validationResultLabel.textColor = UIColor.green
            validationResultLabel.text = "\(validEmail) - valid"
        } else {
            validationResultLabel.textColor = UIColor.red
            validationResultLabel.text = "\(email) - invalid"
        }
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleEMailValidatorViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleEMailValidatorViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleEMailValidatorViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
