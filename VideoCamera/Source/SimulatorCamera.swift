//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import UIKit
import AVFoundation

internal class SimulatorCamera {

    // general
    private weak var delegate: VideoCameraDelegate?
    private let workQueue: DispatchQueue

    // still image
    private let simulatedImage: CGImage
    private var photoCaptureFallbackBlock: ((_ photo: CGImage) -> Void)?

    // video output
    private let videoFeedbackQueue: DispatchQueue
    private var videoFeedbackTimer: DispatchSourceTimer?
    private let videoFeedbackInterval: DispatchTimeInterval
    private var videoFeedbackPixelBuffer: CVPixelBuffer?
    private let videoFeedbackOrientation: AVCaptureVideoOrientation
    private weak var videoFeedbackHandler: VideoCameraSimulatedVideoDataOutputHandler?

    // preview
    private let cameraPreviewView: SimulatorCameraPreviewView

    // MARK: - Initialization

    internal init(configuration: VideoCameraConfiguration) throws {
        workQueue = DispatchQueue(label: "com.shakuro.simulatorcamera.workqueue")
        delegate = configuration.cameraDelegate
        videoFeedbackOrientation = configuration.simulatedVideoFeedOrientation
        videoFeedbackInterval = configuration.simulatedVideoFeedFrameInterval
        if let providedImage = configuration.simulatedImage {
            simulatedImage = providedImage
        } else {
            if let image = SimulatorCamera.defaultSimulatorImage() {
                simulatedImage = image
            } else {
                throw VideoCameraError.invalidConfiguration(message: "Simulated image is not provided & can't create default image.")
            }
        }
        cameraPreviewView = SimulatorCameraPreviewView(
            frame: CGRect(x: 0, y: 0, width: 100.0, height: 100.0),
            flashColor: configuration.flashColor,
            flashAnimationDuration: configuration.flashAnimationDuration,
            image: simulatedImage)
        videoFeedbackQueue = DispatchQueue(label: "com.shakuro.simulatorcamera.videofeedbackqueue")
        videoFeedbackTimer = nil
        videoFeedbackPixelBuffer = nil
        videoFeedbackHandler = configuration.simulatedVideoFeedDelegate
        photoCaptureFallbackBlock = configuration.photoCaptureSimulatorFallbackBlock

        // general initialization is done - do additional stuff
        cameraPreviewView.setImageHidden(true)

        // simulate creation of capture device
        VideoCameraFactory.requestAuthorizationForVideo(completion: { (_: Bool) in
            self.delegate?.videoCamera(self, authorizationStatusChanged: VideoCameraFactory.authorizationStatusForVideo())
        })

        // done
        delegate?.videoCameraInitialized(self, errors: [])
    }

}

// MARK: - VideoCamera

extension SimulatorCamera: VideoCamera {

    var isInitialized: Bool {
        return true
    }

    var cameraAuthrizationStatus: AVAuthorizationStatus {
        return VideoCameraFactory.authorizationStatusForVideo()
    }

    var previewView: UIView {
        return cameraPreviewView
    }

    var hasFlash: Bool {
        return true
    }

    var flashMode: AVCaptureDevice.FlashMode {
        get {
            return AVCaptureDevice.FlashMode.off
        }
        set { // swiftlint:disable:this unused_setter_value
            // do nothing
        }
    }

    func setNextFlashMode() {
        // do nothing
    }

    var hasTorch: Bool {
        return true
    }

    var torchMode: AVCaptureDevice.TorchMode {
        get {
            return AVCaptureDevice.TorchMode.off
        }
        set {// swiftlint:disable:this unused_setter_value
            // do nothing
        }
    }

    func selectNextTorchMode() {
        // do nothing
    }

    func setDesiredFrameRate(_ frameRate: CMTimeScale) {
        // do nothing
    }

    var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
        get {
            return AVCaptureDevice.WhiteBalanceMode.locked
        }
        set {// swiftlint:disable:this unused_setter_value
            // do nothing
        }
    }

    var automaticallyEnablesLowLightBoostWhenAvailable: Bool {
        get {
            return false
        }
        set {// swiftlint:disable:this unused_setter_value
            // do nothing
        }
    }

    var focusPointOfInterest: CGPoint {
        return CGPoint(x: 0.5, y: 0.5)
    }

    func setFocusMode(_ mode: AVCaptureDevice.FocusMode, atPoint point: CGPoint) {
        // do nothing
    }

    var smoothAutoFocusEnabled: Bool {
        get {
            return false
        }
        set {// swiftlint:disable:this unused_setter_value
            // do nothing
        }

    }

    var autoFocusRangeRestriction: AVCaptureDevice.AutoFocusRangeRestriction {
        get {
            return AVCaptureDevice.AutoFocusRangeRestriction.none
        }
        set {// swiftlint:disable:this unused_setter_value
            // do nothing
        }
    }

    var videoDataOutputSize: CGSize {
        return CGSize(width: simulatedImage.width, height: simulatedImage.height)
    }

    var videoDataOutputOrientation: AVCaptureVideoOrientation {
        return videoFeedbackOrientation
    }

    func startSession() {
        cameraPreviewView.setImageHidden(false)
        if let bufferHandler = videoFeedbackHandler {
            // create simulated buffer, if it is not created yet
            if videoFeedbackPixelBuffer == nil {
                do {
                    videoFeedbackPixelBuffer = try ImageProcessor.createBGRAPixelBuffer(image: simulatedImage)
                } catch let error {
                    delegate?.videoCamera(self, error: VideoCameraError.cantCreateSimulatedVideoBuffer(message: error.localizedDescription))
                }
            }
            if let imageBuffer = videoFeedbackPixelBuffer {
                let videoOrientation = videoFeedbackOrientation
                // (re)start timer
                videoFeedbackTimer?.cancel()
                let timer = DispatchSource.makeTimerSource(queue: videoFeedbackQueue)
                timer.schedule(deadline: DispatchTime.now(), repeating: videoFeedbackInterval, leeway: DispatchTimeInterval.milliseconds(100))
                timer.setEventHandler(handler: {
                    bufferHandler.process(imageBuffer: imageBuffer, orientation: videoOrientation)
                })
                timer.resume()
                videoFeedbackTimer = timer
            }
        }
    }

    func stopSession() {
        videoFeedbackTimer?.cancel()
        videoFeedbackTimer = nil
        cameraPreviewView.setImageHidden(true)
    }

    func setVideoPreviewPaused(_ paused: Bool) {
        // do nothing
    }

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        if let fallback = photoCaptureFallbackBlock {
            fallback(simulatedImage)
        } else {
            fatalError("VideoCamera: fallback is not provided - capture with delegate on simulator is not supported.")
        }
    }

    func capturePhoto(completionBlock: @escaping (Data?, Error?) -> Void) {
        let image = UIImage(cgImage: simulatedImage)
        if let imageData = image.jpegData(compressionQuality: 1) {
            completionBlock(imageData, nil)
        } else {
            completionBlock(nil, VideoCameraError.cantFlattenCapturedPhotoToData)
        }
    }

    var metadataRectOfInterest: CGRect {
        get {
            return cameraPreviewView.bounds
        }
        set {// swiftlint:disable:this unused_setter_value
            // do nothing
        }
    }

    func transformedMetadataObject(_ metadataObject: AVMetadataObject) -> AVMetadataObject? {
        return metadataObject
    }

}

// MARK: - Private

private extension SimulatorCamera {

    private static func defaultSimulatorImage() -> CGImage? {
        let imageSize = CGSize(width: 200, height: 200)
        let imageRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        UIColor.black.setFill()
        UIRectFill(imageRect)
        let font = UIFont.systemFont(ofSize: 16.0)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: UIColor.green
        ]
        let string: NSString = "iOS Toolbox\nsimulator camera"
        string.draw(in: imageRect.insetBy(dx: 0, dy: 60), withAttributes: attributes)
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return uiImage?.cgImage
    }

}
