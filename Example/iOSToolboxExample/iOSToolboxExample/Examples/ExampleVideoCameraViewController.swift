//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit
import AVFoundation

class ExampleVideoCameraViewController: UIViewController {

    @IBOutlet private var previewContainerView: UIView!
    @IBOutlet private var flashButton: UIButton!
    @IBOutlet private var torchButton: UIButton!
    @IBOutlet private var takePhotoButton: UIButton!
    @IBOutlet private var cameraAuthorizationLabel: UILabel!

    private var example: Example?
    private var camera: VideoCamera?

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        title = example?.title

        var cameraConfig = VideoCameraConfiguration()
        cameraConfig.cameraDelegate = self
        cameraConfig.capturePhotoEnabled = true
        cameraConfig.simulatedImage = UIImage(named: "IMG_0010.JPG")?.cgImage // you can leave this value as nil to use default image
        let videoCamera = VideoCameraFactory.createCamera(configuration: cameraConfig)
        let previewView = videoCamera.previewView
        previewView.translatesAutoresizingMaskIntoConstraints = true
        previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewView.frame = previewContainerView.bounds
        previewContainerView.addSubview(previewView)
        camera = videoCamera

        cameraAuthorizationLabel.text = nil

        updateFlashButton()
        updateTorchButton()
    }

    // MARK: - Events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera?.startSession()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera?.stopSession()
    }

    // MARK: - Interface callbacks

    @IBAction private func flashButtonTapped() {
        camera?.setNextFlashMode()
    }

    @IBAction private func torchButtonTapped() {
        camera?.selectNextTorchMode()
    }

    @IBAction private func takePhotoButtonTapped() {
        takePhotoButton.isEnabled = false
        camera?.capturePhoto(completionBlock: { (imageData: Data?, error: Error?) in
            DispatchQueue.main.async(execute: {
                if let realError = error {
                    self.showErrorAlert(error: realError)
                } else {
                    var image: UIImage?
                    if let data = imageData {
                        image = UIImage(data: data)
                    }
                    let imageVC = ImagePreviewViewController.instantiate(image: image)
                    self.navigationController?.pushViewController(imageVC, animated: true)
                }
                self.takePhotoButton.isEnabled = true
            })
        })
    }

    // MARK: - Private

    private func updateFlashButton() {
        if let flashMode = camera?.flashMode {
            let newTitle: String
            switch flashMode {
            case .off:
                newTitle = "flash: off"
            case .on:
                newTitle = "flash: on"
            case .auto:
                newTitle = "flash: auto"
            @unknown default:
                fatalError()
            }
            flashButton.setTitle(newTitle, for: UIControl.State.normal)
        }
    }

    private func updateTorchButton() {
        if let torchMode = camera?.torchMode {
            let newTitle: String
            switch torchMode {
            case .off:
                newTitle = "torch: off"
            case .on:
                newTitle = "torch: on"
            case .auto:
                newTitle = "torch: auto"
            @unknown default:
                fatalError()
            }
            torchButton.setTitle(newTitle, for: UIControl.State.normal)
        }
    }

    private func showErrorAlert(error: Error) {
        let title = "Error"
        let message: String
        // NOTE: wierd thing with custom error types
        if let cameraError = error as? VideoCameraError {
            message = cameraError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }

}

extension ExampleVideoCameraViewController: VideoCameraDelegate {

    func videoCamera(_ videoCamera: VideoCamera, error: Error) {
        DispatchQueue.main.async(execute: {
            self.showErrorAlert(error: error)
        })
    }

    func videoCameraInitialized(_ videoCamera: VideoCamera, errors: [VideoCameraError]) {
        DispatchQueue.main.async(execute: {
            self.updateTorchButton()
            self.updateFlashButton()
        })
    }

    func videoCamera(_ videoCamera: VideoCamera, authorizationStatusChanged newValue: AVAuthorizationStatus) {
        DispatchQueue.main.async(execute: {
            switch newValue {
            case .notDetermined:
                self.cameraAuthorizationLabel.text = "auth: not determined"
            case .restricted:
                self.cameraAuthorizationLabel.text = "auth: restricted"
            case .denied:
                self.cameraAuthorizationLabel.text = "auth: denied"
            case .authorized:
                self.cameraAuthorizationLabel.text = nil
            @unknown default:
                fatalError()
            }
        })
    }

    func videoCamera(_ videoCamera: VideoCamera, flashModeForPhotoDidChanged newValue: AVCaptureDevice.FlashMode) {
        DispatchQueue.main.async(execute: {
            self.updateFlashButton()
        })
    }

    func videoCamera(_ videoCamera: VideoCamera, torchModeDidChanged newValue: AVCaptureDevice.TorchMode) {
        DispatchQueue.main.async(execute: {
            self.updateTorchButton()
        })
    }

    func videoCamera(_ videoCamera: VideoCamera, focusPointOfInterestDidChanged newValue: CGPoint) {
        // skip
    }

    func videoCameraWillCapturePhoto(_ videoCamera: VideoCamera) {
        // skip
    }

    func videoCameraDidFinishCapturingPhoto(_ videoCamera: VideoCamera, error: Error?) {
        // skip
    }

    func videoCameraDidFinishRecordingLivePhoto(_ videoCamera: VideoCamera, url: URL) {
        // skip
    }

    func videoCameraDidFinishProcessingLivePhoto(_ videoCamera: VideoCamera, url: URL, duration: CMTime, photoDisplayTime: CMTime, error: Error?) {
        // skip
    }

}

// MARK: - ExampleViewControllerProtocol

extension ExampleVideoCameraViewController: ExampleViewControllerProtocol {

    static func instantiate(example: Example) -> UIViewController {
        let exampleVC: ExampleVideoCameraViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kExampleVideoCameraViewControllerID")
        exampleVC.example = example
        return exampleVC
    }

}
