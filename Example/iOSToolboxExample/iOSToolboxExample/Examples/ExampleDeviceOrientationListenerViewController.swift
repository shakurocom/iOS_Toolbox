//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

internal class ExampleDeviceOrientationListenerViewController: UIViewController {

    @IBOutlet private var orientationLabel: UILabel!
    @IBOutlet private var updateButton: UIButton!

    private var example: Example?
    private var orientationListener: DeviceOrientationListener?

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        orientationLabel.text = ""
        updateButton.isExclusiveTouch = true

        orientationListener = DeviceOrientationListener()
    }

    // MARK: - Events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        orientationListener?.beginListeningDeviceOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        orientationListener?.endListeningDeviceOrientation()
    }

    // MARK: - Interface callbacks

    @IBAction private func updateButtonTapped() {
        if let listener = orientationListener {
            let orientationString: String
            switch listener.currentOrientation {
            case .unknown: orientationString = "Unknown"
            case .portrait: orientationString = "Portrait"
            case .portraitUpsideDown: orientationString = "Portrait Upside Down"
            case .landscapeLeft: orientationString = "Landscape Left"
            case .landscapeRight: orientationString = "Landscape Right"
            case .faceUp: orientationString = "Face Up"
            case .faceDown: orientationString = "Face Down"
            }
            orientationLabel.text = orientationString
        }
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleDeviceOrientationListenerViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleDeviceOrientationListenerViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleDeviceOrientationListenerViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
