//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

class ExampleUIStoryboardExtensionsViewController: UIViewController {

    @IBOutlet private var instantiateGoodViewControllerButton: UIButton!
    @IBOutlet private var instantiateBadTypeViewControllerButton: UIButton!
    @IBOutlet private var instantiateBadIdViewControllerButton: UIButton!

    private var example: Example?

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        instantiateGoodViewControllerButton.isExclusiveTouch = true
        instantiateGoodViewControllerButton.titleLabel?.numberOfLines = 0
        instantiateGoodViewControllerButton.titleLabel?.textAlignment = .center
        instantiateGoodViewControllerButton.setTitle("good example\n(will be dismissed in few seconds)", for: UIControl.State.normal)
        instantiateBadTypeViewControllerButton.isExclusiveTouch = true
        instantiateBadTypeViewControllerButton.titleLabel?.numberOfLines = 0
        instantiateBadTypeViewControllerButton.titleLabel?.textAlignment = .center
        instantiateBadTypeViewControllerButton.setTitle("bad example (wrong type)\n(will result in fatalError)", for: UIControl.State.normal)
        instantiateBadIdViewControllerButton.isExclusiveTouch = true
        instantiateBadIdViewControllerButton.titleLabel?.numberOfLines = 0
        instantiateBadIdViewControllerButton.titleLabel?.textAlignment = .center
        instantiateBadIdViewControllerButton.setTitle("bad example (wrong ID)\n(will result in storyboard exception)", for: UIControl.State.normal)
    }

    // MARK: - Interface callbacks

    @IBAction private func instantiateGoodViewControllerButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: type(of: self)))
        // NOTE: type is specified, so generic method from extension will be called
        let deviceTypeVC: ExampleDeviceTypeViewController = storyboard.instantiateViewController(withIdentifier: "kExampleDeviceTypeViewControllerID")
        self.present(deviceTypeVC, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5), execute: {
            deviceTypeVC.dismiss(animated: true, completion: nil)
        })
    }

    @IBAction private func instantiateBadTypeViewControllerButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: type(of: self)))
        // NOTE: return type is different from the view controller with this ID
        let wrongVC: ExampleDeviceOrientationListenerViewController = storyboard.instantiateViewController(withIdentifier: "kExampleDeviceTypeViewControllerID")
        self.present(wrongVC, animated: true, completion: nil)
    }

    @IBAction private func instantiateBadIdViewControllerButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: type(of: self)))
        // note the type is specified
        let wrongVC: ExampleDeviceTypeViewController = storyboard.instantiateViewController(withIdentifier: "kExampleDeviceTyp")
        self.present(wrongVC, animated: true, completion: nil)
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleUIStoryboardExtensionsViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleUIStoryboardExtensionsViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleUIStoryboardExtensionsViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
